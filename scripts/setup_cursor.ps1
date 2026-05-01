# ------------------------------------------------------------------
# setup_cursor.ps1
#
# Sets up symlinks so Cursor IDE auto-discovers this repo's content.
#
# What it does:
#   1. Creates a .cursor/ directory at the repo root (if absent).
#   2. Symlinks resources/rules/* into .cursor/rules/ (flattened)
#      so Cursor applies .mdc guardrails automatically.
#   3. Symlinks the top-level agents/ directory into .cursor/agents/
#      so role agents are discoverable via @mention.
#   4. Symlinks the top-level skills/ directory into .cursor/skills/
#      so role + process skills are discoverable via @mention.
#   5. Symlinks the top-level commands/ directory into .cursor/commands/
#      so /brainstorm, /write-plan, /execute-plan, /ship are available.
#
# Usage (run from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts\setup_cursor.ps1
#
# NOTE: Creating symlinks on Windows requires either:
#   - Running PowerShell as Administrator, OR
#   - Having Developer Mode enabled in Windows Settings.
# ------------------------------------------------------------------

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$CursorDir = Join-Path $RepoRoot ".cursor"
$RulesDir = Join-Path $CursorDir "rules"

Write-Host "Setting up Cursor IDE integration..."

if (-not (Test-Path $CursorDir)) {
    New-Item -ItemType Directory -Path $CursorDir | Out-Null
}
if (-not (Test-Path $RulesDir)) {
    New-Item -ItemType Directory -Path $RulesDir | Out-Null
}

# Flatten all .mdc files from categorized subfolders into .cursor/rules/
$mdcFiles = Get-ChildItem -Recurse -Path (Join-Path $RepoRoot "resources\rules") -Filter "*.mdc" -ErrorAction SilentlyContinue
foreach ($file in $mdcFiles) {
    $linkPath = Join-Path $RulesDir $file.Name
    if (Test-Path $linkPath) {
        Remove-Item $linkPath -Force
    }
    New-Item -ItemType SymbolicLink -Path $linkPath -Target $file.FullName | Out-Null
    Write-Host "  Linked rule: $($file.Name)"
}

function Link-Dir {
    param([string]$Name)
    $target = Join-Path $RepoRoot $Name
    $link   = Join-Path $CursorDir $Name
    if (-not (Test-Path $target)) {
        Write-Host "  Skipping: $Name/ does not exist at repo root"
        return
    }
    if (Test-Path $link) {
        Remove-Item $link -Force -Recurse
    }
    New-Item -ItemType SymbolicLink -Path $link -Target $target | Out-Null
    Write-Host "  Linked $Name/"
}

Link-Dir "agents"
Link-Dir "skills"
Link-Dir "commands"

Write-Host ""
Write-Host "Done. Cursor will now apply rules automatically and you can"
Write-Host "@mention agents/, skills/, and use /brainstorm, /write-plan,"
Write-Host "/execute-plan, /ship from commands/ in Cursor Chat."
