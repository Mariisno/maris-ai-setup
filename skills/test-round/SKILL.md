---
name: test-round
description: Use when the person needs to test something themselves and wants to know exactly what to click — after an agent run finishes, after a prototype change is uploaded, before a design is called done, or before showing something to a team. Also for a repeatable test list for a screen or module. Triggers - "what should I test", "give me a test round", "it's done, what do I check", "make me a checklist", «hva skal jeg teste», «gi meg en testrunde».
---

# Test round — what the person actually clicks

> **Is it `testing` you want?** This skill owns the **form**: the concrete click-by-click list
> the person follows. Deciding *which test layer* is required, or whether something is tested
> well enough, is `testing`.

## Core principle

**I can read the code. Only the person can see the screen.** The test round is the dividing
line: deliver the code-verifiable as settled, and give them *only* what needs eyes, in a form
they can do in a couple of minutes without thinking.

⚠️ **Never deliver a test round for something you haven't verified in code first.** The order
is: code check → *then* a test round on what remains.

## The delivery is TWO parts, not one

### Part 1 · Change overview
One row per change. Not a commit log: a list of what is **different for them**:

| What | Where | Noticeable for you |
|---|---|---|
| short, in their words | the screen name they use | what they will actually see |

- **Leave out the invisible.** Refactoring, comments, renamed variables belong in the commit message.
- **Separate your changes from the design tool's**, when both surfaces were in play.
- **Say what was NOT done** if something was stopped, skipped or failed.

### Part 2 · The test
Four columns. **Each point answers one point in the overview.** A change without a test is
unverifiable, and that is stated explicitly.

| # | Open | Look for | Wrong if |
|---|---|---|---|

- **Open**: the screen name they use + the filter state when it matters.
- **Look for**: **a number or concrete text**, never "that it looks right". No number, no test.
- **Wrong if**: the failure symptom. This is what lets them decide without asking.

At most **6–8 points**. More means you put in things you could have checked in code.

## Mark the most important one
One point is marked most important, with **why**. Choose the one with a **silent failure
mode**, where something looks right while it is wrong: a group that looks untouched while
one line is filled · a filter that hides rows without saying so · a row showing another
person's data · a forecast showing 0 where data is missing · a number right under one filter
and wrong under another.

## Expected numbers from a fact sheet, not from memory
If the project has a fact sheet (a route list with expected values), **read it** and use
those numbers. If not, compute them from the data files and write them down there.
**Always state which filter a number holds under.**

## Say what happens if it fails
End every round with **one line** on recovery: which commit or snapshot is the last known
good state, and that they can just say "it fails on point N". They should never wonder
whether a failure during testing is lost work.

## When the test is delegated to an agent instead
Then it is a **verification prompt**, and it needs four things the click list doesn't:
1. **Expected numbers, with the filter they hold under.**
2. **"Fix nothing — report with numbers."**
3. **"List the test data you created."**
4. **"Don't touch \<file\>."** Name the files another run owns right now.

While it tests: write nothing to the same files. When the report comes: **don't take it at
its word.** Fetch the file and diff against the last commit before believing anything; if
the report says a number is wrong, compute against the file, not the report.

## After the round
- **Confirmed** → update the change log with "verified *by them*", not only by you.
- **Failed** → recover first, investigate after.
- **Findings out of scope** → the findings inbox in the notes, not the tracker.

## Common mistakes
| Mistake | Fix |
|---|---|
| "Check that it looks fine" | a number or concrete text, or it isn't a test |
| 15 points | 6–8. The rest belongs in the code check |
| Asking them to verify something grep could settle | do it yourself first |
| No "wrong if" | they have to ask to know whether it failed |
| A number without its filter | state the filter |
| Code names in "Open" | the screen names they use |
| No recovery line | one sentence, always |
| A test round for something not uploaded yet | check that it is actually there |
