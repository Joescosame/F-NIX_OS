#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname -- "$0")/common.sh"
[[ ${GITHUB_REPOSITORY:-} == Joescosame/F-NIX_OS ]] || die 'Repositório inesperado.'
mkdir -p "$ROOT/dist"
tag=$(gh api repos/Joescosame/F-NIX_OS/releases --jq '.[] | select(.draft and .name == "FÊNIX candidata 44002337245 — NÃO HOMOLOGADA") | .tag_name')
[[ -n $tag && $tag != *$'\n'* ]] || die 'Candidata em rascunho não identificada de forma única.'
printf '%s\n' "$tag" > "$ROOT/dist/candidate-tag.txt"
gh release download "$tag" --repo Joescosame/F-NIX_OS --dir "$ROOT/dist/release" --pattern '*.part*' --pattern manifesto.json
python3 "$ROOT/tools/release.py" join "$ROOT/dist/release"
python3 "$ROOT/tools/boot-live.py"
