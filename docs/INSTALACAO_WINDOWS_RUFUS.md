# Baixar, juntar e gravar no Windows 11

**Existe uma candidata em Release de rascunho, com boot Live SeaBIOS aprovado e instalação ainda não homologada.** Acesso autenticado aos colaboradores; este guia descreve a candidata de referência. Não tente gravar o ZIP de fontes como sistema operacional.

1. Na Release aprovada do [repositório oficial público](https://github.com/Joescosame/F-NIX_OS/releases), baixe todas as partes `.part001`, `.part002` etc., `manifesto.json`, `SHA256SUMS` e `JUNTAR_ISO.ps1` para a mesma pasta. Confira que nomes não ganharam `(1)` nem `.txt`. Não extraia as partes.
2. Use disco NTFS/exFAT com espaço para partes + ISO (aproximadamente duas vezes o tamanho da imagem). FAT32 não aceita arquivos de 4 GiB ou mais.
3. Abra **Windows PowerShell** na pasta e execute:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\JUNTAR_ISO.ps1
   ```

   Essa opção vale só para o processo atual. O script usa .NET, lê em streaming, confere cada parte, reconstrói em `.partial` e valida tamanho e SHA-256 final antes de renomear. Não sobrescreve ISO existente nem apaga partes. Se faltar/corromper parte, baixe a parte novamente. Uma saída `.partial` de falha deve ser preservada para diagnóstico ou removida manualmente antes da nova tentativa.

4. Confira também `Get-FileHash .\FENIX-OS-Legacy-amd64.iso -Algorithm SHA256` contra a linha final de `SHA256SUMS`, se o cmdlet estiver disponível. Hash confirma integridade; os arquivos devem vir da Release autêntica. Não use manifestos de terceiros.
5. Baixe Rufus do [site oficial](https://rufus.ie/). Selecione o pendrive de **8 GB ou mais** conferindo nome e capacidade: a gravação apagará seu conteúdo. Escolha a ISO completa, **MBR**, **BIOS (ou UEFI-CSM)**. Se o Rufus oferecer modo DD para imagem híbrida, use-o e teste em BIOS Legacy. A interface pode variar conforme versão; o boot UEFI desta candidata não foi homologado.
6. No computador de teste Legacy, abra o menu de boot da BIOS e escolha a entrada USB Legacy. Teste Live antes de instalar. O SSD/HD de destino deve ser identificado por modelo e capacidade; faça backup antes de confirmar exclusão. A campanha de referência prevê MBR; a instalação portátil GPT será outra campanha (PORTABILIDADE.md). Não instalar no disco de uso diário antes da aprovação virtual.

No Linux, baixe `juntar-iso.sh`, `release.py`, partes e manifesto para a mesma pasta e execute `bash juntar-iso.sh`. Requer Python 3.11+ e verifica o mesmo hash final. Nunca concatene as partes em ordem escolhida manualmente.
