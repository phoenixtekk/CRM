# 2. Requirements Guide — Managing Microsoft Purview: Operations & Governance

Verify **every** requirement before you begin operating. Each entry gives **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the S&C
PowerShell + Graph toolchain, in-scope data sources, governance stakeholders, and a pilot scope +
change control) are in `global-requirements-purview.md` — this file adds the prerequisites specific to
**running Purview as an operated program**. Reference the six category requirements; do not re-derive them.

> **This is an operations solution, not an implementation.** It assumes an **already-implemented Purview
> foundation** (labels, DLP, retention, and the relevant advanced capabilities are live). If that
> foundation does not yet exist, implement it first (see the separate *Implementing Microsoft Purview —
> Foundation, Roles & Onboarding* solution) — you cannot operate what has not been built.

## 2.1 An implemented Purview foundation to operate
**Description:** Live Purview configuration to manage — at minimum published sensitivity labels and label
policies, DLP policies, and retention policies; optionally auto-labeling, insider risk, communication
compliance, and Audit (Premium) if in scope.
**Why:** The entire operating model (lifecycle, drift, triage, KPIs) acts on existing policies; with
nothing deployed there is nothing to operate.
**Verify:** In the Purview portal you can see published policies under **Data loss prevention → Policies**,
**Information protection → Sensitivity labels / Label policies**, and **Data lifecycle management** /
**Records management → Retention policies**. `PURVOPS-Discovery.ps1` returns a non-empty inventory.
**Implement:** Complete the implementation project first, then return to operate it.

## 2.2 Purview operations roles (least privilege, role-separated)
**Description:** The **least-privilege** compliance role groups the operating tasks need — typically
**Compliance Administrator** (or **Compliance Data Administrator**) for policy lifecycle and change,
**Information Protection Admin/Analyst** for labels/DLP, **Insider Risk Management** roles for insider-risk
operations, **eDiscovery** and **Audit** roles where those are in scope — with a deliberate **separation**
between who *administers* and who *investigates* (especially for insider risk and communication compliance).
Global Administrator is used only where genuinely required.
**Why:** Purview uses fine-grained role groups; operating a capability requires the matching role, and
HR/privacy-sensitive capabilities require role separation as a control, not a convenience.
**Verify:** Purview portal → **Roles & scopes → Permissions** (or **Settings → Roles**) shows your
accounts in the named role groups. `PURVOPS-Validation.ps1` enumerates them read-only.
**Implement:** Assign the least-privilege role groups under change control; document the separation between
administrator and investigator/reviewer duties for insider risk and communication compliance.

## 2.3 S&C PowerShell + Graph, plus Graph Security permissions for alerting
**Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via
`ExchangeOnlineManagement`) and **Microsoft Graph PowerShell**; for the alert rollup, the Graph
**security** read scopes (`SecurityEvents.Read.All` or `SecurityAlert.Read.All`) consented.
**Why:** Policy inventory, role review, and config changes run through S&C PowerShell; the alert rollup
reads triggered alerts from the Microsoft Graph security API.
**Verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed with the admin account; a read against
`/security/alerts_v2` returns without a permissions error. Run `PURVOPS-Report.ps1` — it reports if a
scope is missing.
**Implement:** `Install-Module ExchangeOnlineManagement` and `Install-Module Microsoft.Graph`; consent the
security read scopes at first `Connect-MgGraph` (admin consent once if required).

## 2.4 A recorded policy baseline (for drift detection)
**Description:** A saved snapshot of the current policy inventory (names + modes) that "healthy" is measured
against — the baseline `PURVOPS-Discovery.ps1` compares each run to.
**Why:** Drift is only meaningful relative to a known-good baseline; without one you can list policies but
not detect *what changed* since the last review.
**Verify:** A baseline JSON exists (`Policy Baseline – Purview – <date>`); a fresh discovery run diffs
cleanly against it.
**Implement:** Run `PURVOPS-Discovery.ps1 -SaveBaseline` once after a reviewed, known-good state to
establish the baseline; re-baseline after each approved change set.

## 2.5 Compliance Manager access and an improvement-action export
**Description:** Access to **Compliance Manager** in the Purview portal and the ability to **export** its
improvement actions (Compliance Manager has **no supported public API** — data is exported from the portal
as CSV).
**Why:** The improvement-action cadence and the compliance-score KPI are driven from Compliance Manager;
the KPI script ingests the exported CSV.
**Verify:** Purview portal → **Compliance Manager → Improvement actions** loads; the **Export** control
produces a CSV. `PURVOPS-KpiReport.ps1 -ComplianceManagerCsv <path>` ingests it.
**Implement:** Confirm licensing exposes the improvement actions you need (some templates/actions are
premium/E5), and establish the monthly export as part of the cadence.

## 2.6 An approved role-membership list (access-review baseline)
**Description:** An **authoritative list of who should be in each Purview role group** — the attestation
baseline the quarterly access review compares actual membership to.
**Why:** An access review needs an approved state to compare against; otherwise you can list members but
not identify unauthorized or stale privilege.
**Verify:** An approved-membership CSV exists and is owned by a named approver; `PURVOPS-Validation.ps1
-ApprovedListCsv <path>` reports additions/removals against it.
**Implement:** Capture current approved membership with the accountable owner, store it as the baseline, and
re-approve it each review cycle.

## 2.7 Defined alert-triage scope, severities, and SLAs
**Description:** The **alert categories in scope** (DLP, insider risk, information-protection/label, audit),
their **severities**, and the **response SLAs** (e.g. high-severity triaged within X hours) that define the
triage queue.
**Why:** "Triage the alerts" is only operable when the queue, priorities, and response times are defined;
SLAs make triage measurable as a KPI.
**Verify:** The categories, severities, and SLAs are documented and agreed; the alert rollup groups by
those categories.
**Implement:** Agree the scope and SLAs with security/compliance stakeholders and record them in the
operating runbook before triage begins.

## 2.8 A defined KPI set, thresholds, and review governance
**Description:** The **KPIs** that define program health (e.g. % policies enforced vs test, alert volume
and mean triage time, improvement-action burn-down, compliance-score trend, privileged-role count), their
**thresholds**, and the **governance forum** (who reviews, how often).
**Why:** Proving health requires an agreed measure and a forum that acts on it; undefined KPIs produce a
dashboard nobody owns.
**Verify:** The KPI list with thresholds is documented; a recurring program-health review is scheduled with
named attendees.
**Implement:** Agree the KPI set and thresholds with leadership/compliance, schedule the review cadence, and
set the dashboard up to report exactly those measures.

## 2.9 Change-control process and window for live-policy edits
**Description:** A **change-control** path — request, review/approval, change window, recorded change,
rollback plan — for edits to live DLP, label, and retention policies.
**Why:** Editing a live, enforcing policy is high-impact; uncontrolled changes are the classic Purview
outage. Change control makes every change reviewed, timed, recorded, and reversible.
**Verify:** A change-record store exists (`Change Record – Purview – ChangeControl`) and a change window /
approver are named; `PURVOPS-Remediation.ps1` defaults to `-WhatIf` and stamps a change record on `-Commit`.
**Implement:** Define the approval path and window with stakeholders; adopt the `-WhatIf`-first discipline
and the change record for every operational change.

---
## Checklist
- [ ] Implemented Purview foundation present to operate (2.1)
- [ ] Least-privilege, role-separated operations roles assigned (2.2)
- [ ] S&C PowerShell + Graph installed; Graph security read scopes consented (2.3)
- [ ] Policy baseline recorded for drift detection (2.4)
- [ ] Compliance Manager export established (no public API) (2.5)
- [ ] Approved role-membership list captured as the access-review baseline (2.6)
- [ ] Alert-triage scope, severities, and SLAs defined (2.7)
- [ ] KPI set, thresholds, and program-health review forum agreed (2.8)
- [ ] Change-control path, window, and change record in place; `-WhatIf`-first adopted (2.9)
