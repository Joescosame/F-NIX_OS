#!/usr/bin/env bash
# Instalar .deb adicionais fornecidos pelo construtor somente com SHA-256 pré-validado.
# Usar exclusivamente numa VM de build descartável, após revisão dos fornecedores.
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Execute como root no chroot Cubic'; exit 1; }
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../externals" && pwd)"
[[ -f "$base/SHA256SUMS.txt" ]] || { echo "Sem $base/SHA256SUMS.txt: nenhum arquivo externo instalado."; exit 2; }
(cd "$base" && sha256sum -c SHA256SUMS.txt)
shopt -s nullglob
pkgs=("$base"/*.deb)
((${#pkgs[@]})) || { echo 'Nenhum .deb encontrado.'; exit 2; }
for pkg in "${pkgs[@]}"; do dpkg-deb --info "$pkg" | sed -n '1,25p'; done
read -r -p 'Fornecedores e metadados auditados? Digite INSTALAR: ' answer
[[ "$answer" == INSTALAR ]] || exit 2
apt-get install -y --no-install-recommends "${pkgs[@]}"
