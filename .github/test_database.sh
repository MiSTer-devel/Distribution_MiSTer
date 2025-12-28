#!/usr/bin/env bash
# Copyright (c) 2022-2025 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

echo "Testing ${DB_ID}: ${DB_JSON_NAME}"
echo

DB_URL="$(pwd)/${DB_JSON_NAME}"
cd "$(mktemp -d)"
curl --show-error --fail --location -o "downloader_test.py" "https://github.com/MiSTer-devel/Downloader_MiSTer/releases/download/latest/downloader_test.py"
chmod +x downloader_test.py
./downloader_test.py "${DB_ID}" "${DB_URL}"

echo
echo "The test went well."
