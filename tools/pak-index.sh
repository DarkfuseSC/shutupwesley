#!/usr/bin/env bash
# Dev-only: dump the game pak index for asset-name research. Read-only on the pak.
set -euo pipefail
cd "$(dirname "$0")/.."
P='/mnt/c/Program Files (x86)/GOG Galaxy/Games/MW5Mercs/MW5Mercs/Content/Paks/MW5Mercs-WindowsNoEditor.pak'
repak info "$P" 2>&1 | head -8
repak list "$P" > pak-index.txt 2> pak-err.txt || true
wc -l pak-index.txt
head -c 300 pak-err.txt || true
