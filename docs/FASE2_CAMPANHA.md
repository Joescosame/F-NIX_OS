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

## Diagnóstico da primeira tentativa

[Execução 44283462064](https://github.com/Joescosame/F-NIX_OS/actions/runs/44283462064): validações Linux e reconstrução com SHA-256 **PASSARAM**. Campanha interrompida após 8 minutos de VM porque o serviço de QA não iniciou. A serial registrou `Initramfs unpacking failed: invalid magic at start of compressed archive`; a captura de 450 s mostra o desktop Live, sem execução do instalador. Instalação e migração: **NÃO EXECUTADOS**.

A extensão newc começava imediatamente após os 82.518.462 bytes do initrd original, em offset com resto 2 na divisão por 4. O [formato initramfs do kernel](https://www.kernel.org/doc/html/latest/driver-api/early-userspace/buffer-format.html) exige alinhamento ALGN(4). A correção acrescenta dois bytes nulos antes do arquivo CPIO temporário; não modifica o original ou a ISO. Regressão cobre todos os restos e o tamanho observado. O executor agora aborta cedo diante do erro do kernel ou de 10 minutos sem início do serviço.

Evidências preservadas no rascunho: `portable-44283462064-1.tar.gz`, SHA-256 `0d5b692ac4a11fa368ed1c5656039b2ce5f537d22d4b5f56f18bdc9e39bf9d3f`. A correção requer nova execução real antes de qualquer aprovação.

[Tentativa 44286694048](https://github.com/Joescosame/F-NIX_OS/actions/runs/44286694048): **FALHOU** em 6,2 s de VM com a mesma mensagem; 28 testes Linux passaram e 2 exclusivos do Windows não executaram. A primeira correção não descarregava o buffer Python antes da escrita direta do subprocesso `cpio`. Reprodução com prefixo `xx` e escritor externo `070701` produziu `xx070701\0\0`: os zeros ficaram depois do cabeçalho. Agora `flush()` é obrigatório antes do processo externo, com teste de regressão que reproduz a escrita em arquivo real. Evidências: `portable-44286694048-1.tar.gz`, SHA-256 `37020ae9bd3eae8ac79583983f6a90486a443adbeabb61b07672668f9a38238f`. Instalador e migrações continuam **NÃO EXECUTADOS** nessa tentativa.
