#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname -- "$0")/common.sh"
for c in shellcheck desktop-file-validate python3; do need "$c"; done
while IFS= read -r -d '' file; do
  bash -n "$file"
  shellcheck --external-sources --severity=warning --exclude=SC1091 "$file"
done < <(find "$ROOT/scripts" "$ROOT/tools" -name '*.sh' -print0)
for file in "$ROOT"/assets/*.desktop; do desktop-file-validate "$file"; done
python3 "$ROOT/tests/validate.py"
python3 -m unittest discover -s "$ROOT/tests" -v
echo 'PASSOU: validações estáticas e testes locais. Boot/instalação pendentes.'
