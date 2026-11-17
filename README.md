# FÊNIX OS — Legacy Edition

Perfil e construtor de ISO para Linux Mint 22.3 Xfce / Ubuntu 24.04 LTS, x86_64, PT-BR. Alvo: Intel H55, i5-650 (2 núcleos/4 threads), 8 GB DDR3, Ironlake i915/Mesa, BIOS Legacy, SATA e instalação MBR.

**Versão 0.3.0-dev: ISO NÃO CONSTRUÍDA e instalação NÃO HOMOLOGADA.** Não há ISO ou Release para download. Os testes portáteis e bloqueios estão em [RESULTADOS](docs/RESULTADOS.md). Organizar o código e corrigir o callback não conclui a missão de comprovar boot → instalação → reboot → login.

## Começar

Leia [Comece aqui](docs/COMECE_AQUI.md) e [Build](docs/BUILD.md). Em VM Ubuntu 24.04 x86_64, após instalar as dependências documentadas:

```bash
./tools/lint.sh
./tools/preflight.sh
sudo -E ./tools/build-iso.sh
./tools/test-iso.sh inspect
./tools/test-iso.sh install
./tools/test-iso.sh reboot
./tools/package-release.sh
```

Não há automação de particionamento físico. O harness usa qcow2 próprio e SeaBIOS, 2 vCPUs, 4–8 GB, offline por padrão. **A instalação gráfica e sua aprovação ainda são manuais.** O comando reboot não anexa ISO. Veja [QA](docs/QA.md).

## O que está implementado

- Download oficial com SHA-256 e assinatura GPG obrigatórios; uso opcional de ISO local igualmente verificada.
- Remasterização automática com squashfs/chroot/xorriso, replay de MBR/El Torito e manifests para retenção de personalizações no sistema instalado.
- Xfce, Whisker, Plank, atalhos, aplicativos leves, zram e configurações reversíveis. Sem Snap/Flatpak, PPAs ou kernel experimental adicionado.
- Hub: inventário, histórico CSV/JSONL offline, snapshots de diagnóstico, monitor, Synaptic, Mint Update e overlays quando disponíveis.
- Proteção de resposta vazia/cancelada do GeoIP Ubiquity e entrada de instalação offline sem espera de NTP; [investigação e limites](docs/TIMEZONE.md).
- Workflows exclusivamente manuais. Nenhum foi disparado, nenhuma cobrança habilitada, nenhuma Release estável automatizada.
- Divisão em partes de até 1900 MiB, hashes por parte/final, reconstrução PowerShell 5.1 e Linux, gate para draft prerelease após QA.

Newelle/DeepSeek permanece [fase 2](docs/NEWELLE_FASE2.md), fora do build. HWall, HardInfo2, SMC, WhiteSur e Waydroid exigem homologação; a base usa fallbacks. Não se promete Vulkan na Ironlake.

## Publicação e origem

O repositório Git local está preparado em `main`. A publicação GitHub não foi possível nesta sessão: o conector não oferece criação de repositório e o navegador foi bloqueado. O destino consultado `Joescosame/FENIX-OS-Legacy` retornou 404 (ausente ou sem acesso). Não declaramos repositório remoto criado.

`tools/PUBLICAR_GITHUB.ps1`, com Git e GitHub CLI autenticado na conta correta, cria **privado**, confere visibilidade e faz push sem força. Não muda a visibilidade nem inicia Actions. Alternativamente crie o repositório privado vazio no GitHub e conceda acesso ao conector para publicação em continuação.

Fonte primária: ZIP v0.2.2; 36 arquivos conferidos contra o manifesto original. README/manifesto originais e guias numerados foram preservados. Leia [arquitetura](docs/ARQUITETURA.md), [licenças](docs/LICENCAS.md), [Windows/Rufus](docs/INSTALACAO_WINDOWS_RUFUS.md) e [histórico](CHANGELOG.md).
