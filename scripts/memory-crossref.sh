#!/usr/bin/env bash
# Part of Mari's AI Setup by Mari Svennevik Notland · https://github.com/Mariisno/maris-ai-setup · MIT License
# memory-crossref.sh — see across ALL project-scoped memories.
#
# Why: Claude Code loads only the memories in <config dir>/projects/<cwd-slug>/memory/.
# A fact written in one folder is invisible in another, and the same mistake can live for
# days in two places. This script reads every folder, wherever you stand.
#
#   memory-crossref.sh                 overview: folders, counts, what is invisible from here
#   memory-crossref.sh <word>          search ALL memories, with the folder each hit lives in
#   memory-crossref.sh --others        list the memories NOT loaded in this folder
#
# Read-only. Writes nothing.
set -uo pipefail
ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects"
CWD_SLUG="$(pwd | sed 's|/|-|g')"
MINE="$ROOT/$CWD_SLUG/memory"
HOME_SLUG="$(printf '%s' "$HOME" | sed 's|/|-|g')"

label() { basename "$(dirname "$1")" | sed "s|^$HOME_SLUG|~|; s|-|/|g"; }
count() { local n=0 f; for f in "$1"/*.md; do [ -e "$f" ] || continue; case "$(basename "$f")" in MEMORY.md|_inbox.md) ;; *) n=$((n+1)) ;; esac; done; echo "$n"; }

case "${1:-}" in
  --others)
    printf '== Memories NOT loaded when you stand in %s ==\n\n' "$(pwd)"
    for d in "$ROOT"/*/memory; do
      [ -d "$d" ] || continue; [ "$d" = "$MINE" ] && continue
      n=$(count "$d"); [ "$n" -eq 0 ] && continue
      printf -- '-- %s (%s memories)\n' "$(label "$d")" "$n"
      for f in "$d"/*.md; do
        case "$(basename "$f")" in MEMORY.md|_inbox.md) continue ;; esac
        desc=$(sed -n 's/^description: *//p' "$f" | head -1 | tr -d '"' | cut -c1-88)
        printf '   %-52s %s\n' "$(basename "$f" .md)" "$desc"
      done; echo
    done ;;
  "")
    printf '== Project-scoped memory folders ==\n\n'
    printf '%-46s %6s  %s\n' "FOLDER" "COUNT" "LOADED HERE?"
    tot=0
    for d in "$ROOT"/*/memory; do
      [ -d "$d" ] || continue
      n=$(count "$d"); [ "$n" -eq 0 ] && continue
      tot=$((tot+n)); here="no"; [ "$d" = "$MINE" ] && here="YES (cwd)"
      printf '%-46s %6s  %s\n' "$(label "$d")" "$n" "$here"
    done
    mine_n=0; [ -d "$MINE" ] && mine_n=$(count "$MINE")
    printf '\n%s memories in total. %s loaded here; %s invisible from this folder.\n' "$tot" "$mine_n" "$((tot - mine_n))"
    printf 'Search across them: memory-crossref.sh <word>\n' ;;
  *)
    q="$1"; printf '== Searching for "%s" in ALL project memories ==\n\n' "$q"; hits=0
    for d in "$ROOT"/*/memory; do
      [ -d "$d" ] || continue
      for f in "$d"/*.md; do
        [ -f "$f" ] || continue
        if grep -qil -- "$q" "$f" 2>/dev/null; then
          hits=$((hits+1)); flag=""; [ "$d" != "$MINE" ] && flag="   <-- NOT loaded in this session"
          printf -- '-- %s / %s%s\n' "$(label "$d")" "$(basename "$f" .md)" "$flag"
          grep -in -- "$q" "$f" | head -3 | sed 's/^/     /' | cut -c1-150; echo
        fi
      done
    done
    [ "$hits" -eq 0 ] && printf 'No hits in any folder.\n' || printf '%s file(s) with hits.\n' "$hits" ;;
esac
