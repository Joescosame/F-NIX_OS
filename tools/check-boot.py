#!/usr/bin/env python3
"""Validação estrutural; nunca equivale a inicialização no QEMU."""
import pathlib
import re
import sys

def signature(path, plataformas=('BIOS',)):
    text = pathlib.Path(path).read_text()
    entries = re.findall(r'El Torito boot img\s*:\s*\d+\s+(BIOS|UEFI)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\d+)', text)
    for plataforma in plataformas:
        if not any(e[0] == plataforma and e[1] == 'y' for e in entries):
            raise SystemExit('FALHOU: nenhuma entrada habilitada para '+plataforma)
    if not re.search(r'System area summary:[^\n]*\bMBR\b', text):
        raise SystemExit('FALHOU: MBR híbrido ausente')
    return entries

if __name__ == '__main__':
    plataformas = ('BIOS','UEFI') if sys.argv[3:] == ['--dual'] else ('BIOS',)
    if sys.argv[3:] not in ([],['--dual']): raise SystemExit('Opção desconhecida; use --dual')
    if signature(sys.argv[1],plataformas) != signature(sys.argv[2],plataformas):
        raise SystemExit('FALHOU: plataformas ou atributos de boot divergiram')
    print('PASSOU: estrutura BIOS/El Torito preservada. Boot real pendente.')
