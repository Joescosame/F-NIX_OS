# Git no notebook Windows

Origem oficial exclusiva: **https://github.com/Joescosame/F-NIX_OS.git**. O usuário informou e a integração confirmou acesso administrativo e visibilidade pública. Não criar outro repositório nem modificar visibilidade/cobrança.

## Checkout já existente nesta sessão

O agente acessou o notebook Windows e configurou `origin` na pasta de fontes entregue em `outputs/FENIX-OS-Legacy`. A pasta tem esse nome por ser a entrega anterior; o destino remoto é exclusivamente **F-NIX_OS**.

A branch principal é `main`. Desenvolvimento significativo usa `codex/legacy-iso-integration` e Pull Request para `main`. O histórico local original está preservado também em `archive/local-v0.3.0`; nenhum reset destrutivo ou push com força é necessário.

O sandbox consegue fazer fetch por HTTPS, mas o auxiliar de credenciais do Git falha ao iniciar. A integração conectada pode publicar pela API sem gravar tokens. Esse limite não prova que o Git no PowerShell normal do usuário falhará. Nenhuma credencial foi criada ou configurada no notebook por esta sessão.

## Clonar em outra pasta ou sincronizar

No PowerShell normal, com Git instalado:

```powershell
git clone https://github.com/Joescosame/F-NIX_OS.git
cd F-NIX_OS
git switch main
git pull --ff-only
git switch -c codex/minha-alteracao
```

No checkout já existente, abra o terminal na pasta correta e confira:

```powershell
git remote -v
git fetch origin
git switch main
git pull --ff-only
```

Se o pull recusar por divergência ou mudanças locais, preserve os arquivos e examine o histórico; não use `reset --hard` nem `push --force` para contornar.

Para publicar pelo notebook, autentique o GitHub CLI no próprio terminal (`gh auth login`, sem colar tokens no chat) e execute `powershell.exe -NoProfile -File .\tools\PUBLICAR_GITHUB.ps1`. O helper só aceita o destino oficial, publica a branch atual sem força e não cria repositórios nem muda visibilidade. Abra PR das branches de desenvolvimento para `main`.

Para construir a ISO, clone o mesmo endereço **dentro de uma VM Ubuntu 24.04**, no filesystem Linux, e siga `BUILD.md`. Configurar Git no Windows não instala WSL, QEMU ou dependências Linux.
