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

# Build status line with a11y_tip on its own line
# Yellow color (using 256-color mode: color 178 is close to rgb(191,153,0))
a11y_color=$'\033[38;5;178m'
reset_color=$'\033[0m'

# Word-wrap tip to terminal width so full content is visible across lines
# stty size </dev/tty reads the real terminal dimensions even in subprocesses
# (COLUMNS is a shell variable not inherited by subprocesses; tput fails without a TTY)
term_width=$(stty size </dev/tty 2>/dev/null | cut -d' ' -f2)
width_known=false
if [ -n "$term_width" ] && [ "$term_width" -ge 10 ] 2>/dev/null; then
    width_known=true
else
    # Fallback: COLUMNS is reliable when set (interactive shell); tput/echo 80 are not.
    term_width=$COLUMNS
    [ -n "$COLUMNS" ] && width_known=true
    if [ -z "$term_width" ]; then
        term_width=$(tput cols 2>/dev/null || echo 80)
    fi
fi

# Only show the resize hint when we have a confirmed narrow width from stty or COLUMNS.
# Skipping the hint when width is unknown avoids false positives in subprocess contexts
# where stty fails and tput/COLUMNS both return 80 as a default.
MIN_WIDTH_FOR_TIPS=120
if [ "$width_known" = true ] && [ "$term_width" -lt "$MIN_WIDTH_FOR_TIPS" ] 2>/dev/null; then
    a11y_tip="↔ Widen terminal to ${MIN_WIDTH_FOR_TIPS}+ cols to see WCAG accessibility tips"
fi

wrapped_tip=$(echo "$a11y_tip" | fold -s -w "$term_width")

# Apply color to the wrapped tip
colored_tip="${a11y_color}${wrapped_tip}${reset_color}"

printf "%s📁 %s │ 🤖 %s │ 🧮 %s (%d%%)\n%s" \
    "$git_branch" \
    "$dir_name" \
    "$model_name" \
    "$token_display" \
    "$context_pct" \
    "$colored_tip"
