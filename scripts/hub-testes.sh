#!/usr/bin/env bash
# Interface única FÊNIX; nenhuma ferramenta pesada fica executando em segundo plano.
set -u
notify() {
  if command -v yad >/dev/null 2>&1; then yad --center --info --title='Hub de Testes FÊNIX' --text="$1" --button=OK:0;
  else printf '%s\n' "$1"; fi
}
launch() { command -v "$1" >/dev/null 2>&1 && { "$@" >/dev/null 2>&1 & } || notify "Ferramenta não instalada: $1. Use Synaptic para verificar a disponibilidade."; }
action="${1:-menu}"
case "$action" in
  inventory)
    if command -v hardinfo2 >/dev/null; then launch hardinfo2
    elif command -v hardinfo >/dev/null; then launch hardinfo
    elif command -v cpu-x >/dev/null; then launch cpu-x
    else notify 'Inventário GUI indisponível; execute Salvar Snapshot para obter relatório local.'; fi
    ;;
  history)
    if command -v hwall >/dev/null 2>&1; then launch hwall
    else
      if command -v xfce4-terminal >/dev/null; then
        xfce4-terminal --hold -x python3 /usr/local/lib/fenix/historico-sensores.py --duration 120 --interval 5 >/dev/null 2>&1 &
      else notify 'Terminal Xfce indisponível'; fi
      notify 'HWall não instalado. Histórico equivalente será salvo pelo coletor leve em ~/TestesPC/historico (CSV + JSONL).'
    fi
    ;;
  snapshot) /usr/local/lib/fenix/salvar-snapshot.sh ;;
  live)
    if command -v system-monitoring-center >/dev/null; then launch system-monitoring-center
    elif command -v xfce4-taskmanager >/dev/null; then launch xfce4-taskmanager
    elif command -v htop >/dev/null; then launch xfce4-terminal -e htop
    else notify 'Nenhum monitor em tempo real disponível.'; fi
    ;;
  upgrade) python3 /usr/local/lib/fenix/diagnostico-upgrade.py --gui ;;
  synaptic)
    if command -v synaptic-pkexec >/dev/null; then launch synaptic-pkexec
    elif command -v synaptic >/dev/null && command -v pkexec >/dev/null; then launch pkexec "$(command -v synaptic)"
    else notify 'Synaptic ou autenticação administrativa indisponível.'; fi
    ;;
  update) if command -v mintupdate >/dev/null; then launch mintupdate; else notify 'mintupdate indisponível.'; fi ;;
  menu)
    if ! command -v yad >/dev/null; then echo 'YAD indisponível. Execute: hub-testes.sh {inventory|upgrade|history|snapshot|live|synaptic|update}'; exit 1; fi
    yad --center --title='Hub de Testes | FÊNIX OS' --width=660 --height=290 \
      --form --columns=2 --separator='' --button='Fechar:0' \
      --field='Inventário e Benchmark:BTN' '/usr/local/lib/fenix/hub-testes.sh inventory' \
      --field='Diagnóstico de Upgrade:BTN' '/usr/local/lib/fenix/hub-testes.sh upgrade' \
      --field='Histórico de Sensores:BTN' '/usr/local/lib/fenix/hub-testes.sh history' \
      --field='Salvar Snapshot do PC:BTN' '/usr/local/lib/fenix/hub-testes.sh snapshot' \
      --field='Monitoramento em Tempo Real:BTN' '/usr/local/lib/fenix/hub-testes.sh live' \
      --field='Central de Programas:BTN' '/usr/local/lib/fenix/hub-testes.sh synaptic' \
      --field='Atualizações do Sistema:BTN' '/usr/local/lib/fenix/hub-testes.sh update' \
      >/dev/null 2>&1 || true
    ;;
  *) echo "Ação desconhecida: $action" >&2; exit 2;;
esac
