# LinkedIn Thought-Leadership Engine

**Goal:** make the founder the recognizable authority on Microsoft Modern Workplace / Entra / Intune /
Purview problem-solving, so IT Directors, CISOs, consultants, and MSPs come to you. Your content already
exists — it's the answers you write. This just repurposes them on a cadence.

## Positioning (the through-line of every post)
> "I solve the hard Microsoft endpoint/identity/data problems — and I hand you the click-by-click runbook
> to fix it yourself. Engage a catalog of 400+ ready-to-deploy solutions, not a headcount."

## The 4 post formats (rotate them)
1. **"Saw this in the wild" fix** (your bread and butter). A real error/scenario → the mechanism → the
   fix. E.g. `JoinNotFound`, PLAP `0x87D30067`, source-anchor breakage. High save/share rate.
2. **Myth / "you're doing it wrong"** — a common misconfig (e.g. "Clear quarantine ≠ Restart sync";
   "objectGUID as your source anchor will orphan every account you migrate"). Provocative, useful.
3. **Carousel: "5 steps to X"** — a solution's phases as a swipeable (Autopilot pre-logon, DLP rollout).
   Carousels get the most reach on LinkedIn right now.
4. **Behind-the-build / proof** — "Someone asked X in a forum this morning; here's the runbook we shipped
   by lunch." Shows the "built in 1 day" promise is real. Screen-record `/create`.

## Cadence (sustainable)
- **3 posts/week**: Mon = "saw in the wild" fix · Wed = carousel or myth · Fri = behind-the-build/proof.
- Each post: **hook (line 1 stops the scroll) → the value (steps/mechanism) → soft CTA.**
- CTA rotation: "full runbook → workplace.phoenixtekk.com" · "describe your problem → /create" ·
  "comment 'RUNBOOK' and I'll send it." Always tag the link `?src=linkedin`.
- Engage 15 min/day in the comments of others' Intune/Entra posts — that's where reach is earned.

## Hooks that work for this audience
- "If your Entra Connect source anchor is objectGUID, your next domain migration will orphan every account. Here's why — and the 4-step fix."
- "'JoinNotFound' in cloud sync isn't a per-user bug. It's a stale watermark. Clear quarantine won't fix it. Restart sync will."
- "A GlobalProtect PLAP deploy failing with an 'unzipping' error during Autopilot? It's Intune 0x87D30067. Here's the real cause."
- "You don't need to hire a Modern Workplace engineer. You need the runbook they'd write. We have 400+."

## Assets to make once, reuse forever
- A **branded post template** (your navy/green, the `512x512` logo) for carousels.
- A **30–60s screen recording** of `/create` (describe a problem → get matches/queued). This is your best top-of-funnel demo.
- A pinned **"start here"** post: what the catalog is, the "engage a catalog not a headcount" pitch, links to `/start` and `/create`.

## Measurement
- All links `?src=linkedin` → `tools/leadgen-digest.py` shows conversion vs other channels.
- Track which **format** drives profile visits → site clicks; double down on the winner.

See `linkedin-starter-posts.md` for 6 posts ready to publish now (repurposed from answers already written).
