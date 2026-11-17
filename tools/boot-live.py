#!/usr/bin/env python3
"""Coleta limitada de boot real; aprovação exige revisão das capturas."""
import hashlib
import json
import pathlib
import socket
import subprocess
import tempfile
import time
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
ISO = ROOT/'dist/release/FENIX-OS-Legacy-amd64.iso'
EXPECTED = '1404e0c5dadecb595a3c031bd2538e51379579e18d412dc9ed7cea5b64f6c764'
OUT = ROOT/'qa/boot-live'

def main():
    with ISO.open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    if actual != EXPECTED or ISO.stat().st_size != 3218407424:
        raise SystemExit('FALHOU: candidata diferente da aprovada para este teste')
    OUT.mkdir(parents=True, exist_ok=False)
    start = time.monotonic()
    record = dict(iso_sha256=actual, iso_bytes=ISO.stat().st_size,
                  status='BLOQUEADO', motivo='Aguardando revisão visual das capturas reais',
                  instalacao='NÃO EXECUTADO', reboot_disco='NÃO EXECUTADO', capturas=[])
    with tempfile.TemporaryDirectory(prefix='fenix-qmp-') as tmp:
        sock = pathlib.Path(tmp)/'qmp.sock'
        cmd = ['qemu-system-x86_64', '-machine', 'pc', '-accel', 'tcg',
               '-cpu', 'Westmere', '-smp', '2', '-m', '4096',
               '-bios', '/usr/share/seabios/bios.bin', '-vga', 'std',
               '-nic', 'none', '-boot', 'order=d', '-cdrom', str(ISO),
               '-display', 'none', '-qmp', f'unix:{sock},server=on,wait=off',
               '-serial', f'file:{OUT}/serial.log', '-no-reboot']
        record['command'] = cmd
        with (OUT/'qemu.log').open('w') as log:
            proc = subprocess.Popen(cmd, stdout=log, stderr=log)
            try:
                for _ in range(100):
                    if sock.exists(): break
                    if proc.poll() is not None: raise RuntimeError('QEMU encerrou antes do QMP')
                    time.sleep(.1)
                with socket.socket(socket.AF_UNIX) as client:
                    client.settimeout(20)
                    client.connect(str(sock))
                    wire = client.makefile('rwb', buffering=0)
                    json.loads(wire.readline())
                    def qmp(command, args=None):
                        wire.write((json.dumps(dict(execute=command, arguments=args or {}))+'\n').encode())
                        while True:
                            reply = json.loads(wire.readline())
                            if 'error' in reply: raise RuntimeError(reply)
                            if 'return' in reply: return reply['return']
                    qmp('qmp_capabilities')
                    for seconds in [2, 5, 15, 30, 60, 90, 120, 180, 240, 360, 480, 600]:
                        while time.monotonic()-start < seconds:
                            if proc.poll() is not None: raise RuntimeError('QEMU encerrou durante boot')
                            time.sleep(.5)
                        ppm = OUT/f'{seconds:04}.ppm'
                        qmp('screendump', dict(filename=str(ppm)))
                        with Image.open(ppm) as frame:
                            frame.save(ppm.with_suffix('.png'))
                        ppm.unlink()
                        record['capturas'].append(dict(segundos=round(time.monotonic()-start,2), arquivo=f'{seconds:04}.png'))
                        print(f'Captura real: {seconds}s', flush=True)
                        if seconds == 15:
                            qmp('human-monitor-command', dict(**{'command-line':'sendkey ret'}))
                    qmp('quit')
            except Exception as error:
                record.update(status='FALHOU', motivo=str(error))
                raise
            finally:
                if proc.poll() is None: proc.terminate()
                try: proc.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    proc.kill(); proc.wait()
                record['duration_seconds'] = round(time.monotonic()-start,2)
                (OUT/'resultado.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n')

if __name__ == '__main__': main()
