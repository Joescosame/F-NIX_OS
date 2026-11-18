#!/usr/bin/env bash
# Sonda temporária da campanha; não integra o produto ou autostart da ISO.
set -Eeuo pipefail
exec > /dev/ttyS0 2>&1
[[ $(cat /sys/class/dmi/id/product_name) == FENIX-QA-PORTABLE ]]
[[ -f /etc/fenix-qa-installed ]]
if grep -qw boot=casper /proc/cmdline; then echo FENIX_QA_ERRO_AINDA_LIVE; exit 1; fi
mode=legacy
[[ ! -d /sys/firmware/efi ]] || mode=uefi
rootdev=$(findmnt -n -o SOURCE /)
root_uuid=$(blkid -s UUID -o value "$rootdev")
[[ -n $root_uuid ]]
disk=$(lsblk -dn -o NAME,SERIAL | awk '$2=="FENIXQA001" {print "/dev/"$1}')
[[ -b $disk && $(lsblk -dn -o PTTYPE "$disk") == gpt ]]
if [[ $mode == uefi ]]; then mountpoint -q /boot/efi; fi
for ((i=0;i<300;i++)); do
  if pgrep -u fenixqa -x xfce4-session >/dev/null; then break; fi
  sleep 2
done
pgrep -u fenixqa -x xfce4-session >/dev/null
[[ -x /usr/local/lib/fenix/hub-testes.sh ]]
printf 'FENIX_QA_BOOT_OK mode=%s root_uuid=%s campaign=%s user=fenixqa\n' "$mode" "$root_uuid" "$(cat /etc/fenix-qa-installed)"
findmnt / /boot/efi || true
lsblk -o NAME,TYPE,PTTYPE,PARTTYPE,UUID,PARTUUID "$disk"
free -m
swapon --show
systemctl --failed --no-pager
sleep 15
sync
systemctl poweroff
