# Portabilidade do disco — projeto da Fase 2

Estado: **NÃO EXECUTADO**. A Fase 1 documenta o projeto e adapta verificadores; não altera kernel, initramfs, GRUB, firmware ou partições. A candidata de referência permanece imutável e só tem boot Live SeaBIOS aprovado.

## Layout proposto em disco virtual descartável

GPT, partição BIOS Boot sem filesystem de 2 MiB (tipo EF02/bios_grub), ESP FAT32 de 512 MiB (tipo EF00/esp), restante ext4 raiz. A ESP monta em /boot/efi por UUID; raiz e swap usam UUID, nunca um nome permanente como /dev/sda. BIOS Boot não é /boot e não recebe filesystem. Manter MBR protetor GPT; não criar MBR híbrido para o disco instalado. O MBR híbrido da mídia ISO é outro objeto.

O [GRUB documenta BIOS Boot em GPT](https://www.gnu.org/software/grub/manual/grub/html_node/BIOS-installation.html). O esquema é uma proposta para PCs x86_64 compatíveis; firmwares Legacy antigos podem recusar GPT ou exigir uma flag específica. Isso só pode ser aceito após boot real. Fallback: manter a instalação MBR original ou restaurar backup em outro disco, sem conversão automática destrutiva.

## Instalador e GRUB

O Ubiquity executa apenas o caminho correspondente ao firmware da sessão Live; ainda não foi demonstrado que instala ambos os destinos. Na Fase 2, usar particionamento manual exclusivamente em QCOW2 dedicado e auditar as versões/pacotes grub-pc-bin, grub-efi-amd64-bin e ferramentas efibootmgr disponíveis em Noble/Mint. Verificar conflitos entre pacotes de configuração antes de instalar. Não substituir o gerenciador de boot sem ensaio e recuperação.

Após instalação, protótipo controlado deve instalar destinos i386-pc no disco virtual inteiro e x86_64-efi na ESP, compartilhando a configuração /boot/grub. Planejar caminho fallback EFI/BOOT/BOOTX64.EFI sem depender de NVRAM da placa original; avaliar --removable e --no-nvram com as versões efetivas. [Manual grub-install](https://www.gnu.org/software/grub/manual/grub/html_node/Installing-GRUB-using-grub_002dinstall.html). Não executar estes procedimentos em discos físicos nesta campanha.

Secure Boot fica fora do aceite inicial; OVMF deve começar com Secure Boot desativado. Nenhuma promessa de chaves, shim assinado ou firmware modificado. Arquivos GRUB presentes não comprovam boot.

## Initramfs e hardware novo

Preservar kernel estável, firmware e drivers genéricos. Planejar MODULES=most, verificar conteúdos reais com lsinitramfs e módulos AHCI/SATA, SCSI, NVMe, USB e virtio usados na matriz. A configuração padrão [initramfs-tools Noble](https://manpages.ubuntu.com/manpages/noble/man5/initramfs.conf.5.html) favorece most; dep pode limitar portabilidade. NVMe deve ser conferido explicitamente na imagem, não inferido. Alterações de initramfs só na Fase 2 com cópia recuperável do kernel/initrd anterior e teste de rollback.

Não fixar Xorg/i915 nem instalar drivers proprietários automaticamente. A sessão deve usar detecção do kernel/Mesa. A troca de GPU pode exigir diagnóstico e intervenção manual. Discos criptografados vinculados ao TPM, mudança de controladora RAID e extensões de CPU ausentes podem exigir recuperação ou impedir a migração. Portabilidade não substitui backup de dados e da tabela de partições.

## Matriz de aceitação obrigatória

1. Criar um único QCOW2 independente, sem backing/data-file, e registrar ID da campanha, UUID raiz, PARTUUIDs e hash da ISO.
2. Instalar offline em GPT; registrar término do instalador e GRUB, nunca apenas inspeção de arquivos.
3. Desligar, retirar ISO, iniciar esse disco em SeaBIOS. Confirmar login, raiz por UUID, serviços e Hub.
4. Desligar, iniciar o mesmo disco em OVMF com arquivo VARS próprio. Confirmar boot UEFI, ESP, login e mesmo UUID raiz.
5. Retornar a SeaBIOS, depois repetir UEFI com VARS novo (sem entrada NVRAM herdada). Nenhuma reinstalação ou nova raiz entre etapas.
6. Alterar separadamente controlador IDE/SATA/AHCI, virtio e NVMe quando suportados pelo QEMU; usar o mesmo disco e comparar inventários. Manter uma cópia de recuperação anterior, identificando quando uma cópia foi usada; não misturar seus resultados com a migração do disco original.
7. Reprovar migração se depender da ISO, de reinstalação, de entrada NVRAM anterior, de caminho /dev fixo ou de disco diferente. Registrar cada boot e duração, logs e capturas, UUID raiz e disco_campanha.

Não usar hash completo do QCOW2 como identidade invariável: o convidado escreve logs ao iniciar. Usar ID de campanha + cadeia de custódia do arquivo + UUID/PARTUUIDs, com hashes antes/depois registrados como estados distintos.

## Verificações preparadas

- guest-check.sh mantém padrão legacy/dos para a candidata de referência. Para outra campanha, argumentos explícitos `legacy gpt` ou `uefi gpt`; UEFI exige ESP FAT montada. Copiar também platform-check.py junto do script. Isso é verificação parcial, não prova de boot duplo.
- check-boot.py --dual exige entradas BIOS e UEFI habilitadas e preservação de atributos; ainda exige MBR da mídia híbrida. Não interpreta disco instalado como ISO.
- Gate de aprovação mantém legacy-mbr-v1 para evidências antigas; portable-gpt-v1 exige instalação GPT, boots e migrações independentes, com disco_campanha coincidente. O gate verifica declarações e arquivos, não substitui revisão de boot real.
- qemu-qa.py e boot-live.py continuam harnesses Legacy identificados. A extensão OVMF e o controle do mesmo disco são trabalho da Fase 2; não foram simulados como aprovados nesta entrega.
