# 2. Requirements Guide — Microsoft Purview Administrator Training

Verify **every** requirement before running the labs. Each entry follows **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are published once in
`global-requirements-purview.md` — this guide covers the prerequisites specific to standing up and
running the **training curriculum** and does not repeat the six category requirements.

> **Vendor boundary.** Microsoft Purview portal, M365 admin center, Security & Compliance PowerShell,
> and Microsoft Graph paths are authored from Microsoft's current public documentation. Purview
> capability availability is **licensing-dependent** and the portal **evolves** — flagged **"verify
> your licensing/tenant."** This is administrator training: **illustrative** taxonomies, retention
> periods, and policy scopes are used so trainees can practice; **real** records/retention/legal and
> HR/privacy determinations are deferred to the relevant governance functions.

## 2.1 A training environment — sandbox tenant preferred, scoped production acceptable
**Description:** An environment to run the hands-on labs. A **dedicated sandbox/training/dev tenant** is
strongly preferred; where labs must run in a production tenant, they are strictly confined to the
training scope group and simulation/test mode and torn down afterward.
**Why:** Labs create real Purview objects (labels, DLP policies, retention policies, an eDiscovery
case). A sandbox isolates that from production; scoped-and-simulated is the fallback discipline when it
cannot.
**Verify:** Confirm which tenant the team will train in, and that you have admin sign-in to it. Run
`OPSTRAIN-Readiness.ps1` — it reports the connected tenant and whether the training scope exists.
**Implement:** Provision or nominate a training tenant; if using production, agree the confinement rules
(scope group + simulation/test + teardown) with change control before Lab 1.

## 2.2 A training scope group and naming convention
**Description:** A **security group `TRAIN-Pilot-Users`** containing only training/test accounts, and the
`TRAIN-` object-naming convention used verbatim across every lab and script.
**Why:** Labels, DLP, retention, and auto-labeling are all published/targeted to this group so a lab
never touches a real user; the `TRAIN-` prefix makes every training artifact unmistakable and safe to
tear down.
**Verify:** In **Entra ID → Groups** (or `Get-MgGroup`) confirm `TRAIN-Pilot-Users` exists and contains
only test accounts. `OPSTRAIN-Readiness.ps1` flags whether the group is present.
**Implement:** Create the group with test accounts (`OPSTRAIN-LabScope.ps1 -Commit` can create/verify it),
and reserve the `TRAIN-` naming convention before configuring anything.

## 2.3 Least-privilege Purview role groups for the trainees
**Description:** Each trainee holds the **least-privilege Purview role group** the module needs —
e.g. **Information Protection** (labels), **Compliance Data Administrator / Compliance Administrator**
(DLP, retention), **Records Management**, **Insider Risk Management** roles, **Communication
Compliance** roles, **Audit** roles, **eDiscovery Manager** — with Global Administrator reserved and
avoided.
**Why:** Purview uses fine-grained role groups; a lab only works with the matching role, and training on
least-privilege is itself a core competency. Insider Risk and Communication Compliance require
**strict role separation** (analyst vs investigator vs admin) as a privacy control.
**Verify:** **Purview portal → Settings → Roles & scopes / Permissions** — confirm each trainee's role
group membership. `OPSTRAIN-Readiness.ps1` reports the connected admin's readable role context.
**Implement:** Assign the least-privilege role group per module under change control; for Modules 5–6
assign the **separated** roles to different people. Do not grant Global Administrator "to make the lab
work."

## 2.4 Security & Compliance PowerShell + Microsoft Graph toolchain
**Description:** A workstation with **ExchangeOnlineManagement** (for `Connect-IPPSSession`) and
**Microsoft.Graph** PowerShell modules, PowerShell 5.1+ or 7+, and a modern-auth/MFA-capable admin
account.
**Why:** The labs and all five provided scripts run through Security & Compliance PowerShell and Graph;
learning the cmdlet surface is part of the curriculum.
**Verify:** `Connect-IPPSSession` and `Connect-MgGraph` both succeed; `Get-Label` returns without error.
`OPSTRAIN-Readiness.ps1` performs these connectivity checks.
**Implement:** `Install-Module ExchangeOnlineManagement` and `Install-Module Microsoft.Graph`; confirm
modern-auth sign-in before Lab 0.

## 2.5 Licensing sufficient for the modules in scope (verify per feature)
**Description:** The **compliance licensing** each in-scope module requires — E3 for baseline labels and
manual retention; **E5 / E5 Compliance** for advanced DLP, auto-labeling, insider risk, communication
compliance, **Audit Premium**, **eDiscovery Premium**, and **DSPM** (some capabilities preview).
**Why:** Purview features are plan-gated; an unlicensed feature is not visible and its lab cannot run in
full. Knowing *which* license unlocks *what* is itself an administrator competency.
**Verify:** In the **M365 admin center** confirm subscriptions/add-ons; confirm each module's feature is
visible in the Purview portal. `OPSTRAIN-Readiness.ps1` probes which feature areas are readable and warns
where one is not (likely unlicensed).
**Implement:** Assign the required licensing before the corresponding module, **or** run that module as a
read-only walkthrough. **Verify your licensing/tenant** — do not assume availability.

## 2.6 Illustrative lab data and scope (not real regulated data)
**Description:** **Illustrative** sample content and an **illustrative** classification/label/retention
scheme for the labs (e.g. a `TRAIN-Label-Confidential` label, a synthetic-PII test document for DLP) —
explicitly **not** real regulated records, real employee communications, or a live records schedule.
**Why:** Trainees must practice the mechanics on safe data; using real regulated data or a real schedule
would turn a *training exercise* into a *governance action*, which is a determination reserved to the
governance functions.
**Verify:** Confirm the sample content is synthetic/non-sensitive and the taxonomy/periods are labeled
"illustrative." Insider Risk / Communication Compliance labs use **no** real employee data.
**Implement:** Prepare synthetic sample files and an illustrative taxonomy before the relevant labs; keep
real schedules and real cases out of the training environment.

## 2.7 Stakeholders identified for the hand-off (compliance, records, privacy, HR, legal)
**Description:** The named **compliance, records-management, privacy, HR, and legal** stakeholders who own
the real determinations the trained administrators will *implement* — retention schedules, records file
plans, legal holds, insider-risk and communication-compliance policy and case outcomes.
**Why:** Training builds the *technical* operator; the *governance* decisions stay with these functions.
Modules 5–6 in particular are HR/privacy-sensitive and their outcomes are never the administrator's call.
**Verify:** The owners are named and the hand-off (who decides vs who configures) is written down.
**Implement:** Identify the owners before Module 10 so the runbooks route each real decision to the right
function; capture the RACI in the operations runbook.

## 2.8 A pilot scope and change control for the training rollout
**Description:** A **pilot cohort** (the first trainees), **simulation/test/disabled mode confirmed
available** for the high-impact labs, and a **change-control** path for any training object created in a
shared tenant — mirroring the category-wide pilot/change-control requirement, applied to the *training
program itself*.
**Why:** The curriculum is delivered the same disciplined way it teaches: piloted, validated, then
expanded — and any object created in a shared tenant follows change control and is torn down.
**Verify:** A named first cohort, confirmed simulation/test availability for Modules 2 and 4, and an
agreed change/teardown window.
**Implement:** Define the cohort and change-control path before Lab 1; use each lab's teardown to leave
the tenant clean.
