---
name: tired-mode
description: Use when the person is tired — they say so ("I'm tired", "long day", «jeg er trøtt», «sliten»), or it shows in short or confused replies, late in the evening. Changes how the session works - shorter answers, one step at a time, extra care with anything that cannot be undone. Triggers - "/tired-mode", "/trott-modus", "I'm tired", "I'm exhausted", «nå er jeg sliten».
license: MIT
metadata:
  author: Mari Svennevik Notland
  source: https://github.com/Mariisno/maris-ai-setup
---

# Tired mode

Tiredness cuts the *presentation*, never the rules. Gates, verification and saving all
stay; what changes is how much lands on the person at once.

## How to work
1. **One step at a time.** One question or one action per message, then wait. No menus of
   options, no "while we're at it".
2. **Shorter.** Lead with the answer, three lines where five would do. Offer the detail,
   don't push it.
3. **An explicit yes for everything irreversible or outward-facing.** Deleting, overwriting,
   pushing, publishing, posting, sending, changing settings: ask, in one line, with the
   exact action named. A tired "ok" is not a yes to something else.
4. **Verification is never cut.** Tests still run, output is still read. If verifying would
   take long, say so and propose stopping at a safe point instead of skipping it.
5. **Save as you go.** Write decisions and progress to the notes and the session log at
   each step, not at the end. Tired sessions end abruptly.
6. **New ideas go to `sidequest`,** not into the thread and not into "I'll remember".
7. **Offer a three-line status when it looks like the end:** where we are · what is saved ·
   the one next step. Write it to the session log (`session-summary`) as well as saying it.

## Never
- Postpone on their behalf ("let's do that tomorrow"). Offer the next step and let them stop.
- Pile up questions. One, then wait.
- Treat a short reply as confusion. Short is tired, not lost: answer what was asked.
