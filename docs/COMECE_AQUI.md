# Comece aqui

O FÊNIX é uma personalização do Linux Mint 22.3 Xfce para o Intel H55/i5-650, 8 GB, Intel Ironlake, SATA e BIOS Legacy. **Ainda não há ISO FÊNIX construída ou instalação homologada nesta entrega.** Consulte o relatório em `RESULTADOS.md`.

No Windows, uma ISO não é uma pasta para copiar programas. Prepare uma **VM Ubuntu 24.04 de 64 bits**, com 8 GB de RAM se o notebook permitir e pelo menos 50 GiB livres no disco virtual. A VM de testes usa mais um disco virtual de 32 GiB. Nunca conecte discos físicos à VM.

1. Copie este repositório para o disco Linux da VM (não execute o build em pasta compartilhada NTFS).
2. Siga `BUILD.md` para instalar ferramentas e construir.
3. Siga `QA.md`: boot Live não comprova instalação. Instale no disco virtual em MBR e reinicie sem CD.
4. Só após aprovação virtual grave um pendrive e faça a validação física H55.

Não é necessário executar GitHub Actions. O build local não consome minutos do GitHub. Os workflows estão prontos e são **exclusivamente manuais**; nada foi disparado, nenhuma cobrança foi habilitada.

O Hub reúne inventário, histórico CSV/JSONL, snapshots de diagnóstico, monitoramento, Synaptic e atualizações. Snapshots são relatórios locais do PC; **não são backup/restauração do disco**. Ferramentas avançadas têm fallbacks. Newelle/DeepSeek é opcional e fica fora da ISO base.

Os guias antigos numerados foram preservados como histórico v0.2.2. Em conflito, siga os novos guias sem prefixo numérico. Cubic continua uma alternativa de exploração, mas a entrega reproduzível usa os scripts novos.
