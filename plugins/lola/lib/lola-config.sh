# Part of Mari's AI Setup by Mari Svennevik Notland · https://github.com/Mariisno/maris-ai-setup · MIT License
# lola-config.sh — sourced by every Lola script. Loads the user's ONE config file on top
# of the defaults, so a missing file or a missing key never breaks a script.
#
#   LOLA_HOME    default ~/.lola
#   LOLA_CONFIG  default $LOLA_HOME/config.sh

LOLA_HOME="${LOLA_HOME:-$HOME/.lola}"
LOLA_CONFIG="${LOLA_CONFIG:-$LOLA_HOME/config.sh}"
LOLA_ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Defaults: identical to templates/config.example.sh.
LOLA_USER_NAME="you"
LOLA_USER_PRONOUNS=""
LOLA_LANGUAGE="English"
LOLA_LEADS=("LOLA|everything, including how you work (skills, scripts, instructions)|lola|$HOME")
LOLA_LEAD_MODEL="claude-opus-5-5"
LOLA_LEAD_EFFORT="high"
LOLA_SPECIALIST_SESSION="engine-room"
LOLA_SPECIALIST_CWD="$HOME"
LOLA_SWEEP_SPECIALISTS=1
LOLA_ACCOUNTS=("default|$HOME/.claude|")
LOLA_DEFAULT_ACCOUNT="default"
LOLA_INBOX_DIR="$LOLA_HOME/inbox"
LOLA_ASSIGNMENT_DIR="$LOLA_HOME/assignments"
LOLA_NOTES_DIR="$LOLA_HOME/notes"
LOLA_NOTES_STYLE="markdown"
LOLA_QUEUE_FILE=""
LOLA_SESSION_LOG_DIR=""
LOLA_INSIGHT_DIR=""
LOLA_HYGIENE_FILE=""
LOLA_METHOD_LOG=""
LOLA_DIG_GUARD_EVERY=4
LOLA_SEND_MAX_CHARS=600
LOLA_INBOX_WARN_KB=60
LOLA_RECEIPT_AFTER_MIN=10
LOLA_GITHUB_USER=""
LOLA_LABEL_OPTION="@label"
LOLA_ROLES_DIR=""
LOLA_SPECIALIST_CAP=5
LOLA_USAGE_DIR=""
LOLA_PROJECT_DIRS=()

# shellcheck source=/dev/null
[ -f "$LOLA_CONFIG" ] && . "$LOLA_CONFIG"

# The tmux option that holds a pane's label (its identity). It goes into tmux formats and
# set-option calls, so only @ plus letters, digits, - and _ are accepted.
case "$LOLA_LABEL_OPTION" in
  @|@*[!A-Za-z0-9_-]*|[!@]*|"")
    echo "lola: LOLA_LABEL_OPTION='$LOLA_LABEL_OPTION' is not a tmux user option (@name). Using @label." >&2
    LOLA_LABEL_OPTION="@label" ;;
esac

# Paths that hang off the notes folder follow it unless set explicitly.
LOLA_QUEUE_FILE="${LOLA_QUEUE_FILE:-$LOLA_NOTES_DIR/Waiting on you.md}"
LOLA_SESSION_LOG_DIR="${LOLA_SESSION_LOG_DIR:-$LOLA_NOTES_DIR/session-log}"
LOLA_INSIGHT_DIR="${LOLA_INSIGHT_DIR:-$LOLA_NOTES_DIR/insight}"
LOLA_HYGIENE_FILE="${LOLA_HYGIENE_FILE:-$LOLA_NOTES_DIR/Hygiene jobs.md}"
LOLA_METHOD_LOG="${LOLA_METHOD_LOG:-$LOLA_NOTES_DIR/Method log.md}"
# The role catalogue ships with the plugin; point LOLA_ROLES_DIR at a copy to edit it freely.
LOLA_ROLES_DIR="${LOLA_ROLES_DIR:-$LOLA_ROOT/roles}"
# Where the status line writes its usage snapshot, for quota.sh.
LOLA_USAGE_DIR="${LOLA_USAGE_DIR:-$LOLA_HOME/usage}"

# lola_lead_names — one lead NAME per line.
lola_lead_names() {
  local row
  for row in "${LOLA_LEADS[@]}"; do printf '%s\n' "${row%%|*}"; done
}

# lola_is_lead <label> — true when the label's first word is a configured lead NAME.
lola_is_lead() {
  local first="${1%% *}" name
  while IFS= read -r name; do
    [ -n "$name" ] && [ "$first" = "$name" ] && return 0
  done < <(lola_lead_names)
  return 1
}

# lola_account <name> — prints "config dir|plan label" for the account, or fails.
lola_account() {
  local row
  for row in "${LOLA_ACCOUNTS[@]}"; do
    if [ "${row%%|*}" = "$1" ]; then printf '%s\n' "${row#*|}"; return 0; fi
  done
  return 1
}

# lola_account_for_dir <config dir> — prints the account NAME whose config dir matches
# (an empty or unset CLAUDE_CONFIG_DIR means ~/.claude). Fails when no row matches.
lola_account_for_dir() {
  local want="${1:-$HOME/.claude}" row dir
  want="${want%/}"
  for row in "${LOLA_ACCOUNTS[@]}"; do
    dir="${row#*|}"; dir="${dir%%|*}"; dir="${dir%/}"
    if [ "$dir" = "$want" ]; then printf '%s\n' "${row%%|*}"; return 0; fi
  done
  return 1
}

# lola_role_meta <file> <key> — a value from the first line of a role or domain file:
#   <!-- machine: role=UI model=claude-opus-5-5 effort=high -->
lola_role_meta() {
  sed -n '1s/.*machine:\(.*\)-->.*/\1/p' "$1" | tr ' ' '\n' | sed -n "s/^$2=//p" | head -1
}

# Ownership. Lola marks every tmux session and window it creates with the user option @lola,
# and only ever relabels, types into or reconfigures what carries the mark. A session of
# yours that happens to share a name is left alone. Targets use "=" for an exact match:
# without it, tmux also matches by prefix, so "lola" would hit a session called "lola-old".
# set-option and show-options read -t as a pane target, so a session is written "=name:".
lola_owns_session() { [ "$(tmux show-options -qv -t "=$1:" @lola 2>/dev/null)" = 1 ]; }
lola_owns_window()  { [ "$(tmux show-options -qv -w -t "=$1:=$2" @lola 2>/dev/null)" = 1 ]; }
lola_mark_session() { tmux set-option -t "=$1:" @lola 1; }
lola_mark_window()  { tmux set-option -w -t "=$1:=$2" @lola 1; }

# lola_is_shell <command> — true for an idle login or interactive shell. LOLA_SHELLS is the
# one list: lola_export hands it to the python helpers, so they never keep their own.
LOLA_SHELLS="zsh -zsh bash -bash fish -fish sh -sh login"
lola_is_shell() {
  case " $LOLA_SHELLS " in *" $1 "*) [ -n "$1" ] ;; *) return 1 ;; esac
}

# lola_shows_menu — reads a pane capture on stdin; true when a menu or prompt is open.
# The rule is structural: a «❯» line right under a ─ rule is the composer, and a pane
# showing its composer is at the prompt, so nothing on screen is a menu. That matters
# because the scrollback holds sent messages («❯ 1. yes, run it») and quoted hints that
# look like menus. Without a composer, menu hints or a «❯ 1.» + «2.» list mean a menu.
lola_shows_menu() {
  awk '
    { l[NR] = $0 }
    END {
      for (i = NR; i > 1; i--) if (l[i] ~ /^❯( |$)/ && l[i-1] ~ /^──────/) exit 1
      for (i = 1; i <= NR; i++) {
        if (l[i] ~ /Do you want to proceed\?|Enter to select|Enter to confirm|Esc to cancel|↑\/↓ to navigate/) exit 0
        if (l[i] ~ /^[ \t]*[│|]?[ \t]*❯[ \t]*1\.[ \t]/) one = 1
        if (l[i] ~ /^[ \t]*[│|]?[ \t]*2\.[ \t]/) two = 1
      }
      exit !(one && two)
    }'
}

# lola_lock <name> [seconds] — take <LOLA_HOME>/.<name>.lock, a directory (mkdir is atomic on
# every filesystem). A lock older than two minutes is a crash's leftover and is taken over.
# Waits up to [seconds] (default 60); fails with 1 when the lock is still held. Pair with
# lola_unlock <name>, and put it in a trap so a failing script never leaves the lock behind.
lola_lock() {
  local lock="$LOLA_HOME/.$1.lock" wait="${2:-60}" i=0
  mkdir -p "$LOLA_HOME" 2>/dev/null
  while ! mkdir "$lock" 2>/dev/null; do
    if [ -n "$(find "$lock" -maxdepth 0 -mmin +2 2>/dev/null)" ]; then rmdir "$lock" 2>/dev/null; continue; fi
    i=$((i+1)); [ "$i" -lt "$wait" ] || return 1
    sleep 1
  done
}
lola_unlock() { rmdir "$LOLA_HOME/.$1.lock" 2>/dev/null; }

# lola_unsent_text — reads a pane capture on stdin; prints what stands typed but unsent in
# the composer (the «❯» line right under a ─ rule), or nothing. «/exit» counts: a specialist
# that typed /exit and never pressed Enter is finished and still alive. The dim placeholder
# («Try "…"») is not a message. A pane in a menu has no composer, so it prints nothing.
lola_unsent_text() {
  awk '
    { l[NR] = $0 }
    END {
      for (i = NR; i > 1; i--) if (l[i] ~ /^❯( |$)/ && l[i-1] ~ /^──────/) {
        t = l[i]; sub(/^❯[ \t]*/, "", t); sub(/[ \t]+$/, "", t)
        if (t ~ /^Try "/) t = ""
        if (t != "") print t
        exit
      }
    }'
}

# lola_export — export the config for child processes (python helpers, hooks).
lola_export() {
  export LOLA_HOME LOLA_CONFIG LOLA_ROOT LOLA_USER_NAME LOLA_USER_PRONOUNS LOLA_LANGUAGE LOLA_LEAD_MODEL \
    LOLA_LEAD_EFFORT LOLA_SPECIALIST_SESSION LOLA_SPECIALIST_CWD LOLA_SWEEP_SPECIALISTS \
    LOLA_DEFAULT_ACCOUNT LOLA_INBOX_DIR LOLA_ASSIGNMENT_DIR LOLA_NOTES_DIR LOLA_NOTES_STYLE \
    LOLA_QUEUE_FILE LOLA_SESSION_LOG_DIR LOLA_INSIGHT_DIR LOLA_HYGIENE_FILE LOLA_METHOD_LOG \
    LOLA_DIG_GUARD_EVERY LOLA_SEND_MAX_CHARS LOLA_INBOX_WARN_KB LOLA_RECEIPT_AFTER_MIN LOLA_GITHUB_USER LOLA_SHELLS LOLA_LABEL_OPTION \
    LOLA_ROLES_DIR LOLA_SPECIALIST_CAP LOLA_USAGE_DIR
  LOLA_LEADS_LINES="$(printf '%s\n' "${LOLA_LEADS[@]}")"
  LOLA_ACCOUNTS_LINES="$(printf '%s\n' "${LOLA_ACCOUNTS[@]}")"
  LOLA_PROJECT_DIRS_LINES="$(printf '%s\n' ${LOLA_PROJECT_DIRS[@]+"${LOLA_PROJECT_DIRS[@]}"})"
  export LOLA_LEADS_LINES LOLA_ACCOUNTS_LINES LOLA_PROJECT_DIRS_LINES
}
