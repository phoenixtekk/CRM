# 7. Best Practices — Microsoft Purview Adoption Program

Field-tested practices for driving **real adoption** of Purview controls — not just configuring them. They
assume the program in the Implementation Guide is in place; the goal here is to keep adoption **rising,
durable, and defensible** as scope grows.

## Behavior change & rollout
- **Never enforce cold.** Mandatory labeling and DLP *block* are introduced **only after** a ring has
  demonstrated adoption at the wave gate. Switching enforcement on without comms and champions produces a
  helpdesk storm, shadow-IT workarounds, and a rolled-back program. Earn it, then enforce it.
- **Pilot in a ring, expand in waves.** New behavior goes to a small pilot ring first, is reinforced and
  measured, then expands wave by wave. Every expansion is `-WhatIf`-previewed, change-controlled, and
  reversible — so scope never outruns the comms.
- **Make the right thing the easy thing.** A sensible **default label**, clear DLP **policy tips** before any
  block, and 90-second how-tos beat a five-page policy PDF. Adoption is a friction problem before it is a
  compliance problem.
- **Nudge before you block.** DLP in notify/tip mode, gentle reminders, and defaults change behavior with far
  less resistance than a hard stop — and the audit signal from the notify phase tells you when a ring is
  ready for enforcement.
- **Re-baseline deliberately.** Only re-save the adoption baseline at agreed milestones, so the trend always
  measures against an approved starting point — otherwise you normalize away the very progress you want to show.

## Champions network
- **One named champion per in-scope area, in a real group.** Coverage is a KPI — an area with no local
  advocate is an adoption blind spot. The validation diff against the roster is what proves coverage, not a
  spreadsheet.
- **Equip champions, don't just anoint them.** Give them the 90-second how-tos, the "which label when" cheat
  sheet, the answer to "why can't I just email it," and a direct line to the program. A champion who can't
  answer the first question loses the room.
- **Champions surface friction upward.** The weekly check-in is where "everyone's picking the wrong label" or
  "the DLP tip is confusing" is caught early and fed back to the control owners for tuning — before it becomes
  a coverage problem.

## Communications
- **A campaign, not an announcement.** Awareness → training → reinforcement, per wave, per control, on a
  cadence. One launch email is not a comms plan; reach is measured and reinforced until behavior sticks.
- **Speak to the "why," then the "how."** Lead with the risk the control prevents (in plain language), then
  the exact steps. People adopt what they understand the point of.
- **Track reach and act on it.** Reach (sent/opened/attended) is a KPI; a wave with low reach is not ready to
  gate. Low reach explains low coverage more often than resistance does.

## Measurement & KPIs
- **Measure behavior, not config.** Labeling coverage %, DLP override/false-positive rate, champion coverage,
  and comms reach — trended against the baseline — are what prove adoption. "The label exists" proves nothing.
- **Aggregate-first, privacy-by-design.** Adoption metrics are for **coverage and coaching**, not
  surveillance. Report in aggregate; keep per-user signal role-separated and minimal; any individual case
  action is an HR/legal determination, never an output of this program.
- **A KPI without a wave gate is decoration.** The gate must actually *decide* expand/hold/enforce and be
  recorded. A dashboard nobody gates on is a vanity metric.
- **Falling overrides are as important as rising coverage.** A high labeling rate with a high DLP override
  rate means people are labeling *and* routing around the control — tune the friction, don't just celebrate
  coverage.

## Boundaries & automation safety
- **Adoption drives use; it does not define the controls.** *Which* labels exist and mean what, retention
  schedules, records file plans, legal holds, and any insider-risk / communication-compliance case action
  stay with compliance, records, privacy, HR, and legal. This program gets people to *use* the controls and
  evidences that they do.
- **Read-only or `-WhatIf` by default; `-Commit` is the exception.** Four of the five scripts are read-only;
  the one that writes (ring expansion) gates every change behind `-Commit`, a wave gate, and a change record.
- **No secrets in code — ever.** Scripts use interactive modern-auth (`Connect-IPPSSession` /
  `Connect-MgGraph`); never hardcode credentials, tokens, or app secrets.
- **Verify licensing, audit availability, and portal paths for *your* tenant.** Purview is plan-gated and
  evolving; audit operation names and retention vary by workload and plan. Confirm before relying on a
  feature, and flag "verify your licensing/tenant" in your own runbooks where availability is uncertain.

## Adoption discipline (the short version)
> Make it easy before you make it mandatory. Nudge before you block. Champion every area. Measure behavior,
> not config. Gate before you expand. Enforce only what's been adopted. Re-baseline only what's approved.
