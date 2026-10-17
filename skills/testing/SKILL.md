---
name: testing
description: Use when something is to be tested or verified in design or prototype work — to make a test round, to judge a test report, or to decide which test layer is needed before something is called done. Triggers - "make a test", "can you test", "the test report came", "is this tested?", "verify this", a build round nearing done, «lag en test», «er dette testet».
license: MIT
metadata:
  author: Mari Svennevik Notland
  source: https://github.com/Mariisno/maris-ai-setup
---

# Testing — three layers, and none of them counts for another

> **Is it `test-round` you want?** This skill owns the **method**: which test layer applies,
> and whether something is tested well enough to be called done. If the person is going to
> test it themselves and needs to know exactly what to click, `test-round` owns that **form**.
> Overlapping triggers, different jobs: "does this hold?" is here, "what do I do now?" is `test-round`.

## Core principle

Testing has layers, and **one layer is never good for another:**

| Layer | The question it answers | Who / tool |
|---|---|---|
| **Code test** | Does the logic work? Data is written, states flip, nothing crashes | Claude Code: headless asserts (the real code, never copies) + harness clicks with a browser tool |
| **Visual agent test** | Does it render, and does it look systematically right? | an agent run: routes + screenshots + "not asked for" |
| **The person's test** | Is it RIGHT? Readability, feel, judgment | the person — **always the last gate** |

Consequences: always say WHICH layer a verification covers ("harness-verified" = the code
layer only) · nothing is "fully tested" before all relevant layers ran · never ask the person
to repeat a layer an agent already ran; their time goes to the layer only they can take.

## Which layer when
- **While building:** a code test per step (assert → edit → parse → harness in the same run → commit).
- **After a delivery round:** a visual agent test, then the person's look.
- **On a reported "bug":** suspect the environment before the code (the traps below).

## Rule 0 and environment traps (each has cost a round)
- **Same page load.** A prototype without persistence resets on reload. Action and ALL
  checks in the same page load; the report must say whether the page was reloaded.
- **Browser cache in a local harness.** A plain static server sends no cache headers, so
  old code runs after an edit. Fix: a version stamp on script URLs and the page; bump it on
  every change.
- **The filter first.** Every expected number holds UNDER a filter (a view, a type, a
  status). A number without its filter stated is not a deviation.
- **The test creates its own data.** An agent that creates demo records and then reports the
  count as a deviation. Require the test to list what it created itself.

## A test prompt for an agent (checklist)
⛔ "change no line of code" · Rule 0 in bold · a pointer to the route list (never duplicate
it) · report format `# | action | observed | OK/DEVIATION`, with the observed value ALSO when
it matches · a separate "Not asked for" section (1–3 observations) · a concrete screenshot
list. **Model: the strongest available, high effort.** Medium has missed the "not asked
for" findings, which is where real bugs turn up.

## Reviewing the report
1. Point by point against the expected result.
2. Deviation → check the environment traps BEFORE suspecting the code; reproduce in your own
   harness before anything is called a bug.
3. Real deviations are fixed in code by the builder (traceability), never by the test agent.
4. A green report ≠ done: the person's gate remains.

## Common mistakes
| Mistake | Fix |
|---|---|
| "E2E green" read as fully tested | Name the layer: code ≠ visual ≠ the person's gate |
| The visual test recounts what headless already proved | The visual test weighs what eyes see: screenshots, readability |
| Reported bug → straight into the code | Environment traps first; reproduce yourself |
| Test prompt on medium to save tokens | Strongest model · high |
| Expected numbers duplicated into the prompt | Point at the one route list |
| Asking the person to verify counts | Their layer is judgment, not counting |
