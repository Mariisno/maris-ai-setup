# tmux mechanics for leads

Hard-won details. Each one cost real time, usually a lost message or a nearly closed wrong pane.

## Layout

- The lead's window is what the human sees. **All specialist panes live in the detached
  specialist session** (`LOLA_SPECIALIST_SESSION`). Detached is the point: the human
  shouldn't have to look at specialists. If they want to look inside one, they ask; a task
  for the human never points there.
- **Ownership:** every session and window the scripts create carries the tmux option
  `@lola 1`. The scripts change nothing without it, so a same-named session of the human's
  is safe. Target sessions with `=name` for an exact match: plain `-t name` also matches by
  prefix.
- **Labels are identity:** `tmux set-option -p -t %N @label "NAME · role (LEAD)"` (the option is `LOLA_LABEL_OPTION`, `@label` by default) plus
  `pane-border-status top`. Pane titles lie (programs rewrite them); the label option doesn't.
- Specialists start with `claude --model <m> --effort <e>; exit`, so the pane closes when
  the specialist runs `/exit`. Effort as a flag, never `/effort`: that one is saved to
  settings and changes every later session.

## Sending

- `lola-send` delivers through a paste buffer (atomic) and then checks the scrollback.
  Typing with `send-keys -l` loses races against startup screens, and the Enter after it can
  be swallowed by slash-command autocomplete.
- Never send text into a pane that shows a menu or a permission prompt: digits in your
  message can answer it. `lola-send` refuses; answer the prompt first.
- **`Escape` is the emergency stop.** It always works.
- Long assignments go as a file; the pane gets one line pointing at it. A long paste can
  arrive in part; a file can't.
- A lead can answer a plan-approval prompt in a specialist pane for pure read-only work.
  Anything else goes to the human.

## Seeing

- Sweep **all** sessions (`tmux list-panes -a`), never only your own. A cropped picture gives
  no conclusion.
- Pane contents can move between pane ids (a window is moved, a pane is reused). Check the
  label against what the pane shows, regularly.
- tmux's `window_activity` is useless for claude panes when a status line redraws every
  second. Claude Code's session registry (`<config dir>/sessions/<pid>.json`, with `status`
  and `statusUpdatedAt`) tells idle from busy.

## Closing

- **Before `kill-pane`, always `capture-pane` on the same pane in the same moment**, and check
  the content matches the label. Panes get reused and labels go stale; closing on a stale
  label kills the wrong session.
- Close only panes in the specialist session. Never a lead, never a pane the human works in,
  never one that is busy or shows a question.

## Moving

- `move-window`, `new-session` and `rename-session` kill no process, but **a lead moved into a
  session nobody is attached to lives on without a screen.** After every such operation,
  read `#{session_attached}` on the target session. If it is 0, tell the human in the same
  reply, with the exact command: `tmux attach -t <session>` in a NEW terminal tab (not
  `switch-client`, which takes over the tab they're in).
- Grouped sessions die when their last window moves out, and clients detach before a
  `switch-client` can run. Group only when a shared window list is really wanted.

## After a restart

- `lola-revive` rebuilds lead sessions and resumes leads with `claude --continue`, which picks
  the most recent conversation in the pane's directory. Several sessions sharing a directory
  can make it pick the wrong one: use `claude --resume <id>` when you have the id.
- Check that no orphaned process still holds a lead's old transcript (`lsof <transcript>`):
  orphans can come back to life and run monitors twice.
- A lead isn't back until its first answer shows it knows its role. Verify; don't assume.
