# ADR 0004 — Identidade genérica e PT-BR

Data: 18/11/2026. Decisão aceita.

FÊNIX OS atende máquinas x86_64 compatíveis, antigas ou modernas, com Mint 22.3 Xfce como base. Não condicionar interfaces a placa, CPU ou GPU específicas, nem incluir referências pessoais ou bastidores do desenvolvimento. Marcas técnicas conservam seus nomes. Hardware inicial fica documentado apenas no histórico e QA.

Não impor driver Xorg específico, não instalar driver proprietário automaticamente e não criar novos processos permanentes sem medir necessidade. Identificação de hardware em relatório técnico é resultado de inventário local, não identidade do produto. Componentes próprios usam PT-BR; tradução completa dos componentes upstream não foi homologada nesta fase.
