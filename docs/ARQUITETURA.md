# Arquitetura

## Camadas

1. `config/base.env`: versão, URL oficial, fingerprint e hash fixados da ISO.
2. `tools/fetch-base.sh`: baixa o manifesto e assinatura sem alterá-los, usa chave isolada e valida `VALIDSIG`; compara hash assinado, hash fixado e ISO.
3. `tools/build-iso.sh`: extrai a mídia, abre squashfs em chroot dentro de namespace de montagem privado, modifica somente a árvore temporária e remasteriza com `xorriso -boot_image any replay`.
4. `scripts/install-packages.sh`: instalação apt, dependências essenciais obrigatórias, remoção simulada e protegida de Snap/Flatpak, sem autoremove nem PPAs.
5. `scripts/stage-into-root.sh`: `/usr/local/lib/fenix`, aplicativos, ícones, modelos e `/etc/skel` entram no squashfs. O instalador copia estes arquivos ao destino. Os manifests são atualizados preservando exclusões Live e retendo pacotes FÊNIX e traduções PT-BR. A persistência efetiva requer QA no sistema instalado.
6. Autostart do primeiro login: aplica perfil Xfce por usuário com backup. Não marca sucesso após erro de configuração; a sessão Live é ignorada. Isso evita confundir perfil do usuário `mint` com o novo usuário instalado.
7. `tools/qemu-qa.py`: cria exclusivamente um arquivo qcow2 próprio, sem backing file, 2 vCPUs Westmere, SeaBIOS explícito, 4–8 GB de RAM e rede desligada por padrão. **O instalador gráfico é operado manualmente**; não há teste desassistido completo nesta versão.

## Limites de segurança e estabilidade

Nenhum script do host particiona ou formata disco. O construtor não recebe dispositivos de bloco como saída. O harness não aceita caminhos de discos fornecidos pelo usuário nem passagem de discos físicos. O instalador original continua com seleção e confirmação manuais de destino.

O namespace evita propagação de mounts ao host. Uma política temporária impede inicialização de serviços no chroot. DNS e política original são restaurados antes da recompressão. Árvore e logs permanecem em `work/build.*` para investigação. Não se remove árvore de build automaticamente após falha; desmonte antes de limpar e use uma VM descartável.

Mantemos kernel e initrd da base, driver i915/Mesa, sem driver Xorg forçado. Waydroid, HWall, HardInfo2, SMC e WhiteSur não são instalados pela base. MangoHud/GOverlay só são incluídos se houver candidato apt; continuam sujeitos a teste real. Vulkan e jogos recentes não são prometidos na Ironlake.

As versões dos pacotes são registradas. Repetir o procedimento é possível, mas os repositórios apt mudam: **não se promete ISO idêntica byte a byte** sem espelho/snapshot apt congelado e timestamps normalizados. A assinatura da ISO não autentica pacotes externos; não entram automaticamente.

## Dados e licenças

Históricos e snapshots permanecem locais, com permissão restrita. Relatórios podem incluir identificadores; não entram no Git ou em Release automaticamente. Leia `LICENCAS.md` antes de distribuir uma ISO. O nome FÊNIX não implica endosso do Linux Mint.
