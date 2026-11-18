> HISTÓRICO v0.2.2: não executar estas instruções. Consulte ../../../README.md e os ADRs atuais. Integrações antigas foram canceladas.

# FÊNIX OS — Comece aqui (versão simples)

## Resposta curta
Você **não precisa enviar a ISO ao ChatGPT** nem abrir o arquivo `.iso` e mover programas para dentro dele. Uma ISO é uma imagem de inicialização, não uma pasta comum. O Cubic extrai e reconstrói a imagem.

**Arquivos necessários (na VM de montagem):**
1. ISO oficial `linuxmint-22.3-xfce-64bit.iso` (Xfce de 64 bits), baixada e verificada.
2. Arquivos do projeto `FENIX_OS_Legacy_v0_2_2` (esta pasta), extraídos do ZIP.
3. Uma máquina virtual com Ubuntu 24.04 LTS, conexão com internet e Cubic instalado.

**Onde montar:** use um computador relativamente moderno (Windows com VirtualBox, por exemplo). NÃO é necessário voltar a iniciar o PC antigo até termos uma ISO testada.

## Passos no computador de montagem (Windows)
1. Baixe o VirtualBox para Windows em https://www.virtualbox.org/wiki/Downloads e instale.
2. Baixe uma ISO do **Ubuntu 24.04 LTS Desktop** em https://ubuntu.com/download/desktop (não confundir com o Linux Mint de destino).
3. No VirtualBox clique em **New/Novo**. Nome: `Oficina-FENIX`. Tipo Linux/Ubuntu 64-bit. Se pedir instalação automática, escolha a opção de **ignorar instalação desassistida** para instalar manualmente.
4. Atribua à VM aproximadamente 4 vCPUs, 6–8 GB de RAM se seu PC tiver 16 GB ou mais, e 60 GB de disco virtual dinâmico. Se o computador de montagem tiver 8 GB no total, não siga esses valores sem reavaliar.
5. Configure a ISO Ubuntu 24.04 no drive ótico virtual. Inicie a VM e faça a instalação normal do Ubuntu **no disco virtual da VM**, não no HD físico do Windows.
6. Após iniciar o Ubuntu, abra o navegador **dentro da VM**, baixe o ISO Linux Mint 22.3 Xfce e o ZIP do FÊNIX no ChatGPT. Isso evita configurar pastas compartilhadas; se já tiver os arquivos no Windows, uma pasta compartilhada do VirtualBox também serve.
7. Extraia o ZIP; a pasta terá o nome `FENIX_OS_Legacy_v0_2_2`.

## Passos no Ubuntu da VM
1. Abra o **Terminal** com `Ctrl+Alt+T` e cole estas quatro linhas (uma por vez):

   ```bash
   sudo add-apt-repository universe
   sudo add-apt-repository ppa:cubic-wizard/release
   sudo apt update
   sudo apt install --no-install-recommends cubic
   ```

2. Abra o aplicativo **Cubic** pelo menu.
3. Selecione uma pasta vazia como projeto (ex.: `/home/SEU_USUARIO/Cubic-FENIX`), avance e escolha a ISO original do Mint (`linuxmint-22.3-xfce-64bit.iso`).
4. O Cubic exibirá um terminal **dentro da imagem** (chroot). No terminal Cubic digite `cd /root` e pressione Enter. **Arraste a pasta extraída** `FENIX_OS_Legacy_v0_2_2` do gerenciador de arquivos do Ubuntu para a janela do terminal Cubic; clique no botão **Copy** se aparecer. Agora digite `mv /root/FENIX_OS_Legacy_v0_2_2 /root/fenix` e depois `ls /root/fenix/scripts/install-packages.sh`. **Somente continue se esse último comando mostrar o arquivo**. O arrastar-e-soltar e o botão Copy fazem parte da interface oficial do Cubic.
5. Execute os três comandos abaixo, **dentro do terminal do Cubic** (e não no Terminal normal do Ubuntu):

   ```bash
   bash /root/fenix/scripts/install-packages.sh
   bash /root/fenix/scripts/cleanup-optimize.sh apply
   bash /root/fenix/scripts/stage-into-root.sh
   ```

   Se algum mostrar `error`, **não avance** à geração da ISO: registre a mensagem e corrija a causa. A sintaxe foi verificada, mas os pacotes ainda não foram testados em uma VM Noble/Mint real.
6. Avance nas telas do Cubic sem trocar o kernel da imagem. Escolha compressão `xz` quando disponível, preservando a opção de boot **BIOS Legacy**.
7. Gere `fenix-os-legacy-amd64.iso` e verifique seu tamanho. A meta é caber em 8 GB, idealmente ficar abaixo de 4 GB, mas isso depende das dependências realmente incluídas.

## Testar antes de usar o computador antigo
1. No VirtualBox, crie **outra VM** Linux/Ubuntu 64-bit, com disco virtual de 32 GB e ~4 GB RAM.
2. Em Settings/Configurações > System/Sistema > Motherboard/Placa-mãe: **desative EFI**; precisa simular BIOS Legacy.
3. Selecione a ISO personalizada como drive de CD/DVD virtual, ligue e verifique que abre a sessão Live.
4. Execute `Install Linux Mint` e instale no **disco virtual**. Confira que a instalação conclui, remova ISO do drive e reinicie. Não confunda Live que funciona com instalação concluída.
5. Confira login, Whisker Menu, Hub, teclado e pacotes. Caso o instalador trave na etapa de horário, a ISO NÃO está homologada — o FÊNIX não corrigiu o Ubiquity original.
6. Só então grave a ISO pelo Rufus em um pendrive (MBR / BIOS ou UEFI-CSM) e teste no hardware Intel H55. Confirme o SSD/HD de destino antes de apagar qualquer coisa.

## Newelle (fase 2)
NÃO rode os scripts Newelle enquanto estiver remasterizando a ISO base. Eles são para depois que o Mint estiver instalado, testado e com internet. Consulte `docs/06_NEWELLE_FASE2.md`.

## Paradas obrigatórias
- **Não** selecione o SSD físico do Windows como disco da VM.
- **Não** apague partições do PC antigo durante o build ou teste em VM.
- **Não** prossiga se scripts essenciais falharem.
- É necessário testar a instalação inteira; a falha anterior de fuso horário ainda não foi corrigida.
