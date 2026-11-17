#!/usr/bin/env bash
# O autostart Xfce executa uma única vez por usuário instalado, não em modo Live.
set -u
if grep -qw 'boot=casper' /proc/cmdline; then exit 0; fi
[[ "${XDG_CURRENT_DESKTOP:-}" == *XFCE* || "${DESKTOP_SESSION:-}" == *xfce* ]] || exit 0
marker="$HOME/.local/state/fenix/primeiro-login-v02"
[[ -e "$marker" ]] && exit 0
mkdir -p "$(dirname "$marker")" "$HOME/.config/MangoHud"
for sub in benchmarks historico snapshots logs; do mkdir -p "$HOME/TestesPC/$sub"; done
if [[ ! -e "$HOME/.config/MangoHud/MangoHud.conf" ]]; then cp /usr/local/share/fenix/templates/MangoHud.conf "$HOME/.config/MangoHud/MangoHud.conf"; fi
if ! /usr/local/lib/fenix/configure-xfce.sh >> "$HOME/TestesPC/logs/primeiro-login.log" 2>&1; then
  echo 'Configuração incompleta; será tentada novamente no próximo login.' >&2
  exit 1
fi
/usr/local/lib/fenix/configure-gestures.sh >> "$HOME/TestesPC/logs/primeiro-login.log" 2>&1 || true
# Não marque concluído se faltar o gerenciador de configurações do XFCE.
if command -v xfconf-query >/dev/null 2>&1; then touch "$marker"; fi
