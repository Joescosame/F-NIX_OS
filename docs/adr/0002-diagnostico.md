# ADR 0002 — Diagnóstico de Upgrade local

Data: 18/11/2026. Decisão aceita; primeira versão implementada.

Inventários JSON versionados com leitura sob demanda de /proc e /sys, sem processo residente, root ou rede. Comparação por categoria/localização e atributos, sem serial/MAC/UUID para correlação. Isso reduz identificadores, mas implica ambiguidade quando componentes mudam de porta; apresentar possíveis substituições, nunca certeza sem evidência. Dados locais ainda podem identificar modelos de hardware: não publicar automaticamente.

Driver vinculado e dispositivo detectado são evidências distintas de dispositivo testado. Nenhum teste funcional é marcado PASSOU pela coleta. Interface PT-BR em texto e YAD opcional, integrada ao Hub. Não instalar drivers. Limites e comandos em ../DIAGNOSTICO_UPGRADE.md.
