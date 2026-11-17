#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID == 0 && ${FENIX_BUILD:-} == 1 ]] || { echo 'Uso exclusivo pelo construtor no chroot.' >&2; exit 1; }
source /etc/os-release
[[ ${ID:-} == linuxmint && ${VERSION_ID:-} == 22.3 && ${UBUNTU_CODENAME:-} == noble ]] || { echo 'Base deve ser Mint 22.3/Noble'; exit 1; }
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export DEBIAN_FRONTEND=noninteractive
mkdir -p /usr/local/share/fenix /etc/apt/preferences.d
cat > /etc/apt/preferences.d/fenix-no-snap-flatpak <<'CONF'
Package: snapd flatpak
Pin: version *
Pin-Priority: -1
CONF
apt-get update
remove=()
for p in snapd flatpak; do
  if dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'install ok installed'; then remove+=("$p"); fi
done
if ((${#remove[@]})); then
  apt-get -s purge "${remove[@]}" > /usr/local/share/fenix/purge-simulation.txt
  if grep -Eq '^Remv (mint-meta[^ ]*|xfce4[^ ]*|ubiquity[^ ]*|casper|lightdm|grub[^ ]*|linux-image[^ ]*|network-manager) ' /usr/local/share/fenix/purge-simulation.txt; then
    echo 'Remoção de Snap/Flatpak afeta pacote protegido. Build bloqueado.' >&2; exit 1
  fi
  apt-get purge -y "${remove[@]}"
fi
mapfile -t packages < "$base/config/packages.txt"
apt-get install -y --no-install-recommends "${packages[@]}"
cp "$base/config/packages.txt" /usr/local/share/fenix/required-packages.txt
for p in mangohud goverlay glmark2 cpu-x; do
  candidate=$(apt-cache policy "$p" | awk '/Candidate:/ {print $2}')
  if [[ -n $candidate && $candidate != '(none)' ]]; then
    apt-get install -y --no-install-recommends "$p"
    printf '%s\n' "$p" >> /usr/local/share/fenix/required-packages.txt
  else
    printf 'NÃO INCLUÍDO: %s (opcional)\n' "$p"
  fi
done
