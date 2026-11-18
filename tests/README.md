# Testes automÃ¡ticos disponÃ­veis

Procedimento atual: `./tools/lint.sh` e `docs/QA.md`. Abaixo estÃ¡ o procedimento mÃ­nimo preservado da fonte v0.2.2. Consulte `docs/RESULTADOS.md` para os resultados efetivamente executados. Os testes usam dados temporÃ¡rios e nÃ£o aprovam uma ISO por existÃªncia de scripts.

No host Linux:
```
bash scripts/teste-sintaxe.sh
python3 scripts/historico-sensores.py --duration 1 --interval 1
```

O coletor cria CSV e JSONL em `~/TestesPC/historico/`. NÃ£o execute no host se nÃ£o quiser gerar arquivos ali. As verificaÃ§Ãµes estÃ¡ticas nÃ£o simulam a GPU, Xfce, Ubiquity, BIOS ou ISO real. Procedimento de boot e instalaÃ§Ã£o em `docs/BUILD.md`; QA funcional em `docs/QA.md`.

Fase 1: fixtures de inventário/upgrade, privacidade, ausências, perfis de firmware e gate do mesmo disco. São testes simulados, não portabilidade real.
