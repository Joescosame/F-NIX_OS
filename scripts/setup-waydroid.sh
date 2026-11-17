#!/usr/bin/env bash
# SEM instalação automática: Waydroid é experimental nesta Intel Ironlake.
set -Eeuo pipefail
if [[ "${1:-}" != '--experimental' ]]; then
  cat <<'INFO'
Waydroid desabilitado por padrão na Ironlake (gráficos e binder não validados).
Antes de habilitar, consulte: https://docs.waydro.id/usage/install-on-desktops
Uso após instalar manualmente via repositório oficial: bash setup-waydroid.sh --experimental
Não adicionamos repositórios de terceiros automaticamente.
INFO
  exit 0
fi
command -v waydroid >/dev/null || { echo 'Waydroid não instalado. Instale a partir do repositório oficial documentado.'; exit 2; }
command -v cage >/dev/null || { echo 'cage indisponível. Instale no gerenciador de pacotes.'; exit 2; }
[[ -e /dev/binderfs || -e /dev/binder ]] || { echo 'Binder indisponível: Waydroid não funcionará sem suporte no kernel.'; exit 2; }
echo 'Pré-requisitos básicos encontrados. A compatibilidade gráfica ainda precisa ser testada.'
echo 'O lançador do menu pode ser usado para um teste controlado.'
