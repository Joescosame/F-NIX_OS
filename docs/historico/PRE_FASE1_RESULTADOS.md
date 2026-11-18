> HISTÓRICO: relatório da etapa anterior, não representa o estado atual. Veja RESULTADO_BOOT_LIVE.md e FASE1_RESULTADOS.md.

# Resultados históricos da primeira etapa — 16/11/2026

> Registro preservado da primeira entrega. A decisão posterior tornou F-NIX_OS o repositório oficial público. Para a etapa atual consulte AUDITORIA.md e Git no Windows em GIT_WINDOWS.md. O bloqueio histórico de criação de repositório não se aplica ao destino oficial já existente.

Este relatório descreve evidências locais, não uma homologação da ISO.

| Verificação | Estado | Evidência/limite |
|---|---|---|
| Integridade do ZIP de origem | PASSOU | 36 arquivos conferem com SHA256SUMS_FONTE.txt original |
| SHA-256 da ISO Mint local | PASSOU | `45a835b5dddaf40e84d776549e0b19b3fbd49673b6cc6434ebddbfcd217df776`; igual ao manifesto obtido do servidor oficial |
| GPG da ISO original nesta sessão | BLOQUEADO | GnuPG do Git falha em NtCreateDirectoryObject; GnuPG Windows extraído falha por realocação de DLL no sandbox. Nenhum bypass no construtor |
| Inspeção do conteúdo da ISO local | PASSOU | Leitura com 7-Zip: Ubiquity 24.04.3+mint19; plugin e clock-setup examinados |
| Regressão do callback timezone | PASSOU | Original reproduz AttributeError em double de cancelamento; patch trata resposta vazia/cancelada/inválida e conserva fallback |
| Python AST/compilação, YAML, SVG, estrutura desktop | PASSOU | Validações portáteis e unittest; não substituem desktop-file-validate |
| ShellCheck | PASSOU | ShellCheck nativo Windows 0.11.0, nível warning/error; SC1091 excluído para includes de runtime |
| bash -n | BLOQUEADO | Bash Git/MSYS não inicia no sandbox Windows, erro NtCreateDirectoryObject. ShellCheck conseguiu analisar os scripts |
| desktop-file-validate nativo | BLOQUEADO | Ferramenta Linux ausente; validação portátil de campos executada |
| Histórico CSV/JSONL offline | PASSOU | Coleta por 1 segundo, consistência de timestamps/linhas e rejeição de intervalo inválido; sensores Linux reais não disponíveis |
| Divisão/reconstrução Python | PASSOU | Fixture binária, múltiplas partes, hash final, parte ausente/corrompida, caminhos inválidos e sobrescrita recusados |
| Reconstrução Windows PowerShell 5.1 | PASSOU | Fixture binária reconstruída; corrupção e sobrescrita recusadas |
| Snapshot em Linux | NÃO EXECUTADO | Teste presente, pulado no Windows; manifesto corrigido para excluir a si próprio |
| Configuração QEMU e proteção de caminhos | PASSOU | Testes unitários da linha de comando; reboot sem CD, offline sem rede e injeção em caminho rejeitada |
| Retenção de pacotes/idioma e gate de Release | PASSOU | Fixtures de manifests, rejeição de pacote essencial ausente e de aprovação sem hash/testes/evidências válidas |
| Build squashfs/chroot/xorriso | BLOQUEADO | Host Windows, WSL não instalado, utilitários Linux/root ausentes; cerca de 17 GiB livres, abaixo do mínimo 35 GiB |
| Boot da ISO FÊNIX no SeaBIOS | NÃO EXECUTADO | ISO FÊNIX não existe; QEMU ausente |
| Instalação offline em MBR | NÃO EXECUTADO | Requer ISO construída, Linux/QEMU e operador gráfico |
| Reboot do disco sem ISO e login | NÃO EXECUTADO | Depende da instalação completa |
| Xfce/Hub no sistema instalado | NÃO EXECUTADO | Presença no código não prova instalação ou funcionamento gráfico |
| zram, swap, RAM e serviços em runtime | NÃO EXECUTADO | Configuração e coleta implementadas; falta boot real |
| Reversão de otimizações no sistema real | NÃO EXECUTADO | Backup de estado corrigido; validar após boot |
| H55, Ironlake, HDD/SSD SATA físicos | NÃO EXECUTADO | Homologação física separada da virtual |
| Criação e push GitHub | BLOQUEADO | Conta conectada Joescosame; get_repo retornou 404. Conector sem create_repository; controle Firefox bloqueado pela política de URLs da ferramenta |
| GitHub Actions e Release | NÃO EXECUTADO | Nenhum workflow disparado; nenhuma Release/ISO publicada; sem mudanças de cobrança/visibilidade |

ZIP original SHA-256: `68e0a0187992b4e90afb862e5ed6daf3f03bf899c7b78f7787445a3b09a0eddc`.

Os logs resumidos públicos estão em `tests/evidence/`; não contêm snapshots do computador nem credenciais. A fonte extraída do Ubiquity é fixture GPL. Leia `TIMEZONE.md`: corrigir o callback não comprova a causa total da espera de NTP nem a instalação no SSD.

O objetivo final continua **pendente**: gerar a ISO, instalar em MBR numa VM, retirar a ISO, reiniciar e entrar no Xfce/Hub. Em seguida validar o H55. O próximo desbloqueio da publicação é criar/conceder acesso ao repositório privado vazio; nenhuma mudança para público é necessária.
