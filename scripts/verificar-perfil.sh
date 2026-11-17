#!/usr/bin/env bash
# Auditoria da imagem/chroot. Faltas impeditivas para o perfil completo são reportadas.
set -u
fail=0
check(){
  local tool="$1" label="$2"
  if command -v "$tool" >/dev/null 2>&1; then echo "OK: $label ($tool)"
  else echo "FALTA: $label ($tool)"; fail=$((fail+1)); fi
}
check xfce4-session XFCE
check xfce4-panel Painel
check xfce4-popup-whiskermenu Whisker
check plank Plank
check yad HubGUI
check synaptic Synaptic
check mintupdate MintUpdate
check mpv MPV
check mangohud MangoHud
check goverlay GOverlay
check hardinfo2 HardInfo2
check hwall HWall
check system-monitoring-center SystemMonitoringCenter
check hwall-cli HWallCLI
check xfce4-taskmanager MonitorFallback
if [[ $fail -gt 0 ]]; then
  echo "NÃO HOMOLOGADO: $fail componente(s) não atendido(s). Modo FÊNIX com fallbacks ainda pode funcionar."
  exit 1
fi
echo 'Todos os executáveis esperados foram encontrados. Testes funcionais ainda obrigatórios.'
