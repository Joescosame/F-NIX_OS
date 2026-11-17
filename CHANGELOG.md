# Histórico de alterações

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
