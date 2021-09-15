#!/usr/bin/env bash
# Copyright (c) 2021 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

update_distribution() {
    local OUTPUT_FOLDER="${1}"
    local PUSH_COMMAND="${2:-}"

    fetch_core_urls
    classify_core_categories

    if [[ "${LINUX_GITHUB_REPOSITORY:-}" != "" ]] ; then
        local LINUX_JSON_STR=$(curl -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${LINUX_GITHUB_REPOSITORY}/git/trees/HEAD")
        local LATEST_LINUX=$(echo $LINUX_JSON_STR | jq -r '.tree[].path' | grep '^release.*\.7[zZ]$' | sort | tail -n 1)
        echo "${LATEST_LINUX}" > latest_linux.txt
    fi

    for url in ${!CORE_CATEGORIES[@]} ; do
        for category in ${CORE_CATEGORIES[${url}]} ; do
            process_url "${url}" "${category}" "${OUTPUT_FOLDER}"
        done
    done

    if [[ "${PUSH_COMMAND}" == "--push" ]] ; then
        git checkout -f develop -b main 
        git add "${OUTPUT_FOLDER}"
        git commit -m "-"
        git fetch origin main || true
        if ! git diff --quiet main origin/main^ ; then
            echo "Calculating db..."
            ./.github/calculate_db.py
        else
            echo "Nothing to be updated."
        fi
    fi
}

CORE_URLS=
fetch_core_urls() {
    local MISTER_URL="https://github.com/MiSTer-devel/Main_MiSTer"
    CORE_URLS=$(curl -sSLf "$MISTER_URL/wiki"| awk '/user-content-fpga-cores/,/user-content-development/' | grep -ioE '(https://github.com/[a-zA-Z0-9./_-]*[_-]MiSTer/tree/[a-zA-Z0-9-]+)|(https://github.com/[a-zA-Z0-9./_-]*[_-]MiSTer)|(user-content-[a-zA-Z0-9-]*)')
    local MENU_URL=$(echo "${CORE_URLS}" | grep -io 'https://github.com/[a-zA-Z0-9./_-]*Menu_MiSTer')
    CORE_URLS=$(echo "${CORE_URLS}" |  sed 's/https:\/\/github.com\/[a-zA-Z0-9.\/_-]*Menu_MiSTer//')
    CORE_URLS=${MISTER_URL}$'\n'${MENU_URL}$'\n'${CORE_URLS}$'\n'"user-content-arcade-cores"$'\n'$(curl -sSLf "$MISTER_URL/wiki/Arcade-Cores-List"| awk '/wiki-content/,/wiki-rightbar/' | grep -io '\(https://github.com/[a-zA-Z0-9./_-]*_MiSTer\)' | awk '!a[$0]++')
    CORE_URLS=${CORE_URLS}$'\n'"user-content-zip-release"$'\n'"https://github.com/MiSTer-devel/Filters_MiSTer"
    CORE_URLS=${CORE_URLS}$'\n'"user-content-fonts"$'\n'"https://github.com/MiSTer-devel/Fonts_MiSTer"
    CORE_URLS=${CORE_URLS}$'\n'"user-content-scripts"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/ini_settings.sh"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/samba_on.sh"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/other_authors/fast_USB_polling_on.sh"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/other_authors/fast_USB_polling_off.sh"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/other_authors/wifi.sh"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/rtc.sh"
    CORE_URLS=${CORE_URLS}$'\n'"https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/timezone.sh"
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
            "user-content-zip-release") ;&
            "user-content-scripts") ;&
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

process_url() {
    local URL="${1}"
    local CATEGORY="${2}"
    local TARGET_DIR="${3}"

    case "${CATEGORY}" in
        "user-content-scripts")
            install_script "${URL}" "${TARGET_DIR}"
            return
            ;;
        *) ;;
    esac

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
        "user-content-fonts") INSTALLER=install_fonts ;;
        *) INSTALLER=install_other_core ;;
    esac
    
    if [[ "${URL}" =~ Atari800 ]] ; then
        INSTALLER=install_atari800
    fi

    ${INSTALLER} "${TMP_FOLDER}" "${TARGET_DIR}" "${CATEGORY}"

    rm -rf "${TMP_FOLDER}"
}

install_arcade_core() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

    touch_folder "${TARGET_DIR}/games/hbmame"
    touch_folder "${TARGET_DIR}/games/mame"

    local BINARY_NAMES=$(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq)
    if [[ "${BINARY_NAMES}" == "MRA-Alternatives" ]] ; then
        install_zip_release "${TMP_FOLDER}" "${TARGET_DIR}/_Arcade" 
        return
    fi

    for bin in ${BINARY_NAMES} ; do

        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
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

    for bin in $(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq) ; do

        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/_Console/${LAST_RELEASE_FILE}"
    done

    for folder in $(game_folders "${TMP_FOLDER}") ; do
        for readme in $(ls "${TMP_FOLDER}" | grep -i "readme.") ; do
            copy_file "${TMP_FOLDER}/${readme}" "${TARGET_DIR}/games/${folder}/${readme}"
        done

        for palette in $(files_with_stripped_date "${TMP_FOLDER}/palettes" | uniq) ; do

            get_latest_palette "${TMP_FOLDER}" "palettes"
            local LAST_PALETTE_FILE="${GET_LATEST_PALETTE_RET}"

            if is_not_zip_release "${LAST_PALETTE_FILE}" ; then
                continue
            fi

            local PALETTES_TMP=$(mktemp -d)
            unzip -o "${TMP_FOLDER}/palettes/${LAST_PALETTE_FILE}" -d "${PALETTES_TMP}/"
            pushd "${PALETTES_TMP}" > /dev/null 2>&1
            find . -type f -not -iname '*.pal' -and -not -iname '*.gbp' -delete
            find . -type f -print0 | while IFS= read -r -d '' file ; do touch -a -m -t 202108231405 "${file}" ; done
            zip -q -0 -D -X -A -r "Palettes.zip" *
            popd > /dev/null 2>&1
            mv "${PALETTES_TMP}/Palettes.zip" "${TARGET_DIR}/games/${folder}/Palettes.zip"
            rm -rf "${PALETTES_TMP}"
        done

        touch_folder "${TARGET_DIR}/games/${folder}"
    done
}

install_computer_core() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

    for bin in $(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq) ; do

        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/_Computer/${LAST_RELEASE_FILE}"
    done

    for folder in $(game_folders "${TMP_FOLDER}") ; do

        for file in $(files_with_no_date "${TMP_FOLDER}/releases") ; do
            copy_file "${TMP_FOLDER}/releases/${file}" "${TARGET_DIR}/games/${folder}/${file}"
        done

        for readme in $(ls "${TMP_FOLDER}" | grep -i "readme.") ; do
            copy_file "${TMP_FOLDER}/${readme}" "${TARGET_DIR}/games/${folder}/${readme}"
        done

        touch_folder "${TARGET_DIR}/games/${folder}"
    done
}

install_other_core() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local CATEGORY="${3}"
    local IFS=$'\n'

    for bin in $(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq) ; do

        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/${CATEGORY}/${LAST_RELEASE_FILE}"
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

    for bin in $(files_with_stripped_date "${TMP_FOLDER}/releases" | grep "${NAME}" | uniq) ; do

        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/${CATEGORY}/${LAST_RELEASE_FILE}"
    done
}

install_main_binary() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

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

install_zip_release() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

    for zip in $(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq) ; do

        get_latest_release "${TMP_FOLDER}" "${zip}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_empty_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        unzip -o "${TMP_FOLDER}/releases/${GET_LATEST_RELEASE_RET}" -d "${TARGET_DIR}/"
    done
}

install_fonts() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

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
    local ACTUAL_EXTENSION="${INPUT_FILE#*.}"
    if [[ "${INPUT_FILE}" == "" ]] || [[ "${ACTUAL_EXTENSION,,}" != "${EXPECTED_EXTENSION,,}" ]] ; then
        >&2 echo "Not ${EXPECTED_EXTENSION^^}."
        return 0
    fi
    return 1
}

is_empty_release() {
    local RELEASE_FILE="${1}"
    if [[ "${RELEASE_FILE}" == "" ]] ; then
        >&2 echo "Empty."
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    update_distribution "${1}" "${2:-}"
fi
