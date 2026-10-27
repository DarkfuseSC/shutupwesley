#!/usr/bin/env bash
# Dev-only: list a packaged mod pak and confirm the override books are inside.
set -euo pipefail
P="${1:?pak path (linux form)}"
repak info "$P" | head -4
echo "== entries:"
repak list "$P" | sort
echo "== book count:"
repak list "$P" | grep -c 'Dialogue/Barks/.*\.uasset$' || true
