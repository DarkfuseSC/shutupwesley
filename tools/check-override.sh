#!/bin/bash
# Dev-only. Unpacks the packaged pak and confirms the /Game/DLC7 override books
# differ from the shipped originals and no longer carry Bark.* context tags.
set -u
PAK='/mnt/d/Epic Games/Epic Games/MechWarrior5Editor/MW5Mercs/Mods/Paks/ShutUpWesley.pak'
ORIG="$(cd "$(dirname "$0")/.." && pwd)/extracted"   # from tools/extract-barks.sh
W=/tmp/suwchk
rm -rf "$W"; mkdir -p "$W"; cd "$W" || exit 1
repak unpack "$PAK" -o out >/dev/null 2>&1 || { echo "unpack failed"; exit 1; }
n=0; same=0; tagged=0
for f in $(find out -path '*MW5Mercs/Content/DLC7*' -name '*Barks.uasset' | sort); do
  b=$(basename "$f" .uasset)
  o=$(find "$ORIG" -name "$b.uasset" | head -1)
  n=$((n+1))
  if [ -n "$o" ] && cmp -s "$o" "$f"; then same=$((same+1)); echo "SAME     $b"; fi
  t=$(strings -n 5 "$f" | grep -c 'Bark\.')
  ot=$(strings -n 5 "$o" | grep -c 'Bark\.')
  [ "$t" -gt 0 ] && tagged=$((tagged+1))
  printf '%-26s cooked-size=%8d orig-size=%8d Bark.* names: mod=%d orig=%d\n' "$b" "$(stat -c %s "$f")" "$(stat -c %s "$o")" "$t" "$ot"
done
echo "--- $n override books, $same identical to original, $tagged still carrying Bark.* tags"
