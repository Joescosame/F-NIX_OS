#!/usr/bin/env bash
# Configuração reversível para RAM/SSD/HD; não toca em partições nem no GRUB.
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Execute com sudo ou no chroot'; exit 1; }
case "${1:-apply}" in
  apply)
    install -d /etc/sysctl.d /etc/systemd
    if [[ -f /etc/sysctl.d/90-fenix-memory.conf && ! -f /etc/sysctl.d/90-fenix-memory.conf.fenix-original ]]; then
      cp -a /etc/sysctl.d/90-fenix-memory.conf /etc/sysctl.d/90-fenix-memory.conf.fenix-original
    fi
    cat > /etc/sysctl.d/90-fenix-memory.conf <<'CONF'
# FÊNIX OS: ajustes modestos; usuários com HD/SSD podem comparar resultados.
vm.swappiness=10
vm.vfs_cache_pressure=50
CONF
    if [[ -f /etc/systemd/zram-generator.conf && ! -f /etc/systemd/zram-generator.conf.fenix-original ]]; then
      cp -a /etc/systemd/zram-generator.conf /etc/systemd/zram-generator.conf.fenix-original
    fi
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
    rm -f /etc/sysctl.d/90-fenix-memory.conf /etc/systemd/zram-generator.conf
    if [[ -f /etc/sysctl.d/90-fenix-memory.conf.fenix-original ]]; then
      mv /etc/sysctl.d/90-fenix-memory.conf.fenix-original /etc/sysctl.d/90-fenix-memory.conf
    fi
    if [[ -f /etc/systemd/zram-generator.conf.fenix-original ]]; then
      mv /etc/systemd/zram-generator.conf.fenix-original /etc/systemd/zram-generator.conf
    fi
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
