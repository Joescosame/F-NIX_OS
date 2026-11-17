> Documento histórico v0.2.2 preservado. Para o procedimento atual, siga COMECE_AQUI.md, BUILD.md, QA.md e NEWELLE_FASE2.md. As instruções antigas não autorizam executar módulos ou publicar resultados.

# 01 — Plano de build detalhado (Cubic com chroot)

## Decisão de arquitetura
- **Cubic** como ferramenta principal para uma VM Ubuntu/Mint: extrai e recompõe a ISO base e preserva a cadeia de inicialização sem escrever `isolinux`, `grub-mkrescue` ou `El Torito` manualmente.
- **live-build** não é recomendado para modificar a ISO Mint existente: é melhor para construir distro baseada em Debian de origem, mas recriar a integração específica do Mint e Ubiquity elevaria o risco.
- **chroot manual + xorriso** seria possível e mais automatizável, porém refazer corretamente o boot híbrido Legacy/UEFI aumenta a chance de gerar uma imagem não inicializável. Usar Cubic primeiro, documentando/automatizando alterações no chroot por scripts.
- O Cubic é um PPA de terceiro que executa tarefas privilegiadas; use em **VM descartável**; veja alerta de segurança no guia oficial.
- A ISO será x86_64 e deve inicializar por Legacy BIOS. Não pressupor UEFI.

## 0. Preparar o ambiente de build
Preferir VM Ubuntu 24.04 com pelo menos 4 vCPU, 8 GB RAM e 50 GB livres em disco. Montar unidade compartilhada com:
- `linuxmint-22.3-xfce-64bit.iso` original, verificada contra SHA-256 e assinatura GPG da lista oficial;
- este diretório `FENIX_OS_Legacy_v0_2`.

Instalar Cubic no **sistema de build** (este passo adiciona apenas o PPA de Cubic ao host/VM, nunca à ISO-alvo):
```bash
sudo add-apt-repository universe
sudo add-apt-repository ppa:cubic-wizard/release
sudo apt update
sudo apt install --no-install-recommends cubic
```
Fonte oficial: https://github.com/PJ-Singh-001/Cubic

## 1. Personalizar com Cubic
1. Execute `cubic` na VM; crie projeto vazio `~/Cubic-Fenix`.
2. Selecione a ISO oficial do Mint 22.3 Xfce.
3. No terminal de chroot mostrado pelo Cubic, coloque os arquivos deste projeto em `/root/fenix` (use a função de cópia de arquivos para o terminal/ambiente do Cubic).
4. Execute **um comando por vez**:
```bash
bash /root/fenix/scripts/install-packages.sh
bash /root/fenix/scripts/cleanup-optimize.sh apply
bash /root/fenix/scripts/stage-into-root.sh
```
5. Opcional: acrescente `.deb` auditados do HardInfo2/HWall/SMC em `/root/fenix/externals/` e SHA256SUMS.txt. **Somente depois** execute `bash /root/fenix/scripts/install-extras-verificados.sh`. Nunca baixe `.deb` aleatórios sem verificar origem, licença, dependências e integridade.
6. Examine `bash /root/fenix/scripts/verificar-perfil.sh`: faltas são reportadas, não ocultadas.
7. Se decidir remover apps grandes, leia `docs/05_PACOTES.md`: executar apenas a **simulação**, revisando que nenhum pacote-base (XFCE, kernel, mint-meta, ubiquity, casper, lightdm) seria removido. A remoção é decisão explícita e não ocorre por padrão.
8. Remova apenas caches de pacotes *sem* alterar o sistema apt: `apt-get clean`. Não use autoremove cegamente.
9. Siga as telas de kernel/ISO do Cubic, deixando o kernel LTS padrão da base; recompressão squashfs em **xz**; preserve a entrada original Legacy BIOS no boot ISO.
10. Gere `fenix-os-legacy-0.2-amd64.iso`.

## 2. Inspeção da ISO e tamanho
No host da VM de build:
```bash
sha256sum fenix-os-legacy-0.2-amd64.iso > fenix-os-legacy-0.2-amd64.iso.sha256
stat -c '%n: %s bytes' fenix-os-legacy-0.2-amd64.iso
xorriso -indev fenix-os-legacy-0.2-amd64.iso -report_el_torito plain
```
Deve haver entrada de boot **BIOS** (El Torito) para o PC H55. Meta <4 GiB; máximo do pendrive 8 GB (< capacidade real). Caso exceda 4 GiB, reduza extras e recompima; não prometer tamanho até medir.

## 3. Testar em QEMU com SeaBIOS (não OVMF)
```bash
sudo apt install qemu-system-x86 qemu-utils
qemu-img create -f qcow2 fenix-qa.qcow2 32G
qemu-system-x86_64 -m 4096 -smp 2 -machine pc -boot d \
 -cdrom fenix-os-legacy-0.2-amd64.iso \
 -drive file=fenix-qa.qcow2,format=qcow2,if=ide -vga std
```
A VM deve entrar na tela de Live Mint. Execute instalador em disco virtual QEMU, reinicie **sem a ISO** e confirme que o GRUB foi instalado em modo BIOS. Se quiser acelerar com KVM, adicione `-enable-kvm` apenas se host tiver suporte KVM.

## 4. Testar em VirtualBox (alternativa)
Criar VM Linux/Ubuntu 64 bits, 4 GB RAM, HDD virtual >=32 GB. Em `Settings > System > Motherboard`, desmarcar `Enable EFI`. Anexar ISO ao drive ótico, iniciar e instalar no disco virtual, depois retirar ISO e validar boot. Não teste apagamento em disco físico nesta fase.

## 5. Homologação em H55
- Primeiro testar modo Live por pendrive sem formatar nada.
- Registrar `uname -r`, `lspci -k`, `lsusb`, `glxinfo -B`, áudio, Wi-Fi 2.4 GHz e funcionamento de hub offline.
- Confirmar SSD SATA ou HD pelo tamanho **e modelo**, não apenas `/dev/sda`, que pode variar.
- Só depois escolher formatação, com confirmação manual do disco. Não automatizar particionamento nesse projeto.
- **A falha anterior do Ubiquity no timezone não está resolvida** por este remaster. Faça QA específico em VM e no hardware, não assuma que instalará por funcionar em Live.

## 6. Versões e documentação
Manter em um manifesto o hash SHA-256 da ISO fonte, hash de todo `.deb` externo, lista `dpkg-query -W`, versão do Cubic, kernel, xorriso e hash da ISO gerada. Não atualizar kernel ou firmware de forma experimental no build.
