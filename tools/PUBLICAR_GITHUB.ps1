# Executar somente depois de autenticar GitHub CLI. Não altera visibilidade.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Get-Command gh -ErrorAction Stop | Out-Null
Get-Command git -ErrorAction Stop | Out-Null
& gh auth status
if ($LASTEXITCODE -ne 0) { throw 'Autentique o gh na sua conta; nunca cole tokens no projeto' }
$usuario = & gh api user --jq .login
if ($LASTEXITCODE -ne 0 -or $usuario -cne 'Joescosame') { throw 'Conta autenticada diferente da conta conectada Joescosame' }
$repo = 'Joescosame/FENIX-OS-Legacy'
$json = & gh repo view $repo --json isPrivate,url 2>$null
if ($LASTEXITCODE -ne 0) {
    & gh repo create $repo --private --source $raiz --remote origin
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar repositorio privado' }
    $json = & gh repo view $repo --json isPrivate,url
}
$meta = $json | ConvertFrom-Json
if (-not $meta.isPrivate) { throw 'Repositorio nao e privado. Operacao interrompida' }
$origin = & git -C $raiz remote get-url origin 2>$null
if ($LASTEXITCODE -ne 0) {
    & git -C $raiz remote add origin "https://github.com/$repo.git"
} elseif ($origin -ne "https://github.com/$repo.git" -and $origin -ne "git@github.com:$repo.git") {
    throw 'Remote origin aponta para outro destino'
}
& git -C $raiz push -u origin main
if ($LASTEXITCODE -ne 0) { throw 'Push falhou; nada sera forcado' }
Write-Host "Publicado em $($meta.url), mantendo privado. Nenhum workflow foi disparado."
