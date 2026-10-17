# Grounding — techniques against claims without support

> Condensed from the vendor's guidance on reducing hallucinations, long-context prompting,
> agentic coding and the strongest model's progress-claim guidance. This is the technical
> backbone under a notes rule many people already have: **no claim without a source.**

## ⚠️ Conflict rule, read first
Generic guardrail advice recommends "chain-of-thought verification" and "iterative
refinement". The per-model pages partly say the opposite: the current strong model should
have verification instructions *deleted*, and the strongest model can refuse instructions to
reproduce its own thinking. **When they collide, the model-specific page wins.**

| Technique | Status on current models |
|---|---|
| Ground claims in **quoted excerpts from the source** | ✅ works, unchanged. This is grounding |
| Require that every claim points to a **tool result** | ✅ works, unchanged |
| "Double-check your answer" / a self-verification step | ❌ delete: over-verification without gain |
| "Show me your reasoning" / transcribe the thinking | ⚠️ can trigger a refusal on the strongest model |

In short: **ground in sources, not in self-examination.**

## The techniques that apply
1. **Give explicit permission to say "I don't know".** The simplest and most effective.
   Without it the model fills the gap. "If the material lacks the information, write 'I
   don't have enough grounds to assess this' instead of estimating."
2. **Quote first, analyse after** (documents over ~20k tokens). Ask for verbatim excerpts
   before the task is solved, numbered; build the analysis **only** on them. None found ⇒
   "no relevant quotes found".
3. **Post-check with a quote requirement.** For each claim in the draft, find a quote that
   covers it. None ⇒ **remove the claim**, don't soften it.
4. **Shut out general knowledge.** Use **only** the attached material, not what the model
   knows from before. Matters most when the topic is something the model "knows" generally:
   design systems, component names, platform conventions.
5. **Ground progress claims in tool results** (long runs). "Before reporting progress,
   check each claim against an actual tool result from this session. Report only work you
   can point to evidence for; if something isn't verified, say so. Failing tests are
   reported with their output; a skipped step is named as skipped."
6. **Read before you speak** (agentic coding). Never speculate about code you haven't
   opened. If a file is named, read it before answering.

## Placement in long prompts
Long documents at the top, above the question, instructions and examples. Structure with
`<documents>` › `<document index="n">` › `<source>` + `<document_content>`.

## The limit
These techniques **reduce** hallucination; they don't remove it. Critical information is
still validated, especially before something ships or is shown to a team.
