#!/usr/bin/env bash
# Exclusivo da VM descartável desta campanha; nunca executar no host.
set -Eeuo pipefail
exec > /dev/ttyS0 2>&1
trap 'echo "FENIX_QA_INSTALL_ERROR linha=$LINENO codigo=$?"' ERR
grep -qw 'fenix.qa=portable-v1' /proc/cmdline
grep -qw 'boot=casper' /proc/cmdline
[[ $(cat /sys/class/dmi/id/product_name) == FENIX-QA-PORTABLE ]]
[[ $(lsblk -dn -o TYPE | grep -c '^disk$') == 1 ]]
disk=$(lsblk -dn -o NAME,SERIAL | awk '$2=="FENIXQA001" {print "/dev/"$1}')
[[ -b $disk && $(blockdev --getsize64 "$disk") == 34359738368 ]]
echo 'FENIX_QA_LIVE_INICIADO'
# Retenção do binário EFI na instalação; overlay em RAM, sem alterar a ISO.
grep -v '^grub-efi-amd64-bin\([[:space:]]\|$\)' /cdrom/casper/filesystem.manifest-remove > /opt/fenix-qa/manifest-remove
mount --bind /opt/fenix-qa/manifest-remove /cdrom/casper/filesystem.manifest-remove
sed "s|@DISK@|$disk|g" /opt/fenix-qa/preseed.cfg > /run/fenix-qa-preseed.cfg
debconf-set-selections /run/fenix-qa-preseed.cfg
export FENIX_INSTALL_OFFLINE=1 WEBKIT_DISABLE_COMPOSITING_MODE=1
export DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0
for ((i=0;i<180;i++)); do
  if pgrep -x xfce4-session >/dev/null; then break; fi
  sleep 2
done
pgrep -x xfce4-session >/dev/null
echo 'FENIX_QA_UBIQUITY_INICIO'
# Sem rede no QEMU; não há downloads no instalador.
/usr/bin/ubiquity --automatic gtk_ui > /var/log/fenix-qa-ubiquity.log 2>&1 &
installer=$!
while kill -0 "$installer" 2>/dev/null; do
  sleep 30
  if [[ -f /run/fenix-qa-success ]]; then
    echo 'FENIX_QA_INSTALADOR_CONCLUIDO'
    sync
    systemctl poweroff
    exit 0
  fi
  echo 'FENIX_QA_UBIQUITY_EM_EXECUCAO'
  tail -n 5 /var/log/installer/debug 2>/dev/null | grep -viE 'password|passwd|preseed|crypt' || true
done
wait "$installer"
[[ -f /target/etc/fenix-qa-installed ]]
echo 'FENIX_QA_INSTALADOR_CONCLUIDO'
sync
systemctl poweroff
