#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname -- "$0")/common.sh"
mode=${1:-inspect}
case "$mode" in
  inspect)
    need xorriso
    [[ -f "$ROOT/dist/FENIX-OS-Legacy-amd64.iso" ]] || die 'Construa a ISO primeiro.'
    (cd "$ROOT/dist" && sha256sum -c SHA256SUMS)
    mkdir -p "$ROOT/qa"
    xorriso -indev "$ROOT/dist/FENIX-OS-Legacy-amd64.iso" -report_el_torito plain -report_system_area plain > "$ROOT/qa/boot-inspection.txt" 2>&1
    python3 "$ROOT/tools/check-boot.py" "$ROOT/dist/boot-original.txt" "$ROOT/qa/boot-inspection.txt"
    echo 'Instalação NÃO EXECUTADA. Continue: ./tools/test-iso.sh install'
    ;;
  install|reboot)
    shift
    exec python3 "$ROOT/tools/qemu-qa.py" "$mode" "$@"
    ;;
  *) die 'Uso: test-iso.sh [inspect|install|reboot] [--online]';;
esac
