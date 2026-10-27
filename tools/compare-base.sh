#!/bin/bash
# Dev-only: does a symbol exist in the CURRENT base-game copy of an asset vs a mod's override?
# Usage: compare-base.sh <symbol> <mod> <pak path> [<pak path> ...]
sym="${1:?symbol}"; mod="${2:?mod}"; shift 2
P="${PAK:-/mnt/c/Program Files (x86)/GOG Galaxy/Games/MW5Mercs/MW5Mercs/Content/Paks/MW5Mercs-WindowsNoEditor.pak}"
# PAK=<other pak> overrides the "base" side, e.g. to read a freshly installed mod pak.
for f in "$@"; do
  b=$(repak get "$P" "$f" 2>/dev/null | grep -c -a -- "$sym")
  m=$(grep -c -a -- "$sym" "/tmp/symchk/$mod/$f" 2>/dev/null)
  printf '%-62s base=%s %s=%s\n' "$f" "$b" "$mod" "$m"
done
