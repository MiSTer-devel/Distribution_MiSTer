#!/usr/bin/env bash

# This file is part of the MiSTer FPGA Project.
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed
# with the original source.
#
# This derivative is distributed under the GNU General Public License,
# version 3 or later. The original license is available at:
# https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# MiSTer WiFi helper based on the RetroPie-derived wifi.sh.
#
# Changelog:
# Version 2.3.0 - 2026-07-27 - Makes config updates transactional and preserves valid custom settings.
#                            - Uses MiSTer's running DHCP manager, rejects stale leases, and scopes WiFi recovery.
#                            - Applies the regulatory domain before scanning and restores hidden-only setup.
#                            - Adds headless dependency handling and a testable library mode.
#                            - Consolidates status into diagnostics and adds signal, link-rate, and traffic-counter metrics.
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
WPA_WORK_FILE=""
WPA_ROLLBACK_FILE=""
WPA_ROLLBACK_ACTIVE=0
WPA_ROLLBACK_SSID=""
WPA_REENABLE_IDS=()
WPA_SELECTION_ACTIVE=0

cleanup_wpa_work_file() {
    if [[ -n "$WPA_WORK_FILE" ]]; then
        rm -f "$WPA_WORK_FILE" 2>/dev/null || true
        WPA_WORK_FILE=""
    fi
}

begin_wpa_rollback() {
    local previous_ssid="${1:-}"

    [[ "$WPA_ROLLBACK_ACTIVE" -eq 0 ]] || return 1
    if [[ -n "$WPA_ROLLBACK_FILE" ]]; then
        discard_wpa_rollback || return 1
    fi
    [[ -f "$WPA_CONF" ]] || return 1

    WPA_ROLLBACK_FILE=$(mktemp "${WPA_CONF}.rollback.XXXXXX") || {
        WPA_ROLLBACK_FILE=""
        return 1
    }
    cp -p "$WPA_CONF" "$WPA_ROLLBACK_FILE" 2>/dev/null || {
        rm -f "$WPA_ROLLBACK_FILE" 2>/dev/null || true
        WPA_ROLLBACK_FILE=""
        return 1
    }
    chmod 600 "$WPA_ROLLBACK_FILE" || {
        rm -f "$WPA_ROLLBACK_FILE" 2>/dev/null || true
        WPA_ROLLBACK_FILE=""
        return 1
    }
    WPA_ROLLBACK_ACTIVE=1
    WPA_ROLLBACK_SSID="$previous_ssid"
}

restore_wpa_rollback() {
    [[ "$WPA_ROLLBACK_ACTIVE" -eq 1 && -n "$WPA_ROLLBACK_FILE" && -f "$WPA_ROLLBACK_FILE" ]] || return 1
    chmod 600 "$WPA_ROLLBACK_FILE" || return 1
    mv -f "$WPA_ROLLBACK_FILE" "$WPA_CONF" || return 1
    WPA_ROLLBACK_FILE=""
    WPA_ROLLBACK_ACTIVE=0
    sync || true
    return 0
}

discard_wpa_rollback() {
    [[ -n "$WPA_ROLLBACK_FILE" ]] || {
        WPA_ROLLBACK_ACTIVE=0
        WPA_ROLLBACK_SSID=""
        return 0
    }
    if ! rm -f "$WPA_ROLLBACK_FILE" 2>/dev/null; then
        WPA_ROLLBACK_ACTIVE=0
        WPA_ROLLBACK_SSID=""
        return 1
    fi
    WPA_ROLLBACK_FILE=""
    WPA_ROLLBACK_ACTIVE=0
    WPA_ROLLBACK_SSID=""
}

cleanup() {
    cleanup_wpa_work_file
    if [[ "$WPA_SELECTION_ACTIVE" -eq 1 ]]; then
        restore_network_enable_state >/dev/null 2>&1 ||
            reload_wpa_supplicant >/dev/null 2>&1 ||
            true
    fi
    if [[ "$WPA_ROLLBACK_ACTIVE" -eq 1 ]]; then
        if restore_wpa_rollback >/dev/null 2>&1; then
            recover_previous_wifi_connection "$WPA_ROLLBACK_SSID" >/dev/null 2>&1 ||
                reload_wpa_supplicant >/dev/null 2>&1 ||
                true
        fi
        WPA_ROLLBACK_SSID=""
    elif [[ -n "$WPA_ROLLBACK_FILE" ]]; then
        rm -f "$WPA_ROLLBACK_FILE" 2>/dev/null || true
        WPA_ROLLBACK_FILE=""
    fi
    WPA_ROLLBACK_SSID=""
}

if [[ "${WIFI_LIBRARY_ONLY:-0}" != "1" ]]; then
    trap cleanup EXIT
fi

sanitize_control_text() {
    local text="$1"
    local code hex control

    for ((code = 1; code < 32; code++)); do
        [[ "$code" -eq 9 || "$code" -eq 10 ]] && continue
        printf -v hex '%02X' "$code"
        printf -v control '%b' "\\x$hex"
        text="${text//$control/\\x$hex}"
    done
    control=$'\x7f'
    text="${text//$control/\\x7F}"
    printf '%s' "$text"
}

print_console_text() {
    local text

    text=$(sanitize_control_text "$1")
    text="${text//\\n/$'\n'}"
    printf '%s\n' "$text"
}

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
        [[ "$type" == "console" ]] && print_console_text "$msg"
        if [[ "$type" == "heading" ]]; then
            printf '\n= = = = = = = = = = = = = = = = = = = = =\n'
            print_console_text "$msg"
            printf '= = = = = = = = = = = = = = = = = = = = =\n\n'
        fi
    done

    return 0
}

show_infobox() {
    if [[ "$__nodialog" != "1" ]] && dialog_ui_available; then
        run_dialog dialog --backtitle "$__backtitle" --infobox "\n$1" 5 56
    else
        print_console_text "$1" >&2
    fi
}

close_dialog_screen() {
    [[ "$__nodialog" == "1" ]] && return 0

    if dialog_tty_available; then
        stty sane < "$DIALOG_TTY" 2>/dev/null || true
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
        # dialog draws on the tty selected through stdout and returns its value
        # through the original stdout captured by the caller.
        "$@" 3>&1 1> "$DIALOG_TTY" 2>&3 3>&-
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

make_wpa_temp() {
    local output_dir output_name

    cleanup_wpa_work_file
    output_dir=$(dirname "$WPA_CONF")
    output_name=$(basename "$WPA_CONF")
    mkdir -p "$output_dir" 2>/dev/null || return 1
    WPA_WORK_FILE=$(mktemp "${output_dir}/.${output_name}.tmp.XXXXXX") || {
        WPA_WORK_FILE=""
        return 1
    }
}

commit_wpa_temp() {
    [[ -n "$WPA_WORK_FILE" && -f "$WPA_WORK_FILE" ]] || return 1

    chmod 600 "$WPA_WORK_FILE" || {
        cleanup_wpa_work_file
        return 1
    }
    mv -f "$WPA_WORK_FILE" "$WPA_CONF" || {
        cleanup_wpa_work_file
        return 1
    }
    WPA_WORK_FILE=""
    sync || true
    return 0
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
    local mode="${1:-scan}"
    local missing=()
    local tool
    local tools=(awk grep ip iwgetid od sed tr)

    case "$mode" in
        scan)
            tools+=(dialog iw iwlist sort)
            ;;
        reconnect)
            ;;
        *)
            return 2
            ;;
    esac

    for tool in "${tools[@]}"; do
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
    [[ -f "$WPA_CONF" ]] && return 0

    make_wpa_temp || return 1
    if ! cat > "$WPA_WORK_FILE" <<'EOF'
ctrl_interface=/run/wpa_supplicant
update_config=1

EOF
    then
        cleanup_wpa_work_file
        return 1
    fi
    commit_wpa_temp
}

wpa_conf_validation_error() {
    local file="${1:-$WPA_CONF}"

    [[ -f "$file" ]] || return 0

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

        function structural(s, first_quote, last_quote, idx, suffix, comment_at) {
            s = trim(s)
            first_quote = index(s, "\"")
            last_quote = 0
            if (first_quote > 0) {
                for (idx = length(s); idx > first_quote; idx--) {
                    if (substr(s, idx, 1) == "\"") {
                        last_quote = idx
                        break
                    }
                }
            }
            suffix = substr(s, last_quote > first_quote ? last_quote + 1 : 1)
            comment_at = index(suffix, "#")
            if (comment_at > 0) {
                s = substr(s, 1, (last_quote > first_quote ? last_quote : 0) + comment_at - 1)
            }
            return trim(s)
        }

        function config_block_kind(s) {
            s = structural(s)
            if (s == "network={") {
                return "network"
            }
            if (s == "cred={" || s ~ /^blob-base64-[^=]+=\{$/) {
                return "opaque"
            }
            if (s ~ /^[^=]+=[[:space:]]*\{$/) {
                return "invalid"
            }
            return ""
        }

        function quoted_value_complete(value) {
            value = trim(value)
            if (substr(value, 1, 2) == "P\"") {
                return length(value) >= 3 && substr(value, length(value), 1) == "\""
            }
            if (substr(value, 1, 1) != "\"") {
                return 1
            }
            return length(value) >= 2 && substr(value, length(value), 1) == "\""
        }

        function ssid_value_complete(value) {
            value = trim(value)
            if (substr(value, 1, 1) == "\"" || substr(value, 1, 2) == "P\"") {
                return quoted_value_complete(value)
            }
            return value ~ /^[[:xdigit:]]+$/ && (length(value) % 2) == 0 && length(value) <= 64
        }

        BEGIN {
            in_block = 0
            block_start = 0
            saw_ssid = 0
            is_network = 0
            country_count = 0
            error = ""
        }

        {
            line = trim($0)
            structure = structural($0)
            kind = config_block_kind($0)
            if (!in_block && line ~ /^country[[:space:]]*=/) {
                country_count++
            }
            if (kind != "") {
                if (in_block) {
                    if (error == "") {
                        error = "nested config block near line " NR
                    }
                    next
                }
                in_block = 1
                block_start = NR
                saw_ssid = 0
                is_network = (kind == "network")
                if (kind == "invalid" && error == "") {
                    error = "invalid config block header near line " NR
                }
                next
            }

            if (!in_block && structure == "}" && error == "") {
                error = "unmatched closing brace near line " NR
            }
            if (in_block && is_network && structure ~ /^ssid[[:space:]]*=/) {
                value = structure
                sub(/^ssid[[:space:]]*=[[:space:]]*/, "", value)
                value = trim(value)
                if ((value == "" || value == "\"\"" || value == "P\"\"") && error == "") {
                    error = "empty SSID near line " NR
                } else {
                    saw_ssid = 1
                }
                if (value != "" && !ssid_value_complete(value) && error == "") {
                    error = "invalid or unterminated SSID near line " NR
                }
            }
            if (in_block && structure ~ /^[[:alnum:]_.-]+[[:space:]]*=/ && error == "") {
                value = structure
                sub(/^[[:alnum:]_.-]+[[:space:]]*=[[:space:]]*/, "", value)
                value = trim(value)
                if ((substr(value, 1, 1) == "\"" || substr(value, 1, 2) == "P\"") &&
                    !quoted_value_complete(value)) {
                    error = "unterminated quoted value near line " NR
                }
            }
            if (in_block && structure == "}") {
                if (is_network && !saw_ssid && error == "") {
                    error = "network block without SSID near line " block_start
                }
                in_block = 0
                block_start = 0
                saw_ssid = 0
                is_network = 0
            }
        }

        END {
            if (in_block && error == "") {
                if (is_network) {
                    error = "unclosed network block starting near line " block_start
                } else {
                    error = "unclosed config block starting near line " block_start
                }
            }
            if (country_count > 1 && error == "") {
                error = "multiple country headers"
            }
            if (error != "") {
                print error
            }
        }
    ' "$file"
}

top_level_country_headers() {
    local file="$1"

    [[ -f "$file" ]] || return 0

    awk '
        function trim(s) {
            sub(/^[[:space:]]+/, "", s)
            sub(/[[:space:]\r]+$/, "", s)
            return s
        }

        function structural(s, first_quote, last_quote, idx, suffix, comment_at) {
            s = trim(s)
            first_quote = index(s, "\"")
            last_quote = 0
            if (first_quote > 0) {
                for (idx = length(s); idx > first_quote; idx--) {
                    if (substr(s, idx, 1) == "\"") {
                        last_quote = idx
                        break
                    }
                }
            }
            suffix = substr(s, last_quote > first_quote ? last_quote + 1 : 1)
            comment_at = index(suffix, "#")
            if (comment_at > 0) {
                s = substr(s, 1, (last_quote > first_quote ? last_quote : 0) + comment_at - 1)
            }
            return trim(s)
        }

        function is_block_header(s) {
            s = structural(s)
            if (s == "network={" ||
                s == "cred={" ||
                s ~ /^blob-base64-[^=]+=\{$/ ||
                s ~ /^[^=]+=[[:space:]]*\{$/) {
                return 1
            }
            return 0
        }

        {
            line = trim($0)
            structure = structural($0)
            if (!in_block && is_block_header($0)) {
                in_block = 1
                next
            }
            if (in_block) {
                if (structure == "}") {
                    in_block = 0
                }
                next
            }
            if (line ~ /^country[[:space:]]*=/) {
                print
            }
        }
    ' "$file"
}

get_country_code_from_file() {
    local file="$1"

    top_level_country_headers "$file" | awk -F= '
        {
            value = $2
            sub(/[[:space:]]*#.*/, "", value)
            gsub(/[[:space:]"\r]/, "", value)
            value = toupper(value)

            if (!found && value ~ /^[A-Z][A-Z]$/) {
                result = value
                found = 1
            }
        }

        END {
            if (found) {
                print result
            }
        }
    '
}

get_country_code() {
    get_country_code_from_file "$WPA_CONF"
}

has_country_header() {
    local file="$1"

    [[ -n "$(top_level_country_headers "$file")" ]]
}

first_country_header() {
    local file="$1"

    top_level_country_headers "$file" | awk '
        NR == 1 {
            first = $0
        }
        END {
            if (first != "") {
                print first
            }
        }
    '
}

raw_country_code_from_file() {
    local file="$1"

    top_level_country_headers "$file" | awk -F= '
        !found {
            value = $2
            sub(/[[:space:]]*#.*/, "", value)
            gsub(/[^[:alnum:]]/, "", value)
            result = toupper(value)
            found = 1
        }
        END {
            if (found) {
                print result
            }
        }
    '
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
    local error country raw_country repaired_country backup preserved

    ensure_wpa_conf || return 1
    error=$(wpa_conf_validation_error)

    if [[ -z "$error" ]]; then
        printMsgs "dialog" "$WPA_CONF looks OK. No repair needed."
        return 0
    fi

    backup=$(mktemp "${WPA_CONF}.bak.XXXXXX") || {
        printMsgs "dialog" "Unable to create a unique backup for $WPA_CONF.\n\nNo repair was made."
        return 1
    }
    cp -p "$WPA_CONF" "$backup" 2>/dev/null || {
        rm -f "$backup" 2>/dev/null || true
        printMsgs "dialog" "Unable to back up $WPA_CONF.\n\nNo repair was made."
        return 1
    }

    country=$(get_country_code_from_file "$backup")
    raw_country=$(raw_country_code_from_file "$backup")
    if ! is_valid_country_code "$country" && [[ -n "$raw_country" ]]; then
        repaired_country=$(repair_country_code "$raw_country")
        is_valid_country_code "$repaired_country" && country="$repaired_country"
    fi

    make_wpa_temp || {
        printMsgs "dialog" "Unable to create a temporary file for $WPA_CONF.\n\nBackup remains at:\n$backup"
        return 1
    }
    if ! {
        is_valid_country_code "$country" && printf 'country=%s\n' "$country"
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

            function structural(s, first_quote, last_quote, idx, suffix, comment_at) {
                s = trim(s)
                first_quote = index(s, "\"")
                last_quote = 0
                if (first_quote > 0) {
                    for (idx = length(s); idx > first_quote; idx--) {
                        if (substr(s, idx, 1) == "\"") {
                            last_quote = idx
                            break
                        }
                    }
                }
                suffix = substr(s, last_quote > first_quote ? last_quote + 1 : 1)
                comment_at = index(suffix, "#")
                if (comment_at > 0) {
                    s = substr(s, 1, (last_quote > first_quote ? last_quote : 0) + comment_at - 1)
                }
                return trim(s)
            }

            function config_block_kind(s) {
                s = structural(s)
                if (s == "network={") {
                    return "network"
                }
                if (s == "cred={" || s ~ /^blob-base64-[^=]+=\{$/) {
                    return "opaque"
                }
                if (s ~ /^[^=]+=[[:space:]]*\{$/) {
                    return "invalid"
                }
                return ""
            }

            function quoted_value_complete(value) {
                value = trim(value)
                if (substr(value, 1, 2) == "P\"") {
                    return length(value) >= 3 && substr(value, length(value), 1) == "\""
                }
                if (substr(value, 1, 1) != "\"") {
                    return 1
                }
                return length(value) >= 2 && substr(value, length(value), 1) == "\""
            }

            function ssid_value_complete(value) {
                value = trim(value)
                if (substr(value, 1, 1) == "\"" || substr(value, 1, 2) == "P\"") {
                    return quoted_value_complete(value)
                }
                return value ~ /^[[:xdigit:]]+$/ && (length(value) % 2) == 0 && length(value) <= 64
            }

            function finish_block() {
                if (!bad_block && (block_kind != "network" || saw_ssid)) {
                    printf "%s\n", block
                }
                in_block = 0
                bad_block = 0
                saw_ssid = 0
                block = ""
                depth = 0
                block_kind = ""
            }

            BEGIN {
                in_block = 0
                bad_block = 0
                saw_ssid = 0
                block = ""
                depth = 0
                block_kind = ""
            }

            {
                line = trim($0)
                structure = structural($0)
                kind = config_block_kind($0)

                if (kind != "") {
                    if (in_block) {
                        bad_block = 1
                        block = block $0 ORS
                        depth++
                        next
                    }

                    in_block = 1
                    bad_block = 0
                    saw_ssid = 0
                    block = $0 ORS
                    depth = 1
                    block_kind = kind
                    if (kind == "invalid") {
                        bad_block = 1
                    }
                    next
                }

                if (in_block) {
                    block = block $0 ORS

                    if (structure ~ /^[[:alnum:]_.-]+[[:space:]]*=/) {
                        value = structure
                        sub(/^[[:alnum:]_.-]+[[:space:]]*=[[:space:]]*/, "", value)
                        value = trim(value)
                        if ((substr(value, 1, 1) == "\"" || substr(value, 1, 2) == "P\"") &&
                            !quoted_value_complete(value)) {
                            bad_block = 1
                        }
                    }

                    if (block_kind == "network" && structure ~ /^ssid[[:space:]]*=/) {
                        value = structure
                        sub(/^ssid[[:space:]]*=[[:space:]]*/, "", value)
                        value = trim(value)
                        if (value == "" || value == "\"\"" || value == "P\"\"" ||
                            !ssid_value_complete(value)) {
                            bad_block = 1
                        } else {
                            saw_ssid = 1
                        }
                    }

                    if (structure == "}") {
                        depth--
                        if (depth == 0) {
                            finish_block()
                        }
                    }
                    next
                }

                if (line ~ /^country[[:space:]]*=/ || structure == "}") {
                    next
                }

                print
            }
        ' "$backup"
    } > "$WPA_WORK_FILE"; then
        cleanup_wpa_work_file
        printMsgs "dialog" "Unable to rebuild $WPA_CONF.\n\nBackup remains at:\n$backup"
        return 1
    fi

    error=$(wpa_conf_validation_error "$WPA_WORK_FILE")
    if [[ -n "$error" ]]; then
        cleanup_wpa_work_file
        printMsgs "dialog" "Unable to rebuild a valid $WPA_CONF:\n$error\n\nBackup remains at:\n$backup"
        return 1
    fi
    if ! commit_wpa_temp; then
        printMsgs "dialog" "Unable to replace $WPA_CONF.\n\nBackup remains at:\n$backup"
        return 1
    fi

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

    prompt_message="$WPA_CONF appears malformed:"$'\n\n'"$error"$'\n\n'"Repair can back up the current file, preserve valid top-level settings and complete saved network blocks, and drop malformed or incomplete blocks."$'\n\n'"Repair now?"
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
    [[ "$1" =~ ^[A-Z]{2}$ && "$1" != "ZZ" ]]
}

set_country_code() {
    local country="$1"
    local error

    is_valid_country_code "$country" || return 1
    ensure_wpa_conf || return 1
    error=$(wpa_conf_validation_error)
    if [[ -n "$error" && "$error" != "multiple country headers" ]]; then
        offer_wpa_config_repair "$error" || return 1
    fi
    make_wpa_temp || return 1

    if ! {
        printf 'country=%s\n\n' "$country"
        awk '
            function trim(s) {
                sub(/^[[:space:]]+/, "", s)
                sub(/[[:space:]\r]+$/, "", s)
                return s
            }

            function structural(s, first_quote, last_quote, idx, suffix, comment_at) {
                s = trim(s)
                first_quote = index(s, "\"")
                last_quote = 0
                if (first_quote > 0) {
                    for (idx = length(s); idx > first_quote; idx--) {
                        if (substr(s, idx, 1) == "\"") {
                            last_quote = idx
                            break
                        }
                    }
                }
                suffix = substr(s, last_quote > first_quote ? last_quote + 1 : 1)
                comment_at = index(suffix, "#")
                if (comment_at > 0) {
                    s = substr(s, 1, (last_quote > first_quote ? last_quote : 0) + comment_at - 1)
                }
                return trim(s)
            }

            function is_block_header(s) {
                s = structural(s)
                if (s == "network={" ||
                    s == "cred={" ||
                    s ~ /^blob-base64-[^=]+=\{$/ ||
                    s ~ /^[^=]+=[[:space:]]*\{$/) {
                    return 1
                }
                return 0
            }

            {
                line = trim($0)
                structure = structural($0)
                if (!in_block && is_block_header($0)) {
                    in_block = 1
                    print
                    next
                }
                if (in_block) {
                    print
                    if (structure == "}") {
                        in_block = 0
                    }
                    next
                }
                if (line ~ /^country[[:space:]]*=/) {
                    next
                }
                print
            }
        ' "$WPA_CONF"
    } > "$WPA_WORK_FILE"
    then
        cleanup_wpa_work_file
        return 1
    fi
    commit_wpa_temp
}

apply_regulatory_country() {
    local country="$1"
    local attempts=0

    is_valid_country_code "$country" || return 1
    command_exists iw || {
        printMsgs "dialog" "Unable to apply country=$country before scanning because iw is not installed."
        return 1
    }
    iw reg set "$country" >/dev/null 2>&1 || {
        printMsgs "dialog" "Unable to apply the WiFi regulatory country $country."
        return 1
    }

    while [[ "$attempts" -lt 3 ]]; do
        if iw reg get 2>/dev/null | awk -v wanted="$country" '
            $1 == "country" {
                code = $2
                sub(/:.*/, "", code)
                if (code == wanted) {
                    found = 1
                }
            }
            END {
                exit found ? 0 : 1
            }
        '; then
            return 0
        fi
        sleep 1
        attempts=$((attempts + 1))
    done

    printMsgs "dialog" "Kernel regulatory domain did not change to $country."
    return 1
}

prompt_country_code() {
    local force_prompt="${1:-0}"
    local current_country choice entered_country default_country

    ensure_wpa_conf || return 1
    current_country=$(get_country_code)

    if [[ "$force_prompt" != "1" ]] && is_valid_country_code "$current_country"; then
        apply_regulatory_country "$current_country"
        return $?
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

    apply_regulatory_country "$choice" || return 1
    set_country_code "$choice" || {
        if is_valid_country_code "$current_country" && [[ "$current_country" != "$choice" ]]; then
            apply_regulatory_country "$current_country" >/dev/null 2>&1 || true
        fi
        printMsgs "dialog" "Unable to save country=$choice in $WPA_CONF"
        return 1
    }
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

wifi_menu_label() {
    local essid="$2"
    local type="$3"
    local signal="$1"

    printf '%s (%s, %s signal)' "$essid" "$type" "$signal"
}

string_to_wpa_hex() {
    local value="$1"
    local hex

    hex=$(printf '%s' "$value" | LC_ALL=C od -An -v -tx1 | tr -d '[:space:]') || return 1
    [[ -n "$hex" ]] || return 1
    printf '%s' "$hex"
}

iwlist_essid_to_hex() {
    local escaped="$1"
    local output="" char next_char high low token byte_hex ordinal
    local index=0
    local LC_ALL=C

    while [[ "$index" -lt "${#escaped}" ]]; do
        char="${escaped:$index:1}"
        if [[ "$char" == '\' && $((index + 3)) -lt ${#escaped} ]]; then
            next_char="${escaped:$((index + 1)):1}"
            high="${escaped:$((index + 2)):1}"
            low="${escaped:$((index + 3)):1}"
            if [[ "$next_char" == "x" && "$high$low" =~ ^[0-9A-Fa-f]{2}$ ]]; then
                token="$high$low"
                ordinal=$((16#$token))
                # iwlist only escapes controls, non-ASCII bytes, and an
                # ambiguity-causing backslash. Printable \xHH text is literal.
                if (( ordinal < 32 || ordinal >= 127 || ordinal == 92 )); then
                    output+="${token,,}"
                    index=$((index + 4))
                    continue
                fi
            fi
        fi

        printf -v ordinal '%d' "'$char"
        printf -v byte_hex '%02x' "$ordinal"
        output+="$byte_hex"
        index=$((index + 1))
    done

    [[ -n "$output" ]] || return 1
    printf '%s' "$output"
}

wpa_cli_ssid_to_hex() {
    local escaped="$1"
    local output="" char next_char token byte_hex ordinal
    local index=0
    local LC_ALL=C

    while [[ "$index" -lt "${#escaped}" ]]; do
        char="${escaped:$index:1}"
        if [[ "$char" == '\' && $((index + 1)) -lt ${#escaped} ]]; then
            next_char="${escaped:$((index + 1)):1}"
            if [[ "$next_char" == "x" && $((index + 3)) -lt ${#escaped} ]]; then
                token="${escaped:$((index + 2)):2}"
                if [[ "$token" =~ ^[0-9A-Fa-f]{2}$ ]]; then
                    output+="${token,,}"
                    index=$((index + 4))
                    continue
                fi
            fi
            case "$next_char" in
                '\')
                    output+="5c"
                    ;;
                '"')
                    output+="22"
                    ;;
                a)
                    output+="07"
                    ;;
                b)
                    output+="08"
                    ;;
                e)
                    output+="1b"
                    ;;
                f)
                    output+="0c"
                    ;;
                n)
                    output+="0a"
                    ;;
                r)
                    output+="0d"
                    ;;
                t)
                    output+="09"
                    ;;
                v)
                    output+="0b"
                    ;;
                *)
                    printf -v ordinal '%d' "'$next_char"
                    printf -v byte_hex '%02x' "$ordinal"
                    output+="$byte_hex"
                    ;;
            esac
            index=$((index + 2))
            continue
        fi

        printf -v ordinal '%d' "'$char"
        printf -v byte_hex '%02x' "$ordinal"
        output+="$byte_hex"
        index=$((index + 1))
    done

    printf '%s' "$output"
}

wpa_hex_to_string() {
    local hex="$1"
    local output="" byte ordinal
    local index=0

    [[ "$hex" =~ ^([0-9A-Fa-f]{2})+$ && ${#hex} -le 64 ]] || return 1
    while [[ "$index" -lt "${#hex}" ]]; do
        byte="${hex:$index:2}"
        ordinal=$((16#$byte))
        (( ordinal >= 32 && ordinal != 127 )) || return 1
        printf -v byte '%b' "\\x$byte"
        output+="$byte"
        index=$((index + 2))
    done

    printf '%s' "$output"
}

list_wifi() {
    local scan_output
    local line essid="" ssid_hex="" type="" quality=0 quality_max=0 quality_pct=0
    local auth_suite_seen=0 saw_psk=0
    local raw_networks="" preferred_networks="" sorted_networks=""

    set_interface_state up || return 1
    show_infobox "Searching for WiFi networks..."

    scan_output=$(run_with_timeout "$SCAN_TIMEOUT_SECONDS" iwlist "$INTERFACE" scan 2>/dev/null) || {
        printMsgs "dialog" "WiFi scan did not complete within ${SCAN_TIMEOUT_SECONDS} seconds on $INTERFACE."
        return 1
    }

    emit_network() {
        local label security_rank

        [[ -n "$essid" && -n "$ssid_hex" ]] || return 0

        if [[ -z "$type" ]]; then
            type="open"
        elif [[ "$type" == "wpa" && "$auth_suite_seen" -eq 1 && "$saw_psk" -eq 0 ]]; then
            type="unsupported"
        fi

        label=$(signal_label "$quality_pct")
        case "$type" in
            wpa)
                security_rank=4
                ;;
            wep)
                security_rank=2
                ;;
            unsupported)
                security_rank=3
                ;;
            *)
                security_rank=1
                ;;
        esac
        raw_networks+="${quality_pct}"$'\t'"${essid}"$'\t'"${type}"$'\t'"${label}"$'\t'"${security_rank}"$'\t'"${ssid_hex}"$'\n'
    }

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*Cell[[:space:]] ]]; then
            emit_network
            essid=""
            ssid_hex=""
            type=""
            auth_suite_seen=0
            saw_psk=0
            quality_pct=0
            continue
        fi

        if [[ "$line" =~ ESSID:\"(.*)\" ]]; then
            essid="${BASH_REMATCH[1]}"
            if [[ -z "$essid" ]]; then
                essid="<hidden>"
                ssid_hex=""
            else
                ssid_hex=$(iwlist_essid_to_hex "$essid") || {
                    essid=""
                    ssid_hex=""
                }
            fi
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

        if [[ "$line" == *"Authentication Suites"* ]]; then
            auth_suite_seen=1
            if [[ "$line" =~ (^|[^[:alnum:]_])(PSK|FT/PSK)([^[:alnum:]_]|$) ]]; then
                saw_psk=1
            fi
        fi
    done <<< "$scan_output"

    emit_network

    [[ -n "$raw_networks" ]] || return 0
    preferred_networks=$(printf '%s' "$raw_networks" | awk -F '\t' '
        {
            ssid = $6
            rank = $5 + 0
            quality = $1 + 0
            if (!(ssid in best_rank) || rank > best_rank[ssid] || (rank == best_rank[ssid] && quality > best_quality[ssid])) {
                best_rank[ssid] = rank
                best_quality[ssid] = quality
                best_line[ssid] = $0
            }
        }
        END {
            for (ssid in best_line) {
                print best_line[ssid]
            }
        }
    ') || return 1
    sorted_networks=$(printf '%s\n' "$preferred_networks" | sort -t $'\t' -k1,1nr -k2,2) || return 1

    while IFS=$'\t' read -r quality_pct essid type label security_rank ssid_hex; do
        [[ -n "$essid" ]] || continue

        printf '%s\t%s\t%s\t%s\t%s\n' "$essid" "$type" "$label" "$quality_pct" "$ssid_hex"
    done <<< "$sorted_networks"
}

write_config_without_ssid() {
    local target_ssid="$1"
    local input_file="$2"
    local require_match="${3:-0}"
    local target_hex="${4:-}"

    if [[ -z "$target_hex" ]]; then
        target_hex=$(string_to_wpa_hex "$target_ssid") || return 1
    fi
    [[ "$target_hex" =~ ^([0-9A-Fa-f]{2})+$ && ${#target_hex} -le 64 ]] || return 1

    LC_ALL=C WPA_REMOVE_SSID_HEX="$target_hex" awk -v require_match="$require_match" '
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

        function raw_hex(value, idx, output) {
            output = ""
            for (idx = 1; idx <= length(value); idx++) {
                output = output byte_hex[substr(value, idx, 1)]
            }
            return output
        }

        function hex_nibble(char) {
            return index("0123456789abcdef", tolower(char)) - 1
        }

        function printf_hex(value, content, idx, char, next_char, high, low, output, octal) {
            content = substr(value, 3, length(value) - 3)
            output = ""
            for (idx = 1; idx <= length(content); idx++) {
                char = substr(content, idx, 1)
                if (char != "\\" || idx == length(content)) {
                    output = output byte_hex[char]
                    continue
                }

                next_char = substr(content, idx + 1, 1)
                if (next_char == "x" && idx + 3 <= length(content)) {
                    high = hex_nibble(substr(content, idx + 2, 1))
                    low = hex_nibble(substr(content, idx + 3, 1))
                    if (high >= 0 && low >= 0) {
                        output = output sprintf("%02x", high * 16 + low)
                        idx += 3
                        continue
                    }
                }
                if (next_char ~ /^[0-7]$/ &&
                    substr(content, idx + 2, 1) ~ /^[0-7]$/ &&
                    substr(content, idx + 3, 1) ~ /^[0-7]$/) {
                    octal = (next_char + 0) * 64 + (substr(content, idx + 2, 1) + 0) * 8 + (substr(content, idx + 3, 1) + 0)
                    output = output sprintf("%02x", octal % 256)
                    idx += 3
                    continue
                }
                if (next_char in escape_hex) {
                    output = output escape_hex[next_char]
                } else {
                    output = output byte_hex[next_char]
                }
                idx++
            }
            return output
        }

        function value_hex(value) {
            value = trim(value)
            if (substr(value, 1, 2) == "P\"") {
                return printf_hex(value)
            }
            if (substr(value, 1, 1) == "\"") {
                return raw_hex(substr(value, 2, length(value) - 2))
            }
            return tolower(value)
        }

        function structural(s, first_quote, last_quote, idx, suffix, comment_at) {
            s = trim(s)
            first_quote = index(s, "\"")
            last_quote = 0
            if (first_quote > 0) {
                for (idx = length(s); idx > first_quote; idx--) {
                    if (substr(s, idx, 1) == "\"") {
                        last_quote = idx
                        break
                    }
                }
            }
            suffix = substr(s, last_quote > first_quote ? last_quote + 1 : 1)
            comment_at = index(suffix, "#")
            if (comment_at > 0) {
                s = substr(s, 1, (last_quote > first_quote ? last_quote : 0) + comment_at - 1)
            }
            return trim(s)
        }

        function config_block_kind(s) {
            s = structural(s)
            if (s == "network={") {
                return "network"
            }
            if (s == "cred={" || s ~ /^blob-base64-[^=]+=\{$/) {
                return "opaque"
            }
            return ""
        }

        BEGIN {
            for (byte = 1; byte < 256; byte++) {
                byte_hex[sprintf("%c", byte)] = sprintf("%02x", byte)
            }
            escape_hex["a"] = "07"
            escape_hex["b"] = "08"
            escape_hex["e"] = "1b"
            escape_hex["f"] = "0c"
            escape_hex["n"] = "0a"
            escape_hex["r"] = "0d"
            escape_hex["t"] = "09"
            escape_hex["v"] = "0b"
            escape_hex["\\"] = "5c"
            escape_hex["\""] = "22"
            target = tolower(ENVIRON["WPA_REMOVE_SSID_HEX"])
            in_block = 0
            is_network = 0
            skip_block = 0
            removed = 0
            block = ""
        }

        {
            line = trim($0)
            structure = structural($0)
            kind = config_block_kind($0)

            if (!in_block && kind != "") {
                in_block = 1
                is_network = (kind == "network")
                skip_block = 0
                block = $0 ORS
                next
            }

            if (in_block) {
                block = block $0 ORS
                if (is_network && structure ~ /^ssid[[:space:]]*=/) {
                    ssid = structure
                    sub(/^ssid[[:space:]]*=[[:space:]]*/, "", ssid)

                    if (value_hex(ssid) == target) {
                        skip_block = 1
                    }
                }

                if (structure == "}") {
                    if (!is_network || !skip_block) {
                        printf "%s", block
                    } else {
                        removed = 1
                    }
                    in_block = 0
                    is_network = 0
                    block = ""
                }
                next
            }

            print
        }
        END {
            if (in_block) {
                exit 2
            }
            if (require_match && !removed) {
                exit 3
            }
        }
    ' "$input_file"
}

remove_network_by_ssid() {
    local target_ssid="$1"
    local target_hex="${2:-}"
    local error

    ensure_wpa_conf || return 1
    validate_wpa_conf || return 1
    make_wpa_temp || return 1
    if ! write_config_without_ssid "$target_ssid" "$WPA_CONF" 1 "$target_hex" > "$WPA_WORK_FILE"; then
        cleanup_wpa_work_file
        return 1
    fi
    error=$(wpa_conf_validation_error "$WPA_WORK_FILE")
    if [[ -n "$error" ]]; then
        cleanup_wpa_work_file
        return 1
    fi
    commit_wpa_temp
}

saved_networks() {
    ensure_wpa_conf

    LC_ALL=C awk '
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

        function raw_hex(value, idx, output) {
            output = ""
            for (idx = 1; idx <= length(value); idx++) {
                output = output byte_hex[substr(value, idx, 1)]
            }
            return output
        }

        function hex_nibble(char) {
            return index("0123456789abcdef", tolower(char)) - 1
        }

        function printf_hex(value, content, idx, char, next_char, high, low, output, octal) {
            content = substr(value, 3, length(value) - 3)
            output = ""
            for (idx = 1; idx <= length(content); idx++) {
                char = substr(content, idx, 1)
                if (char != "\\" || idx == length(content)) {
                    output = output byte_hex[char]
                    continue
                }

                next_char = substr(content, idx + 1, 1)
                if (next_char == "x" && idx + 3 <= length(content)) {
                    high = hex_nibble(substr(content, idx + 2, 1))
                    low = hex_nibble(substr(content, idx + 3, 1))
                    if (high >= 0 && low >= 0) {
                        output = output sprintf("%02x", high * 16 + low)
                        idx += 3
                        continue
                    }
                }
                if (next_char ~ /^[0-7]$/ &&
                    substr(content, idx + 2, 1) ~ /^[0-7]$/ &&
                    substr(content, idx + 3, 1) ~ /^[0-7]$/) {
                    octal = (next_char + 0) * 64 + (substr(content, idx + 2, 1) + 0) * 8 + (substr(content, idx + 3, 1) + 0)
                    output = output sprintf("%02x", octal % 256)
                    idx += 3
                    continue
                }
                if (next_char in escape_hex) {
                    output = output escape_hex[next_char]
                } else {
                    output = output byte_hex[next_char]
                }
                idx++
            }
            return output
        }

        function value_hex(value) {
            value = trim(value)
            if (substr(value, 1, 2) == "P\"") {
                return printf_hex(value)
            }
            if (substr(value, 1, 1) == "\"") {
                return raw_hex(substr(value, 2, length(value) - 2))
            }
            return tolower(value)
        }

        function hex_display(value, idx, high, low, byte, output) {
            output = ""
            for (idx = 1; idx <= length(value); idx += 2) {
                high = hex_nibble(substr(value, idx, 1))
                low = hex_nibble(substr(value, idx + 1, 1))
                if (high < 0 || low < 0) {
                    return ""
                }
                byte = high * 16 + low
                if (byte < 32 || byte == 127) {
                    output = output sprintf("\\x%02X", byte)
                } else {
                    output = output sprintf("%c", byte)
                }
            }
            return output
        }

        function structural(s, first_quote, last_quote, idx, suffix, comment_at) {
            s = trim(s)
            first_quote = index(s, "\"")
            last_quote = 0
            if (first_quote > 0) {
                for (idx = length(s); idx > first_quote; idx--) {
                    if (substr(s, idx, 1) == "\"") {
                        last_quote = idx
                        break
                    }
                }
            }
            suffix = substr(s, last_quote > first_quote ? last_quote + 1 : 1)
            comment_at = index(suffix, "#")
            if (comment_at > 0) {
                s = substr(s, 1, (last_quote > first_quote ? last_quote : 0) + comment_at - 1)
            }
            return trim(s)
        }

        function config_block_kind(s) {
            s = structural(s)
            if (s == "network={") {
                return "network"
            }
            if (s == "cred={" || s ~ /^blob-base64-[^=]+=\{$/) {
                return "opaque"
            }
            return ""
        }

        BEGIN {
            for (byte = 1; byte < 256; byte++) {
                byte_hex[sprintf("%c", byte)] = sprintf("%02x", byte)
            }
            escape_hex["a"] = "07"
            escape_hex["b"] = "08"
            escape_hex["e"] = "1b"
            escape_hex["f"] = "0c"
            escape_hex["n"] = "0a"
            escape_hex["r"] = "0d"
            escape_hex["t"] = "09"
            escape_hex["v"] = "0b"
            escape_hex["\\"] = "5c"
            escape_hex["\""] = "22"
            in_block = 0
            is_network = 0
            idx = 0
            ssid_hex = ""
        }

        {
            line = trim($0)
            structure = structural($0)
            kind = config_block_kind($0)
            if (!in_block && kind != "") {
                in_block = 1
                is_network = (kind == "network")
                ssid_hex = ""
                next
            }

            if (in_block) {
                if (is_network && structure ~ /^ssid[[:space:]]*=/) {
                    ssid_value = structure
                    sub(/^ssid[[:space:]]*=[[:space:]]*/, "", ssid_value)
                    ssid_hex = value_hex(ssid_value)
                } else if (structure == "}") {
                    if (is_network && ssid_hex != "") {
                        printf "%s\t%s\t%s\n", idx, hex_display(ssid_hex), ssid_hex
                        idx++
                    }
                    in_block = 0
                    is_network = 0
                }
            }
        }
    ' "$WPA_CONF"
}

network_block_for_wpa() {
    local essid="$1"
    local key="$2"
    local hidden="$3"
    local ssid_hex="${4:-}"
    local block

    [[ -n "$essid" && "$essid" != *$'\r'* && "$essid" != *$'\n'* ]] || return 1
    [[ "$key" != *$'\r'* && "$key" != *$'\n'* ]] || return 1
    if [[ -z "$ssid_hex" ]]; then
        ssid_hex=$(string_to_wpa_hex "$essid") || return 1
    fi
    [[ "$ssid_hex" =~ ^([0-9A-Fa-f]{2})+$ && ${#ssid_hex} -le 64 ]] || return 1

    if [[ "$key" =~ ^[0-9A-Fa-f]{64}$ ]]; then
        block=$(cat <<EOF
network={
    ssid=$ssid_hex
    psk=$key
}
EOF
)
    else
        [[ ${#key} -ge 8 && ${#key} -le 63 ]] || return 1
        if command_exists wpa_passphrase; then
            block=$(
                printf '%s\n' "$key" |
                    wpa_passphrase "$essid" 2>/dev/null |
                    WPA_SSID_HEX="$ssid_hex" awk '
                        /^[[:space:]]*#psk=/ {
                            next
                        }
                        /^[[:space:]]*ssid=/ && !replaced {
                            print "    ssid=" ENVIRON["WPA_SSID_HEX"]
                            replaced = 1
                            next
                        }
                        {
                            print
                        }
                        END {
                            if (!replaced) {
                                exit 1
                            }
                        }
                    '
            ) || return 1
            [[ -n "$block" ]] || return 1
        else
            block=$(cat <<EOF
network={
    ssid=$ssid_hex
    psk="$key"
}
EOF
)
        fi
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
        ') || return 1
    fi

    [[ "$block" == *"network={"* && "$block" == *"}"* ]] || return 1
    printf '%s\n' "$block" | grep -q '^[[:space:]]*psk=' || return 1
    printf '%s\n' "$block"
}

append_network_config() {
    local type="$1"
    local essid="$2"
    local key="$3"
    local hidden="$4"
    local ssid_hex="${5:-}"
    local key_hex block error

    [[ -n "$essid" && "$essid" != *$'\r'* && "$essid" != *$'\n'* ]] || return 1
    [[ "$key" != *$'\r'* && "$key" != *$'\n'* ]] || return 1
    if [[ -z "$ssid_hex" ]]; then
        ssid_hex=$(string_to_wpa_hex "$essid") || return 1
    fi
    [[ "$ssid_hex" =~ ^([0-9A-Fa-f]{2})+$ && ${#ssid_hex} -le 64 ]] || return 1
    ensure_wpa_conf || return 1
    validate_wpa_conf || return 1

    case "$type" in
        wpa)
            block=$(network_block_for_wpa "$essid" "$key" "$hidden" "$ssid_hex") || return 1
            ;;
        wep)
            [[ -n "$key" ]] || return 1
            block=$(cat <<EOF
network={
    ssid=$ssid_hex
    key_mgmt=NONE
    wep_tx_keyidx=0
EOF
)
            if [[ "$key" =~ ^([0-9A-Fa-f]{10}|[0-9A-Fa-f]{26}|[0-9A-Fa-f]{32})$ ]]; then
                block+=$'\n'"    wep_key0=$key"
            else
                key_hex=$(string_to_wpa_hex "$key") || return 1
                [[ ${#key_hex} -eq 10 || ${#key_hex} -eq 26 || ${#key_hex} -eq 32 ]] || return 1
                block+=$'\n'"    wep_key0=$key_hex"
            fi
            [[ "$hidden" == "1" ]] && block+=$'\n'"    scan_ssid=1"
            block+=$'\n}'
            ;;
        open)
            block=$(cat <<EOF
network={
    ssid=$ssid_hex
    key_mgmt=NONE
EOF
)
            [[ "$hidden" == "1" ]] && block+=$'\n'"    scan_ssid=1"
            block+=$'\n}'
            ;;
        *)
            return 1
            ;;
    esac
    [[ -n "$block" ]] || return 1

    make_wpa_temp || return 1
    if ! write_config_without_ssid "$essid" "$WPA_CONF" 0 "$ssid_hex" > "$WPA_WORK_FILE"; then
        cleanup_wpa_work_file
        return 1
    fi
    if ! printf '\n%s\n' "$block" >> "$WPA_WORK_FILE"; then
        cleanup_wpa_work_file
        return 1
    fi
    error=$(wpa_conf_validation_error "$WPA_WORK_FILE")
    if [[ -n "$error" ]]; then
        cleanup_wpa_work_file
        return 1
    fi
    commit_wpa_temp
}

start_dhcp_lease_request() {
    if command_exists dhcpcd; then
        run_with_timeout "$IPV4_WAIT_SECONDS" dhcpcd -n "$INTERFACE" >/dev/null 2>&1
        return $?
    elif command_exists udhcpc; then
        run_with_timeout "$IPV4_WAIT_SECONDS" udhcpc -n -q -i "$INTERFACE" -T 3 -t 5 >/dev/null 2>&1
        return $?
    elif command_exists dhclient; then
        run_with_timeout "$IPV4_WAIT_SECONDS" dhclient "$INTERFACE" >/dev/null 2>&1
        return $?
    fi

    return 1
}

reload_wpa_supplicant() {
    if command_exists wpa_cli && wpa_cli -i "$INTERFACE" ping 2>/dev/null | grep -qx 'PONG'; then
        wpa_cli -i "$INTERFACE" reconfigure 2>/dev/null | grep -qx 'OK' || return 1
        wpa_cli -i "$INTERFACE" reassociate 2>/dev/null | grep -qx 'OK' ||
            wpa_cli -i "$INTERFACE" reconnect 2>/dev/null | grep -qx 'OK' ||
            true
        return 0
    fi

    if command_exists wpa_supplicant; then
        wpa_supplicant -B -i "$INTERFACE" -c "$WPA_CONF" >/dev/null 2>&1 || return 1
        return 0
    fi

    return 1
}

select_target_network() {
    local target_ssid="$1"
    local target_hex="${2:-}"
    local listed_id listed_ssid listed_flags listed_hex
    local network_list
    local network_id

    WPA_REENABLE_IDS=()
    WPA_SELECTION_ACTIVE=0
    [[ -n "$target_ssid" ]] || return 0
    command_exists wpa_cli || return 1
    if [[ -z "$target_hex" ]]; then
        target_hex=$(string_to_wpa_hex "$target_ssid") || return 1
    fi

    network_list=$(wpa_cli -i "$INTERFACE" list_networks 2>/dev/null) || return 1
    while IFS=$'\t' read -r listed_id listed_ssid _ listed_flags; do
        [[ "$listed_id" =~ ^[0-9]+$ ]] || continue
        listed_hex=$(wpa_cli_ssid_to_hex "$listed_ssid") || continue
        if [[ "${listed_hex,,}" == "${target_hex,,}" ]]; then
            network_id="$listed_id"
        elif [[ "$listed_flags" != *"[DISABLED]"* ]]; then
            WPA_REENABLE_IDS+=("$listed_id")
        fi
    done <<< "$network_list"

    [[ "$network_id" =~ ^[0-9]+$ ]] || return 1
    wpa_cli -i "$INTERFACE" select_network "$network_id" 2>/dev/null | grep -qx 'OK' || return 1
    WPA_SELECTION_ACTIVE=1
}

restore_network_enable_state() {
    local network_id
    local status=0

    [[ "$WPA_SELECTION_ACTIVE" -eq 1 ]] || return 0
    for network_id in "${WPA_REENABLE_IDS[@]}"; do
        wpa_cli -i "$INTERFACE" enable_network "$network_id" 2>/dev/null | grep -qx 'OK' || status=1
    done
    WPA_REENABLE_IDS=()
    WPA_SELECTION_ACTIVE=0
    return "$status"
}

current_ip() {
    ip -o -4 addr show dev "$INTERFACE" scope global 2>/dev/null |
        awk '$4 !~ /^169[.]254[.]/ { split($4, address, "/"); print address[1]; exit }'
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
    local expected_ssid="${1:-}"
    local seconds=0
    local ip associated_ssid

    while [[ "$seconds" -lt "$IPV4_WAIT_SECONDS" ]]; do
        associated_ssid=$(current_ssid)
        if [[ -n "$expected_ssid" && "$associated_ssid" != "$expected_ssid" ]]; then
            sleep 1
            seconds=$((seconds + 1))
            continue
        fi
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
                exit
            }
        }
    '
}

interface_counter() {
    local counter="$1"
    local path value

    case "$counter" in
        rx_bytes|tx_bytes|rx_errors|tx_errors|rx_dropped|tx_dropped)
            ;;
        *)
            return 1
            ;;
    esac
    [[ "$INTERFACE" =~ ^[[:alnum:]_.:-]+$ ]] || return 1

    path="/sys/class/net/$INTERFACE/statistics/$counter"
    [[ -r "$path" ]] || return 1
    IFS= read -r value < "$path" || return 1
    [[ "$value" =~ ^[0-9]+$ ]] || return 1
    printf '%s' "$value"
}

human_bytes() {
    awk -v bytes="$1" 'BEGIN {
        split("B KiB MiB GiB TiB", units, " ")
        value = bytes + 0
        unit = 1
        while (value >= 1024 && unit < 5) {
            value /= 1024
            unit++
        }
        if (unit == 1) {
            printf "%.0f %s", value, units[unit]
        } else {
            printf "%.1f %s", value, units[unit]
        }
    }'
}

dbm_signal_label() {
    local dbm="${1%%.*}"

    [[ "$dbm" =~ ^-?[0-9]+$ ]] || {
        printf 'Unknown'
        return 0
    }

    if (( dbm >= -55 )); then
        printf 'Strong'
    elif (( dbm >= -67 )); then
        printf 'Good'
    elif (( dbm >= -75 )); then
        printf 'Fair'
    else
        printf 'Weak'
    fi
}

wireless_link_report() {
    local link="" radio_status
    local signal_dbm="" signal_description="" frequency="" rx_rate="" tx_rate=""
    local rx_bytes="" tx_bytes="" rx_errors="" tx_errors="" rx_dropped="" tx_dropped=""

    if ! command_exists iw; then
        radio_status="metrics unavailable (iw not installed)"
    else
        link=$(iw dev "$INTERFACE" link 2>/dev/null || true)
        if [[ "$link" == Not\ connected.* ]]; then
            radio_status="not connected"
        elif [[ -z "$link" ]]; then
            radio_status="metrics unavailable"
        else
            radio_status="associated"
            signal_dbm=$(awk '$1 == "signal:" && $2 ~ /^-?[0-9]+([.][0-9]+)?$/ && $3 == "dBm" { print $2; exit }' <<< "$link")
            frequency=$(awk '$1 == "freq:" && $2 ~ /^[0-9]+$/ { print $2; exit }' <<< "$link")
            rx_rate=$(awk '$1 == "rx" && $2 == "bitrate:" && $3 ~ /^[0-9]+([.][0-9]+)?$/ { print $3 " " $4; exit }' <<< "$link")
            tx_rate=$(awk '$1 == "tx" && $2 == "bitrate:" && $3 ~ /^[0-9]+([.][0-9]+)?$/ { print $3 " " $4; exit }' <<< "$link")
        fi
    fi

    rx_bytes=$(interface_counter rx_bytes 2>/dev/null || true)
    tx_bytes=$(interface_counter tx_bytes 2>/dev/null || true)
    rx_errors=$(interface_counter rx_errors 2>/dev/null || true)
    tx_errors=$(interface_counter tx_errors 2>/dev/null || true)
    rx_dropped=$(interface_counter rx_dropped 2>/dev/null || true)
    tx_dropped=$(interface_counter tx_dropped 2>/dev/null || true)

    printf 'Radio link: %s\n' "$radio_status"
    if [[ -n "$signal_dbm" ]]; then
        signal_description=$(dbm_signal_label "$signal_dbm")
        printf 'Signal: %s dBm (%s)\n' "$signal_dbm" "$signal_description"
    else
        printf 'Signal: (unavailable)\n'
    fi
    [[ -n "$frequency" ]] && printf 'Frequency: %s MHz\n' "$frequency"
    [[ -n "$rx_rate" ]] && printf 'RX link rate: %s\n' "$rx_rate"
    [[ -n "$tx_rate" ]] && printf 'TX link rate: %s\n' "$tx_rate"

    if [[ -n "$rx_bytes" && -n "$tx_bytes" ]]; then
        printf 'Traffic since interface up: RX %s, TX %s\n' \
            "$(human_bytes "$rx_bytes")" "$(human_bytes "$tx_bytes")"
    fi
    if [[ -n "$rx_errors" && -n "$tx_errors" && -n "$rx_dropped" && -n "$tx_dropped" ]]; then
        printf 'Errors/dropped packets: RX %s/%s, TX %s/%s\n' \
            "$rx_errors" "$rx_dropped" "$tx_errors" "$tx_dropped"
    fi
}

ping_once() {
    command_exists ping || return 2
    ping -I "$INTERFACE" -c 1 -W 2 "$1" >/dev/null 2>&1
}

dns_lookup_ok() {
    local output

    if command_exists getent; then
        getent hosts misterfpga.org >/dev/null 2>&1 && return 0
        return 1
    elif command_exists nslookup; then
        output=$(nslookup misterfpga.org 2>/dev/null || true)
        if awk '
            /^[[:space:]]*Name:[[:space:]]/ {
                found_name = 1
                next
            }
            found_name && /^[[:space:]]*Address([[:space:]][0-9]+)?:[[:space:]]/ {
                address = $0
                sub(/^[[:space:]]*Address([[:space:]][0-9]+)?:[[:space:]]*/, "", address)
                split(address, fields, /[[:space:]]+/)
                address = fields[1]
                sub(/#[0-9]+$/, "", address)
                if ((address ~ /^[0-9][0-9.]*$/ && address ~ /[.]/) ||
                    (address ~ /^[0-9A-Fa-f][0-9A-Fa-f:]*$/ && address ~ /:/)) {
                    found_address = 1
                }
            }
            END {
                exit(found_address ? 0 : 1)
            }
        ' <<< "$output"; then
            return 0
        fi
        return 1
    else
        return 2
    fi
}

connection_health_report() {
    local include_heading="${1:-1}"
    local ssid ip gateway country gateway_status internet_status dns_status dns_result

    ssid=$(current_ssid)
    ip=$(current_ip)
    gateway=$(default_gateway)
    country=$(get_country_code 2>/dev/null || true)

    [[ -z "$ssid" ]] && ssid="(not connected)"
    [[ -z "$ip" ]] && ip="(no IPv4 lease)"
    [[ -z "$gateway" ]] && gateway="(none)"
    [[ -z "$country" ]] && country="(missing)"
    ssid=$(sanitize_control_text "$ssid")

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

    dns_lookup_ok
    dns_result=$?
    case "$dns_result" in
        0)
            dns_status="OK"
            ;;
        2)
            dns_status="not tested (resolver tool unavailable)"
            ;;
        *)
            dns_status="failed"
            ;;
    esac

    [[ "$include_heading" == "1" ]] && printf 'Connection summary:\n'
    printf 'Interface: %s\n' "$INTERFACE"
    printf 'SSID: %s\n' "$ssid"
    printf 'Country: %s\n' "$country"
    printf 'IPv4: %s\n' "$ip"
    printf 'Gateway: %s\n' "$gateway"
    wireless_link_report
    printf 'Gateway ping: %s\n' "$gateway_status"
    printf 'Internet ping: %s\n' "$internet_status"
    printf 'DNS lookup: %s' "$dns_status"
}

disconnect_wifi() {
    local ssid ip_addr remaining_ssid remaining_ip seconds=0
    local was_associated=0 disconnect_command_ok=0

    show_infobox "Disconnecting WiFi.\nPlease wait..."
    require_tools reconnect || return 1
    detect_interface || return 1

    ssid=$(current_ssid)
    ip_addr=$(current_ip)

    [[ -n "$ssid" ]] && was_associated=1
    [[ -z "$ssid" ]] && ssid="(not connected)"
    ssid=$(sanitize_control_text "$ssid")
    [[ -z "$ip_addr" ]] && ip_addr="(no IPv4 lease)"

    if command_exists wpa_cli; then
        if run_with_timeout "$DISCONNECT_TIMEOUT_SECONDS" wpa_cli -i "$INTERFACE" disconnect >/dev/null 2>&1; then
            disconnect_command_ok=1
        fi
    fi

    if command_exists iw; then
        if run_with_timeout "$DISCONNECT_TIMEOUT_SECONDS" iw dev "$INTERFACE" disconnect >/dev/null 2>&1; then
            disconnect_command_ok=1
        fi
    fi

    if [[ "$was_associated" -eq 1 && "$disconnect_command_ok" -eq 0 ]]; then
        printMsgs "dialog" "Unable to disconnect $INTERFACE.\n\nNeither wpa_cli nor iw accepted the disconnect request."
        return 1
    fi

    run_with_timeout "$DISCONNECT_TIMEOUT_SECONDS" ip -4 addr flush dev "$INTERFACE" >/dev/null 2>&1 || {
        printMsgs "dialog" "Unable to clear the IPv4 lease from $INTERFACE."
        return 1
    }

    while [[ "$seconds" -lt "$DISCONNECT_TIMEOUT_SECONDS" ]]; do
        remaining_ssid=$(current_ssid)
        remaining_ip=$(current_ip)
        if [[ -z "$remaining_ssid" && -z "$remaining_ip" ]]; then
            printMsgs "dialog" "Disconnected WiFi.\n\nInterface: $INTERFACE\nPrevious network: $ssid\nPrevious IPv4: $ip_addr\n\nSaved networks were not changed."
            return 0
        fi
        sleep 1
        seconds=$((seconds + 1))
    done

    printMsgs "dialog" "Unable to disconnect $INTERFACE.\n\nStill associated with: ${remaining_ssid:-(none)}\nRemaining IPv4: ${remaining_ip:-(none)}"
    return 1
}

apply_wifi_settings() {
    local target_ssid="$1"
    local target_hex="${2:-}"
    local target_label settings_label target_display ssid ssid_display ip health

    if [[ -n "$target_ssid" ]]; then
        target_display=$(sanitize_control_text "$target_ssid")
        target_label="$target_display"
        settings_label="Saved WiFi settings for $target_display"
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
    if ! select_target_network "$target_ssid" "$target_hex"; then
        printMsgs "dialog" "Unable to select the saved network $target_ssid on $INTERFACE."
        return 1
    fi

    show_infobox "Connecting $INTERFACE to $target_label..."
    ssid=$(wait_for_association "$target_ssid") || {
        restore_network_enable_state >/dev/null 2>&1 || reload_wpa_supplicant >/dev/null 2>&1 || true
        printMsgs "dialog" "$settings_label are present, but $INTERFACE did not associate within ${ASSOCIATION_WAIT_SECONDS} seconds.\n\nIf the adapter is valid and the password is correct, try waiting a bit longer or rebooting."
        return 1
    }
    ssid_display=$(sanitize_control_text "$ssid")
    if ! restore_network_enable_state; then
        reload_wpa_supplicant >/dev/null 2>&1 || true
        printMsgs "dialog" "Connected to $ssid_display, but unable to restore the enabled state of other saved networks."
        return 1
    fi

    show_infobox "Requesting an IP address for $INTERFACE..."
    preserve_ssh_client_route
    ip -4 addr flush dev "$INTERFACE" scope global >/dev/null 2>&1 || {
        printMsgs "dialog" "Unable to clear the previous IPv4 lease from $INTERFACE."
        return 1
    }
    start_dhcp_lease_request || {
        printMsgs "dialog" "Unable to request an IPv4 lease for $INTERFACE."
        return 1
    }
    ip=$(wait_for_ipv4_lease "$ssid") || {
        printMsgs "dialog" "$INTERFACE connected to $ssid_display, but MiSTer did not receive an IPv4 address within ${IPV4_WAIT_SECONDS} seconds."
        return 1
    }

    health=$(connection_health_report)
    printMsgs "dialog" "Successfully connected.\n\nInterface: $INTERFACE\nNetwork: $ssid_display\nIP address: $ip\n\n$health"
    return 0
}

prompt_for_key() {
    local type="$1"
    local essid="$2"
    local key="" key_hex
    local key_ok=0

    while [[ "$key_ok" -eq 0 ]]; do
        key=$(capture_dialog dialog --backtitle "$__backtitle" --insecure --passwordbox "Enter the WiFi password for:\n$essid" 10 64) || return 1
        key_ok=1

        if [[ "$type" == "wpa" ]]; then
            if [[ ${#key} -eq 64 && "$key" =~ ^[0-9A-Fa-f]{64}$ ]]; then
                :
            elif [[ ${#key} -lt 8 || ${#key} -gt 63 ]]; then
                printMsgs "dialog" "WPA credentials must be an 8-63 character passphrase or a 64-digit hexadecimal PSK."
                key_ok=0
            fi
        fi

        if [[ "$type" == "wep" ]]; then
            if [[ "$key" =~ ^([0-9A-Fa-f]{10}|[0-9A-Fa-f]{26}|[0-9A-Fa-f]{32})$ ]]; then
                :
            else
                key_hex=$(string_to_wpa_hex "$key") || key_hex=""
                if [[ ${#key_hex} -ne 10 && ${#key_hex} -ne 26 && ${#key_hex} -ne 32 ]]; then
                    printMsgs "dialog" "WEP keys must be 5, 13, or 16 characters, or 10, 26, or 32 hexadecimal digits."
                    key_ok=0
                fi
            fi
        fi
    done

    printf '%s' "$key"
}

connect_saved_wifi() {
    local saved_count

    show_infobox "Connecting to WiFi.\nPlease wait..."
    require_tools reconnect || return 1
    detect_interface || return 1
    ensure_wpa_conf || return 1
    validate_wpa_conf || return 1

    saved_count=$(saved_networks | awk 'END { print NR + 0 }')
    if [[ "$saved_count" -eq 0 ]]; then
        printMsgs "dialog" "No saved WiFi networks were found in $WPA_CONF.\n\nUse Scan and connect first to save a network."
        return 1
    fi

    apply_wifi_settings ""
}

recover_previous_wifi_connection() {
    local previous_ssid="$1"
    local associated_ssid ip

    reload_wpa_supplicant || return 1
    [[ -n "$previous_ssid" ]] || return 0

    associated_ssid=$(wait_for_association "$previous_ssid") || return 1
    ip=$(current_ip)
    [[ -n "$ip" ]] && return 0

    preserve_ssh_client_route
    start_dhcp_lease_request || return 1
    wait_for_ipv4_lease "$associated_ssid" >/dev/null
}

connect_wifi() {
    local networks=()
    local network_hexes=()
    local types=()
    local raw options=()
    local essid ssid_hex type signal quality choice hidden key menu_label menu_prompt previous_ssid
    local index=0

    show_infobox "Preparing WiFi setup.\nPlease wait..."
    require_tools scan || return 1
    detect_interface || return 1
    prompt_country_code || return 1

    raw=$(list_wifi) || return 1
    if [[ -n "$raw" ]]; then
        while IFS=$'\t' read -r essid type signal quality ssid_hex; do
            [[ -n "$essid" ]] || continue
            networks+=("$essid")
            network_hexes+=("$ssid_hex")
            types+=("$type")
            menu_label=$(wifi_menu_label "$signal" "$essid" "$type")
            options+=("$index" "$menu_label")
            index=$((index + 1))
        done <<< "$raw"
    fi

    options+=("H" "Hidden network")
    menu_prompt="Choose the WiFi network you would like to connect to:"
    if [[ ${#networks[@]} -eq 0 ]]; then
        menu_prompt="No visible WiFi networks were found. Choose Hidden network to enter one manually:"
    fi

    choice=$(capture_dialog dialog --backtitle "$__backtitle" --menu "$menu_prompt" 22 76 16 "${options[@]}") || return 1

    hidden=0
    if [[ "$choice" == "H" ]]; then
        essid=$(capture_dialog dialog --backtitle "$__backtitle" --inputbox "Enter the hidden network SSID:" 10 60) || return 1
        [[ -n "$essid" ]] || return 1
        ssid_hex=$(string_to_wpa_hex "$essid") || return 1
        wpa_hex_to_string "$ssid_hex" >/dev/null || {
            printMsgs "dialog" "SSID control characters are not supported."
            return 1
        }
        type=$(capture_dialog dialog --backtitle "$__backtitle" --menu "Choose the network security type:" 14 44 6 wpa "WPA / WPA2" wep "WEP" open "Open") || return 1
        hidden=1
    else
        ssid_hex="${network_hexes[$choice]}"
        essid=$(wpa_hex_to_string "$ssid_hex") || {
            printMsgs "dialog" "This SSID contains control bytes that the WiFi helper cannot safely configure."
            return 1
        }
        type="${types[$choice]}"
    fi

    if [[ "$type" == "unsupported" ]]; then
        printMsgs "dialog" "This network does not advertise WPA/WPA2-PSK authentication. Enterprise, SAE-only, and OWE networks are not supported by this password-only helper."
        return 1
    fi

    key=""
    if [[ "$type" == "wpa" || "$type" == "wep" ]]; then
        key=$(prompt_for_key "$type" "$essid") || return 1
    fi

    previous_ssid=$(current_ssid)
    begin_wpa_rollback "$previous_ssid" || {
        printMsgs "dialog" "Unable to create a rollback copy of $WPA_CONF."
        return 1
    }
    append_network_config "$type" "$essid" "$key" "$hidden" "$ssid_hex" || {
        discard_wpa_rollback || true
        printMsgs "dialog" "Failed to save WiFi settings for $essid."
        return 1
    }

    if apply_wifi_settings "$essid" "$ssid_hex"; then
        discard_wpa_rollback || printMsgs "dialog" "Connected, but unable to remove the temporary rollback copy:\n$WPA_ROLLBACK_FILE"
        return 0
    fi

    if restore_wpa_rollback; then
        if recover_previous_wifi_connection "$previous_ssid"; then
            printMsgs "dialog" "Connection failed. Restored the previous WiFi settings and network connection."
        else
            printMsgs "dialog" "Connection failed. Restored the previous WiFi settings, but could not automatically recover the previous network connection."
        fi
        WPA_ROLLBACK_SSID=""
    else
        printMsgs "dialog" "Connection failed and the previous WiFi settings could not be restored automatically.\n\nRecovery copy:\n$WPA_ROLLBACK_FILE"
    fi
    return 1
}

remove_saved_network() {
    local networks=()
    local network_hexes=()
    local options=()
    local line index ssid ssid_hex choice

    ensure_wpa_conf || return 1
    validate_wpa_conf || return 1

    while IFS=$'\t' read -r index ssid ssid_hex; do
        networks+=("$ssid")
        network_hexes+=("$ssid_hex")
        options+=("$index" "$ssid")
    done < <(saved_networks)

    if [[ ${#networks[@]} -eq 0 ]]; then
        printMsgs "dialog" "No saved WiFi networks were found in $WPA_CONF."
        return 0
    fi

    choice=$(capture_dialog dialog --backtitle "$__backtitle" --menu "Select a saved network to remove:" 20 70 12 "${options[@]}") || return 0
    ssid="${networks[$choice]}"
    ssid_hex="${network_hexes[$choice]}"

    capture_dialog dialog --backtitle "$__backtitle" --yes-label "Remove" --no-label "Cancel" --yesno "Remove this saved WiFi network?\n\n$ssid\n\nThis only removes the saved network from $WPA_CONF." 12 70 || return 0

    if ! remove_network_by_ssid "$ssid" "$ssid_hex"; then
        printMsgs "dialog" "Unable to remove saved network:\n$ssid\n\n$WPA_CONF was not changed."
        return 1
    fi
    printMsgs "dialog" "Removed saved network:\n$ssid"
}

saved_networks_menu() {
    local networks=()
    local network_hexes=()
    local options=()
    local index ssid ssid_hex choice default_item="0" next_default

    while true; do
        networks=()
        network_hexes=()
        options=()

        ensure_wpa_conf || return 1
        validate_wpa_conf || return 1

        while IFS=$'\t' read -r index ssid ssid_hex; do
            networks+=("$ssid")
            network_hexes+=("$ssid_hex")
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
        ssid_hex="${network_hexes[$choice]}"

        capture_dialog dialog --backtitle "$__backtitle" --yes-label "Remove" --no-label "Cancel" --yesno "Remove this saved WiFi network?\n\n$ssid\n\nThis only removes the saved network from $WPA_CONF." 12 70 || {
            default_item="$choice"
            continue
        }

        next_default="$choice"
        if ! remove_network_by_ssid "$ssid" "$ssid_hex"; then
            printMsgs "dialog" "Unable to remove saved network:\n$ssid\n\n$WPA_CONF was not changed."
            default_item="$choice"
            continue
        fi
        printMsgs "dialog" "Removed saved network:\n$ssid"
        default_item="$next_default"
    done
}

show_saved_networks() {
    saved_networks_menu
}

diagnose_wifi() {
    local requested_interface="$INTERFACE"
    local detected_interface error networks

    echo "MiSTer WiFi diagnostics"

    detected_interface=$(find_wireless_interface 2>/dev/null || true)
    echo
    echo "--- Connection summary ---"
    if [[ -n "$detected_interface" ]]; then
        INTERFACE="$detected_interface"
        connection_health_report 0
        echo
    else
        echo "Requested interface: $requested_interface"
        echo "Detected interface: (none)"
        echo "No wireless interface is available for connection checks."
    fi

    echo
    echo "--- Configuration ---"
    echo "Script: $0"
    echo "WPA config: $WPA_CONF"
    echo "Requested interface: $requested_interface"
    echo "Detected interface: ${detected_interface:-(none)}"
    echo "Timeouts: adapter=${INTERFACE_DETECT_TIMEOUT_SECONDS}s scan=${SCAN_TIMEOUT_SECONDS}s association=${ASSOCIATION_WAIT_SECONDS}s ipv4=${IPV4_WAIT_SECONDS}s disconnect=${DISCONNECT_TIMEOUT_SECONDS}s"

    if [[ -f "$WPA_CONF" ]]; then
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
    echo "--- Interface details ---"
    if [[ -n "$detected_interface" ]]; then
        if command_exists ip; then
            ip -s link show dev "$INTERFACE" 2>&1 || true
            ip -4 addr show dev "$INTERFACE" 2>&1 || true
            echo
            echo "Routes:"
            ip route show 2>&1 || true
        else
            echo "ip not installed"
        fi
        if command_exists iw; then
            echo
            echo "Wireless link:"
            iw dev "$INTERFACE" link 2>&1 || true
        else
            echo "iw not installed"
        fi
    else
        if command_exists ip; then
            ip -o link show 2>&1 || true
        else
            echo "ip not installed"
        fi
        if command_exists iw; then
            iw dev 2>&1 || true
        else
            echo "iw not installed"
        fi
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
        dmesg 2>/dev/null | grep -Ei '1a2b|c820|331d|8821|88x2|rtl|realtek|wlan|wifi|wireless|802\.11|cfg80211|firmware|usb 1-|disconnect|udevd' | tail -120 || true
    else
        echo "dmesg not installed"
    fi
    return 0
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
    local choice current current_ip_addr detected_interface default_item="1"

    while true; do
        detected_interface=$(find_wireless_interface_once 2>/dev/null || true)
        [[ -n "$detected_interface" ]] && INTERFACE="$detected_interface"
        current=$(current_ssid)
        current=$(sanitize_control_text "$current")
        current_ip_addr=$(current_ip)

        [[ -z "$current" ]] && current="(not connected)"
        [[ -z "$current_ip_addr" ]] && current_ip_addr="(no IPv4 lease)"

        choice=$(capture_dialog dialog --backtitle "$__backtitle" --cancel-label "Exit" --default-item "$default_item" --menu "MiSTer WiFi tools\n\nCurrent network: $current\nCurrent IPv4: $current_ip_addr" 22 72 12 \
            1 "Scan and Connect" \
            2 "Connect to Saved WiFi" \
            3 "Disconnect from WiFi" \
            4 "Saved Networks" \
            5 "Set / fix country code" \
            6 "Diagnostics" \
            7 "Save diagnostics to file" \
            8 "Repair WPA config") || break

        default_item="$choice"

        case "$choice" in
            1)
                connect_wifi
                ;;
            2)
                connect_saved_wifi
                ;;
            3)
                disconnect_wifi
                ;;
            4)
                saved_networks_menu
                ;;
            5)
                prompt_country_code 1
                ;;
            6)
                show_diagnostics
                ;;
            7)
                save_diagnostics
                ;;
            8)
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
        --status|--health)
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

if [[ "${WIFI_LIBRARY_ONLY:-0}" == "1" ]]; then
    return 0 2>/dev/null || exit 0
fi

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
