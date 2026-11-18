# FÊNIX OS

Sistema leve baseado no Linux Mint 22.3 Xfce / Ubuntu 24.04 LTS, x86_64, português brasileiro. Repositório oficial exclusivo: [Joescosame/F-NIX_OS](https://github.com/Joescosame/F-NIX_OS). Desenvolvimento por branches e PRs; main não recebe merge sem autorização.

## Evidências existentes

A primeira ISO foi [construída](https://github.com/Joescosame/F-NIX_OS/actions/runs/44002337245) e iniciou no [desktop Live Xfce em SeaBIOS](https://github.com/Joescosame/F-NIX_OS/actions/runs/44006253371). Tem 3.218.407.424 bytes e SHA-256 `1404e0c5dadecb595a3c031bd2538e51379579e18d412dc9ed7cea5b64f6c764`. Permanece preservada na Release de rascunho autenticada. Instalação, reboot pelo disco e portabilidade UEFI NÃO EXECUTADOS. Não é versão estável.

Esta branch executa somente a Fase 1 arquitetural: retira integrações canceladas, implementa Diagnóstico de Upgrade e prepara os critérios da próxima versão. Nenhuma ISO foi reconstruída nesta fase. A candidata anterior não contém essas alterações.

## Uso e desenvolvimento

Leia [Comece aqui](docs/COMECE_AQUI.md), [arquitetura](docs/ARQUITETURA.md), [roadmap](docs/ROADMAP.md) e [ADRs](docs/adr/0001-portabilidade.md).

```bash
python3 scripts/diagnostico-upgrade.py
python3 scripts/diagnostico-upgrade.py --comparar anterior.json atual.json
./tools/lint.sh
```

O diagnóstico salva somente dados locais e nunca instala drivers. Consulte [limites e modo gráfico](docs/DIAGNOSTICO_UPGRADE.md). O Hub mantém inventário, diagnóstico, histórico CSV/JSONL, snapshots de diagnóstico, monitoramento, Synaptic e atualizações Mint. Xfce, Whisker, Plank, atalhos, zram e ajustes reversíveis permanecem. Sem Snap, Flatpak ou drivers proprietários instalados automaticamente.

## Próximas campanhas

[Portabilidade Legacy/UEFI](docs/PORTABILIDADE.md) exige o mesmo disco virtual instalado nos dois firmwares; presença de arquivos GRUB não aprova boot. [Central de Desempenho](docs/CENTRAL_DESEMPENHO.md) e [Motor Android](docs/MOTOR_ANDROID.md) estão em arquitetura/pesquisa e não são recursos prontos. Não avançar para Fase 2 automaticamente.

O [construtor existente](docs/BUILD.md) verifica assinatura GPG e hash oficiais, remasteriza em chroot isolado, preserva boot e manifests, divide em partes de 1900 MiB e fornece scripts de reconstrução para Windows/Linux. Workflows são exclusivamente manuais, sem contratação de runners ou armazenamento pago. Nesta fase executar apenas Validar fontes.

[QA](docs/QA.md), [resultados atuais](docs/FASE1_RESULTADOS.md), [relatório do boot de referência](docs/RESULTADO_BOOT_LIVE.md), [Windows/Rufus](docs/INSTALACAO_WINDOWS_RUFUS.md), [licenças](docs/LICENCAS.md). A origem v0.2.2 e os relatórios históricos permanecem identificados; não executar guias históricos como instruções atuais.
