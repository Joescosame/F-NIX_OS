# ADR 0001 — Disco portátil e perfis de QA

Data: 18/11/2026. Decisão arquitetural aceita; implementação e homologação pendentes.

Contexto: preservar o mesmo SSD ao trocar hardware, sem reinstalar quando compatível. A candidata anterior prova somente Live Legacy.

Decisão: investigar GPT + BIOS Boot + ESP + raiz por UUID, dois destinos GRUB, initramfs genérico e recuperação. Separar mídia ISO híbrida do disco instalado. Critério: mesmo QCOW2 inicia SeaBIOS e OVMF, sem reinstalação, com evidências de migração nos dois sentidos. Secure Boot não presumido. Plano e riscos em ../PORTABILIDADE.md.

Consequências: mais passos no instalador, conflitos de pacotes GRUB a investigar, necessidade de ESP/fallback EFI e recuperação. Não converter discos físicos automaticamente. Perfil legado continua verificável; novos perfis não herdam aprovação antiga.
