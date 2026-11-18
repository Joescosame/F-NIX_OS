#!/usr/bin/env python3
"""Valida perfil declarado, sem presumir que toda instalação usa MBR/Legacy."""
def validar(firmware, tabela, esperado_firmware, esperado_tabela, esp_montada=False):
    if esperado_firmware not in ('legacy','uefi') or esperado_tabela not in ('dos','gpt'):
        raise ValueError('Perfil de firmware/particionamento desconhecido.')
    if firmware != esperado_firmware or tabela != esperado_tabela:
        raise ValueError('Firmware ou tabela real diverge do perfil de QA solicitado.')
    if firmware == 'uefi' and (tabela != 'gpt' or not esp_montada):
        raise ValueError('Perfil UEFI requer GPT e ESP FAT montada em /boot/efi.')
    return True

if __name__ == '__main__':
    import argparse
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('firmware'); p.add_argument('tabela')
    p.add_argument('esperado_firmware'); p.add_argument('esperado_tabela')
    p.add_argument('--esp-montada',action='store_true')
    a=p.parse_args()
    try: validar(a.firmware,a.tabela,a.esperado_firmware,a.esperado_tabela,a.esp_montada)
    except ValueError as erro: p.exit(1,'FALHOU: '+str(erro)+'\n')
