# Operations: CI minutes, a small machine, scheduled rounds

What keeps several sessions running side by side without the machine or the CI plan giving
out. The gate itself, and when to run it locally, is in [autonomy.md](autonomy.md).

## Fewer CI minutes

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
