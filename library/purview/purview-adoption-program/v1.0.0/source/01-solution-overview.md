# 1. Solution Overview — Microsoft Purview Adoption Program: Champions, Comms & Change

## What this solution is
Configuring Microsoft Purview — sensitivity labels, DLP, retention, compliance controls — is only half the
job. The other half is **adoption**: getting people to *actually apply the labels, respect the DLP prompts,
and change the day-to-day behavior* the controls depend on. A perfectly configured label taxonomy that
nobody applies protects nothing; a DLP policy users route around with personal email is a false sense of
security. This solution is the **adoption program** that turns configured Purview controls into adopted
behavior — a repeatable way to **drive real adoption, not just config**.

It provides a **champions network** (identified, briefed, and equipped local advocates), a **communications
plan** (awareness → training → reinforcement, mapped to the rollout waves), a **behavior-change model** for
labels/DLP/compliance (nudges, mandatory-labeling and justification prompts introduced *gradually*, pilot
rings that expand in waves), and — critically — the **adoption measurement** that proves it is working:
labeling coverage, DLP override/false-positive rates, champion coverage, and comms reach, baselined and
trended over time. Everything is driven from the **Microsoft Purview portal**, **Security & Compliance
PowerShell** (`Connect-IPPSSession`), **Microsoft Graph**, and the **unified audit log** — with no
third-party tooling and no hardcoded secrets.

This is deliberately **distinct from an implementation project**. It assumes the labels, DLP, and retention
controls exist (a separate implementation solution builds those) and answers the question every compliance
and change owner faces after go-live: *how do we get people to use it?*

## Why this matters
- **Config without adoption is a compliance gap.** An unlabeled estate, DLP prompts users ignore or bypass,
  and controls "in place" on paper but not in behavior are exactly what an auditor or an incident exposes.
  The control is only real once the behavior is.
- **Enforcement without adoption breaks the business.** Flip mandatory labeling or DLP enforcement on cold,
  with no comms and no champions, and you get a helpdesk storm, shadow-IT workarounds, and a program that
  gets rolled back. Behavior change has to be *led*, not switched on.
- **Users need a reason and a guide.** People adopt when they understand *why* (the risk the label prevents),
  *how* (a 90-second "how to label this document"), and *who to ask* (a local champion) — not from a single
  launch email. Awareness, training, and reinforcement are a campaign, not an announcement.
- **Resistance is predictable and manageable.** "It slows me down," "I don't know which label," "I'll just
  email it to myself" — these are known adoption failure modes with known countermeasures (defaults,
  guidance, gentle nudges before hard enforcement). Naming and working them is the program.
- **If you can't measure adoption, you can't prove it or improve it.** "Are people labeling?" must become a
  number — coverage %, override rate, champion coverage, comms reach — baselined and trended, or the program
  is an opinion.

## How it works
1. **Baseline the adoption surface + current behavior.** `OPSADOPT-Discovery.ps1` inventories what users are
   *expected* to adopt — published sensitivity labels, label policies (and their scope), and DLP/retention
   policies in enforce vs test — and records an adoption **baseline** to measure change against.
2. **Stand up the champions network.** Identify local advocates per business unit, brief and equip them, and
   validate coverage. `OPSADOPT-Validation.ps1` diffs an expected **champions & pilot roster** against actual
   pilot-ring and champion-group membership so every in-scope area has a named advocate.
3. **Run the communications campaign.** Awareness → training → reinforcement messages, mapped to each rollout
   wave and each control (labels, DLP, retention), with reach tracked as a metric.
4. **Change behavior gradually — pilot in a ring, expand in waves.** New behaviors (applying labels, honoring
   DLP prompts) are introduced to a **pilot ring** first, reinforced, measured, then expanded wave by wave;
   mandatory labeling and DLP enforcement are introduced *only after* adoption is demonstrated — never cold.
5. **Measure adoption from real signal.** `OPSADOPT-Report.ps1` reads the **unified audit log** and Graph for
   actual behavior — sensitivity-label apply/change events, DLP matches and user overrides/justifications —
   and turns "are people using it?" into coverage and override numbers.
6. **Prove and steer with a KPI dashboard.** `OPSADOPT-KpiReport.ps1` composes the adoption KPI dashboard —
   labeling coverage, DLP override/false-positive rate, champion coverage, comms reach, trend vs baseline —
   from live telemetry plus comms/survey CSVs, so each expansion wave and each enforcement decision is
   data-driven.
7. **Expand the ring under change control.** `OPSADOPT-Remediation.ps1` performs the one write action — moving
   the next wave of users into the adoption/pilot ring group (or rolling a wave back) — **`-WhatIf` by
   default**, only writing with an explicit `-Commit`, and stamping each change into the change record.

## The adoption model (the arc of the program)
| Phase | Focus | Signal it worked |
|---|---|---|
| **Assess** | Baseline the adoption surface + current labeling/DLP behavior | Baseline captured; starting coverage known |
| **Design** | Champions roster, comms plan, wave/ring plan, behavior-change tactics | Roster + calendar approved |
| **Configure** | Stand up champion group + pilot ring; schedule comms | Pilot ring populated; comms live |
| **Pilot (test)** | Introduce behavior to the pilot ring; reinforce; measure | Pilot coverage rising; overrides falling |
| **Validate** | Confirm adoption KPIs pass the wave gate | KPIs meet threshold for the ring |
| **Expand (enforce)** | Move the next wave in; introduce mandatory/enforce only after adoption | Coverage holds as scope grows |

## What you can control
- Which controls are in the adoption scope (sensitivity labels, DLP, retention) and the rollout wave plan.
- The champions network — who, per business unit, and the coverage target.
- The communications plan — the awareness/training/reinforcement messages, channels, and cadence per wave.
- The behavior-change tactics — default labels, when nudges start, and *when* mandatory labeling / DLP
  enforcement is introduced (gated on adoption, never cold).
- The adoption KPI set and thresholds that define a "ready to expand" wave gate.
- The pilot-ring / wave membership and the change-control path for expanding it.

## What stays with your governance functions (be explicit with buyers)
This solution delivers the **adoption method and the evidence** — not the compliance *determinations*.
**Which labels exist and what they mean, retention schedules, records file plans, legal holds, and any
insider-risk / communication-compliance case action** remain with your compliance, records, privacy, HR, and
legal teams. Where the program touches HR/privacy-sensitive signal (e.g. per-user labeling behavior), it
emphasizes **privacy-by-design, aggregate-first reporting, and role separation** — adoption metrics are for
coaching and coverage, not surveillance, and any individual case action is deferred to the accountable owner.

## Licensing reality (verify for your tenant)
Purview capabilities are heavily **licensing- and plan-dependent** and the portal is **actively evolving**.
Sensitivity labels and manual labeling are broadly available; **auto-labeling, mandatory labeling in some
apps, advanced DLP, and richer audit signal** generally require **Microsoft 365 E5** or the **E5 Compliance**
add-on, and audit-log retention/availability is itself plan-gated. Audit-log **operation names and record
types vary by workload and evolve.** Every step below is flagged where availability depends on licensing;
**confirm capability, audit availability, and portal paths for your own tenant** before relying on them.

## The standard adoption model
> Baseline the adoption surface and current behavior → design the champions, comms, and wave plan →
> configure the champion network and pilot ring → **pilot the behavior in the ring (test)** → validate the
> adoption KPIs → **expand wave by wave, introducing mandatory/enforce only after adoption is proven.**
> Behavior change is always piloted before it is enforced, and every ring expansion is reversible and recorded.
