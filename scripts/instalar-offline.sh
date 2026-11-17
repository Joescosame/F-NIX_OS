#!/usr/bin/env bash
# Não configura disco nem dispara instalação desassistida.
set -Eeuo pipefail
grep -qw boot=casper /proc/cmdline || { echo 'Permitido somente na sessão Live.' >&2; exit 1; }
if ((EUID != 0)); then
  exec sudo --preserve-env=DISPLAY,XAUTHORITY,DBUS_SESSION_BUS_ADDRESS,XDG_DATA_DIRS,XDG_RUNTIME_DIR,GTK_THEME "$0" "$@"
fi
debconf-set-selections <<'CONF'
d-i clock-setup/ntp boolean false
d-i tzsetup/geoip_server string
d-i time/zone string America/Sao_Paulo
d-i debian-installer/locale string pt_BR.UTF-8
CONF
export FENIX_INSTALL_OFFLINE=1
export WEBKIT_DISABLE_COMPOSITING_MODE=1
exec /usr/bin/ubiquity gtk_ui
