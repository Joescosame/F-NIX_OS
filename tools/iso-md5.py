#!/usr/bin/env python3
"""Atualiza o verificador de mídia sem incluir o próprio manifesto/boot mutável."""
import hashlib
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
with (root / 'md5sum.txt').open('w', encoding='utf-8', newline='\n') as stream:
    for p in sorted(root.rglob('*')):
        rel = p.relative_to(root).as_posix()
        if p.is_symlink() or not p.is_file() or rel in ('md5sum.txt', 'isolinux/boot.cat', 'isolinux/isolinux.bin', 'boot.catalog'):
            continue
        with p.open('rb') as f:
            digest = hashlib.file_digest(f, 'md5').hexdigest()
        stream.write(f'{digest}  ./{rel}\n')
