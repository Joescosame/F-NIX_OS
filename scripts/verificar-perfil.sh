#!/usr/bin/env bash
set -Eeuo pipefail
fail=0
for tool in xfce4-session xfce4-panel xfce4-terminal xfce4-popup-whiskermenu plank yad synaptic mintupdate mpv hardinfo xfce4-taskmanager python3 sensors; do
  if command -v "$tool" >/dev/null; then echo "PASSOU: executável $tool";
  else echo "FALHOU: ausente $tool"; fail=$((fail+1)); fi
done
for tool in hardinfo2 hwall system-monitoring-center; do
  command -v "$tool" >/dev/null || echo "NÃO INCLUÍDO: $tool (opcional; fallback no Hub)"
done
((fail == 0))
echo 'Presença de executáveis verificada; funcionalidade gráfica precisa de QA.'
