---
name: task-brief
description: Use when a task is to be formulated for the best result — how the prompt is built, which context must be grounded, which kind of task this is — and when an answer didn't hold and you must find out whether it lacked knowledge, effort or context. Also owns the paste-ready prompt rule - every prompt handed to the person comes with a model and effort recommendation. Triggers - "how should I prompt this", "help me write the prompt", "the answer was poor", "why was it so bad", "what context does it need", before every paste-ready prompt, «hvordan bør jeg prompte dette», «svaret ble dårlig».
---

# Task brief — how to formulate the task

> **What this skill owns:** the prompt craft, the grounding (which context the task needs so
> it doesn't guess), the task types, and the diagnosis when an answer didn't hold: did it
> lack *knowledge*, *effort* or *context*?
>
> **What it doesn't own:** the model ids, prices and effort levels. Those come from the
> built-in `claude-api` skill, which the vendor maintains. Look them up there; never repeat
> numbers from here or from memory. The default model and effort for your setup live in
> `~/.lola/config.sh` (`LOLA_LEAD_MODEL`, `LOLA_LEAD_EFFORT`) and in the role catalogue.

## 1. Three levers, two orders

The most common mistake is treating the levers as one ranked list. The order depends on
*when* you ask.

**Setting up a task:** `spec → model → effort`.
You can't tune what you haven't specified. The spec decides the difficulty, the difficulty
decides the model, the model decides the effort ladder. An under-specified task burns tokens
on any model.

**The result didn't hold:** `effort → model → prompt`.
Effort is cheapest and most reversible. Change model when effort doesn't reach. Rewrite the
prompt last, and only when the problem actually *is* wording.

**Mid-session** model and effort are locked (switching tears the prompt cache). Two levers
remain: `ultrathink` anywhere in the prompt (deeper reasoning for one turn; "think hard" is
not a keyword) · `effort` in a skill's front matter (overrides the session level while the
skill runs). If neither reaches: a new session at higher effort.

## 2. The diagnosis, when the answer was poor

Ask one question: **did it lack knowledge, effort or context?**

| Gap | Symptom | Lever |
|---|---|---|
| **Knowledge** | a genuinely hard problem, an unknown domain, a subtle bug: it is confidently wrong | a stronger model |
| **Effort** | skipped files without reading them · didn't run the needed tests · gave up multi-step work early | raise effort |
| **Context** | didn't know enough about *your* situation | a better prompt, clearer instructions, attach files |

The three effort symptoms are the checkable part. Use them over gut feeling.

## 3. The stance

**Quality first.** Vendor docs are written for API customers optimising cost in production.
That is not the frame for someone's daily work.

- Effort levels don't mean the same across models. Set a level that fits the way you work
  (`medium` for mechanics, `high` for judgment), and handle exceptions with front matter or
  `ultrathink`, not by micro-tuning per task.
- **Judgment work** (design decisions, critique, a new direction) → the default strong
  model at `high`. The strongest model is a **deliberate step up** when the assessment is
  long and ambiguous, the default didn't hold, or a direction is expensive to get wrong.
  Say in one line that it is used.
- **Pure mechanics with a clear answer** → a lighter model is fine. Not because it is
  cheaper, but because a heavy model buys nothing there.
- Cost is a **tie-breaker** between equal options, never a first choice.

## 4. The paste-ready prompt rule

Every paste-ready prompt you hand the person (a start prompt, a follow-up, an ad hoc one)
comes with **model + effort + where it runs**. Where a surface has no effort selector,
recommend the model alone; don't invent a setting. The recommendation goes in the chat
*around* the prompt, never inside the prompt file.

### The literal template, two fields, both required

```markdown
**Runs in:** <surface> · **The task requires:** <model> · <effort>
**Practical considerations:** <quota · time · cost — or "none">
```

- **Line 1 answers one question alone: what does the task require?** Decided by §3.
- **Quota, time and cost are NEVER allowed to change line 1.** They go in line 2, as
  information the person weighs themselves. A quiet downgrade is a bad basis for a decision,
  not a consideration.
- An empty line 2 is written as "none". A missing line 2 is an unfinished recommendation.

> Why a template and not a reminder: the rule stood as prose in two places and still slipped
> twice (the strongest model presented as a downgrade; a weaker model recommended with quota
> as the hidden reason). A rule that slipped after being written down needs form, not
> stronger wording. Two separate fields make the mix-up structurally impossible.

## 5. Where to look things up

| Question | File |
|---|---|
| How to phrase the prompt · model-specific prompting · anti-patterns | `references/prompt.md` |
| Grounding claims in sources · avoiding unsupported claims | `references/grounding.md` |
| How your own skills should be worded for current models | `references/skill-hygiene.md` |
| Model ids, prices, API parameters | `Skill(claude-api)`, the primary source |

## Common mistakes
| Mistake | Fix |
|---|---|
| Lowering effort to get shorter answers | Wrong lever. Effort steers thinking volume, not length. Prompt for length |
| "think hard" in Claude Code | Not a keyword. Use `ultrathink` |
| Switching effort mid-session | Tears the cache. Use `ultrathink` or front matter |
| Downgrading by reflex to save tokens | Quality first. Cost is a tie-breaker |
| Recommending a weaker model because quota is tight | Quota goes in **line 2**, never line 1 |
| One-line recommendation without "Practical considerations" | Both fields are required. None ⇒ write "none" |
| Prompting harder at a session that runs too low | Diagnose first: knowledge, effort or context? |
| A paste-ready prompt without model + effort | §4 is mandatory |
| Answering from a reference file with an old date stamp | Re-verify against `claude-api` first |
