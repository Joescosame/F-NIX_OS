#!/usr/bin/env bash
# Reversão somente do módulo, sem apagar chats, chaves ou dados pessoais.
set -Eeuo pipefail
if (( EUID == 0 )); then echo 'Execute como usuário normal.' >&2; exit 1; fi
state="$HOME/.local/state/fenix-newelle"
# Evita apagar um .desktop que tenha sido substituído pelo usuário.
if [[ -f /usr/share/applications/newelle-fenix.desktop ]] && \
   grep -q '^Exec=/usr/local/bin/fenix-newelle$' /usr/share/applications/newelle-fenix.desktop; then
  sudo rm -f /usr/share/applications/newelle-fenix.desktop
fi
if [[ -f /usr/local/bin/fenix-newelle ]]; then
  sudo rm -f /usr/local/bin/fenix-newelle
fi
# Desinstala apenas os destinos que o Meson registrou no /usr/local.
if [[ -f "$state/installed-files.txt" ]]; then
  while IFS= read -r p; do
    [[ "$p" == /usr/local/* && "$p" != *'/../'* ]] || continue
    [[ -f "$p" || -L "$p" ]] && sudo rm -f -- "$p"
  done < "$state/installed-files.txt"
fi
# Mantém venv, código-fonte e dados do usuário; revisão manual evita perda de segredos.
echo 'Integração removida. Pacotes apt, venv, repositório e dados pessoais preservados.'
echo "Para revisar pacotes apt instalados apenas na fase 2: $state/packages-added.txt"
