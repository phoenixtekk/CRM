# 2. Requirements Guide — Microsoft Purview Adoption Program

Verify **every** requirement before you begin. Each entry gives **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the S&C PowerShell +
Graph toolchain, in-scope data sources, governance stakeholders, and a pilot scope + change control) are in
`global-requirements-purview.md` — this file adds the prerequisites specific to running an **adoption
program**. Reference the six category requirements; do not re-derive them.

> **This is an adoption program, not an implementation.** It assumes the controls people are being asked to
> adopt — published sensitivity labels and label policies, DLP policies, and retention policies — **already
> exist**. If they do not, implement them first (see the separate Purview implementation solutions) — you
> cannot drive adoption of controls that have not been built.

## 2.1 Implemented Purview controls to adopt
**Description:** Live, published controls that users are being asked to adopt — at minimum **published
sensitivity labels and label policies** scoped to real users, and typically **DLP** and **retention**
policies. Auto-labeling and mandatory labeling optionally, if in scope.
**Why:** The entire program drives adoption of *existing* controls; with nothing published there is no
behavior to adopt or measure.
**Verify:** In the Purview portal you can see published labels under **Information protection → Sensitivity
labels / Label policies**, and DLP/retention under **Data loss prevention** / **Data lifecycle management**.
`OPSADOPT-Discovery.ps1` returns a non-empty inventory of published labels and policies.
**Implement:** Complete the implementation project first, then return to drive adoption of it.

## 2.2 Adoption program roles (least privilege) and a change/comms owner
**Description:** The **least-privilege** roles the program needs — **Information Protection Admin / Analyst**
(or **Compliance Administrator**) to read label/DLP configuration and adoption signal, **View-Only Audit
Logs / Audit Reader** for the unified audit log, and **Group administrator** (or a scoped Graph permission)
to manage the pilot-ring group — plus a named **change-management / communications owner** accountable for
the comms plan and champions network. Global Administrator only where genuinely required.
**Why:** Reading adoption signal, managing the rollout ring, and owning the campaign are distinct duties;
least privilege and a named owner make the program operable and auditable.
**Verify:** Purview portal → **Roles & scopes → Permissions** shows your accounts in the named role groups;
a named comms/change owner is documented. `OPSADOPT-Discovery.ps1` and `OPSADOPT-Report.ps1` run read-only.
**Implement:** Assign the least-privilege roles under change control; name the change/comms owner.

## 2.3 S&C PowerShell + Graph, plus audit-log and directory read scopes
**Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via
`ExchangeOnlineManagement`) and **Microsoft Graph PowerShell**; for adoption signal, access to
**`Search-UnifiedAuditLog`** (audit logging enabled and searchable for your tenant) and the Graph directory
read scopes (`Group.Read.All`, `User.Read.All`, and `Group.ReadWrite.All` **only** for the ring-management
helper).
**Why:** Label/DLP inventory and ring membership run through S&C PowerShell and Graph; adoption behavior
(label apply/change events, DLP matches/overrides) is read from the unified audit log.
**Verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed; `Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-1) -EndDate (Get-Date) -ResultSize 1`
returns without error. `OPSADOPT-Report.ps1` reports if audit search or a scope is unavailable.
**Implement:** `Install-Module ExchangeOnlineManagement` and `Install-Module Microsoft.Graph`; confirm
**audit logging is enabled** (it is on by default for most tenants but verify retention/availability for your
plan) and consent the directory scopes at first `Connect-MgGraph`.

## 2.4 A defined rollout wave plan and a pilot-ring group
**Description:** A **wave plan** (which users/business units adopt in which order) and a real **pilot-ring
group** — a security or Microsoft 365 group whose membership defines the current adoption ring (and, ideally,
the scope of the label/DLP policies being piloted).
**Why:** Behavior change is piloted then expanded in waves; the ring group is the concrete object the program
grows, and the thing membership diffs and expansions act on.
**Verify:** A named ring group exists in Entra/Graph (`Adoption Ring – Purview – WaveN`) and the wave plan is
documented. `OPSADOPT-Validation.ps1` can enumerate the group members.
**Implement:** Create the ring group, agree the wave sequence with stakeholders, and (where used to scope
policies) confirm the label/DLP policy is scoped to that group.

## 2.5 A champions roster (expected advocates per area)
**Description:** An **authoritative roster of the champions** the program expects — the local advocate for
each in-scope business unit — plus the pilot users expected in the current ring, as the baseline the coverage
check compares actual membership against.
**Why:** Champion coverage is a program KPI; a roster is what the validation diff attests actual champion-
group and ring membership against, so every in-scope area has a named advocate.
**Verify:** A roster CSV exists (`Champions Roster – Purview – Adoption`) owned by the change/comms owner;
`OPSADOPT-Validation.ps1 -RosterCsv <path>` reports gaps and unexpected members.
**Implement:** Identify one champion per in-scope area with the change/comms owner, capture the roster, and
create the champions group they are members of.

## 2.6 A communications plan (awareness → training → reinforcement)
**Description:** The **comms plan** — the awareness, training, and reinforcement messages, their **channels**
(email, Teams, intranet, town hall), and **cadence**, mapped to each rollout wave and each control (labels,
DLP, retention) — plus a way to record **reach** (sent/opened/attended) as a metric.
**Why:** Adoption comes from a campaign, not one launch email; and comms **reach** is an adoption KPI that
must be captured to be reported.
**Verify:** The comms plan and calendar are documented and mapped to waves; a reach-tracking CSV
(`Comms Reach – Purview – Adoption`) exists. `OPSADOPT-KpiReport.ps1 -CommsCsv <path>` ingests it.
**Implement:** Build the awareness/training/reinforcement message set per wave with the comms owner, schedule
it, and decide how reach is captured (mail flow/Teams/attendance) for the KPI.

## 2.7 An adoption baseline (starting behavior)
**Description:** A saved snapshot of the **starting adoption state** — the published adoption surface and the
current labeling/DLP behavior (e.g. share of activity that is labeled, current override rate) — that "adopted"
is measured against.
**Why:** Adoption is a *change* metric; without a baseline you can report a coverage number but not the trend
that proves the program is working.
**Verify:** A baseline JSON exists (`Adoption Baseline – Purview – <date>`); a fresh discovery/report run
diffs cleanly against it.
**Implement:** Run `OPSADOPT-Discovery.ps1 -SaveBaseline` (surface) and `OPSADOPT-Report.ps1` for a starting
behavior window once, before the campaign begins; re-baseline deliberately at agreed milestones.

## 2.8 A defined adoption KPI set, thresholds, and a wave gate
**Description:** The **adoption KPIs** that define success (e.g. labeling coverage %, DLP override / false-
positive rate, champion coverage %, comms reach %, per-wave trend), their **thresholds**, and the **wave
gate** — the KPI bar a ring must clear before the next wave (or enforcement) is introduced.
**Why:** "Expand the ring" and "turn on mandatory labeling" must be *earned* by demonstrated adoption; an
undefined bar means enforcement happens cold or never.
**Verify:** The KPI list with thresholds and the wave-gate rule are documented and agreed;
`OPSADOPT-KpiReport.ps1` reports each KPI against its threshold.
**Implement:** Agree the KPI set, thresholds, and the wave-gate rule with compliance/leadership before the
first expansion.

## 2.9 Change control for ring expansion and enforcement introduction
**Description:** A **change-control** path — request, review/approval, change window, recorded change,
rollback plan — for **expanding the adoption ring** (adding a wave) and for **introducing mandatory labeling
or DLP enforcement** to a ring.
**Why:** Expanding scope and enforcing behavior are high-impact; uncontrolled expansion is how a program
outruns its comms and generates a helpdesk storm. Change control makes each expansion reviewed, gated on the
KPIs, recorded, and reversible.
**Verify:** A change-record store exists (`Change Record – Purview – Adoption`) and a change window / approver
are named; `OPSADOPT-Remediation.ps1` defaults to `-WhatIf` and stamps a change record on `-Commit`.
**Implement:** Define the approval path, window, and wave-gate check with stakeholders; adopt the
`-WhatIf`-first discipline and the change record for every ring expansion.

---
## Checklist
- [ ] Implemented Purview controls present to adopt (2.1)
- [ ] Least-privilege program roles assigned; change/comms owner named (2.2)
- [ ] S&C PowerShell + Graph installed; audit-log search + directory scopes available (2.3)
- [ ] Rollout wave plan documented; pilot-ring group created (2.4)
- [ ] Champions roster captured as the coverage baseline (2.5)
- [ ] Communications plan + reach tracking in place (2.6)
- [ ] Adoption baseline (starting behavior) recorded (2.7)
- [ ] Adoption KPI set, thresholds, and wave gate agreed (2.8)
- [ ] Change control for ring expansion / enforcement introduction; `-WhatIf`-first adopted (2.9)
