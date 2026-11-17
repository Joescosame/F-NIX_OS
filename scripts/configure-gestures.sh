#!/usr/bin/env bash
# Gestos apenas se houver touchpad de verdade e libinput-gestures instalado.
set -u
conf="$HOME/.config/libinput-gestures.conf"
mkdir -p "$(dirname "$conf")"
[[ -f "$conf" ]] || cp /usr/local/share/fenix/templates/libinput-gestures.conf "$conf" 2>/dev/null || true
if ! command -v libinput-gestures >/dev/null 2>&1; then
  echo 'libinput-gestures não está disponível no repositório base. Não ativado.'
  exit 0
fi
if ! command -v xinput >/dev/null 2>&1 || ! xinput list --name-only 2>/dev/null | grep -Eiq 'touchpad|trackpad'; then
  echo 'Nenhum touchpad encontrado (desktop com mouse). Gestos não ativados.'
  exit 0
fi
libinput-gestures-setup autostart 2>/dev/null || true
libinput-gestures-setup start 2>/dev/null || true
echo 'Gestos configurados. Confirme grupo de acesso a eventos e faça novo login.'
