#!/usr/bin/env bash
# ------------------------------------------------------------------
# setup_cursor.sh
#
# Sets up symlinks so Cursor IDE auto-discovers this repo's content.
#
# What it does:
#   1. Creates a .cursor/ directory at the repo root (if absent).
#   2. Symlinks resources/rules/* into .cursor/rules/ (flattened)
#      so Cursor applies .mdc guardrails automatically.
#      Optionally filtered by category via --rules.
#   3. Symlinks the top-level agents/ directory into .cursor/agents/
#      so role agents are discoverable via @mention.
#   4. Symlinks the top-level skills/ directory into .cursor/skills/
#      so role + process skills are discoverable via @mention.
#   5. Symlinks the top-level commands/ directory into .cursor/commands/
#      so /brainstorm, /write-plan, /execute-plan, /ship are available.
#
# Usage:
#   bash scripts/setup_cursor.sh                                # all rules
#   bash scripts/setup_cursor.sh --rules code_quality,security  # subset
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

# Flatten .mdc files from categorized subfolders into .cursor/rules/.
for category_dir in "$REPO_ROOT"/resources/rules/*/; do
    [ -d "$category_dir" ] || continue
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

link_dir() {
    local name="$1"
    local target="$REPO_ROOT/$name"
    local link="$CURSOR_DIR/$name"
    if [ ! -d "$target" ]; then
        echo "  Skipping: $name/ does not exist at repo root"
        return
    fi
    if [ -L "$link" ] || [ ! -e "$link" ]; then
        ln -sfn "$target" "$link"
        echo "  Linked $name/"
    else
        echo "  WARNING: .cursor/$name/ already exists and is not a symlink. Skipping."
    fi
}

link_dir "agents"
link_dir "skills"
link_dir "commands"

echo ""
echo "Done. Cursor will now apply rules automatically and you can"
echo "@mention agents/, skills/, and use /brainstorm, /write-plan,"
echo "/execute-plan, /ship from commands/ in Cursor Chat."
