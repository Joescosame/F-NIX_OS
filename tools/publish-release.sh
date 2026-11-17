#!/usr/bin/env bash
# Não executado nesta entrega. Requer autorização específica do operador.
set -Eeuo pipefail
source "$(dirname -- "$0")/common.sh"
[[ ${1:-} == --autorizar-prerelease && ${2:-} =~ ^v[0-9]+\.[0-9]+\.[0-9]+-rc[0-9]+$ ]] || die 'Uso: publish-release.sh --autorizar-prerelease v0.3.0-rc1'
tag=$2
need gh
python3 "$ROOT/tools/check-approval.py"
[[ $(gh repo view Joescosame/F-NIX_OS --json nameWithOwner --jq .nameWithOwner) == Joescosame/F-NIX_OS ]] || die 'Repositório oficial não acessível.'
[[ -z $(git -C "$ROOT" status --porcelain) ]] || die 'Faça commit das fontes antes de preparar Release.'
[[ -d "$ROOT/dist/release" ]] || die 'Execute package-release.sh primeiro.'
python3 - "$ROOT/dist/release" "$ROOT/qa/aprovacao.json" <<'PY'
import json,pathlib,sys,hashlib
p=pathlib.Path(sys.argv[1]); m=json.loads((p/'manifesto.json').read_text()); approval=json.loads(pathlib.Path(sys.argv[2]).read_text())
if m['sha256'] != approval['iso_sha256']: raise SystemExit('Partes pertencem a outra ISO')
for part in m['parts']:
    f=p/part['name']
    if f.name != part['name'] or f.is_symlink(): raise SystemExit('Nome inválido')
    with f.open('rb') as s:
        if hashlib.file_digest(s,'sha256').hexdigest()!=part['sha256']: raise SystemExit('Parte corrompida')
PY
notes="$ROOT/dist/release-notes.md"
cat > "$notes" <<'TEXT'
Candidato FÊNIX OS Legacy. Pré-lançamento, sem homologação física H55 presumida.
Baixe todas as partes, manifesto e JUNTAR_ISO.ps1; execute o script para verificar e reconstruir a ISO.
Consulte docs/QA.md e docs/INSTALACAO_WINDOWS_RUFUS.md. Nenhuma cobrança é habilitada por este script.
TEXT
gh release create "$tag" "$ROOT/dist/release/"* --repo Joescosame/F-NIX_OS --target "$(git -C "$ROOT" rev-parse HEAD)" --draft --prerelease --title "FÊNIX OS Legacy $tag (candidato)" --notes-file "$notes"
echo 'Draft prerelease criada. Revisão e publicação final continuam manuais; nunca marcar estável sem aprovação.'
