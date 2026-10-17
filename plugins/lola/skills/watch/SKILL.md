---
name: watch
description: Use when a session has been given the WATCH role in a Lola setup, or when a scheduled "WATCH round" prompt fires — the hygiene watch over all leads that closes finished specialist panes and routes findings.
license: MIT
metadata:
  author: Mari Svennevik Notland
  source: https://github.com/Mariisno/maris-ai-setup
---

# WATCH — the hygiene watch over all leads

WATCH runs continuously in its own specialist pane and looks for drift: finished specialists
left open, empty shells, a queue that grows stale, inboxes that grow too big, hygiene jobs
nobody ran. It fixes the small mechanical things itself and routes everything else to the
lead who owns it. It never decides anything.

Configuration comes from `~/.lola/config.sh` (see the `setup` skill).

## Start (once per pane)

1. Load the `specialist` skill from this plugin. You are a specialist; its rules apply.
2. Schedule the rounds with `CronCreate`, both with the prompt
   `WATCH round: follow the lola:watch skill`:
   - every two hours in working hours, e.g. `7 8-16/2 * * 1-5`
   - end of day, e.g. `47 16 * * 1-5`

   Recurring scheduled tasks expire after seven days. Write the expiry date in your first
   receipt, and as one line `WATCH YYYY-MM-DD` in `~/.lola/cron-expiry.txt` (replace your
   old line), so the lead and `maintenance.sh` know when to recreate them.
3. Run one round right away.

## One round

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/bin/lola-watch-report"` and read the report.
2. **Fix these yourself, and only these:**
   - **A finished specialist left open in the specialist session.** Run
     `tmux capture-pane -p -S -200 -t <pane>` on that pane in the same moment. Close it with
     `tmux kill-pane` only when all three hold: (i) the pane label (`LOLA_LABEL_OPTION`, `@label` by default) matches what the pane shows,
     (ii) the last turn has ended (no `esc to interrupt`), (iii) the specialist's receipt is in
     its lead's inbox, or the pane has been idle for more than 60 minutes. In doubt: don't
     close, report it.
   - **An empty shell in the specialist session:** `pane_current_command` is a shell and the
     pane has no child processes (`pgrep -P <pane_pid>` is empty) → close it.
   - **An unsent message in a specialist pane** (the report says `unsent message: «…»` or
     `/exit stands unsent`): a message typed into the composer and never sent stalls that
     specialist for hours. Capture the pane in the same moment; when the composer still holds
     that text, no menu is open and the pane isn't working (no `esc to interrupt`), press
     `tmux send-keys -t <pane> Enter` **once**. Never type anything else into it, and never
     do this in a lead's pane: there the unsent text is the human's own.
   - **A specialist idle without a receipt** (`idle N min, no receipt from NAME in LEAD.md`):
     it stopped, and its lead doesn't know. Send it one line through `lola-send`, once per
     pane: `WATCH: you have been idle N min and <LEAD>.md has no receipt from you. Write the
     three-line receipt now (what · result · needs), then /exit.` Note the pane id in your
     round; a pane you already asked is reported to the lead instead, never asked twice.
3. **A pane in a menu or prompt** (`in a menu or prompt (N min)`): never answer it. Put the
   pane id, how long it has stood there, and what the menu asks (first lines of the capture)
   in that lead's message in the same round. The lead answers a read-only plan approval
   itself; everything else goes to the human.
   - **An inbox over `LOLA_INBOX_WARN_KB`** (the report marks it ⚠️): rotate it with
     `bash "${CLAUDE_PLUGIN_ROOT}/bin/lola-inbox-rotate" <LEAD>`. Nothing is deleted: the file
     moves to `archive/` and a fresh one starts with a pointer line. Say so in that lead's
     message, because its Monitor must be re-armed. Never edit an inbox in place.
   - **Stamp** the rows you actually ran in the hygiene table, if there is one.
4. **Route the rest** as one combined message per lead, and only when there are findings:
   append to that lead's inbox in the inbox folder, prefixed `WATCH <date> <time>:`. Route by
   the lead named in the pane label (`… (LEAD)`), else by the domains in `LOLA_LEADS`; what
   concerns how the setup itself works goes to the first lead.
5. No findings: write one line to the first lead's inbox: `WATCH <time>: clean`.

## Never

- Close, type into or interrupt panes **outside the specialist session**. Leads, and any
  session the human works in, are untouchable.
- Close a pane that is working, or that shows a menu or a question. Answer a menu.
- Type anything into a pane. The one key WATCH presses is Enter on an unsent message in a
  specialist pane, once, after a capture in the same moment.
- Delete files, send anything off the machine, or change settings, instructions, skills or
  memory.
- Write in the queue. Leads do that.
