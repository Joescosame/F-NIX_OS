> Documento histórico v0.2.2 preservado. Para o procedimento atual, siga COMECE_AQUI.md, BUILD.md, QA.md e NEWELLE_FASE2.md. As instruções antigas não autorizam executar módulos ou publicar resultados.

# 05 — Pacotes a instalar/remover (Mint 22.3 / Ubuntu Noble)

## Princípio
`install-packages.sh` verifica cada candidato em `apt-cache` e só instala o que existir. Um comando que falhe não deve ser silenciosamente classificado como atendido; conferir `/var/log/fenix-install-packages.log`. Não faz remoção automática nem habilita Snap/Flatpak.

## Base, integração e firmware
```bash
sudo apt-get update
sudo apt-get install --no-install-recommends \
  xfce4-whiskermenu-plugin xfce4-notifyd xfce4-taskmanager xfce4-screenshooter \
  thunar-archive-plugin thunar-volman gvfs-backends mousepad xarchiver \
  file-roller p7zip-full unzip network-manager linux-firmware \
  mesa-utils mesa-vulkan-drivers xserver-xorg-video-intel \
  wmctrl xdotool xcape python3 python3-gi python3-tk \
  systemd-zram-generator
```
Nota: `xfce4-notifyd-plugin` é tentado apenas se existente no repo. **i915 é módulo do kernel**, não pacote separado para instalar manualmente.

## Leves e multimídia
```bash
sudo apt-get install --no-install-recommends \
  abiword gnumeric firefox claws-mail mpv audacious pinta \
  plank atril ristretto kdeconnect
```
A disponibilidade concreta de `pinta` depende dos repositórios ativos; instalar script com fallback, não puxar Snap. Usar apps do Mint se faltar um substituto. Firefox mantém como navegador padrão, sem modificar extensões de fábrica às cegas.

## Hub, sensores e ferramentas
```bash
sudo apt-get install --no-install-recommends \
  yad zenity synaptic hardinfo cpu-x xfce4-taskmanager \
  lm-sensors smartmontools lshw pciutils usbutils inxi \
  htop iotop sysstat lsof dmidecode nvme-cli \
  mangohud goverlay glmark2
```
**Os pacotes `hardinfo2`, `hwall`, `system-monitoring-center` não são oferecidos como pacotes oficiais Noble.** Para esses três, incorporar `.deb` auditado ou compilar/empacotar a partir dos projetos oficiais e testar dependências em VM; consulte `02_EXTRAS_E_LIMITES.md` e o `install-extras-verificados.sh`. Não disfarçar `hardinfo` como `hardinfo2`.

## Gestos e Android — módulos opcionais
```bash
sudo apt-get install --no-install-recommends libinput-tools xinput xdotool wmctrl cage
```
`libinput-gestures` requer instalação externa revisada. `waydroid` exige repositório oficial próprio, Binder e GPU; não automatizado para Ironlake. `libhoudini` não incluído.

## Remoções opcionais (somente após simulação)
```bash
sudo apt-get -s purge libreoffice-core libreoffice-writer libreoffice-calc \
  libreoffice-impress thunderbird gimp rhythmbox celluloid
```
**Se a simulação não remover Xfce, Mint meta, Ubiquity, kernel ou GRUB**, o mantenedor pode avaliar:
```bash
sudo apt-get purge libreoffice-core libreoffice-writer libreoffice-calc \
  libreoffice-impress thunderbird gimp rhythmbox celluloid
```
Não executar `autoremove` automaticamente; não usar glob indiscriminado `libreoffice*` sem conhecer impactos. Remover snaps/flatpaks somente se já presentes e identificados, em uma fase de build específica e com auditoria de dependências — não são instalados por este projeto.

## Pacotes que não devem ser removidos por economia mínima
`mint-meta-xfce`, `xfce4-session`, `xfce4-panel`, `ubiquity`, `casper`, `linux-image-*`, `lightdm`, `network-manager`, `linux-firmware`, `grub-pc` (destino BIOS). Não remover ajuda de acessibilidade ou fontes essenciais sem testes em português e outros idiomas.
