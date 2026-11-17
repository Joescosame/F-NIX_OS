#!/usr/bin/env bash
# FÊNIX OS: dependências da FASE 2. Nunca executar no chroot da ISO base.
# Instala somente pacotes oficiais apt; registra a diferença de pacotes para revisão.
set -Eeuo pipefail
if (( EUID == 0 )); then
  echo 'Execute como usuário normal; o script solicitará sudo quando necessário.' >&2
  exit 1
fi
. /etc/os-release
if [[ "${UBUNTU_CODENAME:-}" != noble && "${VERSION_CODENAME:-}" != noble ]]; then
  echo 'BLOQUEADO: testado somente para Mint 22.x / Ubuntu 24.04 Noble.' >&2
  exit 1
fi
# Guarda lista anterior; NÃO desinstala apt automaticamente na reversão.
state="$HOME/.local/state/fenix-newelle"
mkdir -p "$state" "$HOME/TestesPC/logs"
dpkg-query -W -f='${binary:Package}\n' | sort -u > "$state/packages-before.txt"
# Runtime GTK4 / WebKit GTK6 + ferramentas de build; sem Flatpak ou Snap.
packages=(
  git ca-certificates meson ninja-build gettext pkg-config desktop-file-utils
  libglib2.0-dev-bin libgtk-4-dev libadwaita-1-dev libgtksourceview-5-dev
  libvte-2.91-gtk4-dev libwebkitgtk-6.0-dev portaudio19-dev
  gir1.2-gtk-4.0 gir1.2-adw-1 gir1.2-gtksource-5 gir1.2-vte-3.91
  gir1.2-webkit-6.0 python3 python3-venv python3-pip python3-gi
  python3-gi-cairo python3-pil python3-lxml python3-requests
  python3-matplotlib python3-openai python3-pyaudio python3-tldextract
)
sudo apt-get update
missing=()
for p in "${packages[@]}"; do
  apt-cache show "$p" >/dev/null 2>&1 || missing+=("$p")
done
if (( ${#missing[@]} )); then
  printf 'Não disponíveis nos repositórios atuais: %s\n' "${missing[*]}" >&2
  echo 'Verifique se Universe está habilitado; não adicionarei PPAs automaticamente.' >&2
  exit 2
fi
sudo apt-get install -y --no-install-recommends "${packages[@]}"
dpkg-query -W -f='${binary:Package}\n' | sort -u > "$state/packages-after.txt"
comm -13 "$state/packages-before.txt" "$state/packages-after.txt" > "$state/packages-added.txt"
printf 'Lista para eventual revisão: %s\n' "$state/packages-added.txt"
