# Primeiro boot real da candidata

No workflow manual existente, escolha a branch do PR #2, `modo=boot-live` e confirme os recursos. O job de construção fica desativado nesse modo. O teste baixa a candidata da construção #5, reconstrói as partes e exige SHA-256 e tamanho exatos antes de iniciar QEMU.

SeaBIOS, máquina PC, CPU Westmere, 2 vCPUs, 4096 MiB, vídeo std e TCG. Sem rede e sem disco rígido: somente a ISO como CD-ROM. Nenhum dispositivo físico é acessado. Capturas QMP reais aos 2, 5, 15, 30, 60, 90, 120, 180, 240, 360, 480 e 600 segundos; Enter aos 15 segundos confirma a opção padrão do menu. QEMU é encerrado ao final do limite.

Logs, comando, duração e capturas PNG são arquivados no rascunho existente. O resultado inicial fica BLOQUEADO para revisão visual: sucesso do processo ou workflow significa coleta concluída, não aprovação do boot. O responsável deve identificar o menu e o desktop Live nas capturas antes de registrar PASSOU. Instalação e reinicialização pelo disco continuam NÃO EXECUTADOS.
