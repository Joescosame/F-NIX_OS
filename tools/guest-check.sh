#!/usr/bin/env bash
# Executar como usuário após login no disco instalado; somente leitura/coleta local.
set -Eeuo pipefail
[[ $(uname -s) == Linux ]] || exit 1
if grep -qw boot=casper /proc/cmdline; then echo 'FALHOU: ainda em Live'; exit 1; fi
[[ ! -d /sys/firmware/efi ]] || { echo 'FALHOU: boot UEFI'; exit 1; }
[[ -n ${DISPLAY:-} ]] || { echo 'FALHOU: falta sessão gráfica'; exit 1; }
pgrep -u "$UID" -x xfce4-session >/dev/null
command -v hub-testes >/dev/null
[[ -x /usr/local/lib/fenix/hub-testes.sh && -f /usr/share/applications/hub-testes.desktop ]]
for p in snapd flatpak; do
  if dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'install ok installed'; then echo "FALHOU: $p instalado"; exit 1; fi
done
umask 077
out=$(mktemp -d "$HOME/fenix-qa.XXXXXXXX")
{
  date -Is
  uname -a
  findmnt /
  lsblk -o NAME,TYPE,SIZE,PTTYPE,FSTYPE,MOUNTPOINTS
  localectl status
  timedatectl status
  free -h
  swapon --show
  zramctl
  systemctl --failed --no-pager
  systemctl status systemd-zram-setup@zram0 --no-pager
  sysctl vm.swappiness vm.vfs_cache_pressure
} > "$out/sistema.txt" 2>&1
[[ -b /dev/zram0 ]] || { echo 'FALHOU: zram ausente'; exit 1; }
swapon --show=NAME --noheadings | grep -q '^/dev/zram0$'
rootdev=$(findmnt -n -o SOURCE /)
lsblk -s -n -o PTTYPE "$rootdev" | grep -qx dos || { echo 'FALHOU: tabela MBR não confirmada'; exit 1; }
python3 /usr/local/lib/fenix/historico-sensores.py --duration 1 --interval 0.5 --output-dir "$out/historico"
FENIX_NO_GUI=1 /usr/local/lib/fenix/salvar-snapshot.sh > "$out/snapshot.txt"
echo "PASSOU: verificações locais parciais. Evidências em $out. Abra o Hub e teste os botões; não equivale à homologação total."
