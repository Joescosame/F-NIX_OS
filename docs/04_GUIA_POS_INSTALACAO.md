# 04 — Guia rápido pós-instalação FÊNIX OS (PT-BR)

O FÊNIX foi pensado para funcionar sem decorar comandos. O Linux Mint Xfce continua o sistema real; o Hub reúne as ferramentas de testes num único lugar. O Hub aparece no menu com o nome **Hub de Testes FÊNIX**, e pode ser fixado no Plank.

## Primeira inicialização
1. Faça login no Linux instalado (não no Live USB). A configuração do FÊNIX roda uma vez por usuário.
2. Para aplicar Plank e o atalho Super isolado, encerre a sessão e entre novamente.
3. Abra o Menu Whisker (Ctrl+Esc; Super sozinho se `xcape` estiver funcionando). Busque `Hub de Testes`.
4. Conecte ao Wi-Fi 2.4 GHz com o ícone de rede, selecione SSID e senha. Adaptador MT7601U não suporta 5 GHz.
5. Abra **Gerenciador de Atualizações** depois que a rede funcionar.

## Atalhos
| Tecla | Ação |
|---|---|
| Super+← / Super+→ | Encaixar janela à esquerda/direita |
| Super+↑ | Maximizar janela |
| Super+↓ | Restaurar maximização com `wmctrl` |
| Ctrl+Esc | Whisker Menu (sempre que configurado) |
| Super (toque isolado) | Whisker Menu se `xcape` disponível |
| Super+E | Arquivos Thunar |
| Super+R | Executar/pesquisar aplicações |
| Super+I | Configurações Xfce |
| Super+T | Terminal |
| Ctrl+Shift+Esc | Gerenciador de tarefas |
| Alt+Tab / Alt+F4 | Alternar / fechar janelas |

## Gestos
3 dedos esquerda/direita trocam a área de trabalho; 3 dedos para cima abrem menu de janelas (não Exposé). Dependem de touchpad físico, libinput-gestures e permissões; não há gestos de quatro dedos prontos na edição legada por falta de um compositor/visão geral nativos adequados. Se o equipamento não possui touchpad, 'N/A'.

## O Hub de Testes (um ícone)
- **Inventário e Benchmark:** HardInfo2 se instalado; caso contrário, hardinfo/CPU-X. Para exportar HTML, no terminal com HardInfo2: `hardinfo2 -r -f html > ~/TestesPC/benchmarks/meu-pc.html`.
- **Histórico de Sensores:** abre HWall se instalado. Caso contrário, coletor leve por 2 min; gera CSV+JSONL em `~/TestesPC/historico` sem conexão.
- **Salvar Snapshot do PC:** salva CPU, RAM, dispositivos, sensores, informações gráficas, relatórios opcionais e hashes num diretório novo.
- **Monitoramento em Tempo Real:** System Monitoring Center se instalado, caso contrário XFCE Task Manager.
- **Configurar Overlay de Jogos:** abre GOverlay se disponível.
- **Ativar Overlay Globalmente:** salva `MANGOHUD=1` no arquivo do usuário; requer logout/login; pode não aparecer em OpenGL legado.
- **Desativar MangoHud:** remove variável do usuário; logout/login.
- **Central de Programas:** Synaptic.
- **Atualizações do Sistema:** mintupdate.
- **Aplicativos Android:** recurso experimental; explica erros se Waydroid/Cage/Binder não estiverem disponíveis.

## Integração com Android por KDE Connect
Abra **KDE Connect** no Menu Whisker e o aplicativo KDE Connect no telefone. Os dois devem estar na mesma rede local. Autorize emparelhamento e escolha recursos de notificações, transferência de arquivos e SMS conforme suporte do Android e permissões concedidas. Não é preciso deixar o KDE Connect aberto se não for usar.

## MangoHud
- Steam: em cada jogo compatível, Opções de inicialização = `mangohud %command%`.
- Outros jogos OpenGL: testar `mangohud --dlsym comando-do-jogo` (ou `mangohud comando-do-jogo`, conforme programa). Não habilitar globalmente se piorar o desempenho.
- Ironlake não tem Vulkan nativo. Não esperar games Proton/Vulkan contemporâneos.
- Logs locais de jogos em `~/TestesPC/logs/` se explicitamente habilitados; nenhum log automático de partidas por padrão.

## Compositor
Menu > Configurações > Ajustes do Gerenciador de Janelas > Compositor. Ativar se a imagem ficar fluida; desativar se ocorrerem travamentos. O perfil antigo mantém compositor desligado por padrão.

## Aplicativos Android / Waydroid
A entrada de menu é experimental. Waydroid precisa Wayland (Cage aninhado), binder e aceleração apropriada. **Pode não funcionar na Ironlake**; o menu exibe uma explicação. Não instale libhoudini ou imagens ARM de procedência desconhecida. Consulte o guia Waydroid antes de testes avançados.

## Dados de teste
```text
~/TestesPC/
├── benchmarks/   (relatórios HardInfo2/alternativas)
├── historico/    (CSV e JSONL dos sensores)
├── snapshots/    (um diretório novo por coleta)
└── logs/         (erros e logs opcionais)
```
Comparar duas capturas: salvar snapshots em datas diferentes, abrir seus arquivos `cpu.txt`, `memoria.txt`, `sensores.txt`, `grafico.txt`, `discos.txt` lado a lado. Não publicar serial/MAC/identificadores sem revisar.

## Como reverter ajustes
- **MangoHud:** `ativar-mangohud off`; fazer logout/login.
- **Zram e sysctl:** `sudo bash cleanup-optimize.sh revert` (script no pacote de fontes); reiniciar.
- **Atalhos/Xfce:** a rotina salva backup em `~/.local/share/fenix/backups/<data>/xfconf-original`. Encerre a sessão, copie de volta para `~/.config/xfce4/xfconf` e inicie novamente; também pode editar atalhos por Configurações > Teclado.
- **Plank:** Configurações > Sessão e Inicialização > Inicialização automática; desmarque `Plank Dock FÊNIX`. Alternativamente remova `~/.config/autostart/fenix-plank.desktop`.
- **Super isolado:** remova `~/.config/autostart/fenix-super.desktop` e faça logout/login.
- **Compositor:** volte à configuração do Xfce; nenhum arquivo Xorg alterado por padrão.
- **Tema WhiteSur opcional:** voltar ao tema Mint por Configurações > Aparência e Gerenciador de Janelas; desinstalar tema somente depois.
- **Ações Thunar:** editor em Editar > Configurar ações personalizadas ou restaure backup `uca.xml`.
- **Gestos:** `libinput-gestures-setup stop` e remova autostart; mantém configuração em `~/.config/libinput-gestures.conf`.
- **Waydroid:** não instalado automaticamente. Não precisa reverter se apenas visualizar o atalho.

## Diagnóstico sem internet
Abra Hub > Salvar Snapshot; os dados ficam locais. Para mostrar erro, envie somente os arquivos necessários, retirando números de série, UUIDs e endereços de rede.

## Assistente IA (Newelle) — módulo opcional da fase 2

Não acompanha a ISO principal. Só habilite após o boot BIOS/instalador base ser homologado.
O Newelle usa GTK4/libadwaita e se conecta à API da DeepSeek na nuvem; nenhum modelo local será instalado.
Na pasta de fontes do FÊNIX, em uma instalação Mint 22.x **já concluída**, execute:

```bash
bash scripts/build-newelle.sh
bash scripts/install-newelle.sh
```

O build instala dependências do repositório Ubuntu 24.04, clona o Newelle e compila com Meson/Ninja.
Não usa `install.sh` upstream porque atualmente chama `flatpak-builder`; não usa `pip install .`.
Logs de construção: `~/TestesPC/logs/build-newelle.log` (não insira sua chave da DeepSeek em comandos/logs).

**Chave da DeepSeek:** crie-a no painel da DeepSeek (https://platform.deepseek.com/api_keys).
Abra o Newelle pelo menu **Assistente IA (Newelle)**, entre em Configurações/Models, escolha
**DeepSeek**, cole a chave no campo **API Key** e selecione um modelo atual, por exemplo `deepseek-flash`,
conforme o painel da API. O endpoint padrão é `https://api.deepseek.com`.
A chave é configurada manualmente; não é embutida na ISO ou em scripts. A API pode ter custos.

Por segurança, comece com execução automática de comandos DESATIVADA e leitura de arquivos
limitada às pastas que você autorizar. Chamadas enviadas ao modelo na nuvem podem incluir
conteúdo da conversa e de arquivos selecionados. O Newelle não substitui o Hub de Testes.

**Limitações:** o projeto Newelle alerta que builds sem Flatpak podem apresentar bugs.
A versão recente usa componentes GNOME/GTK4 e pode ser pesada ou incompatível com versões
do Ubuntu 24.04. Em caso de dependência indisponível, não force PPAs ou kernels novos.

**Reversão:** `bash scripts/uninstall-newelle.sh`. Remove o atalho e arquivos instalados
registrados pelo Meson; preserva chats, chaves, venv e dependências apt para revisão.
Consulte `~/.local/state/fenix-newelle/packages-added.txt` antes de remover pacotes.
