#!/usr/bin/env python3
"""Preserva exclusões do instalador, retendo os pacotes FÊNIX no destino."""
import pathlib
import sys

casper, root = map(pathlib.Path, sys.argv[1:])
lines = (casper / 'filesystem.manifest').read_text().splitlines()
installed = {line.split()[0] for line in lines if line.strip()}
removed = set((casper / 'filesystem.manifest-remove').read_text().split())
required = set((root / 'usr/local/share/fenix/required-packages.txt').read_text().split())
for name in installed:
    if name.startswith(('ubiquity', 'casper', 'live-')):
        if name in required:
            raise SystemExit('Pacote Live incluído indevidamente no perfil')
removed -= required
(casper / 'filesystem.manifest-remove').write_text(''.join(n+'\n' for n in sorted(removed)))
(casper / 'filesystem.manifest-desktop').write_text(''.join(line+'\n' for line in lines if line.split()[0] not in removed))
missing = required - installed
if missing:
    raise SystemExit(f'Pacotes FÊNIX ausentes: {sorted(missing)}')
