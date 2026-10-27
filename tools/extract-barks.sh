#!/usr/bin/env bash
# Dev-only: extract dialogue bark/persona assets and the dialogue component
# from the game pak for structure research. Read-only on the pak.
set -euo pipefail
cd "$(dirname "$0")/.."
P='/mnt/c/Program Files (x86)/GOG Galaxy/Games/MW5Mercs/MW5Mercs/Content/Paks/MW5Mercs-WindowsNoEditor.pak'
OUT=extracted
mkdir -p "$OUT"
repak unpack "$P" -o "$OUT" -f -q \
  -i MW5Mercs/Content/DLC7/Dialogue/Barks \
  -i MW5Mercs/Content/Dialogue/_common \
  -i MW5Mercs/Content/Audio/Events/Dialogue/Enemy_Radio_Chatter.uasset \
  -i MW5Mercs/Content/Audio/Events/Dialogue/Commander_Chatter.uasset \
  -i MW5Mercs/Content/Audio/Events/Dialogue/Dialogue_Radio_Chatter.uasset \
  -i MW5Mercs/Content/Audio/Events/Dialogue/DialogueContextTagPriorityData.uasset
find "$OUT" -type f | sed 's#^extracted/##' | sort
