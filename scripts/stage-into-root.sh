#!/usr/bin/env bash
# Executar dentro do ambiente chroot Cubic, após colar este projeto no /root/fenix.
# Faz staging de arquivos no filesystem que será copiado para a instalação final.
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Execute como root no Cubic'; exit 1; }
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
install -d /usr/local/lib/fenix /usr/local/bin /etc/xdg/autostart /usr/share/applications /usr/share/icons/hicolor/scalable/apps /usr/local/share/fenix/templates
for f in configure-xfce.sh configure-gestures.sh waydroid-launcher.sh setup-waydroid.sh hub-testes.sh salvar-snapshot.sh ativar-mangohud.sh first-login.sh historico-sensores.py; do
  install -m 0755 "$base/scripts/$f" "/usr/local/lib/fenix/$f"
done
for f in hub-testes.sh salvar-snapshot.sh ativar-mangohud.sh waydroid-launcher.sh; do ln -sfn "/usr/local/lib/fenix/$f" "/usr/local/bin/${f%.sh}"; done
install -m 0644 "$base/assets/hub-testes.desktop" /usr/share/applications/hub-testes.desktop
install -m 0644 "$base/assets/waydroid-fenix.desktop" /usr/share/applications/waydroid-fenix.desktop
install -m 0644 "$base/assets/fenix-first-login.desktop" /etc/xdg/autostart/fenix-first-login.desktop
install -m 0644 "$base/assets/fenix-hub.svg" /usr/share/icons/hicolor/scalable/apps/fenix-hub.svg
install -m 0644 "$base/assets/MangoHud.conf" /usr/local/share/fenix/templates/MangoHud.conf
install -m 0644 "$base/assets/libinput-gestures.conf" /usr/local/share/fenix/templates/libinput-gestures.conf
install -m 0644 "$base/assets/20-intel.conf.example" /usr/local/share/fenix/templates/20-intel.conf.example
install -m 0644 "$base/docs/04_GUIA_POS_INSTALACAO.md" /usr/local/share/fenix/GUIA_POS_INSTALACAO.md
# /etc/skel protege perfil de novos usuários. A personalização xfconf deve rodar com sessão XFCE já aberta.
install -d /etc/skel/.config/MangoHud
install -m 0644 "$base/assets/MangoHud.conf" /etc/skel/.config/MangoHud/MangoHud.conf
for p in benchmarks historico snapshots logs; do install -d "/etc/skel/TestesPC/$p"; done
printf 'Stage concluído: hub visível no menu; primeiro login aplica atalhos e dados.\n'
