# Microsoft Purview Adoption Program

> **Version 1.0.0** · Category: Purview · Solution code: OPSADOPT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview Adoption Program: Champions, Comms & Change

## The situation
Configuring Microsoft Purview — sensitivity labels, DLP, retention — is a project with an end date. Getting
people to **actually use it** is not. A label taxonomy nobody applies protects nothing; a DLP policy users
route around with personal email is a false sense of security; controls "in place" on paper but not in
behavior are exactly what an audit or an incident exposes. And enforcement flipped on cold — mandatory
labeling or DLP block with no comms and no local champions — produces a helpdesk storm, shadow-IT
workarounds, and a program that gets rolled back. The risk after go-live is not *"is it configured?"* — it is
*"is it adopted?"*

## The solution
A complete **adoption program** for Purview controls that already exist — the answer to *how do we get people
to use it?* It provides:
- A **champions network** — a named local advocate for every in-scope business unit, briefed, equipped, and
  coverage-validated against a roster.
- A **communications campaign** — awareness → training → reinforcement, mapped to each rollout wave and each
  control, with reach measured, not assumed.
- A **behavior-change / wave rollout** — pilot the behavior in a small ring, reinforce and measure it, then
  expand wave by wave, introducing mandatory labeling and DLP enforcement **only after** adoption is proven —
  never cold.
- **Adoption measurement** — labeling coverage, DLP override/false-positive rate, champion coverage, and
  comms reach, baselined and trended, so "are people using it?" becomes a number.
- A **wave gate** — a KPI bar each ring must clear before the next wave or enforcement, so expansion is
  earned, gated, and recorded.

Five **read-only-by-default** PowerShell tools (Security & Compliance PowerShell / Microsoft Graph / unified
audit log) drive the work: adoption-surface baseline, adoption-signal report, champion/ring coverage diff, a
KPI dashboard with the wave-gate verdict, and a change-controlled ring-expansion helper that makes no change
without an explicit `-Commit` and a change record.

## Why it matters
- **Real, not paper:** controls that are actually applied and respected — the only kind that protect data.
- **Measured:** rising coverage and falling overrides, trended against a baseline — evidence, not opinion.
- **Defensible:** adopted controls, named champions, recorded wave gates, and KPI evidence are exactly what
  an audit wants to see.
- **Safe:** behavior change is always piloted in a ring first, enforcement is introduced only after adoption
  is demonstrated, and every ring expansion is reversible and recorded.

## What stays with your governance functions
This solution delivers the **adoption method and the evidence** — not the compliance decisions. Which labels
exist and what they mean, retention schedules, records file plans, legal holds, and insider-risk /
communication-compliance case outcomes remain with your compliance, records, privacy, HR, and legal teams.
Adoption metrics are aggregate and **privacy-by-design** — for coverage and coaching, not surveillance.
Purview is heavily **licensing-gated** and evolving, and audit signal varies by workload and plan —
availability is verified for your tenant, never assumed.

## Bottom line
Configured Purview controls become **adopted** Purview controls — used, measured, championed, and expanded
only as fast as behavior sticks — so the compliance investment is real and defensible, at a fraction of the
cost of ongoing external change-management consulting, and without the cold-enforcement blow-up that gets
programs rolled back.


---


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


---


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


---


# Global Requirements — Microsoft Purview Solutions

These requirements apply to **every** solution in the **Purview** category (implementing and managing
Microsoft Purview, sensitivity & retention labels, DLP, data lifecycle & records, insider risk,
communication compliance, audit, data security posture management, and data governance). Verify each
before starting a solution's implementation steps.

> **Vendor boundary (applies to every Purview solution).** The **Microsoft Purview portal**
> (purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
> (`Connect-IPPSSession`), and **Microsoft Graph** are authored at exact, current click-by-click /
> cmdlet detail from Microsoft's public documentation. Microsoft Purview features are heavily
> **licensing-/plan-dependent** (many require **Microsoft 365 E5** or the **E5 Compliance** add-on;
> some are in preview) and the portal is **actively evolving** — capability availability and portal
> paths are **cited or flagged "verify your licensing/tenant"**, never asserted or invented.
> **Regulatory, records-retention, and legal determinations** (retention schedules, records file plans,
> legal holds, insider-risk case actions, regulatory applicability) are **deferred to the organization's
> compliance, records, privacy, and legal functions** — the solutions provide the technical
> configuration method and evidence, not the determination. Automation is **PowerShell** (Security &
> Compliance PowerShell / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with the required Purview/compliance licensing
- **Description:** A Microsoft 365 tenant with the **compliance licensing** the capability requires
  (E3 for baseline; **E5 / E5 Compliance** for advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, DSPM, etc.).
- **Why required:** Most Purview capabilities are plan-gated; the feature won't be available without the
  right plan.
- **How to verify:** In the M365 admin center confirm the subscription/add-ons; check the feature is
  visible in the Purview portal.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Purview roles (least-privilege) and portal access
- **Description:** Access with the least-privilege **Purview / compliance role** the solution names
  (e.g. Compliance Administrator, Compliance Data Administrator, Information Protection, Records
  Management, Insider Risk, eDiscovery, Audit roles), with Global Administrator only where required.
- **Why required:** Purview uses fine-grained role groups; configuration requires the matching role.
- **How to verify:** Purview portal → **Roles & scopes / Permissions** — confirm the role membership.
- **How to implement if missing:** Assign the least-privilege role group under change control.

## 3. Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
  ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, modern-auth / MFA-capable admin.
- **Why required:** Configuration, automation, and the provided scripts run through these.
- **How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed with the admin account.
- **How to implement if missing:** Install the modules and confirm modern-auth sign-in before running steps.

## 4. Data sources & scope in scope
- **Description:** The **workloads and data sources** in scope (Exchange, SharePoint, OneDrive, Teams,
  endpoints/devices, and — for data governance — the broader data estate) and a **data-classification /
  sensitivity** intent to drive labels, DLP, and retention.
- **Why required:** Purview policies key off the in-scope workloads and the classification scheme.
- **How to verify:** Confirm the in-scope workloads and the classification/sensitivity approach with
  stakeholders.
- **How to implement if missing:** Define the scope and classification intent before authoring policies.

## 5. Compliance, records, privacy & legal stakeholders
- **Description:** Engagement with the **compliance, records-management, privacy, security, and legal**
  stakeholders whose policies the configuration must satisfy (retention schedules, records file plans,
  regulatory obligations, insider-risk and communication-compliance policy, legal hold).
- **Why required:** Purview configuration must align to enterprise policy and legal/records requirements,
  not technical defaults; several capabilities have HR/legal sensitivity.
- **How to verify:** Confirm the applicable policies, the records schedule, and named approvers.
- **How to implement if missing:** Identify the owners and capture the requirements before configuring.

## 6. A pilot scope and change control
- **Description:** A **pilot scope** (users/sites/policies in simulation or a limited ring) to validate
  on before tenant-wide enforcement, and a **change-control** process — most Purview policies support a
  **simulation / test / disabled** mode that MUST be used before enforcement.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot (simulate) → Validate
  → Expand (enforce)** model; DLP, labels, retention, and insider-risk changes are high-impact.
- **How to verify:** Confirm a named pilot scope, that simulation/test mode is available, and a change
  window/approval path.
- **How to implement if missing:** Define the pilot and agree change control before enforcing anything.

*The deployment model across every Purview solution is the same: **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)**, with explicit pass/fail gates and a documented rollback.
Automation is delivered as **PowerShell** (Security & Compliance PowerShell / Graph) — never with
hardcoded credentials or secrets. Regulatory/records/legal determinations are deferred to the relevant
governance functions.*


---


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


---


# 5. Testing & Validation Guide — Microsoft Purview Adoption Program

Validate that the **adoption program actually drives and measures behavior change** — not that Purview is
merely configured. Each test below has an explicit **pass/fail** signal and, where relevant, a **rollback**.
Run the Part-A tests once when you stand the program up, then treat the Part-B tests as the acceptance gate
for each rollout wave. All checks are **read-only or `-WhatIf`** unless a step is explicitly a controlled
change.

## Test 1 — Adoption surface inventory + baseline (RB-01 / setup)
1. Run `OPSADOPT-Discovery.ps1` and confirm it returns a non-empty inventory of **published** sensitivity
   labels, label policies (with scope), and DLP/retention policies with their mode.
2. Run `OPSADOPT-Discovery.ps1 -SaveBaseline`, then make **no** changes and re-run with `-CompareBaseline`.
   - **Pass:** the diff reports **zero surface drift** and echoes the recorded starting behavior window.
   - **Fail:** drift reported with no change made → the baseline key is wrong; re-baseline.

## Test 2 — Adoption signal reads from the audit log (RB-01)
1. Run `OPSADOPT-Report.ps1 -Days 30`. Confirm it authenticates, searches the unified audit log, and returns
   **labeling activity** (label apply/change/remove events) and **DLP** match/override counts.
   - **Pass:** counts render and reconcile with the Purview **Activity explorer** / audit search for the same
     window; a labeling-coverage figure is computed.
   - **Fail:** an "audit search unavailable / not enabled" error → confirm audit logging and your Audit
     Reader role (Requirement 2.3). *(If no activity exists in the window, the script reports an empty result
     cleanly — a valid pass for a pre-launch baseline.)*
2. Run with `-RingGroup "<current ring>"` and confirm the signal is scoped to the ring's members.
   *(Operation names/record types vary by tenant/workload — if a category looks empty, verify the operation
   names for your tenant; see Troubleshooting.)*

## Test 3 — Champion + ring coverage diff (RB-02 / setup)
1. Run `OPSADOPT-Validation.ps1 -RosterCsv <roster.csv> -RingGroup "Adoption Ring – Purview – Wave1"
   -ChampionsGroup "Champions – Purview – Adoption"`.
   - **Pass:** every in-scope area in the roster maps to a champion present in the champions group, and the
     ring membership matches the intended wave; gaps and unexpected members are listed explicitly.
2. Remove a champion from the roster's area (or from the group) and re-run.
   - **Pass:** the missing-champion gap is flagged for that area.
   - **Rollback:** restore the champion; the next run shows full coverage.

## Test 4 — Ring-expansion helper is safe by default (RB-04 / change control)
1. Run `OPSADOPT-Remediation.ps1 -Action AddWave -RingGroup "Adoption Ring – Purview – Wave2" -MembersCsv
   <wave2.csv> -WhatIf`.
   - **Pass:** it lists the users it *would* add and confirms **no change was made**; the ring membership is
     unchanged when re-checked.
   - **Fail:** any membership change occurs under `-WhatIf` → stop and do not use `-Commit` until fixed.
2. Only in a change window, run the same with `-Commit`.
   - **Pass:** the wave's users are added to the ring **and** a row is written to `Change Record – Purview –
     Adoption`.
   - **Rollback:** `-Action RemoveWave -RingGroup "Adoption Ring – Purview – Wave2" -MembersCsv <wave2.csv>
     -Commit` removes them and records the reversal.

## Test 5 — Adoption KPI dashboard + wave gate (RB-03 / RB-05)
1. Run `OPSADOPT-KpiReport.ps1 -CommsCsv <comms-reach.csv> -RingGroup "<current ring>"`.
   - **Pass:** `KPI Dashboard – Purview – Adoption` renders the KPI set — labeling coverage %, DLP
     override/false-positive rate, champion coverage %, comms reach %, and trend vs the baseline — with each
     KPI compared to its threshold and the **wave-gate** verdict (clear / hold) shown.
   - **Fail:** the comms CSV does not parse → re-export/confirm columns (the script prints the columns it
     found).
2. Confirm a ring **below** threshold produces a **hold** verdict (no expand/enforce) and a ring **at/above**
   threshold produces a **clear** verdict.

## Test 6 — The wave cadence actually fires (program model)
1. Confirm the wave loop has run once end to end: a ring piloted, measured (RB-01), reinforced (RB-02),
   gated (RB-03, recorded in `Wave Gate – Purview – Adoption`), and expanded (RB-04) — each with a named owner.
   - **Pass:** one full wave cycle has produced its artifacts, and mandatory/enforce was introduced **only**
     to a ring that had cleared its gate.
   - **Fail:** any expansion or enforcement done **before** a passing wave gate → roll back the enforcement,
     re-earn adoption, and re-gate before proceeding.

---
## Acceptance gate (all must pass before declaring the program "adopting")
- [ ] Discovery returns the published adoption surface; baseline diff is clean.
- [ ] Report reads labeling + DLP override signal from the audit log and reconciles with Activity explorer.
- [ ] Coverage diff maps every in-scope area to a champion and flags gaps; ring matches the wave.
- [ ] `OPSADOPT-Remediation.ps1` makes no change under `-WhatIf`; `-Commit` expands the ring **and** writes a
      change record; rollback works.
- [ ] KPI dashboard renders all adoption KPIs vs thresholds and shows the correct wave-gate verdict.
- [ ] One full wave cycle has run with named owners, and enforcement was introduced only after a passing gate.


---


# 6. Troubleshooting Guide — Microsoft Purview Adoption Program

Common failures when *driving adoption* of Purview, with the cause and the fix. Grouped by area. All fixes
stay within the safe-by-default model — read-only checks first, changes only under `-WhatIf`-then-`-Commit`.

## Connection & permissions
**"The term 'Get-Label' / 'Get-DlpCompliancePolicy' is not recognized."**
- *Cause:* not in a Security & Compliance PowerShell session; those cmdlets only exist after
  `Connect-IPPSSession`.
- *Fix:* `Import-Module ExchangeOnlineManagement; Connect-IPPSSession` with a modern-auth/MFA admin, then
  re-run the script.

**`OPSADOPT-Report.ps1` / `OPSADOPT-KpiReport.ps1` errors that audit search is unavailable.**
- *Cause:* `Search-UnifiedAuditLog` isn't available in your session, your role lacks **View-Only Audit Logs /
  Audit Reader**, or audit logging isn't enabled/retained for your plan.
- *Fix:* connect with an audit-capable admin; confirm audit logging is on (M365 admin / Purview **Audit**);
  verify audit retention for your licensing. The scripts warn and return `n/a` rather than inventing data.

**`Get-MgGroup` / `New-MgGroupMember` fails with an authorization error.**
- *Cause:* the Graph scope isn't consented — read scopes (`Group.Read.All`, `User.Read.All`) for
  validation/reporting, or `Group.ReadWrite.All` for the ring-expansion helper.
- *Fix:* `Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All'` (add `Group.ReadWrite.All` only for
  `OPSADOPT-Remediation.ps1`); an admin consents the scope once if required. Confirm with `Get-MgContext`.

**A whole control family reads empty (e.g. auto-labeling, advanced DLP).**
- *Cause:* the capability isn't licensed/enabled (Purview is plan-gated — E5 / E5 Compliance) or your role
  lacks access.
- *Fix:* verify licensing and the role group (Requirement 2.2) in the portal; `OPSADOPT-Discovery.ps1` logs a
  warning and continues with what it *can* read — expected on lower plans.

## Adoption signal (OPSADOPT-Report.ps1)
**The report is empty but you know people are labeling.**
- *Cause:* the window (`-Days`) is too short, the **operation names** don't match your tenant/workload (they
  vary and evolve), or audit hasn't ingested the events yet.
- *Fix:* widen `-Days`; reconcile against Purview **Activity explorer** for the same window; pass your
  tenant's actual operation names via `-LabelApplyOps` / `-DlpOps`. An empty pre-launch window is a valid
  baseline, not a bug.
**Everything lands in one bucket / coverage looks wrong.**
- *Cause:* the apply-vs-remove coverage figure is a **directional proxy** from audit events, not a
  document-by-document census; and operation-name matching is best-effort.
- *Fix:* treat coverage as a trend signal (is it rising?), not an absolute count; for an absolute labeled-item
  census use Purview **Content explorer** (licensing permitting). Adjust the operation lists to your tenant.
**Ring scoping (`-RingGroup`) returns tenant-wide numbers.**
- *Cause:* Microsoft.Graph isn't connected, or the ring group name/`UserIds` field don't match; the audit
  `UserIds` value may differ from the group member UPN format.
- *Fix:* `Connect-MgGraph`; confirm the exact ring `displayName`; if UPNs don't match the audit `UserIds`
  format, reconcile the identifier before scoping.

## Coverage diff (OPSADOPT-Validation.ps1)
**An area is flagged as uncovered but you know it has a champion.**
- *Cause:* the champion is named in the roster but **not a member of the champions group**, or the UPN in the
  roster doesn't match the group member UPN.
- *Fix:* add the champion to `Champions – Purview – Adoption`, or correct the roster UPN; re-run. Coverage is
  proven by group membership, not by the roster alone.
**The ring diff flags expected members as absent right after populating the ring.**
- *Cause:* Graph group membership can take a short time to replicate, or the wave CSV UPNs differ from the
  directory UPNs.
- *Fix:* re-run after replication; confirm the CSV UPNs exactly match directory UPNs.
**"Roster CSV must have 'Area' and 'ChampionUpn' columns."**
- *Cause:* the roster export uses different column names.
- *Fix:* rename the columns to `Area`, `ChampionUpn` (and optionally `RingMember`, `Wave`); the script prints
  the columns it found.

## Ring expansion (OPSADOPT-Remediation.ps1)
**`-WhatIf` seems to do nothing / you expected the ring to change.**
- *Cause:* that is correct behavior — the tool is **safe by default**; without `-Commit` it previews only.
- *Fix:* review the previewed add/remove list, then re-run with `-Commit` **inside a change window, after a
  CLEAR wave gate**.
**`-Commit` skips users as "already in ring" / "not in ring."**
- *Cause:* idempotency — the tool won't re-add an existing member or remove a non-member.
- *Fix:* expected; only genuine deltas are applied and recorded. Confirm the intended membership with
  `OPSADOPT-Validation.ps1`.
**Expansion succeeded but the piloted behavior didn't apply to the new users.**
- *Cause:* the label/DLP policy is scoped to a **different** object than the ring group, so ring membership
  alone doesn't change what applies to the user.
- *Fix:* confirm the piloted label/DLP policy is scoped to `Adoption Ring – Purview – WaveN`; policy scope
  changes are made on the policy under **its own** change control (this tool manages ring membership only).
**You want to turn on mandatory labeling / DLP block via this script.**
- *Cause:* it intentionally does **not** do that — enforcement is a change to the label/DLP policy itself,
  not to ring membership.
- *Fix:* introduce enforcement on the policy under change control **only after** the ring's wave gate is
  CLEAR; never cold.

## KPIs & wave gate (OPSADOPT-KpiReport.ps1)
**The comms CSV won't parse / reach shows "n/a".**
- *Cause:* the export columns differ from `Wave, Sent, Reached`.
- *Fix:* the script prints the columns it found — re-export with `Sent` and `Reached` totals, or rename
  columns. This is a data-format issue, not a Purview fault.
**The wave gate says INCONCLUSIVE.**
- *Cause:* one or more KPIs are `n/a` (not connected for live signal, no roster/comms CSV supplied).
- *Fix:* connect `Connect-IPPSSession` (labeling/DLP) and `Connect-MgGraph` (champion coverage) and supply
  `-CommsCsv` / `-RosterCsv`; **do not gate on incomplete data** — resolve availability first.
**Coverage is high but the gate still HOLDs.**
- *Cause:* another KPI (often DLP **override rate** too high, or comms reach too low) fails its threshold — a
  high label rate with high overrides means people are labeling *and* routing around DLP.
- *Fix:* tune the friction driving overrides and reinforce comms; don't expand on one green KPI while another
  is red.

## General
**Adoption metrics are being treated as individual performance/surveillance data.**
- *Cause:* per-user audit signal was surfaced instead of the aggregate coverage the program is for.
- *Fix:* report **aggregate** KPIs (privacy-by-design); keep per-user signal role-separated and minimal; any
  individual case action is an **HR/legal** determination, never an output of this program.
**Not sure whether a capability / audit signal is available for your tenant.**
- *Cause:* Purview is plan-gated, audit operation names/retention vary by workload and evolve.
- *Fix:* verify in the M365 admin center and the Purview portal for **your** tenant before relying on a
  feature; flag "verify your licensing/tenant" in your runbook where availability is uncertain — never assume.


---


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


---


# 8. Deliverables Summary — Microsoft Purview Adoption Program

Everything included in this solution and exactly how each piece is used to **drive real adoption of Microsoft
Purview controls — champions, comms, and behavior change — not just configuration**.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The adoption model — champions network, communications campaign, behavior-change/wave rollout, and adoption measurement — and where the compliance *determinations* stay with compliance/records/legal. |
| **Requirements Guide** | The nine adoption-specific prerequisites (implemented controls to adopt, program roles + change/comms owner, toolchain + audit/directory scopes, wave plan + pilot ring, champions roster, comms plan, adoption baseline, KPI set + wave gate, change control) — each with Verify / Implement-if-missing — over the six category requirements. |
| **Implementation Guide** | Part A to design and stand up the program once; Part B the per-wave heartbeat as five named runbooks (RB-01…RB-05) with pass/fail and rollback. |
| **Testing & Validation Guide** | Six tests with explicit pass/fail + rollback and an acceptance gate proving the program drives and measures behavior (surface baselined, adoption signal reads, coverage flagged, ring expansion safe, KPIs + wave gate render, the cadence fires). |
| **Troubleshooting Guide** | The common adoption failures — audit-search/scope errors, empty or mis-bucketed signal, roster/ring diff mismatches, comms CSV parsing, ring-expansion gating — with causes and fixes. |
| **Best Practices** | Durable practices for behavior change/rollout, champions, communications, measurement, and automation safety. |
| **Executive Summary** | A one-page brief for leadership on why adoption — not config — is what makes Purview controls real and defensible. |

## PowerShell tools (5) — Security & Compliance PowerShell / Microsoft Graph
All are **read-only or `-WhatIf` by default**; the one that writes gates every change behind `-Commit`, a wave
gate, and a change record. None contain credentials or secrets — they use interactive modern auth.

| Script | Role | What it does | Default |
|---|---|---|---|
| **OPSADOPT-Discovery.ps1** | Discovery / baseline | Inventories the **adoption surface** — published sensitivity labels, label policies (with scope), and DLP/retention policy modes — and saves/compares an adoption baseline. | Read-only |
| **OPSADOPT-Report.ps1** | Reporting / signal | Reads the **unified audit log** for actual behavior — sensitivity-label apply/change/remove events and DLP match/override counts — optionally scoped to a ring, and computes labeling coverage + override rate. | Read-only |
| **OPSADOPT-Validation.ps1** | Validation | Diffs the expected **champions roster** and intended wave membership against actual **champions-group** and **ring-group** membership, flagging coverage gaps and unexpected members. | Read-only |
| **OPSADOPT-KpiReport.ps1** | Reporting / KPIs | Composes the adoption KPI dashboard — labeling coverage, DLP override/false-positive rate, champion coverage, comms reach, trend vs baseline — from live signal plus the comms-reach CSV, and renders the **wave-gate** verdict. | Read-only |
| **OPSADOPT-Remediation.ps1** | Config / rollout | The one write tool — **expands** the adoption ring by the next wave (or rolls a wave back) via Microsoft Graph group membership — `-WhatIf` first, `-Commit` writes and stamps the change record. | `-WhatIf` (safe) |

## Named adoption artifacts (created and reused verbatim)
`Adoption Baseline – Purview – <date>` · `Champions Roster – Purview – Adoption` · `Champions – Purview –
Adoption` · `Adoption Ring – Purview – WaveN` · `Comms Plan – Purview – Adoption` · `Comms Reach – Purview –
Adoption` · `KPI Dashboard – Purview – Adoption` · `Wave Gate – Purview – Adoption` · `Change Record –
Purview – Adoption`.

## Adoption cadences
Weekly adoption measurement + comms reinforcement and champions check-in · per-wave gate review · per-wave
ring expansion (change-controlled) · monthly trend review and scope reassessment.

## Outcome
Microsoft Purview controls **actually adopted** — labels applied, DLP prompts respected, behavior changed —
piloted in a ring, measured, reinforced by champions and comms, gated on adoption KPIs, and expanded wave by
wave, so the capability is **in place, in use, and defensible** rather than configured-but-ignored. The
compliance determinations remain with the accountable governance functions; this solution supplies the
adoption method, the champions/comms program, and the evidence that people use the controls.

## Boundaries (what this solution does not decide)
- **Which labels exist and what they mean, retention schedules, records file plans, legal holds** — determined
  by compliance/records/legal; this program drives *use* of the published controls.
- **Insider-risk / communication-compliance case outcomes** — HR/legal determinations; adoption metrics are
  aggregate, privacy-by-design, and never an individual case action.
- **Regulatory applicability** — compliance/legal own the determination; the program evidences adoption of
  the technical controls.
- **Capability availability** — Purview is heavily licensing-gated and evolving, and audit signal varies by
  workload/plan; verify each feature, audit availability, and portal path for your own tenant.
