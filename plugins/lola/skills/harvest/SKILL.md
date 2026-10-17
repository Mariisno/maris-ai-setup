---
name: harvest
description: Use when a session has been given the HARVEST role in a Lola setup, or when a scheduled "HARVEST round" or "HARVEST week" prompt fires — the daily sweep that makes sure every insight from conversations with leads is saved, linked and analysed in the notes.
license: MIT
metadata:
  author: Mari Svennevik Notland
  source: https://github.com/Mariisno/maris-ai-setup
---

# HARVEST — insight harvest across all leads

Rule five of the method says every insight from a conversation with a lead goes to the notes:
saved, analysed, organised, and linked to what it concerns. Leads are supposed to write as they
go. HARVEST is the net under them: once a day it reads what the human actually said to each
lead and writes down what slipped. Once a week it looks for threads and connections across
leads and days.

Configuration comes from `~/.lola/config.sh`: the notes folder (`LOLA_NOTES_DIR`), the link
style (`LOLA_NOTES_STYLE`), the insight folder (`LOLA_INSIGHT_DIR`) and the language to write
in (`LOLA_LANGUAGE`).

## Start (once per pane)

1. Load the `specialist` skill from this plugin. Read the notes folder's own rules if it has
   any (a `README.md` or `CLAUDE.md` at its root): they decide placement, front matter and
   link style.
2. Schedule with `CronCreate`:
   - daily, e.g. `53 16 * * 1-5`, prompt `HARVEST round: follow the lola:harvest skill, Daily`
   - weekly, e.g. `23 15 * * 5`, prompt `HARVEST week: follow the lola:harvest skill, Weekly`

   Recurring scheduled tasks expire after seven days. Write the expiry date in your first
   receipt, and as one line `HARVEST YYYY-MM-DD` in `~/.lola/cron-expiry.txt`.
3. Run one daily round right away, for today.

## Daily — catch what slipped

1. **Find today's lead conversations.** Lead panes are the ones whose label (the tmux option in `LOLA_LABEL_OPTION`, `@label` by default) starts with a
   lead NAME (`tmux list-panes -a -F '#{pane_id} #{pane_pid} #{@label}'`, with your option in place of `@label`). From the pane's
   process, find its `claude` child; the account's `sessions/<pid>.json` gives the
   `sessionId`, and the transcript is `<config dir>/projects/<slug>/<sessionId>.jsonl`.
   Include leads that ended today: `find <config dir>/projects -name '*.jsonl' -newermt <today>`.
2. **Read the human's own messages** (role `user`, not tool results and not system
   reminders) and the lead's answers to them. Pick out: decisions · rules and preferences ·
   insight about users and the product · people, roles and organisation · method errors ·
   ideas.
3. **Check the notes:** is it already there? Search for key words and the date. What is
   there, leave. What is missing, write in the note it belongs to:
   - a decision or product insight → the feature or topic note it concerns, linked to the
     hub note when it touches several
   - a lesson or method → the learning notes, or the method log
   - people and organisation → the people note
   - a rule about how the human wants sessions to work → one line to the first lead's inbox.
     You don't write rules, instructions or memory yourself.

   Always mark the source: `[internal]`, the date, which lead, and the human's own words in
   quotes.
4. **Daily insight log:** `<insight dir>/<YYYY-MM-DD>.md` — what was caught, where it was
   written (links), and what was already there.

## Weekly — threads and connections

Write `<insight dir>/Week <NN> – threads and connections.md`:

- **Recurring threads** across leads and days (the same problem in two domains, the same wish
  from the human several times)
- **Tensions:** decisions that pull in different directions, rules that contradict each other
- **What has changed** in the human's priorities
- **Map:** a small Mermaid diagram of the connections
- **★ Three things worth the human's attention**, marked `[assessment]`
- Link the week from an index note in the insight folder (create it if missing).

## Never

Delete or rewrite anyone else's text in the notes (only add) · change instructions, skills,
memory or settings · send anything off the machine · type into lead panes · copy personal
data about third parties beyond what the notes already hold.

## Report

One line per round in the first lead's inbox: `HARVEST <date>: N caught · M already there ·
<link to the insight log>`. Weekly: the link to the week note and the three ★ points.
