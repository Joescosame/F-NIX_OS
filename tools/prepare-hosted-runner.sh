#!/usr/bin/env bash
# Remove somente SDKs dispensáveis de uma VM efêmera hospedada pelo GitHub.
set -Eeuo pipefail
[[ $EUID == 0 && ${GITHUB_ACTIONS:-} == true && ${RUNNER_ENVIRONMENT:-} == github-hosted ]] || {
  echo 'BLOQUEADO: limpeza exclusiva do runner efêmero GitHub-hosted.' >&2; exit 1;
}
source /etc/os-release
[[ ${ID:-} == ubuntu && ${VERSION_ID:-} == 24.04 ]] || exit 1
df -h .
for path in /usr/local/lib/android /usr/share/dotnet /opt/ghc /opt/hostedtoolcache/CodeQL; do
  [[ ! -L $path ]] || { echo "BLOQUEADO: link inesperado em $path" >&2; exit 1; }
  if [[ -d $path ]]; then
    printf 'Removendo SDK dispensável do executor efêmero: %s\n' "$path"
    rm -rf --one-file-system -- "$path"
  fi
done
df -h .
echo 'Recursos reais serão conferidos novamente pelo preflight; espaço não é garantido.'
