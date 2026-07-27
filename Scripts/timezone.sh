#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Copyright 2019 Alessandro "Locutus73" Miele

# You can download the latest version of this script from:
# https://github.com/MiSTer-devel/Scripts_MiSTer

# Version 1.4 - 2026-06-09 - Update menu system to use dialog
# Version 1.3 - 2025-01-02 - Manual selection with country and city, added automatic/manual option.
# Version 1.2 - 2019-03-02 - Changed "/media/fat/timezone" to "/media/fat/linux/timezone", removed -k option from curl.
# Version 1.1 - 2019-01-08 - Changed "http://ip-api.com/json/" to "http://www.ip-api.com/json/".
# Version 1.0 - 2019-01-08 - First commit.


if ! mode=$(dialog \
    --title "Choose timezone setting method" \
    --menu "" \
    10 40 2 \
    a Automatic \
    m Manual \
    3>&1 1>&2 2>&3) ; then echo "Cancelled"; exit 1; fi

if [ "$mode" == "a" ]; then
    echo "Querying ip-api.com for timezone..."
    TIMEZONE="$(curl -sLf "http://www.ip-api.com/json/" | jq -rM .timezone)"
elif [ "$mode" == "m" ]; then
    COUNTRY_LIST=()
    while IFS= read -r country; do
        COUNTRY_LIST+=("$country" "")
    done < <(
        find /usr/share/zoneinfo/posix -mindepth 1 -maxdepth 1 -type d | \
        sed 's|/usr/share/zoneinfo/posix/||' | \
        sort)

    if ! SELECTED_COUNTRY=$(
        dialog \
            --title "Select your continent/region" \
            --menu "" \
            20 50 10 \
            "${COUNTRY_LIST[@]}" \
            3>&1 1>&2 2>&3
    ) ; then echo "Cancelled"; exit 1; fi

    CITY_LIST=()
    while IFS= read -r city; do
        CITY_LIST+=("$city" "")
    done < <(
        find "/usr/share/zoneinfo/posix/$SELECTED_COUNTRY" -type f | \
        sed "s|/usr/share/zoneinfo/posix/$SELECTED_COUNTRY/||" | \
        sort)

    if ! CITY_CHOICE=$(
        dialog \
            --title "Select your city" \
            --menu "" \
            20 50 10 \
            "${CITY_LIST[@]}" \
            3>&1 1>&2 2>&3
    ) ; then echo "Cancelled"; exit 1; fi

    TIMEZONE="$SELECTED_COUNTRY/$CITY_CHOICE"
fi

echo "Setting timezone set to $TIMEZONE."
if echo "$TIMEZONE" | grep -qE "^.+[/].+$"; then
    cp "/usr/share/zoneinfo/posix/$TIMEZONE" "/media/fat/linux/timezone"
    echo "Timezone set to $TIMEZONE."
else
    echo "Unable to set timezone to $TIMEZONE. Please check your input or try again."
fi

exit 0
