#!/usr/bin/env python3
"""Campanha controlada: Ubiquity offline e mesmo QCOW2 em dois firmwares."""
import hashlib
import json
import os
import pathlib
import re
import secrets
import shutil
import socket
import subprocess
import tempfile
import time

ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'qa/portable'
ISO=ROOT/'dist/release/FENIX-OS-Legacy-amd64.iso'
HASH='1404e0c5dadecb595a3c031bd2538e51379579e18d412dc9ed7cea5b64f6c764'

def run(*cmd,**kw): return subprocess.run(cmd,check=True,**kw)
def digest(path):
    with path.open('rb') as stream: return hashlib.file_digest(stream,'sha256').hexdigest()

def align_cpio(output):
    # Cada cabeçalho newc deve começar em ALGN(4), inclusive após membro comprimido.
    output.write(b'\0' * (-output.tell() % 4))

def command(disk, mode, controller, acceleration, sock, serial, install=False, initrd=None, varfile=None):
    for path in (disk,sock,serial):
        if any(c in str(path) for c in (',','\n','\r')): raise ValueError('Caminho QEMU inválido')
    if disk.name!='destino.qcow2' or disk.is_symlink(): raise ValueError('Disco de QA inválido')
    cmd=['qemu-system-x86_64','-machine','pc','-accel',acceleration,'-cpu','Westmere',
         '-smp','2','-m','4096','-vga','std','-nic','none','-display','none',
         '-smbios','type=1,manufacturer=FENIX-QA,product=FENIX-QA-PORTABLE',
         '-drive',f'file={disk},format=qcow2,if=none,id=destino',
         '-serial',f'file:{serial}','-qmp',f'unix:{sock},server=on,wait=off','-no-reboot']
    if controller=='sata': cmd+=['-device','ich9-ahci,id=ahci','-device','ide-hd,drive=destino,bus=ahci.0,serial=FENIXQA001']
    elif controller=='nvme': cmd+=['-device','nvme,drive=destino,serial=FENIXQA001']
    elif controller=='ide': cmd+=['-device','ide-hd,drive=destino,serial=FENIXQA001']
    else: raise ValueError('Controlador desconhecido')
    if mode=='legacy': cmd+=['-bios','/usr/share/seabios/bios.bin']
    elif mode=='uefi' and varfile:
        cmd+=['-drive','if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd',
              '-drive',f'if=pflash,format=raw,file={varfile}']
    else: raise ValueError('Firmware/estado OVMF inválido')
    if install:
        cmd+=['-cdrom',str(ISO),'-kernel',str(OUT/'vmlinuz'),'-initrd',str(initrd),
              '-append','boot=casper username=mint hostname=fenix-qa fenix.qa=portable-v1 console=tty0 console=ttyS0,115200n8 quiet splash --']
    else: cmd+=['-boot','order=c']
    return cmd

def prepare(campaign):
    run('xorriso','-osirrox','on','-indev',str(ISO),'-extract','/casper/vmlinuz',str(OUT/'vmlinuz'),
        '-extract','/casper/initrd.lz',str(OUT/'initrd-original'))
    payload=OUT/'payload'; body=payload/'fenix-payload'; body.mkdir(parents=True)
    for path in (ROOT/'tools/portable').glob('*.sh'): shutil.copy2(path,body/path.name)
    (body/'campaign-id').write_text(campaign+'\n')
    # Credencial efêmera do usuário de teste, jamais publicada nos registros.
    password=secrets.token_urlsafe(24)
    hashed=subprocess.check_output(['openssl','passwd','-6','-stdin'],input=password.encode()).decode().strip()
    text=(ROOT/'tools/portable/preseed.cfg').read_text().replace('@PASSWORD_HASH@',hashed).replace('@PASSWORD@',password)
    (body/'preseed.cfg').write_text(text)
    os.chmod(body/'preseed.cfg',0o600)
    service='[Unit]\nAfter=display-manager.service\n[Service]\nType=oneshot\nExecStart=/bin/bash /opt/fenix-qa/guest-install.sh\n[Install]\nWantedBy=multi-user.target\n'
    (body/'install.service').write_text(service)
    (body/'probe.service').write_text('[Unit]\nAfter=display-manager.service\n[Service]\nType=oneshot\nExecStart=/usr/local/sbin/fenix-qa-probe\n[Install]\nWantedBy=multi-user.target\n')
    script=payload/'scripts/casper-bottom/99fenix-qa'; script.parent.mkdir(parents=True)
    script.write_text('''#!/bin/sh
case "$1" in prereqs) exit 0;; esac
grep -qw fenix.qa=portable-v1 /proc/cmdline || exit 0
dest="${rootmnt:-/root}"
mkdir -p "$dest/opt/fenix-qa" "$dest/etc/systemd/system/multi-user.target.wants"
cp -a /fenix-payload/. "$dest/opt/fenix-qa/"
cp /fenix-payload/install.service "$dest/etc/systemd/system/fenix-qa-install.service"
ln -s ../fenix-qa-install.service "$dest/etc/systemd/system/multi-user.target.wants/fenix-qa-install.service"
''')
    script.chmod(0o755)
    initrd=OUT/'initrd-qa'
    shutil.copyfile(OUT/'initrd-original',initrd)
    names=subprocess.check_output(['find','.','-print0'],cwd=payload)
    with initrd.open('ab') as output:
        align_cpio(output)
        run('cpio','--null','-o','--format=newc',input=names,cwd=payload,stdout=output)
    return initrd

def campaign_run(name, mode, controller, disk, acceleration, initrd=None):
    from PIL import Image
    case=OUT/name; case.mkdir()
    start=time.monotonic(); success=False
    rec=dict(status='NÃO EXECUTADO',firmware=mode,controlador=controller,iso_conectada=initrd is not None,
             disco=str(disk.relative_to(ROOT)),inode=disk.stat().st_ino,hash_antes=digest(disk),capturas=[])
    with tempfile.TemporaryDirectory(prefix='fenix-port-') as tmp:
        varfile=None
        if mode=='uefi':
            varfile=case/'OVMF_VARS.fd'
            shutil.copyfile('/usr/share/OVMF/OVMF_VARS_4M.fd',varfile)
        cmd=command(disk,mode,controller,acceleration,pathlib.Path(tmp)/'qmp.sock',case/'serial.log',
                    install=initrd is not None,initrd=initrd,varfile=varfile)
        rec['command']=cmd
        with (case/'qemu.log').open('w') as log:
            proc=subprocess.Popen(cmd,stdout=log,stderr=log)
            try:
                sock=pathlib.Path(tmp)/'qmp.sock'
                for _ in range(200):
                    if sock.exists(): break
                    if proc.poll() is not None: raise RuntimeError('QEMU encerrou antes do QMP')
                    time.sleep(.1)
                with socket.socket(socket.AF_UNIX) as client:
                    client.settimeout(30); client.connect(str(sock)); wire=client.makefile('rwb',buffering=0)
                    json.loads(wire.readline())
                    def qmp(cmd,args=None):
                        wire.write((json.dumps(dict(execute=cmd,arguments=args or {}))+'\n').encode())
                        while True:
                            value=json.loads(wire.readline())
                            if 'error' in value: raise RuntimeError(value)
                            if 'return' in value: return value['return']
                    qmp('qmp_capabilities')
                    deadline=2400 if initrd else 600
                    last_capture=-90; last_message=-60
                    while proc.poll() is None:
                        elapsed=time.monotonic()-start
                        serial=(case/'serial.log').read_text(errors='replace') if (case/'serial.log').exists() else ''
                        marker='FENIX_QA_INSTALADOR_CONCLUIDO' if initrd else 'FENIX_QA_BOOT_OK'
                        found=marker in serial
                        if 'Initramfs unpacking failed:' in serial:
                            raise RuntimeError('Kernel rejeitou o initramfs; consultar serial.log')
                        if initrd and elapsed>600 and 'FENIX_QA_LIVE_INICIADO' not in serial:
                            raise TimeoutError('Serviço de QA não iniciou no Live em 10 minutos')
                        if re.search(r'FENIX_QA_\w*ERROR',serial):
                            raise RuntimeError('Erro explícito no instalador/hook; consultar serial.log')
                        if elapsed-last_capture>=90 or (found and not success):
                            ppm=case/f'{int(elapsed):04}.ppm'
                            qmp('screendump',{'filename':str(ppm)})
                            with Image.open(ppm) as img: img.save(ppm.with_suffix('.png'))
                            ppm.unlink(); last_capture=elapsed; rec['capturas'].append(ppm.with_suffix('.png').name)
                        success=success or found
                        if elapsed-last_message>=60:
                            print(f'{name}: {int(elapsed)}s, marcador={success}',flush=True)
                            # Publicar apenas marcadores controlados; nada de senhas/debconf.
                            print('\n'.join(re.findall(r'^FENIX_QA_[A-Z_]+.*$',serial,re.M)[-3:]),flush=True)
                            last_message=elapsed
                        if elapsed>deadline: raise TimeoutError(f'{name}: tempo limite sem desligamento da VM')
                        time.sleep(3)
                if not success: raise RuntimeError('VM encerrou sem marcador de conclusão verificável')
                rec['status']='PASSOU'
                if not initrd:
                    match=re.search(r'FENIX_QA_BOOT_OK mode=(\w+) root_uuid=([\w-]+) campaign=([\w-]+) user=fenixqa',serial)
                    if not match or match[1]!=mode: raise RuntimeError('Firmware real não confere')
                    rec.update(root_uuid=match[2],disco_campanha=match[3])
            except Exception as error:
                rec.update(status='FALHOU',erro=str(error)); raise
            finally:
                if proc.poll() is None: proc.terminate()
                try: proc.wait(timeout=15)
                except subprocess.TimeoutExpired: proc.kill(); proc.wait()
                rec.update(duracao_segundos=round(time.monotonic()-start,2),qemu_exit=proc.returncode,hash_depois=digest(disk))
                (case/'resultado.json').write_text(json.dumps(rec,ensure_ascii=False,indent=2)+'\n')
    return rec

def main():
    if os.name!='posix' or not os.environ.get('GITHUB_ACTIONS'): raise SystemExit('Use a VM Linux efêmera do workflow oficial')
    if digest(ISO)!=HASH: raise SystemExit('ISO diverge da candidata de referência')
    OUT.mkdir(parents=True,exist_ok=False)
    campaign='fenix-'+os.environ['GITHUB_RUN_ID']+'-'+os.environ.get('GITHUB_RUN_ATTEMPT','1')
    summary=dict(disco_campanha=campaign,iso_sha256=HASH,status='BLOQUEADO',campanhas=[])
    disk=OUT/'destino.qcow2'
    run('qemu-img','create','-f','qcow2',str(disk),'32G')
    info=json.loads(subprocess.check_output(['qemu-img','info','--output=json',str(disk)]))
    if info.get('format')!='qcow2' or info.get('backing-filename'): raise SystemExit('Imagem não independente')
    acceleration='kvm' if os.access('/dev/kvm',os.R_OK|os.W_OK) else 'tcg'
    summary['aceleracao']=acceleration
    try:
        initrd=prepare(campaign)
        summary['campanhas'].append(campaign_run('instalacao','legacy','ide',disk,acceleration,initrd))
        identity=None
        for name,mode,controller in [('legacy-1','legacy','ide'),('uefi-1','uefi','ide'),
                                     ('retorno-legacy','legacy','ide'),('uefi-nvram-nova','uefi','ide'),
                                     ('uefi-sata','uefi','sata'),('uefi-nvme','uefi','nvme')]:
            rec=campaign_run(name,mode,controller,disk,acceleration)
            summary['campanhas'].append(rec)
            key=(rec['root_uuid'],rec['disco_campanha'],rec['inode'])
            if identity is not None and key!=identity: raise RuntimeError('Identidade do disco/raiz mudou')
            if rec['disco_campanha']!=campaign: raise RuntimeError('Campanha divergente')
            identity=key
        summary['status']='PASSOU'
    except Exception as error:
        summary.update(status='FALHOU',erro=str(error)); raise
    finally:
        (OUT/'resumo.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')

if __name__=='__main__': main()
