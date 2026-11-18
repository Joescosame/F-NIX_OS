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

Os namespaces de montagem e processos evitam propagação de mounts e separam a árvore de processos. O chroot recebe `/dev` em tmpfs com somente dispositivos de caracteres essenciais e devpts próprio; discos do host não são compartilhados. Uma política temporária impede inicialização de serviços. Isso reduz exposição acidental, mas um chroot root não deve ser considerado uma sandbox para código malicioso: use somente fontes confiáveis numa VM descartável. DNS e política original são restaurados antes da recompressão. Árvore e logs permanecem em `work/build.*` para investigação. Não se remove árvore de build automaticamente após falha; desmonte antes de limpar.

Mantemos kernel e initrd estáveis da base, drivers genéricos do kernel/Mesa e detecção automática, sem driver Xorg forçado ou proprietário automático. Ferramentas avançadas dependem de homologação; as integrações canceladas foram retiradas conforme ADR 0003. Nenhuma portabilidade universal ou API gráfica é presumida.

As versões dos pacotes são registradas. Repetir o procedimento é possível, mas os repositórios apt mudam: **não se promete ISO idêntica byte a byte** sem espelho/snapshot apt congelado e timestamps normalizados. A assinatura da ISO não autentica pacotes externos; não entram automaticamente.

## Dados e licenças

Históricos e snapshots permanecem locais, com permissão restrita. Relatórios podem incluir identificadores; não entram no Git ou em Release automaticamente. Leia `LICENCAS.md` antes de distribuir uma ISO. O nome FÊNIX não implica endosso do Linux Mint.

## Evolução arquitetural — Fase 1

Decisões em adr/: disco portátil GPT com dois destinos de boot (proposto), diagnóstico local sem telemetria (implementado), separação coleta/overlay e Android isolado (pesquisa), identidade genérica PT-BR. PORTABILIDADE.md detalha GRUB, instalador, initramfs, recuperação e matriz de migração do mesmo QCOW2. Nenhuma alteração desses componentes críticos foi executada nesta fase.

diagnostico-upgrade.py lê proc/sysfs sob demanda, salva JSON restrito e compara registros; o Hub e o .desktop chamam a mesma entrada. Não inicia daemon. Dados simulados validam contratos, ausências e diferenças; GUI instalada e hardware real permanecem pendentes. CENTRAL_DESEMPENHO.md e MOTOR_ANDROID.md são propostas sem implementação nesta fase.
