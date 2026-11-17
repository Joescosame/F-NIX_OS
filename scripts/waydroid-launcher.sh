#!/usr/bin/env bash
# Waydroid através de Cage aninhado. Falha de modo informativo em Ironlake.
set -u
err() { if command -v yad >/dev/null; then yad --error --title='FÊNIX Android experimental' --text="$1"; else echo "$1" >&2; fi; }
if ! command -v waydroid >/dev/null; then err 'Waydroid não instalado. Consulte o guia: recurso experimental na GPU Ironlake.'; exit 2; fi
if ! command -v cage >/dev/null; then err 'Cage não instalado.'; exit 2; fi
if [[ ! -d /dev/binderfs && ! -e /dev/binder ]]; then err 'Kernel sem binder disponível; Android não poderá iniciar.'; exit 2; fi
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  exec waydroid show-full-ui
else
  # Cage cria um compositor Wayland aninhado. Waydroid precisa abrir sessão nesse ambiente.
  exec cage -- sh -c 'waydroid session start >/tmp/fenix-waydroid.log 2>&1 & sleep 5; exec waydroid show-full-ui'
fi
