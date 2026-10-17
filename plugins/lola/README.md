# Lola — the plugin

The lead/specialist method for running several Claude Code sessions in parallel, packaged
as a Claude Code plugin. The repository this folder lives in,
[Mari's AI Setup](../../README.md), explains the whole setup and how to install it in five
minutes; this file is the plugin's own reference.

## What's in it

| Part | What it does |
|---|---|
| `lead` skill | The method for a lead: roles, channels, the five-part brief, the gates, rule four and rule five, the tmux mechanics |
| `specialist` skill | How a specialist starts, works and finishes: receipt first, session log, queue, `/exit` |
| `watch` skill | WATCH role: a scheduled hygiene round that closes finished panes and routes findings |
| `harvest` skill | HARVEST role: a daily sweep that saves the insight leads missed, and a weekly "threads and connections" note |
| `setup` skill | First-time setup, a health check, and bringing everything back after a restart |
| `roles/` | The role catalogue: a craft per file (`ux/ui`, `dev/backend`, `test/tester` …) and a domain per file (`domains/work.md`), read by `lola-spawn --role` |
| `lola-spawn` | Start a specialist pane, from the catalogue or by hand; verify model, effort and account in the banner; cap per lead; send the brief |
| `lola-send` | Send a message to a pane and verify it landed; long messages go as a file |
| `lola-revive` | Rebuild the lead sessions after a restart. Starts claude only in empty shells, and leaves alone any tmux session Lola didn't create |
| `lola-watch-report` | The deterministic checks behind WATCH |
| `lola-dig-guard` | A hook that warns a lead when it starts doing the digging itself |
| `lola-init` | Create the config, inboxes, queue and folders. Idempotent |

## One config file

Everything personal lives in `~/.lola/config.sh` (override the path with `LOLA_CONFIG`).
Every script and skill reads from it. [`templates/config.example.sh`](templates/config.example.sh)
documents each key:

| Key | Default | What it is |
|---|---|---|
| `LOLA_USER_NAME` · `LOLA_LANGUAGE` | `you` · `English` | how sessions address you, and the language they write notes in |
| `LOLA_LEADS` | one lead, `LOLA` | `NAME\|domain\|tmux session\|working dir`, one row per lead |
| `LOLA_SPECIALIST_SESSION` | `engine-room` | the detached tmux session where specialists live |
| `LOLA_ACCOUNTS` | your default `~/.claude` | `name\|config dir\|plan label`, one row per Claude account |
| `LOLA_NOTES_DIR` · `LOLA_NOTES_STYLE` | `~/.lola/notes` · `markdown` | any folder of Markdown, or an Obsidian vault (`obsidian` switches to `[[wikilinks]]`) |
| `LOLA_QUEUE_FILE` | `<notes>/Waiting on you.md` | the queue: only what waits on *your* answer |
| `LOLA_ROLES_DIR` | the plugin's `roles/` | point it at a copy to edit roles and add domains |
| `LOLA_SPECIALIST_CAP` | `5` | how many specialists one lead may have alive at once |
| `LOLA_LABEL_OPTION` | `@label` | the tmux option that holds a pane's label (its identity) |
| `LOLA_DIG_GUARD_EVERY` | `4` | warn a lead after every N reading calls in a turn; `0` turns it off |
| `LOLA_USAGE_DIR` | `~/.lola/usage` | where the status line writes one usage snapshot per account |

## Safety

- Nothing in Lola sends anything off your machine. `lola-watch-report` reads GitHub only if
  you set `LOLA_GITHUB_USER`.
- **Files:** `lola-init` creates the config, the inboxes, the queue and empty folders, and
  never overwrites. `lola-send` writes long messages as files in the assignment folder.
  `lola-spawn` holds a short lock file in `~/.lola` while it counts. Nothing else writes
  files; `lola-watch-report` only reads.
- **tmux:** `lola-spawn` and `lola-revive` create sessions and windows, label panes, and
  start claude in empty shells. They mark everything they create with the tmux option
  `@lola` and change nothing that lacks the mark: a session of yours with the same name is
  reported and left alone. No script closes a pane, except `lola-spawn` closing the pane it
  just made when the banner check fails. Closing finished specialists is WATCH's job, and
  only inside the specialist session.
- `lola-send` types only into panes in Lola's specialist session, and refuses a pane that
  shows a menu or a permission prompt.
- HARVEST reads your own session transcripts on your own machine to find what you decided.
  It writes only to your notes folder.

## Tests

```sh
test/run.sh
```

No dependencies beyond bash and awk, and no tmux needed. It checks that every script
parses, that `lola_shows_menu` refuses real menus and never a pane at its composer, that
every role and domain file carries a complete machine line, that `lola-spawn --role`
resolves label, model, effort and lead (dry run), and that `LOLA_LABEL_OPTION` is validated
and read by the scripts.

## License

MIT. See [LICENSE](LICENSE).
