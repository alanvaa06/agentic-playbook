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
#   3. Symlinks resources/agents/ into .cursor/agents/
#      so agents are discoverable via @mention.
#   4. Symlinks resources/skills/ into .cursor/skills/
#      so skills are discoverable via @mention.
#
# Usage:
#   cd <repo-root>
#   bash scripts/setup_cursor.sh
# ------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CURSOR_DIR="$REPO_ROOT/.cursor"

echo "Setting up Cursor IDE integration..."

mkdir -p "$CURSOR_DIR/rules"

# Flatten all .mdc files from categorized subfolders into .cursor/rules/
for mdc_file in "$REPO_ROOT"/resources/rules/**/*.mdc; do
    if [ -f "$mdc_file" ]; then
        filename=$(basename "$mdc_file")
        ln -sf "$mdc_file" "$CURSOR_DIR/rules/$filename"
        echo "  Linked rule: $filename"
    fi
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
