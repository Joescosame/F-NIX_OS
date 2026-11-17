#!/usr/bin/env bash
# FÊNIX OS — instalação conservadora em chroot do Cubic ou sistema Mint 22.x.
# Não adiciona PPAs, Snap ou Flatpak. Extras não empacotados são documentados.
# Newelle é FASE 2: NÃO incluir aqui. Execute scripts/install-newelle.sh
# somente no sistema já instalado e validado, nunca no chroot da ISO base.
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Execute como root: sudo bash scripts/install-packages.sh'; exit 1; }
export DEBIAN_FRONTEND=noninteractive
log=/var/log/fenix-install-packages.log
mkdir -p /var/log
exec > >(tee -a "$log") 2>&1
printf '\n=== FENIX PACOTES %s ===\n' "$(date -Is)"
if [[ -f /etc/os-release ]]; then . /etc/os-release; fi
[[ "${VERSION_CODENAME:-}" == 'wilma' || "${VERSION_CODENAME:-}" == 'xia' || "${VERSION_CODENAME:-}" == 'zara' || "${VERSION_CODENAME:-}" == 'zena' || "${UBUNTU_CODENAME:-}" == 'noble' ]] || echo 'AVISO: base diferente do Mint 22.x/Noble; validar pacotes.'
apt-get update
install_group() {
  local group=$1; shift
  local available=() p
  echo "--- Grupo: $group"
  for p in "$@"; do
    if apt-cache show "$p" >/dev/null 2>&1; then available+=("$p"); else echo "INDISPONÍVEL (não instalado): $p"; fi
  done
  if ((${#available[@]})); then
    apt-get install -y --no-install-recommends "${available[@]}"
  fi
}
install_group sistema-base \
  xfce4-whiskermenu-plugin xfce4-notifyd xfce4-notifyd-plugin \
  xfce4-taskmanager xfce4-screenshooter xcape thunar-archive-plugin \
  thunar-volman gvfs-backends mousepad xarchiver file-roller p7zip-full unzip \
  network-manager linux-firmware mesa-utils mesa-vulkan-drivers \
  xserver-xorg-video-intel synaptic yad zenity \
  lm-sensors smartmontools lshw pciutils usbutils inxi \
  htop iotop sysstat lsof dmidecode nvme-cli \
  wmctrl xdotool xinput x11-xserver-utils x11-utils \
  python3 python3-gi python3-tk git curl wget \
  systemd-zram-generator
install_group aplicativos \
  abiword gnumeric claws-mail mpv audacious pinta firefox \
  plank mugshot atril ristretto kdeconnect
install_group ferramentas-hub \
  hardinfo cpu-x mangohud goverlay glmark2 \
  mesa-utils-extra libinput-tools
# O HardInfo2 NÃO existe no repositório Ubuntu Noble: hardinfo é fallback.
# HWall e System Monitoring Center são opcionais externos, com instalação verificada.
# A instalação do Waydroid em Ironlake NÃO é automática.
echo 'Base instalada. Verifique os extras no arquivo docs/EXTRAS_E_LIMITES.md.'
echo 'Não execute apt autoremove sem revisar a simulação.'
