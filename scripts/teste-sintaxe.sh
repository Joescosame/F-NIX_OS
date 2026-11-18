#!/usr/bin/env bash
# Rodar no host antes de usar o Cubic; testes estáticos, não provam boot.
set -Eeuo pipefail
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
for file in "$base"/scripts/*.sh; do bash -n "$file"; done
python3 -m py_compile "$base/scripts/historico-sensores.py"
python3 - "$base" <<'PY'
import pathlib,sys,xml.etree.ElementTree as ET
root=pathlib.Path(sys.argv[1]); ET.parse(root/'assets/fenix-hub.svg')
for d in (root/'assets').glob('*.desktop'):
    assert d.read_text().startswith('[Desktop Entry]'), d
for f in ('install-packages.sh','configure-xfce.sh','configure-gestures.sh',
'cleanup-optimize.sh','hub-testes.sh','salvar-snapshot.sh','stage-into-root.sh'):
    assert (root/'scripts'/f).is_file(),f
print('Sintaxe Bash, Python, SVG, .desktop: OK')
PY
