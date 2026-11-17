#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname -- "$0")/common.sh"
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || die 'Use Ubuntu 24.04 x86_64 em VM Linux.'
source /etc/os-release
[[ ${ID:-} == ubuntu && ${VERSION_ID:-} == 24.04 ]] || die 'Host de build suportado: Ubuntu 24.04.'
for c in xorriso unsquashfs mksquashfs gpg curl chroot mount umount unshare python3 rsync sha256sum dpkg-query shellcheck desktop-file-validate qemu-system-x86_64 qemu-img; do need "$c"; done
python3 -c 'import yaml' || die 'Instale python3-yaml.'
mem=$(awk '/MemTotal:/ {print int($2/1024)}' /proc/meminfo)
free=$(df -Pk "$ROOT" | awk 'END {print int($4/1024/1024)}')
printf 'RAM total: %s MiB; espaço livre: %s GiB\n' "$mem" "$free"
((mem >= 3800)) || die 'Mínimo 4 GB RAM; recomendado 8 GB.'
((free >= 35)) || die 'São necessários 35 GiB livres; recomendado 50 GiB + 32 GiB para QA.'
[[ -f /usr/share/seabios/bios.bin ]] || die 'Instale seabios.'
echo 'PASSOU: recursos mínimos. Isso não homologa build ou instalação.'
