# Testes automáticos disponíveis

Procedimento atual: `./tools/lint.sh` e `docs/QA.md`. Abaixo está o procedimento mínimo preservado da fonte v0.2.2. Consulte `docs/RESULTADOS.md` para os resultados efetivamente executados. Os testes usam dados temporários e não aprovam uma ISO por existência de scripts.

No host Linux:
```
bash scripts/teste-sintaxe.sh
python3 scripts/historico-sensores.py --duration 1 --interval 1
```

O coletor cria CSV e JSONL em `~/TestesPC/historico/`. Não execute no host se não quiser gerar arquivos ali. As verificações estáticas não simulam a GPU, Xfce, Ubiquity, BIOS ou ISO real. Procedimento de boot e instalação em `docs/01_PLANO_BUILD.md`; QA funcional em `docs/03_QA.md`.
