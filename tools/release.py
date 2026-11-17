#!/usr/bin/env python3
"""Divisão e reconstrução por streaming, com hashes e nomes estritos."""
import argparse
import hashlib
import json
import pathlib
import re
import shutil

NAME = 'FENIX-OS-Legacy-amd64.iso'
CHUNK = 8 * 1024 * 1024
PART_LIMIT = 1900 * 1024 * 1024

def digest(path):
    with path.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()

def validate(m):
    if m.get('schema') != 1 or m.get('iso') != NAME:
        raise ValueError('Manifesto inválido')
    if not re.fullmatch(r'[0-9a-f]{64}', m.get('sha256', '')):
        raise ValueError('Hash final inválido')
    if not isinstance(m.get('size'), int) or m['size'] <= 0:
        raise ValueError('Tamanho final inválido')
    parts = m.get('parts')
    if not isinstance(parts, list) or not 1 <= len(parts) <= 999:
        raise ValueError('Lista de partes inválida')
    for i, p in enumerate(parts, 1):
        if p.get('name') != f'{NAME}.part{i:03}' or not re.fullmatch(r'[0-9a-f]{64}', p.get('sha256', '')):
            raise ValueError('Nome/ordem/hash de parte inválido')
        if not isinstance(p.get('size'), int) or not 0 < p['size'] <= PART_LIMIT:
            raise ValueError('Parte excede limite')
    if sum(p['size'] for p in parts) != m['size']:
        raise ValueError('Soma de tamanhos incorreta')
    return m

def split(iso, out, part_size=PART_LIMIT):
    if iso.name != NAME or not iso.is_file() or iso.is_symlink():
        raise ValueError('Informe a ISO final regular com o nome padrão')
    if not 1 <= part_size <= PART_LIMIT:
        raise ValueError('Tamanho de parte inválido')
    out.mkdir(parents=True, exist_ok=False)
    m = dict(schema=1, iso=NAME, size=0, sha256='', parts=[])
    fullhash = hashlib.sha256()
    with iso.open('rb') as src:
        for i in range(1, 1000):
            first = src.read(min(CHUNK, part_size))
            if not first:
                break
            p = out / f'{NAME}.part{i:03}'
            ph = hashlib.sha256()
            size = 0
            with p.open('xb') as dst:
                data = first
                while data:
                    dst.write(data); fullhash.update(data); ph.update(data)
                    size += len(data)
                    if size == part_size:
                        break
                    data = src.read(min(CHUNK, part_size-size))
            m['parts'].append(dict(name=p.name, size=size, sha256=ph.hexdigest()))
            m['size'] += size
        if src.read(1):
            raise ValueError('Mais de 999 partes')
    m['sha256'] = fullhash.hexdigest()
    validate(m)
    (out / 'manifesto.json').write_text(json.dumps(m, indent=2)+'\n', encoding='utf-8')
    hashes = [(p['sha256'], p['name']) for p in m['parts']] + [(m['sha256'], NAME)]
    (out / 'SHA256SUMS').write_text(''.join(f'{h}  {n}\n' for h,n in hashes), encoding='utf-8')
    here = pathlib.Path(__file__).parent
    for name in ('JUNTAR_ISO.ps1', 'juntar-iso.sh', 'release.py'):
        shutil.copy2(here / name, out / name)
    return m

def join(folder):
    m = validate(json.loads((folder / 'manifesto.json').read_text(encoding='utf-8')))
    final = folder / NAME
    partial = folder / (NAME+'.partial')
    if final.exists() or partial.exists():
        raise FileExistsError('Saída já existe; não será sobrescrita')
    for p in m['parts']:
        path = folder / p['name']
        if path.is_symlink() or path.stat().st_size != p['size'] or digest(path) != p['sha256']:
            raise ValueError('Parte ausente/corrompida: '+p['name'])
    with partial.open('xb') as dst:
        for p in m['parts']:
            with (folder / p['name']).open('rb') as src:
                shutil.copyfileobj(src, dst, CHUNK)
    if partial.stat().st_size != m['size'] or digest(partial) != m['sha256']:
        raise ValueError('Hash final incorreto; saída parcial preservada para diagnóstico')
    partial.rename(final)
    print('PASSOU: ISO reconstruída e SHA-256 final conferido:', final)
    return final

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='action', required=True)
    sp = sub.add_parser('split'); sp.add_argument('iso', type=pathlib.Path); sp.add_argument('out', type=pathlib.Path)
    jp = sub.add_parser('join'); jp.add_argument('folder', type=pathlib.Path)
    args = parser.parse_args()
    if args.action == 'split': split(args.iso, args.out)
    else: join(args.folder)
