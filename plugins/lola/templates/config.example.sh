# Lola configuration — the ONE file that holds everything personal.
#
# `lola-init` copies this to ~/.lola/config.sh (or $LOLA_CONFIG). Every script and skill
# reads from there; nothing else in the plugin needs editing. The defaults work as-is for a
# new user with one Claude account and no Obsidian. It is a bash file: keep it to plain
# assignments.

# --- You -------------------------------------------------------------------------------
# How leads and specialists refer to you in notes and reports.
LOLA_USER_NAME="you"
# The language sessions write notes, reports and receipts in.
LOLA_LANGUAGE="English"

# --- Leads -----------------------------------------------------------------------------
# One lead per domain. Format: "NAME|domain|tmux session|working directory".
# NAME is what goes on the pane label; the dig guard and the watch report recognise a lead
# by it. Start with one; add more when one lead has more than it can route.
LOLA_LEADS=(
  "LOLA|everything, including how you work (skills, scripts, instructions)|lola|$HOME"
  # "LOLA-WEB|the web app: issues, code reviews, releases|web|$HOME/code/web-app"
)
LOLA_LEAD_MODEL="claude-opus-5-5"
LOLA_LEAD_EFFORT="high"

# --- Specialists -----------------------------------------------------------------------
# All specialist panes live in this tmux session. It is detached on purpose: you look at
# leads, not specialists.
LOLA_SPECIALIST_SESSION="engine-room"
# Working directory new specialist panes start in.
LOLA_SPECIALIST_CWD="$HOME"
# Move specialist windows that ended up in a lead's session over to the specialist
# session when `lola-revive` runs (1 = on, 0 = off).
LOLA_SWEEP_SPECIALISTS=1

# --- Pane labels -----------------------------------------------------------------------
# The tmux user option that holds each pane's label: its identity. Lola sets it on the panes
# it starts and reads it everywhere else. Keep @label unless your panes already carry another
# option. Example: a setup whose panes are named with @navn sets
#   LOLA_LABEL_OPTION="@navn"
# Only @ followed by letters, digits, - and _ is accepted; anything else falls back to @label.
LOLA_LABEL_OPTION="@label"

# --- Accounts --------------------------------------------------------------------------
# One row per Claude account you run sessions on. Format: "name|config dir|plan label".
# The plan label is the plan name Claude Code's startup banner shows after the effort.
# Leave it empty to skip the plan check when spawning.
LOLA_ACCOUNTS=(
  "default|$HOME/.claude|"
)
# Account a specialist starts on unless `LOLA_ACCOUNT=<name>` is set for the spawn.
LOLA_DEFAULT_ACCOUNT="default"

# --- Files -----------------------------------------------------------------------------
# Lola's own state: inboxes and assignment files.
LOLA_INBOX_DIR="$LOLA_HOME/inbox"            # one <LEAD>.md per lead
LOLA_ASSIGNMENT_DIR="$LOLA_HOME/assignments" # long assignments land here as files

# --- Notes system ----------------------------------------------------------------------
# Any folder of Markdown files works. Point it at an Obsidian vault if you use one.
LOLA_NOTES_DIR="$LOLA_HOME/notes"
# "markdown" writes [text](file.md) links; "obsidian" writes [[wikilinks]].
LOLA_NOTES_STYLE="markdown"
# The queue: what is waiting on YOUR answer. Not your task list.
LOLA_QUEUE_FILE="$LOLA_NOTES_DIR/Waiting on you.md"
# Daily session log, one file per day (YYYY-MM-DD.md). Tomorrow's "yesterday" reads it.
LOLA_SESSION_LOG_DIR="$LOLA_NOTES_DIR/session-log"
# Where HARVEST writes daily insight logs and weekly "threads and connections".
LOLA_INSIGHT_DIR="$LOLA_NOTES_DIR/insight"
# Optional tables the watch report checks if the files exist.
LOLA_HYGIENE_FILE="$LOLA_NOTES_DIR/Hygiene jobs.md"
LOLA_METHOD_LOG="$LOLA_NOTES_DIR/Method log.md"

# --- Guards and limits -----------------------------------------------------------------
# The dig guard warns a lead after every N reading calls in one turn (rule four).
LOLA_DIG_GUARD_EVERY=4
# Messages longer than this go to an assignment file; the pane only gets a pointer.
LOLA_SEND_MAX_CHARS=600
# Inbox files larger than this are flagged by the watch report.
LOLA_INBOX_WARN_KB=60
# GitHub user whose open pull requests the watch report lists. Empty = skip.
LOLA_GITHUB_USER=""

# --- Role catalogue --------------------------------------------------------------------
# `lola-spawn --role <group/role> --domain <domain>` reads role and domain files from here.
# The catalogue ships with the plugin (plugins/lola/roles). To edit roles or add domains
# of your own, copy that folder somewhere and point at the copy:
#   LOLA_ROLES_DIR="$HOME/.lola/roles"
LOLA_ROLES_DIR=""
# How many specialists one lead may have alive at once. `lola-spawn` refuses the next one
# past the cap (LOLA_CAP=0 on the command line overrides for one spawn). 0 = no cap.
LOLA_SPECIALIST_CAP=5

# --- Usage and maintenance -------------------------------------------------------------
# The status line writes a usage snapshot here; scripts/quota.sh reads it.
LOLA_USAGE_DIR="$LOLA_HOME/usage"
# The status line's cat, Sussi, is Mari's signature. 0 leaves her out.
STATUSLINE_PERSONAL=1
# Folders scripts/maintenance.sh sweeps for stale git locks and extra worktrees. Empty = skip.
LOLA_PROJECT_DIRS=(
  # "$HOME/code"
)
