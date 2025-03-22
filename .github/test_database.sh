#!/usr/bin/env bash
# Copyright (c) 2022-2025 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

DB_URL="$(pwd)/${DB_JSON_NAME}"
DOWNLOADER="$(pwd)/Scripts/.config/downloader/downloader_latest.zip"

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
if [ -f "${DOWNLOADER}" ] ; then
  cp "${DOWNLOADER}" downloader
else
  # This allows this script to be used as a dependency. It's playing that role for other builds already, so please keep it in place.
  curl --show-error --fail --location -o "downloader" "https://github.com/MiSTer-devel/Downloader_MiSTer/releases/download/latest/dont_download.zip"
fi
chmod +x downloader

echo
echo "Running downloader"
export DEBUG=true
export CURL_SSL=""
export DOWNLOADER_INI_PATH="$(pwd)/downloader.ini"
./downloader

echo
echo "The test went well."
