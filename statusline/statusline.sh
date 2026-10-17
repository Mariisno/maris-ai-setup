#!/bin/bash
# Part of Mari's AI Setup by Mari Svennevik Notland 🌸 · https://github.com/Mariisno/maris-ai-setup · MIT License
# A Claude Code status line
# Line 1: greeting · project · git branch · model + effort · Sussi the cat
# Line 2: meters for context, the 5-hour limit and the weekly limit
# Claude Code runs this and shows whatever it prints at the bottom of the window.
# Reads ~/.lola/config.sh (or $LOLA_CONFIG) for your name; works without it.
# Nothing leaves your machine: no network calls, one local usage snapshot for quota.sh.
#
#   STATUSLINE_PERSONAL=0   turns off my signature, Sussi the cat (env or config.sh)

case "${1:-}" in
  --version|-v) echo "statusline.sh, part of Mari's AI Setup by Mari Svennevik Notland"; exit 0 ;;
  --help|-h)
    cat <<'EOF'
statusline.sh: a cozy two-line status line for Claude Code
Part of Mari's AI Setup by Mari Svennevik Notland 🌸 · https://github.com/Mariisno/maris-ai-setup

Claude Code pipes its session JSON to stdin, and the script prints two lines.

  LOLA_USER_NAME           your name in the greeting, set in ~/.lola/config.sh
  STATUSLINE_PERSONAL=0    turns off my signature, Sussi the cat

  --help     this text
  --version  where it comes from
EOF
    exit 0 ;;
esac

input=$(cat)

# --- Config (optional) -----------------------------------------------------------------
LOLA_HOME="${LOLA_HOME:-$HOME/.lola}"; LOLA_CONFIG="${LOLA_CONFIG:-$LOLA_HOME/config.sh}"
LOLA_USER_NAME="you"; LOLA_USAGE_DIR=""
# shellcheck source=/dev/null
[ -f "$LOLA_CONFIG" ] && . "$LOLA_CONFIG" 2>/dev/null
LOLA_USAGE_DIR="${LOLA_USAGE_DIR:-$LOLA_HOME/usage}"; mkdir -p "$LOLA_USAGE_DIR" 2>/dev/null
STATUSLINE_PERSONAL="${STATUSLINE_PERSONAL:-1}"
name=""; [ "$LOLA_USER_NAME" != "you" ] && [ -n "$LOLA_USER_NAME" ] && name=", $LOLA_USER_NAME"

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
project=$(basename "${dir:-~}")

# Greeting that follows the clock. Edit the four strings to taste (or to your language).
hour=$((10#$(date +%H)))
if   [ "$hour" -ge 6 ]  && [ "$hour" -lt 10 ]; then greeting="Good morning$name ☀️"
elif [ "$hour" -ge 10 ] && [ "$hour" -lt 17 ]; then greeting="Good day$name 🌤️"
elif [ "$hour" -ge 17 ] && [ "$hour" -lt 23 ]; then greeting="Good evening$name 🌙"
else greeting="Good night$name ✨"
fi

# Effort level (how deeply Claude thinks), shown next to the model name.
# Effort below high is shown in peach, so an accidental downgrade is visible.
effort=$(echo "$input" | jq -r '.effort.level // empty')
effort_tag=""
if [ -n "$effort" ]; then
  case "$effort" in high|xhigh|max) effort_tag=" · $effort" ;;
                   *) effort_tag=" · \033[38;5;223m$effort\033[38;5;245m" ;; esac
fi

# One usage snapshot of the session this runs in, for scripts/quota.sh. Written only when
# the weekly window is present, so a render without it never blanks a good number.
if [ -n "$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)" ]; then
  printf '%s' "$input" | jq -c '{rate_limits, context_window, capturedAt: now}' \
    > "$LOLA_USAGE_DIR/snapshot.json.tmp" 2>/dev/null && mv "$LOLA_USAGE_DIR/snapshot.json.tmp" "$LOLA_USAGE_DIR/snapshot.json"
fi

# 🐈 Sussi, the cat my design system is named after, trots across the line one step per
# second while Claude works. At night she sleeps. STATUSLINE_PERSONAL=0 leaves her out.
track_len=6
cat_track=""
if [ "$STATUSLINE_PERSONAL" = "0" ]; then :
elif [ "$hour" -ge 23 ] || [ "$hour" -lt 6 ]; then cat_track="🐈💤"
else
  pos=$(( track_len - 1 - ($(date +%s) % track_len) ))
  for ((i = 0; i < track_len; i++)); do
    if   [ "$i" -eq "$pos" ];        then cat_track+="🐈"
    elif [ "$i" -eq $((pos + 2)) ];  then cat_track+="🐾"
    else cat_track+="  "
    fi
  done
fi

# Git branch, with * when there are uncommitted changes
branch=""
if [ -n "$dir" ] && git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
  [ -n "$(git -C "$dir" status --porcelain 2>/dev/null | head -1)" ] && branch="$branch*"
  branch="  \033[38;5;183m$branch\033[0m"
fi

# Pastel palette (256-colour, made for dark themes)
PINK=218; BLUE=117; LAVENDER=183; MINT=151; PEACH=223; CORAL=209; DIM=245; FAINT=242

printf "\033[38;5;${PINK}m%s\033[0m  \033[38;5;${BLUE}m%s\033[0m%b  \033[38;5;${DIM}m%s%b\033[0m%s\n" \
  "$greeting" "$project" "$branch" "$model" "$effort_tag" "${cat_track:+  $cat_track}"

# ── Line 2: soft dot meters ───────────────────────────────────────────────────
# Mint under 50 %, peach from 50 %, coral from 80 %.
tone() { if [ "$1" -ge 80 ]; then echo $CORAL; elif [ "$1" -ge 50 ]; then echo $PEACH; else echo $MINT; fi; }
dots() { local p=$1 w=10 fill c; c=$(tone "$p")
  fill=$(( (p * w + 50) / 100 )); [ "$fill" -gt "$w" ] && fill=$w
  printf "\033[38;5;%sm" "$c";      for ((i = 0; i < fill; i++)); do printf "●"; done
  printf "\033[38;5;%sm" "$FAINT";  for ((i = fill; i < w; i++)); do printf "○"; done
  printf "\033[0m"; }
meter() { local c; c=$(tone "$2")
  printf "\033[38;5;%sm%s\033[0m %s \033[38;5;%sm%s%%\033[0m" "$DIM" "$1" "$(dots "$2")" "$c" "$2"
  [ -n "${3:-}" ] && printf " \033[38;5;%sm· %s\033[0m" "$LAVENDER" "$3"; }
# Times can arrive with decimals, and $((…)) only takes whole numbers.
until_reset() { local s=$(( ${1%%.*} - $(date +%s) )); [ "$s" -lt 0 ] && s=0; printf "%dh %02dm" $((s / 3600)) $((s % 3600 / 60)); }
reset_day() { date -r "${1%%.*}" '+%a %H:%M' 2>/dev/null || date -d "@${1%%.*}" '+%a %H:%M'; }
# Percentages can arrive as decimals (33.3). Rounds in plain bash, because printf %.0f
# fails under a locale with a decimal comma.
num() { local v=${1:-0} i f; i=${v%%.*}; f=${v#"$i"}; f=${f#.}
  [ "${f:0:1}" -ge 5 ] 2>/dev/null && i=$((${i:-0} + 1)); printf "%s" "${i:-0}"; }

parts=()
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
[ -n "$ctx_used" ] && parts+=("$(meter ctx "$(num "$ctx_used")")")
h5=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$h5" ]; then r=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty'); parts+=("$(meter 5h "$(num "$h5")" "${r:+$(until_reset "$r")}")"); fi
d7=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$d7" ]; then r=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty'); parts+=("$(meter 7d "$(num "$d7")" "${r:+$(reset_day "$r")}")"); fi
if [ ${#parts[@]} -gt 0 ]; then
  out="${parts[0]}"; for m in "${parts[@]:1}"; do out="$out   $m"; done
  printf "%s" "$out"
fi
