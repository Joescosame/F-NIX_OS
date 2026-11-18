# Fase 2 — instalação portátil em VM

Campanha experimental. Não autoriza executar hooks de QA num computador físico. A candidata ISO é lida e conferida por SHA-256, sem remasterização ou substituição. O modo manual portable-install usa só o executor público padrão Ubuntu 24.04; nenhum runner pago, disco físico ou dispositivo externo é aceito.

## Instrumentação declarada

Para automatizar Ubiquity offline, o kernel e initrd são extraídos da candidata. Uma extensão cpio temporária do initrd instala um serviço **somente no Live da VM de QA**, carrega o preseed e inicia o instalador original. A fase de instalação usa boot direto do kernel por QEMU; não é um novo teste El Torito da ISO. O boot Live SeaBIOS da mídia já tem evidência separada.

O serviço exige boot=casper, marcador de kernel, DMI FENIX-QA-PORTABLE, exatamente um disco virtual de 32 GiB e serial FENIXQA001. O host cria exclusivamente qa/portable/destino.qcow2 independente. A rede da VM está ausente. A senha aleatória do usuário de laboratório fica só no payload efêmero, não é publicada. Login instalado usa autologin de fenixqa; esse ensaio não valida autenticação por senha.

O manifesto de remoção do Live recebe bind temporário em RAM que retém grub-efi-amd64-bin. O binário já existe na candidata; sem retenção o Ubiquity o excluiria. O hook de sucesso audita GPT e ESP e executa grub-install para i386-pc e x86_64-efi, este com fallback removível e sem NVRAM. Faz backup de fstab e arquivos GRUB anteriores no disco de laboratório. Não troca kernel ou binários GRUB por versões externas. Essa intervenção testa uma **instalação com o protótipo de configuração portátil**, não demonstra suporte portátil nativo da ISO de referência sem o hook.

## Aceite e sequência

Receita GPT: 2 MiB BIOS Boot, 512 MiB ESP FAT, raiz ext4 restante. Ubiquity deve executar seu hook de sucesso e a VM desligar. Depois o mesmo arquivo/inode QCOW2 deve iniciar, sempre sem CD-ROM e sem -kernel/-initrd:

1. SeaBIOS/IDE.
2. OVMF/IDE com VARS novo.
3. Retorno a SeaBIOS/IDE.
4. OVMF/IDE com outro VARS novo, sem entrada NVRAM herdada.
5. OVMF/SATA-AHCI.
6. OVMF/NVMe.

A sonda instalada temporária verifica raiz não Live, GPT, usuário com xfce4-session, presença do Hub e ESP montada em UEFI, registra modo real, UUID raiz e ID da campanha na serial e desliga. Isso comprova boot e sessão instalada, não operação dos botões do Hub. Sua presença é exclusiva do disco descartável de teste, não uma decisão de autostart do produto. O mesmo UUID raiz, ID da campanha e inode devem se manter em todos os boots. Hashes completos do QCOW2 mudam a cada boot e são registrados antes/depois, não usados como identidade invariável.

QEMU usa 2 vCPUs/4 GiB, Westmere e VGA std; KVM quando acessível, senão TCG. Limites: 40 min instalador e 10 min por boot, até 110 min job incluindo preparação. Erros explícitos abortam cedo. Logs, PNGs e JSON são guardados no rascunho; payload com senha, initrds e QCOW2 não são enviados. Revisar capturas e marcadores, não aprovar por processo ativo ou arquivos EFI presentes. Se falhar, os casos seguintes permanecem NÃO EXECUTADOS.

## Referências técnicas

- [Particionamento/preseed Debian](https://sources.debian.org/src/installation-guide/20230508%2Bdeb12u1/en/appendix/preseed.xml): formato da receita, confirmações e GPT/EFI; compatibilidade efetiva com Ubiquity precisa ser executada.
- [Ubiquity Mint](https://github.com/linuxmint/ubiquity/blob/master/scripts/install.py): manifesto controla a lista de pacotes removidos; a versão efetiva continua a da candidata, registrada na campanha.
- [GRUB BIOS/GPT](https://www.gnu.org/software/grub/manual/grub/html_node/BIOS-installation.html) e [EFI removível](https://www.gnu.org/software/grub/manual/grub/html_node/Installing-GRUB-using-grub_002dinstall.html).

Estado inicial: instalação e migração **NÃO EXECUTADOS**. Será atualizado com execução e evidências reais. A homologação física e Secure Boot continuam fora do aceite.
