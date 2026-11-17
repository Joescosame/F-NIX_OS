#!/usr/bin/env bash
# FÊNIX OS / FASE 2: compila Newelle via Meson (NÃO usa install.sh: ele usa Flatpak).
# Execução como usuário normal; logs sem chave DeepSeek.
set -Eeuo pipefail
if (( EUID == 0 )); then echo 'Não execute como root.' >&2; exit 1; fi
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/TestesPC/logs" "$HOME/.local/state/fenix-newelle"
log="$HOME/TestesPC/logs/build-newelle.log"
exec > >(tee -a "$log") 2>&1
printf '\n=== Newelle fase 2: %s ===\n' "$(date -Is)"
# Primeiro instala somente as dependências, fora da imagem ISO base.
bash "$here/install-newelle-deps.sh"
repo="$HOME/.local/src/fenix-newelle/Newelle"
mkdir -p "$(dirname "$repo")"
if [[ ! -d "$repo/.git" ]]; then
  [[ ! -e "$repo" ]] || { echo 'Diretório de fonte já existe e não é git.'; exit 1; }
  git clone --depth 1 https://github.com/qwersyk/Newelle.git "$repo"
else
  [[ "$(git -C "$repo" remote get-url origin)" == 'https://github.com/qwersyk/Newelle.git' ]] || {
    echo 'Origem Git diferente da oficial. Interrompido.'; exit 1;
  }
  # Nunca altera silenciosamente uma árvore local já existente.
  git -C "$repo" diff --quiet && git -C "$repo" diff --cached --quiet || {
    echo 'Há alterações locais; revise antes de compilar.'; exit 1;
  }
fi
# Ref opcional para versões reproduzíveis: NEWELLE_REF=<tag ou SHA>.
if [[ -n "${NEWELLE_REF:-}" ]]; then
  git -C "$repo" fetch --depth=1 origin "$NEWELLE_REF"
  git -C "$repo" checkout --detach FETCH_HEAD
fi
commit="$(git -C "$repo" rev-parse HEAD)"
printf '%s\n' "$commit" > "$HOME/.local/state/fenix-newelle/commit.txt"
[[ -f "$repo/modules/requirements.txt" && -f "$repo/meson.build" ]] || {
  echo 'Estrutura do repositório mudou; build cancelado.'; exit 1;
}
# NÃO fazer pip install -r requirements.txt: inclui modelos locais, FAISS e áudio pesado.
# Venv isolado com acesso aos bindings GTK instalados pelo apt.
venv="$HOME/.local/share/fenix/newelle-venv"
mkdir -p "$(dirname "$venv")"
python3 -m venv --system-site-packages "$venv"
"$venv/bin/python" -m pip install --prefer-binary \
  'openai>=1,<3' requests expandvars pillow lxml lxml_html_clean \
  markdownify pylatexenc tldextract tiktoken pydub
# Verificação de importação mínima antes da instalação global.
"$venv/bin/python" - <<'PYTEST'
import gi, openai, requests, PIL, lxml, expandvars, markdownify
for namespace, ver in [('Gtk','4.0'), ('Adw','1'), ('WebKit','6.0'), ('Vte','3.91')]:
    gi.require_version(namespace, ver)
from gi.repository import Gtk, Adw, WebKit, Vte
print('Bibliotecas essenciais importadas; a GUI ainda precisa de teste real.')
PYTEST
# Evita sobrescrever instalação anterior não gerenciada.
state="$HOME/.local/state/fenix-newelle"
if [[ -e /usr/local/bin/newelle && ! -f "$state/installed-files.txt" ]]; then
  echo 'Newelle já existe em /usr/local e não há manifesto FÊNIX. Interrompido.' >&2
  exit 1
fi
cd "$repo"
if [[ -d builddir ]]; then
  meson setup --reconfigure builddir --prefix=/usr/local --buildtype=release
else
  meson setup builddir --prefix=/usr/local --buildtype=release
fi
meson compile -C builddir
sudo meson install -C builddir
# upstream pode gerar launcher sem bit de execução para usuário comum.
# Ajusta apenas o launcher instalado pelo Meson em /usr/local.
sudo chmod 0755 /usr/local/bin/newelle
# Registra destinos instalados pela build, limitados a /usr/local (para reversão).
meson introspect --installed builddir | python3 -c '
import json,sys
obj=json.load(sys.stdin)
files=obj.values() if isinstance(obj,dict) else []
for p in sorted(set(files)):
    if isinstance(p,str) and p.startswith("/usr/local/"):
        print(p)
' > "$state/installed-files.txt"
# O Newelle tem launcher Python; executa-o com a venv do usuário, não via pip global.
tmp="$(mktemp)"
cat > "$tmp" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
venv="$HOME/.local/share/fenix/newelle-venv"
[[ -x "$venv/bin/python" ]] || { echo 'Ambiente Python Newelle ausente para este usuário.' >&2; exit 1; }
exec "$venv/bin/python" /usr/local/bin/newelle "$@"
WRAPPER
sudo install -m 0755 "$tmp" /usr/local/bin/fenix-newelle
rm -f "$tmp"
[[ -x /usr/local/bin/newelle && -x /usr/local/bin/fenix-newelle ]] || {
  echo 'Instalação incompleta: launcher não localizado.' >&2; exit 1;
}
echo "Newelle compilado (commit $commit). Teste gráfico ainda pendente."
echo "Log: $log"
