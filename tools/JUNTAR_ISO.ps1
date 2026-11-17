# Compatível com Windows PowerShell 5.1. Não usa concatenação de texto.
[CmdletBinding()]
param([string]$Pasta = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
function Get-Sha256([string]$Caminho) {
    $stream = [IO.File]::OpenRead($Caminho)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose(); $stream.Dispose() }
}
$Pasta = (Resolve-Path -LiteralPath $Pasta).Path
$m = Get-Content -LiteralPath (Join-Path $Pasta 'manifesto.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$nome = 'FENIX-OS-Legacy-amd64.iso'
if ($m.schema -ne 1 -or $m.iso -cne $nome -or $m.sha256 -cnotmatch '^[0-9a-f]{64}$' -or [long]$m.size -le 0) { throw 'Manifesto invalido' }
$partes = @($m.parts)
if ($partes.Count -lt 1 -or $partes.Count -gt 999) { throw 'Quantidade de partes invalida' }
$destino = Join-Path $Pasta $nome
$parcial = "$destino.partial"
if ((Test-Path -LiteralPath $destino) -or (Test-Path -LiteralPath $parcial)) { throw 'Saida ja existe; nao sera sobrescrita' }
$total = [long]0
for ($i = 0; $i -lt $partes.Count; $i++) {
    $p = $partes[$i]
    $esperado = '{0}.part{1:D3}' -f $nome, ($i+1)
    if ($p.name -cne $esperado -or $p.sha256 -cnotmatch '^[0-9a-f]{64}$' -or [long]$p.size -le 0 -or [long]$p.size -gt 1992294400) { throw 'Parte invalida' }
    $caminho = Join-Path $Pasta $esperado
    $arquivo = Get-Item -LiteralPath $caminho
    if (($arquivo.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $arquivo.Length -ne [long]$p.size) { throw "Tamanho/link invalido: $esperado" }
    if ((Get-Sha256 $caminho) -cne $p.sha256) { throw "Hash incorreto: $esperado" }
    $total += [long]$p.size
}
if ($total -ne [long]$m.size) { throw 'Soma dos tamanhos incorreta' }
$saida = [IO.File]::Open($parcial, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
try {
    foreach ($p in $partes) {
        $entrada = [IO.File]::OpenRead((Join-Path $Pasta $p.name))
        try { $entrada.CopyTo($saida, 8388608) } finally { $entrada.Dispose() }
    }
} finally { $saida.Dispose() }
if ((Get-Item -LiteralPath $parcial).Length -ne [long]$m.size -or (Get-Sha256 $parcial) -cne $m.sha256) { throw 'Hash final incorreto' }
[IO.File]::Move($parcial, $destino)
Write-Host "PASSOU: ISO reconstruida e SHA-256 final conferido: $destino"
