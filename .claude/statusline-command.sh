#!/usr/bin/env bash
input=$(cat)

# Colors
RESET='\033[0m'
BOLD='\033[1m'

RED='\033[38;5;196m'
ORANGE='\033[38;5;214m'
YELLOW='\033[38;5;226m'
GREEN='\033[38;5;82m'
CYAN='\033[38;5;51m'
BLUE='\033[38;5;39m'
PURPLE='\033[38;5;135m'
PINK='\033[38;5;213m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;240m'

# Extract fields
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "?"')
model=$(echo "$input" | jq -r '.model.display_name // "?"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
repo=$(echo "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
pr_num=$(echo "$input" | jq -r '.pr.number // empty')
pr_state=$(echo "$input" | jq -r '.pr.review_state // empty')
five_hr=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
session_name=$(echo "$input" | jq -r '.session_name // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

# Shorten cwd: replace home with ~
short_cwd="${cwd/#$HOME/~}"

# Build line parts
parts=()

# Session name
if [ -n "$session_name" ]; then
  parts+=("$(printf "${PURPLE}${BOLD}[%s]${RESET}" "$session_name")")
fi

# Directory
parts+=("$(printf "${CYAN}${BOLD}%s${RESET}" "$short_cwd")")

# Git repo / worktree
if [ -n "$repo" ]; then
  repo_str="$repo"
  [ -n "$git_worktree" ] && repo_str="$repo_str:$git_worktree"
  parts+=("$(printf "${YELLOW}(%s)${RESET}" "$repo_str")")
fi

# PR badge
if [ -n "$pr_num" ]; then
  case "$pr_state" in
    approved)          pr_color="$GREEN" ;;
    changes_requested) pr_color="$RED" ;;
    draft)             pr_color="$GRAY" ;;
    *)                 pr_color="$ORANGE" ;;
  esac
  parts+=("$(printf "${pr_color}PR#%s${RESET}" "$pr_num")")
fi

# Model
parts+=("$(printf "${BLUE}%s${RESET}" "$model")")

# Effort level
if [ -n "$effort" ]; then
  case "$effort" in
    low)    eff_color="$GRAY" ;;
    medium) eff_color="$GREEN" ;;
    high)   eff_color="$ORANGE" ;;
    xhigh)  eff_color="$RED" ;;
    max)    eff_color="$PINK" ;;
    *)      eff_color="$WHITE" ;;
  esac
  parts+=("$(printf "${eff_color}effort:%s${RESET}" "$effort")")
fi

# Context usage bar
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  bar_total=10
  bar_filled=$(( used_int * bar_total / 100 ))
  bar_empty=$(( bar_total - bar_filled ))
  bar=""
  if [ "$used_int" -ge 80 ]; then
    bar_color="$RED"
  elif [ "$used_int" -ge 50 ]; then
    bar_color="$ORANGE"
  else
    bar_color="$GREEN"
  fi
  for i in $(seq 1 $bar_filled); do bar="${bar}#"; done
  for i in $(seq 1 $bar_empty); do bar="${bar}-"; done
  parts+=("$(printf "${bar_color}ctx[%s]%d%%${RESET}" "$bar" "$used_int")")
fi

# Token usage
if [ -n "$total_in" ] || [ -n "$total_out" ]; then
  in_val="${total_in:-0}"
  out_val="${total_out:-0}"
  # Format as k (thousands) if >= 1000
  fmt_tokens() {
    local n="$1"
    if [ "$n" -ge 1000 ] 2>/dev/null; then
      printf "%.1fk" "$(echo "scale=1; $n / 1000" | bc)"
    else
      printf "%s" "$n"
    fi
  }
  in_fmt=$(fmt_tokens "$in_val")
  out_fmt=$(fmt_tokens "$out_val")
  parts+=("$(printf "${GRAY}tok in:${WHITE}%s${GRAY} out:${WHITE}%s${RESET}" "$in_fmt" "$out_fmt")")
fi

# Rate limit (5-hour)
if [ -n "$five_hr" ]; then
  five_int=$(printf "%.0f" "$five_hr")
  if [ "$five_int" -ge 80 ]; then
    rl_color="$RED"
  elif [ "$five_int" -ge 50 ]; then
    rl_color="$ORANGE"
  else
    rl_color="$GREEN"
  fi
  parts+=("$(printf "${rl_color}5h:%d%%${RESET}" "$five_int")")
fi

# Vim mode
if [ -n "$vim_mode" ]; then
  case "$vim_mode" in
    INSERT)   vm_color="$GREEN" ;;
    NORMAL)   vm_color="$CYAN" ;;
    VISUAL*)  vm_color="$ORANGE" ;;
    *)        vm_color="$WHITE" ;;
  esac
  parts+=("$(printf "${vm_color}${BOLD}[%s]${RESET}" "$vim_mode")")
fi

# Join with separator
sep="$(printf " ${GRAY}|${RESET} ")"
result=""
for part in "${parts[@]}"; do
  if [ -z "$result" ]; then
    result="$part"
  else
    result="${result}${sep}${part}"
  fi
done

printf "%b\n" "$result"
