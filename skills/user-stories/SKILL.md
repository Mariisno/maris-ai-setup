---
name: user-stories
description: Use when user stories are to be written, reviewed or improved — when planning a feature or a slice, or when a requirement is a loose sentence that should be structured. Triggers - "/user-stories", "write a user story", "turn this into user stories", "is this story good enough", "which acceptance criteria do we need", «skriv en brukerhistorie», «lag user stories av dette», a requirement in loose prose.
---

# User stories

## What and why
A user story captures *who*, *what* and *why*, not the solution. It gives a developer and a
tester enough motivation to understand the value, and it breaks down into acceptance
criteria.

## Format (always)
> As a **\<role\>** I want **\<goal/action\>** so that **\<value/outcome\>**.

- **Role** = a concrete type of user (new user, administrator, guest), not "the user".
- **Goal** = what they want to achieve, not which button they press.
- **Value** = why it matters. The most important part.

## Acceptance criteria
Write 2–5, each verifiable (a tester can answer yes or no). Use Given/When/Then when flow or
state matters.

## Checklist before done
- [ ] Follows "As a … I want … so that …"
- [ ] The role is concrete, not "the user"
- [ ] "So that" describes real value, not a restatement of the goal
- [ ] No solution or UI detail in the story itself (that belongs in design + acceptance criteria)
- [ ] Small enough for one iteration; otherwise split it
- [ ] Has acceptance criteria

## Common mistakes
| Mistake | Fix |
|---|---|
| "As a user I want …" | Switch to a concrete role |
| "… so that I can click X" | Describe the outcome, not the action again |
| The solution is in the story | Move it to design or acceptance criteria |
| Too big (an epic) | Split into several stories |

## Example
**Weak:** As a user I want a button to save articles.

**Strong:** As a busy commuter I want to save articles for later offline reading, so that I
can read on the train without a connection.

Acceptance criteria:
- [ ] I can save an article from the reading view with one tap
- [ ] Saved articles are available without a connection
- [ ] I can clearly see that an article is already saved
