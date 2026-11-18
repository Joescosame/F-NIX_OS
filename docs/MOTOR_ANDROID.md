# Motor Android FÊNIX — estudo inicial

Pesquisa documental, sem compilação AOSP nem execução Android nesta fase. Nenhuma medição de consumo foi feita; números abaixo são limites propostos de ensaio. O motor terá gerenciamento e interface próprios em português e não dependerá do desktop Xfce para seu ciclo de vida. Não fará parte da ISO principal antes dos testes.

| Alternativa | Base técnica | Isolamento e custo provável | Decisão preliminar |
| --- | --- | --- | --- |
| Contêiner próprio | AOSP, namespaces, cgroups, binderfs, ponte gráfica própria | Compartilha kernel; integração HAL/gráfica complexa; menor overhead potencial, não medido | Pesquisa secundária: não escolher só por promessa de leveza |
| VM gerenciada pelo FÊNIX | AOSP x86_64, QEMU/KVM ou VMM aberto revisado | Kernel convidado separado; RAM reservada e virtualização disponíveis condicionam uso | Preferida para primeiro protótipo isolado e reversível |
| Cuttlefish como referência de laboratório | Plataforma virtual oficial AOSP | Host Linux com virtualização/KVM e componentes próprios | Referência para comparar boot/framework; não renomear produto de terceiros como motor completo próprio |
| AVF/Microdroid | Framework de virtualização Android | AVF documentado para ARM64; Microdroid é subconjunto, não desktop Android completo | Não atende diretamente ao host Mint x86_64 deste protótipo |

Essa escolha é uma inferência de engenharia para reduzir acoplamento ao kernel host, não um benchmark. [Cuttlefish](https://source.android.com/docs/devices/cuttlefish) suporta ambientes Linux x86/ARM64; seu [procedimento oficial](https://source.android.com/docs/devices/cuttlefish/get-started) exige verificar virtualização/KVM e parear imagem e host package do mesmo build. Não presumir KVM no runner público ou em firmware antigo.

## Requisitos a investigar

- Binder: em contêiner, verificar configuração do kernel e instância privada binderfs. [binderfs](https://docs.kernel.org/admin-guide/binderfs.html) oferece dispositivos privados por instância; isso não isola todo o kernel. Em VM, Binder fica inicialmente no convidado. Não adicionar módulo/kernel experimental à base para satisfazer protótipo.
- Gráficos: manter SurfaceFlinger/HWC e backend EGL/OpenGL ES/Vulkan compatíveis com a imagem. [SurfaceFlinger](https://source.android.com/docs/core/graphics/surfaceflinger-windowmanager) compõe buffers Android; não basta abrir uma janela Linux. Ensaiar renderização por software e virtual GPU separadamente, sem afirmar aceleração universal. GPU antiga sem Vulkan pode exigir software lento.
- ISA: AOSP x86_64 e APK Java/Kotlin não garantem suporte a bibliotecas nativas ARM. Aplicativos ARM exigem tradução de instruções/ABI adicional e licença revisada; fora do primeiro protótipo. Não redistribuir tradutores proprietários, serviços Google, Play Store ou imagens com licença indefinida.
- Isolamento: sem pastas host, USB, câmera, microfone, clipboard ou rede por padrão; acesso opt-in específico. ADB restrito a socket/local, sem porta pública. Usuário host sem privilégios; serviço privilegiado mínimo apenas se demonstrado necessário, com revisão. Sistema convidado somente leitura e dados em arquivo descartável próprio. Nunca dispositivo físico.
- Atualizações: imagem e ferramentas fixadas por hash/versão, inventário de componentes/licenças, fontes e avisos disponíveis. A [licença AOSP](https://source.android.com/license) é predominantemente Apache 2.0, com exceções; kernel e outros componentes exigem análise por arquivo/pacote, incluindo GPL e oferta de fontes. Componentes FÊNIX não anulam licenças de terceiros.
- AVF não é atalho para este host: [documentação AVF](https://source.android.com/docs/core/virtualization) limita suporte a ARM64; [Microdroid](https://source.android.com/docs/core/virtualization/microdroid) expõe subconjunto de APIs.

## Critérios objetivos do protótipo da Fase 4

Pré-requisitos: VM Linux dedicada, KVM verificado e recursos disponíveis sem contratar máquina. Primeira imagem x86_64 oficial/fixada, uma Activity aberta de teste com código e licença conhecidos. Launcher FÊNIX deve iniciar/parar a VM e apresentar erro em português, sem iniciar junto do desktop. Sem apps ARM ou loja nesta primeira rodada.

Registrar três partidas frias: tempo até boot_completed e Activity visível, CPU/RSS/PSS do host e memória do convidado, tempo de parada, hashes e logs revisados. Proposta de orçamento inicial: convidado 2 vCPUs/2 GiB, boot <=120 s com KVM, parar <=15 s, host sem processo residual ao desativar. São critérios de seleção, NÃO resultados. TCG/software será uma campanha distinta com teto de 5 min; reprovar viabilidade de uso interativo se não cumprir orçamento, sem generalizar a todo hardware.

Testar negação real de acesso a arquivo sentinela do host, dispositivos e rede; repetir ciclos iniciar/parar, snapshot/rollback do disco de dados e verificar ausência de escrita no sistema host. Uma falha de isolamento bloqueia qualquer integração. Comparar app de referência com GPU virtual e software; medir latência/renderização e recursos antes de decidir. Não compilar Android completo enquanto faltarem espaço, imagem licenciada, baseline e hipótese de ensaio.
