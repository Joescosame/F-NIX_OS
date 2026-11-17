#!/usr/bin/env bash
# Personalização por usuário no primeiro login XFCE (não rodar em chroot).
set -Eeuo pipefail
if [[ -z "${DISPLAY:-}" ]]; then echo 'Abra uma sessão gráfica do XFCE primeiro.'; exit 1; fi
command -v xfconf-query >/dev/null || { echo 'xfconf-query ausente'; exit 1; }
backup="$HOME/.local/share/fenix/backups/$(date +%Y%m%d_%H%M%S)_$$"
mkdir -p "$backup" "$HOME/.config/autostart" "$HOME/.config/Thunar" "$HOME/.config/plank/dock1/launchers"
if [[ -d "$HOME/.config/xfce4/xfconf" ]]; then cp -a "$HOME/.config/xfce4/xfconf" "$backup/xfconf-original"; fi
for c in xfce4-keyboard-shortcuts xfwm4 xfce4-panel xsettings xfce4-notifyd; do
  xfconf-query -c "$c" -lv > "$backup/$c.txt" 2>/dev/null || true
done
[[ ! -f "$HOME/.config/Thunar/uca.xml" ]] || cp "$HOME/.config/Thunar/uca.xml" "$backup/uca.xml"
set_pref() { # canal propriedade tipo valor; atualiza ou cria
  local c="$1" p="$2" t="$3" v="$4"
  if xfconf-query -c "$c" -p "$p" >/dev/null 2>&1; then
    xfconf-query -c "$c" -p "$p" -s "$v"
  else
    xfconf-query -c "$c" -p "$p" -n -t "$t" -s "$v"
  fi
}
c=xfce4-keyboard-shortcuts
# Tiling integrado ao xfwm4. SUPER isolado usa xcape para não bloquear SUPER+setas.
set_pref "$c" '/xfwm4/custom/<Super>Left' string 'tile_left_key'
set_pref "$c" '/xfwm4/custom/<Super>Right' string 'tile_right_key'
set_pref "$c" '/xfwm4/custom/<Super>Up' string 'maximize_window_key'
# SUPER+Down executa wmctrl: restaura janela maximizada sem tentar adivinhar ação do xfwm4.
xfconf-query -c "$c" -p '/xfwm4/custom/<Super>Down' -r >/dev/null 2>&1 || true
set_pref "$c" '/commands/custom/<Super>Down' string 'wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz'
set_pref "$c" '/commands/custom/<Super>e' string 'thunar'
set_pref "$c" '/commands/custom/<Super>r' string 'xfce4-appfinder --collapsed'
set_pref "$c" '/commands/custom/<Super>i' string 'xfce4-settings-manager'
set_pref "$c" '/commands/custom/<Primary><Shift>Escape' string 'xfce4-taskmanager'
set_pref "$c" '/commands/custom/<Primary>Escape' string 'xfce4-popup-whiskermenu'
set_pref "$c" '/commands/custom/<Super>t' string 'xfce4-terminal'
if command -v xcape >/dev/null 2>&1; then
  # Remove interceptação direta da tecla Super caso exista, mantendo Super+setas.
  xfconf-query -c "$c" -p '/commands/custom/Super_L' -r >/dev/null 2>&1 || true
  xfconf-query -c "$c" -p '/commands/custom/Super_R' -r >/dev/null 2>&1 || true
  cat > "$HOME/.config/autostart/fenix-super.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=FÊNIX - Tecla Super
Exec=xcape -e "Super_L=Control_L|Escape"
OnlyShowIn=XFCE;
NoDisplay=true
X-GNOME-Autostart-enabled=true
DESKTOP
  # A sessão seguinte reconhecerá toque Super isolado e manterá combinações.
else
  echo 'AVISO: xcape ausente; Ctrl+Esc abre o Whisker sem risco de conflito.'
fi
# Posição de painel nativo no topo. Preserva layout e widgets existentes;
# posição exata é validada no login/QA, sem reconstruir plugins às cegas.
if xfconf-query -c xfce4-panel -p /panels/panel-1/position >/dev/null 2>&1; then
  set_pref xfce4-panel /panels/panel-1/position string 'p=6;x=0;y=0'
else
  echo 'Painel nativo não identificado. Use Painel > Preferências para mover ao topo.'
fi
# Na Ironlake, compositor desligado por padrão; pode ser reativado no ajuste do xfwm4.
set_pref xfwm4 /general/use_compositing bool false
if command -v xfce4-popup-whiskermenu >/dev/null; then
  if ! xfconf-query -c xfce4-panel -lv 2>/dev/null | grep -qi whiskermenu; then
    xfce4-panel --add=whiskermenu >/dev/null 2>&1 || true
  fi
fi
if command -v plank >/dev/null 2>&1; then
  cat > "$HOME/.config/autostart/fenix-plank.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Plank Dock FÊNIX
Exec=plank
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
DESKTOP
  for item in thunar firefox xfce4-terminal hub-testes; do
    desktop=/usr/share/applications/$item.desktop
    [[ -f "$desktop" ]] || continue
    cat > "$HOME/.config/plank/dock1/launchers/$item.dockitem" <<EOF2
[PlankDockItemPreferences]
Launcher=file://$desktop
EOF2
  done
  if command -v gsettings >/dev/null 2>&1 && gsettings list-schemas | grep -qx net.launchpad.plank.dock.settings; then
    gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ position 'bottom' 2>/dev/null || true
    gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ hide-mode 'intellihide' 2>/dev/null || true
  fi
fi
# Notificações no topo direito; histórico na versão do notifyd disponível pelo painel de ajustes.
set_pref xfce4-notifyd /notify-location uint 2
# Nunca impor WhiteSur ou compositor num Ironlake antes do teste de estabilidade.
# Adiciona as ações do Thunar sem apagar outras ações existentes.
python3 - "$HOME/.config/Thunar/uca.xml" <<'PY'
import sys, xml.etree.ElementTree as ET
p=sys.argv[1]
try:
    tree=ET.parse(p); root=tree.getroot()
except (OSError, ET.ParseError):
    root=ET.Element('actions'); tree=ET.ElementTree(root)
items=[
 ('Abrir terminal aqui','xfce4-terminal --working-directory=%f','utilities-terminal', True),
 ('Editar como root','mousepad admin://%f','accessories-text-editor', False),
 ('Extrair aqui','xarchiver --extract-to=%d %f','package-x-generic', False),
]
existing={e.findtext('name') for e in root.findall('action')}
for name,command,icon,folder in items:
    if name in existing: continue
    a=ET.SubElement(root,'action')
    for tag,value in [('icon',icon),('name',name),('command',command),('description','Ação FÊNIX'),('patterns','*')]:
        ET.SubElement(a,tag).text=value
    ET.SubElement(a,'directories' if folder else 'other-files')
    if not folder: ET.SubElement(a,'text-files')
ET.indent(tree,space='  ')
tree.write(p,encoding='utf-8',xml_declaration=True)
PY
mkdir -p "$HOME/TestesPC"/{benchmarks,historico,snapshots,logs}
printf 'FÊNIX XFCE: concluído. Backup: %s\n' "$backup"
printf 'Plank e tecla Super isolada serão ativados na próxima sessão.\n'
