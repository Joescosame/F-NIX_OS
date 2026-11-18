# Roadmap

1. **Base arquitetural (esta entrega):** ADRs, remoções, inventário/comparação funcional e testes simulados, perfis de verificadores e estudos. Sem nova ISO.
2. **Instalação portátil (próxima tarefa):** QCOW2 descartável GPT, SeaBIOS/OVMF, instalador offline, dois destinos GRUB e mesma raiz nas migrações. Começar por investigar pacotes e fluxo Ubiquity; não partir para SSD físico.
3. **Central de Desempenho:** métricas reais, histórico, GUI e depois overlay independente, com orçamento medido.
4. **Motor Android:** protótipo isolado somente após validar imagem, licenças, KVM e orçamento. Sem integração na base.
5. **Nova candidata:** integrar apenas aprovados, construir separadamente, hashes, boot, instalação, reboot e testes físicos. Nunca substituir a primeira candidata.

Não avançar fases automaticamente. Cada campanha registra PASSOU, FALHOU, BLOQUEADO ou NÃO EXECUTADO e preserva evidências e hash exato da imagem.
