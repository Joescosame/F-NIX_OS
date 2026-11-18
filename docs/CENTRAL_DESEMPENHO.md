# Central de Desempenho FÊNIX — arquitetura da Fase 3

Estado: arquitetura proposta; coletor novo, interface e overlay **NÃO EXECUTADOS**. O histórico de sensores existente continua operacional, sem virar um serviço permanente. Sem wrappers ou execução oculta de overlays externos.

## Coleta independente da apresentação

Coletor sob demanda com amostras monotônicas e esquema versionado: CPU por diferenças de /proc/stat, RAM/swap por /proc/meminfo, I/O por /proc/diskstats, sensores por libsensors/hwmon, GPU por interfaces públicas DRM quando o driver as oferecer. Leituras ausentes são indisponível, nunca zero. CPU pode exceder 100% se agregada por núcleo: escolher e registrar normalização. Deltas negativos/reinício do contador devem reiniciar a série.

Histórico JSONL/CSV local com rotação e limite configurável de bytes/duração. Tempo UTC para correlação e monotônico para intervalos. Nenhum número de série, MAC ou telemetria. Interface PT-BR lê o mesmo esquema em modo texto ou gráfico. Sem coleta, timer, processo residente ou autostart quando desativada. Nenhuma leitura SMART contínua que acorde discos sem opção explícita.

[DRM fdinfo](https://docs.kernel.org/gpu/drm-usage-stats.html) permite estatísticas de clientes quando implementadas pelo driver; não fornece FPS universal. Permissões por processo e diferenças entre fabricantes precisam de adaptadores testados. [hwmon](https://docs.kernel.org/hwmon/sysfs-interface.html) tem atributos opcionais e rótulos dependentes da placa; preferir libsensors, sem inventar temperatura de CPU a partir da posição de um sensor.

## Overlay como frente separada

Primeiro protótipo: janela X11 própria, pequena, opcional e sem foco, com atualização máxima inicial de 1 Hz para métricas do sistema. Validar composição, fullscreen, escala e interferência com entrada; fallback para janela normal. Não chamar essa janela de overlay compatível com todos os jogos. Wayland requer caminho próprio e permissões do compositor; fora do primeiro protótipo.

FPS/frametime precisam de timestamps de apresentação ou fonte de telemetria real. Comparar integração voluntária de aplicativo, camada Vulkan própria e interceptação OpenGL própria em protótipos isolados. Camadas e injeção em processos introduzem riscos de estabilidade, anti-cheat, licenciamento e tempo de frame; não entram na base antes de revisão. Não injetar automaticamente em jogos. Não confundir taxa de atualização do monitor, amostras do coletor ou uso de GPU com FPS.

## Aceite proposto, ainda não medido

Em máquina de teste definida: medir 5 min ocioso e 5 min sob carga reproduzível, com/sem coleta, janela e overlay. Metas iniciais: CPU média do coletor <=1% de um núcleo em 1 Hz, RSS <=50 MiB; desativado: nenhum processo. Se exceder, investigar antes de integrar. Testar Intel/AMD/NVIDIA com driver aberto quando disponível, sem GPU, sensores ausentes e leitura negada. Para FPS, ao menos um aplicativo de referência OpenGL e um Vulkan com contagem própria e erro <=2% em intervalo de 60 s; frametime comparar série, não apenas média. Jogos não testados ficam NÃO EXECUTADOS. Preservar histórico atual e permitir rollback dos protótipos.
