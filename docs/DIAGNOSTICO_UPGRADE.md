# Diagnóstico de Upgrade — versão inicial

Coleta local sob demanda, sem rede, sudo, instalação de drivers ou mudanças no sistema. CPU/modelos e processadores lógicos, RAM utilizável total, placa-mãe, firmware, PCI (GPU, áudio, rede, controladores), armazenamento, interfaces de rede e USB. Modelos podem aparecer como IDs numéricos; não há banco online. Sem serial, MAC, UUID de máquina/disco ou hostname.

```bash
python3 scripts/diagnostico-upgrade.py
python3 scripts/diagnostico-upgrade.py --comparar anterior.json atual.json
python3 scripts/diagnostico-upgrade.py --gui
```

Na instalação futura: `fenix-diagnostico-upgrade` ou menu Diagnóstico de Upgrade FÊNIX, também acessível no Hub. `--gui` usa YAD se houver DISPLAY; caso contrário imprime texto. Coletar salva em `$XDG_STATE_HOME/fenix/inventarios`, normalmente `~/.local/state/fenix/inventarios`, com arquivo 0600 e diretório novo 0700. Cada coleta tem nome próprio e não sobrescreve anteriores. Comparação explícita não salva nem altera os arquivos. Apague manualmente inventários indesejados. Não envie relatórios sem revisão.

Ao coletar, compara automaticamente com o inventário anterior disponível. A GUI mostra o inventário, sugestões e a comparação no mesmo relatório. Em modo texto sem GUI as mesmas informações são exibidas. Não há monitoramento contínuo.

## Interpretação

- Detectado: apareceu numa interface de leitura do kernel.
- Driver vinculado: existe um vínculo driver no sysfs; pode ser módulo ou código embutido no kernel. Não confundir ausência de vínculo consultável com certeza de driver ausente.
- Teste funcional: sempre NÃO EXECUTADO nesta versão. A presença de placa de rede não prova conectividade; a presença da GPU não prova aceleração.
- Mesmo local com atributos diferentes: possível substituição. Mudou de porta ou nome de bloco: adicionado/removido; o programa não pode afirmar que é outro dispositivo sem identidade persistente. Drivers alterados são informados separadamente.
- Hardware sem suporte só deve ser declarado incompatível quando houver logs/testes adicionais. A primeira versão oferece sugestões, não uma base universal de compatibilidade.

Memória não identifica DIMMs, clocks ou slots. Armazenamento não lê SMART nem testa integridade. Áudio USB aparece em USB; a função específica pode exigir inspeção adicional. Firmware não disponível gera limitação. Arquivos ilegíveis não elevam privilégios; dados faltantes podem gerar diferenças aparentes. Nenhum teste de stress é disparado.

Testes usam árvores /proc e /sys simuladas e inventários artificiais; não homologam hardware real nem a GUI instalada. A incorporação no staging está preparada para a próxima ISO, sem alterar a candidata de referência.
