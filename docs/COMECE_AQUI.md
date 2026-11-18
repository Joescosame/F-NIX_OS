# Comece aqui

O FÊNIX usa Mint 22.3 Xfce x86_64, para máquinas antigas e modernas compatíveis. Já existe uma candidata com boot Live SeaBIOS aprovado: veja RESULTADO_BOOT_LIVE.md. A instalação completa e o boot UEFI continuam NÃO EXECUTADOS.

Nesta Fase 1 não construa nova ISO. Para conhecer o diagnóstico nas fontes Linux: `python3 scripts/diagnostico-upgrade.py`; salve antes e depois de trocar hardware e compare conforme DIAGNOSTICO_UPGRADE.md. Não exige sudo. O modo `--gui` usa YAD e oferece texto quando não há ambiente gráfico.

Para desenvolvimento, use Ubuntu 24.04 x86_64 ou Validar fontes manual no Actions da branch. `./tools/lint.sh` valida fontes e testes; não aprova hardware real. Os testes no Windows não substituem os Linux.

O Hub mantém ferramentas já operacionais e ganhou Diagnóstico de Upgrade no staging. Snapshot é relatório, não backup de recuperação. Recursos em pesquisa não aparecem como botões sem função.

Próxima tarefa: instalação portátil em QCOW2, conforme PORTABILIDADE.md. Não conectar discos físicos. Não converter seu SSD antes de backup e homologação da estratégia. A interface será genérica; hardware inicial consta apenas do QA histórico.

Os guias em historico/ e origem-v0.2.2/ preservam rastreabilidade; não são procedimentos atuais. Siga ROADMAP.md e os ADRs.
