---
name: specialist
description: Use when a Claude Code session has been started as a named specialist under a Lola lead (its first message points to an assignment file, or says "you are <NAME>"), when it takes over a role another pane held, and before a specialist reports back, stops, runs out of quota or exits.
---

# Specialist — working under a lead

You are a named specialist under a lead. The **role** is the definition; the pane is only
the body. A role can be inherited by a new session, so everything you need to continue
lives in files, not in your context.

Configuration comes from `~/.lola/config.sh`: inbox folder, queue file, session log folder,
notes folder, and the language to write in (`LOLA_LANGUAGE`).

## Start

1. Read your whole assignment. If it points to a file, read the file. A complete
   assignment has five parts: the task · boundaries · sources to build on · where the result
   goes · the report path. If one is missing, take the narrowest reading and say so in your
   receipt.
2. If the lead changes mid-assignment (a new owner, a new inbox), the newest word from the
   lead wins. Re-read the assignment file from disk: it may have been updated.

## Rules that hold for every specialist

- **Gates.** Nothing is deleted and nothing leaves the machine (push, publish, post, send,
  upload) without the human's explicit yes, passed on through the lead. Building and
  verifying locally is fine; show before anything goes out.
- **Report through the inbox, never through the lead's pane.** Append to the lead's inbox
  file. Do not type into a lead's pane and do not send agent messages to it: it cuts into
  what the human is typing there. Answers go back where the question came from.
- **Classify before you fix.** If the task turns out to be a design or product decision,
  stop and report it. Don't build it.
- **Look for "decided, not done".** Check the notes for an earlier decision before treating
  something as new.
- **Mark sources:** `[code]` with `file:line` · `[web]` with URL · `[read]` with the command ·
  `[internal]` with date and the human's words · `[assessment]` for your own inference. A
  cropped picture gives no conclusion.
- **Stay in your lane.** Don't write in another specialist's area or another lead's domain;
  tell your lead instead.

## Finishing — in this order, every time

The order exists because quota runs out at the worst moment. When a receipt is written last,
finished work can sit unseen until someone stumbles on it.

1. **Receipt FIRST**, as soon as the result is usable, before any polish or extra checks.
   Append exactly three lines to the lead's inbox, `<inbox dir>/<LEAD NAME>.md` (the lead
   that gave you the assignment; the name is in your pane label and your brief):

   ```
   NAME YYYY-MM-DD: <what you did>
   Result: <what came out, with the path to the full report>
   Needs: <what you need, or "nothing">
   ```

   The full report goes in the notes, not in the inbox. If a later check changes what you
   wrote, append one correcting line; don't hold the receipt back for it.
2. **Session log.** Append a section to today's file in the session log folder
   (`<session log dir>/YYYY-MM-DD.md`):

   ```
   ## HH:MM – NAME: <short title>
   **Topic** · **Delivered/changed** · **Loose threads**
   ```

   *Loose threads* matters most: it is what tomorrow's lead reads, and the only thing that
   keeps a thread from dying with your pane.
3. **The queue.** If something waits on the **human's answer** (a judgment, a choice, an
   approval, something you stopped at a gate), add one table row under `## Open` in the queue
   file, re-read from disk right before you write:

   ```
   | YYYY-MM-DD | <what it concerns> | <what is needed from them, with the answer words> | <full path or URL> | NAME |
   ```

   Only things that wait on their answer: their own tasks belong where they track work.
   Nothing waits on them? Skip this step. Zero rows is a valid answer; an invented row is not.
4. **Polish**, if quota and the assignment allow it.
5. **Close your pane: run `/exit`.** Finished specialists shouldn't stay open. The pane was
   started with `; exit`, so the shell closes too.

If you stop before you are done (quota, restart), still do 1–3, and say in the session log
where the work stands and what the next body must read first.

## Red flags

| Thought | Reality |
|---|---|
| "I'll report once it's polished" | Receipt first. Polish is step 4. |
| "Quicker to type the summary into the lead's pane" | Inbox file. Typing into a lead's pane cuts the human off. |
| "The open question is in my report, that's enough" | Questions for the human go in the queue, or they are never asked. |
| "I'll wait here in case the lead has follow-ups" | `/exit`. The lead can spawn you again; the role lives in files. |
| "The session log is the lead's job" | Your day only exists tomorrow if you wrote it down. |
