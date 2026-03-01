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
if [ "$context_size" != "null" ] && [ "$context_size" -gt 0 ]; then
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

# WCAG Accessibility Tips - Load from JSON file with 30-second caching
WCAG_JSON="$HOME/.claude/wcag-search.json"
TIP_CACHE="/tmp/claude-a11y-tip-cache"
MIN_TIP_DURATION=30  # Minimum seconds before tip changes

get_new_tip() {
    if [ -f "$WCAG_JSON" ]; then
        tip_count=$(jq '[.[].guidelines[].success_criteria[]] | length' "$WCAG_JSON")
        tip_index=$((RANDOM % tip_count))
        # Include special_cases titles when present (e.g., for criteria like 1.4.13)
        jq -r "[.[].guidelines[].success_criteria[]][$tip_index] | \"WCAG \(.ref_id) (\(.level)): \(.title) - \(.description)\" + (if .special_cases then \" \" + ([.special_cases[].title] | join(\"; \")) else \"\" end)" "$WCAG_JSON"
    else
        echo "WCAG tips file not found"
    fi
}

# Check if cached tip exists and is recent enough
if [ -f "$TIP_CACHE" ]; then
    cache_age=$(( $(date +%s) - $(stat -f %m "$TIP_CACHE" 2>/dev/null || stat -c %Y "$TIP_CACHE" 2>/dev/null) ))
    if [ "$cache_age" -lt "$MIN_TIP_DURATION" ]; then
        a11y_tip=$(cat "$TIP_CACHE")
    else
        a11y_tip=$(get_new_tip)
        echo "$a11y_tip" > "$TIP_CACHE"
    fi
else
    a11y_tip=$(get_new_tip)
    echo "$a11y_tip" > "$TIP_CACHE"
fi

# Strip embedded newlines so the tip is always a single line
a11y_tip=$(printf '%s' "$a11y_tip" | tr '\n' ' ')

# Truncate tip to fit the statusline width.
# tput cols returns 80 (non-TTY default) in Claude Code's subprocess context, and
# the statusline renderer clips lines at that display width.
# "A11Y: " (6 bytes) + tip + "…" (3 bytes UTF-8) must fit within 80 bytes:
#   6 + 70 + 3 = 79 bytes → always visible with ellipsis at 80-col clip.
# If tput reports a wider real terminal, use that minus prefix/ellipsis overhead.
term_cols=$(tput cols 2>/dev/null)
if [ "${term_cols:-0}" -gt 80 ] 2>/dev/null; then
    max_tip=$(( term_cols - 10 ))   # 6 prefix + 3 ellipsis + 1 margin
    [ "$max_tip" -gt 160 ] && max_tip=160
else
    max_tip=70
fi
if [ "${#a11y_tip}" -gt "$max_tip" ]; then
    a11y_tip="${a11y_tip:0:$max_tip}…"
fi

# Output status line: info on line 1, tip on line 2
# No ANSI color codes — Claude Code's statusline renderer counts raw bytes (not visual
# width) for truncation, so any escape sequence eats into the display budget.
# Use plain ASCII prefix — ♿ (U+267F) is "ambiguous width" and may be counted as 2
# display columns, consuming the budget before any tip text can appear.
printf "%s📁 %s │ 🤖 %s │ 🧮 %s (%d%%)\nA11Y: %s" \
    "$git_branch" \
    "$dir_name" \
    "$model_name" \
    "$token_display" \
    "$context_pct" \
    "$a11y_tip"
