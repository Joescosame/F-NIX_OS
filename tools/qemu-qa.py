#!/usr/bin/env python3
"""Inicia QA isolado em SeaBIOS; concluir instalação requer operador no instalador."""
import argparse
import datetime
import hashlib
import json
import os
import pathlib
import shutil
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]

def validate_image_info(info):
    details = info.get('format-specific', {}).get('data', {})
    if (info.get('format') != 'qcow2' or info.get('backing-filename') or
            info.get('full-backing-filename') or info.get('data-file') or details.get('data-file')):
        raise ValueError('Disco deve ser qcow2 independente, sem backing/data file')

def command(mode, iso, disk, bios, ram=4096, online=False):
    if mode not in ('install', 'reboot') or not 4096 <= ram <= 8192:
        raise ValueError('Modo/RAM inválido')
    for p in (iso, disk, bios):
        if any(c in str(p) for c in (',', '\n', '\r')):
            raise ValueError('Nome de caminho não permitido pelo QEMU')
    cmd = ['qemu-system-x86_64', '-machine', 'pc', '-accel', 'tcg', '-cpu', 'Westmere',
           '-smp', '2', '-m', str(ram), '-bios', str(bios), '-vga', 'std',
           '-drive', f'file={disk},format=qcow2,if=ide', '-no-reboot']
    cmd += ['-nic', 'user,model=e1000'] if online else ['-nic', 'none']
    if mode == 'install':
        cmd += ['-boot', 'order=d', '-cdrom', str(iso)]
    else:
        cmd += ['-boot', 'order=c']
    return cmd

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['install', 'reboot'])
    parser.add_argument('--online', action='store_true', help='segunda campanha, com novo disco separado')
    parser.add_argument('--ram', type=int, default=4096)
    args = parser.parse_args()
    if os.name != 'posix':
        parser.error('Use host Linux com QEMU/SeaBIOS')
    iso = ROOT / 'dist/FENIX-OS-Legacy-amd64.iso'
    if not iso.is_file() or iso.is_symlink():
        parser.error('ISO final regular ausente')
    bios = pathlib.Path('/usr/share/seabios/bios.bin')
    for tool in ('qemu-system-x86_64', 'qemu-img'):
        if not shutil.which(tool): parser.error('Dependência ausente: '+tool)
    if not bios.is_file(): parser.error('Instale seabios')
    case = ROOT / 'qa' / ('online' if args.online else 'offline')
    case.mkdir(parents=True, exist_ok=True)
    # Nenhum caminho de disco é aceito da linha de comando.
    disk = case / 'destino.qcow2'
    if disk.is_symlink(): parser.error('Link de disco proibido')
    if disk.resolve().parent != case.resolve(): parser.error('Disco fora da pasta QA')
    with iso.open('rb') as f:
        iso_hash = hashlib.file_digest(f, 'sha256').hexdigest()
    identity = case / 'iso-sha256.txt'
    if args.mode == 'install':
        if disk.exists(): parser.error('Disco já existe. Preserve evidências e use outro checkout para nova campanha.')
        subprocess.run(['qemu-img', 'create', '-f', 'qcow2', str(disk), '32G'], check=True)
        identity.write_text(iso_hash+'\n')
    elif not disk.is_file() or not identity.exists() or identity.read_text().strip() != iso_hash:
        parser.error('Disco ausente ou pertence a outra ISO')
    info = json.loads(subprocess.check_output(['qemu-img', 'info', '--output=json', str(disk)]))
    try:
        validate_image_info(info)
    except ValueError as error:
        parser.error(str(error))
    cmd = command(args.mode, iso, disk, bios, args.ram, args.online)
    record = dict(mode=args.mode, iso_sha256=iso_hash, command=cmd,
                  started=datetime.datetime.now(datetime.timezone.utc).isoformat(), status='NÃO EXECUTADO',
                  note='Saída QEMU não comprova instalador/login. Anexar evidências conforme docs/QA.md.')
    evidence = case / (args.mode+'-execution.json')
    if evidence.exists(): parser.error('Registro já existe; não sobrescrever evidências')
    evidence.write_text(json.dumps(record, indent=2, ensure_ascii=False))
    print('Instale manualmente somente no disco virtual QEMU. Offline por padrão.')
    print('Após concluir, desligue a VM e execute o modo reboot (sem CD).')
    with (case / (args.mode+'-qemu.log')).open('x') as log:
        result = subprocess.run(cmd, stdout=log, stderr=log)
    record['qemu_exit_code'] = result.returncode
    record['ended'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    evidence.write_text(json.dumps(record, indent=2, ensure_ascii=False))
    if result.returncode: raise SystemExit(result.returncode)
    print('VM encerrada. Resultado funcional NÃO APROVADO automaticamente; registre evidências.')

if __name__ == '__main__': main()
