<#
.SYNOPSIS
    Instala las extensiones de VS Code listadas en extensions.txt.

.DESCRIPTION
    extensions.txt se genera/actualiza con:
        code --list-extensions > vscode\extensions.txt
    (no se versiona la carpeta de extensiones en si, es binaria y pesa demasiado)
#>

$ExtensionsFile = Join-Path $PSScriptRoot "extensions.txt"

if (-not (Test-Path $ExtensionsFile)) {
    Write-Host "No se encontro $ExtensionsFile" -ForegroundColor Red
    exit 1
}

Get-Content $ExtensionsFile | Where-Object { $_.Trim() -ne "" } | ForEach-Object {
    Write-Host "Instalando: $_" -ForegroundColor Cyan
    code --install-extension $_
}
