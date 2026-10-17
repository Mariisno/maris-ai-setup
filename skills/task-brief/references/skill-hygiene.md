# Skill hygiene — how your own skills should be worded for current models

> Condensed from the vendor's prompting guides and migration notes. Skills written for an
> older generation can **lower** quality on the current one: "Skills developed for prior
> models are often too prescriptive and can degrade output quality. Review and consider
> removing older instructions if default performance is better."

## The four rules
1. **Tone down command language.** Current models follow the system prompt closely;
   wording written to overcome old reluctance over-triggers. `CRITICAL: You MUST use …` →
   `Use … when …`. `If in doubt, use [tool]` → delete. **Don't over-correct:** a gate that
   fixes a *factual error* (read the live source, not a snapshot) is not scaffolding that
   asks for diligence. Keep the gates; soften the language that asks the model to try harder.
2. **Delete verification scaffolding.** The current strong model verifies its own work
   unasked. Instructions that *ask* for verification produce over-verification: more tokens,
   more latency, no gain. This is a deletion, not a rewrite, and it reverses a common best
   practice; a prompt library needs an exception here, not a global rewrite.
3. **The subagent direction has turned.** Older models under-delegated and needed
   encouragement; current ones delegate willingly, so they need a **cap**. Delegate genuinely
   independent, large tracks; don't delegate work that fits in a handful of tool calls, and
   don't use subagents to double-check your own work.
4. **Don't ask the model to reproduce its own thinking.** On the strongest model that can
   trigger a refusal. Asking for a *rationale* ("explain why you recommend this") is safe.

## What does NOT go into your global instructions file
The harness already delivers the current tuning in its system prompt: the correction rule
(correct only when the error changes the person's decision), scope discipline, "when you
have enough to act, act", and the subagent guard. Duplicating it gives two sets of
instructions that can pull against each other, and a copy that isn't updated when the
harness is. Your instructions file should own what is yours and only yours: workflow,
rules, who you are.

## Positive wording works best
Throughout the docs: **positive examples beat negative instructions.** "This is what it
should look like" steers better than "don't do X", for length, tone and format. That holds
for skills as much as for single prompts.
