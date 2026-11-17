#!/usr/bin/env bash
# Armazena apenas rascunho técnico; não publica nem aprova a candidata.
set -Eeuo pipefail
source "$(dirname -- "$0")/common.sh"
[[ ${GITHUB_ACTIONS:-} == true && ${GITHUB_REPOSITORY:-} == Joescosame/F-NIX_OS ]] || die 'Uso exclusivo no Actions oficial.'
[[ ${GITHUB_RUN_ID:-} =~ ^[0-9]+$ && ${GITHUB_RUN_ATTEMPT:-} =~ ^[0-9]+$ && ${GITHUB_SHA:-} =~ ^[0-9a-f]{40}$ ]] || die 'Identificação da execução inválida.'
need gh
python3 "$ROOT/tools/release.py" verify "$ROOT/dist/release"
tag="candidata-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
notes=$(mktemp)
trap 'rm -f -- "$notes"' EXIT
stat -c 'ISO: %s bytes' "$ROOT/dist/FENIX-OS-Legacy-amd64.iso"
{
  echo 'CANDIDATA NÃO HOMOLOGADA — rascunho técnico para testes.'
  echo 'Boot SeaBIOS, instalação offline MBR e reinicialização pelo disco: NÃO EXECUTADOS por este build.'
  echo "Fontes: $GITHUB_SHA"
  echo "Execução: https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
  echo 'Baixe todas as partes e os scripts; JUNTAR_ISO.ps1 confere partes e SHA-256 final.'
  cat "$ROOT/dist/SHA256SUMS"
} > "$notes"
gh release create "$tag" "$ROOT/dist/release/"* "$ROOT/dist/build-info.txt" "$ROOT/dist/packages.txt" "$ROOT/dist/gpg-verification.txt" "$ROOT/dist/boot-"*.txt \
  --repo "$GITHUB_REPOSITORY" --target "$GITHUB_SHA" --draft --prerelease \
  --title "FÊNIX candidata $GITHUB_RUN_ID — NÃO HOMOLOGADA" --notes-file "$notes"
echo 'Partes guardadas em Release de rascunho; publicação e homologação continuam pendentes.'
