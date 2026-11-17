# Sincroniza somente o repositorio oficial existente; nao cria repositorios.
[CmdletBinding()]
param([string]$Branch = '')
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Get-Command gh -ErrorAction Stop | Out-Null
Get-Command git -ErrorAction Stop | Out-Null
& gh auth status
if ($LASTEXITCODE -ne 0) { throw 'Autentique o gh; nunca cole tokens no projeto' }
$repo = 'Joescosame/F-NIX_OS'
$json = & gh repo view $repo --json nameWithOwner,url
if ($LASTEXITCODE -ne 0) { throw 'Repositorio oficial inacessivel; nao sera criado outro' }
$meta = $json | ConvertFrom-Json
if ($meta.nameWithOwner -cne $repo) { throw 'Repositorio inesperado' }
$origin = & git -C $raiz remote get-url origin
if ($LASTEXITCODE -ne 0) { throw 'Configure origin conforme docs/GIT_WINDOWS.md' }
if ($origin -ne "https://github.com/$repo.git" -and $origin -ne "git@github.com:$repo.git") {
    throw 'Remote origin aponta para outro destino'
}
if (-not $Branch) { $Branch = & git -C $raiz branch --show-current }
& git -C $raiz check-ref-format --branch $Branch
if ($LASTEXITCODE -ne 0) { throw 'Branch invalida' }
& git -C $raiz push -u origin $Branch
if ($LASTEXITCODE -ne 0) { throw 'Push falhou; nada sera forcado' }
Write-Host "Publicado em $($meta.url), branch $Branch. Nenhum workflow foi disparado."
