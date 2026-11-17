# Qualidade: critérios e evidências

Estados permitidos: **PASSOU**, **FALHOU**, **BLOQUEADO**, **NÃO EXECUTADO**. Ausência de erro no shell não homologa instalador ou login. O estado inicial está em `RESULTADOS.md`.

## Testes portáteis e Linux

`./tools/lint.sh` exige bash -n, ShellCheck, desktop-file-validate, Python AST, YAML, SVG e unittest. Os unittests cobrem reconstrução/hash, corrupção, parte ausente, caminhos maliciosos, callback timezone e histórico offline. No Windows incluem reconstrução real no Windows PowerShell 5.1; no Linux incluem snapshot e conferência do manifesto. Testes pulados aparecem como skipped, não aprovados.

`test-iso.sh inspect` verifica hash e estrutura de boot. `test-iso.sh install` abre QEMU com SeaBIOS, Westmere, 2 vCPUs, 4096 MiB, disco virtual qcow2 de 32 GiB, IDE e sem rede. Para 8 GB use `--ram 8192`. Não conecta pastas/discos físicos. A GUI requer DISPLAY no host; em CI sem GUI esta etapa fica NÃO EXECUTADA.

## Campanha obrigatória offline

1. Guarde hash da ISO e commit. Execute `./tools/test-iso.sh install`.
2. Capture o menu BIOS e o desktop Live. Confirme teclado e mouse. Abra **Instalar FÊNIX (modo offline)** pelo menu. Não habilite downloads de codecs ou atualizações.
3. No particionamento manual, crie tabela **msdos/MBR**, uma partição ext4 raiz e selecione o disco virtual inteiro para GRUB. Não criar tabela GPT. O único disco interno exibido é o QEMU de 32 GiB. Registre tela de particionamento, início e fim da instalação.
4. Selecione manualmente São Paulo/Brasília. Registre duração na etapa de horário. Se travar, capture tela e logs `/var/log/installer`, `/var/log/syslog`, `/var/log/partman`, sem marcar corrigido. Registre também horário da BIOS/RTC, estado da rede e versão Ubiquity.
5. Ao concluir, desligue. `-no-reboot` encerra QEMU quando o convidado solicita reinício. Execute **`./tools/test-iso.sh reboot`**. Esse comando não contém `-cdrom` e usa boot pelo disco.
6. Entre com usuário e senha criados; capture login e desktop. Copie e execute `tools/guest-check.sh` dentro do convidado. Ele recusa Live e UEFI, verifica Xfce, componentes, tabela MBR e zram; coleta serviços/memória/swap e histórico. Copie evidências para `qa/offline/` no host por meio controlado após o teste.
7. Abra o Hub; teste cada botão, snapshot, CSV/JSONL, fallback hardinfo, monitor e configuração reversível. Faça logout/login para testar Plank, atalhos e Super isolado. Snapshot é relatório, não imagem de recuperação.

O harness automatiza preparação, isolamento, comandos e registros; **não automatiza cliques no instalador nem aprova telas por inferência**. O JSON de execução continua NÃO EXECUTADO até revisão explícita das evidências. O teste de instalação fim a fim ainda precisa ser implementado/homologado para CI sem operador.

## Campanha com rede

Repita `install --online` e `reboot --online`; usa outro qcow2 em `qa/online`. Teste também o instalador original do Mint para comparar GeoIP/NTP e o modo offline do FÊNIX com interface de rede presente. Registre atrasos de DNS, falha HTTP, cancelamento de pesquisa, relógio incorreto e seleção local. Não desligar NTP globalmente como solução: no instalado, verificar `timedatectl` e sincronizar quando houver rede.

## Aceite e publicação

Para aprovar candidato, preencher `qa/aprovacao.json` conforme `config/aprovacao.example.json`, com hash da ISO, cada teste obrigatório e evidências relativas à pasta QA. Não copiar PASSOU sem executar. `tools/publish-release.sh` recusa resultados ausentes, hash divergente ou evidências inexistentes e só cria **draft prerelease**, com autorização explícita na linha de comando. Não há publicação estável automatizada.

Registros do QEMU e evidências não devem conter senhas ou chaves. Não publique logs completos sem revisão. O repositório é público; revisar cuidadosamente qualquer arquivo antes de anexá-lo à Release.

## H55 físico: homologação separada

QEMU não emula a GPU Ironlake nem o chipset H55. Após aprovação virtual, use USB BIOS Legacy e valide i915/Mesa (`lspci -k`, `glxinfo -B`), áudio, rede, USB, RAM, temperaturas, HD/SSD SATA, boot MBR e reinicialização sem pendrive. Compare swap/zram e desempenho com medições salvas. Não prometa Vulkan/Waydroid ou equivalência com Windows sem teste. A formatação física permanece seleção manual, após backup e conferência de modelo/capacidade.

Reprovar se boot falhar, instalador não concluir, disco não reiniciar, usuário não conseguir entrar, Xfce/Hub não persistirem ou ocorrer corrupção. Tratar extras como pendentes; não sacrificar a base para incluí-los.
