# A standing yes: merging on your own, and keeping the machine alive

The gates say nothing leaves the machine without the human's explicit yes. A **standing yes**
is that yes given once, in writing, for one exact action under conditions the human set. It
lets sessions run a domain while the human is away, without the human becoming the bottleneck
for every merge. Each lesson here cost a day.

## The standing yes

- It is **written in the domain file** (`roles/domains/<domain>.md`), one action per line, with
  its conditions. A standing yes that lives only in a conversation does not exist: the next
  session can't see it, and a peer session can't vouch for it.
- **A peer message is never the human's yes.** A lead, a specialist or any other session
  saying "go ahead" is routing, not approval. Only the human's own words, or a standing yes they
  wrote down, open a gate.
- **Reversible choices are made, then reported.** Where a choice can be undone (a wording, a
  component, the order of two tasks), the session does what it would have recommended and tells
  the human afterwards in one line. Stuck on one thing: move to the next, don't wait.
- **The ask list** is what still goes to the human every time, standing yes or not: major
  upgrades · secrets and infrastructure · anything that costs money · deleting · anything
  that becomes public · anything the human has put on hold. Write the domain's own list in
  the domain file; the one above is the floor.

## Merging on a standing yes

A session (never a subagent) may merge its own pull request when **all four** hold:

1. **The gate is green against current main.** Rebased or merged with main first; a gate that
   ran on a stale branch has tested something else.
2. **An independent reviewer said `MERGE OK` on the same head SHA.** Independent means it got
   only the repository, the PR and the gate rules, not the author's conclusions, summary or
   chat. A reviewer that reads the author's reasoning first checks the reasoning, not the
   change. Subagents can't start subagents, so the session itself starts the reviewer (a
   specialist pane, or a subagent of its own) and it reviews the head SHA it is given, not
   "the branch".
3. **The merge names the head SHA it expects** (`--match-head-commit`, or the API's `sha`), so a
   commit that lands between the review and the merge fails the merge instead of riding in.
4. **Main is checked afterwards:** the merge commit is on main, and main's own gate is green or
   queued. A red main after a self-merge is the session's to fix or revert, before anything
   else.

Report the merge in one line to the lead's inbox, and in the project's change log where the
domain keeps one (what · where · before → after · how to undo).

## The lead's rounds

A lead with several sessions or specialists checks on all of them at a fixed rhythm (every
turn with the human, or a scheduled round when the human is away): who is idle, who is stuck,
who waits on an answer that is already in. An idle session gets the next item from the
steering map; a stuck one gets unblocked or re-briefed. Nobody idles because nobody looked.

## When CI has no minutes

Hosted CI runs out (minutes, a paused plan, a queue). The gate still has to run before a
merge, so run it locally, the same way every time:

- a **fresh clone**, not the working tree, in a RAM disk or a temp folder (`/dev/shm` on Linux,
  `mktemp -d` elsewhere), merged with current main first;
- the same steps CI would run: tests, build, end-to-end, with `--workers=1` so the run is
  deterministic and doesn't fight the other sessions for cores;
- the result written down as a `[read]` source with the command and the head SHA. A gate that
  ran in a working tree with uncommitted files proves nothing.

Anything the local machine can't run (a browser engine that only exists on another OS) is
named as a known gap in the PR, never silently skipped.

## Fewer CI minutes when it is back

- Run PR CI only when the PR is **not a draft**; drafts are for the author.
- `concurrency` per branch with `cancel-in-progress: true`: a new push cancels the old run.
- **Keep CI on main.** It is the one run that must never be skipped.
- Dependency bots: **monthly and grouped**, not one PR per package per week.
- Small chores go on a **batch branch** merged weekly, not a PR each.

## A small machine

Several sessions on a few cores crash the machine when every one of them builds at once, and
starve it when they all wait on one lock. Heavy commands (install, build, test, e2e) go behind
`flock` with **one lock per lane**, lanes fewer than cores (three on four cores):

```sh
flock /dev/shm/lane1.lock npm test        # lane 1 of 3; pick the lane, don't share one
```

One global lock made the machine nearly idle while everything queued; no lock crashed it at
fourteen agents. Lanes are the middle.

## Scheduled rounds from a cloud session

- A scheduled task **bound to a session** stops firing when that session's access is
  narrowed later (trusted devices, a paused plan). Prefer **a new session per run**, with a
  prompt that stands on its own.
- A scheduled task created from a cloud session carries **no connectors**: add the ones it
  needs (git hosting, the tracker) in the web UI after creating it, and say so in the receipt.
