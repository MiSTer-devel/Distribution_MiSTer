#!/usr/bin/env bash
# Copyright (c) 2022-2025 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

git checkout -f develop -b main
git add .
git commit -m "-"
git fetch origin main || true
