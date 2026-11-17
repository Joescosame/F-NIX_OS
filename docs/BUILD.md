# Construir em Ubuntu 24.04

## Preparar uma VM descartável

Use Ubuntu 24.04 x86_64, mínimo 4 GB RAM (8 GB recomendado), 35 GiB livres no filesystem do checkout (50 GiB recomendado). Reserve mais espaço para disco qcow2 e partes da Release; o pico aumenta se reter múltiplas árvores. No host local não se removem ferramentas automaticamente.

```bash
sudo apt-get update
sudo apt-get install -y git xorriso squashfs-tools gnupg curl rsync shellcheck desktop-file-utils python3-yaml qemu-system-x86 qemu-utils seabios
./tools/lint.sh
./tools/preflight.sh
sudo -E ./tools/build-iso.sh
./tools/test-iso.sh inspect
./tools/test-iso.sh install
./tools/test-iso.sh reboot
./tools/package-release.sh
```

Execute na pasta do repositório. Permissões executáveis são versionadas. Se copiar de ZIP no Windows, primeiro rode `chmod +x tools/*.sh scripts/*.sh` no Linux. Dependências do host não entram na ISO. `preflight` só verifica; não instala nem aumenta recursos automaticamente.

Para aproveitar a ISO original já baixada, copie-a para uma pasta Linux e informe caminho absoluto:

```bash
sudo FENIX_BASE_ISO=/home/SEU_USUARIO/Downloads/linuxmint-22.3-xfce-64bit.iso ./tools/build-iso.sh
```

Ela também passa por assinatura GPG e SHA-256. Não há opção de ignorar verificação. Erro de chave/rede/assinatura bloqueia o build. Se o fingerprint oficial mudar, revisar documentação oficial e a alteração; não trocar a chave automaticamente.

Saídas: `dist/FENIX-OS-Legacy-amd64.iso`, `dist/SHA256SUMS`, versões, lista de pacotes e inspeções de boot. Logs completos e árvores ficam em `work/build.*`, ignorados pelo Git. Nenhuma saída existente é sobrescrita. Preserve evidências antes de limpar manualmente a VM.

O build retém o kernel/initrd oficiais e reproduz MBR híbrido e El Torito da mídia original. Inspeção compara plataformas e atributos; só o boot da própria ISO e do USB comprovam funcionamento. O limite conservador é 7,8 bilhões de bytes; meta abaixo de 4 bilhões. O tamanho real desta versão permanece **NÃO MEDIDO**.

## GitHub Actions

No [Actions do repositório oficial](https://github.com/Joescosame/F-NIX_OS/actions) escolha **Validar fontes** ou **Construir ISO não homologada**, depois Run workflow na `main`. Todos os gatilhos são `workflow_dispatch`; nenhuma compilação é iniciada por commit ou PR. Para construir, mantenha `runner=ubuntu-24.04`, marque `confirmar_recursos` e deixe `guardar_artefato=false` até verificar a franquia gratuita de armazenamento. Não executamos nenhum workflow nesta sessão.

Os runners **padrão** são gratuitos em repositórios públicos; runners maiores são pagos e não são opções deste projeto. Armazenamento de artefatos tem franquia separada. Nenhuma configuração de cobrança ou orçamento é alterada. Fontes: [runners oficiais](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), [cobrança e armazenamento](https://docs.github.com/en/billing/concepts/product-billing/github-actions).

O runner padrão pode ter menos de 35 GiB livres. `otimizar_disco=true` permite remover apenas SDKs Android, .NET, GHC e CodeQL da VM efêmera GitHub-hosted antes do preflight. O script recusa outro ambiente, inclusive runner próprio. Essa limpeza não garante espaço suficiente; se ainda faltar, o job para e registra a limitação. Aumentar o tempo limite não resolve falta de disco. Para runner próprio já existente: VM dedicada Ubuntu 24.04 x64 com os rótulos `self-hosted`, `Linux`, `X64`, `fenix-noble`. Não use um host com dados pessoais para executar builds root. O projeto não contrata nem cria esse runner.

O job faz validação, build e inspeção estrutural, registra hashes e resultado no log/resumo. Sem `guardar_artefato`, a ISO fica somente na VM efêmera e não estará disponível após o job. Com a opção explicitamente habilitada, o candidato é guardado por um dia; o projeto não presume franquia de armazenamento disponível. Não homologa instalação gráfica, não publica Release e não marca a ISO estável. A interface QEMU exige host Linux com sessão gráfica; execute os comandos de QA localmente. Sem KVM usa TCG, que é mais lento.

## Cubic como alternativa

Os guias numerados registram o fluxo antigo. Para experimentar com Cubic, use uma VM descartável e aplique as mesmas alterações; `install-packages.sh` agora exige `FENIX_BUILD=1` no chroot. A imagem feita por Cubic é outro candidato e precisa de todos os testes. O processo suportado e registrável é o construtor automático.
