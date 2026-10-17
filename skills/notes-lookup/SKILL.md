---
name: notes-lookup
argument-hint: <topic>
description: Use when the person wants to know what the notes already say about a topic, without it being a formal task — an explicit lookup in the notes folder (a Markdown folder or an Obsidian vault). Searches broadly, synthesises with sources and links, and says honestly when nothing is there. Triggers - "/notes-lookup <topic>", "what do we know about …", "did we note anything about …", "look up …", "check the notes", «hva vet vi om», «hva står i vaulten om», «slå opp».
license: MIT
metadata:
  author: Mari Svennevik Notland
  source: https://github.com/Mariisno/maris-ai-setup
---

# Notes lookup — fetch what we already know

An explicit, **read-only** lookup in the notes folder (`LOLA_NOTES_DIR` in
`~/.lola/config.sh`). Never write to the notes from here: capturing goes through
`session-summary`, `sidequest`, `method-issue` or the lead's own flow. Offer that as a next
step; don't do it unasked.

## Steps

1. **Search broadly** with ripgrep in the notes folder. Several angles: the issue number
   (`#584`, `(584)`), the feature name, related terms and synonyms. One pass is rarely
   enough. If the topic is wide (many hits, several threads) and you are a lead, delegate
   the broad search to a specialist and synthesise yourself.
2. **Synthesise, don't dump files.** The short answer first, then detail. A table or a list
   when it makes things clearer. Write in `LOLA_LANGUAGE`.
3. **Source every fact.** Each point links to the note it came from: a clickable path
   (`Projects/Checkout – decisions.md`) or a `[[wikilink]]` when the notes use them
   (`LOLA_NOTES_STYLE=obsidian`). Separate **what the notes say** from **your own
   inference**, and mark the latter `[assessment]`.
4. **Check freshness where it matters.** An old note on a live topic (status, an ongoing
   issue) gets its last-touched date, so the person knows how far to trust it.
5. **Nothing found = say so.** Don't guess, don't invent. Suggest where it might live
   instead (a tracker, a repository, a design file), or that we capture it now through the
   right skill.

## Notes
- Be selective: fetch what answers the question, not everything that mentions the word.
- If the notes folder has its own rules file (`README.md` or `CLAUDE.md` at its root), those
  rules decide structure and source marking. Read them when you haven't this session.
