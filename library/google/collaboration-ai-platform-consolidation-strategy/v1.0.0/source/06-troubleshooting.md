# 6. Troubleshooting Guide — Collaboration & AI Platform Consolidation Strategy & Roadmap

Failure modes and fixes, grouped by area. Most consolidation programs stall for a few root causes: **the
target platform was never truly decided**, **a legacy system has no written exit criteria**, **a
decommission was attempted with a live dependency still attached**, or **coexistence was never gated so
it simply never ends**.

> Use `GWCONSOL-Discovery.ps1` / `GWCONSOL-Validation.ps1` (read-only) for current-state and target-state
> conformance, and `GWCONSOL-Report.ps1` for cost/savings + decommission readiness. Use
> `GWCONSOL-Remediation.ps1` (default `-WhatIf`) to preview fixes. **Google Admin / Microsoft-Entra
> console specifics are named from the vendors' public docs; Gemini preview capabilities are verified
> in-tenant** — these fixes name *what* to correct.

---

## A. Target / strategy ambiguity

| Symptom | Cause | Remediation |
|---|---|---|
| Program keeps adding "keep it for now" exceptions | Target platform never executive-ratified; teams hedge | Ratify the target-platform decision at the sponsor level (`Consolidation Strategy – Platform – Design`, R1); every exception must be a recorded retained-exception with a driver, not a default |
| Two teams disagree on what is "target" vs "legacy" | Strategy thesis not stated once and reused | Publish the single thesis (target + what retires + why) and reference it in every wave and gate |
| A decommission decision gets reversed under pushback | No owner with decommission authority | Assign `Consolidation Sponsor – Program – Run` with decommission-approval authority (R2); the gate, not the loudest objector, decides |

## B. Estate mapping / redundancy

| Symptom | Cause | Remediation |
|---|---|---|
| A legacy system surfaces late that nobody had mapped | Estate inventory incomplete | Re-run `GWCONSOL-Discovery.ps1` for the discoverable Microsoft side; capture third-party/contract context manually into `Consolidation Estate Map – Platform – Design` (R4) |
| Redundant systems not being retired | Decommission candidates not flagged in the map | For every system where a target capability does the same job, mark it a decommission candidate and record its duplicate cost (§03 A2) |
| "Retained" systems accumulating with no reason | Retained exceptions not justified/reviewed | Require a driver + review date per retained exception; revisit on the operating-model cadence (Best Practices §07) |

## C. Sequencing / dependencies

| Symptom | Cause | Remediation |
|---|---|---|
| Decommissioning a system broke a production workflow | Retired out of dependency order / a live dependency missed | Build/refresh the dependency map (R8); retire in dependency order; make each blocking dependency an explicit exit-criterion (T1.3/T2.2/T3.2) |
| Wave scope keeps slipping | Cohorts split across waves, extending coexistence | Scope waves to groups who work together (`Consolidation Wave Scope – <Wave> – Pilot/Broad`); keep cohorts intact |
| Underlying migration not ready when the wave needs it | Roadmap sequences a migration engagement that isn't scheduled | Confirm the underlying migration (separate engagement) is scheduled before the wave's Configure; this roadmap *sequences* it, it does not perform it |

## D. Decommission gates / exit criteria

| Symptom | Cause | Remediation |
|---|---|---|
| Nobody is sure whether a system is safe to turn off | No written coexistence-exit criteria | Author exit criteria per candidate (R6): data migrated + verified, no active users/dependencies, target validated, rollback window elapsed, governance cleared |
| A gate "passed" but the system still had active users | Gate decided on optimism, not evidence | Decide the gate on `GWCONSOL-Report.ps1` decommission-readiness output; a gate is PASS only when every exit-criterion is objectively met (§05) |
| Coexistence never ends | No decommission gate wired into the program | Attach a decommission gate to every candidate; the coexistence-footprint KPI must trend to zero, wave by wave |

## E. Cost / savings not materializing

| Symptom | Cause | Remediation |
|---|---|---|
| Consolidation isn't showing savings | System technically retired but licence/contract still billing | Reharvest freed licences promptly (licence-reduction KPI); align decommission with renewal/true-up windows so the contract saving lands (§07) |
| Savings can't be measured | No cost baseline of running both ecosystems | Capture the run-rate baseline (R9) in `Consolidation Cost Model – Platform – Run`; tie each cost line to the system whose retirement removes it |
| Reported savings drift from reality | Realized savings not tracked against the model | Run `GWCONSOL-Report.ps1` on the cadence; reconcile realized vs projected (T5.1) |

## F. Governance / compliance blocking retirement

| Symptom | Cause | Remediation |
|---|---|---|
| Legal blocks a decommission at the last minute | Retention hold / eDiscovery obligation not cleared up front | Make governance clearance an exit-criterion (R10); obtain it *before* the gate is scheduled, not at cutover (T1.4) |
| Uncertainty over where regulated data lives post-retirement | Data-residency not mapped for the target | Confirm target-platform data-residency with the governance stakeholders before retiring the legacy store |

## G. Program / operating-model issues

| Symptom | Cause | Remediation |
|---|---|---|
| Program drifting back toward two-platform sprawl | No owner / artifacts not maintained | Assign `Consolidation Owner – Platform – Run` (R2); keep the four strategy artifacts current as living documents (§07) |
| Progress unclear to leadership | KPIs not measured | Capture the baseline (R12) and keep `GWCONSOL-Report.ps1` live — report coexistence footprint, decommission progress, and realized savings (T5.1) |
| Retained exceptions never revisited | No review cadence | Institute the estate/exception review in the operating model (§03 Part B3); re-justify or retire each exception |

## H. Tooling / script issues

| Symptom | Cause | Remediation |
|---|---|---|
| A script fails to connect to Graph | Microsoft Graph PowerShell module not installed or not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; sign in with the required read scopes when prompted |
| Remediation made no change | `-WhatIf` is the default (by design) | Re-run with `-Apply` once the preview is correct |
| Report shows licence/cost as 'n/a' | No operator-maintained cost/status CSV, or Graph sizing unavailable | Provide the status/cost CSV template `GWCONSOL-Report.ps1` writes; confirm Graph read access for live licence/group sizing |
| Gemini capability assumed but absent | A preview/rolling-out capability was treated as GA | Verify the capability in your tenant (vendor note); if absent, record it as a risk/assumption and do not gate a decommission on it (T2.1) |

---

## When to escalate

If the target platform is ratified, the estate and dependency maps are current, a candidate's
coexistence-exit criteria are written and objectively met, governance is cleared, and a decommission
still cannot proceed safely — collect the `GWCONSOL-Discovery.ps1` and `GWCONSOL-Validation.ps1` output
and the relevant `Decommission Results – <System> – <Wave>`, and escalate to the
`Consolidation Sponsor – Program – Run` with the specific blocking exit-criterion. For underlying
migration mechanics, refer to that migration engagement's own runbook; for Google/Microsoft product
behavior, reference the vendor's official documentation.
