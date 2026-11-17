# Histórico de alterações

## Integração oficial F-NIX_OS — continuação da versão 0.3.0-dev

- Repositório público existente adotado como única origem; configuração local de origin, branch de desenvolvimento e documentação Git Windows.
- Histórico anterior preservado; README remoto inicial arquivado.
- Eliminada criação de outros repositórios nos helpers atuais; Release aponta ao destino oficial.
- Chroot com dispositivos mínimos e namespace de processos; mídia reimportada explicitamente antes de reproduzir boot.
- Verificador de boot exige BIOS habilitada e MBR; testes adicionais de regressão e de limites financeiros do workflow.
- Workflow manual com limpeza restrita do runner efêmero; upload de artefatos desativado por padrão.
- Construção e instalação continuam não homologadas; detalhes em docs/AUDITORIA.md.

## 0.3.0-dev — 16/11/2026 — não homologado

- Construtor Bash/chroot/xorriso para Ubuntu 24.04; assinatura GPG e SHA fixados, replay do boot, manifests e relatórios.
- Workflows exclusivamente manuais, sem contratação de runner ou cobrança e sem publicação estável.
- Patch testável do callback GeoIP Ubiquity e instalador offline que evita NTP na instalação.
- Dependências essenciais agora falham quando ausentes; opcionais não reprovam indevidamente o perfil.
- Remoção protegida de Snap/Flatpak e retenção de pacotes/traduções no sistema instalado.
- Primeiro login não é marcado concluído depois de erro; falhas xfconf essenciais propagam.
- Corrigidos escape do Exec de xcape, manifesto de snapshot (exclui a si próprio), permissões privadas de histórico/snapshot e colisão de nomes hwmon.
- Reversão preserva o estado original mesmo após reaplicar otimizações; Synaptic usa autenticação administrativa; todo DEB externo precisa constar no manifesto.
- Reconstrução por streaming em PowerShell 5.1/Linux com hash por parte e final, rejeição de caminhos e sem sobrescrita.
- Harness QEMU isolado: SeaBIOS, 2 CPUs, 4–8 GB, disco virtual separado offline/online; instalação ainda manual.
- Testes de regressão e guias em PT-BR. Base anterior preservada com avisos de histórico.
- GitHub, construção ISO e testes completos permanecem sujeitos aos bloqueios registrados em docs/RESULTADOS.md.
