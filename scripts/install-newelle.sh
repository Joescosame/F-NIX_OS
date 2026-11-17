#!/usr/bin/env bash
# Integração opcional FÊNIX fase 2: .desktop + launcher; sem gravar API key.
set -Eeuo pipefail
if (( EUID == 0 )); then echo 'Execute como usuário normal.' >&2; exit 1; fi
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Compila se o launcher ainda não estiver disponível.
if [[ ! -x /usr/local/bin/fenix-newelle ]]; then
  bash "$here/build-newelle.sh"
fi
[[ -x /usr/local/bin/newelle && -x "$HOME/.local/share/fenix/newelle-venv/bin/python" ]] || { echo 'Falha: /usr/local/bin/newelle ausente.'; exit 1; }
# O arquivo original upstream é preservado; criamos uma entrada FÊNIX própria.
tmp="$(mktemp)"
cat > "$tmp" <<'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Assistente IA (Newelle)
Comment=Assistente opcional FÊNIX com API na nuvem
Exec=/usr/local/bin/fenix-newelle
Icon=io.github.qwersyk.Newelle
Terminal=false
Categories=Utility;Network;
StartupNotify=true
DESKTOP
sudo install -Dm644 "$tmp" /usr/share/applications/newelle-fenix.desktop
rm -f "$tmp"
if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate /usr/share/applications/newelle-fenix.desktop
fi
# hub-testes.sh já possui integração condicional; nada é alterado na ISO base.
echo 'Atalho disponível. No Hub de Testes, o botão Newelle aparece se fenix-newelle existir.'
echo 'Configure DeepSeek/API Key manualmente na primeira abertura.'
