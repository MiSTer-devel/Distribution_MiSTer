#!/usr/bin/env bash
# Copyright (c) 2021-2022 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

update_distribution() {
    local OUTPUT_FOLDER="${1}"

    git fetch --unshallow origin

    fetch_core_urls
    echo
    echo "CORE_URLs:"
    echo ${CORE_URLS}
    echo
    classify_core_categories

    if [[ "${LINUX_GITHUB_REPOSITORY:-}" != "" ]] ; then
        local LINUX_JSON_STR=$(curl -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${LINUX_GITHUB_REPOSITORY}/git/trees/HEAD")
        local LATEST_LINUX=$(echo $LINUX_JSON_STR | jq -r '.tree[].path' | grep '^release.*\.7[zZ]$' | sort | tail -n 1)
        echo "${LATEST_LINUX}" > latest_linux.txt
    fi
    
    local job_counter=0
    for url in ${!CORE_CATEGORIES[@]} ; do
        for category in ${CORE_CATEGORIES[${url}]} ; do
            process_url "${url}" "${category}" "${OUTPUT_FOLDER}" &
        done
        if [ ${job_counter} -ge 100 ] ; then
            wait_jobs
            job_counter=0
        else
            job_counter=$((job_counter + 1))
        fi
    done
    
    wait_jobs
}

wait_jobs() {
    for job in `jobs -p` ; do
        wait ${job} || {
            echo "Failed job ${job}!"
            exit 1
        }
    done
}

CORE_URLS=
fetch_core_urls() {
    local WIKI_URL="https://raw.githubusercontent.com/wiki/MiSTer-devel/Wiki_MiSTer"
    CORE_URLS="https://github.com/MiSTer-devel/Main_MiSTer"$'\n'"https://github.com/MiSTer-devel/Menu_MiSTer"
    CORE_URLS=${CORE_URLS}$'\n'"user-content-mra-alternatives"$'\n'"https://github.com/MiSTer-devel/MRA-Alternatives_MiSTer"
    CORE_URLS=${CORE_URLS}$'\n'$(most_cores "${WIKI_URL}" | uniq -u)
    CORE_URLS=${CORE_URLS}$'\n'"user-content-arcade-cores"$'\n'$(arcade_cores "${WIKI_URL}" | uniq -u)
    CORE_URLS=${CORE_URLS}$'\n'"user-content-fonts"$'\n'"https://github.com/MiSTer-devel/Fonts_MiSTer"
    CORE_URLS=${CORE_URLS}$'\n'"user-content-folders-Filters|Filters_Audio|Gamma"$'\n'"https://github.com/MiSTer-devel/Filters_MiSTer"
    CORE_URLS=${CORE_URLS}$'\n'"user-content-folders-Shadow_Masks"$'\n'"https://github.com/MiSTer-devel/ShadowMasks_MiSTer"
    CORE_URLS=${CORE_URLS}$'\n'"user-content-folders-Presets"$'\n'"https://github.com/MiSTer-devel/Presets_MiSTer"
    CORE_URLS=${CORE_URLS}$'\n'"user-content-scripts"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/ini_settings.sh"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/samba_on.sh"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/other_authors/fast_USB_polling_on.sh"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/other_authors/fast_USB_polling_off.sh"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/other_authors/wifi.sh"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/rtc.sh"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/timezone.sh"
    CORE_URLS=${CORE_URLS}$'\n'"user-content-linux-binary"$'\n'"https://github.com/MiSTer-devel/PDFViewer_MiSTer"
    CORE_URLS=${CORE_URLS}$'\n'"user-content-empty-folder"$'\n'"games/TGFX16-CD"
    CORE_URLS=${CORE_URLS}$'\n'"user-content-gamecontrollerdb"$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Gamecontrollerdb_MiSTer/main/gamecontrollerdb.txt"
    CORE_URLS=${CORE_URLS}$'\n'"user-cheats"$'\n'"https://gamehacking.org/mister/"
}

most_cores() {
    local WIKI_URL="${1}"
    curl -sSLf "${WIKI_URL}/_Sidebar.md" | python3 -c "
import sys, re
regex = re.compile(r'https://github.com/MiSTer-devel/[a-zA-Z0-9._-]*[_-]MiSTer(/tree/[a-zA-Z0-9-]+)?', re.I)
reading = False
for line in sys.stdin.readlines():
    match = regex.search(line)
    line = line.strip().lower()
    if 'fpga cores' in line or 'service cores' in line:
        reading = True
    if reading is False:
        continue
    if line.startswith('###'):
        if 'development' in line[4:] or 'arcade cores' in line[4:]:
            reading = False
        else:
            print('user-content-%s' % line[4:].replace(' ', '-'))
    elif match is not None:
        core = match.group(0)
        if 'menu_mister' not in core.lower():
            print(core)
"
}

arcade_cores() {
    local WIKI_URL="${1}"
    curl -sSLf "${WIKI_URL}/Arcade-Cores-List.md" | python3 -c "
import sys, re
regex = re.compile(r'https://github.com/MiSTer-devel/[a-zA-Z0-9._-]*[_-]MiSTer[^\/]', re.I)
for line in sys.stdin.readlines():
    match = regex.search(line)
    if match is not None:
        print(match.group(0)[0:-1])
"
}

cat_local_core_urls() {
    CORE_URLS=$(cat local_core_urls.txt)
}

declare -A CORE_CATEGORIES
classify_core_categories() {
    local CURRENT_CORE_CATEGORY="main"
    for url in ${CORE_URLS[@]} ; do
        case "${url}" in
            "user-content-computers---classic") CURRENT_CORE_CATEGORY="_Computer" ;;
            "user-content-arcade-cores") CURRENT_CORE_CATEGORY="_Arcade" ;;
            "user-content-consoles---classic") CURRENT_CORE_CATEGORY="_Console" ;;
            "user-content-other-systems") CURRENT_CORE_CATEGORY="_Other" ;;
            "user-content-service-cores") CURRENT_CORE_CATEGORY="_Utility" ;;
            "user-content-linux-binary") ;&
            "user-content-zip-release") ;&
            "user-content-scripts") ;&
            "user-cheats") ;&
            "user-content-empty-folder") ;&
            "user-content-gamecontrollerdb") ;&
            "user-content-folders-"*) ;&
            "user-content-mra-alternatives") ;&
            "user-content-mra-alternatives-under-releases") ;&
            "user-content-fonts") CURRENT_CORE_CATEGORY="${url}" ;;
            "user-content-fpga-cores") ;&
            "user-content-development") ;&
            "user-content-fpga-cores") ;&
            "") ;;
            *)
                if [[ "${CORE_CATEGORIES[${url}]:-false}" == "false" ]] ; then
                    CORE_CATEGORIES["${url}"]="${CURRENT_CORE_CATEGORY}"
                elif is_standard_core "${CORE_CATEGORIES[${url}]}" && is_standard_core "${CURRENT_CORE_CATEGORY}" ; then
                    CORE_CATEGORIES["${url}"]="${CORE_CATEGORIES[${url}]} ${CURRENT_CORE_CATEGORY}"
                elif [[ "${CORE_CATEGORIES[${url}]}" != "${CURRENT_CORE_CATEGORY}" ]] ; then
                    echo "Already processed ${url} as ${CORE_CATEGORIES["${url}"]}. Tried to be processed again as ${CURRENT_CORE_CATEGORY}."
                fi
                ;;
        esac
    done
}

is_standard_core() {
    local CATEGORY="${1}"
    if [[ "${CATEGORY}" == "_Arcade" ]] \
    || [[ "${CATEGORY}" == "_Computer" ]] \
    || [[ "${CATEGORY}" == "_Other" ]] \
    || [[ "${CATEGORY}" == "_Console" ]] ; then
        return 0
    else
        return 1
    fi
}

PROCESS_URL_CTX=
process_url() {
    local URL="${1}"
    local CATEGORY="${2}"
    local TARGET_DIR="${3}"

    PROCESS_URL_CTX="${URL}"

    local EARLY_INSTALLER=
    case "${CATEGORY}" in
        "user-content-scripts") EARLY_INSTALLER=install_script ;;
        "user-content-empty-folder") EARLY_INSTALLER=install_empty_folder ;;
        "user-cheats") EARLY_INSTALLER=install_cheats ;;
        "user-content-gamecontrollerdb") EARLY_INSTALLER=install_gamecontrollerdb ;;
        *) ;;
    esac
    
    if [[ "${EARLY_INSTALLER}" != "" ]] ; then
        ${EARLY_INSTALLER} "${URL}" "${TARGET_DIR}"
        return
    fi

    if ! [[ ${URL} =~ ^([a-zA-Z]+://)?github.com(:[0-9]+)?/([a-zA-Z0-9_-]*)/([a-zA-Z0-9_-]*)(/tree/([a-zA-Z0-9_-]+))?$ ]] ; then
        >&2 echo "WARNING! Wrong repository url '${URL}'."
        return
    fi

    local GITHUB_OWNER="${BASH_REMATCH[3]}"
    local GITHUB_REPO="${BASH_REMATCH[4]}"
    local GITHUB_BRANCH="${BASH_REMATCH[6]:-}"

    local TMP_FOLDER="$(mktemp -d)"

    download_repository "${TMP_FOLDER}" "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}.git" "${GITHUB_BRANCH}"

    local INSTALLER=
    case "${CATEGORY}" in
        "_Arcade") INSTALLER=install_arcade_core ;;
        "_Computer") INSTALLER=install_computer_core ;;
        "_Console") INSTALLER=install_console_core ;;
        "main") INSTALLER=install_main_binary ;;
        "user-content-zip-release") INSTALLER=install_zip_release ;;
        "user-content-linux-binary") INSTALLER=install_linux_binary ;;
        "user-content-fonts") INSTALLER=install_fonts ;;
        "user-content-mra-alternatives") INSTALLER=install_mra_alternatives ;;
        "user-content-mra-alternatives-under-releases") INSTALLER=install_mra_alternatives_under_releases ;;
        "user-content-folders-"*) INSTALLER=install_folders ;;
        *) INSTALLER=install_other_core ;;
    esac
    
    if [[ "${URL}" =~ Atari800 ]] ; then
        INSTALLER=install_atari800
    fi

    ${INSTALLER} "${TMP_FOLDER}" "${TARGET_DIR}" "${CATEGORY}" "${URL}"

    rm -rf "${TMP_FOLDER}"
}

install_arcade_core() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

    touch_folder "${TARGET_DIR}/games/hbmame"
    touch_folder "${TARGET_DIR}/games/mame"

    if [ ! -d "${TMP_FOLDER}/releases" ] ; then
        return
    fi

    local BINARY_NAMES=$(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq)
    if [[ "${BINARY_NAMES}" == "MRA-Alternatives" ]] ; then
        return
    fi
    
    local ARCADE_INSTALLED="false"

    for bin in ${BINARY_NAMES} ; do

        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        if is_arcade_core "${bin}" ; then
            ARCADE_INSTALLED="true"
        elif [[ "${ARCADE_INSTALLED}" == "true" ]] ; then
            continue
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/_Arcade/cores/${LAST_RELEASE_FILE#Arcade-}"
    done

    for mra in $(mra_files "${TMP_FOLDER}/releases") ; do
        copy_file "${TMP_FOLDER}/releases/${mra}" "${TARGET_DIR}/_Arcade/${mra}"
    done
}

install_console_core() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

    if [ ! -d "${TMP_FOLDER}/releases" ] ; then
        return
    fi

    for bin in $(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq) ; do

        if is_arcade_core "${bin}" ; then
            continue
        fi
        
        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/_Console/${LAST_RELEASE_FILE}"
    done

    for folder in $(game_folders "${TMP_FOLDER}") ; do
        for readme in $(ls "${TMP_FOLDER}" | grep -i "readme.") ; do
            copy_file "${TMP_FOLDER}/${readme}" "${TARGET_DIR}/docs/${folder}/${readme}"
        done

        for file in $(files_with_no_date "${TMP_FOLDER}/releases") ; do
            local EXTENSION="${file##*.}"
            if [[ "${EXTENSION,,}" == "mra" ]] ; then
                continue
            fi
            copy_file_according_to_extension "${TMP_FOLDER}/releases/${file}" "${TARGET_DIR}" "${folder}" "${file}" "_Console"
        done

        touch_folder "${TARGET_DIR}/games/${folder}"

        local TARGET_PALETTES_FOLDER="${TARGET_DIR}/games/${folder}/Palettes/"
        for palette_folder in Palette Palettes palettes ; do
            local SOURCE_PALETTES_FOLDER="${TMP_FOLDER}/${palette_folder}/"
            if [ ! -d "${SOURCE_PALETTES_FOLDER}" ] ; then
                continue
            fi
            
            cp -r "${SOURCE_PALETTES_FOLDER}" "${TARGET_PALETTES_FOLDER}"
            pushd "${TARGET_PALETTES_FOLDER}" > /dev/null 2>&1
            find . -type f -not -iname '*.pal' -and -not -iname '*.gbp' -delete
            popd > /dev/null 2>&1  
            break
        done

    done
}

install_computer_core() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

    if [ ! -d "${TMP_FOLDER}/releases" ] ; then
        return
    fi

    for bin in $(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq) ; do

        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/_Computer/${LAST_RELEASE_FILE}"
    done

    for folder in $(game_folders "${TMP_FOLDER}") ; do

        if [[ "${folder}" == "Minimig" ]] ; then
            folder="Amiga"
        elif [[ "${folder}" == "SHARP MZ SERIES" ]] ; then
            folder="SharpMZ"
        fi

        for readme in $(ls "${TMP_FOLDER}" | grep -i "readme.") ; do
            copy_file "${TMP_FOLDER}/${readme}" "${TARGET_DIR}/docs/${folder}/${readme}"
        done

        for file in $(files_with_no_date "${TMP_FOLDER}/releases") ; do
            copy_file_according_to_extension "${TMP_FOLDER}/releases/${file}" "${TARGET_DIR}" "${folder}" "${file}" "_Computer"
        done

        touch_folder "${TARGET_DIR}/games/${folder}"
    done
}

install_other_core() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local CATEGORY="${3}"
    local IFS=$'\n'

    if [ ! -d "${TMP_FOLDER}/releases" ] ; then
        return
    fi

    for bin in $(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq) ; do

        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/${CATEGORY}/${LAST_RELEASE_FILE}"
    done

    for folder in $(game_folders "${TMP_FOLDER}") ; do

        for readme in $(ls "${TMP_FOLDER}" | grep -i "readme.") ; do
            copy_file "${TMP_FOLDER}/${readme}" "${TARGET_DIR}/docs/${folder}/${readme}"
        done

        for file in $(files_with_no_date "${TMP_FOLDER}/releases") ; do
            copy_file_according_to_extension "${TMP_FOLDER}/releases/${file}" "${TARGET_DIR}" "${folder}" "${file}" "${CATEGORY}"
        done
    done
}

install_atari800() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local CATEGORY="${3}"
    local IFS=$'\n'
    
    local NAME=
    case "${CATEGORY}" in
        "_Computer") NAME="Atari800" ;;
        "_Console") NAME="Atari5200" ;;
        *)
            echo "Could not install Atari 800 core. (CATEGORY=${CATEGORY})"
            exit 1
            ;;
    esac

    if [ ! -d "${TMP_FOLDER}/releases" ] ; then
        return
    fi

    for bin in $(files_with_stripped_date "${TMP_FOLDER}/releases" | grep "${NAME}" | uniq) ; do

        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/${CATEGORY}/${LAST_RELEASE_FILE}"
    done

    for folder in $(game_folders "${TMP_FOLDER}") ; do

        if [[ "${CATEGORY}" == "_Computer" ]] ; then
            for file in $(files_with_no_date "${TMP_FOLDER}/releases") ; do
                copy_file_according_to_extension "${TMP_FOLDER}/releases/${file}" "${TARGET_DIR}" "${folder}" "${file}" "${CATEGORY}"
            done
        fi

        for readme in $(ls "${TMP_FOLDER}" | grep -i "readme.") ; do
            copy_file "${TMP_FOLDER}/${readme}" "${TARGET_DIR}/docs/${folder}/${readme}"
        done

        touch_folder "${TARGET_DIR}/games/${folder}"
    done
}

install_main_binary() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

    if [ ! -d "${TMP_FOLDER}/releases" ] ; then
        return
    fi

    for bin in $(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq) ; do

        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_empty_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        local FILE_EXTENSION=".${LAST_RELEASE_FILE#*.}"
        if [[ ".${LAST_RELEASE_FILE}" == "${FILE_EXTENSION}" ]] ; then
            FILE_EXTENSION="" # Handling files without extensions, like Main.
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/${bin%%?????????}${FILE_EXTENSION}"
    done
}

install_linux_binary() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

    if [ ! -d "${TMP_FOLDER}/releases" ] ; then
        return
    fi

    for bin in $(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq) ; do

        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_empty_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/linux/${LAST_RELEASE_FILE%%?????????}"
    done
}

install_zip_release() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

    if [ ! -d "${TMP_FOLDER}/releases" ] ; then
        return
    fi

    for zip in $(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq) ; do

        get_latest_release "${TMP_FOLDER}" "${zip}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_empty_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        echo "unzip ${TMP_FOLDER}/releases/${GET_LATEST_RELEASE_RET} to ${TARGET_DIR}/"
        unzip -q -o "${TMP_FOLDER}/releases/${GET_LATEST_RELEASE_RET}" -d "${TARGET_DIR}/"
    done
}

install_mra_alternatives() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"

    echo "Installing MRA Alternatives ${4}"

    mkdir -p "${TARGET_DIR}/_Arcade"
    copy_file "${TMP_FOLDER}/_alternatives" "${TARGET_DIR}/_Arcade/_alternatives"
}

install_mra_alternatives_under_releases() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"

    echo "Installing MRA Alternatives under /releases ${4}"
    
    if [[ "$(ls -a ${TMP_FOLDER}/releases/_alternatives/ 2> /dev/null)" == "" ]] ; then
        >&2 echo "WARNING! _alternatives folder is empty."
        return
    fi

    mkdir -p "${TARGET_DIR}/_Arcade/_alternatives"
    cp -r "${TMP_FOLDER}/releases/_alternatives/"* "${TARGET_DIR}/_Arcade/_alternatives/"
}

install_fonts() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

    echo "Installing Fonts ${4}"

    for font in $(ls "${TMP_FOLDER}" | grep .pf) ; do
        copy_file "${TMP_FOLDER}/${font}" "${TARGET_DIR}/font/${font}"
    done
}

install_script() {
    local URL="${1}"
    local TARGET_DIR="${2}"

    mkdir -p "${TARGET_DIR}/Scripts" || true
    echo "Script: ${URL}"
    pushd "${TARGET_DIR}/Scripts" > /dev/null 2>&1
    curl -sSLf "${URL}" -O
    popd > /dev/null 2>&1
}

install_empty_folder() {
    local URL="${1}"
    local TARGET_DIR="${2}"
    touch_folder "${TARGET_DIR}/${URL}"
}

install_gamecontrollerdb() {
    local URL="${1}"
    local TARGET_DIR="${2}"

    mkdir -p "${TARGET_DIR}/linux/gamecontrollerdb/" || true
    echo "SDL Game Controller DB: ${URL}"
    pushd "${TARGET_DIR}/linux/gamecontrollerdb/" > /dev/null 2>&1
    curl -sSLf "${URL}" -O
    popd > /dev/null 2>&1
}

declare -A CHEAT_MAPPINGS=( \
    ["fds"]="NES" \
    ["gb"]="GameBoy" \
    ["gba"]="GBA" \
    ["gbc"]="GameBoy" \
    ["gen"]="Genesis" \
    ["gg"]="SMS" \
    ["lnx"]="AtariLynx" \
    ["nes"]="NES" \
    ["pce"]="TGFX16" \
    ["pcd"]="TGFX16-CD" \
    ["psx"]="PSX" \
    ["scd"]="MegaCD" \
    ["sms"]="SMS" \
    ["snes"]="SNES" \
)

install_cheats() {
    local URL="${1}"
    local TARGET_DIR="${2}"
    #install_cheats_backup "${TARGET_DIR}"
    #return

    mkdir -p "${TARGET_DIR}/Cheats/"

    local CHEAT_URLS=$(curl -sSLf --cookie "challenge=BitMitigate.com" "${URL}" | grep -oE '"mister_[^_]+_[0-9]{8}.zip"' | sed 's/"//g')
    for cheat_key in ${!CHEAT_MAPPINGS[@]} ; do
        local cheat_platform=${CHEAT_MAPPINGS[${cheat_key}]}
        local cheat_zip=$(echo "${CHEAT_URLS}" | grep "mister_${cheat_key}_")
        local cheat_url="${URL}${cheat_zip}"
        echo "cheat_key: ${cheat_key}, cheat_platform: ${cheat_platform}, cheat_zip: ${cheat_zip}, cheat_url: ${cheat_url}"

        mkdir -p "${TARGET_DIR}/Cheats/${cheat_platform}"
        curl --silent --show-error --fail --location -o "/tmp/${cheat_platform}.zip" "${cheat_url}"
        unzip -q -o "/tmp/${cheat_platform}.zip" -d "${TARGET_DIR}/Cheats/${cheat_platform}"
    done
}

install_cheats_backup() {
    local TARGET_DIR="${1}"
    curl --silent --show-error --fail --location -o "/tmp/old_main.zip" "https://github.com/MiSTer-devel/Distribution_MiSTer/archive/refs/heads/main.zip"
    unzip -q -o "/tmp/old_main.zip" -d "/tmp/"
    cp -r "/tmp/Distribution_MiSTer-main/Cheats/" "${TARGET_DIR}/Cheats/"
}

GET_LATEST_RELEASE_RET=
get_latest_release() {
    echo "BINARY_NAME: ${2}"
    get_latest_special_file "${1}" "${2}" "releases"
    GET_LATEST_RELEASE_RET="${GET_LATEST_SPECIAL_FILE_RET}"
}

GET_LATEST_PALETTE_RET=
get_latest_palette() {
    get_latest_special_file "${1}" "Palettes" "${2}"
    GET_LATEST_PALETTE_RET="${GET_LATEST_SPECIAL_FILE_RET}"
}

GET_LATEST_SPECIAL_FILE_RET=
get_latest_special_file() {
    local TMP_FOLDER="${1}"
    local BINARY_NAME="${2}"
    local SPECIAL_FOLDER="${3}"
    GET_LATEST_SPECIAL_FILE_RET=$(cd "${TMP_FOLDER}/${SPECIAL_FOLDER}/" ; git ls-files -z | xargs -0 -n1 -I{} -- git log -1 --format="%ai {}" {} | grep -i "${BINARY_NAME}_[0-9]\{8\}" | sort --ignore-case | tail -n1 | awk '{ print substr($0, index($0,$4)) }')
    if [[ "${GET_LATEST_SPECIAL_FILE_RET}" == "" ]] ; then
        >&2 echo "WARNING! No ${SPECIAL_FOLDER} files for binary '${BINARY_NAME}'"
    fi
}

copy_file() {
    local SOURCE="${1}"
    local TARGET="${2}"

    mkdir -p "${TARGET%/*}"
    cp -r "${SOURCE}" "${TARGET}"
}

copy_file_according_to_extension() {
    local SOURCE="${1}"
    local TARGET_DIR="${2}"
    local SYSTEM_FOLDER="${3}"
    local FILE="${4}"
    local CATEGORY="${5}"

    if is_mgl_file "${FILE}" ; then
        copy_file "${SOURCE}" "${TARGET_DIR}/${CATEGORY}/${FILE}"
    elif is_doc_file "${FILE}" ; then
        copy_file "${SOURCE}" "${TARGET_DIR}/docs/${SYSTEM_FOLDER}/${FILE}"
    else
        copy_file "${SOURCE}" "${TARGET_DIR}/games/${SYSTEM_FOLDER}/${FILE}"
    fi
}

is_mgl_file() {
    is_file_extension "${1}" "mgl"
}

is_doc_file() {
    local FILE="${1}"
    local EXTENSION="${FILE##*.}"
    case "${EXTENSION,,}" in
            "pdf") ;&
            "md") ;&
            "txt") ;&
            "rtf")
                return 0
                ;;
            *)
                return 1
                ;;
    esac
}

touch_folder() {
    local FOLDER="${1}"
    if [ -d "${FOLDER}" ] ; then
        return
    fi
    mkdir -p "${FOLDER}"
    touch "${FOLDER}/.delme"
}

is_not_rbf_release() {
    is_not_file_extension "${1}" "rbf"
}

is_not_zip_release() {
    is_not_file_extension "${1}" "zip"
}

is_not_file_extension() {
    local INPUT_FILE="${1}"
    local EXPECTED_EXTENSION="${2}"
    if is_file_extension "${INPUT_FILE}" "${EXPECTED_EXTENSION}" ; then
        return 1
    fi
    >&2 echo "${PROCESS_URL_CTX}: ${INPUT_FILE} is NOT a ${EXPECTED_EXTENSION^^} file."
    return 0
}

is_file_extension() {
    local INPUT_FILE="${1}"
    local EXPECTED_EXTENSION="${2}"
    local ACTUAL_EXTENSION="${INPUT_FILE#*.}"
    if [[ "${INPUT_FILE}" == "" ]] || [[ "${ACTUAL_EXTENSION,,}" != "${EXPECTED_EXTENSION,,}" ]] ; then
        return 1
    fi
    return 0
}

is_empty_release() {
    local RELEASE_FILE="${1}"
    if [[ "${RELEASE_FILE}" == "" ]] ; then
        >&2 echo "Empty."
        return 0
    fi
    return 1
}

is_arcade_core() {
    if [[ "${1^^}" =~ ^ARCADE-.*$ ]] ; then
        return 0
    fi
    return 1
}

download_repository() {
    local FOLDER="${1}"
    local GIT_URL="${2}"
    local BRANCH="${3}"
    pushd "${TMP_FOLDER}" > /dev/null 2>&1
    git init -q
    git remote add origin "${GIT_URL}"
    git -c protocol.version=2 fetch --depth=1 -q --no-tags --prune --no-recurse-submodules origin "${BRANCH}"
    git checkout -qf FETCH_HEAD
    popd > /dev/null 2>&1
}

files_with_stripped_date() {
    local FOLDER="${1}"
    pushd "${FOLDER}" > /dev/null 2>&1
    for file in *; do
        local WITH_DATE="${file%.*}"
        if [[ "${WITH_DATE}" =~ ^.+_([0-9]{8})$ ]] ; then
            echo "${WITH_DATE%%?????????}"
        fi
    done
    popd > /dev/null 2>&1
}

files_with_no_date() {
    local FOLDER="${1}"
    pushd "${FOLDER}" > /dev/null 2>&1
    for file in *; do
        if ! [[ "${file}" =~ ^.+_([0-9]{8})(\..+)?$ ]] ; then
            echo "${file}"
        fi
    done
    popd > /dev/null 2>&1
}

mra_files() {
    local FOLDER="${1}"
    pushd "${FOLDER}" > /dev/null 2>&1
    for mra in *.[mM][rR][aA]; do
        echo "${mra}"
    done
    popd > /dev/null 2>&1
}

game_folders() {
    local TMP_FOLDER="${1}"
    for folder in $(game_folders_from_conf_str "${TMP_FOLDER}") ; do
        echo "${folder}"
        for file in $(files_with_no_date "${TMP_FOLDER}/releases") ; do
            if is_mgl_file "${file}" ; then
                extract_from_setname_tag "${TMP_FOLDER}/releases/${file}"
            fi
        done
    done
}

game_folders_from_conf_str() {
    local FOLDER="${1}"
    pushd "${FOLDER}" > /dev/null 2>&1
    extract_from_conf_str "localparam"
    extract_from_conf_str "parameter"
    popd > /dev/null 2>&1
}


extract_from_conf_str() {
    local PARAMETER="${1}"
    for conf_line in $(grep -H * -e "\s*${PARAMETER}\s\s*CONF_STR1\{0,1\}\s*=" 2> /dev/null) ; do
        if [[ "${conf_line}" =~ ^(.*):.*$ ]] ; then
            local CONF_FILE="${BASH_REMATCH[1]}"
            local PATTERN=".*${PARAMETER}[[:space:]]*CONF_STR1{0,1}[[:space:]]*=[[:space:]]*\{[[:space:]]*\"([^[:cntrl:];]+)\;[^[:cntrl:];]*;[[:space:]]*\""
            if [[ "$(cat ${CONF_FILE})" =~ ${PATTERN} ]] ; then
                local GAME_FOLDER="${BASH_REMATCH[1]}"
                echo "${GAME_FOLDER}"
            fi
        fi
    done
}

extract_from_setname_tag() {
    local FILE="${1}"
    python3 -c "
import xml.etree.ElementTree as ET
try:
    for _, elem in ET.iterparse('${FILE}', events=('start',)):
        if elem.tag.lower() == 'setname' and elem.text is not None:
            print(elem.text.strip())
except ET.ParseError as e:
    pass
"
}

install_folders() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local CATEGORY="${3}"
    local URL="${4}"
    local IFS=$'\n'

    if ! [[ ${CATEGORY} =~ ^user-content-folders-(([a-zA-Z0-9_-]+[|]?)+)$ ]] ; then
        >&2 echo "WARNING! Wrong category '${CATEGORY}' or wrong repository url '${URL}'."
        return
    fi

    local FOLDERS="${BASH_REMATCH[1]}"

    local IFS="|"
    for folder in ${FOLDERS} ; do
        echo "Installing folder '${folder}' from ${URL}"

        copy_file "${TMP_FOLDER}/${folder}" "${TARGET_DIR}/${folder}"
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    update_distribution "${1}"
fi
