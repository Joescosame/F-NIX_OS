#!/usr/bin/env python3
"""Validação estrutural; nunca equivale a inicialização no QEMU."""
import pathlib
import re
import sys

def signature(path):
    text = pathlib.Path(path).read_text()
    entries = re.findall(r'El Torito boot img\s*:\s*\d+\s+(BIOS|UEFI)\s+(\S+)\s+(\S+)', text)
    if not any(e[0] == 'BIOS' for e in entries):
        raise SystemExit('FALHOU: nenhuma entrada BIOS')
    if not re.search(r'System area summary:.*(MBR|isohybrid)', text):
        raise SystemExit('FALHOU: MBR híbrido ausente')
    return entries

if signature(sys.argv[1]) != signature(sys.argv[2]):
    raise SystemExit('FALHOU: plataformas ou atributos de boot divergiram')
print('PASSOU: estrutura BIOS/El Torito preservada. Boot real pendente.')
