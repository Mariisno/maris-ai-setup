---
name: sidequest
argument-hint: <what came up>
description: Use when a sidequest turns up in the middle of a working session — a new problem, an idea, a clean-up that is NOT today's main task. Captures it without hijacking the thread - logs it in the notes, proposes its own session with a recommended model and effort. Triggers - "/sidequest <thing>", "by the way we should also…", "we need to look at that some time", a finding outside scope, the person starting on something new mid-task, «btw vi burde også», «dette må vi se på en gang».
---

# Sidequest — capture without hijacking the thread

People jump between things. When something new turns up mid-session it is **captured
properly** (so it isn't lost) without disturbing the main thread. No multitasking in the
same session.

The log is a table in the notes: `<LOLA_NOTES_DIR>/Sidequests.md` (create it on first use;
follow the notes folder's own rules for front matter). It is **shared state**: other
sessions write to it too, so re-read it from disk right before you write, never from a copy
in your context.

## Is it actually a sidequest?
- **No**: small things (under two minutes, same file and context) → just do it, no ceremony.
- **No**: it belongs to today's main task → take it into the thread.
- **Yes**: anything else new or out of scope → the steps below.

## Steps
1. **Log it.** One row, **all cells filled, in this order:**

   ```
   | <YYYY-MM-DD> | **Sidequest:** <title> | <kind: optimisation / deliverable> | <private / team> | 🔴/🟡/⚪ | <model> · <effort> · <when> | <home: repo#issue, or "— private"> | <context + links + "Dependency: …" + "→ Next: …"> | 🔄 or ⏳ |
   ```

   - **Status is a cell in the template, not an afterthought.** Starting now ⇒ `🔄`.
     Waiting ⇒ `⏳`. There is no third option: the row isn't written until the cell has a value.
   - **Context must survive a cold pick-up:** links to issues, notes and files, plus the next step.
   - **`Dependency:` is required, never blank.** Write one of two:
     - `Dependency: independent` — can run any time. Valid and the most common answer.
     - `Dependency: <what> must happen first — <why>`. Without the why it is useless later.
       If the blocker is another row in the log, name it with its date.

   Three questions that surface a dependency (ask all three; they catch different things):
   1. **Same file?** Does another open row touch the same file? ⇒ same session, not two in parallel.
   2. **Order?** Does this become wrong, wasted or collision-prone if it runs before something else lands?
   3. **Waiting on an answer?** Does it need a decision from the person, someone else, or a meeting? ⇒ that is the blocker; write what is missing.

   **When showing sidequests:** blockers and order are shown explicitly. Nobody should have
   to read the context cells to find out what can run now.
2. **A home in the tracker?** If the sidequest has a natural home (an epic, an issue, a
   repository), create or link the issue: the log points, the issue carries the work. When
   an issue exists, the tracker is the single source of status; the row keeps only planning
   context (model · effort · next step). Purely private work keeps a full row with status.
3. **Propose its own session**, now or later: the person chooses. The main thread continues.
4. **Recommend model and effort** for the new session, concretely: "run this on X with
   effort Y because …". The `task-brief` skill owns how to choose; don't repeat the rules here.
5. **Back to the main thread:** say explicitly where we were ("we were on …").

## Status changes
- **Flip status the moment it happens:** 🔄 when the work starts, ✅ when it is delivered.
  Not at the end of the session; by then the list has drifted.
- **Conflict → keep both rows.** Two sessions writing the same row is cheaper to merge than
  a lost row.

## Common mistakes
| Mistake | Fix |
|---|---|
| Starting on the sidequest in the same session | Log + propose a session. Don't start |
| Showing the list from memory | Read the file from disk. Another session may have written since |
| Writing the row and "flipping status afterwards" | Status is a cell in the template |
| Logging without enough context for a cold pick-up | Links + the next step in the row |
| Leaving `Dependency:` blank because "it's probably independent" | Write `independent` explicitly. Blank means "not assessed" |
| Spotting a dependency and only mentioning it in chat | The chat disappears, the row stays |
| Two sidequests editing the same file in two parallel sessions | Question 1 in step 1 catches this |
| Forgetting the model and effort recommendation | Step 4 is mandatory when proposing a session |
| Treating a small thing as a sidequest | Under two minutes → just do it |
| Losing the main thread afterwards | Always end with "we were on …" |
