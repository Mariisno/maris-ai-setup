# The role catalogue — a craft, with the domain as its label

A specialist is named by **what it can do** (the role) and **where it works and whom it
reports to** (the domain). The two are separate files, so one `ux/ui` role serves every
domain, and one `domains/work.md` tells every role who the lead is and what is off limits.

```
roles/
├── ux/        service-design · ui · microcopy · critic
├── dev/       frontend · backend · mobile
├── product/   tracker                (issues, boards, tickets)
├── test/      tester
├── ops/       watch · harvest        (pointers to the watch and harvest skills)
└── domains/   work · hobby           (examples: copy one per real domain)
```

| The question is … | Role |
|---|---|
| Which problem are we solving, for whom? | `ux/service-design` |
| What should the screen look like? | `ux/ui` |
| What should it say? | `ux/microcopy` |
| Is the design done? | `ux/critic` |
| Build it, in code or as a mockup | `dev/frontend` |
| What does the system do under the hood? | `dev/backend` |
| How does the app do it? | `dev/mobile` |
| Put it on the board or in the tracker | `product/tracker` |
| Does it work? What do I click on? | `test/tester` |
| Hygiene across all leads · insight that slipped | `ops/watch` · `ops/harvest` |

## How it is used

```sh
lola-spawn --role ux/ui --domain work [--name ANNA] [--window ui-work] \
           [--model claude-opus-5-5] [--effort high] "the assignment"
```

- The pane label becomes `UI · Work (LOLA)` (with `--name`: `ANNA · UI · Work (LOLA)`).
- Model and effort come from the role file when they are not given.
- The assignment gets the preface *"Read `<roles>/ux/ui.md` and `<roles>/domains/work.md` first."*
- The positional form still works: `lola-spawn <window> <label> <model> <effort> [assignment]`.

**Machine-readable line.** The first line of every file is a comment the script reads:
`<!-- machine: role=UI model=claude-opus-5-5 effort=high -->` in a role,
`<!-- machine: name=Work lead=LOLA -->` in a domain. Change the values, keep the form.

**A new role?** One file in the right folder, with the same sections: what the role does ·
pick it when · loads · default · standing rules · not this role's job. Check that every skill
and script it names exists before you write it down.

**A new domain?** Copy `domains/work.md`, fill in the lead (a NAME from `LOLA_LEADS`), where
the inbox is, which repositories and notes to read first, and who owns what. The domain file
is where the real names live: people, boards, products. Roles stay generic.

**Where the catalogue lives.** It ships inside the plugin. To edit it without touching the
plugin, copy the folder and set `LOLA_ROLES_DIR` in `~/.lola/config.sh`.
