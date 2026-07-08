# 3. Implementation Guide — Microsoft Purview Adoption Program

This is the **adoption** guide: how to stand up and then *run* the champions/comms/behavior-change program on
a wave cadence. Work through **Part A** once to design and configure the program, then run **Part B** as the
recurring per-wave heartbeat. Inventory and ring membership come from **Security & Compliance PowerShell**
(`Connect-IPPSSession`) and **Microsoft Graph**; adoption behavior comes from the **unified audit log**
(`Search-UnifiedAuditLog`). Every ring expansion is run **`-WhatIf` first** and only committed with `-Commit`
under change control. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention and are reused
verbatim across docs, scripts, and the portal.

> **Model:** Baseline the adoption surface + behavior → design champions/comms/waves → configure the champion
> group + pilot ring → **pilot the behavior in the ring (test)** → validate the adoption KPIs against the
> wave gate → **expand wave by wave, introducing mandatory/enforce only after adoption is proven.** Behavior
> change is always piloted before it is enforced, and every ring expansion is reversible and recorded.

## Named adoption artifacts
| Artifact | Name |
|---|---|
| Adoption surface + behavior baseline | `Adoption Baseline – Purview – <date>` |
| Champions roster (expected advocates per area) | `Champions Roster – Purview – Adoption` |
| Champions group (actual advocates) | `Champions – Purview – Adoption` |
| Pilot / rollout ring group (per wave) | `Adoption Ring – Purview – WaveN` |
| Communications plan + calendar | `Comms Plan – Purview – Adoption` |
| Communications reach log | `Comms Reach – Purview – Adoption` |
| Adoption KPI dashboard | `KPI Dashboard – Purview – Adoption` |
| Wave gate decision record | `Wave Gate – Purview – Adoption` |
| Change record (ring expansion / enforcement) | `Change Record – Purview – Adoption` |

---
# Part A — Design & stand up the program (once)

## Step 1 — Baseline the adoption surface and current behavior (Assess)
1. Confirm your least-privilege roles are in place (Requirement 2.2) and connect: `Connect-IPPSSession` and
   `Connect-MgGraph`.
2. Run `OPSADOPT-Discovery.ps1` to inventory the **adoption surface** — published sensitivity labels, label
   policies (and their scope), and DLP/retention policies with their mode (Enable / Test / Disable). It
   writes the surface into the baseline.
3. Run `OPSADOPT-Report.ps1` for a starting window to capture **current behavior** — labeling activity and
   DLP match/override signal from the unified audit log. Once agreed as the starting point, run
   `OPSADOPT-Discovery.ps1 -SaveBaseline` to write `Adoption Baseline – Purview – <date>` (Requirement 2.7),
   the reference all trend measurement diffs against.

## Step 2 — Design the champions network, comms plan, and wave plan (Design)
1. With the change/comms owner, identify **one champion per in-scope business unit** and capture the
   `Champions Roster – Purview – Adoption` (Requirement 2.5). Create the `Champions – Purview – Adoption`
   group they belong to.
2. Build the **communications plan** — awareness → training → reinforcement messages, per control (labels,
   DLP, retention), mapped to each rollout wave, with channels and cadence (Requirement 2.6). Record it as
   `Comms Plan – Purview – Adoption` and decide how **reach** is captured into `Comms Reach – Purview –
   Adoption`.
3. Agree the **wave plan** (who adopts in which order) and the **wave gate** — the adoption KPI bar a ring
   must clear before the next wave or before mandatory/enforce is introduced (Requirement 2.8).

## Step 3 — Configure the champion group and the pilot ring (Configure)
1. Create the **pilot-ring group** `Adoption Ring – Purview – Wave1` (Requirement 2.4). Where the piloted
   controls are scoped by group, confirm the label/DLP policy targets this ring so the pilot behavior applies
   only to the ring.
2. Populate Wave 1 with the pilot users and champions. Use `OPSADOPT-Remediation.ps1 -Action AddWave
   -RingGroup "Adoption Ring – Purview – Wave1" -MembersCsv <wave1.csv> -WhatIf` to preview, then `-Commit`
   in a change window to populate it (Requirement 2.9).
3. Confirm the config helper is safe by default: with no `-Commit` it previews and changes **nothing**; only
   `-Commit` writes group membership and stamps `Change Record – Purview – Adoption`.

## Step 4 — Validate champion + ring coverage (Configure)
1. Run `OPSADOPT-Validation.ps1 -RosterCsv <champions-roster.csv> -RingGroup "Adoption Ring – Purview –
   Wave1" -ChampionsGroup "Champions – Purview – Adoption"` to diff the **expected roster** against **actual**
   champion-group and ring membership.
2. Close every gap: an in-scope area with no champion, or a ring missing an expected pilot user, is fixed
   before the pilot behavior is introduced. **Pass:** every in-scope area has a named champion in the group;
   the ring matches the intended Wave 1 membership.

## Step 5 — Launch comms and introduce the behavior to the ring (Pilot / test)
1. Fire the **awareness** comms for Wave 1, then the **training** ("how to label this document/email in 90
   seconds"; "what the DLP prompt means and what to do"). Record reach into `Comms Reach – Purview –
   Adoption`.
2. Introduce the behavior **gently first** — labels available with a sensible **default**, DLP in
   **notify/tip** rather than block, nudges before any hard prompt. **Do not** enable mandatory labeling or
   DLP block for the ring yet; adoption is earned first. *(Which labels mean what, and any retention/records
   determination, remain with compliance/records — this step drives use of the published controls, it does
   not define them.)*
3. Reinforce on cadence per the comms plan; route questions to the local champion.

---
# Part B — Run the program (per-wave heartbeat)

## RB-01 — Measure adoption for the current ring (weekly)
1. Run `OPSADOPT-Report.ps1 -RingGroup "<current ring>" -Days 7` to read the unified audit log for the ring:
   sensitivity-label apply/change events and DLP match/override counts. **Pass:** labeling coverage rising
   week over week; override/false-positive rate falling.
2. Feed recurring friction back to the champions and the comms plan (e.g. a label users keep getting wrong →
   clearer guidance or a better default). Note tuning needs for the control owners (label default, DLP tip
   text) under their change control.

## RB-02 — Reinforce comms and work the champions (weekly)
1. Send the scheduled **reinforcement** message for the wave; record reach into `Comms Reach – Purview –
   Adoption`. **Pass:** reach ≥ threshold for the wave.
2. Hold the champions check-in: surface blockers, share what's working, collect the "it slows me down / I
   don't know which label / I'd rather email it" objections and the countermeasures. Champions carry the
   message locally; the program removes the friction.

## RB-03 — Wave gate review: decide expand / enforce (per wave)
1. Run `OPSADOPT-KpiReport.ps1 -CommsCsv <comms-reach.csv> -RingGroup "<current ring>"` to compose
   `KPI Dashboard – Purview – Adoption` — labeling coverage, DLP override/false-positive rate, champion
   coverage, comms reach, and trend vs `Adoption Baseline – Purview – <date>`.
2. In the wave-gate review, compare each KPI to its threshold (Requirement 2.8) and record the decision in
   `Wave Gate – Purview – Adoption`:
   - **KPIs clear the gate →** approve expanding to the next wave, and/or introducing **mandatory labeling /
     DLP enforcement** to the *proven* ring.
   - **KPIs miss →** hold; reinforce comms, tune the friction, re-measure. Do **not** expand or enforce cold.

## RB-04 — Expand the ring (per wave, change-controlled)
1. With a passed wave gate, raise a change request and preview the expansion:
   `OPSADOPT-Remediation.ps1 -Action AddWave -RingGroup "Adoption Ring – Purview – WaveN+1" -MembersCsv
   <next-wave.csv> -WhatIf`. Review the users that would be added.
2. Apply in the change window with `-Commit`. **Pass:** the next wave's users are in the ring and a row is
   written to `Change Record – Purview – Adoption`. **Rollback:** `-Action RemoveWave -RingGroup "<ring>"
   -MembersCsv <wave.csv> -Commit` removes the wave and records the reversal.
3. Re-run Step 4's validation for the new ring, then start its comms and pilot (Part A, Steps 4–5) for the new
   wave. Introduce **mandatory labeling / DLP enforcement only after** that wave, too, has cleared its gate.

## RB-05 — Trend, reinforce, and reassess (monthly / per program review)
1. **Monthly:** refresh `KPI Dashboard – Purview – Adoption`; walk the trend with stakeholders — coverage
   climbing, overrides falling, champion and comms coverage holding as scope grows. **Pass:** KPIs within
   threshold or with an owned remediation plan.
2. Reassess scope as new controls are published or new business units come in; add them to the wave plan and
   the champions roster. Re-baseline (`OPSADOPT-Discovery.ps1 -SaveBaseline`) deliberately at agreed
   milestones so the trend always measures against an approved starting point.

---
### Order of operations
`Baseline surface + behavior → design champions/comms/waves → configure champion group + Wave 1 ring →
validate coverage → launch comms + pilot the behavior (gentle) → then per wave: weekly measure · weekly
reinforce/champions · wave-gate KPI review · expand ring (-WhatIf-first, recorded) · introduce
mandatory/enforce only after adoption is proven · monthly trend + reassess.`
