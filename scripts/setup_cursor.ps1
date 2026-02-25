# ------------------------------------------------------------------
# setup_cursor.ps1
#
# Sets up symlinks so that Cursor IDE can automatically read the
# resources content as if it lived inside .cursor/.
#
# What it does:
#   1. Creates a .cursor/ directory at the repo root (if absent).
#   2. Symlinks resources/rules/* into .cursor/rules/ (flat)
#      so Cursor applies .mdc guardrails automatically.
#   3. Symlinks resources/agents/ into .cursor/agents/
#      so agents are discoverable via @mention.
#   4. Symlinks resources/skills/ into .cursor/skills/
#      so skills are discoverable via @mention.
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
$mdcFiles = Get-ChildItem -Recurse -Path (Join-Path $RepoRoot "resources\rules") -Filter "*.mdc"
foreach ($file in $mdcFiles) {
    $linkPath = Join-Path $RulesDir $file.Name
    if (Test-Path $linkPath) {
        Remove-Item $linkPath -Force
    }
    New-Item -ItemType SymbolicLink -Path $linkPath -Target $file.FullName | Out-Null
    Write-Host "  Linked rule: $($file.Name)"
}

# Symlink agents directory
$agentsLink = Join-Path $CursorDir "agents"
$agentsTarget = Join-Path $RepoRoot "resources\agents"
if (Test-Path $agentsLink) {
    Remove-Item $agentsLink -Force -Recurse
}
New-Item -ItemType SymbolicLink -Path $agentsLink -Target $agentsTarget | Out-Null
Write-Host "  Linked agents directory"

# Symlink skills directory
$skillsLink = Join-Path $CursorDir "skills"
$skillsTarget = Join-Path $RepoRoot "resources\skills"
if (Test-Path $skillsLink) {
    Remove-Item $skillsLink -Force -Recurse
}
New-Item -ItemType SymbolicLink -Path $skillsLink -Target $skillsTarget | Out-Null
Write-Host "  Linked skills directory"

Write-Host ""
Write-Host "Done! Cursor will now automatically apply rules, and you can"
Write-Host "@mention agents and skills from resources/ in Cursor Chat."
