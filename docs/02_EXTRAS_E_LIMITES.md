> Documento histórico v0.2.2 preservado. Para o procedimento atual, siga COMECE_AQUI.md, BUILD.md, QA.md e NEWELLE_FASE2.md. As instruções antigas não autorizam executar módulos ou publicar resultados.

# 02 — Componentes opcionais e limitações físicas

## HardInfo2
O repositório Ubuntu 24.04 `noble` oferece o **hardinfo** legado, não `hardinfo2`. O pacote `hardinfo2` aparece oficialmente no Ubuntu 26.04 e posteriores, portanto **NÃO** executar `apt install hardinfo2` como se existisse no Noble.
- O Hub funciona offline com `hardinfo`; o snapshot também extrai `lshw`, `lscpu`, `lsusb`, `lsblk`, `sensors`.
- Para entregar HardInfo2, criar um pacote `.deb` testado contra Noble a partir de fontes oficiais https://github.com/hardinfo2/hardinfo2 ou selecionar o pacote fornecido pelo projeto em https://hardinfo2.org/download/ depois de verificar arquitetura, dependências e hash. Em VM descartável; copiar para `externals/` e gerar `sha256sum arquivo.deb >> SHA256SUMS.txt`.
- Relatório: `hardinfo2 -r -f html > ~/TestesPC/benchmarks/relatorio.html`; conexão online opcional e nunca automática.

## HWall
https://github.com/pulpul-s/HWall — projeto open-source recente de sensores em GTK4/Rust com histórico, gráficos e CSV/JSONL. Não é pacote oficial Ubuntu Noble. Compilar/pacotar em VM ou obter `.deb` oficial adequado à arquitetura e auditar antes de usar; o Hub abre `hwall` quando presente. Para **histórico offline garantido no build mínimo**, `historico-sensores.py` cria CSV+JSONL locais, sem ambiente GTK4 extra.

## System Monitoring Center
https://github.com/hakandundar34coding/system-monitoring-center/releases — há `.deb` upstream, mas não incluído nos repositórios Noble por padrão. Auditar SHA256/dependências; o Hub usa `xfce4-taskmanager` como fallback, não mostra métricas impossíveis pela Ironlake.

## WhiteSur
Temas GTK, ícones e Plank: fornecedores distintos, verificar licenças e versões. GTK: https://github.com/vinceliuice/WhiteSur-gtk-theme . Há relato de falha da rotina de instalação em Mint 22.3/XFCE; **não** executar `curl ... | bash` no build. Baixar código-fonte em VM, revisar o instalador, testar e distribuir apenas os arquivos de tema resultantes em `externals/WhiteSur/` com licença. O script da instalação não assume que WhiteSur existe. Usar tema simples do Mint até aprovar.

## Gestos touchpad
`libinput-gestures` não é pressuposto como pacote do Noble. Driver libinput do X11 e dispositivo multitouch são necessários. O PC H55 de mesa normalmente usa mouse, logo gestos **não funcionam** sem touchpad real. O script fornece o arquivo de configuração, mas só ativa se o binário e o touchpad existirem. 3 dedos para cima chamam o menu de janelas como *aproximação*, não Exposé.

## Waydroid Android
Waydroid exige binder, uma sessão Wayland (por exemplo Cage aninhado) e drivers gráficos adequados. A Ironlake é pré-Vulkan, em geral limitada a OpenGL 2.1. **Não prometer que apps Android 2D rodarão.** Software rendering pode ser lento; até o arranque pode falhar. Por segurança o instalador não adiciona repositório Waydroid nem baixa imagens Android automaticamente. O menu tem um lançador que explica o bloqueio. Consulte https://docs.waydro.id/usage/install-on-desktops para procedimento opcional após testar kernel e GPU; `libhoudini` não é instalado pelo pacote e tem implicações de licença e confiança.

## MangoHud/GOverlay
`mangohud` pertence ao Ubuntu Noble, mas o suporte útil depende da API gráfica do jogo. GPU Ironlake não possui Vulkan nativo; muitos jogos Steam/Proton não iniciam. Para OpenGL, tentar `mangohud --dlsym COMANDO` ou `mangohud COMANDO` conforme binário, sem garantia; `MANGOHUD=1` sozinho não injeta overlay em todos os aplicativos. Global 'on' só terá efeito após novo login; switch reversível. O pacote tenta `goverlay` apenas se existir no repositório.

## Driver i915, Intel Xorg e ajustes avançados
Kernel padrão do Mint + Mesa dos repositórios. `i915` no kernel e Mesa são as bases de vídeo, mas resultado depende da aceleração disponível. **Não configurar** `intel_iommu=igfx_off` ou `AccelMethod` por padrão. Arquivo `assets/20-intel.conf.example` é exemplo, `uxa` para teste controlado, `sna` pode não ser suportado/estável. Para experimentar, copie o arquivo para `/etc/X11/xorg.conf.d/20-intel.conf` SOMENTE com acesso TTY/resgate; remova se tela preta. Para kernel arg, editar GRUB manualmente em VM/teste, validar, documentar e reverter.

## Serviços e codecs
Bluetooth/Avahi/CUPS não são desativados por padrão. Leitores de tela e fontes não latinas não são removidos automaticamente para preservar acessibilidade e documentação em idiomas diferentes. Preferir segurança e estabilidade à economia mínima de RAM/disco.
