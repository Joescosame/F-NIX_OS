#!/usr/bin/env bash
set -Eeuo pipefail
here="$(cd -- "$(dirname -- "$0")" && pwd)"
exec python3 "$here/release.py" join "$here"
