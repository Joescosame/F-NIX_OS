**LEIA PRIMEIRO:** `docs/00_COMECE_AQUI.md` contém o passo a passo simplificado para montar o FÊNIX OS em uma VM Ubuntu, sem alterar o computador antigo.

# FÊNIX OS — Legacy Edition v0.2.2 (projeto de build; não é ISO pronta)

**Alvo obrigatório:** Intel H55 / LGA1156 / Core i5-650 / 8 GB DDR3 / Intel Ironlake / BIOS Legacy / HDD ou SSD SATA. Base: Linux Mint 22.3 Xfce, Ubuntu 24.04 LTS, x86_64.

Este repositório é um **perfil de remasterização e código-fonte auditável**, não um sistema com boot homologado. Foi criada uma camada de aplicações, UX e diagnóstico compatível em princípio com Mint 22.x, mas **não** foi gerada nem testada uma ISO inicializável com os arquivos deste pacote. O ISO original do Mint não acompanha este ZIP.

## Como usar
1. Leia `docs/01_PLANO_BUILD.md` e `docs/02_EXTRAS_E_LIMITES.md`.
2. Numa VM Ubuntu 24.04/Mint 22.x com Cubic, abra a ISO Mint 22.3 XFCE oficial.
3. Copie o diretório FÊNIX para `/root/fenix` no chroot Cubic e execute os scripts indicados no plano.
4. Construa ISO (x86_64, BIOS), verifique hash e tamanho, teste Live/instalação em QEMU BIOS, só depois no hardware.
5. Leia `docs/03_QA.md` e `docs/04_GUIA_POS_INSTALACAO.md`.

## Entregas
- `scripts/install-packages.sh`: pacotes dos repositórios Ubuntu Noble / Mint; observa ausência de extras.
- `scripts/stage-into-root.sh`: Hub/atalhos/ícone e autostart no filesystem da ISO.
- `scripts/configure-xfce.sh` + `first-login.sh`: layout por usuário, não em chroot.
- `scripts/configure-gestures.sh`: touchpads apenas, não mouse comum.
- `scripts/setup-waydroid.sh` e `waydroid-launcher.sh`: diagnóstico e lançador experimental, não garante Android na Ironlake.
- `scripts/cleanup-optimize.sh`: sysctl/zram, sem alterações no boot, sem remoções ocultas.
- `scripts/hub-testes.sh`: central em YAD.
- `scripts/salvar-snapshot.sh`, `historico-sensores.py`: relatório e histórico offline.
- `scripts/ativar-mangohud.sh`: toggle por usuário, aplicado após novo login.
- `scripts/install-extras-verificados.sh`: suportes externos .deb devem ser fornecidos e verificados antes.
- `scripts/verificar-perfil.sh`: verifica faltas e não homologa falsamente.

## Estado honesto por requisito
| Requisito | Entrega | Estado |
|---|---|---|
| Boot BIOS Legacy | ISO base com configuração preservada no Cubic | Precisa QEMU/PC |
| Xfce/Whisker/Plank | Script do perfil e autostart | Precisa Xfce instalado para teste |
| ZRAM/sysctl | Arquivos e scripts reversíveis | Precisa reinício e verificação |
| Hub YAD, snapshot, histórico offline | Scripts completos | Sintaxe verificada, interface sem execução real aqui |
| HardInfo2 no Mint 22.3 | Extra externo verificado ou build por fonte | **NÃO** no Ubuntu Noble oficial; fallback hardinfo |
| HWall / System Monitoring Center | Extra externo verificado | **NÃO** oficiais Noble; fallback kernel/Taskmanager |
| Waydroid/Cage | Lançador e gate de hardware | Experimental; não presumir suporte Ironlake |
| WhiteSur tema/ícones | Integração documentada | Opcional; terceiros não baixados nem incorporados |
| MangoHud/GOverlay | Pacotes se disponíveis | OpenGL 2D deve testar; Vulkan Ironlake ausente |
| ISO final <4 GB | Meta; compactação xz | Tamanho real NÃO medido |
| instalação Mint no SSD | Instalador oficial mantido | **Não corrigido** erro anterior do Ubiquity |

NENHUM script apaga partições ou seleciona automaticamente discos de instalação.

## Fase 2 opcional — Newelle (DeepSeek na nuvem)
- A ISO base permanece inalterada quanto a pacotes: **sem Newelle por padrão**.
- `scripts/install-newelle-deps.sh`: somente dependências do módulo em Mint instalado.
- `scripts/build-newelle.sh`: clone oficial + Meson/Ninja e Python isolado (sem Flatpak/Snap).
- `scripts/install-newelle.sh`: `.desktop` e botão condicional do Hub.
- `scripts/uninstall-newelle.sh`: remove integração e arquivos Meson registrados, preserva dados.
- `docs/06_NEWELLE_FASE2.md`: guia, QA e limites.
