# Prompt craft

> Condensed from the vendor's prompting guides (prompting best practices, the per-model
> pages, and the thinking/effort page). Re-verify against the live docs when the guidance
> feels stale; the model ids and effort facts are in `Skill(claude-api)`.

The prompt is the **third** lever when setting up and the **last** when debugging (see
`SKILL.md`). This file is the technique once you are there.

## The golden rule
> Show the prompt to a colleague with minimal context and ask them to follow it. If they get
> confused, the model will too.

Think of the model as a capable new hire who doesn't know your norms and workflow.

## Principles
1. **Be explicit about what you want.** Want "above and beyond"? Ask for it.
2. **Give the reason, not only the rule.** The model generalises from the explanation; a rule
   without a why is followed literally and wrongly at the edges. For the strongest models
   this is the single most effective move: "I'm working on [the larger task] for [whom].
   They need [what the result enables]. With that in mind: [the assignment]."
3. **Examples are the most reliable steering.** Three to five, relevant, varied (cover edge
   cases, vary enough that no accidental pattern is learned), wrapped in `<example>` tags.
   **Positive examples beat negative instructions**, for length, tone and format alike.
4. **Structure with XML tags** when the prompt mixes instruction, context, examples and
   input: `<instructions>`, `<context>`, `<input>`. Consistent names; nest when natural.
5. **Give a role.** One sentence moves tone and focus noticeably.

## Format steering, in order of effect
1. Say what to do, not what not to do ("write in flowing prose" beats "no markdown").
2. Use XML as the format indicator.
3. Match the prompt's style to the output you want.
4. Be detailed when you have a specific preference.

## Tool triggering
Models read precisely. "Can you suggest some changes?" yields **suggestions**, not changes.
Want action: "Change this function to …". Want only an assessment: "Make no changes until I
ask. Report your findings." Want a tool used more often: describe *when and why* in the
tool's own description, not only in the system prompt.

## Long documents
Put the documents at the top, above the question and the instructions. Quote before you
analyse (see `grounding.md`).

## Model-specific (current generation)
| Behaviour seen | Move |
|---|---|
| Longer answers than earlier models | Prompt for brevity; effort is not the lever |
| Narrates between tool calls | Describe the cadence you want: one sentence before the first call, short updates only on findings, the outcome first at the end |
| Verifies its own work unasked | **Delete** verification instructions (see `skill-hygiene.md`) |
| May widen scope | Scope discipline: deliver what was asked, flag a concern in one sentence, never narrow or widen quietly |
| Delegates to subagents willingly | Set a **cap** |
| Literal on low effort (smaller models) | State the scope: "applies to all sections, not only the first" |
| Design defaults look templated (smaller models) | A concrete spec (hex, type, radius, spacing), or "propose four distinct directions first, implement only the chosen one" |
| The strongest model: short instruction beats a list | One sentence steers most behaviours |
| The strongest model: asked to transcribe its thinking | Can refuse (reasoning extraction). Asking for a *rationale* is fine |
| The strongest model on long runs | Ground progress claims in tool results (see `grounding.md` §5); give it a memory file |

## Anti-patterns to stop
| Pattern | Why it is wrong now |
|---|---|
| `CRITICAL: You MUST …` | Over-triggers. Current models follow the system prompt closely. Write "Use … when …" |
| "If in doubt, use [tool]" | Written to overcome old reluctance. Delete |
| "Double-check your answer" | Over-verification, no quality gain |
| "After every third tool call, summarise progress" | Models do this themselves. Remove the scaffold |
| Lowering effort for shorter answers | Wrong lever. Prompt for length |
| Prose steering before effort is tuned | Effort is calibrated; prose is wording-sensitive. Effort first |

## The limit of the prompt as a lever
Not every failing result is best solved by prompt engineering. If the model isn't strong
enough, or effort is too low, no rewrite helps. Check the first two levers first.
