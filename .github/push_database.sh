#!/usr/bin/env bash
# Copyright (c) 2022-2025 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

echo "Fetch unshallow"
git fetch --unshallow origin || true

git stash
CUR_BRANCH=$(git rev-parse --abbrev-ref HEAD)
ZIPS=$(git ls-files --directory . -o --exclude-standard | grep '.zip$' || true)
if [[ "${ZIPS}" != "" ]] ; then
    echo "Adding ZIPs: ${ZIPS}"
    git checkout --orphan zips
    git reset
    git add ${ZIPS}
    git commit -m "-"
    ZIPS_BRANCH_SHA=$(git rev-parse --verify HEAD)
    echo "Writing ZIP SHA: ${ZIPS_BRANCH_SHA} to ${DB_JSON_NAME}"
    sed -i "s/<ZIPS_BRANCH_BASE_URL>/${ZIPS_BRANCH_SHA}/g" "${DB_JSON_NAME}"
    git checkout --force "${CUR_BRANCH}"
fi
DB_ZIP_NAME="${DB_JSON_NAME}.zip"
echo "Creating ${DB_ZIP_NAME} from ${DB_JSON_NAME}."

git stash pop || true
zip "${DB_ZIP_NAME}" "${DB_JSON_NAME}"
git add "${DB_ZIP_NAME}"
git add README.md
git commit -m "-"
if [[ "${ZIPS}" != "" ]] ; then
    git push --force origin zips
fi
git push --force origin "${CUR_BRANCH}"

if ! which gh > /dev/null 2>&1 ; then
    echo "No 'gh' command."
    exit 0
fi

gh release download all_releases --pattern releases.txt || true
DATE=$(date +"%Y-%m-%d %T")
echo "$DATE: $(git rev-parse --verify HEAD)" >> releases.txt
gh release create all_releases || true
gh release upload all_releases releases.txt --clobber
