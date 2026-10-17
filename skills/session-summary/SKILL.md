---
name: session-summary
argument-hint: "[tidy]"
description: Use when the person wants the current Claude Code session summarised and saved as a re-readable section in the daily session log — typically when a meaningful session lands. Also has a tidy mode that reviews recent session-log files, cross-checks loose threads, and proposes maintenance without changing anything. Triggers - "/session-summary", "summarise the session", "save a session note", "we landed something", "tidy the session log", «oppsummer økta», «skriv økt-notat», «rydd i øktloggen».
license: MIT
metadata:
  author: Mari Svennevik Notland
  source: https://github.com/Mariisno/maris-ai-setup
---

# Session summary → the daily session log

You run **inside** the session, so you already have the whole context: synthesise from the
conversation. Don't read transcripts or `.jsonl` files.

The log lives in `LOLA_SESSION_LOG_DIR` (from `~/.lola/config.sh`; by default
`<notes>/session-log/`), one file per day, `YYYY-MM-DD.md`, one `## HH:MM – title` section
per session. Specialists under a lead write the same kind of section when they finish, so
"yesterday" is one file to read.

## Steps

1. **The worth-keeping gate, before writing anything.** The log should be re-readable, not
   a heap. Choose the level deliberately:
   - **Trivial** (a few messages, no decisions or deliverables, a plain lookup) → say so
     honestly and ask whether to skip. Don't write an empty note.
   - **Small but real** (one small deliverable, no decisions that matter) → one line, not
     the full template: `## HH:MM – title · what was done · Source: [internal]`.
   - **Substantial** (decisions, deliverables, a change of direction, loose threads worth
     catching) → the full section (template below).
2. **Get the date and time** by running `date "+%Y-%m-%d"` and `date "+%H:%M"`. Never guess.
3. **Synthesise from the conversation**, short and re-readable, not minutes:
   - **Topic** — what the session was about (one line)
   - **Decisions** — what was decided, and briefly why when not obvious
   - **Delivered / changed** — files, issues, artifacts, notes, config
   - **Loose threads / next** — what remains or was parked. This is what tomorrow reads.
   - Link to related notes (`[[wikilinks]]` when `LOLA_NOTES_STYLE=obsidian`, else paths).
4. **Save.** If the day's file doesn't exist, create it (with front matter if the notes
   folder's rules ask for it). If it exists, **read it first** and decide:
   - A section already summarises **this same session** (you recognise your own summary)?
     **Replace that section**; keep its original time in the heading. "Summarise again"
     means "update", not "duplicate".
   - Otherwise **append** a new section.
   - Never touch sections from **other** sessions the same day. In doubt, append.
5. **Confirm briefly:** what was written and where.

## Tidy mode (`/session-summary tidy`)

Reads recent files (default the last 7 days, or what the person asks for) and *proposes*
maintenance. It deletes or rewrites nothing without an explicit ok.

1. Session-log sections are point-in-time; they are normally **not** rewritten.
2. **Cross-check every loose thread against reality:** is it (a) resolved in a later
   session, (b) already tracked somewhere (the queue, a tracker, a work log), or
   (c) **stranded**, living only in the session log? Stranded threads are the real gain:
   they die if they don't get a home.
3. **Propose, don't act:** stranded threads as rows for wherever work is tracked; genuine
   duplicates or trivial sections as cuts, with file and section named. Deletion needs a yes.
   In doubt, keep.

## Section template

```markdown
## 14:30 – Short title for the session
**Topic:** …
**Decisions:** …
**Delivered / changed:** …
**Loose threads / next:** …
Source: [internal]
```
