#!/bin/bash
# Dev-only: after find-symbol.sh unpacked mods into /tmp/symchk, list which BASE-GAME
# assets each mod overrides (MW5Mercs/Content/...), and grep a symbol across them.
sym="${1:-GetCurrentMission}"
cd /tmp/symchk || exit 1
for m in */; do
  m=${m%/}
  n=$(find "$m/MW5Mercs/Content" -type f -name '*.uasset' 2>/dev/null | wc -l)
  echo "== $m: $n base-game asset overrides"
  find "$m/MW5Mercs/Content" -type f -name '*.uasset' 2>/dev/null | sed "s#^$m/MW5Mercs/Content/#   #" | head -60
done
echo "== files containing '$sym':"
grep -r -l -a -- "$sym" . | head -20
