#!/usr/bin/env bash
# Configuração reversível para RAM/SSD/HD; não toca em partições nem no GRUB.
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Execute com sudo ou no chroot'; exit 1; }
state=/var/lib/fenix/optimize-original
case "${1:-apply}" in
  apply)
    install -d /etc/sysctl.d /etc/systemd
    if [[ ! -d $state ]]; then
      install -d -m 0700 "$state"
      for path in /etc/sysctl.d/90-fenix-memory.conf /etc/systemd/zram-generator.conf; do
        name=$(basename "$path")
        if [[ -e $path || -L $path ]]; then cp -a "$path" "$state/$name";
        else touch "$state/$name.absent"; fi
      done
    fi
    cat > /etc/sysctl.d/90-fenix-memory.conf <<'CONF'
# FÊNIX OS: ajustes modestos; usuários com HD/SSD podem comparar resultados.
vm.swappiness=10
vm.vfs_cache_pressure=50
CONF
    cat > /etc/systemd/zram-generator.conf <<'CONF'
# 50% da RAM em swap comprimida; prioridade alta; requer systemd-zram-generator.
[zram0]
zram-size = ram / 2
compression-algorithm = lz4
swap-priority = 100
CONF
    echo 'Ajustes gravados. zram será gerada na próxima inicialização.'
    echo 'Validar depois: zramctl; swapon --show; sysctl vm.swappiness'
    ;;
  revert)
    [[ -d $state ]] || { echo 'Sem estado original; nenhuma configuração foi apagada.'; exit 0; }
    for path in /etc/sysctl.d/90-fenix-memory.conf /etc/systemd/zram-generator.conf; do
      name=$(basename "$path")
      if [[ -e "$state/$name" || -L "$state/$name" ]]; then
        rm -f "$path"
        cp -a "$state/$name" "$path"
      elif [[ -f "$state/$name.absent" ]]; then
        rm -f "$path"
      else
        echo "Estado incompleto: $name; não removido" >&2; exit 1
      fi
    done
    rm -rf -- "$state"
    echo 'Arquivos FÊNIX retirados; reinicie para remover zram e restaurar defaults.'
    ;;
  services)
    echo 'Nenhum serviço desativado automaticamente.'
    echo 'Ajuste manualmente se desnecessário: sudo systemctl disable --now bluetooth avahi-daemon cups'
    echo 'Para reverter: sudo systemctl enable --now SERVICO'
    ;;
  remove-apps)
    echo 'SIMULAÇÃO: nenhum pacote será removido sem confirmação explícita.'
    apt-get -s purge libreoffice-core libreoffice-writer libreoffice-calc thunderbird gimp rhythmbox celluloid || true
    echo 'Revise a lista acima. Esta versão NÃO executa o purge automaticamente.'
    ;;
  *) echo 'Uso: cleanup-optimize.sh [apply|revert|services|remove-apps]'; exit 2;;
esac
