#!/usr/bin/env bash
# Desmontagem normal recursiva, limitada a um ponto criado pelo construtor.
set -Eeuo pipefail
target=${1:?Informe o ponto de montagem}
[[ $target == /* && $target != / && ! -L $target ]] || exit 2
echo "Diagnóstico de desmontagem: $target"
findmnt -R --mountpoint "$target" -o TARGET,SOURCE,FSTYPE,OPTIONS || true
if command -v fuser >/dev/null; then fuser -vm "$target" || true; fi
ps -eo pid,ppid,stat,comm,args || true
# util-linux desmonta filhos antes do pai; sem lazy/force e sem matar processos.
umount --recursive -- "$target"
if mountpoint -q "$target"; then
  echo "FALHOU: montagem restante: $target" >&2
  exit 1
fi
