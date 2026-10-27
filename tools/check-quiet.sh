#!/bin/bash
# Dev-only: in the packaged Quiet pak, every cooked bark book must still carry its
# Context tags (unlike Silent) and differ from the shipped original (MaxPlaysPerMission=1).
PAK="${1:-/mnt/d/Epic Games/Epic Games/MechWarrior5Editor/MW5Mercs/Mods/Paks/ShutUpWesley.pak}"
ORIG="$(cd "$(dirname "$0")/.." && pwd)/extracted"
W=/tmp/suwq; rm -rf "$W"; mkdir -p "$W"; cd "$W" || exit 1
repak unpack "$PAK" -o out >/dev/null 2>&1 || { echo "unpack failed"; exit 1; }
n=0; same=0; notag=0
for f in $(find out -path '*MW5Mercs/Content/DLC7*' -name '*Barks.uasset' | sort); do
  b=$(basename "$f" .uasset); o=$(find "$ORIG" -name "$b.uasset" | head -1); n=$((n+1))
  cmp -s "$o" "$f" && same=$((same+1))
  [ "$(strings -n 8 "$f" | grep -c 'DialogueContext')" -eq 0 ] && notag=$((notag+1))
done
echo "--- $n books, $same identical to original, $notag without DialogueContext names (expect 0 for Quiet)"
