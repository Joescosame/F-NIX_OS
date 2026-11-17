# Primeiro boot Live — PASSOU

Resultado após revisão visual das capturas reais da [execução 44006253371](https://github.com/Joescosame/F-NIX_OS/actions/runs/44006253371), modo `boot-live`, código do teste `f3f7ed019f2ecce2628d3efa9230cd9bcc022f59`. A ISO não foi reconstruída: as partes existentes foram reunidas e o SHA-256 foi conferido antes de iniciar QEMU.

- ISO: commit `1472112ab07f93bcf2c94d589a79d2b63775e249`, 3218407424 bytes.
- SHA-256: `1404e0c5dadecb595a3c031bd2538e51379579e18d412dc9ed7cea5b64f6c764`.
- SeaBIOS explícito, máquina PC, CPU Westmere, 2 vCPUs, 4096 MiB, VGA std, aceleração TCG.
- Sem rede e sem disco rígido. Somente a ISO candidata no CD-ROM.
- Duração da coleta: 600,43 segundos. Doze capturas PNG via QMP. Nenhum erro registrado em qemu.log.

## Evidências observadas

| Captura | Observação | SHA-256 do PNG |
| --- | --- | --- |
| 0005.png (5,21 s) | Menu Legacy com Start Linux Mint e contagem automática | `21191444f951437ab33945ebe96dec8f3b32ffded431ec0cc80c2cff59da4a7b` |
| 0060.png (60,29 s) | Tela de inicialização com logotipo Mint | Consultar arquivo original |
| 0240.png (240,45 s) | Transição gráfica, tela preta com ponteiro | Consultar arquivo original |
| 0360.png (360,59 s) | Desktop Xfce, painel e ícone Instalar o Linux Mint | `fb92d53c376c115f3c2da25dd2ebb9170aa7e1f9ba1baeb271914a0b3bdf4fe4` |
| 0600.png (600,36 s) | Desktop Live continua visível | `63f940b38a13653e899d92bf31b17c26884e71bb4112cc8b52920e48494ffb54` |

O desktop foi observado aos seis minutos; não foi medida sua primeira aparição exata. A presença do desktop, painel e instalador Live, junto do comando QEMU sem disco rígido e do hash da ISO, sustenta a aprovação do objetivo de boot Live. Não equivale a testar aplicativos ou o instalador.

## Arquivo original

Na [Release de rascunho autenticada](https://github.com/Joescosame/F-NIX_OS/releases/tag/untagged-d8ba2d14680025ef3d14), baixe `boot-live-44006253371-1.tar.gz`. Contém resultado.json, comando, tempos, doze imagens e logs.

SHA-256 do arquivo: `54af9343a6176a3daf840e6e3715e65f1c75d2168c416134009315d3b32f7726`.

O resultado.json bruto permanece BLOQUEADO porque o coletor exige revisão visual posterior. Este documento registra essa revisão e o resultado PASSOU, preservando o registro bruto sem alterações.

## Limites e próximo passo

Instalação offline MBR, reinicialização pelo disco, funcionamento do Hub e homologação física Intel H55/Ironlake: **NÃO EXECUTADOS**. VGA std virtual não homologa i915/Ironlake físico. Nenhum merge na main ou publicação estável.

Estamos prontos para iniciar a campanha de instalação offline MBR em um disco virtual dedicado, usando esta mesma candidata.
