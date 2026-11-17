#!/usr/bin/env bash
# Snapshot datado: inventário, benchmarks opcionais, sensores, gráficos e logs de SO.
# Não necessita root para métricas comuns; não sobrescreve dados anteriores.
set -Eeuo pipefail
umask 077
outroot="$HOME/TestesPC/snapshots"
mkdir -p "$outroot" "$HOME/TestesPC/benchmarks" "$HOME/TestesPC/historico" "$HOME/TestesPC/logs"
folder="$outroot/$(date +%Y%m%d_%H%M%S)_$$_$(date +%N)"
mkdir -m 700 "$folder"
run() {
  local name="$1"; shift
  if command -v "$1" >/dev/null 2>&1; then
    timeout 90s "$@" > "$folder/$name" 2>&1 || echo "Comando falhou ou excedeu tempo: $*" >> "$folder/avisos.txt"
  else
    echo "Não instalado: $1" >> "$folder/avisos.txt"
  fi
}
cat > "$folder/README.txt" <<EOF2
Snapshot FÊNIX: $(date -Is)
Não publique sem revisar identificadores. Dados locais; nenhum upload automático.
EOF2
run sistema.txt uname -a
run discos.txt lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINTS
run pci.txt lspci -nn
run usb.txt lsusb
run memoria.txt free -h
run cpu.txt lscpu
run kernel.txt dmesg --level=err,warn
run sensores.txt sensors
run grafico.txt glxinfo -B
run swap.txt swapon --show
run processos.txt ps aux
run inventario.txt lshw -short
if command -v hardinfo2 >/dev/null 2>&1; then
  timeout 180s hardinfo2 -r -f html > "$folder/hardinfo2.html" 2>"$folder/hardinfo2.err" || true
  cp -n "$folder/hardinfo2.html" "$HOME/TestesPC/benchmarks/$(basename "$folder").html" 2>/dev/null || true
elif command -v hardinfo >/dev/null 2>&1; then
  timeout 180s hardinfo -r > "$folder/hardinfo.txt" 2>"$folder/hardinfo.err" || true
fi
if command -v hwall-cli >/dev/null 2>&1; then
  timeout 30s hwall-cli export --pretty > "$folder/hwall.json" 2>"$folder/hwall.err" || true
fi
if command -v python3 >/dev/null 2>&1; then
  timeout 10s python3 /usr/local/lib/fenix/historico-sensores.py --duration 1 --interval 1 > "$folder/historico-coleta.txt" 2>&1 || true
fi
( cd "$folder" && find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.txt )
printf 'Snapshot salvo: %s\n' "$folder"
if [[ ${FENIX_NO_GUI:-0} != 1 ]] && command -v yad >/dev/null 2>&1; then
  yad --info --title='FÊNIX' --text="Snapshot salvo em:\n$folder" --button=OK:0 || true
fi
