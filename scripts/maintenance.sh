#!/usr/bin/env bash
# Part of Mari's AI Setup by Mari Svennevik Notland · https://github.com/Mariisno/maris-ai-setup · MIT License
# maintenance.sh — one check for updates and upkeep. Read-only: it changes nothing.
# Run it at the start of a day, or let WATCH run it weekly.
#   1 Claude Code: installed vs newest, and panes still on an older version
#   2 plugins: what changed since the last check, marketplaces without auto-update
#   3 scheduled rounds (WATCH, HARVEST) about to expire: <LOLA_HOME>/cron-expiry.txt, "NAME YYYY-MM-DD" per line
#   4 inboxes that have grown heavy
#   5 leftovers: stale git locks and extra worktrees in LOLA_PROJECT_DIRS, old backup files in the config dir
#   6 quota per account
set -u
here="$(cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=../plugins/lola/lib/lola-config.sh
. "$here/../plugins/lola/lib/lola-config.sh"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
S="$LOLA_HOME/maintenance"; mkdir -p "$S"
red=0; yellow=0
r(){ printf '🔴 %s\n' "$1"; red=$((red+1)); }
y(){ printf '🟡 %s\n' "$1"; yellow=$((yellow+1)); }
o(){ printf '✓  %s\n' "$1"; }

# 1 · Claude Code
inst="$(claude --version 2>/dev/null | awk '{print $1}')"
# npm's own timeout: `timeout` is not on macOS.
newest="$(npm view @anthropic-ai/claude-code version --fetch-timeout=8000 --fetch-retries=0 2>/dev/null || true)"
if [ -n "$newest" ] && [ "$newest" != "$inst" ]; then y "CLI $inst installed, $newest available (updates itself at the next start)"; else o "CLI ${inst:-?}${newest:+ (newest)}"; fi
old="$(tmux list-panes -a -F "#{pane_current_command} #{${LOLA_LABEL_OPTION}}" 2>/dev/null | awk -v v="$inst" '$1 ~ /^[0-9]+\./ && $1 != v {print "   " $0}')"
if [ -n "$old" ]; then y "panes on an older CLI (they get the new one at restart):"; echo "$old"; else o "all panes on CLI ${inst:-?}"; fi

# 2 · Plugins
if [ -f "$CLAUDE_DIR/plugins/installed_plugins.json" ]; then
CLAUDE_DIR="$CLAUDE_DIR" python3 -I - "$S/plugins.txt" <<'PY'
import json, sys, os
snap = sys.argv[1]; cd = os.environ["CLAUDE_DIR"]
d = json.load(open(os.path.join(cd, 'plugins/installed_plugins.json')))
now = {k: (v[0].get('version') if isinstance(v, list) and v else None) for k, v in d.get('plugins', {}).items()}
old = {}
if os.path.exists(snap):
    for l in open(snap):
        k, _, v = l.strip().partition(' '); old[k] = v
ch = [f"{k}: {old.get(k,'new')} → {v}" for k, v in sorted(now.items()) if old.get(k) != str(v)]
if old and ch:
    print("🟡 plugins changed since last check — read what is new (and /reload-plugins in the leads):")
    for c in ch: print("   " + c)
elif not old: print(f"✓  plugin baseline saved ({len(now)} plugins)")
else: print("✓  no plugin changes since last check")
open(snap, 'w').write(''.join(f"{k} {v}\n" for k, v in sorted(now.items())))
mp = os.path.join(cd, 'plugins/known_marketplaces.json')
if os.path.exists(mp):
    m = json.load(open(mp))
    off = [k for k, v in m.items() if isinstance(v, dict) and not v.get('autoUpdate')]
    if off: print("🟡 marketplaces without autoUpdate: " + ", ".join(off))
PY
else o "no plugins installed"; fi

# 3 · Scheduled rounds
today=$(date +%s); exp="$LOLA_HOME/cron-expiry.txt"
if [ -f "$exp" ]; then
  while read -r name day; do
    [ -n "$name" ] || continue
    d=$(( ( $(date -j -f %Y-%m-%d "$day" +%s 2>/dev/null || date -d "$day" +%s) - today ) / 86400 ))
    if [ "$d" -le 0 ]; then r "$name's schedule expired $day — recreate it (the watch/harvest skill says how)"
    elif [ "$d" -le 2 ]; then y "$name's schedule expires $day (in $d d)"
    else o "$name's schedule runs until $day"; fi
    tmux list-panes -a -F "#{${LOLA_LABEL_OPTION}}" 2>/dev/null | grep -q "^$name" || r "no $name pane is running"
  done < "$exp"
else o "no cron-expiry.txt (WATCH and HARVEST write their expiry there)"; fi

# 4 · Inboxes
for f in "$LOLA_INBOX_DIR"/*.md; do
  [ -f "$f" ] || continue; kb=$(( $(wc -c < "$f") / 1024 ))
  [ "$kb" -gt "$LOLA_INBOX_WARN_KB" ] && y "$(basename "$f") is $kb KB — archive what is older than 7 days"
done

# 5 · Leftovers
for p in ${LOLA_PROJECT_DIRS[@]+"${LOLA_PROJECT_DIRS[@]}"}; do
  [ -d "$p" ] || continue
  while IFS= read -r l; do [ -n "$l" ] && r "stale $l — blocks commits (deleting needs a yes)"; done < <(find "$p" -maxdepth 3 -name index.lock -path '*/.git/*' -mmin +60 2>/dev/null)
  wt=$(while IFS= read -r g; do [ -n "$g" ] && git -C "${g%/.git}" worktree list 2>/dev/null | tail -n +2; done < <(find "$p" -maxdepth 3 -name .git -type d 2>/dev/null) | wc -l | tr -d ' ')
  [ "$wt" -gt 0 ] && y "$wt extra git worktrees under $p"
done
bak=$(find "$CLAUDE_DIR" -maxdepth 5 -name '*.bak*' -mtime +14 -not -path '*/_archive/*' 2>/dev/null | wc -l | tr -d ' ')
[ "$bak" -gt 0 ] && y "$bak backup files older than 14 days in $CLAUDE_DIR"

# 6 · Quota
read -r p _ < <("$here/quota.sh" --raw)
if [ "${p:--}" = "-" ]; then y "quota: no numbers yet"
elif [ "$p" -ge 90 ]; then r "quota: 7d $p %"
elif [ "$p" -ge 75 ]; then y "quota: 7d $p %"
else o "quota: 7d $p %"; fi

echo "— $red 🔴 · $yellow 🟡"
