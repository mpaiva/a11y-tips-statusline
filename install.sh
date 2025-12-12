#!/bin/bash
#
# a11y-tips-statusline installer
# https://github.com/mpaiva/a11y-tips-statusline
#
# Usage: curl -fsSL https://raw.githubusercontent.com/mpaiva/a11y-tips-statusline/main/install.sh | bash
#

set -e

REPO_URL="https://raw.githubusercontent.com/mpaiva/a11y-tips-statusline/main"
CLAUDE_DIR="$HOME/.claude"
STATUSLINE_FILE="$CLAUDE_DIR/statusline.sh"
WCAG_FILE="$CLAUDE_DIR/wcag-search.json"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║       a11y-tips-statusline installer                       ║"
echo "║       WCAG Accessibility Tips for Claude Code              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check for curl dependency
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed.${NC}"
    echo ""
    echo "Install curl using one of these commands:"
    echo "  Ubuntu:  sudo apt install curl"
    echo "  Fedora:  sudo dnf install curl"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓${NC} curl is installed"

# Check for jq dependency
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    echo ""
    echo "Install jq using one of these commands:"
    echo "  macOS:   brew install jq"
    echo "  Ubuntu:  sudo apt install jq"
    echo "  Fedora:  sudo dnf install jq"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓${NC} jq is installed"

# Create directory
mkdir -p "$CLAUDE_DIR"

# Backup existing statusline.sh if present
if [ -f "$STATUSLINE_FILE" ]; then
    BACKUP_FILE="$STATUSLINE_FILE.backup.$(date +%Y%m%d%H%M%S)"
    cp "$STATUSLINE_FILE" "$BACKUP_FILE"
    echo -e "${YELLOW}→${NC} Backed up existing statusline.sh to $(basename "$BACKUP_FILE")"
fi

# Download statusline.sh
echo -e "${YELLOW}→${NC} Downloading statusline.sh..."
curl -fsSL "$REPO_URL/statusline.sh" -o "$STATUSLINE_FILE"
chmod +x "$STATUSLINE_FILE"
echo -e "${GREEN}✓${NC} statusline.sh installed"

# Download wcag-search.json (WCAG 2.2 success criteria)
echo -e "${YELLOW}→${NC} Downloading wcag-search.json..."
curl -fsSL "$REPO_URL/wcag-search.json" -o "$WCAG_FILE"
echo -e "${GREEN}✓${NC} wcag-search.json installed"

# Update settings.json
echo -e "${YELLOW}→${NC} Updating settings.json..."

if [ -f "$SETTINGS_FILE" ]; then
    # settings.json exists - update it
    TEMP_FILE=$(mktemp)
    jq '.statusLine = {"type": "command", "command": "'"$STATUSLINE_FILE"'"}' "$SETTINGS_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$SETTINGS_FILE"
else
    # Create new settings.json
    cat > "$SETTINGS_FILE" << EOF
{
  "statusLine": {
    "type": "command",
    "command": "$STATUSLINE_FILE"
  }
}
EOF
fi

echo -e "${GREEN}✓${NC} settings.json updated"

# Verify installation
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Restart Claude Code to see WCAG accessibility tips in your statusline."
echo ""
echo "To uninstall:"
echo "  curl -fsSL $REPO_URL/uninstall.sh | bash"
echo ""
