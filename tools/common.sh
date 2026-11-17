#!/usr/bin/env bash
set -Eeuo pipefail
# Usa Python e ferramentas apt do Ubuntu antes de runtimes opcionais do runner.
export PATH="/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
export ROOT
die() { printf 'BLOQUEADO: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "Dependência ausente: $1"; }
trap 'printf "FALHOU: %s:%s (código %s)\n" "${BASH_SOURCE[0]}" "$LINENO" "$?" >&2' ERR
