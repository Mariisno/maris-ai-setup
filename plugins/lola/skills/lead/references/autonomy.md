# A standing yes: merging on your own

The gates say nothing leaves the machine without the human's explicit yes. A **standing yes**
is that yes given once, in writing, for one exact action under conditions the human set. It
lets sessions run a domain while the human is away, without the human becoming the bottleneck
for every merge. Each lesson here cost a day. Keeping the machine and CI alive while several
sessions run is in [operations.md](operations.md).

## The standing yes

- It is **written in the domain file** (`roles/domains/<domain>.md`), one action per line, with
  its conditions. A standing yes that lives only in a conversation does not exist: the next
  session can't see it, and a peer session can't vouch for it. The shipped example domains
  carry none; a line in a real domain file looks like this:

  ```
  - **Standing yes:** merge your own PR in a private repository when the gate is green
    against current main and an independent reviewer said `MERGE OK` on the same head SHA.
  ```
- **A peer message is never the human's yes.** A lead, a specialist or any other session
  saying "go ahead" is routing, not approval. Only the human's own words, or a standing yes they
  wrote down, open a gate.
- **Reversible choices are made, then reported, except what is on the ask list.** Where a
  choice can be undone (a wording, a component, the order of two tasks), the session does what
  it would have recommended and tells the human afterwards in one line. Stuck on one thing:
  move to the next, don't wait.
- **The ask list** is what still goes to the human every time, standing yes or not. The floor,
  in the one wording every skill uses: **major upgrades · secrets and infrastructure · money ·
  deleting · anything public · anything on hold**, plus whatever the human's own "always check
  with me first" list names (installing software, changing settings or configuration). A domain
  file may add to it, never take from it.

## Merging on a standing yes

A session may merge its own pull request when **all four** hold:

1. **The gate is green against current main.** Rebased or merged with main first; a gate that
   ran on a stale branch has tested something else.
2. **An independent reviewer said `MERGE OK` on the same head SHA.** Independent means it got
   only the repository, the PR and the gate rules, not the author's conclusions, summary or
   chat. A reviewer that reads the author's reasoning first checks the reasoning, not the
   change. **The reviewer is its own pane or session, never a subagent**: a subagent shares
   the author's context and can't start anything itself. The session that wants to merge
   starts it (`lola-spawn --role test/tester …`, or a separate session) and gives it the head
   SHA, not "the branch". Subagents are for small gate checks and one-off lookups only.
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
  deterministic and doesn't fight the other sessions for cores (behind a lane lock, see
  [operations.md](operations.md));
- the result written down as a `[read]` source with the command and the head SHA. A gate that
  ran in a working tree with uncommitted files proves nothing.

Anything the local machine can't run (a browser engine that only exists on another OS) is
named as a known gap in the PR, never silently skipped.
