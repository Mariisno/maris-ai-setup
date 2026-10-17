---
name: setup
description: Use when the user wants to set up Lola for the first time, add or rename a lead, point Lola at a notes folder or Obsidian vault, add a second Claude account, check that the setup works, or bring the lead sessions back after a restart.
argument-hint: "[init | doctor | revive]"
---

# Lola setup

Everything personal lives in ONE file, `~/.lola/config.sh` (or `$LOLA_CONFIG`). The scripts
and skills read from there; nothing else needs editing.

## init — first time (also safe to re-run)

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/bin/lola-init"`. It creates only what is missing: the
   config, one inbox per lead, the assignment folder, the queue, the session log and insight
   folders. It reports what it created and what it kept.
2. Ask the user, one question at a time, only what the defaults can't know:
   - **Leads:** one is enough to start. If they work in clearly separate domains (a product, a
     codebase, a client), offer one lead per domain. Each row is
     `"NAME|domain|tmux session|working directory"`.
   - **Notes:** keep the default plain folder, or point `LOLA_NOTES_DIR` at an existing folder
     or Obsidian vault (then set `LOLA_NOTES_STYLE="obsidian"`).
   - **Language** for notes and reports (`LOLA_LANGUAGE`).
   - **Accounts:** only if they run sessions on more than one Claude account
     (`"name|config dir|plan label"`).
   - **Domains:** `roles/domains/` ships two examples (`work`, `hobby`). Offer to copy one per
     real domain (set `LOLA_ROLES_DIR` to a copy of the catalogue first, so the plugin's own
     files stay untouched) and fill in the lead, inbox, repositories and who owns what.
3. Edit the config with their answers, then re-run `lola-init` so new leads get inboxes.
4. Run `doctor` below.
5. Tell them how to start: `bash "${CLAUDE_PLUGIN_ROOT}/bin/lola-revive"` creates the lead
   sessions; `tmux attach -t <first lead's session>` shows them. In the lead, the `lead`
   skill carries the method.

## doctor — does it work?

Check, and report each as ✓ or ✗ with the fix:

- `tmux`, `jq`, `python3` and `claude` are on PATH; `claude --version` is 2.1.284 or later
- the config file exists and sources cleanly: `bash -n ~/.lola/config.sh`
- every lead in `LOLA_LEADS` has an inbox file
- the queue file exists and has a `## Open` table
- `bash "${CLAUDE_PLUGIN_ROOT}/bin/lola-watch-report" --no-gh` runs and prints a report
- the dig guard is active: it ships as a hook in this plugin, so it is on whenever the plugin
  is enabled, and silent outside lead panes. `LOLA_DIG_GUARD_EVERY=0` in the config turns it off.

## revive — after a restart

Run `bash "${CLAUDE_PLUGIN_ROOT}/bin/lola-revive" --dry` first and show the user what it
will do; then run it without `--dry`. It never starts claude on top of a running program,
and it only changes tmux sessions Lola created (marked with the tmux option `@lola`). If it
reports `SKIP` for a session, the user has a session of their own with that name: offer to
rename theirs or to pick another session name in `LOLA_LEADS`. Don't touch theirs.
Afterwards, check each lead: its first answer should show it knows its role. If a lead woke
up empty, `claude --resume <conversation id>` in that pane picks the right conversation.
