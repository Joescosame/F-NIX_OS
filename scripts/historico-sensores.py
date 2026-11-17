#!/usr/bin/env python3
"""Coletor leve FÊNIX: sensores do kernel + carga CPU/RAM em CSV e JSONL."""
import argparse, csv, datetime, json, os, pathlib, time

os.umask(0o077)

parser = argparse.ArgumentParser(description='Histórico leve de sensores FÊNIX')
parser.add_argument('--duration', type=int, default=120, help='duração em segundos')
parser.add_argument('--interval', type=float, default=5.0, help='intervalo em segundos')
parser.add_argument('--output-dir', type=pathlib.Path, help='diretório local de saída')
a = parser.parse_args()
if not (1 <= a.duration <= 86400 and 0.5 <= a.interval <= 3600):
    parser.error('duração/intervalo fora dos limites')
root = a.output_dir or pathlib.Path.home() / 'TestesPC' / 'historico'
root.mkdir(parents=True, exist_ok=True)
identifier = datetime.datetime.now().strftime('%Y%m%d_%H%M%S_%f') + f'_{os.getpid()}'
jsonpath = root / f'sensores_{identifier}.jsonl'
csvpath = root / f'sensores_{identifier}.csv'

def probe():
    samples = {}
    for sensor in sorted(pathlib.Path('/sys/class/hwmon').glob('hwmon*')):
        try:
            chip = (sensor / 'name').read_text().strip()
        except (OSError, UnicodeDecodeError):
            chip = sensor.name
        for probe_file in sorted(sensor.glob('*_input')):
            name = probe_file.stem
            if not name.startswith(('temp', 'fan', 'in')):
                continue
            try:
                value = float(probe_file.read_text().strip())
            except (OSError, ValueError):
                continue
            if name.startswith('temp'):
                value /= 1000.0
            elif name.startswith('in'):
                value /= 1000.0
            samples[f'{chip}/{sensor.name}/{name}'] = round(value, 3)
    try:
        for row in pathlib.Path('/proc/meminfo').read_text().splitlines():
            if row.startswith(('MemTotal:', 'MemAvailable:')):
                key, raw = row.split(':', 1)
                samples[key + '_MiB'] = round(int(raw.strip().split()[0]) / 1024, 1)
    except (OSError, ValueError):
        pass
    try:
        samples['load1'], samples['load5'], samples['load15'] = os.getloadavg()
    except (AttributeError, OSError):
        pass
    return samples

start = time.monotonic()
with jsonpath.open('x', encoding='utf-8') as stream:
    while True:
        record = {'timestamp': datetime.datetime.now().astimezone().isoformat(), **probe()}
        stream.write(json.dumps(record, ensure_ascii=False) + '\n')
        stream.flush()
        if time.monotonic() - start >= a.duration:
            break
        time.sleep(min(a.interval, max(0, a.duration - (time.monotonic() - start))))
records = [json.loads(line) for line in jsonpath.read_text(encoding='utf-8').splitlines()]
keys = ['timestamp'] + sorted({key for row in records for key in row.keys()} - {'timestamp'})
with csvpath.open('x', encoding='utf-8', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=keys)
    writer.writeheader()
    writer.writerows(records)
print('JSON Lines:', jsonpath)
print('CSV:', csvpath)
print('Sensores não expostos pelo hardware ficam ausentes; não inventamos valores.')
