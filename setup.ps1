<#
.SYNOPSIS
    Crea symlinks/junctions desde tu repo de dotfiles hacia las ubicaciones reales
    que espera cada programa en Windows.

.DESCRIPTION
    Edita la sección $links de abajo con tus propias configuraciones.
    - "Source" = ruta dentro del repo (relativa a la carpeta donde vive este script)
    - "Target" = ruta real donde el programa espera encontrar el archivo/carpeta
    - "Type"   = "File" o "Dir"

    Si el Target ya existe, el script lo respalda (renombrándolo con sufijo .bak)
    antes de crear el link, para no perder configuraciones previas.

.NOTES
    - Para symlinks de ARCHIVOS necesitas "Modo de Desarrollador" activado
      (Configuración > Privacidad y seguridad > Para desarrolladores)
      o correr PowerShell como Administrador.
    - Para carpetas se usan Junctions, que NO requieren permisos especiales.
#>

# ============================================================
# CONFIGURA AQUÍ TUS CONFIGURACIONES
# ============================================================

$RepoRoot = $PSScriptRoot   # carpeta donde está este script (la raíz del repo)

$links = @(
    # VS Code
    @{ Source = "vscode\settings.json"
       Target = "$env:APPDATA\Code\User\settings.json"
       Type   = "File" }

    @{ Source = "vscode\keybindings.json"
       Target = "$env:APPDATA\Code\User\keybindings.json"
       Type   = "File" }

    @{ Source = "vscode\snippets"
       Target = "$env:APPDATA\Code\User\snippets"
       Type   = "Dir" }

    # GlazeWM
    @{ Source = "glazewm"
       Target = "$HOME\.glzr\glazewm"
       Type   = "Dir" }

    # Zebar
    @{ Source = "zebar"
       Target = "$HOME\.glzr\zebar"
       Type   = "Dir" }

    # @{ Source = "powershell\Microsoft.PowerShell_profile.ps1"
    #    Target = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    #    Type   = "File" }

    # @{ Source = "nvim"
    #    Target = "$env:LOCALAPPDATA\nvim"
    #    Type   = "Dir" }

    # @{ Source = "git\.gitconfig"
    #    Target = "$HOME\.gitconfig"
    #    Type   = "File" }
)

# ============================================================
# NO NECESITAS EDITAR NADA DE AQUÍ HACIA ABAJO
# ============================================================

function Write-Info($msg)    { Write-Host "  $msg" -ForegroundColor Cyan }
function Write-Ok($msg)      { Write-Host "  $msg" -ForegroundColor Green }
function Write-WarnMsg($msg) { Write-Host "  $msg" -ForegroundColor Yellow }
function Write-ErrMsg($msg)  { Write-Host "  $msg" -ForegroundColor Red }

Write-Host "`n=== Setup de dotfiles ===" -ForegroundColor Magenta
Write-Host "Repo: $RepoRoot`n"

foreach ($link in $links) {

    $sourcePath = Join-Path $RepoRoot $link.Source
    $targetPath = [System.Environment]::ExpandEnvironmentVariables($link.Target)
    $type       = $link.Type

    Write-Host "-> $($link.Source)" -ForegroundColor White

    # 1. Verifica que el archivo/carpeta exista en el repo
    if (-not (Test-Path $sourcePath)) {
        Write-ErrMsg "No existe en el repo: $sourcePath (se omite)"
        continue
    }

    # 2. Verifica que la carpeta contenedora del target exista, si no, créala
    $targetParent = Split-Path $targetPath -Parent
    if (-not (Test-Path $targetParent)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
        Write-Info "Creada carpeta contenedora: $targetParent"
    }

    # 3. Si el target ya existe...
    if (Test-Path $targetPath) {

        $existingItem = Get-Item $targetPath -Force

        # Si ya es un symlink/junction, revisa si ya apunta al lugar correcto
        if ($existingItem.LinkType) {
            $currentTarget = $existingItem.Target
            if ($currentTarget -eq (Resolve-Path $sourcePath).Path) {
                Write-Ok "Ya estaba enlazado correctamente (se omite)"
                continue
            } else {
                Remove-Item $targetPath -Force -Recurse
                Write-Info "Link antiguo (apuntaba a otro lado) eliminado"
            }
        } else {
            # Es un archivo/carpeta real -> respaldar antes de reemplazar
            $backupPath = "$targetPath.bak"
            if (Test-Path $backupPath) {
                Remove-Item $backupPath -Force -Recurse
            }
            Rename-Item -Path $targetPath -NewName (Split-Path $backupPath -Leaf) -Force
            Write-WarnMsg "Existía config previa, respaldada como: $(Split-Path $backupPath -Leaf)"
        }
    }

    # 4. Crear el link
    try {
        if ($type -eq "Dir") {
            New-Item -ItemType Junction -Path $targetPath -Target $sourcePath -ErrorAction Stop | Out-Null
            Write-Ok "Junction creada"
        } else {
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -ErrorAction Stop | Out-Null
            Write-Ok "Symlink creado"
        }
    } catch {
        Write-ErrMsg "No se pudo crear el link: $($_.Exception.Message)"
        Write-WarnMsg "Sugerencia: activa 'Modo de Desarrollador' o corre este script como Administrador"
    }

    Write-Host ""
}

Write-Host "=== Listo ===" -ForegroundColor Magenta