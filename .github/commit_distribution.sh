#!/usr/bin/env bash
# Copyright (c) 2022 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

git config --global user.email "theypsilon@gmail.com"
git config --global user.name "The CI/CD Bot"
git checkout -f develop -b main
git add .
git commit -m "-"
git fetch origin main || true
