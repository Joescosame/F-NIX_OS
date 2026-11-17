# Construir em Ubuntu 24.04

## Preparar uma VM descartável

Use Ubuntu 24.04 x86_64, mínimo 4 GB RAM (8 GB recomendado), 35 GiB livres no filesystem do checkout (50 GiB recomendado). Reserve mais espaço para disco qcow2 e partes da Release; o pico aumenta se reter múltiplas árvores. O script não libera espaço removendo ferramentas do runner.

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

Em Actions escolha **Validar fontes** ou **Construir ISO não homologada**, depois Run workflow. Todos os gatilhos são `workflow_dispatch`. Confira a franquia e o orçamento da conta antes de executar. Este projeto não contrata runner, não habilita cobrança e não muda visibilidade. Não executamos nenhum workflow nesta sessão.

O runner padrão pode ter menos de 35 GiB livres. Nesse caso o job falha cedo, sem afirmar que há espaço suficiente. Aumentar o tempo limite não resolve falta de disco. Para runner próprio: VM dedicada Ubuntu 24.04 x64 com os rótulos `self-hosted`, `Linux`, `X64`, `fenix-noble`; selecione `self-hosted` no formulário. Não use um host com dados pessoais para executar builds root. O runner próprio também pode gerar custo no provedor escolhido; o projeto não o cria.

O job faz validação e inspeção estrutural e guarda candidato por três dias. Não homologa instalação gráfica, não publica Release e não marca a ISO estável. A interface QEMU exige host Linux com sessão gráfica; execute os comandos de QA localmente. Sem KVM usa TCG, que é mais lento.

## Cubic como alternativa

Os guias numerados registram o fluxo antigo. Para experimentar com Cubic, use uma VM descartável e aplique as mesmas alterações; `install-packages.sh` agora exige `FENIX_BUILD=1` no chroot. A imagem feita por Cubic é outro candidato e precisa de todos os testes. O processo suportado e registrável é o construtor automático.
