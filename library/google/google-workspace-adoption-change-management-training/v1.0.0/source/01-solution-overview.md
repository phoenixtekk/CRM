# Solution Overview

## What this is

This solution is the **human side** of a large-scale Microsoft 365 → Google Workspace
transformation: the **adoption, organizational-change-management (OCM), and training program** that
makes a technically successful migration actually change how ~150,000 users work. A flawless mail,
Drive, and Chat cutover still fails if people keep working the way they always did — forwarding to
old inboxes, saving to shadow file shares, scheduling meetings in the wrong tool, or never touching
Gemini. This program engineers the behavior change that turns a *cutover* into measured *adoption*.

It is deliberately lighter on `gcloud` provisioning than the platform-build solutions in this
category and heavier on program design — stakeholder and champion networks, a structured
awareness → training → reinforcement arc, role-based learning paths, a hypercare/floorwalker support
model, and an adoption-measurement system. It still ships **five Python tools** that instrument and
operate the program against real Google APIs (Admin SDK Reports, Directory) — read-only or dry-run by
default.

## How it works

The program runs **wave-aligned to the migration**. Each migration wave (a set of users/OUs cut over
together) gets the same repeatable OCM cycle so that no cohort lands on Google Workspace
un-prepared and un-supported:

1. **Awareness** — before a wave cuts over, the comms campaign tells that cohort *what is changing,
   when, why, and where to get help*. Executive sponsorship and the champion network carry the
   message locally so it is not "an email from IT".
2. **Training** — role-based learning paths deliver *just-in-time* skills (Gmail, Drive, Docs/Sheets/
   Slides, Meet, Chat, and **Gemini where the wave is licensed**) sized to what each role actually
   does, with completion tracked as a go-live gate.
3. **Reinforcement** — after cutover, **hypercare** (a staffed support surface plus on-site or virtual
   **floorwalkers**) resolves the flood of "how do I…?" moments in the first days, and adoption
   metrics tell you whether usage is actually climbing or whether a cohort needs another push.

The **champion network** is the load-bearing structure across all three phases: a distributed set of
respected peers (roughly 1 per 50–100 users, tuned per org) who translate change locally, run
floor-level support, feed themes back to the program, and model the new tools. Champions are
recruited, trained ahead of their business unit, equipped with content, and recognized.

**Adoption measurement** closes the loop. The Google **Admin SDK Reports API** (Workspace usage
reports) and Directory data are read (never written) to compute per-wave, per-app active-usage
trends; training-completion is tracked from the LMS/roster; hypercare ticket themes are analyzed to
find where training or comms fell short. Those signals drive the next wave — this is a learning
program, not a one-shot launch.

## Reference design

```
                 Executive Sponsor(s)  ──►  visible mandate, funding, "tone from the top"
                          │
         ┌────────────────┼─────────────────────────────┐
         ▼                ▼                              ▼
   OCM / Adoption    Champion Network            Training Team
   Program Lead      (1 per 50–100 users,        (role-based paths:
   (this program)     per business unit)          Gmail/Drive/Docs/
         │                │                        Meet/Chat + Gemini)
         │                │                              │
         ▼                ▼                              ▼
   ┌───────────────────────────────────────────────────────────────┐
   │  Per-migration-wave OCM cycle:                                 │
   │  Awareness ──► Training ──► Cutover ──► Hypercare ──► Measure   │
   │     (comms)     (gated)              (floorwalkers)  (Reports)  │
   └───────────────────────────────────────────────────────────────┘
         │                                                  │
         ▼                                                  ▼
   Support surface (tickets, floor support)     Adoption metrics
   themes fed back into comms + training        (Admin SDK Reports API,
                                                 read-only) → next wave
```

Named artifacts this program creates and reuses (consistent convention
`<Purpose> – <Scope> – <Stage>`):

- `Adoption Program – Enterprise – v1` — the master OCM plan.
- `Champion Network – Enterprise – v1` — the champion roster/model, with per-BU sub-rosters
  (`Champion Cohort – <BU> – Wave N`).
- `Comms Plan – Enterprise – v1` — the awareness campaign calendar.
- `Learning Path – <Role> – v1` — the role-based training paths (e.g. `Learning Path – Frontline – v1`).
- `Hypercare Model – <Wave/Region> – Golive` — the staffed support/floorwalker plan per wave.
- `Adoption Metrics – Enterprise – v1` — the measurement plan and dashboard definition.
- `Adoption Pilot – Wave 0 – Pilot` — the pilot cohort that proves the whole cycle before scale-out.

## Benefits

- **Migration value is realized, not just delivered** — usage of the target tools actually rises, so
  the license spend and the migration effort pay off.
- **Repeatable per-wave playbook** — every cohort gets the same prepared, supported experience;
  quality does not degrade as the program scales to 150k users.
- **Local, trusted change agents** — the champion network makes change peer-led, dramatically cheaper
  and stickier than centrally-delivered support alone.
- **Evidence-driven** — real Workspace usage data (Reports API) and completion/ticket data show where
  to intervene, and prove ROI to the sponsor.
- **Safe by construction** — the tooling is read-only or dry-run by default; the program never
  changes user data to "measure" it.

## Limitations & boundaries

- This is the **adoption/OCM/training** layer. It **assumes** a migration/coexistence plan and the
  underlying Workspace tenant, identity, and licensing exist (see Requirements and the category
  `global-requirements-google.md`) — it does not perform the mail/Drive/Chat data migration itself.
- **Gemini** content is included **only for waves/cohorts that are licensed** for Gemini (Gemini for
  Workspace / Gemini Enterprise add-on). Gemini feature availability is **version- and rollout-
  dependent** — confirm which features (e.g. Gems, Help me write, side-panel in specific apps) are
  enabled for your cohorts in the Admin console before building the Gemini learning path; **verify in
  your tenant** rather than assuming.
- **Adoption targets and cadence** are org-specific; the numbers here (champion ratios, hypercare
  staffing, metric thresholds) are **defaults to tune**, not universal constants.
- **HR/comms/legal ownership** — messaging tone, mandatory-training policy, and any workforce-relations
  considerations are owned by the organization's HR/Comms/Legal functions; this program supplies the
  method and the content, not those determinations.

## Deployment model

The program follows the house model **Assess → (Design →) Configure → Pilot → Validate → Expand**,
**pilot-first**: the full OCM cycle is proven on `Adoption Pilot – Wave 0 – Pilot` (a small, friendly
cohort) with explicit pass/fail gates before it is scaled to production waves, and every wave has a
documented **rollback/hold** (pause the wave's cutover, extend hypercare, re-run comms/training)
rather than pushing an unprepared cohort live.
