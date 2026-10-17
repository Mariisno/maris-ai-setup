#!/usr/bin/env bash
# Part of Mari's AI Setup by Mari Svennevik Notland · https://github.com/Mariisno/maris-ai-setup · MIT License
# skill-usage.sh [days] — how often each of your own skills was used in the last N days (default 30),
# measured in the transcripts. 0 hits = a candidate for skills/_archive/ (move it, don't delete it).
# Read-only.
d="${1:-30}"; CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
cd "$CLAUDE_DIR/projects" 2>/dev/null || { echo "no transcripts under $CLAUDE_DIR/projects"; exit 1; }
# grep, not rg: rg may only exist inside the Claude Code shell. One pass over the files: a
# transcript counts once per skill it uses.
hits=$(find . -name '*.jsonl' -mtime -"$d" -print0 2>/dev/null \
  | xargs -0 grep -oE '"skill": ?"[^"]+"' 2>/dev/null | sed -E 's/"skill": ?"//; s/"$//' | sort -u | cut -d: -f2 | sort | uniq -c)
for s in $(ls "$CLAUDE_DIR/skills" 2>/dev/null | grep -v -E '^_|^synced$'); do
  n=$(printf '%s\n' "$hits" | awk -v s="$s" '$2==s {print $1}')
  echo "${n:-0} $s"
done | sort -n
