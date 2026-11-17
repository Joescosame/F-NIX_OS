#!/usr/bin/env bash
# Instalar .deb adicionais fornecidos pelo construtor somente com SHA-256 pré-validado.
# Usar exclusivamente numa VM de build descartável, após revisão dos fornecedores.
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Execute como root no chroot Cubic'; exit 1; }
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../externals" && pwd)"
[[ -f "$base/SHA256SUMS.txt" ]] || { echo "Sem $base/SHA256SUMS.txt: nenhum arquivo externo instalado."; exit 2; }
shopt -s nullglob
pkgs=("$base"/*.deb)
((${#pkgs[@]})) || { echo 'Nenhum .deb encontrado.'; exit 2; }
python3 - "$base" <<'PY'
import pathlib, sys
p=pathlib.Path(sys.argv[1]); listed=set()
for line in (p/'SHA256SUMS.txt').read_text().splitlines():
    if not line.strip(): continue
    digest, name=line.split(maxsplit=1); name=name.lstrip('*')
    if pathlib.PurePosixPath(name).name != name or '\\' in name or ':' in name:
        raise SystemExit('Manifesto externo deve usar somente nomes locais')
    if name.endswith('.deb'): listed.add(name)
actual={f.name for f in p.glob('*.deb')}
if actual != listed or any(f.is_symlink() for f in p.glob('*.deb')):
    raise SystemExit('Todo DEB precisa estar listado no manifesto; links são proibidos')
PY
(cd "$base" && sha256sum -c SHA256SUMS.txt)
for pkg in "${pkgs[@]}"; do dpkg-deb --info "$pkg" | sed -n '1,25p'; done
read -r -p 'Fornecedores e metadados auditados? Digite INSTALAR: ' answer
[[ "$answer" == INSTALAR ]] || exit 2
apt-get install -y --no-install-recommends "${pkgs[@]}"
