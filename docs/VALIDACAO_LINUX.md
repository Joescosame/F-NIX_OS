# Validação real em Linux

Em 17/11/2026 UTC, [Validar fontes #1](https://github.com/Joescosame/F-NIX_OS/actions/runs/43992807682) executou o commit `f2101118b83c63566e1c13333231b33b7a7dab94` em Ubuntu 24.04, imagem `20261111.370.1`.

- PASSOU: Bash, ShellCheck 0.9.0, desktop-file-validate, Python, YAML, SVG e estrutura.
- PASSOU: 17 de 19 testes, incluindo snapshots e histórico offline CSV/JSONL.
- NÃO EXECUTADO nesse Linux: 2 testes exclusivos de Windows PowerShell 5.1, já executados no notebook na etapa anterior.
- Aviso: duas categorias principais no `.desktop` do Hub; corrigido para `System`.
- Aviso: checkout com Node 20 descontinuado; atualizado para checkout v6 fixado por SHA, com credenciais não persistidas.

O texto de reconstrução de ISO nos testes refere-se a um arquivo sintético pequeno de teste, não a uma imagem instalável. Essa execução não construiu a ISO, não iniciou QEMU e não executou o instalador.

O build deve medir 35 GiB livres antes de instalar dependências e novamente no preflight. Rascunhos em Releases guardam partes sem utilizar a franquia de artefatos Actions. Nenhuma configuração de cobrança foi alterada.
