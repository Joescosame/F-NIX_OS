# Testes automáticos disponíveis

No host Linux:
```
bash scripts/teste-sintaxe.sh
python3 scripts/historico-sensores.py --duration 1 --interval 1
```

O coletor cria CSV e JSONL em `~/TestesPC/historico/`. Não execute no host se não quiser gerar arquivos ali. As verificações estáticas não simulam a GPU, Xfce, Ubiquity, BIOS ou ISO real. Procedimento de boot e instalação em `docs/01_PLANO_BUILD.md`; QA funcional em `docs/03_QA.md`.
