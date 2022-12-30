#!/usr/bin/env bash
# Copyright (c) 2022 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

DB_URL="$(pwd)/${DB_JSON_NAME}"

cd "$(mktemp -d)"
echo "[mister]" > downloader.ini
echo "base_path = $(pwd)" >> downloader.ini
echo "base_system_path = $(pwd)" >> downloader.ini
echo "update_linux = false" >> downloader.ini
echo "allow_reboot  = 0" >> downloader.ini
echo "verbose = false" >> downloader.ini
echo "downloader_retries = 0" >> downloader.ini
echo "[${DB_ID}]" >> downloader.ini
echo "db_url = ${DB_URL}" >> downloader.ini

echo "downloader.ini :"
cat downloader.ini
echo
curl --show-error --fail --location -o "downloader.sh" "https://raw.githubusercontent.com/MiSTer-devel/Downloader_MiSTer/main/downloader.sh"
chmod +x downloader.sh

echo
echo "Running downloader"
export DEBUG=true
export CURL_SSL=""
./downloader.sh

echo
echo "The test went well."