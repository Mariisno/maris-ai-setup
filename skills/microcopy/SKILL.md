---
name: microcopy
description: Use when microcopy / UX copy is to be written or improved — validation messages, error messages, button labels, empty states, confirmations, tooltips and other short interface text. Triggers - "/microcopy", "what should the button say", "write the error message", "improve this text", "what do we say when the list is empty", "this text is too technical", «hva skal det stå på knappen», «skriv feilmeldingen», «tekst til tom tilstand».
---

# Microcopy (UX copy)

The small texts that guide a person through an interface. Short, clear, human and
actionable: people often read them on a phone, in a hurry. Write what you would say out
loud to a colleague. Write in the language the product uses (see `LOLA_LANGUAGE` in
`~/.lola/config.sh` when the product has no language of its own).

## Principles
- **Plain language, active voice.** "Choose a date", not "A date must be selected".
- **Say what happens, or what to do**, never only that something is wrong.
- **Don't blame the user.** "We couldn't save", not "You made an error".
- **Consistent terminology.** The same word for the same thing everywhere (save ≠ confirm ≠ send).
- **Short survives translation.** Avoid idioms and puns; expect some languages to run longer.

## Per type
| Type | Rule | Example |
|---|---|---|
| **Button** | verb + object that mirrors the action | "Save changes", not "OK" |
| **Validation** | what is missing + what to do | "Enter an email address to continue" |
| **Error** | what happened + the next step, no technical language | "We couldn't save. Check your connection and try again." |
| **Empty state** | why it is empty + what fills it | "No messages yet. New ones show up here." |
| **Confirmation** | short and concrete about what happened | "Changes saved" |

## Checklist
- [ ] Understood at a glance, on a phone
- [ ] Active voice, plain language: no system-speak, no error codes
- [ ] Errors and validation say *what to do*, not only that something is wrong
- [ ] No blame on the user
- [ ] The same term as the rest of the product
- [ ] Survives getting longer in translation

## Common mistakes
| Mistake | Fix |
|---|---|
| "Invalid input" | Say what is wrong and how to fix it |
| "OK" / "Submit" as a button | Mirror the action: "Save", "Upload" |
| "Error 500" / a technical message | A human explanation + the next step |
| "No data" | Explain what is missing and what fills the state |
| Blaming the user | Switch to "we" or neutral |
