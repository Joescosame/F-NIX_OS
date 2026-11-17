#!/usr/bin/env bash
# Persistência por usuário após logout/login; não modifica /etc/environment.
set -Eeuo pipefail
file="$HOME/.config/environment.d/90-fenix-mangohud.conf"
case "${1:-status}" in
  on)
    mkdir -p "$(dirname "$file")"
    printf 'MANGOHUD=1\n' > "$file"
    echo 'MANGOHUD=1 salvo para próximas sessões systemd de usuário.'
    echo 'Faça logout/login; launchers GL podem precisar: mangohud COMANDO'
    ;;
  off)
    rm -f "$file"
    echo 'Desativado para as próximas sessões após logout/login.'
    ;;
  status)
    if [[ -f "$file" ]]; then cat "$file"; else echo 'Desativado'; fi
    ;;
  *) echo 'Uso: ativar-mangohud.sh {on|off|status}'; exit 2;;
esac
