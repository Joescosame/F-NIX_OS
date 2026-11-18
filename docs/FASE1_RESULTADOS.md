# Fase 1 — estado e evidências

Ponto de partida: PR #2, commit 977fc265f67c74e90046ad937cd8152fadc5861f, sem merge na main. Branch codex/arquitetura-portabilidade-fase1. Nenhuma nova ISO, alteração da Release, disco físico, bootloader ou kernel nesta fase.

Referência preservada: build 44002337245 e boot Live SeaBIOS 44006253371; ISO 3218407424 bytes, SHA-256 1404e0c5dadecb595a3c031bd2538e51379579e18d412dc9ed7cea5b64f6c764. As mudanças desta branch não estão nessa ISO.

| Verificação | Estado | Escopo |
| --- | --- | --- |
| Testes locais Windows | PASSOU | 27 testes, 24 aprovados e 3 exclusivos de Linux ignorados; inclui PowerShell 5.1 |
| Python AST/YAML/SVG/.desktop estrutural | PASSOU | Validação portátil |
| ShellCheck e Actionlint | PASSOU | Scripts ativos e workflows existentes |
| Inventário/comparação | PASSOU | Dados simulados, privacidade, ausências, formato e diferenças; não homologa hardware |
| Perfis firmware e gate de aprovação | PASSOU | Fixtures, rejeição de firmware/tabela incorretos, ESP ausente e discos diferentes |
| Bash e desktop-file-validate nativos | PASSOU | Execução Linux 44280632624 |
| Diagnóstico na GUI instalada | NÃO EXECUTADO | YAD integra a mesma coleta; nenhuma nova ISO nesta fase |
| Boot do mesmo disco em Legacy e UEFI | NÃO EXECUTADO | Campanha Fase 2 |
| Monitoramento/overlay próprios | NÃO EXECUTADO | Arquitetura Fase 3 |
| Motor Android | NÃO EXECUTADO | Pesquisa documental; protótipo Fase 4 |

Foram retirados scripts, dependências e atalhos dos componentes cancelados. Histórico de fontes e commits permanece rastreável. Guias antigos numerados foram movidos para historico/v0.2.2 com aviso explícito; documentação operacional atualizada para refletir build e boot existentes.

Limites: inventário básico sem serial/MAC/UUID e sem DIMMs individuais; alterações de porta podem aparecer como adição/remoção. Sem teste funcional automático ou diagnóstico universal de incompatibilidade. Portabilidade depende de pacotes GRUB/Ubiquity, firmware, initramfs e migração real; hardware original físico continua não homologado.

Próxima execução recomendada: investigar e implementar a instalação GPT portátil somente em QCOW2 descartável, conforme PORTABILIDADE.md; não iniciar automaticamente a Fase 2.

Validação Linux final: [44280632624](https://github.com/Joescosame/F-NIX_OS/actions/runs/44280632624), código 15ec1bcdbbb13ca9949cd6a1b602c37ac10b898a: 27 testes, 25 aprovados e 2 PowerShell ignorados. Todos os seis testes novos passaram. Bash, ShellCheck, desktop-file-validate, Python, YAML e SVG passaram. Resumo público em tests/evidence/fase1-linux.txt; lista de arquivos em ARQUIVOS_FASE1.md.
