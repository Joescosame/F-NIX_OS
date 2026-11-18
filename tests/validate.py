#!/usr/bin/env python3
"""Validação portátil complementar a bash -n, ShellCheck e desktop-file-validate."""
import ast
import configparser
import pathlib
import xml.etree.ElementTree as ET
import yaml

ROOT = pathlib.Path(__file__).resolve().parents[1]
for folder in ('scripts', 'tools', 'tests'):
    for p in (ROOT / folder).rglob('*.py'):
        ast.parse(p.read_text(encoding='utf-8'), filename=str(p))
for p in (ROOT / 'assets').glob('*.desktop'):
    c = configparser.ConfigParser(interpolation=None, strict=True)
    c.optionxform = str
    c.read_string(p.read_text(encoding='utf-8'))
    assert c['Desktop Entry']['Type'] == 'Application', p
    assert c['Desktop Entry']['Name'] and c['Desktop Entry']['Exec'], p
ET.parse(ROOT / 'assets/fenix-hub.svg')
for p in (ROOT / '.github/workflows').glob('*.yml'):
    d = yaml.safe_load(p.read_text(encoding='utf-8'))
    # YAML 1.1 interpreta on como True; GitHub usa YAML 1.2.
    triggers = d.get('on', d.get(True))
    assert set(triggers) == {'workflow_dispatch'}, p
    assert d['permissions']['contents'] == 'read', p
required = ['README.md','LICENSE','CHANGELOG.md','docs/COMECE_AQUI.md','docs/ARQUITETURA.md',
            'docs/BUILD.md','docs/QA.md','docs/INSTALACAO_WINDOWS_RUFUS.md','docs/PORTABILIDADE.md',
            'docs/GIT_WINDOWS.md','docs/AUDITORIA.md']
for name in required:
    assert (ROOT / name).is_file(), name
for p in list((ROOT/'tools').glob('*.sh')) + list((ROOT/'scripts').glob('*.sh')):
    assert b'\r' not in p.read_bytes(), f'CRLF em {p}'
    assert p.read_bytes().startswith(b'#!/usr/bin/env bash\n'), p
print('PASSOU: Python AST, YAML, campos desktop, SVG, estrutura e finais de linha.')
