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
  if bash -n "$f" 2>/dev/null; then ok "parses: ${f#$root/}"; else bad "parses: ${f#$root/}"; fi
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

# Role catalogue: every role and domain file carries a complete machine line, and
# lola-spawn --role resolves label, model, effort and lead from it without touching tmux.
for f in "$root"/roles/*/*.md; do
  case "$f" in */domains/*) keys="name lead" ;; *) keys="role model effort" ;; esac
  miss=""; for k in $keys; do [ -n "$(lola_role_meta "$f" "$k")" ] || miss="$miss $k"; done
  if [ -z "$miss" ]; then ok "machine line: ${f#$root/}"; else bad "machine line: ${f#$root/} lacks$miss"; fi
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
[ -e "$tmp/home/.spawn.lock" ] && bad "spawn --dry-run left a lock" || ok "spawn --dry-run takes no lock"

# A trust dialog instead of a banner: lola-spawn names the cause. A fake tmux serves the
# fixture as the pane capture; the early exit from the wait loop keeps this fast.
mkdir -p "$tmp/fakebin"
cat > "$tmp/fakebin/tmux" <<'FAKE'
#!/usr/bin/env bash
case "$1" in
  has-session) exit 1 ;;
  list-panes) case " $* " in *pane_id*) echo %9 ;; esac ;;
  capture-pane) cat "$FAKE_PANE" ;;
esac
exit 0
FAKE
chmod +x "$tmp/fakebin/tmux"
out=$(PATH="$tmp/fakebin:$PATH" FAKE_PANE="$root/test/fixtures/menu-trust-workspace.txt" LOLA_CONFIG=/dev/null LOLA_HOME="$tmp/home" \
  bash "$root/bin/lola-spawn" review "MAJA · reviewer (LOLA)" claude-opus-5-5 high "hi" 2>&1); rc=$?
[ "$rc" -eq 1 ] && [[ "$out" == *"folder not trusted: open claude in "*" once and answer yes"* && "$out" == *"Nothing sent"* ]] \
  && ok "spawn: the trust dialog is named, not 'banner says nothing'" || bad "spawn trust dialog (rc $rc): $out"

# lola-init proposes ~/dev/private, not $HOME, on a new config; it never touches an existing one.
ih="$tmp/inithome"; mkdir -p "$ih/dev/private"
HOME="$ih" LOLA_HOME="$ih/.lola" LOLA_CONFIG="" bash "$root/bin/lola-init" >/dev/null 2>&1
grep -qxF 'LOLA_SPECIALIST_CWD="$HOME/dev/private"' "$ih/.lola/config.sh" && ok "init: specialist folder proposed as ~/dev/private" || bad "init: specialist folder: $(grep '^LOLA_SPECIALIST_CWD' "$ih/.lola/config.sh")"
sed -i 's|^LOLA_SPECIALIST_CWD=.*|LOLA_SPECIALIST_CWD="$HOME"|' "$ih/.lola/config.sh"
HOME="$ih" LOLA_HOME="$ih/.lola" LOLA_CONFIG="" bash "$root/bin/lola-init" >/dev/null 2>&1
grep -qxF 'LOLA_SPECIALIST_CWD="$HOME"' "$ih/.lola/config.sh" && ok "init: an existing config is left alone" || bad "init rewrote an existing config"

# install.sh in an empty HOME: the rendered CLAUDE.md must carry the real notes path. The
# config says "$LOLA_HOME/notes"; read bare, without the loader, that once rendered as "/notes".
nh="$tmp/newuser"; mkdir -p "$nh"
if HOME="$nh" CLAUDE_CONFIG_DIR= bash "$root/../../install.sh" >"$tmp/install.log" 2>&1; then
  ok "install.sh: runs in an empty HOME"
  grep -qF '# The notes (~/.lola/notes)' "$nh/.claude/CLAUDE.md" && ok "install.sh: CLAUDE.md renders the notes path" \
    || bad "install.sh: CLAUDE.md notes path: $(grep -m1 '^# The notes' "$nh/.claude/CLAUDE.md")"
  grep -q '{{NAME}}\|{{LANGUAGE}}\|{{NOTES_DIR}}\|{{LEAD}}' "$nh/.claude/CLAUDE.md" && bad "install.sh: a placeholder was left unrendered" \
    || ok "install.sh: no config placeholder left unrendered"
  [ -L "$nh/.claude/statusline.sh" ] && [ -f "$nh/.lola/inbox/LOLA.md" ] && ok "install.sh: links and inbox in place" || bad "install.sh: links or inbox missing"
else
  bad "install.sh: failed in an empty HOME ($(tail -1 "$tmp/install.log"))"
fi

echo; echo "$((n - fail))/$n passed"
[ "$fail" -eq 0 ]
