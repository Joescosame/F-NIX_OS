# Dependências externas auditadas

Esta pasta fica vazia por padrão. Em uma VM de build:
1. Baixe DEBs apenas dos projetos oficiais / pacotes assinados.
2. Registre URL, tag/release e licença em arquivo local.
3. Verifique arquitetura `dpkg-deb -I pacote.deb` e compatibilidade Noble.
4. Gere `sha256sum pacote.deb > SHA256SUMS.txt` (ou acrescente linhas).
5. Instale via `scripts/install-extras-verificados.sh` apenas após inspecionar `dpkg-deb -c`.
6. Documente a versão, não habilite auto-update de fonte não oficial.

NÃO fornecemos bibliotecas ou binários privados nem asseguramos compatibilidade com a Ironlake.
