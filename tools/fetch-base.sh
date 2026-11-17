#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname -- "$0")/common.sh"
source "$ROOT/config/base.env"
mkdir -p "$ROOT/cache"
cd "$ROOT/cache"
curl_opts=(--fail --location --retry 3 --connect-timeout 20 --max-time 180)
curl "${curl_opts[@]}" "$MINT_URL/sha256sum.txt" -o sha256sum.txt
curl "${curl_opts[@]}" "$MINT_URL/sha256sum.txt.gpg" -o sha256sum.txt.gpg
keyhome=$(mktemp -d)
trap 'rm -rf -- "$keyhome"' EXIT
chmod 700 "$keyhome"
gpg --homedir "$keyhome" --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys "$MINT_FINGERPRINT"
gpg --homedir "$keyhome" --batch --status-fd 1 --verify sha256sum.txt.gpg sha256sum.txt > gpg-status.txt 2>gpg-verification.txt
awk -v fingerprint="$MINT_FINGERPRINT" '$2=="VALIDSIG" && ($3==fingerprint || $NF==fingerprint) {ok=1} END {exit !ok}' gpg-status.txt || die 'Assinatura não corresponde à chave fixada.'
python3 - "$ISO_NAME" "$ISO_SHA256" <<'PY'
import pathlib, sys
rows=[line.split() for line in pathlib.Path('sha256sum.txt').read_text().splitlines() if line.strip()]
hits=[h for h,n in rows if n.lstrip('*') == sys.argv[1]]
if hits != [sys.argv[2]]: raise SystemExit('Manifesto assinado diverge do hash fixado. Revisão necessária.')
PY
if [[ -n ${FENIX_BASE_ISO:-} ]]; then
  [[ -f $FENIX_BASE_ISO && ! -L $FENIX_BASE_ISO ]] || die 'ISO local inválida.'
  iso=$(realpath "$FENIX_BASE_ISO")
else
  iso="$ROOT/cache/$ISO_NAME"
  if [[ ! -f $iso ]]; then
    curl --fail --location --retry 3 --connect-timeout 20 "$MINT_URL/$ISO_NAME" -o "$iso.partial"
    mv -- "$iso.partial" "$iso"
  fi
fi
printf '%s  %s\n' "$ISO_SHA256" "$iso" | sha256sum -c -
printf '%s\n' "$iso" > "$ROOT/cache/base-path.txt"
