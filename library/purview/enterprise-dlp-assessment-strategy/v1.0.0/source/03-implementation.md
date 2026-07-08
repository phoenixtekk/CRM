# 3. Implementation Guide — Enterprise DLP Assessment & Strategy (Microsoft Purview)

This is the exact, ordered procedure to run a DLP posture assessment, discover where sensitive data rests
and moves, and produce a **prioritized, simulation-first rollout roadmap** — **without enforcing anything**.
The only Purview object created is a single **monitor-only DLP policy in SIMULATION mode**. Portal paths and
cmdlets are from Microsoft's public documentation; **licensing-/plan-dependent features and evolving portal
paths are flagged "verify your licensing/tenant"** and are never asserted for your tenant. Do the phases in
order. Each phase names its artifacts (from the Overview naming table), states a **pass/fail gate**, and
gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. Four are **read-only**; the one that creates the
> simulation baseline is **`-WhatIf` by default** and requires an explicit `-Commit` — and it **never**
> creates anything but a simulation policy. No credentials are stored in code.

> **Determinations deferred.** *Which* data categories are ultimately in scope, *which* classifiers legally
> apply, and the *enforced action* per category are **compliance/privacy/legal** decisions. This guide
> produces the assessment and the recommended roadmap; those functions ratify it.

---

## Phase 0 — Connect and baseline current posture (Assess)

1. **Connect the toolchain** (GR-#3). On the admin workstation:
   ```powershell
   Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force   # provides Connect-IPPSSession
   Connect-IPPSSession -UserPrincipalName admin@contoso.com            # Security & Compliance PowerShell
   Connect-MgGraph -Scopes 'Organization.Read.All','InformationProtectionPolicy.Read' -NoWelcome
   ```
2. **Run the posture assessment** (delivered script #1, read-only) → `DLP Posture – Baseline – Assessment`:
   ```powershell
   .\DLPASSESS-Discovery.ps1 -CsvPath .\DLPASSESS-Posture.csv
   ```
   It reports existing DLP policies and their **mode** (enforce / simulation / disabled), built-in vs custom
   **SIT** coverage, **sensitivity/retention labels** present, and audit-logging / Content-Explorer
   readiness signals.
3. **Confirm discovery readiness** (delivered script #3, read-only): audit logging **On** (Req 2.3), the
   **Content Explorer viewer roles** held (Req 2.2), and the discovery surfaces visible (Req 2.1):
   ```powershell
   .\DLPASSESS-Validation.ps1
   ```

**Pass/fail gate:** you have a written posture baseline (policies + modes + SIT/label coverage) and the
Validation script confirms audit logging is on and the Content Explorer roles/surfaces are available (or the
gaps are documented). **No enforcing DLP policy is present that the assessment did not expect.**
**Rollback:** none (read-only).

---

## Phase 1 — Discover where sensitive data RESTS (Assess — data at rest)

Aim the scan at your candidate categories (Req 2.4). Do **not** invent SITs — report on built-in ones and
any existing custom ones.

4. **Review Content Explorer in the portal.** **Purview portal → Data classification → Content explorer.**
   Browse by **Sensitive info type** and by **Sensitivity/Retention label** to see the actual
   files/locations across **Exchange, SharePoint, OneDrive, and Teams**. This requires the **Content
   Explorer List Viewer / Content Viewer** roles (Req 2.2) — **verify your licensing/tenant.**
5. **Export the data map** (delivered script #2, read-only) → `Data Discovery – Content Explorer – Assessment`:
   ```powershell
   .\DLPASSESS-DataScan.ps1 -Tags 'Credit Card Number','U.S. Social Security Number (SSN)' -CsvPath .\DLPASSESS-DataMap.csv
   ```
   It uses `Export-ContentExplorerData` to record, per SIT/label, the **count and location** of detected
   items — the data-at-rest half of the map. Pass the SIT/label names from your shortlist.
6. **Note detector gaps.** For a candidate category with **no built-in SIT** (e.g. an internal Employee ID),
   record it as a **detector-to-build** item for the roadmap (custom SIT / EDM / trainable classifier — built
   during the *enforcement* project, not here).
7. **Optional — reach unscanned content.** Where classification hasn't evaluated a location, note
   **on-demand / automatic classification** as a follow-up (availability is plan-dependent — **verify your
   licensing/tenant**); do not assume every store has been scanned.

**Pass/fail gate:** every candidate category maps to a **detected-item count and location profile** (or is
explicitly recorded as a detector gap). You can say where each sensitive-data category rests.
**Rollback:** none (read-only export).

---

## Phase 2 — Stand up the monitor-only SIMULATION baseline (Configure — no user impact)

To measure **movement** (not just data at rest), create **one** broad DLP policy in **simulation mode**. It
evaluates real traffic and records what *would* match — with **no** enforcement and **no** policy tips.

8. **Create the simulation baseline** (delivered script #4 — `-WhatIf` by default; `-Commit` to create) →
   `DLP Baseline – All Locations – Simulation` with rule `Monitor All SITs – All Locations – Simulation`:
   ```powershell
   .\DLPASSESS-Baseline.ps1 -WhatIf                    # preview the intended policy — no change
   .\DLPASSESS-Baseline.ps1 -Commit                    # create it in SIMULATION mode only
   ```
   Portal equivalent: **Data loss prevention → Policies → Create policy** → custom → **Locations: Exchange,
   SharePoint, OneDrive, Teams** (add **Devices** only if endpoints are onboarded and licensed — Req 2.1) →
   rule: condition *Content contains* your shortlist SITs at a **low, inclusive** confidence/instance count
   (the goal is to *see* movement, not to tune yet) → **no action** / audit-only → **Policy mode: Run the
   policy in simulation mode** (without policy tips). Finish.
9. **Confirm it is in simulation, not enforce.** Re-run script #1 or #3:
   ```powershell
   .\DLPASSESS-Discovery.ps1
   ```
   The baseline must report a **Test\*** mode (`TestWithoutNotifications`). If anything shows **Enable**
   (enforcing) that you didn't intend, stop and correct it.

**Pass/fail gate:** exactly one broad DLP policy exists, confirmed in **simulation** (Mode = `TestWithout
Notifications`), scoped to the intended locations and the shortlist SITs. Nothing is enforced.
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is instant and clean
(`.\DLPASSESS-Baseline.ps1 -Remove -Commit`).

---

## Phase 3 — Measure how sensitive data MOVES (Pilot the discovery)

Let the simulation baseline run for the agreed **dwell time** (Req 2.6) to capture representative traffic.

10. **Review what would have matched.** **Purview portal → Data loss prevention → Alerts** (simulation
    alerts) and **Data classification → Activity explorer** (filter to DLP + sharing activities) show every
    simulated match — the file/message, the SIT, the location, and whether it was **shared externally**.
11. **Export the movement data** (delivered script #5, read-only):
    ```powershell
    .\DLPASSESS-Report.ps1 -Days 21 -CsvPath .\DLPASSESS-Movement.csv
    ```
    It aggregates simulation DLP matches (and sharing events) by **SIT, workload, volume, and external
    exposure** — the data-in-motion half of the map.
12. **Confirm coverage.** If a candidate category shows **zero** movement, decide whether that is genuine
    (data at rest only) or a **coverage gap** (dwell too short, location not covered, audit latency) — note
    which in the roadmap.

**Pass/fail gate:** you have measured movement (matches by SIT/workload/volume/external-exposure) over a
representative dwell time, reconciled against the Phase-1 data-at-rest map.
**Rollback:** none (read-only); the simulation policy keeps running or is deleted (Phase 2 rollback).

---

## Phase 4 — Rank exposure and build the roadmap (Design)

13. **Rank data categories by exposure** → `Sensitive Data Map – Prioritized – Assessment`. Combine the
    data-at-rest map (Phase 1) with the movement data (Phase 3) into a ranked view, weighting by:
    **prevalence** (how much of each category exists), **external-sharing exposure** (how much leaves or is
    shared out), **movement volume**, and **detector confidence** (built-in vs a gap to build). The
    reporting script emits this ranking; adjust the weighting with stakeholders.
14. **Draft the rollout roadmap** → `DLP Roadmap – Prioritized – Strategy`. For each ranked category, specify
    the recommended: **detector** (built-in SIT / custom / EDM / trainable — flag gaps to build),
    **location(s)** to cover first, **action progression** (audit → policy tip → allow-with-justification →
    block), the **pilot ring** (`DLP Rollout Ring – Stage1`), and the **order**. **Every step is
    simulation-first** with a pass/fail gate and a rollback — matching the house model.
15. **Mark determinations for ratification.** Explicitly flag every point that is a **compliance/privacy/
    legal decision** — which categories are truly in scope, which classifiers legally apply, and the enforced
    action per category — as **[to be ratified]** in the roadmap, not decided here.

**Pass/fail gate:** a ranked exposure view and a prioritized, simulation-first roadmap exist, every step is
gated and reversible, and every governance determination is flagged for ratification (not assumed).
**Rollback:** none (documentation); the roadmap is a recommendation until ratified.

---

## Phase 5 — Review, ratify, and hand off (Expand)

16. **Walk stakeholders through the roadmap** (Req 2.6): compliance/privacy/legal/records review the ranked
    exposure, the proposed order, detectors, and actions, and **ratify or revise** scope and enforced-action
    determinations.
17. **Record the ratified decisions** back into `DLP Roadmap – Prioritized – Strategy` — scope confirmed,
    actions per category agreed, detector-build backlog captured.
18. **Decide the simulation baseline's fate.** Either **keep** `DLP Baseline – All Locations – Simulation`
    running as an ongoing monitor into the enforcement project, or **delete** it (Phase 2 rollback) — it is
    non-enforcing either way. Document the choice.
19. **Hand off to the enforcement project.** The ratified roadmap, the data map, the movement report, and the
    detector-build backlog are the complete input to a DLP *enforcement* engagement (e.g. the DLP:
    Endpoint/Cloud/Email solution) — which starts, as always, in simulation.

**Pass/fail gate:** the roadmap is ratified by the governance owners, decisions are recorded, the simulation
baseline's disposition is documented, and the enforcement project has everything it needs to start.
**Rollback:** delete the simulation policy at any time (instant, no user impact); all other outputs are
documents.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline posture, confirm readiness | Posture CSV | Baseline + readiness confirmed | n/a (read-only) |
| 1 Rest | Discover where sensitive data rests (Content Explorer) | Data map CSV | Every category → location profile | n/a (read-only) |
| 2 Configure | Create ONE monitor-only **simulation** policy | Simulation baseline | In simulation, correct scope, nothing enforced | Delete sim policy |
| 3 Motion | Measure movement over dwell time | Movement CSV | Movement measured + reconciled | n/a (read-only) |
| 4 Design | Rank exposure, build roadmap | Ranked map + roadmap | Ranked, gated, reversible, flagged | n/a (docs) |
| 5 Ratify | Review, ratify, hand off | Ratified roadmap | Ratified + handed off | Delete sim policy |
