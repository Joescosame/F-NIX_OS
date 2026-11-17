#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname -- "$0")/common.sh"
python3 "$ROOT/tools/release.py" split "$ROOT/dist/FENIX-OS-Legacy-amd64.iso" "$ROOT/dist/release"
echo 'Partes preparadas localmente; publicação não executada.'
