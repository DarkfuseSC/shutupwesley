#!/bin/bash
# Dev-only: which installed mod pak contains a given symbol string (paks are compressed,
# so each is unpacked to /tmp first). Usage: find-symbol.sh <symbol> [mod ...]
sym="${1:?symbol}"; shift
M='/mnt/c/Program Files (x86)/GOG Galaxy/Games/MW5Mercs/MW5Mercs/Mods'
mods=("$@"); [ ${#mods[@]} -eq 0 ] && mods=(Coyotesmission PurchaseSalvage ModOptions ShutUpWesley YetAnotherMechlab)
for m in "${mods[@]}"; do
  for f in "$M/$m"/Paks/*.pak; do
    w=/tmp/symchk/$(basename "$f" .pak); rm -rf "$w"; mkdir -p "$w"
    repak unpack "$f" -o "$w" >/dev/null 2>&1 || { echo "$m: unpack failed"; continue; }
    hits=$(grep -r -l -a -- "$sym" "$w" | sed "s#$w/##")
    printf '%-28s %s\n' "$(basename "$f")" "$(echo "$hits" | grep -c . )"
    echo "$hits" | grep . | head -5 | sed 's/^/     /'
  done
done
