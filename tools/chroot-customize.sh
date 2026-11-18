#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${FENIX_BUILD:-} == 1 && $EUID == 0 ]] || { echo 'Uso exclusivo no chroot de build'; exit 1; }
cd /root/fenix
bash scripts/install-packages.sh
bash scripts/cleanup-optimize.sh apply
bash scripts/stage-into-root.sh
python3 tools/patch-timezone.py /usr/lib/ubiquity/plugins/ubi-timezone.py
locale-gen pt_BR.UTF-8
update-locale LANG=pt_BR.UTF-8
printf 'America/Sao_Paulo\n' > /etc/timezone
ln -sfn /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
bash scripts/verificar-perfil.sh
for p in snapd flatpak; do
  if dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'install ok installed'; then
    echo "Proibido na ISO base: $p" >&2; exit 1
  fi
done
apt-get clean
rm -f /var/lib/dbus/machine-id
: > /etc/machine-id
