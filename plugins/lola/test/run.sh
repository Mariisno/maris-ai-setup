#!/usr/bin/env bash
# test/run.sh — Lola's tests. No dependencies beyond bash, awk and tmux-free fixtures.
#
#   test/run.sh
#
# 1. Every script parses (bash -n).
# 2. lola_shows_menu: menus and prompts are refused, a pane at its composer never is.
#    The fixtures in test/fixtures are pane captures: menu-*.txt must read as a menu,
#    prompt-*.txt must not. A false «menu» blocks a delivery; a missed menu lets the
#    digits in a message answer it.
set -uo pipefail
root="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOLA_CONFIG=/dev/null . "$root/lib/lola-config.sh"
fail=0; n=0
ok()  { n=$((n+1)); printf 'ok   %s\n' "$1"; }
bad() { n=$((n+1)); fail=$((fail+1)); printf 'FAIL %s\n' "$1"; }

for f in "$root"/bin/* "$root"/lib/*.sh "$root"/templates/*.sh; do
  if bash -n "$f" 2>/dev/null; then ok "parses: ${f#"$root"/}"; else bad "parses: ${f#"$root"/}"; fi
done

for f in "$root"/test/fixtures/menu-*.txt; do
  if lola_shows_menu < "$f"; then ok "menu: $(basename "$f")"; else bad "menu: $(basename "$f") was not seen as a menu"; fi
done
for f in "$root"/test/fixtures/prompt-*.txt; do
  if lola_shows_menu < "$f"; then bad "prompt: $(basename "$f") was seen as a menu"; else ok "prompt: $(basename "$f")"; fi
done

# lola_unsent_text: what stands typed but unsent in the composer. Fixture → expected text.
unsent_case() { # <fixture> <expected>
  got=$(lola_unsent_text < "$root/test/fixtures/$1")
  if [ "$got" = "$2" ]; then ok "unsent: $1 → «${2:-nothing}»"; else bad "unsent: $1 gave «$got», wanted «$2»"; fi
}
unsent_case prompt-unsent-exit.txt "/exit"
unsent_case prompt-unsent-list.txt "1. do this"
unsent_case prompt-working.txt "next thing"
unsent_case prompt-quoted-hints.txt ""
unsent_case prompt-sent-numbered.txt ""
for f in "$root"/test/fixtures/menu-*.txt; do unsent_case "$(basename "$f")" ""; done
printf '✻ done\n────────\n❯ Try "fix the failing test"\n────────\n' > "$root/test/fixtures/.placeholder.tmp"
[ -z "$(lola_unsent_text < "$root/test/fixtures/.placeholder.tmp")" ] && ok "unsent: the dim placeholder is not a message" || bad "unsent: placeholder counted as a message"
rm -f "$root/test/fixtures/.placeholder.tmp"

for s in zsh -zsh bash -bash fish -fish sh -sh login; do
  if lola_is_shell "$s"; then ok "shell: $s"; else bad "shell: $s"; fi
done
for s in claude 2.1.291 vim ""; do
  if lola_is_shell "$s"; then bad "shell: «${s}» is not a shell"; else ok "shell: «${s}» is not a shell"; fi
done
if grep -qE '\("zsh"|"-zsh", "fish"' "$root/bin/lola-watch-report"; then bad "watch-report keeps its own shell list"; else ok "watch-report uses LOLA_SHELLS"; fi

# LOLA_LABEL_OPTION: which tmux option holds a pane's identity. @label by default.
# A template with X's: GNU mktemp refuses `-t lola-test`, and the tests then wrote to /.
tmp="$(mktemp -d "${TMPDIR:-/tmp}/lola-test.XXXXXX")"; trap 'rm -rf "$tmp"' EXIT
opt() { ( LOLA_CONFIG="$1" . "$root/lib/lola-config.sh" 2>/dev/null; printf '%s' "$LOLA_LABEL_OPTION" ); }
[ "$(opt /dev/null)" = "@label" ] && ok "label option: @label by default" || bad "label option default: $(opt /dev/null)"
printf 'LOLA_LABEL_OPTION="@navn"\n' > "$tmp/navn.sh"
[ "$(opt "$tmp/navn.sh")" = "@navn" ] && ok "label option: config sets @navn" || bad "label option from config: $(opt "$tmp/navn.sh")"
for junk in 'navn' '@na vn' '@x}' '@x;y' ''; do
  printf 'LOLA_LABEL_OPTION="%s"\n' "$junk" > "$tmp/junk.sh"
  [ "$(opt "$tmp/junk.sh")" = "@label" ] && ok "label option: «${junk}» falls back to @label" || bad "label option: «${junk}» was accepted"
done
if grep -n '@label' "$root"/bin/* | grep -v '^[^:]*:[0-9]*:#'; then bad "a script hardcodes @label"; else ok "no script hardcodes @label"; fi

# End to end: the dig guard reads the configured option. A fake tmux answers only for it.
mkdir -p "$tmp/bin"
cat > "$tmp/bin/tmux" <<'TMUX'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_TMUX_LOG"
case "$*" in *"#{${FAKE_LABEL_OPT}}"*) echo "${FAKE_LABEL-LOLA · lead}" ;; esac
TMUX
chmod +x "$tmp/bin/tmux"
guard() { # <config> <option the panes carry> <session id>
  printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s"}' "$3" \
    | PATH="$tmp/bin:$PATH" TMUX_PANE=%9 TMPDIR="$tmp" LOLA_CONFIG="$1" FAKE_LABEL_OPT="$2" \
      FAKE_TMUX_LOG="$tmp/tmux.log" bash "$root/bin/lola-dig-guard" >/dev/null 2>&1
  [ -e "$tmp/lola-dig-guard/$3.count" ]
}
guard "$tmp/navn.sh" @navn s1 && grep -qF '#{@navn}' "$tmp/tmux.log" \
  && ok "dig guard: with @navn configured, an @navn lead pane is a lead" || bad "dig guard did not read @navn"
guard /dev/null @navn s2 && bad "dig guard: @label config must ignore @navn panes" || ok "dig guard: default config ignores @navn panes"
guard /dev/null @label s3 && ok "dig guard: default config reads @label" || bad "dig guard did not read @label"

# Identity hook: a lead pane gets its context and a state file; a specialist pane gets its
# context and no state file; an unlabelled or foreign pane gets nothing. Same fake tmux.
start() { # <label the fake pane carries> <session id> → prints the hook's stdout
  printf '{"hook_event_name":"SessionStart","session_id":"%s","source":"startup"}' "$2" \
    | PATH="$tmp/bin:$PATH" TMUX_PANE=%9 LOLA_CONFIG="${CFG:-/dev/null}" LOLA_HOME="$tmp/home" FAKE_LABEL_OPT=@label FAKE_LABEL="$1" \
      FAKE_TMUX_LOG="$tmp/tmux.log" bash "$root/bin/lola-session-start" 2>/dev/null
}
out=$(start "LOLA · lead" sid-lead-1)
[[ "$out" == *'"hookEventName":"SessionStart"'* && "$out" == *"You are LOLA, the Lola lead"* && "$out" == *"lola:lead"* ]] \
  && ok "identity: a lead pane is told it is the lead" || bad "identity lead context: $out"
grep -qx 'session_id=sid-lead-1' "$tmp/home/state/LOLA.session" 2>/dev/null && ok "identity: the lead's session id is saved" || bad "identity: no state file for LOLA"
out=$(start "CILLA · CRITIC · Work (LOLA)" sid-spec-1)
[[ "$out" == *"specialist under the lead LOLA"* && "$out" == *"lola:specialist"* ]] && ok "identity: a specialist pane is told its lead" || bad "identity specialist context: $out"
[ -e "$tmp/home/state/CILLA.session" ] && bad "identity: a specialist must not get a state file" || ok "identity: no state file for a specialist"
out=$(start "" sid-none); [ -z "$out" ] && ok "identity: an unlabelled pane gets nothing" || bad "identity: unlabelled pane got: $out"
out=$(start "my own pane" sid-mine); [ -z "$out" ] && ok "identity: a foreign label gets nothing" || bad "identity: foreign label got: $out"
printf 'LOLA_LEADS=("WEB|the web app|web|/tmp")\n' > "$tmp/leads.sh"
out=$(CFG="$tmp/leads.sh" start "WEB · lead" sid-web); [[ "$out" == *"lead for: the web app"* ]] && ok "identity: the domain comes from LOLA_LEADS" || bad "identity domain: $out"
if grep -v '^[[:space:]]*#' "$root/bin/lola-revive" | grep -q -- '--continue'; then bad "revive still uses --continue"; else ok "revive: no --continue, only --resume by saved id"; fi

# lola-watch-report, end to end with a fake tmux that shows one idle specialist pane, and a
# fake session registry that says it is claude. Without a receipt in its lead's inbox the pane
# is flagged; with one it is not; WATCH panes are never asked for receipts.
wr="$tmp/wr"; mkdir -p "$wr/bin" "$wr/home/.claude/sessions" "$wr/home/.lola/inbox"
cat > "$wr/bin/tmux" <<'TMUX'
#!/usr/bin/env bash
case "$1" in
  list-panes)   printf '%%5\tengine-room\tcritic-work\t%s\tclaude\t0\t1\n' "$FAKE_LABEL" ;;
  capture-pane) cat "$FAKE_CAP" ;;
esac
TMUX
chmod +x "$wr/bin/tmux"
printf '{"pid":%s,"tmux":"engine-room:@1.%%5","version":"9.9.9","status":"idle","statusUpdatedAt":%s}\n' "$$" "$(( ($(date +%s) - 20*60) * 1000 ))" > "$wr/home/.claude/sessions/1.json"
report() { # <label> → the Panes row of the report
  PATH="$wr/bin:$PATH" HOME="$wr/home" LOLA_CONFIG=/dev/null LOLA_HOME="$wr/home/.lola" FAKE_LABEL="$1" FAKE_CAP="$root/test/fixtures/prompt-quoted-hints.txt" \
    bash "$root/bin/lola-watch-report" --no-gh 2>/dev/null | grep -F '| `%5`'
}
: > "$wr/home/.lola/inbox/LOLA.md"
row=$(report "CILLA · CRITIC · Work (LOLA)")
[[ "$row" == *"no receipt from CILLA in LOLA.md"* ]] && ok "watch-report: idle specialist without a receipt is flagged" || bad "watch-report no-receipt: $row"
printf 'CILLA %s: reviewed the flow\nResult: three findings\nNeeds: nothing\n' "$(date +%Y-%m-%d)" >> "$wr/home/.lola/inbox/LOLA.md"
row=$(report "CILLA · CRITIC · Work (LOLA)")
[[ "$row" != *"no receipt"* ]] && ok "watch-report: a receipt dated today clears the flag" || bad "watch-report receipt not seen: $row"
row=$(report "WATCH · hygiene (LOLA)")
[[ "$row" != *"no receipt"* ]] && ok "watch-report: WATCH is never asked for a receipt" || bad "watch-report flagged WATCH: $row"
row=$(FAKE_CAP="$root/test/fixtures/menu-permission.txt" PATH="$wr/bin:$PATH" HOME="$wr/home" LOLA_CONFIG=/dev/null LOLA_HOME="$wr/home/.lola" FAKE_LABEL="TORE · FRONTEND · Work (LOLA)" bash "$root/bin/lola-watch-report" --no-gh 2>/dev/null | grep -F '| `%5`')
[[ "$row" == *"in a menu or prompt"* && "$row" != *"no receipt"* ]] && ok "watch-report: a pane in a menu is flagged as a menu, not as missing a receipt" || bad "watch-report menu row: $row"
row=$(FAKE_CAP="$root/test/fixtures/prompt-unsent-list.txt" PATH="$wr/bin:$PATH" HOME="$wr/home" LOLA_CONFIG=/dev/null LOLA_HOME="$wr/home/.lola" FAKE_LABEL="TORE · FRONTEND · Work (LOLA)" bash "$root/bin/lola-watch-report" --no-gh 2>/dev/null | grep -F '| `%5`')
[[ "$row" == *"unsent message: «1. do this»"* ]] && ok "watch-report: an unsent message is flagged with its text" || bad "watch-report unsent row: $row"

# lola-queue: rows land under «## Open» in order, a | in a field survives, done moves a row
# to the Done table, and twenty concurrent adds lose nothing (the lock).
qh="$tmp/qh"; mkdir -p "$qh/notes"; cp "$root/templates/waiting-on-you.md" "$qh/notes/Waiting on you.md"
queue() { LOLA_CONFIG=/dev/null LOLA_HOME="$qh" LOLA_NOTES_DIR="$qh/notes" bash "$root/bin/lola-queue" "$@"; }
queue add "Checkout copy" "Pick A or B" "notes/checkout.md" CILLA >/dev/null && ok "queue: add returns 0" || bad "queue: add failed"
queue add "Pipe | in a field" "yes/no" "/tmp/x" TORE >/dev/null
[ "$(queue list | grep -c .)" = 2 ] && ok "queue: list shows two open rows" || bad "queue list: $(queue list)"
queue list | sed -n 1p | grep -q 'Checkout copy' && queue list | sed -n 2p | grep -qF 'Pipe \| in a field' && ok "queue: rows in order, | escaped" || bad "queue order/escape: $(queue list)"
awk '/^## Open/{o=1} /^## Done/{o=0} o' "$qh/notes/Waiting on you.md" | grep -q 'Checkout copy' && ok "queue: the row is under ## Open" || bad "queue: row not under ## Open"
queue "done" 1 "B" >/dev/null && [ "$(queue list | grep -c .)" = 1 ] && awk '/^## Done/{d=1} d' "$qh/notes/Waiting on you.md" | grep -q '| Checkout copy | B |' && ok "queue: done moves the row to ## Done with the answer" || bad "queue done: $(cat "$qh/notes/Waiting on you.md")"
for i in $(seq 1 20); do queue add "Row $i" "ok" "/tmp/$i" T >/dev/null & done; wait
[ "$(queue list | grep -c 'Row ')" = 20 ] && ok "queue: 20 concurrent adds, 20 rows (the lock holds)" || bad "queue concurrency: $(queue list | grep -c 'Row ') of 20 rows survived"
[ -d "$qh/.queue.lock" ] && bad "queue: a lock was left behind" || ok "queue: no lock left behind"
queue add "only" "three" "args" 2>/dev/null; [ $? -eq 2 ] && ok "queue: wrong arity is refused" || bad "queue: wrong arity accepted"
# done with no «## Done» table: refused, and the open row is still there.
awk '/^## Done/{exit} {print}' "$qh/notes/Waiting on you.md" > "$qh/notes/nodone.md" && mv "$qh/notes/nodone.md" "$qh/notes/Waiting on you.md"
before=$(queue list | grep -c .); queue "done" 1 "x" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && [ "$(queue list | grep -c .)" = "$before" ] && ok "queue: done without a Done table is refused and loses nothing" || bad "queue done without Done table: rc=$rc rows $before → $(queue list | grep -c .)"

# lola-inbox-rotate: the old file moves whole to archive/, the new one is the template plus a
# pointer line, a dry run changes nothing, an unknown lead is skipped, no lock is left.
rh="$tmp/rh"; mkdir -p "$rh/inbox"; printf 'old receipt 1\nold receipt 2\n' > "$rh/inbox/LOLA.md"
rotate() { LOLA_CONFIG=/dev/null LOLA_HOME="$rh" LOLA_INBOX_DIR="$rh/inbox" bash "$root/bin/lola-inbox-rotate" "$@"; }
rotate --dry-run LOLA >/dev/null && [ "$(cat "$rh/inbox/LOLA.md")" = "$(printf 'old receipt 1\nold receipt 2')" ] && ok "inbox-rotate: --dry-run changes nothing" || bad "inbox-rotate --dry-run touched the inbox"
rotate LOLA >/dev/null && ok "inbox-rotate: returns 0" || bad "inbox-rotate failed"
arch=$(ls "$rh"/inbox/archive/LOLA-*.md 2>/dev/null | head -1)
[ -n "$arch" ] && grep -q 'old receipt 2' "$arch" && ok "inbox-rotate: the old lines are in archive/" || bad "inbox-rotate: no archive with the old lines"
grep -q '^# Inbox' "$rh/inbox/LOLA.md" && grep -q "^ROTATED .*2 lines.*$arch" "$rh/inbox/LOLA.md" && ! grep -q 'old receipt' "$rh/inbox/LOLA.md" && ok "inbox-rotate: the new inbox is the template plus a pointer line" || bad "inbox-rotate new inbox: $(cat "$rh/inbox/LOLA.md")"
rotate NOPE >/dev/null 2>&1; [ $? -eq 1 ] && ok "inbox-rotate: an unknown lead is skipped with exit 1" || bad "inbox-rotate: unknown lead accepted"
[ -d "$rh/.inbox-rotate.lock" ] && bad "inbox-rotate: a lock was left behind" || ok "inbox-rotate: no lock left behind"
[ "$(rotate --all)" = "No inbox over 60 KB. Nothing rotated." ] && ok "inbox-rotate: --all rotates nothing under the limit" || bad "inbox-rotate --all: $(rotate --all)"

# Role catalogue: every role and domain file carries a complete machine line, and
# lola-spawn --role resolves label, model, effort and lead from it without touching tmux.
for f in "$root"/roles/*/*.md; do
  case "$f" in */domains/*) keys="name lead" ;; *) keys="role model effort" ;; esac
  miss=""; for k in $keys; do [ -n "$(lola_role_meta "$f" "$k")" ] || miss="$miss $k"; done
  if [ -z "$miss" ]; then ok "machine line: ${f#"$root"/}"; else bad "machine line: ${f#"$root"/} lacks$miss"; fi
done
spawn() { LOLA_CONFIG=/dev/null LOLA_HOME="$tmp/home" bash "$root/bin/lola-spawn" --dry-run "$@" 2>&1; }
out=$(spawn --role ux/critic --domain work --name CILLA "Review it.")
[[ "$out" == *"label 'CILLA · CRITIC · Work (LOLA)'"* ]] && ok "spawn --role: label from role and domain" || bad "spawn --role label: $out"
[[ "$out" == *"claude-opus-5-5 high"* ]] && ok "spawn --role: model and effort from the role file" || bad "spawn --role model/effort: $out"
[[ "$out" == *"Read $root/roles/ux/critic.md and $root/roles/domains/work.md first. Review it."* ]] && ok "spawn --role: assignment gets the preface" || bad "spawn --role preface: $out"
out=$(spawn --role ux/critic --domain work --effort medium --window w1)
[[ "$out" == *"window 'w1'"* && "$out" == *"claude-opus-5-5 medium"* ]] && ok "spawn --role: --window and --effort override" || bad "spawn --role overrides: $out"
spawn --role nope/x --domain work >/dev/null; [ $? -eq 2 ] && ok "spawn --role: unknown role is refused" || bad "spawn --role: unknown role accepted"
spawn --role ux/ui --domain nope >/dev/null; [ $? -eq 2 ] && ok "spawn --role: unknown domain is refused" || bad "spawn --role: unknown domain accepted"
out=$(spawn review "MAJA · reviewer (LOLA)" claude-opus-5-5 high "hi"); [[ "$out" == *"label 'MAJA · reviewer (LOLA)'"* ]] && ok "spawn: positional form still works" || bad "spawn positional: $out"
[[ "$out" == *"--add-dir $(printf '%q' "$tmp/home")"* ]] && ok "spawn: the start command adds LOLA_HOME with --add-dir" || bad "spawn --add-dir: $out"
sp="$tmp/home with space"; mkdir -p "$sp"
out=$(LOLA_CONFIG=/dev/null LOLA_HOME="$sp" bash "$root/bin/lola-spawn" --dry-run review "MAJA · reviewer (LOLA)" claude-opus-5-5 high "hi" 2>&1)
[[ "$out" == *"--add-dir $(printf '%q' "$sp")"* && "$out" != *"--add-dir '"* ]] && ok "spawn: --add-dir quotes a LOLA_HOME with a space the %q way" || bad "spawn --add-dir with space: $out"
[ -e "$tmp/home/.spawn.lock" ] && bad "spawn --dry-run left a lock" || ok "spawn --dry-run takes no lock"

# install.sh in an empty HOME: the rendered CLAUDE.md must carry the real notes path. The
# config says "$LOLA_HOME/notes"; read bare, without the loader, that once rendered as "/notes".
nh="$tmp/newuser"; mkdir -p "$nh"
if HOME="$nh" CLAUDE_CONFIG_DIR='' bash "$root/../../install.sh" >"$tmp/install.log" 2>&1; then
  ok "install.sh: runs in an empty HOME"
  grep -qF '# The notes (~/.lola/notes)' "$nh/.claude/CLAUDE.md" && ok "install.sh: CLAUDE.md renders the notes path" \
    || bad "install.sh: CLAUDE.md notes path: $(grep -m1 '^# The notes' "$nh/.claude/CLAUDE.md")"
  grep -q '{{[A-Z_]*}}' "$nh/.claude/CLAUDE.md" && bad "install.sh: a placeholder was left unrendered: $(grep -o '{{[A-Z_]*}}' "$nh/.claude/CLAUDE.md" | sort -u | tr '\n' ' ')" \
    || ok "install.sh: no placeholder left unrendered"
  # The rendered file holds a literal "~/…" on purpose (install.sh writes the path with ~ for
  # the person to read), so the test looks for exactly that text: not a path to expand.
  # shellcheck disable=SC2088
  grep -qF '~/.claude/scripts/memory-crossref.sh' "$nh/.claude/CLAUDE.md" && ok "install.sh: scripts are named by their full path" || bad "install.sh: script path not rendered"
  grep -qF 'Pronouns: «your pronouns»' "$nh/.claude/CLAUDE.md" && ok "install.sh: empty pronouns leave a «…» to fill" || bad "install.sh: pronouns line: $(grep -m1 Pronouns "$nh/.claude/CLAUDE.md")"
  [ -L "$nh/.claude/statusline.sh" ] && [ -f "$nh/.lola/inbox/LOLA.md" ] && ok "install.sh: links and inbox in place" || bad "install.sh: links or inbox missing"
else
  bad "install.sh: failed in an empty HOME ($(tail -1 "$tmp/install.log"))"
fi
# --uninstall removes our links and nothing else; a foreign link in skills/ survives.
ln -s /nonexistent/other-skill "$nh/.claude/skills/other-skill"
HOME="$nh" CLAUDE_CONFIG_DIR='' bash "$root/../../install.sh" --uninstall --dry-run >"$tmp/un.log" 2>&1
[ -L "$nh/.claude/statusline.sh" ] && ok "install.sh --uninstall --dry-run: changes nothing" || bad "install.sh --uninstall --dry-run removed a link"
HOME="$nh" CLAUDE_CONFIG_DIR='' bash "$root/../../install.sh" --uninstall >"$tmp/un.log" 2>&1
if [ ! -e "$nh/.claude/statusline.sh" ] && [ ! -e "$nh/.claude/skills/task-brief" ] && [ ! -e "$nh/.claude/scripts/quota.sh" ]; then ok "install.sh --uninstall: our links are gone"; else bad "install.sh --uninstall left links: $(ls "$nh/.claude/skills" "$nh/.claude/scripts")"; fi
[ -L "$nh/.claude/skills/other-skill" ] && ok "install.sh --uninstall: a foreign link is kept" || bad "install.sh --uninstall removed a foreign link"
[ -f "$nh/.claude/CLAUDE.md" ] && [ -f "$nh/.lola/config.sh" ] && ok "install.sh --uninstall: CLAUDE.md and ~/.lola are kept" || bad "install.sh --uninstall touched CLAUDE.md or ~/.lola"
grep -q 'claude plugin uninstall lola@maris-ai-setup' "$tmp/un.log" && ok "install.sh --uninstall: prints the plugin removal" || bad "install.sh --uninstall: no plugin removal printed"

echo; echo "$((n - fail))/$n passed"
[ "$fail" -eq 0 ]
