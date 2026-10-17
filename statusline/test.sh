#!/bin/bash
# Smoke test: feeds statusline.sh the JSON Claude Code sends and checks both lines, the
# signature switch, that no account is ever named, and the snapshot quota.sh reads.
# HOME and LOLA_HOME point at a temp folder, so nothing lands in the real ones.
# Run: bash statusline/test.sh
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp" LOLA_HOME="$tmp/.lola" LOLA_CONFIG="$tmp/.lola/config.sh"
mkdir -p "$LOLA_HOME"; : > "$LOLA_CONFIG"
failed=0

run() { # run <name> <json> <text the output must contain> [text it must NOT contain]
  local out err
  out=$(printf '%s' "$2" | bash "$root/statusline/statusline.sh" 2>"$tmp/err"); err=$(cat "$tmp/err")
  if [ -n "$err" ]; then echo "✗ $1: stderr: $err"; failed=1
  elif [[ "$out" != *"$3"* ]]; then echo "✗ $1: missing «$3» in: $out"; failed=1
  elif [ -n "${4:-}" ] && [[ "$out" == *"$4"* ]]; then echo "✗ $1: should not show «$4» in: $out"; failed=1
  else echo "✓ $1"; fi
}
check() { # check <name> <actual> <expected substring>
  if [[ "$2" == *"$3"* ]]; then echo "✓ $1"; else echo "✗ $1: got «$2»"; failed=1; fi
}

now=$(date +%s)
full='{"model":{"display_name":"Opus"},"effort":{"level":"high"},"context_window":{"used_percentage":40},
  "rate_limits":{"five_hour":{"used_percentage":25,"resets_at":'$((now + 3600))'},
                 "seven_day":{"used_percentage":60,"resets_at":'$((now + 86400))'}}}'
opus='{"model":{"display_name":"Opus"}}'
run 'full input' "$full" '7d'
run 'empty input' '{}' 'Claude'
run 'low effort' '{"model":{"display_name":"Opus"},"effort":{"level":"medium"}}' 'medium'
run 'decimal percentages' '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":12.5},
  "rate_limits":{"five_hour":{"used_percentage":66.6,"resets_at":'$((now + 3600)).5'}}}' '67%'

run 'Sussi by default' "$opus" '🐈'
STATUSLINE_PERSONAL=0 run 'signature off' "$opus" 'Opus' '🐈'
echo 'LOLA_USER_NAME="Ola"' > "$LOLA_CONFIG"
run 'name from config' "$opus" ', Ola'
echo 'STATUSLINE_PERSONAL=0' > "$LOLA_CONFIG"
run 'signature off in config' "$opus" 'Opus' '🐈'

# Two accounts configured, run from the second: the line still names no account.
printf '%s\n' 'LOLA_ACCOUNTS=("default|$HOME/.claude|" "second|$HOME/.claude-second|")' > "$LOLA_CONFIG"
CLAUDE_CONFIG_DIR="$tmp/.claude-second" run 'no account tag' "$full" 'Opus' 'SECOND'

snap="$LOLA_HOME/usage/snapshot.json"
check 'one snapshot, no account in it' "$(jq -c 'has("account")' "$snap" 2>&1)" 'false'
check 'quota.sh --raw' "$(bash "$root/scripts/quota.sh" --raw 2>&1)" '60 25'
check 'quota.sh' "$(bash "$root/scripts/quota.sh" 2>&1)" '7d   60 %'
rm -f "$snap"
check 'quota.sh before any snapshot' "$(bash "$root/scripts/quota.sh" --raw 2>&1)" '- -'

for flag in --version --help; do
  check "$flag" "$(bash "$root/statusline/statusline.sh" "$flag" </dev/null 2>&1)" 'by Mari Svennevik Notland'
done

# A decimal comma locale must not break the rounding (printf %.0f does under nb_NO).
: > "$LOLA_CONFIG"
if locale -a 2>/dev/null | grep -qiE "^nb_NO\.utf-?8$"; then
  LC_ALL=nb_NO.UTF-8 run 'Norwegian locale' '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":12.5}}' '13%'
else echo "- Norwegian locale: skipped, nb_NO.UTF-8 is not installed"; fi

exit $failed
