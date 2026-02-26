#!/usr/bin/env bash
# ------------------------------------------------------------------
# setup_cursor.sh
#
# Sets up symlinks so that Cursor IDE can automatically read the
# resources content as if it lived inside .cursor/.
#
# What it does:
#   1. Creates a .cursor/ directory at the repo root (if absent).
#   2. Symlinks resources/rules/* into .cursor/rules/ (flat)
#      so Cursor applies .mdc guardrails automatically.
#      Optionally filtered by category via --rules.
#   3. Symlinks resources/agents/ into .cursor/agents/
#      so agents are discoverable via @mention.
#   4. Symlinks resources/skills/ into .cursor/skills/
#      so skills are discoverable via @mention.
#
# Usage:
#   cd <repo-root>
#
#   # Load all rule categories (default)
#   bash scripts/setup_cursor.sh
#
#   # Load only specific rule categories (comma-separated)
#   bash scripts/setup_cursor.sh --rules code_quality,security
#
# Available rule categories:
#   code_quality, evaluation, llm_standards, security
# ------------------------------------------------------------------

set -euo pipefail

RULE_FILTER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rules) RULE_FILTER="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CURSOR_DIR="$REPO_ROOT/.cursor"

echo "Setting up Cursor IDE integration..."

mkdir -p "$CURSOR_DIR/rules"

# Flatten .mdc files from categorized subfolders into .cursor/rules/
# Respects --rules filter if provided; otherwise links all categories.
for category_dir in "$REPO_ROOT"/resources/rules/*/; do
    category=$(basename "$category_dir")
    if [[ -n "$RULE_FILTER" ]] && [[ ",$RULE_FILTER," != *",$category,"* ]]; then
        echo "  Skipping category: $category"
        continue
    fi
    for mdc_file in "$category_dir"*.mdc; do
        [ -f "$mdc_file" ] || continue
        ln -sf "$mdc_file" "$CURSOR_DIR/rules/$(basename "$mdc_file")"
        echo "  Linked rule: $(basename "$mdc_file") [$category]"
    done
done

# Symlink agents directory
if [ -L "$CURSOR_DIR/agents" ] || [ ! -e "$CURSOR_DIR/agents" ]; then
    ln -sfn "$REPO_ROOT/resources/agents" "$CURSOR_DIR/agents"
    echo "  Linked agents directory"
else
    echo "  WARNING: .cursor/agents/ already exists and is not a symlink. Skipping."
fi

# Symlink skills directory
if [ -L "$CURSOR_DIR/skills" ] || [ ! -e "$CURSOR_DIR/skills" ]; then
    ln -sfn "$REPO_ROOT/resources/skills" "$CURSOR_DIR/skills"
    echo "  Linked skills directory"
else
    echo "  WARNING: .cursor/skills/ already exists and is not a symlink. Skipping."
fi

echo ""
echo "Done! Cursor will now automatically apply rules, and you can"
echo "@mention agents and skills from resources/ in Cursor Chat."
