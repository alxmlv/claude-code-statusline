#!/bin/bash
# Claude Code Status Line
# Clean, informative status line with context progress bar
# Works in light and dark terminals

# Read JSON input from Claude Code
input=$(cat)

# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

BAR_WIDTH=8                     # Width of progress bar
BAR_FILLED="█"                  # Filled character (alternatives: ━ ■ ●)
BAR_EMPTY="░"                   # Empty character (alternatives: ─ □ ○)
CONTEXT_WARNING=60              # Yellow above this %
CONTEXT_DANGER=80               # Red above this %

# ══════════════════════════════════════════════════════════════════════════════
# COLORS - Work in both light & dark terminals
# ══════════════════════════════════════════════════════════════════════════════

R='\033[0m'           # Reset
C='\033[36m'          # Cyan - directory
G='\033[32m'          # Green - git clean / low context
Y='\033[33m'          # Yellow - model / warning
M='\033[35m'          # Magenta - context percentage
B='\033[34m'          # Blue - modifications
D='\033[31m'          # Red - danger / deletions
DIM='\033[90m'        # Dim - separators

# ══════════════════════════════════════════════════════════════════════════════
# PARSE JSON
# ══════════════════════════════════════════════════════════════════════════════

model=$(echo "$input" | jq -r '.model.display_name // "?"')
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // "~"')
added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Get short directory name
dir=$(basename "$cwd")
[[ ${#dir} -gt 18 ]] && dir="…${dir: -17}"

# ══════════════════════════════════════════════════════════════════════════════
# CONTEXT CALCULATION
# ══════════════════════════════════════════════════════════════════════════════

# Get context percentage directly from the JSON input
context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
[[ ! "$context_pct" =~ ^[0-9]+$ ]] && context_pct=0

# Build progress bar with color based on usage
build_bar() {
    local pct=$1
    local width=$BAR_WIDTH
    local filled=$((pct * width / 100))
    [[ $filled -gt $width ]] && filled=$width
    local empty=$((width - filled))
    
    # Choose color based on percentage
    local color
    if [[ $pct -ge $CONTEXT_DANGER ]]; then
        color="$D"  # Red
    elif [[ $pct -ge $CONTEXT_WARNING ]]; then
        color="$Y"  # Yellow
    else
        color="$G"  # Green
    fi
    
    # Build bar string
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="$BAR_FILLED"; done
    for ((i=0; i<empty; i++)); do bar+="$BAR_EMPTY"; done
    
    # Return the bar (caller uses command substitution)
    printf '%b%s%b %b%d%%%b' "$color" "$bar" "$R" "$color" "$pct" "$R"
}

context_bar=$(build_bar $context_pct)

# ══════════════════════════════════════════════════════════════════════════════
# GIT INFO
# ══════════════════════════════════════════════════════════════════════════════

git_part=""
if git -C "$cwd" rev-parse --git-dir &>/dev/null; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    if [[ -n "$branch" ]]; then
        [[ ${#branch} -gt 12 ]] && branch="${branch:0:11}…"
        
        if git -C "$cwd" diff --quiet &>/dev/null && git -C "$cwd" diff --cached --quiet &>/dev/null; then
            git_part="${G}${branch}${R}"
        else
            staged=$(git -C "$cwd" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
            unstaged=$(git -C "$cwd" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
            git_part="${Y}${branch}${R}"
            [[ $staged -gt 0 ]] && git_part+=" ${G}●${staged}${R}"
            [[ $unstaged -gt 0 ]] && git_part+=" ${B}○${unstaged}${R}"
        fi
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# SESSION STATS
# ══════════════════════════════════════════════════════════════════════════════

stats=""
if [[ $added -gt 0 || $removed -gt 0 ]]; then
    [[ $added -gt 0 ]] && stats="${G}+${added}${R}"
    if [[ $removed -gt 0 ]]; then
        [[ -n "$stats" ]] && stats+=" "
        stats+="${D}-${removed}${R}"
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# BUILD OUTPUT
# ══════════════════════════════════════════════════════════════════════════════

sep="${DIM}│${R}"
out="📁 ${C}${dir}${R}"

[[ -n "$git_part" ]] && out+=" ${sep} 🌿 ${git_part}"
out+=" ${sep} 🤖 ${Y}${model}${R}"
out+=" ${sep} 🧠 ${context_bar}"
[[ -n "$stats" ]] && out+=" ${sep} ${stats}"

printf '%b' "$out"
