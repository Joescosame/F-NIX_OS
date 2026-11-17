#!/usr/bin/env python3
"""Gate de evidências declaradas pelo operador; não substitui sua revisão."""
import hashlib
import json
import pathlib
import re
import sys

REQUIRED = {'legacy_live','offline_install_mbr','disk_boot_without_iso',
            'login_xfce_hub','history_snapshot','zram_swap_services'}

def check(root):
    qa = root / 'qa'
    data = json.loads((qa/'aprovacao.json').read_text(encoding='utf-8'))
    iso = root/'dist/FENIX-OS-Legacy-amd64.iso'
    if not re.fullmatch('[0-9a-f]{64}',data.get('iso_sha256','')):
        raise ValueError('Hash de aprovação inválido')
    with iso.open('rb') as f:
        if hashlib.file_digest(f,'sha256').hexdigest() != data['iso_sha256']:
            raise ValueError('Aprovação pertence a outra ISO')
    for name in REQUIRED:
        test = data.get('tests',{}).get(name,{})
        if test.get('status') != 'PASSOU' or not test.get('evidence'):
            raise ValueError('Sem aprovação/evidências: '+name)
        for evidence in test['evidence']:
            rel = pathlib.PurePosixPath(evidence)
            if rel.is_absolute() or '..' in rel.parts or '\\' in evidence or ':' in evidence:
                raise ValueError('Caminho de evidência inválido')
            p = qa / evidence
            if not p.is_file() or p.stat().st_size == 0 or not p.resolve().is_relative_to(qa.resolve()):
                raise ValueError('Evidência ausente/vazia/fora do QA: '+evidence)
    print('PASSOU: hash e evidências declaradas. Publicação somente draft prerelease.')
    return data

if __name__ == '__main__': check(pathlib.Path(__file__).resolve().parents[1])
