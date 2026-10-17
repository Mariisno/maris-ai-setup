---
name: method-issue
argument-hint: <what slipped>
description: Use when we notice a flaw, a gap or a breach in our own way of working — a routine that wasn't followed, a skill mechanism that doesn't work, an instruction that is out of date. Logged IMMEDIATELY in the method log with severity and priority; fixed when it suits. Sister of sidequest (new work); this one is for errors in how we work. Triggers - "/method-issue <finding>", "/skill-issue", "this slipped", "the skill doesn't work", "we didn't follow what we agreed", «dette glapp», «metodefeil», a routine deviation noticed during work.
license: MIT
metadata:
  author: Mari Svennevik Notland
  source: https://github.com/Mariisno/maris-ai-setup
---

# Method issue — catch it now, fix it when it suits

When the method has a hole or wasn't followed: **log it at once** (thirty seconds, mid-task),
set severity and priority, and go back to the work. The fix comes when it suits. Don't let
the finding vanish, and don't let the fixing hijack the thread.

The log is `LOLA_METHOD_LOG` (from `~/.lola/config.sh`; by default `<notes>/Method log.md`).

## Steps

1. **Log immediately.** Create the file if needed (follow the notes folder's own rules for
   front matter). Fill the template, all six cells:

   ```
   | <YYYY-MM-DD> | <what went wrong + root cause> | <skill/routine/instruction + which step> | 🔴/🟡/⚪ | <fix idea> | ⏳ waiting, or ✅ <what was done> — Evidence: <command + result, or a quote from the file> |
   ```

   - Severity: 🔴 produces errors in deliverables · 🟡 friction or mess · ⚪ cosmetic
   - **`Evidence:` is a required part of the status cell, not an afterthought.** A row
     without evidence is not closed, however sure you are.

   **A description of the action ≠ evidence.** "Fixed in the skill" is true of the action
   and may be false of the result.

   | Not evidence | Evidence |
   |---|---|
   | "Fixed in the skill" | `grep -n "CLAUDE.md" SKILL.md` → 4 hits, all negative |
   | "The script is written" | `bash /full/path/script.sh` → ran, exit 0 |
   | "The status is set" | read back with the tracker's field list → the value stands |

2. **Check whether it is a repeat**, before proposing any fix. Search on the **name of the
   skill, routine or file** the error lives in, not on the symptom:

   ```
   grep -in "<skill or routine name>" "<method log>"
   ```

   The place name is a reliable predicate; symptom words are not.

   **A hit on the same underlying error ⇒ a prose fix is ruled out.** Don't sharpen the
   wording, don't add a paragraph, don't move the rule higher up. Change the **form**, and
   write in the row which form you escalated to:

   | The error repeated because | Escalate to |
   |---|---|
   | a field or step is forgotten | a required cell in a **literal template**, not a reminder beside it |
   | a prerequisite step is skipped | **one sanctioned command** that performs the prerequisite itself |
   | the rule has a definite answer and needs no judgment | a **script** |
   | something must happen every time, regardless | a **hook** |

   No hit ⇒ a prose fix is fine on the first attempt. Then write the **place name in the
   "where" cell so it is searchable** (skill name + step), so the next repeat is found.

3. **Fix now ONLY if** trivial (under two minutes) or 🔴 and blocking the current work.
   Otherwise: status "⏳ waiting", fixed in a session of its own (the `sidequest` model).
4. **When fixing:** update the row (✅ + what was done + evidence), and **verify structural
   fixes before counting them done**: a script or hook is tested the way it actually runs,
   not by reading it.
5. Back to the main thread: "we were on …".

## Common mistakes
| Mistake | Fix |
|---|---|
| "I'll fix it later" without logging | Log FIRST. Memory is not storage |
| Fixing everything at once and losing the thread | Only trivial or blocking now; the rest waits |
| Proposing a fix without searching the log first | Step 2 is mandatory: a repeat changes which fix is allowed |
| Sharpening the wording of a rule that already slipped | Prose has proven it doesn't hold here. Change the form, not the words |
| Counting a structural fix done because it is written | Test it the way it runs |
