#!/usr/bin/env bash

# MiSTer WiFi helper based on the older RetroPie-derived wifi.sh.
#
# Changelog:
# Version 2.2.0 - 2026-04-30 - Adds retryable adapter detection, disconnect, config repair, diagnostics file, and health checks.
#                            - Consolidates saved-network viewing/removal and remembers menu selection.
#                            - Adds reconnect command for saved WiFi networks.
# Version 2.0.0 - 2026-04-19 - Updated for MiSTer distribution use.
#                            - Avoids ifup/ifdown so WiFi setup does not trigger /etc/network/if-up.d hooks.
#                            - Manages /media/fat/linux/wpa_supplicant.conf directly and preserves saved networks.
#                            - Adds country-code setup/fix flow for regulatory-domain compatibility.
#                            - Waits for WPA association before DHCP, then verifies an IPv4 lease.
#                            - Sends dialog UI to /dev/tty when available for MiSTer menu compatibility.
#                            - Adds diagnostics for Realtek adapters stuck in USB storage mode.
#                            - Adds --diagnose for interface, USB, config, and dmesg reporting.
#                            - Detects malformed wpa_supplicant.conf before editing saved networks.
#                            - Warns when legacy CIFS boot-time network hooks are present.
# Version 1.0.0 - 2019-10-21 - Ported from the RetroPie Project wifi.sh for MiSTer by Porkchop Express / MiSTerAddons.
# Original      - RetroPie Project WiFi helper.

set -u
set -o pipefail

readonly WPA_CONF="${WPA_CONF:-/media/fat/linux/wpa_supplicant.conf}"
readonly WPA_TMP="${WPA_CONF}.tmp.$$"
readonly INTERFACE_WAIT_SECONDS=2
readonly INTERFACE_DETECT_TIMEOUT_SECONDS="${INTERFACE_DETECT_TIMEOUT_SECONDS:-5}"
readonly ASSOCIATION_WAIT_SECONDS="${ASSOCIATION_WAIT_SECONDS:-15}"
readonly IPV4_WAIT_SECONDS="${IPV4_WAIT_SECONDS:-15}"
readonly SCAN_TIMEOUT_SECONDS="${SCAN_TIMEOUT_SECONDS:-20}"
readonly DISCONNECT_TIMEOUT_SECONDS="${DISCONNECT_TIMEOUT_SECONDS:-5}"
readonly DIAGNOSE_FILE="${DIAGNOSE_FILE:-/media/fat/wifi_diagnose.txt}"

COMMON_COUNTRIES=(
    US "United States"
    CA "Canada"
    GB "United Kingdom"
    AU "Australia"
    DE "Germany"
    ES "Spain"
    FR "France"
    IT "Italy"
    JP "Japan"
    BR "Brazil"
    ZZ "Other / enter manually"
)

__backtitle="MiSTer WiFi Configuration"
__nodialog="${__nodialog:-0}"
DIALOG_TTY="${DIALOG_TTY:-/dev/tty}"
INTERFACE="${INTERFACE:-wlan0}"
CIFS_WARNING_SHOWN=0

cleanup() {
    rm -f "$WPA_TMP" 2>/dev/null || true
}

trap cleanup EXIT

printMsgs() {
    local type="$1"
    shift

    if [[ "$__nodialog" == "1" && "$type" == "dialog" ]]; then
        type="console"
    fi
    if [[ "$type" == "dialog" ]] && ! dialog_ui_available; then
        type="console"
    fi

    for msg in "$@"; do
        [[ "$type" == "dialog" ]] && run_dialog dialog --backtitle "$__backtitle" --cr-wrap --no-collapse --msgbox "$msg" 20 68
        [[ "$type" == "console" ]] && echo -e "$msg"
        [[ "$type" == "heading" ]] && echo -e "\n= = = = = = = = = = = = = = = = = = = = =\n$msg\n= = = = = = = = = = = = = = = = = = = = =\n"
    done

    return 0
}

show_infobox() {
    if [[ "$__nodialog" != "1" ]] && dialog_ui_available; then
        run_dialog dialog --backtitle "$__backtitle" --infobox "\n$1" 5 56
    else
        echo -e "$1" >&2
    fi
}

close_dialog_screen() {
    [[ "$__nodialog" == "1" ]] && return 0

    if dialog_tty_available; then
        stty sane < "$DIALOG_TTY" > "$DIALOG_TTY" 2>/dev/null || true
        printf '\033[?25h\033[0m' > "$DIALOG_TTY" 2>/dev/null || true
        clear > "$DIALOG_TTY" 2>/dev/null || true
    elif [[ -t 1 ]]; then
        stty sane 2>/dev/null || true
        printf '\033[?25h\033[0m'
        clear 2>/dev/null || true
    fi

    return 0
}

return_to_mister_menu() {
    [[ "$__nodialog" == "1" ]] && return 0
    [[ -n "${SSH_CLIENT:-}${SSH_CONNECTION:-}" ]] && return 0
    [[ -w /dev/MiSTer_cmd ]] || return 0
    [[ -f /media/fat/menu.rbf ]] || return 0

    command_exists timeout || return 0
    timeout 2 sh -c 'printf "%s\n" "load_core /media/fat/menu.rbf" > /dev/MiSTer_cmd' >/dev/null 2>&1 || true
}

capture_dialog() {
    if dialog_tty_available; then
        "$@" 2>&1 > "$DIALOG_TTY"
    elif [[ -t 1 || -t 2 ]]; then
        "$@" 3>&1 1>&2 2>&3
    else
        printMsgs "console" "Interactive dialog is unavailable. Run this script from the MiSTer menu or an interactive terminal."
        return 1
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_with_timeout() {
    local seconds="$1"
    shift

    if command_exists timeout; then
        timeout "$seconds" "$@"
    else
        "$@"
    fi
}

dialog_tty_available() {
    [[ -n "${DIALOG_TTY:-}" && -c "$DIALOG_TTY" ]] || return 1
    { : > "$DIALOG_TTY"; } 2>/dev/null
}

dialog_ui_available() {
    command_exists dialog || return 1
    dialog_tty_available || [[ -t 1 || -t 2 ]]
}

run_dialog() {
    if dialog_tty_available; then
        "$@" > "$DIALOG_TTY"
    elif [[ -t 1 || -t 2 ]]; then
        "$@" 1>&2
    else
        return 1
    fi
}

usb_devices() {
    command_exists lsusb || return 0
    lsusb 2>/dev/null || true
}

realtek_storage_devices() {
    usb_devices | grep -Ei '0bda:1a2b.*(Realtek|DISK)|0bda:1a2b' || true
}

wifi_like_usb_devices() {
    usb_devices | grep -Eiv 'root hub' | grep -Ei '802\.11|wireless|wi-?fi|wlan|realtek|ralink|mediatek|atheros|broadcom|tp-link|d-link|0bda:|2001:|2357:' || true
}

no_wireless_interface_text() {
    local storage_devices wifi_devices

    storage_devices=$(realtek_storage_devices)
    if [[ -n "$storage_devices" ]]; then
        printf 'No wireless network interface was detected.\n\nDetected Realtek adapter in USB storage mode:\n%s\n\nThis adapter has not switched into WiFi mode yet. Unplug and reinsert the dongle.' "$storage_devices"
        return 0
    fi

    wifi_devices=$(wifi_like_usb_devices)
    if [[ -n "$wifi_devices" ]]; then
        printf 'No wireless network interface was detected.\n\nThese USB devices look WiFi-related, but no wlan interface is available:\n%s\n\nThis usually means the driver or firmware did not bind yet. Try unplugging/reinserting the adapter or rebooting MiSTer.' "$wifi_devices"
        return 0
    fi

    printf 'No wireless network interface was detected.'
}

no_wireless_interface_message() {
    printMsgs "dialog" "$(no_wireless_interface_text)"
}

retry_no_wireless_interface() {
    local message prompt_message

    message=$(no_wireless_interface_text)

    if [[ "$__nodialog" == "1" ]] || ! dialog_ui_available; then
        printMsgs "dialog" "$message"
        return 1
    fi

    prompt_message="${message}"$'\n\nAfter reinserting the dongle, choose Retry.'
    capture_dialog dialog --backtitle "$__backtitle" --yes-label "Retry" --no-label "Back" --yesno "$prompt_message" 20 74
}

require_tools() {
    local missing=()
    local tool

    for tool in awk dialog grep ip iwgetid iwlist sed; do
        command_exists "$tool" || missing+=("$tool")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        printMsgs "dialog" "Missing required tools: ${missing[*]}"
        return 1
    fi

    return 0
}

detect_interface() {
    local detected_interface

    while true; do
        detected_interface=$(find_wireless_interface) || {
            retry_no_wireless_interface || return 1
            continue
        }

        INTERFACE="$detected_interface"
        return 0
    done
}

ensure_wpa_conf() {
    if [[ ! -f "$WPA_CONF" ]]; then
        mkdir -p "$(dirname "$WPA_CONF")" 2>/dev/null || true
        cat > "$WPA_CONF" <<'EOF'
ctrl_interface=/run/wpa_supplicant
update_config=1

EOF
        chmod 600 "$WPA_CONF"
    fi
}

wpa_conf_validation_error() {
    [[ -f "$WPA_CONF" ]] || return 0

    awk '
        function ltrim(s) {
            sub(/^[[:space:]]+/, "", s)
            return s
        }

        function rtrim(s) {
            sub(/[[:space:]\r]+$/, "", s)
            return s
        }

        function trim(s) {
            return rtrim(ltrim(s))
        }

        BEGIN {
            in_block = 0
            block_start = 0
            error = ""
        }

        {
            line = trim($0)
            if (line ~ /^network[[:space:]]*=[[:space:]]*\{$/) {
                if (in_block && error == "") {
                    error = "nested network block near line " NR
                }
                in_block = 1
                block_start = NR
                next
            }

            if (in_block && line == "}") {
                in_block = 0
                block_start = 0
            }
        }

        END {
            if (in_block && error == "") {
                error = "unclosed network block starting near line " block_start
            }
            if (error != "") {
                print error
            }
        }
    ' "$WPA_CONF"
}

get_country_code_from_file() {
    local file="$1"

    [[ -f "$file" ]] || return 0

    awk -F= '
        /^[[:space:]]*country[[:space:]]*=/ {
            value = $2
            sub(/[[:space:]]*#.*/, "", value)
            gsub(/[[:space:]"\r]/, "", value)
            value = toupper(value)

            if (value ~ /^[A-Z][A-Z]$/) {
                print value
                exit
            }
        }
    ' "$file"
}

get_country_code() {
    get_country_code_from_file "$WPA_CONF"
}

has_country_header() {
    local file="$1"

    [[ -f "$file" ]] || return 1

    awk '
        /^[[:space:]]*country[[:space:]]*=/ {
            found = 1
            exit
        }

        END {
            exit found ? 0 : 1
        }
    ' "$file"
}

first_country_header() {
    local file="$1"

    [[ -f "$file" ]] || return 0

    awk '
        /^[[:space:]]*country[[:space:]]*=/ {
            sub(/[[:space:]\r]+$/, "", $0)
            print
            exit
        }
    ' "$file"
}

raw_country_code_from_file() {
    local file="$1"

    [[ -f "$file" ]] || return 0

    awk -F= '
        /^[[:space:]]*country[[:space:]]*=/ {
            value = $2
            sub(/[[:space:]]*#.*/, "", value)
            gsub(/[^[:alnum:]]/, "", value)
            print toupper(value)
            exit
        }
    ' "$file"
}

repair_country_code() {
    local country="$1"

    case "$country" in
        USA|UNITEDSTATES)
            echo "US"
            ;;
        GBR|UK|UNITEDKINGDOM)
            echo "GB"
            ;;
        CAN|CANADA)
            echo "CA"
            ;;
        AUS|AUSTRALIA)
            echo "AU"
            ;;
        DEU|GER|GERMANY)
            echo "DE"
            ;;
        ESP|SPAIN)
            echo "ES"
            ;;
        FRA|FRANCE)
            echo "FR"
            ;;
        ITA|ITALY)
            echo "IT"
            ;;
        JPN|JAPAN)
            echo "JP"
            ;;
        BRA|BRAZIL)
            echo "BR"
            ;;
    esac
}

repair_wpa_conf() {
    local error country raw_country repaired_country timestamp backup preserved

    ensure_wpa_conf
    error=$(wpa_conf_validation_error)

    if [[ -z "$error" ]]; then
        printMsgs "dialog" "$WPA_CONF looks OK. No repair needed."
        return 0
    fi

    timestamp=$(date '+%Y%m%d-%H%M%S' 2>/dev/null || echo "$$")
    backup="${WPA_CONF}.bak.${timestamp}"

    cp "$WPA_CONF" "$backup" 2>/dev/null || {
        printMsgs "dialog" "Unable to back up $WPA_CONF.\n\nNo repair was made."
        return 1
    }

    country=$(get_country_code_from_file "$backup")
    raw_country=$(raw_country_code_from_file "$backup")
    if ! is_valid_country_code "$country" && [[ -n "$raw_country" ]]; then
        repaired_country=$(repair_country_code "$raw_country")
        is_valid_country_code "$repaired_country" && country="$repaired_country"
    fi

    {
        echo "ctrl_interface=/run/wpa_supplicant"
        echo "update_config=1"
        is_valid_country_code "$country" && echo "country=$country"
        echo
        awk '
            function ltrim(s) {
                sub(/^[[:space:]]+/, "", s)
                return s
            }

            function rtrim(s) {
                sub(/[[:space:]\r]+$/, "", s)
                return s
            }

            function trim(s) {
                return rtrim(ltrim(s))
            }

            function finish_block() {
                if (!bad_block && saw_ssid) {
                    printf "%s\n", block
                }
                in_block = 0
                bad_block = 0
                saw_ssid = 0
                block = ""
            }

            BEGIN {
                in_block = 0
                bad_block = 0
                saw_ssid = 0
                block = ""
            }

            {
                line = trim($0)

                if (line ~ /^network[[:space:]]*=[[:space:]]*\{$/) {
                    if (in_block) {
                        bad_block = 1
                        block = block $0 ORS
                        next
                    }

                    in_block = 1
                    bad_block = 0
                    saw_ssid = 0
                    block = $0 ORS
                    next
                }

                if (in_block) {
                    block = block $0 ORS

                    if (line ~ /^ssid[[:space:]]*=/) {
                        saw_ssid = 1
                    }

                    if (line == "}") {
                        finish_block()
                    }
                }
            }
        ' "$backup"
    } > "$WPA_TMP" || {
        rm -f "$WPA_TMP" 2>/dev/null || true
        printMsgs "dialog" "Unable to rebuild $WPA_CONF.\n\nBackup remains at:\n$backup"
        return 1
    }

    mv "$WPA_TMP" "$WPA_CONF" || {
        printMsgs "dialog" "Unable to replace $WPA_CONF.\n\nBackup remains at:\n$backup"
        return 1
    }

    chmod 600 "$WPA_CONF"
    sync

    preserved=$(saved_networks | awk 'END { print NR + 0 }')
    if is_valid_country_code "$country"; then
        if [[ -n "$raw_country" && "$raw_country" != "$country" ]]; then
            printMsgs "dialog" "Repaired $WPA_CONF.\n\nBackup saved as:\n$backup\n\nRepaired country=$raw_country to country=$country in the config header.\nPreserved complete saved networks: $preserved\nDropped malformed or incomplete network blocks."
        else
            printMsgs "dialog" "Repaired $WPA_CONF.\n\nBackup saved as:\n$backup\n\nRestored country=$country in the config header.\nPreserved complete saved networks: $preserved\nDropped malformed or incomplete network blocks."
        fi
    elif has_country_header "$backup"; then
        printMsgs "dialog" "Repaired $WPA_CONF.\n\nBackup saved as:\n$backup\n\nFound an invalid country header and did not invent a replacement:\n$(first_country_header "$backup")\n\nSet/fix the country code from the WiFi menu.\nPreserved complete saved networks: $preserved\nDropped malformed or incomplete network blocks."
    else
        printMsgs "dialog" "Repaired $WPA_CONF.\n\nBackup saved as:\n$backup\n\nNo country header was found, so no country code was invented.\nSet/fix the country code from the WiFi menu.\nPreserved complete saved networks: $preserved\nDropped malformed or incomplete network blocks."
    fi
}

offer_wpa_config_repair() {
    local error="$1"
    local prompt_message

    if [[ "$__nodialog" == "1" ]] || ! dialog_ui_available; then
        printMsgs "console" "$WPA_CONF appears malformed:\n\n$error\n\nNo WiFi network entries were changed. Run $0 --repair-config to back up the file and rebuild complete saved networks."
        return 1
    fi

    prompt_message="$WPA_CONF appears malformed:"$'\n\n'"$error"$'\n\n'"Repair can back up the current file, rebuild the standard header, preserve complete saved network blocks, and drop malformed or incomplete blocks."$'\n\n'"Repair now?"
    capture_dialog dialog --backtitle "$__backtitle" --yes-label "Repair" --no-label "Back" --yesno "$prompt_message" 20 74 || {
        printMsgs "dialog" "No WiFi network entries were changed."
        return 1
    }

    repair_wpa_conf
}

validate_wpa_conf() {
    local error

    error=$(wpa_conf_validation_error)
    if [[ -n "$error" ]]; then
        offer_wpa_config_repair "$error" || return 1
    fi

    return 0
}

is_valid_country_code() {
    [[ "$1" =~ ^[A-Z]{2}$ ]]
}

set_country_code() {
    local country="$1"

    if grep -q '^[[:space:]]*country[[:space:]]*=' "$WPA_CONF"; then
        awk -v country="$country" '
            BEGIN {
                replaced = 0
            }

            {
                if (!replaced && $0 ~ /^[[:space:]]*country[[:space:]]*=/) {
                    print "country=" country
                    replaced = 1
                } else {
                    print
                }
            }
        ' "$WPA_CONF" > "$WPA_TMP"
        mv "$WPA_TMP" "$WPA_CONF"
    else
        {
            echo "country=$country"
            echo
            cat "$WPA_CONF"
        } > "$WPA_TMP"
        mv "$WPA_TMP" "$WPA_CONF"
    fi

    chmod 600 "$WPA_CONF"
}

prompt_country_code() {
    local force_prompt="${1:-0}"
    local current_country choice entered_country default_country

    ensure_wpa_conf
    current_country=$(get_country_code)

    if [[ "$force_prompt" != "1" ]] && is_valid_country_code "$current_country"; then
        return 0
    fi

    if is_valid_country_code "$current_country"; then
        printMsgs "dialog" "Current WiFi country code: $current_country\n\nChoose a new country code if you want to change it."
        default_country="$current_country"
    else
        printMsgs "dialog" "MiSTer WiFi needs a valid two-letter country code in $WPA_CONF.\n\nThis improves compatibility and helps avoid the connection issues described in Scripts_MiSTer issue #98."
        default_country="US"
    fi

    choice=$(capture_dialog dialog --backtitle "$__backtitle" --default-item "$default_country" --cancel-label "Back" --menu "Choose your WiFi country code:" 20 68 10 "${COMMON_COUNTRIES[@]}") || return 1

    if [[ "$choice" == "ZZ" ]]; then
        entered_country=$(capture_dialog dialog --backtitle "$__backtitle" --inputbox "Enter your 2-letter country code:" 10 52 "$default_country") || return 1
        entered_country=$(echo "$entered_country" | tr '[:lower:]' '[:upper:]')
        if ! is_valid_country_code "$entered_country"; then
            printMsgs "dialog" "Country code must be exactly two letters, for example US, CA, GB, DE, or JP."
            return 1
        fi
        choice="$entered_country"
    fi

    set_country_code "$choice"
    printMsgs "dialog" "Saved country=$choice in $WPA_CONF"
    return 0
}

warn_if_cifs_boot_hooks_exist() {
    local hook

    [[ "$CIFS_WARNING_SHOWN" -eq 0 ]] || return 0

    for hook in /etc/network/if-up.d/* /etc/network/if-down.d/*; do
        [[ -e "$hook" ]] || continue
        if [[ "$(basename "$hook")" == *cifs* ]] || grep -qi 'cifs\|mount_cifs\|cifs_mount' "$hook" 2>/dev/null; then
            CIFS_WARNING_SHOWN=1
            printMsgs "dialog" "Detected CIFS boot-time network hooks.\n\nThis WiFi script avoids ifup/ifdown so it does not intentionally trigger those hooks, but MiSTer users have reported WiFi trouble when CIFS auto-mount is enabled at boot (Scripts_MiSTer issue #88).\n\nIf WiFi is unstable, set MOUNT_AT_BOOT=false in cifs_mount.ini and mount your shares after networking is already up."
            return 0
        fi
    done
}

set_interface_state() {
    local state="$1"

    if ! detect_interface; then
        return 1
    fi

    if [[ "$state" == "up" ]]; then
        ip link set "$INTERFACE" up >/dev/null 2>&1 || {
            printMsgs "dialog" "Unable to bring up $INTERFACE."
            return 1
        }
        sleep "$INTERFACE_WAIT_SECONDS"
    elif [[ "$state" == "down" ]]; then
        ip link set "$INTERFACE" down >/dev/null 2>&1 || true
    fi

    return 0
}

signal_label() {
    local quality="$1"

    if (( quality >= 75 )); then
        echo "Strong"
    elif (( quality >= 50 )); then
        echo "Good"
    elif (( quality >= 25 )); then
        echo "Fair"
    else
        echo "Weak"
    fi
}

signal_color() {
    local quality="$1"

    if (( quality >= 75 )); then
        echo "2"
    elif (( quality >= 50 )); then
        echo "3"
    else
        echo "1"
    fi
}

colorize_menu_label() {
    local quality="$1"
    local essid="$2"
    local type="$3"
    local color

    color=$(signal_color "$quality")
    printf '\\Z%s%s\\Zn (%s)' "$color" "$essid" "$type"
}

list_wifi() {
    local scan_output
    local line essid="" type="" quality=0 quality_max=0 quality_pct=0
    local raw_networks="" sorted_networks="" seen="|"

    set_interface_state up || return 1
    show_infobox "Searching for WiFi networks..."

    scan_output=$(run_with_timeout "$SCAN_TIMEOUT_SECONDS" iwlist "$INTERFACE" scan 2>/dev/null) || {
        printMsgs "dialog" "WiFi scan did not complete within ${SCAN_TIMEOUT_SECONDS} seconds on $INTERFACE."
        return 1
    }

    emit_network() {
        local label

        [[ -n "$essid" ]] || return 0
        [[ "$essid" == "<hidden>" ]] && return 0

        if [[ -z "$type" ]]; then
            type="open"
        fi

        label=$(signal_label "$quality_pct")
        raw_networks+="${quality_pct}"$'\t'"${essid}"$'\t'"${type}"$'\t'"${label}"$'\n'
    }

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*Cell[[:space:]] ]]; then
            emit_network
            essid=""
            type=""
            quality_pct=0
            continue
        fi

        if [[ "$line" =~ ESSID:\"(.*)\" ]]; then
            essid="${BASH_REMATCH[1]}"
            [[ -z "$essid" ]] && essid="<hidden>"
        fi

        if [[ "$line" =~ Quality=([0-9]+)/([0-9]+) ]]; then
            quality="${BASH_REMATCH[1]}"
            quality_max="${BASH_REMATCH[2]}"
            if [[ "$quality_max" -gt 0 ]]; then
                quality_pct=$(( quality * 100 / quality_max ))
            fi
        elif [[ "$line" =~ Signal\ level=-([0-9]+) ]]; then
            quality=$(( 100 - BASH_REMATCH[1] ))
            (( quality < 0 )) && quality=0
            quality_pct=$quality
        fi

        if [[ "$line" == *"Encryption key:off"* ]]; then
            type="open"
        elif [[ "$line" == *"IEEE 802.11i/WPA2"* ]] || [[ "$line" == *"WPA2"* ]] || [[ "$line" == *"IE: IEEE 802.11i/WPA2"* ]]; then
            type="wpa"
        elif [[ "$line" == *"WPA Version"* ]] || [[ "$line" == *"IE: WPA"* ]]; then
            type="wpa"
        elif [[ "$line" == *"Encryption key:on"* && -z "$type" ]]; then
            type="wep"
        fi
    done <<< "$scan_output"

    emit_network

    [[ -n "$raw_networks" ]] || return 0
    sorted_networks=$(printf '%s' "$raw_networks" | sort -t $'\t' -k1,1nr -k2,2) || return 1

    while IFS=$'\t' read -r quality_pct essid type label; do
        [[ -n "$essid" ]] || continue
        [[ "$seen" == *"|$essid|"* ]] && continue

        printf '%s\t%s\t%s\t%s\n' "$essid" "$type" "$label" "$quality_pct"
        seen="${seen}${essid}|"
    done <<< "$sorted_networks"
}

escape_wpa_string() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

remove_network_by_ssid() {
    local target_ssid="$1"
    local escaped_ssid

    ensure_wpa_conf
    validate_wpa_conf || return 1
    escaped_ssid=$(escape_wpa_string "$target_ssid")

    awk -v target="$escaped_ssid" '
        function ltrim(s) {
            sub(/^[[:space:]]+/, "", s)
            return s
        }

        function rtrim(s) {
            sub(/[[:space:]\r]+$/, "", s)
            return s
        }

        function trim(s) {
            return rtrim(ltrim(s))
        }

        BEGIN {
            in_block = 0
            skip_block = 0
            block = ""
        }

        trim($0) ~ /^network[[:space:]]*=[[:space:]]*\{$/ {
            in_block = 1
            skip_block = 0
            block = $0 ORS
            next
        }

        in_block {
            block = block $0 ORS
            line = trim($0)
            if (line ~ /^ssid[[:space:]]*=/) {
                ssid = line
                sub(/^ssid[[:space:]]*=[[:space:]]*/, "", ssid)
                ssid = trim(ssid)

                if (ssid ~ /^"/) {
                    sub(/^"/, "", ssid)
                    sub(/"$/, "", ssid)
                }

                gsub(/\\"/, "\"", ssid)
                gsub(/\\\\/, "\\", ssid)

                if (ssid == target) {
                    skip_block = 1
                }
            }
            if (line == "}") {
                if (!skip_block) {
                    printf "%s", block
                }
                in_block = 0
                block = ""
            }
            next
        }

        {
            print
        }
    ' "$WPA_CONF" > "$WPA_TMP" && mv "$WPA_TMP" "$WPA_CONF"
    chmod 600 "$WPA_CONF"
}

saved_networks() {
    ensure_wpa_conf

    awk '
        function ltrim(s) {
            sub(/^[[:space:]]+/, "", s)
            return s
        }

        function rtrim(s) {
            sub(/[[:space:]\r]+$/, "", s)
            return s
        }

        function trim(s) {
            return rtrim(ltrim(s))
        }

        BEGIN {
            in_block = 0
            idx = 0
            ssid = ""
        }

        trim($0) ~ /^network[[:space:]]*=[[:space:]]*\{$/ {
            in_block = 1
            ssid = ""
            next
        }

        in_block {
            line = trim($0)
            if (line ~ /^ssid[[:space:]]*=/) {
                ssid = line
                sub(/^ssid[[:space:]]*=[[:space:]]*/, "", ssid)
                ssid = trim(ssid)

                if (ssid ~ /^"/) {
                    sub(/^"/, "", ssid)
                    sub(/"$/, "", ssid)
                }

                gsub(/\\"/, "\"", ssid)
                gsub(/\\\\/, "\\", ssid)
            } else if (line == "}") {
                if (ssid != "") {
                    printf "%s\t%s\n", idx, ssid
                    idx++
                }
                in_block = 0
            }
        }
    ' "$WPA_CONF"
}

network_block_for_wpa() {
    local essid="$1"
    local key="$2"
    local hidden="$3"
    local block

    if command_exists wpa_passphrase; then
        block=$(wpa_passphrase "$essid" "$key" 2>/dev/null | sed '/^[[:space:]]*#psk=/d')
    else
        block=$(cat <<EOF
network={
    ssid="$(escape_wpa_string "$essid")"
    psk="$(escape_wpa_string "$key")"
}
EOF
)
    fi

    if [[ "$hidden" == "1" ]]; then
        block=$(printf '%s\n' "$block" | awk '
            /ssid=/ && !done {
                print
                print "    scan_ssid=1"
                done = 1
                next
            }
            { print }
        ')
    fi

    printf '%s\n' "$block"
}

append_network_config() {
    local type="$1"
    local essid="$2"
    local key="$3"
    local hidden="$4"
    local escaped_essid escaped_key

    ensure_wpa_conf
    validate_wpa_conf || return 1
    remove_network_by_ssid "$essid" || return 1

    escaped_essid=$(escape_wpa_string "$essid")
    escaped_key=$(escape_wpa_string "$key")

    {
        echo
        case "$type" in
            wpa)
                network_block_for_wpa "$essid" "$key" "$hidden"
                ;;
            wep)
                echo "network={"
                echo "    ssid=\"$escaped_essid\""
                echo "    key_mgmt=NONE"
                echo "    wep_tx_keyidx=0"
                if [[ "$key" =~ ^([0-9A-Fa-f]{10}|[0-9A-Fa-f]{26}|[0-9A-Fa-f]{58})$ ]]; then
                    echo "    wep_key0=$key"
                else
                    echo "    wep_key0=\"$escaped_key\""
                fi
                [[ "$hidden" == "1" ]] && echo "    scan_ssid=1"
                echo "}"
                ;;
            open)
                echo "network={"
                echo "    ssid=\"$escaped_essid\""
                echo "    key_mgmt=NONE"
                [[ "$hidden" == "1" ]] && echo "    scan_ssid=1"
                echo "}"
                ;;
            *)
                return 1
                ;;
        esac
    } >> "$WPA_CONF"

    chmod 600 "$WPA_CONF"
    sync
}

start_dhcp_lease_request() {
    if command_exists udhcpc; then
        run_with_timeout "$IPV4_WAIT_SECONDS" udhcpc -n -q -i "$INTERFACE" -T 3 -t 5 >/dev/null 2>&1 &
        return 0
    elif command_exists dhclient; then
        run_with_timeout "$IPV4_WAIT_SECONDS" dhclient "$INTERFACE" >/dev/null 2>&1 &
        return 0
    fi

    return 0
}

reload_wpa_supplicant() {
    if command_exists wpa_cli && wpa_cli -i "$INTERFACE" reconfigure >/dev/null 2>&1; then
        wpa_cli -i "$INTERFACE" reassociate >/dev/null 2>&1 || wpa_cli -i "$INTERFACE" reconnect >/dev/null 2>&1 || true
        return 0
    fi

    if command_exists pkill; then
        pkill -x wpa_supplicant >/dev/null 2>&1 || true
    elif command_exists killall; then
        killall wpa_supplicant >/dev/null 2>&1 || true
    fi

    if command_exists wpa_supplicant; then
        wpa_supplicant -B -i "$INTERFACE" -c "$WPA_CONF" >/dev/null 2>&1 || return 1
        return 0
    fi

    return 1
}

current_ip() {
    ip -4 addr show "$INTERFACE" 2>/dev/null | awk '/inet / { print $2; exit }' | cut -d/ -f1
}

current_ssid() {
    iwgetid -r "$INTERFACE" 2>/dev/null || true
}

ssh_client_ip() {
    local client=""

    if [[ -n "${SSH_CLIENT:-}" ]]; then
        client="${SSH_CLIENT%% *}"
    elif [[ -n "${SSH_CONNECTION:-}" ]]; then
        client="${SSH_CONNECTION%% *}"
    fi

    [[ "$client" =~ ^[0-9]+(\.[0-9]+){3}$ ]] || return 0
    echo "$client"
}

preserve_ssh_client_route() {
    local client route dev via src
    local cmd

    client=$(ssh_client_ip)
    [[ -n "$client" ]] || return 0

    route=$(ip route get "$client" 2>/dev/null | head -1) || return 0
    dev=$(printf '%s\n' "$route" | awk '{ for (idx = 1; idx <= NF; idx++) if ($idx == "dev" && idx < NF) { print $(idx + 1); exit } }')
    via=$(printf '%s\n' "$route" | awk '{ for (idx = 1; idx <= NF; idx++) if ($idx == "via" && idx < NF) { print $(idx + 1); exit } }')
    src=$(printf '%s\n' "$route" | awk '{ for (idx = 1; idx <= NF; idx++) if ($idx == "src" && idx < NF) { print $(idx + 1); exit } }')

    [[ -n "$dev" ]] || return 0
    [[ "$dev" != "$INTERFACE" ]] || return 0

    cmd=(ip route replace "${client}/32")
    [[ -n "$via" ]] && cmd+=(via "$via")
    cmd+=(dev "$dev")
    [[ -n "$src" ]] && cmd+=(src "$src")

    "${cmd[@]}" >/dev/null 2>&1 || true
}

find_wireless_interface_once() {
    local path

    if [[ -d "/sys/class/net/$INTERFACE" && -d "/sys/class/net/$INTERFACE/wireless" ]]; then
        echo "$INTERFACE"
        return 0
    fi

    if [[ -d "/sys/class/net/wlan0/wireless" ]]; then
        echo "wlan0"
        return 0
    fi

    for path in /sys/class/net/*; do
        [[ -d "$path/wireless" ]] || continue
        basename "$path"
        return 0
    done

    return 1
}

find_wireless_interface() {
    local timeout="${1:-$INTERFACE_DETECT_TIMEOUT_SECONDS}"
    local seconds=0
    local detected_interface

    show_infobox "Detecting WiFi adapter.\nPlease wait..."

    while true; do
        detected_interface=$(find_wireless_interface_once) && {
            echo "$detected_interface"
            return 0
        }

        [[ "$seconds" -ge "$timeout" ]] && return 1
        sleep 1
        seconds=$((seconds + 1))
    done
}

wait_for_association() {
    local target_ssid="$1"
    local seconds=0
    local ssid

    while [[ "$seconds" -lt "$ASSOCIATION_WAIT_SECONDS" ]]; do
        ssid=$(current_ssid)

        if [[ -n "$ssid" ]]; then
            if [[ -n "$target_ssid" && "$ssid" != "$target_ssid" ]]; then
                sleep 1
                seconds=$((seconds + 1))
                continue
            fi
            echo "$ssid"
            return 0
        fi

        sleep 1
        seconds=$((seconds + 1))
    done

    return 1
}

wait_for_ipv4_lease() {
    local seconds=0
    local ip

    while [[ "$seconds" -lt "$IPV4_WAIT_SECONDS" ]]; do
        ip=$(current_ip)

        if [[ -n "$ip" ]]; then
            echo "$ip"
            return 0
        fi

        sleep 1
        seconds=$((seconds + 1))
    done

    return 1
}

default_gateway() {
    ip route show default 2>/dev/null | awk -v iface="$INTERFACE" '
        /^default/ {
            gw = ""
            dev = ""

            for (idx = 1; idx <= NF; idx++) {
                if ($idx == "via" && idx < NF) {
                    gw = $(idx + 1)
                } else if ($idx == "dev" && idx < NF) {
                    dev = $(idx + 1)
                }
            }

            if (dev == iface && gw != "") {
                print gw
                found = 1
                exit
            }

            if (fallback == "" && gw != "") {
                fallback = gw
            }
        }

        END {
            if (!found && fallback != "") {
                print fallback
            }
        }
    '
}

ping_once() {
    command_exists ping || return 2
    ping -c 1 -W 2 "$1" >/dev/null 2>&1
}

dns_lookup_ok() {
    if command_exists nslookup; then
        nslookup misterfpga.org >/dev/null 2>&1
        return $?
    fi

    ping_once misterfpga.org
}

connection_health_report() {
    local ssid ip gateway gateway_status internet_status dns_status

    ssid=$(current_ssid)
    ip=$(current_ip)
    gateway=$(default_gateway)

    [[ -z "$ssid" ]] && ssid="(not connected)"
    [[ -z "$ip" ]] && ip="(no IPv4 lease)"
    [[ -z "$gateway" ]] && gateway="(none)"

    gateway_status="not available"
    if [[ "$gateway" != "(none)" ]]; then
        if ping_once "$gateway"; then
            gateway_status="OK"
        else
            gateway_status="not responding"
        fi
    fi

    if ping_once 1.1.1.1; then
        internet_status="OK"
    else
        internet_status="not verified"
    fi

    if dns_lookup_ok; then
        dns_status="OK"
    else
        dns_status="not verified"
    fi

    printf 'Health check:\n'
    printf 'SSID: %s\n' "$ssid"
    printf 'IPv4: %s\n' "$ip"
    printf 'Gateway: %s\n' "$gateway"
    printf 'Gateway ping: %s\n' "$gateway_status"
    printf 'Internet ping: %s\n' "$internet_status"
    printf 'DNS lookup: %s' "$dns_status"
}

disconnect_wifi() {
    local ssid ip_addr

    show_infobox "Disconnecting WiFi.\nPlease wait..."
    detect_interface || return 1

    ssid=$(current_ssid)
    ip_addr=$(current_ip)

    [[ -z "$ssid" ]] && ssid="(not connected)"
    [[ -z "$ip_addr" ]] && ip_addr="(no IPv4 lease)"

    if command_exists wpa_cli; then
        run_with_timeout "$DISCONNECT_TIMEOUT_SECONDS" wpa_cli -i "$INTERFACE" disconnect >/dev/null 2>&1 || true
    fi

    if command_exists iw; then
        run_with_timeout "$DISCONNECT_TIMEOUT_SECONDS" iw dev "$INTERFACE" disconnect >/dev/null 2>&1 || true
    fi

    run_with_timeout "$DISCONNECT_TIMEOUT_SECONDS" ip addr flush dev "$INTERFACE" >/dev/null 2>&1 || true

    printMsgs "dialog" "Disconnected WiFi.\n\nInterface: $INTERFACE\nPrevious network: $ssid\nPrevious IPv4: $ip_addr\n\nSaved networks were not changed."
}

apply_wifi_settings() {
    local target_ssid="$1"
    local target_label settings_label ssid ip health

    if [[ -n "$target_ssid" ]]; then
        target_label="$target_ssid"
        settings_label="Saved WiFi settings for $target_ssid"
    else
        target_label="saved WiFi network"
        settings_label="Saved WiFi settings"
    fi

    warn_if_cifs_boot_hooks_exist
    set_interface_state up || return 1

    if ! reload_wpa_supplicant; then
        printMsgs "dialog" "Unable to reload wpa_supplicant for $INTERFACE."
        return 1
    fi

    show_infobox "Connecting $INTERFACE to $target_label..."
    ssid=$(wait_for_association "$target_ssid") || {
        printMsgs "dialog" "$settings_label are present, but $INTERFACE did not associate within ${ASSOCIATION_WAIT_SECONDS} seconds.\n\nIf the adapter is valid and the password is correct, try waiting a bit longer or rebooting."
        return 1
    }

    show_infobox "Requesting an IP address for $INTERFACE..."
    preserve_ssh_client_route
    start_dhcp_lease_request
    ip=$(wait_for_ipv4_lease) || {
        printMsgs "dialog" "$INTERFACE connected to $ssid, but MiSTer did not receive an IPv4 address within ${IPV4_WAIT_SECONDS} seconds."
        return 1
    }

    health=$(connection_health_report)
    printMsgs "dialog" "Successfully connected.\n\nInterface: $INTERFACE\nNetwork: $ssid\nIP address: $ip\n\n$health"
    return 0
}

prompt_for_key() {
    local type="$1"
    local essid="$2"
    local key=""
    local key_ok=0

    while [[ "$key_ok" -eq 0 ]]; do
        key=$(capture_dialog dialog --backtitle "$__backtitle" --insecure --passwordbox "Enter the WiFi password for:\n$essid" 10 64) || return 1
        key_ok=1

        if [[ "$type" == "wpa" && ( ${#key} -lt 8 || ${#key} -gt 63 ) ]]; then
            printMsgs "dialog" "WPA passwords must be between 8 and 63 characters."
            key_ok=0
        fi

        if [[ "$type" == "wep" && -z "$key" ]]; then
            printMsgs "dialog" "WEP keys cannot be empty."
            key_ok=0
        fi
    done

    printf '%s' "$key"
}

connect_saved_wifi() {
    local saved_count

    show_infobox "Connecting to WiFi.\nPlease wait..."
    require_tools || return 1
    detect_interface || return 1
    ensure_wpa_conf
    validate_wpa_conf || return 1

    saved_count=$(saved_networks | awk 'END { print NR + 0 }')
    if [[ "$saved_count" -eq 0 ]]; then
        printMsgs "dialog" "No saved WiFi networks were found in $WPA_CONF.\n\nUse Scan and connect first to save a network."
        return 1
    fi

    apply_wifi_settings ""
}

connect_wifi() {
    local networks=()
    local types=()
    local labels=()
    local raw options=()
    local line essid type signal quality choice hidden key colored_label
    local index=0

    show_infobox "Preparing WiFi setup.\nPlease wait..."
    require_tools || return 1
    detect_interface || return 1
    prompt_country_code || return 1

    while IFS=$'\t' read -r essid type signal quality; do
        networks+=("$essid")
        types+=("$type")
        labels+=("$signal")
        colored_label=$(colorize_menu_label "$quality" "$essid" "$type")
        options+=("$index" "$colored_label")
        index=$((index + 1))
    done < <(list_wifi)

    if [[ ${#networks[@]} -eq 0 ]]; then
        printMsgs "dialog" "No visible WiFi networks were found.\n\nIf your network is hidden, choose the hidden network option."
        return 1
    fi

    options+=("H" "Hidden network")

    choice=$(capture_dialog dialog --colors --backtitle "$__backtitle" --menu "Choose the WiFi network you would like to connect to:" 22 76 16 "${options[@]}") || return 1

    hidden=0
    if [[ "$choice" == "H" ]]; then
        essid=$(capture_dialog dialog --backtitle "$__backtitle" --inputbox "Enter the hidden network SSID:" 10 60) || return 1
        [[ -n "$essid" ]] || return 1
        type=$(capture_dialog dialog --backtitle "$__backtitle" --menu "Choose the network security type:" 14 44 6 wpa "WPA / WPA2" wep "WEP" open "Open") || return 1
        hidden=1
    else
        essid="${networks[$choice]}"
        type="${types[$choice]}"
    fi

    key=""
    if [[ "$type" == "wpa" || "$type" == "wep" ]]; then
        key=$(prompt_for_key "$type" "$essid") || return 1
    fi

    append_network_config "$type" "$essid" "$key" "$hidden" || {
        printMsgs "dialog" "Failed to save WiFi settings for $essid."
        return 1
    }

    apply_wifi_settings "$essid"
}

remove_saved_network() {
    local networks=()
    local options=()
    local line index ssid choice

    ensure_wpa_conf
    validate_wpa_conf || return 1

    while IFS=$'\t' read -r index ssid; do
        networks+=("$ssid")
        options+=("$index" "$ssid")
    done < <(saved_networks)

    if [[ ${#networks[@]} -eq 0 ]]; then
        printMsgs "dialog" "No saved WiFi networks were found in $WPA_CONF."
        return 0
    fi

    choice=$(capture_dialog dialog --backtitle "$__backtitle" --menu "Select a saved network to remove:" 20 70 12 "${options[@]}") || return 0
    ssid="${networks[$choice]}"

    capture_dialog dialog --backtitle "$__backtitle" --yes-label "Remove" --no-label "Cancel" --yesno "Remove this saved WiFi network?\n\n$ssid\n\nThis only removes the saved network from $WPA_CONF." 12 70 || return 0

    remove_network_by_ssid "$ssid"
    printMsgs "dialog" "Removed saved network:\n$ssid"
}

saved_networks_menu() {
    local networks=()
    local options=()
    local index ssid choice default_item="0" next_default

    while true; do
        networks=()
        options=()

        ensure_wpa_conf
        validate_wpa_conf || return 1

        while IFS=$'\t' read -r index ssid; do
            networks+=("$ssid")
            options+=("$index" "$ssid")
        done < <(saved_networks)

        if [[ ${#networks[@]} -eq 0 ]]; then
            printMsgs "dialog" "No saved WiFi networks were found in $WPA_CONF."
            return 0
        fi

        if [[ "$default_item" -ge ${#networks[@]} ]]; then
            default_item="$(( ${#networks[@]} - 1 ))"
        fi

        choice=$(capture_dialog dialog --backtitle "$__backtitle" --ok-label "Remove" --cancel-label "Back" --default-item "$default_item" --menu "Saved networks in $WPA_CONF\n\nSelect a network and choose Remove." 22 76 14 "${options[@]}") || return 0
        ssid="${networks[$choice]}"

        capture_dialog dialog --backtitle "$__backtitle" --yes-label "Remove" --no-label "Cancel" --yesno "Remove this saved WiFi network?\n\n$ssid\n\nThis only removes the saved network from $WPA_CONF." 12 70 || {
            default_item="$choice"
            continue
        }

        next_default="$choice"
        remove_network_by_ssid "$ssid"
        printMsgs "dialog" "Removed saved network:\n$ssid"
        default_item="$next_default"
    done
}

show_saved_networks() {
    saved_networks_menu
}

show_status() {
    local ssid ip country

    detect_interface || return 1
    ensure_wpa_conf

    ssid=$(current_ssid)
    ip=$(current_ip)
    country=$(get_country_code)

    [[ -z "$ssid" ]] && ssid="(not connected)"
    [[ -z "$ip" ]] && ip="(no IPv4 lease)"
    [[ -z "$country" ]] && country="(missing)"

    printMsgs "dialog" "Interface: $INTERFACE\nCountry: $country\nConnected SSID: $ssid\nIPv4 address: $ip"
}

diagnose_wifi() {
    local detected_interface country error networks

    echo "MiSTer WiFi diagnostics"
    echo "Script: $0"
    echo "WPA config: $WPA_CONF"
    echo "Requested interface: $INTERFACE"
    echo "Timeouts: adapter=${INTERFACE_DETECT_TIMEOUT_SECONDS}s scan=${SCAN_TIMEOUT_SECONDS}s association=${ASSOCIATION_WAIT_SECONDS}s ipv4=${IPV4_WAIT_SECONDS}s disconnect=${DISCONNECT_TIMEOUT_SECONDS}s"
    echo

    detected_interface=$(find_wireless_interface 2>/dev/null || true)
    if [[ -n "$detected_interface" ]]; then
        INTERFACE="$detected_interface"
        echo "Detected wireless interface: $INTERFACE"
        echo "Current SSID: $(current_ssid)"
        echo "Current IPv4: $(current_ip)"
    else
        echo "Detected wireless interface: (none)"
    fi

    if [[ -f "$WPA_CONF" ]]; then
        country=$(get_country_code)
        [[ -z "$country" ]] && country="(missing)"
        echo "Country: $country"
        error=$(wpa_conf_validation_error)
        if [[ -n "$error" ]]; then
            echo "WPA config parse: ERROR - $error"
        else
            echo "WPA config parse: OK"
            networks=$(saved_networks)
            if [[ -n "$networks" ]]; then
                echo "Saved networks:"
                echo "$networks" | sed 's/^[0-9][0-9]*[[:space:]]*/- /'
            else
                echo "Saved networks: (none)"
            fi
        fi
    else
        echo "Country: (config missing)"
        echo "WPA config parse: config missing"
    fi

    echo
    echo "--- Connection health ---"
    if [[ -n "$detected_interface" ]]; then
        connection_health_report
        echo
    else
        echo "No wireless interface available for health check."
    fi

    echo
    echo "--- /sys/class/net ---"
    ls -l /sys/class/net 2>&1 || true

    echo
    echo "--- IPv4 addresses ---"
    ip -o -4 addr show 2>&1 || true

    echo
    echo "--- Wireless devices ---"
    if command_exists iw; then
        iw dev 2>&1 || true
    else
        echo "iw not installed"
    fi

    echo
    echo "--- USB devices ---"
    if command_exists lsusb; then
        lsusb 2>&1 || true
    else
        echo "lsusb not installed"
    fi

    echo
    echo "--- Adapter hints ---"
    if [[ -n "$(realtek_storage_devices)" ]]; then
        echo "Realtek adapter appears stuck in USB storage mode:"
        realtek_storage_devices
		echo "Recovery hint: Unplug and reinsert the dongle."
    elif [[ -n "$(wifi_like_usb_devices)" ]]; then
        echo "WiFi-like USB devices found:"
        wifi_like_usb_devices
    else
        echo "No obvious USB WiFi device found."
    fi

    echo
    echo "--- Relevant dmesg ---"
    if command_exists dmesg; then
        dmesg 2>/dev/null | grep -Ei '1a2b|c820|331d|8821|88x2|rtl|realtek|wlan|wifi|wireless|802\.11|cfg80211|firmware|usb 1-|disconnect|udevd' | tail -120
    else
        echo "dmesg not installed"
    fi
}

show_diagnostics() {
    local report

    report=$(diagnose_wifi)
    printMsgs "dialog" "$report"
}

save_diagnostics() {
    local output="${1:-$DIAGNOSE_FILE}"
    local output_dir

    output_dir=$(dirname "$output")
    mkdir -p "$output_dir" 2>/dev/null || {
        printMsgs "dialog" "Unable to create diagnostics directory:\n$output_dir"
        return 1
    }

    diagnose_wifi > "$output" || {
        printMsgs "dialog" "Unable to write diagnostics file:\n$output"
        return 1
    }

    chmod 644 "$output" 2>/dev/null || true
    sync
    printMsgs "dialog" "Saved WiFi diagnostics to:\n$output"
}

main_menu() {
    local choice current current_ip_addr default_item="1"

    while true; do
        current=$(current_ssid)
        current_ip_addr=$(current_ip)

        [[ -z "$current" ]] && current="(not connected)"
        [[ -z "$current_ip_addr" ]] && current_ip_addr="(no IPv4 lease)"

        choice=$(capture_dialog dialog --backtitle "$__backtitle" --cancel-label "Exit" --default-item "$default_item" --menu "MiSTer WiFi tools\n\nCurrent network: $current\nCurrent IPv4: $current_ip_addr" 22 72 13 \
            1 "Scan and connect" \
            2 "Connect to WiFi" \
            3 "Saved Networks" \
            4 "Disconnect from WiFi" \
            5 "Set / fix country code" \
            6 "Show WiFi status" \
            7 "Diagnostics" \
            8 "Save diagnostics to file" \
            9 "Repair WPA config") || break

        default_item="$choice"

        case "$choice" in
            1)
                connect_wifi
                ;;
            2)
                connect_saved_wifi
                ;;
            3)
                saved_networks_menu
                ;;
            4)
                disconnect_wifi
                ;;
            5)
                prompt_country_code 1
                ;;
            6)
                show_status
                ;;
            7)
                show_diagnostics
                ;;
            8)
                save_diagnostics
                ;;
            9)
                repair_wpa_conf
                ;;
        esac
    done
}

main() {
    case "${1:-}" in
        --reconnect|--connect-saved)
            __nodialog=1
            connect_saved_wifi
            ;;
        --connect)
            connect_wifi
            ;;
        --remove)
            remove_saved_network
            ;;
        --disconnect)
            __nodialog=1
            disconnect_wifi
            ;;
        --status)
            __nodialog=1
            show_status
            ;;
        --health)
            __nodialog=1
            detect_interface || return 1
            connection_health_report
            echo
            ;;
        --diagnose|--diagnostics)
            __nodialog=1
            show_diagnostics
            ;;
        --diagnose-file|--diagnostics-file)
            __nodialog=1
            save_diagnostics "${2:-$DIAGNOSE_FILE}"
            ;;
        --repair-config)
            __nodialog=1
            repair_wpa_conf
            ;;
        ""|--menu)
            main_menu
            ;;
        *)
            printMsgs "console" "Usage: $0 [--menu|--reconnect|--connect|--disconnect|--remove|--status|--health|--diagnose|--diagnose-file [path]|--repair-config]"
            return 1
            ;;
    esac
}

RETURN_TO_MENU=0
case "${1:-}" in
    ""|--menu)
        RETURN_TO_MENU=1
        ;;
esac

main "$@"
STATUS=$?
close_dialog_screen

if [[ "$STATUS" -eq 0 && "$RETURN_TO_MENU" -eq 1 ]]; then
    return_to_mister_menu
fi

exit "$STATUS"
