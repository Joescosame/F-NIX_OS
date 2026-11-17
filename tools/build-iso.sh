#!/usr/bin/env bash
# Somente arquivos de imagem; nenhum dispositivo de bloco é argumento deste script.
set -Eeuo pipefail
source "$(dirname -- "$0")/common.sh"
[[ $EUID == 0 ]] || die 'Execute sudo -E ./tools/build-iso.sh em VM descartável.'
bash "$ROOT/tools/preflight.sh"
if [[ ${FENIX_BUILD_NAMESPACE:-} != 1 ]]; then
  export FENIX_BUILD_NAMESPACE=1
  exec unshare --mount --propagation private -- "$0" "$@"
fi
bash "$ROOT/tools/fetch-base.sh"
iso=$(cat "$ROOT/cache/base-path.txt")
mkdir -p "$ROOT/work" "$ROOT/dist"
work=$(mktemp -d "$ROOT/work/build.XXXXXXXX")
chmod 700 "$work"
tree="$work/iso"; rootfs="$work/rootfs"
mkdir -p "$tree" "$rootfs"
exec > >(tee "$work/build.log") 2>&1
mounts=()
cleanup() {
  local status=$? failed=0
  trap - EXIT
  for ((i=${#mounts[@]}-1; i>=0; i--)); do
    umount "${mounts[i]}" || failed=1
  done
  printf 'Build terminou: código %s. Trabalho preservado em %s\n' "$status" "$work"
  ((failed == 0)) || status=1
  exit "$status"
}
trap cleanup EXIT
[[ ! -e "$ROOT/dist/FENIX-OS-Legacy-amd64.iso" ]] || die 'Mova a ISO de dist antes de reconstruir; saída não será sobrescrita.'
xorriso -indev "$iso" -report_el_torito plain -report_system_area plain > "$work/boot-original.txt" 2>&1
xorriso -osirrox on -indev "$iso" -extract / "$tree"
[[ -f "$tree/casper/filesystem.squashfs" && -f "$tree/casper/filesystem.manifest-remove" ]] || die 'Layout Mint inesperado.'
unsquashfs -d "$rootfs" "$tree/casper/filesystem.squashfs"
rm -- "$tree/casper/filesystem.squashfs"
cp "$tree/casper/filesystem.manifest-remove" "$work/manifest-remove-original"
mkdir -p "$rootfs/root/fenix"
rsync -a --exclude=.git --exclude=cache --exclude=work --exclude=dist --exclude=qa "$ROOT/" "$rootfs/root/fenix/"
install -m 0755 "$ROOT/tools/chroot-customize.sh" "$rootfs/root/fenix-chroot.sh"
for point in dev proc sys; do mkdir -p "$rootfs/$point"; done
mount --bind /dev "$rootfs/dev"; mounts+=("$rootfs/dev")
mount -t devpts devpts "$rootfs/dev/pts"; mounts+=("$rootfs/dev/pts")
mount -t proc proc "$rootfs/proc"; mounts+=("$rootfs/proc")
mount -t sysfs -o ro sysfs "$rootfs/sys"; mounts+=("$rootfs/sys")
cp -a "$rootfs/etc/resolv.conf" "$work/resolv.original"
rm -f "$rootfs/etc/resolv.conf"
cp -L /etc/resolv.conf "$rootfs/etc/resolv.conf"
if [[ -e "$rootfs/usr/sbin/policy-rc.d" ]]; then cp -a "$rootfs/usr/sbin/policy-rc.d" "$work/policy.original"; fi
printf '#!/bin/sh\nexit 101\n' > "$rootfs/usr/sbin/policy-rc.d"
chmod 755 "$rootfs/usr/sbin/policy-rc.d"
chroot "$rootfs" /usr/bin/env FENIX_BUILD=1 /bin/bash /root/fenix-chroot.sh
rm -f "$rootfs/usr/sbin/policy-rc.d" "$rootfs/etc/resolv.conf"
cp -a "$work/resolv.original" "$rootfs/etc/resolv.conf"
if [[ -e "$work/policy.original" ]]; then cp -a "$work/policy.original" "$rootfs/usr/sbin/policy-rc.d"; fi
chroot "$rootfs" dpkg-query -W -f='${Package} ${Version}\n' > "$tree/casper/filesystem.manifest"
python3 "$ROOT/tools/update-manifests.py" "$tree/casper" "$rootfs"
for ((i=${#mounts[@]}-1; i>=0; i--)); do umount "${mounts[i]}"; done
mounts=()
rm -rf -- "$rootfs/root/fenix"
rm -f "$rootfs/root/fenix-chroot.sh"
# Nenhum autoremove, mudança de kernel ou rebuild de initramfs/bootloader.
mksquashfs "$rootfs" "$tree/casper/filesystem.squashfs" -noappend -comp xz -processors 2 -mem 1G
du -sx --block-size=1 "$rootfs" | cut -f1 > "$tree/casper/filesystem.size"
python3 "$ROOT/tools/iso-md5.py" "$tree"
out="$ROOT/dist/FENIX-OS-Legacy-amd64.iso"
# Importa e reproduz o boot original, incluindo MBR híbrido e El Torito.
xorriso -indev "$iso" -outdev "$out.partial" -update_r "$tree" / -boot_image any replay -commit -end
mv -- "$out.partial" "$out"
[[ $(stat -c %s "$out") -lt 7800000000 ]] || die 'ISO excede limite conservador para pendrive de 8 GB.'
(( $(stat -c %s "$out") < 4000000000 )) || echo 'AVISO: ISO acima da meta de 4 GB.'
xorriso -indev "$out" -report_el_torito plain -report_system_area plain > "$work/boot-final.txt" 2>&1
python3 "$ROOT/tools/check-boot.py" "$work/boot-original.txt" "$work/boot-final.txt"
(cd "$ROOT/dist" && sha256sum FENIX-OS-Legacy-amd64.iso > SHA256SUMS)
cp "$work/boot-original.txt" "$work/boot-final.txt" "$ROOT/dist/"
cp "$tree/casper/filesystem.manifest" "$ROOT/dist/packages.txt"
cp "$ROOT/cache/gpg-verification.txt" "$ROOT/dist/"
{
  date -u +%FT%TZ
  git -C "$ROOT" rev-parse HEAD
  sha256sum "$iso"
  xorriso -version
  mksquashfs -version
  dpkg-query -W xorriso squashfs-tools qemu-system-x86
} > "$ROOT/dist/build-info.txt" 2>&1
echo 'Build concluído; ISO ainda NÃO HOMOLOGADA. Execute QA.'
