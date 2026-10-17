#!/usr/bin/env bash
# Part of Mari's AI Setup by Mari Svennevik Notland · https://github.com/Mariisno/maris-ai-setup · MIT License
# install.sh — link this repository into a Claude Code config folder.
#
#   ./install.sh [--dry-run] [--target DIR]
#
# What it does, in order:
#   1. creates ~/.lola/config.sh (the ONE config file) if missing, via the plugin's lola-init
#   2. symlinks skills/<name>  → <target>/skills/<name>
#               scripts/*.sh  → <target>/scripts/<name>
#               statusline/statusline.sh → <target>/statusline.sh
#   3. renders CLAUDE.md.template into <target>/CLAUDE.md when none exists; otherwise writes
#      <target>/CLAUDE.md.from-template next to it and leaves yours alone
#   4. prints the two `claude plugin` commands that install the Lola plugin, and the
#      settings.json snippet for the status line. It never edits settings.json.
#
# <target> is $CLAUDE_CONFIG_DIR if set, else ~/.claude. Anything it would replace is moved
# to <target>/backup-maris-ai-setup-<stamp>/ first. --dry-run prints every step and changes nothing.
set -euo pipefail
repo="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"; dry=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry=1; shift ;;
    --target) target="${2:?--target needs a directory}"; shift 2 ;;
    -h|--help) awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"; exit 0 ;;
    *) echo "unknown option: $1"; exit 2 ;;
  esac
done
target="${target%/}"
stamp="$(date +%Y%m%d-%H%M%S)"; backup="$target/backup-maris-ai-setup-$stamp"
run() { if [ -n "$dry" ]; then echo "  DRY: $*"; else "$@"; fi; }
say() { printf '%s\n' "$*"; }

# move <path> aside before replacing it, unless it already is the link we want
park() { # <path> <wanted link target>
  local p="$1" want="$2"
  if [ -L "$p" ] && [ "$(readlink "$p")" = "$want" ]; then return 1; fi   # already right
  if [ -e "$p" ] || [ -L "$p" ]; then
    run mkdir -p "$backup"
    run mv "$p" "$backup/$(basename "$p")"
    say "  backed up  ${p#"$HOME"/} → $backup/"
  fi
  return 0
}
link() { # <source> <dest>
  if park "$2" "$1"; then
    run mkdir -p "$(dirname "$2")"
    run ln -s "$1" "$2"
    say "  linked     ${2#"$HOME"/}  →  ${1#"$HOME"/}"
  else
    say "  kept       ${2#"$HOME"/} (already linked)"
  fi
}

say "Mari's AI Setup by Mari Svennevik Notland · github.com/Mariisno/maris-ai-setup"
say "→ $target${dry:+  (dry run: nothing is changed)}"
[ -n "$dry" ] || mkdir -p "$target"

say; say "1 · config"
if [ -n "$dry" ]; then
  say "  DRY: bash plugins/lola/bin/lola-init   (creates ~/.lola/config.sh, inboxes, queue; never overwrites)"
else
  bash "$repo/plugins/lola/bin/lola-init" | sed 's/^/  /'
fi
LOLA_HOME="${LOLA_HOME:-$HOME/.lola}"; LOLA_CONFIG="${LOLA_CONFIG:-$LOLA_HOME/config.sh}"

say; say "2 · skills"
for d in "$repo"/skills/*/; do
  n="$(basename "$d")"; [ -f "$d/SKILL.md" ] || continue
  link "${d%/}" "$target/skills/$n"
done

say; say "3 · scripts"
for f in "$repo"/scripts/*.sh; do link "$f" "$target/scripts/$(basename "$f")"; done

say; say "4 · status line"
link "$repo/statusline/statusline.sh" "$target/statusline.sh"

say; say "5 · CLAUDE.md"
render() { # fill the placeholders the config knows; leave the rest for the person
  local name="you" lang="English" notes="$HOME/.lola/notes" lead="LOLA"
  if [ -f "$LOLA_CONFIG" ]; then
    # Read the values through the plugin's own loader, never by sourcing the config bare:
    # the config says "$LOLA_HOME/notes", and only the loader sets LOLA_HOME and the defaults.
    { IFS= read -r name; IFS= read -r lang; IFS= read -r notes; IFS= read -r lead; } < <(
      LOLA_HOME="$LOLA_HOME" LOLA_CONFIG="$LOLA_CONFIG" bash -c '
        . "$1/plugins/lola/lib/lola-config.sh" 2>/dev/null
        printf "%s\n" "$LOLA_USER_NAME" "$LOLA_LANGUAGE" "$LOLA_NOTES_DIR" "${LOLA_LEADS[0]%%|*}"' _ "$repo"
    )
  fi
  # ENVIRON, not -v: awk would read backslashes in the values as escapes
  # "~" from a variable: bash 4.3+ tilde-expands a literal ~ in the replacement back to $HOME.
  local tilde="~"
  R_NAME="$name" R_LANG="$lang" R_NOTES="${notes/#"$HOME"/$tilde}" R_LEAD="${lead:-LOLA}" awk '
    function sub_all(s, key, val,   i, out) {
      out = ""
      while ((i = index(s, key)) > 0) { out = out substr(s, 1, i - 1) val; s = substr(s, i + length(key)) }
      return out s
    }
    { $0 = sub_all($0, "{{NAME}}", ENVIRON["R_NAME"]); $0 = sub_all($0, "{{LANGUAGE}}", ENVIRON["R_LANG"])
      $0 = sub_all($0, "{{NOTES_DIR}}", ENVIRON["R_NOTES"]); $0 = sub_all($0, "{{LEAD}}", ENVIRON["R_LEAD"]); print }
  ' "$repo/CLAUDE.md.template"
}
if [ -e "$target/CLAUDE.md" ]; then
  say "  kept       $target/CLAUDE.md (yours). A fresh render is at CLAUDE.md.from-template; merge what you want."
  [ -n "$dry" ] || render > "$target/CLAUDE.md.from-template"
else
  if [ -n "$dry" ]; then say "  DRY: render CLAUDE.md.template → $target/CLAUDE.md"; else render > "$target/CLAUDE.md"; say "  wrote      $target/CLAUDE.md — fill in the «…» parts and {{PRONOUNS}}"; fi
fi

say; say "6 · the Lola plugin (run these yourself; they write to your plugin settings):"
say "     claude plugin marketplace add $repo"
say "     claude plugin install lola@maris-ai-setup"
say "   Then, in a Claude Code session: /lola:setup init"

say; say "7 · settings.json (merge by hand; this script never edits it):"
sed 's/^/     /' "$repo/settings.example.json" | grep -v _comment
[ "$target" = "$HOME/.claude" ] || say "   (your target is $target, so use $target/statusline.sh as the command)"

say; say "Done.${dry:+ Nothing was changed.} Restart Claude Code so the skills and the status line load."
