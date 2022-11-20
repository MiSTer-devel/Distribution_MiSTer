#!/usr/bin/env bash
# Copyright (c) 2022 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

git config --global user.email "theypsilon@gmail.com"
git config --global user.name "The CI/CD Bot"
git checkout -f develop -b main
echo "Running detox"
detox -v -s utf_8-only -r *
echo "Detox done"
echo "Removing colons"
IFS=$'\n'
for i in $(find . -name "*:*"); do
    echo mv "${i}" "${i/:/-}"
    mv "${i}" "${i/:/-}"
done
echo "Colons removed"
git add .
git commit -m "-"
git fetch origin main || true
