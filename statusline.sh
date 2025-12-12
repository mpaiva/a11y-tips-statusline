#!/bin/bash
#
# a11y-tips-statusline - WCAG Accessibility Tips for Claude Code
# https://github.com/mpaiva/a11y-tips-statusline
#
# Displays rotating WCAG accessibility guidelines in your Claude Code statusline
#

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
model_name=$(echo "$input" | jq -r '.model.display_name')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size')

# Get current directory name
dir_name=$(basename "$current_dir")

# Get git branch if in a git repo (skip optional locks)
git_branch=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        git_branch="🌿 $branch │ "
    fi
fi

# Calculate token usage and percentage
total_tokens=$((total_input + total_output))
if [ "$context_size" -gt 0 ]; then
    context_pct=$((total_tokens * 100 / context_size))
else
    context_pct=0
fi

# Format token display with K suffix for readability
if [ "$total_tokens" -ge 1000 ]; then
    token_display="$((total_tokens / 1000))K"
else
    token_display="$total_tokens"
fi

# WCAG Accessibility Tips - Load from JSON file
WCAG_JSON="$HOME/.claude/wcag-search.json"

if [ -f "$WCAG_JSON" ]; then
    # Extract all success criteria with ref_id, title, level, and description
    # Format: "WCAG X.X.X (Level): Title - Description"
    tip_count=$(jq '[.[].guidelines[].success_criteria[]] | length' "$WCAG_JSON")
    tip_index=$((RANDOM % tip_count))

    # Get the success criterion at the calculated index and format it
    a11y_tip=$(jq -r "[.[].guidelines[].success_criteria[]][$tip_index] | \"WCAG \(.ref_id) (\(.level)): \(.title) - \(.description)\"" "$WCAG_JSON")
else
    a11y_tip="WCAG tips file not found"
fi

# Build status line with a11y_tip on its own line
# Yellow color (using 256-color mode: color 178 is close to rgb(191,153,0))
a11y_color=$'\033[38;5;178m'
reset_color=$'\033[0m'

# Embed color codes directly in the tip text
colored_tip="${a11y_color}${a11y_tip}${reset_color}"

printf "%s📁 %s │ 🤖 %s │ 🧮 %s (%d%%)\n%s" \
    "$git_branch" \
    "$dir_name" \
    "$model_name" \
    "$token_display" \
    "$context_pct" \
    "$colored_tip"
