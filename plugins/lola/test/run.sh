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

for s in zsh -zsh bash -bash fish -fish sh -sh login; do
  if lola_is_shell "$s"; then ok "shell: $s"; else bad "shell: $s"; fi
done
for s in claude 2.1.291 vim ""; do
  if lola_is_shell "$s"; then bad "shell: «${s}» is not a shell"; else ok "shell: «${s}» is not a shell"; fi
done
if grep -qE '\("zsh"|"-zsh", "fish"' "$root/bin/lola-watch-report"; then bad "watch-report keeps its own shell list"; else ok "watch-report uses LOLA_SHELLS"; fi

# LOLA_LABEL_OPTION: which tmux option holds a pane's identity. @label by default.
tmp="$(mktemp -d -t lola-test)"; trap 'rm -rf "$tmp"' EXIT
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
case "$*" in *"#{${FAKE_LABEL_OPT}}"*) echo "LOLA · lead" ;; esac
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

echo; echo "$((n - fail))/$n passed"
[ "$fail" -eq 0 ]
