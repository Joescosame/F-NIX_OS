#!/usr/bin/env bash
# Hook de sucesso do Ubiquity, executado só após copiar e configurar o alvo.
set -Eeuo pipefail
exec > /dev/ttyS0 2>&1
trap 'echo "FENIX_QA_SUCCESS_HOOK_ERROR linha=$LINENO codigo=$?"' ERR
grep -qw 'fenix.qa=portable-v1' /proc/cmdline
[[ $(cat /sys/class/dmi/id/product_name) == FENIX-QA-PORTABLE ]]
[[ -f /target/etc/os-release && -d /target/home/fenixqa ]]
disk=$(lsblk -dn -o NAME,SERIAL | awk '$2=="FENIXQA001" {print "/dev/"$1}')
[[ -b $disk && $(lsblk -dn -o PTTYPE "$disk") == gpt ]]
dpkg-query --admindir=/target/var/lib/dpkg -W -f='${Status}\n' grub-efi-amd64-bin | grep -qx 'install ok installed'
esp=$(lsblk -ln -o PATH,PARTTYPE "$disk" | awk 'tolower($2)=="c12a7328-f81f-11d2-ba4b-00a0c93ec93b" {print $1}')
[[ -b $esp ]]
mkdir -p /target/boot/efi
if ! mountpoint -q /target/boot/efi; then mount "$esp" /target/boot/efi; fi
[[ $(findmnt -n -o FSTYPE /target/boot/efi) == vfat ]]
esp_uuid=$(blkid -s UUID -o value "$esp")
grep -q '[[:space:]]/boot/efi[[:space:]]' /target/etc/fstab || printf 'UUID=%s /boot/efi vfat umask=0077 0 1\n' "$esp_uuid" >> /target/etc/fstab
mkdir -p /target/var/lib/fenix-qa/recovery
cp -a /target/etc/fstab /target/var/lib/fenix-qa/recovery/fstab
cp -a /target/boot/grub /target/var/lib/fenix-qa/recovery/grub-before-dual
chroot /target grub-install --target=i386-pc "$disk"
chroot /target grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable --no-nvram
chroot /target update-grub
[[ -s /target/boot/efi/EFI/BOOT/BOOTX64.EFI ]]
install -m 0755 /opt/fenix-qa/guest-probe.sh /target/usr/local/sbin/fenix-qa-probe
install -m 0644 /opt/fenix-qa/probe.service /target/etc/systemd/system/fenix-qa-probe.service
mkdir -p /target/etc/systemd/system/multi-user.target.wants
ln -s ../fenix-qa-probe.service /target/etc/systemd/system/multi-user.target.wants/fenix-qa-probe.service
cp /opt/fenix-qa/campaign-id /target/etc/fenix-qa-installed
lsblk -o NAME,TYPE,PTTYPE,PARTTYPE,UUID,PARTUUID "$disk"
echo 'FENIX_QA_DUAL_GRUB_INSTALADO'
touch /run/fenix-qa-success
