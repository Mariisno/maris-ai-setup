#!/usr/bin/env bash
# Part of Mari's AI Setup by Mari Svennevik Notland · https://github.com/Mariisno/maris-ai-setup · MIT License
# skill-audit.sh — verify that [[wikilinks]] in your skills and memory files point to real
# targets (a memory file or another skill), and that inbox files haven't grown unreadable.
#
# Skills and memories cross-link with [[slug]]. A typo or a renamed memory leaves a dead
# link that silently points nowhere. This checks them in one call.
#
#   skill-audit.sh [--mem PATH] [--skills PATH]
#
# A [[link]] is valid if it matches a memory file's slug (filename without .md), the `name:`
# in a memory's front matter, OR a skill name (a dir under the skills folder). Written as
# [[slug]], [[slug.md]], [[slug|alias]] or [[slug#heading]]: all normalised before matching.
# An unresolved link is not always a bug: a [[name]] may mark a memory "worth writing
# later". So they are reported for review, not treated as hard failures.
#
# Exit: 0 = all resolve · 1 = one or more unresolved, or an inbox over the limit · 2 = setup error.
set -euo pipefail
export LC_ALL=C
here="$(cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=../plugins/lola/lib/lola-config.sh
. "$here/../plugins/lola/lib/lola-config.sh"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MEM="$CLAUDE_DIR/projects/$(pwd | sed 's|/|-|g')/memory"
SKILLS="$CLAUDE_DIR/skills"

die() { printf '✗ %s\n' "$1" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --mem)    MEM="${2:-}"; shift 2 ;;
    --skills) SKILLS="${2:-}"; shift 2 ;;
    *) die "unknown option: $1" ;;
  esac
done
[ -d "$MEM" ]    || die "memory dir not found: $MEM (pass --mem, or run from the project folder)"
[ -d "$SKILLS" ] || die "skills dir not found: $SKILLS"

TMP_VALID="$(mktemp)"; trap 'rm -f "$TMP_VALID"' EXIT
{
  for f in "$MEM"/*.md; do
    [ -f "$f" ] || continue
    b="$(basename "$f" .md)"; [ "$b" = "MEMORY" ] && continue
    echo "$b"; sed -n 's/^name: *//p' "$f" | head -1
  done
  for d in "$SKILLS"/*; do [ -e "$d" ] && basename "$d"; done
} | sort -u > "$TMP_VALID"
VALID_COUNT="$(wc -l < "$TMP_VALID" | tr -d ' ')"

is_placeholder() { case "$1" in "..."|name|slug|link|wikilink|wikilinks|their-name) return 0 ;; *) return 1 ;; esac; }
normalise() { local s="$1"; s="${s%%|*}"; s="${s%%#*}"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; s="${s%.md}"; printf '%s' "$s"; }
# a real memory/skill slug is lowercase [a-z0-9_-]; anything else is a note in the notes folder
is_notes_ref() { case "$1" in *[[:upper:]]*) return 0 ;; *[!a-z0-9_-]*) return 0 ;; *) return 1 ;; esac; }

UNRESOLVED=""; NOTESREFS=""; INBOXREFS=""; INBOX_COUNT=0; MD_SUFFIX=0; TOTAL=0; NOTES_COUNT=0; FILES_SCANNED=0
while IFS= read -r file; do
  [ -z "$file" ] && continue
  links="$(grep -oE '\[\[[^]]+\]\]' "$file" 2>/dev/null | sed -E 's/^\[\[//; s/\]\]$//' || true)"
  [ -z "$links" ] && continue
  FILES_SCANNED=$((FILES_SCANNED + 1)); rel="${file#"$HOME"/}"
  while IFS= read -r raw; do
    [ -z "$raw" ] && continue
    slug="$(normalise "$raw")"; is_placeholder "$slug" && continue
    TOTAL=$((TOTAL + 1)); case "$raw" in *.md) MD_SUFFIX=$((MD_SUFFIX + 1)) ;; esac
    if grep -Fxq "$slug" "$TMP_VALID"; then :
    elif [ "$(basename "$file")" = "_inbox.md" ]; then
      # the auto-capture queue: candidates that are not memories yet, never counted as rot
      INBOX_COUNT=$((INBOX_COUNT + 1)); INBOXREFS="${INBOXREFS}${rel}	[[${raw}]]
"
    elif is_notes_ref "$slug"; then
      NOTES_COUNT=$((NOTES_COUNT + 1)); NOTESREFS="${NOTESREFS}${rel}	[[${raw}]]
"
    else
      UNRESOLVED="${UNRESOLVED}${rel}	[[${raw}]]
"
    fi
  done <<EOF2
$links
EOF2
done <<EOF2
$(find -L "$MEM" "$SKILLS" -name '*.md' 2>/dev/null | sort)
EOF2

UNRESOLVED_COUNT="$(printf '%s' "$UNRESOLVED" | grep -c . || true)"
RESOLVED=$((TOTAL - UNRESOLVED_COUNT - NOTES_COUNT - INBOX_COUNT))
grouped() { printf '%s' "$1" | sort | awk -F'\t' '{ if ($1 != prev) { print "  " $1; prev = $1 } print "      " $2 }'; }

echo "── skill-audit: [[wikilink]] integrity ──────────────────────"
echo "Scanned $FILES_SCANNED files (memory + skills) · $TOTAL links · $VALID_COUNT valid targets"; echo
if [ "$UNRESOLVED_COUNT" -gt 0 ]; then
  echo "⚠️  $UNRESOLVED_COUNT unresolved link(s): a typo, a renamed memory, or a memory worth writing later. Review each:"; echo
  grouped "$UNRESOLVED"; echo
fi
if [ "$INBOX_COUNT" -gt 0 ]; then echo "ℹ  $INBOX_COUNT link(s) from an auto-capture _inbox.md (candidates, not link rot):"; echo; grouped "$INBOXREFS"; echo; fi
if [ "$NOTES_COUNT" -gt 0 ]; then echo "ℹ  $NOTES_COUNT cross-reference(s) to the notes folder (a different namespace, not checked here):"; echo; grouped "$NOTESREFS"; echo; fi
if [ "$MD_SUFFIX" -gt 0 ]; then echo "ℹ  $MD_SUFFIX link(s) written with a .md suffix; they resolve, but the convention is [[slug]]."; echo; fi
if [ "$UNRESOLVED_COUNT" -eq 0 ]; then echo "✓ All $TOTAL links resolve."; LINK_RC=0; else echo "$RESOLVED/$TOTAL links resolve."; LINK_RC=1; fi

echo; echo "── Inbox files that have grown unreadable"
# a lead that must read the whole inbox to find what is new spends thousands of tokens on it
FOUND=0
for f in "$LOLA_INBOX_DIR"/*.md; do
  [ -f "$f" ] || continue; KB=$(( $(wc -c < "$f") / 1024 ))
  if [ "$KB" -gt "$LOLA_INBOX_WARN_KB" ]; then echo "  ❌ $(basename "$f") — $KB KB. Rotate it: lola-inbox-rotate $(basename "$f" .md) (never edit it in place: monitors replay)."; FOUND=$((FOUND+1)); fi
done
[ "$FOUND" -eq 0 ] && echo "  ✅ all inboxes under $LOLA_INBOX_WARN_KB KB"
[ $(( LINK_RC + FOUND )) -eq 0 ] && exit 0 || exit 1
