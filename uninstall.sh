#!/bin/bash
#
# a11y-tips-statusline uninstaller
# https://github.com/mpaiva/a11y-tips-statusline
#
# Usage: curl -fsSL https://raw.githubusercontent.com/mpaiva/a11y-tips-statusline/main/uninstall.sh | bash
#

set -e

CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
STATUSLINE_FILE="$CLAUDE_DIR/statusline.sh"
WCAG_FILE="$CLAUDE_DIR/wcag-search.json"
WCAG_COMMAND="$COMMANDS_DIR/wcag.md"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║       a11y-tips-statusline uninstaller                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Remove statusline.sh
if [ -f "$STATUSLINE_FILE" ]; then
    rm "$STATUSLINE_FILE"
    echo -e "${GREEN}✓${NC} Removed statusline.sh"
else
    echo -e "${YELLOW}→${NC} statusline.sh not found (already removed?)"
fi

# Remove wcag-search.json
if [ -f "$WCAG_FILE" ]; then
    rm "$WCAG_FILE"
    echo -e "${GREEN}✓${NC} Removed wcag-search.json"
else
    echo -e "${YELLOW}→${NC} wcag-search.json not found (already removed?)"
fi

# Remove /wcag slash command
if [ -f "$WCAG_COMMAND" ]; then
    rm "$WCAG_COMMAND"
    echo -e "${GREEN}✓${NC} Removed /wcag command"
else
    echo -e "${YELLOW}→${NC} /wcag command not found (already removed?)"
fi

# Clean up old wcag-tokens directory if it exists (from previous versions)
OLD_WCAG_DIR="$CLAUDE_DIR/wcag-tokens"
if [ -d "$OLD_WCAG_DIR" ]; then
    rm -rf "$OLD_WCAG_DIR"
    echo -e "${GREEN}✓${NC} Removed legacy wcag-tokens directory"
fi

# Remove statusLine from settings.json
if [ -f "$SETTINGS_FILE" ]; then
    if command -v jq &> /dev/null; then
        TEMP_FILE=$(mktemp)
        jq 'del(.statusLine)' "$SETTINGS_FILE" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$SETTINGS_FILE"
        echo -e "${GREEN}✓${NC} Removed statusLine from settings.json"
    else
        echo -e "${YELLOW}→${NC} jq not installed - please manually remove statusLine from settings.json"
    fi
fi

# Check for backup files
BACKUPS=$(ls "$CLAUDE_DIR"/statusline.sh.backup.* 2>/dev/null || true)
if [ -n "$BACKUPS" ]; then
    echo ""
    echo -e "${YELLOW}Note:${NC} Backup files found:"
    echo "$BACKUPS"
    echo ""
    echo "To restore a backup:"
    echo "  cp <backup-file> $STATUSLINE_FILE"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Uninstall complete!${NC}"
echo ""
echo "Restart Claude Code to apply changes."
echo ""
