# SharePoint & OneDrive Lifecycle Policies — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: DLCSPO

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — SharePoint & OneDrive Lifecycle Policies: Microsoft Purview

SharePoint and OneDrive fill up and never empty. Sites accumulate a decade of documents; departed
employees' OneDrive accounts linger indefinitely; the same file exists in five versions across three
libraries. Some of that content **must be kept** for a regulatory or business period; much of it **should
be cleaned up** once it ages out — and doing neither is the default. That is both a compliance gap (you
can't prove you keep what you must) and a standing risk (you're holding stale, discoverable content you no
longer need). This solution closes that gap with **Microsoft Purview Data Lifecycle Management** —
retention policies for SharePoint and OneDrive that retain content on schedule and clean it up when it
ages out — configured, piloted, validated, and defensible.

This is a complete, do-it-today package written for an administrator implementing a content lifecycle for
the first time. It delivers the capability end-to-end — from reading existing policies and coverage,
through translating the retention schedule into rules and creating the policy **retain-only** on a limited
pilot, to observing the Preservation Hold Library, validating, and only then enabling deletion as a
deliberate, approved step — with every policy, rule, and scope named once and reused everywhere. Because
deletion after its window is **irreversible**, the guide never deletes on its own: it starts retain-only
and gates cleanup behind an explicit, separate action. Because capability availability (e.g. adaptive
scopes) is licensing-dependent and the portal is evolving, the guide cites the method and flags every
capability "verify your licensing/tenant."

## What you get
- A plain-language Solution Overview of retention policies — retain, retain-then-delete, delete-only, and
  static vs adaptive scopes — and how location policies differ from item-level retention labels.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: retention licensing
  (E3 baseline; E5 for adaptive scopes), the least-privilege records role, the S&C PowerShell toolchain,
  the retention schedule translated to rules, the in-scope locations and scope method, a limited pilot
  scope with change control, and Preservation Hold Library / eDiscovery-hold awareness.
- An Implementation Guide of precise, ordered steps: assess, design the schedule, create the policy
  retain-only on the pilot, pilot and observe the hold library, validate, **enable deletion deliberately**,
  then expand.
- Five PowerShell tools — Discovery, a prerequisite/health helper, a safe Configuration/Remediation tool
  (`-WhatIf` by default; delete behind its own explicit action), Validation, and Reporting — built on
  Security & Compliance PowerShell, **read-only or `-WhatIf` by default with no credentials in code**.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
SharePoint and OneDrive on a lifecycle from Purview: in-scope content retained for the schedule and
cleaned up when it ages out — proven on a limited pilot in retain-only mode before any deletion.

## The deployment model
Assess → Design → Configure (**retain-only**) → Pilot → Validate → Expand (**enable deletion
deliberately**) — with a pilot gate before the estate and deletion enabled only after validation and
approval.

## Outcome
The content-hoarding blind spot closed — the right content kept for the right period and the rest cleaned
up on schedule — with the schedule and the keep/delete determination left to the records, compliance, and
legal owners who make it, and no content ever deleted before it was deliberately approved.


---


# 1. Solution Overview — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

## What this solution is
SharePoint and OneDrive fill up and never empty. Sites accumulate a decade of documents; departed
employees' OneDrive accounts linger; the same file exists in five versions across three libraries. Some
of that content **must be kept** for a regulatory or business period; much of it **should be cleaned up**
once it ages out. Doing neither is the default, and it is both a compliance gap (you can't prove you keep
what you must) and a risk (you're holding stale, discoverable content you no longer need). This solution
closes that gap with **Microsoft Purview Data Lifecycle Management** — **retention policies** for
SharePoint and OneDrive that:

- **Retain** content for a defined period so it can't be permanently deleted before its time — satisfying
  the "keep it" side of the schedule.
- **Clean up** content when it ages out — **retain-then-delete** (keep for N years, then remove) or
  **delete-only** — satisfying the "don't hoard it" side.
- **Scope precisely** — apply to **all** SharePoint sites and OneDrive accounts, or to a targeted set via
  a **static scope** (named sites/accounts) or an **adaptive scope** (a rule over site/user properties),
  so the right content gets the right rule.
- **Operate safely** — SharePoint/OneDrive retention keeps deleted-but-retained content in the
  **Preservation Hold Library** so nothing is lost mid-flight, and the policy is proven on a **limited
  pilot scope in retain-only mode first** before any deletion is enabled.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com) and **Security &
Compliance PowerShell** (`Connect-IPPSSession`) — no third-party tooling. Policies are configured,
**piloted on a limited scope first**, validated against pass/fail gates, then expanded.

> **Retention *policies* apply a period to a location; retention *labels* classify individual items.**
> This solution uses **retention policies** (and adaptive/static scopes) to apply a lifecycle to
> SharePoint sites and OneDrive accounts at the location level. Item-level **retention labels** and
> **records management / file plans** are a complementary, separate effort. The two work together; this
> solution delivers the location-level lifecycle.

## Why this matters
- **You can't prove retention you didn't configure.** "We keep project records for seven years" is a
  policy statement only when a retention policy enforces it — otherwise a user can permanently delete a
  document tomorrow.
- **Stale content is liability.** Every obsolete file you keep past its usefulness is discoverable in
  litigation, exposed in a breach, and clutter in search. Cleanup that runs on a schedule shrinks that
  surface without anyone remembering to do it.
- **Departed-employee OneDrive sprawl.** OneDrive accounts of leavers accumulate; a lifecycle policy
  gives them a defined end instead of indefinite, unmanaged persistence.
- **It is defensible and auditable.** "Every in-scope site retains for the schedule and cleans up after"
  is a statement you can evidence with a policy and a report, not a hope.

## How it works
1. **Assess.** Read the tenant's current state — existing **retention policies and rules**, which
   SharePoint/OneDrive locations they cover, and whether adaptive scopes exist — all read-only.
2. **Design.** With records/compliance, translate the **retention schedule** into concrete rules: what
   period, retain-only vs retain-then-delete vs delete-only, and the **scope** (all locations, a static
   set, or an adaptive rule) for each. The schedule itself is a records/legal determination — you
   implement it.
3. **Configure.** Create the **`SPO-OneDrive Retention – Policy`** and its rule(s) in Purview, scoped to
   the pilot first, **starting in retain-only** where deletion is intended (add deletion after
   validation).
4. **Pilot.** Apply to a **limited pilot scope** (`SPO Lifecycle – Pilot Scope – Stage1`: a small set of
   sites / an adaptive-scope subset) — never all locations on day one. Deletion is **irreversible after
   the hold window**; prove the scope and behavior first.
5. **Validate.** Confirm the policy covers exactly the intended locations, that retained content is held
   (Preservation Hold Library), and — only when you deliberately test deletion — that cleanup behaves as
   designed, against the pass/fail gates.
6. **Expand.** Broaden the scope to all intended locations, enable the **delete** action once retain-only
   is validated and stakeholders approve, and hand ongoing coverage and reporting to operations.

## The lifecycle design (used throughout)
Names below are examples; the **schedule** (periods, what to keep, what to delete) is a records/compliance
**determination** — this solution provides the technical implementation.

| Element | Design intent |
|---|---|
| Retention policy | `SPO-OneDrive Retention – Policy` (SharePoint + OneDrive locations) |
| Retain-only rule | Keep in-scope content for the schedule's period; no deletion (start here) |
| Retain-then-delete rule | Keep for N years from create/modify, then delete (enabled after validation) |
| Scope | `all locations`, a **static scope** (named sites/accounts), or an **adaptive scope** (rule over properties) |
| Pilot scope | `SPO Lifecycle – Pilot Scope – Stage1` — limited sites / adaptive subset |
| Schedule/design map | `Lifecycle Schedule – Map` |
| Coverage report | `Lifecycle – Coverage Report` |

> **Licensing / plan note — verify against your own tenant.** Basic retention policies for SharePoint and
> OneDrive are available with Microsoft 365 E3; **adaptive scopes** and advanced retention capabilities
> generally require **E5 / E5 Compliance**. Confirm the exact capability availability and portal paths for
> *your* tenant in Microsoft's documentation before you design — the Data Lifecycle Management surface is
> evolving. Where a capability (e.g. adaptive scope) is unavailable, use a **static scope** and record the
> advanced capability as **deferred**.

## What you get
- This **Solution Overview**, a **Requirements Guide** (every prerequisite with verify /
  implement-if-missing), a precise **Implementation Guide**, a **Testing Guide** with pass/fail gates, a
  **Troubleshooting Guide**, and field-proven **Best Practices**.
- **Five PowerShell tools** — Discovery, a prerequisite/health helper, a safe Configuration/Remediation
  tool (`-WhatIf` by default), Validation, and Reporting — built on Security & Compliance PowerShell,
  **read-only or `-WhatIf` by default and with no credentials in code**.

> **Boundary.** The **retention schedule** — how long content must be kept, what is a record, what may be
> deleted and when, and any legal hold — is a **determination owned by your records-management,
> compliance, and legal functions**. This solution provides the technical configuration and the evidence,
> and (critically) never deletes on its own — deletion is enabled deliberately after validation and
> approval. It provides the method, not the determination.


---


# 2. Requirements Guide — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 Retention licensing (E3 baseline; E5 for adaptive scopes/advanced)
**Description:** A tenant licensed for **retention policies** for SharePoint/OneDrive — **Microsoft 365
E3** covers basic retention; **adaptive scopes** and advanced Data Lifecycle Management capabilities
generally require **E5 / E5 Compliance**. (Global Requirement 1.)
**Why:** Basic location-scoped retention works on E3, but if your design uses adaptive scopes it is
plan-gated.
**Verify:** M365 admin center → `Billing → Licenses`; in the Purview portal confirm **Data Lifecycle
Management → Retention policies** is available and whether **adaptive scopes** can be created.
`DLCSPO-Check-Prereqs.ps1` reports the retention signal. **Verify against your own plan.**
**Implement:** Assign the required licensing; where adaptive scopes are unavailable, use a **static scope**
and record adaptive scoping as **deferred**.

## 2.2 Least-privilege records/retention role
**Description:** A least-privilege role that can manage retention — **Records Management** or
**Compliance Administrator** (or a custom role group with retention-management rights) — in the Purview
portal. Reserve **Global Administrator** for one-time enablement only. (Global Requirement 2.)
**Why:** Creating/publishing retention policies and rules requires the matching role; retention (and
deletion) is high-impact, so least privilege matters.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` shows Records Management /
Compliance Administrator; `Connect-IPPSSession` succeeds and `Get-RetentionCompliancePolicy` runs.
**Implement:** Assign the least-privilege role under change control; do not use Global Administrator for
day-to-day retention authoring.

## 2.3 Security & Compliance PowerShell toolchain
**Description:** A workstation with **ExchangeOnlineManagement** (provides `Connect-IPPSSession` for
`Get-/New-/Set-RetentionCompliancePolicy` and `...Rule`, and `Get-AdaptiveScope` where licensed), with a
modern-auth / MFA admin. (Global Requirement 3.)
**Why:** Retention policies/rules and scopes are read/authored through Security & Compliance PowerShell;
the provided scripts run there.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession` succeeds and
`Get-RetentionCompliancePolicy` returns. `DLCSPO-Check-Prereqs.ps1` reports module/connection state.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; confirm modern-auth sign-in
before running steps.

## 2.4 The retention schedule translated to rules (records/compliance owned)
**Description:** The organization's **retention schedule** — how long each content class must be kept,
what is a record, what may be deleted and when — translated into concrete **retain-only /
retain-then-delete / delete-only** rules with periods, owned and signed off by
**records-management/compliance/legal**. (Global Requirements 4 & 5.)
**Why:** The policy enforces a schedule; the schedule (periods, keep/delete decisions, legal hold) is a
records/legal **determination**, not a technical default.
**Verify:** The schedule and its mapping to rules/periods are documented and approved; named approvers
recorded in `Lifecycle Schedule – Map`.
**Implement:** Obtain the schedule and the keep/delete determinations before authoring rules; where the
schedule is incomplete, configure **retain-only** and defer deletion until it is agreed.

## 2.5 In-scope SharePoint/OneDrive locations and the scope method
**Description:** The **SharePoint sites and OneDrive accounts in scope**, and the **scope method** for
each rule — **all locations**, a **static scope** (named sites/accounts), or an **adaptive scope** (a
rule over site/user properties). (Global Requirement 4.)
**Why:** Retention keys off the in-scope locations; the wrong scope either misses content or over-retains
content it shouldn't.
**Verify:** `DLCSPO-Discover.ps1` reports existing policies and their covered locations; confirm the
intended in-scope locations with SharePoint/records owners.
**Implement:** Enumerate the in-scope sites/accounts and choose static vs adaptive per rule; where
adaptive is unavailable (2.1), use static and record the drift-management implication.

## 2.6 A limited pilot scope and change control
**Description:** A **limited pilot scope** — `SPO Lifecycle – Pilot Scope – Stage1`: a small set of sites
/ an adaptive-scope subset — plus a **change-control** process (Global Requirement 6), and the discipline
to **start retain-only** before enabling deletion.
**Why:** Deletion is **irreversible after the hold window**; retention changes are high-impact. Prove the
scope and behavior on a limited pilot in retain-only mode before enabling cleanup or expanding.
**Verify:** The pilot scope is defined; a change window/approval path exists; the plan starts retain-only.
**Implement:** Define the pilot scope and agree change control; enable the **delete** action only after
the pilot validates and stakeholders approve.

## 2.7 Awareness of Preservation Hold Library and interactions
**Description:** Awareness that SharePoint/OneDrive retention keeps deleted-but-retained content in the
**Preservation Hold Library**, and of interactions with **eDiscovery holds**, existing labels, and
storage growth from the hold library.
**Why:** Retention behavior (nothing is truly lost mid-window; storage can grow) and hold interactions
must be understood so validation and troubleshooting interpret behavior correctly.
**Verify:** Confirm the Preservation Hold Library behavior is understood; check for existing eDiscovery
holds on in-scope locations; note expected storage impact.
**Implement:** Account for the hold-library storage in capacity planning; coordinate with eDiscovery
owners where holds overlap; document the interactions in `Lifecycle Schedule – Map`.

---
## Checklist
- [ ] Retention licensing confirmed (E3 baseline; E5 for adaptive scopes, else static + deferred)
- [ ] Records Management / Compliance Administrator role assigned least-privilege
- [ ] ExchangeOnlineManagement installed; `Connect-IPPSSession` succeeds; `Get-RetentionCompliancePolicy` runs
- [ ] Retention schedule translated to retain-only / retain-then-delete rules; approvers named
- [ ] In-scope SharePoint/OneDrive locations enumerated; scope method (all/static/adaptive) chosen per rule
- [ ] `SPO Lifecycle – Pilot Scope – Stage1` defined; change control agreed; plan starts **retain-only**
- [ ] Preservation Hold Library behavior + eDiscovery-hold/storage interactions understood


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


# 3. Implementation Guide — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

Follow these steps in order. The model is **Assess → Design → Configure → Pilot → Validate → Expand**.
Every write is **piloted on `SPO Lifecycle – Pilot Scope – Stage1` first**, previewed with `-WhatIf`, and
**starts retain-only** — deletion is enabled deliberately only after validation. Named objects are
introduced once and reused everywhere:

| Object | Name |
|---|---|
| Retention policy | `SPO-OneDrive Retention – Policy` |
| Retain-only rule | `SPO-OneDrive – Retain-Only Rule` |
| Retain-then-delete rule | `SPO-OneDrive – Retain-Then-Delete Rule` (enabled after validation) |
| Pilot scope | `SPO Lifecycle – Pilot Scope – Stage1` |
| Schedule/design map | `Lifecycle Schedule – Map` |
| Coverage report | `Lifecycle – Coverage Report` |

> **The policy never deletes on its own until you enable it.** A retain-only rule keeps content and
> deletes nothing. Only a **retain-then-delete** or **delete-only** rule removes content — and only after
> its period elapses. This solution keeps the delete action **off through the pilot** and enables it as a
> deliberate, approved step. **Verify capability availability (e.g. adaptive scopes) against your
> licensing/tenant.**

## Step 0 — Connect (all steps)
Open PowerShell 5.1+ or 7+ and connect with a modern-auth/MFA admin:
```powershell
Connect-IPPSSession                 # Security & Compliance PowerShell (retention policies + rules)
```
Keep credentials out of scripts — sign in interactively. **Pass/fail:** the connection succeeds and
`Get-RetentionCompliancePolicy` returns without error.

## Step 1 — Assess current state (Assess)
1. Run `DLCSPO-Discover.ps1`. Read-only, it reports every **retention policy and rule**, whether each
   covers **SharePoint** and/or **OneDrive**, the period/action of each rule, and any **adaptive scopes**.
2. Run `DLCSPO-Check-Prereqs.ps1` — module/connection, the retention/role signals, whether adaptive
   scopes are available, and existing policies — PASS/GAP per signal.
3. Record every GAP and remediate before configuring. **Pass/fail:** the inventory and prereq report
   complete; existing coverage and any overlap is captured in `Lifecycle Schedule – Map`.

## Step 2 — Design the lifecycle (Design)
1. With records/compliance, translate the **retention schedule** into concrete rules: period(s), and for
   each whether it is **retain-only**, **retain-then-delete**, or **delete-only** (the last two enabled
   after validation). Record every determination and its approver in `Lifecycle Schedule – Map`.
2. Choose the **scope** per rule — all locations, a **static scope** (named sites/accounts), or an
   **adaptive scope** (rule over properties). Define `SPO Lifecycle – Pilot Scope – Stage1`.
3. Confirm which capabilities your licensing supports (adaptive scopes E5); mark any unsupported approach
   **deferred** and fall back to static scoping.
   **Pass/fail:** `Lifecycle Schedule – Map` is agreed and signed off; the keep/delete determinations are
   owned by records/compliance, not IT.

## Step 3 — Create the policy in retain-only mode (Configure)
Do this **for the pilot scope first**, and **retain-only** — no deletion yet.

1. **Create the policy + retain-only rule.** Preview then commit:
   ```powershell
   .\DLCSPO-Set-RetentionPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -RetainDays 2555 -WhatIf
   .\DLCSPO-Set-RetentionPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -RetainDays 2555 -Commit
   ```
   This creates `SPO-OneDrive Retention – Policy` scoped to the pilot sites (and OneDrive where designed)
   with the **retain-only** rule — content is **retained**, nothing is deleted. Verify with
   `Get-RetentionCompliancePolicy` / `Get-RetentionComplianceRule`.
2. **Confirm scope in the portal.** Purview portal → **Data Lifecycle Management → Retention policies** →
   the policy → confirm the locations equal the pilot scope and the rule is retain-only.
   **Pass/fail:** the policy exists, covers exactly the pilot scope, retains for the intended period, and
   deletes nothing (no retain-then-delete/delete rule is enabled yet).

## Step 4 — Pilot on the limited scope (Pilot)
1. Let the policy apply to the pilot scope. Confirm that content in a pilot site **cannot be permanently
   removed** before its period — deleting a file routes a copy to the **Preservation Hold Library**.
2. Do **not** enable deletion yet. Observe retention behavior only.
   **Pass/fail:** retained content is held; a delete attempt on a pilot document is preserved (hold
   library) as expected; discrepancies are recorded for troubleshooting, not worked around.

## Step 5 — Validate the pilot (Pilot → Validate)
1. Run `DLCSPO-Validate.ps1`. Read-only, it confirms `SPO-OneDrive Retention – Policy` exists, covers the
   intended locations, the rule period matches design, and **no unintended delete action** is enabled —
   PASS/FAIL per gate.
2. Confirm the Preservation Hold Library behavior on a pilot site end-to-end.
3. Complete the **Testing Guide** on the pilot. **Pass/fail:** all Testing-Guide gates pass on
   `SPO Lifecycle – Pilot Scope – Stage1`.

## Step 6 — Enable cleanup and expand (Expand)
1. **Enable deletion deliberately** — only after retain-only is validated and stakeholders approve. Add
   the retain-then-delete behavior:
   ```powershell
   .\DLCSPO-Set-RetentionPolicy.ps1 -Action EnableDelete -RetainDays 2555 -WhatIf
   .\DLCSPO-Set-RetentionPolicy.ps1 -Action EnableDelete -RetainDays 2555 -Commit
   ```
   This sets the rule to **retain-then-delete** (keep for the period, then delete). Communicate the change
   first; deletion after the window is irreversible.
2. **Expand the scope** to all intended locations (or switch a static scope to the full set / an adaptive
   scope) once validated.
3. Run `DLCSPO-Report.ps1 -CsvPath .\LifecycleReport.csv` to produce `Lifecycle – Coverage Report` — each
   policy/rule, its locations, period, and action — as the management evidence artifact, and re-run it on
   a schedule.
   **Pass/fail:** the policy covers all intended locations; the intended action (retain / retain-then-
   delete) is enabled per approval; the report shows coverage as designed.

---
### Rollback
- **Disable / delete the policy** (`Set-RetentionCompliancePolicy ... -Enabled $false` or remove it) to
  stop enforcement — retention stops applying going forward. Content already in the Preservation Hold
  Library follows the documented release behavior.
- **Revert deletion** by returning the rule to **retain-only** before the delete window elapses; once
  content is deleted after the window, it is **not recoverable** — which is why deletion is enabled only
  after validation and approval.
- **Narrow the scope** back to the pilot to reduce blast radius. Keep `Lifecycle Schedule – Map` as the
  record of the intended state.

### Order of operations
`Assess policies + coverage → design schedule → rules + scope (map) → create policy retain-only on pilot →
pilot + observe hold library → validate → enable delete deliberately (approved) → expand scope → report
coverage`


---


# 5. Testing Guide — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

Run after each configuration step. Every test is safe (read-only or a `-WhatIf` preview) except where it
asks you to observe real retention behavior on a pilot site. Validate on `SPO Lifecycle – Pilot Scope –
Stage1` in **retain-only** mode before enabling any deletion or expanding.

## Test 1 — Prerequisites and enablement are in place
**Do:** Run `DLCSPO-Check-Prereqs.ps1`.
**Expected:** ExchangeOnlineManagement present and connected; Records Management / Compliance
Administrator role reported; the retention and adaptive-scope signals reported; existing policies listed.
Every gap (e.g. adaptive scopes unavailable → static scoping) is **recorded, not guessed**.

## Test 2 — Discovery inventory is complete
**Do:** Run `DLCSPO-Discover.ps1`.
**Expected:** Every retention policy and rule is listed with whether it covers **SharePoint** and/or
**OneDrive**, its **period and action** (retain / retain-then-delete / delete), and any adaptive scopes —
matching what the Purview portal shows under Data Lifecycle Management.

## Test 3 — Create dry-run makes no changes
**Do:** Run `DLCSPO-Set-RetentionPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -RetainDays 2555 -WhatIf`.
**Expected:** It states the policy/rule/scope it *would* create (retain-only) plus the reverse action and
changes nothing; a follow-up `Get-RetentionCompliancePolicy` shows no new policy until `-Commit`.

## Test 4 — Policy exists, retain-only, scoped to the pilot
**Do:** After `-Commit`, run `Get-RetentionCompliancePolicy -Identity "SPO-OneDrive Retention - Policy"`
and `Get-RetentionComplianceRule`.
**Expected:** The policy exists, covers exactly the pilot locations (SharePoint and/or OneDrive as
designed), the rule retains for the intended period, and **no delete action** is enabled.

## Test 5 — Retained content cannot be permanently removed before its period
**Do:** On a pilot site, delete a test document, then check the site's **Preservation Hold Library**.
**Expected:** A copy of the deleted document is preserved in the Preservation Hold Library — retention is
protecting the content; nothing is lost mid-window. (Verify the hold-library behavior against current
Microsoft guidance.)

## Test 6 — Validation gate passes on the pilot (retain-only)
**Do:** Run `DLCSPO-Validate.ps1`.
**Expected:** PASS for each gate — the policy exists, covers the intended locations, the period matches
design, and **no unintended delete action** is enabled. Any FAIL names the specific issue.

## Test 7 — Enable-delete dry-run makes no changes and is reversible
**Do:** Run `DLCSPO-Set-RetentionPolicy.ps1 -Action EnableDelete -RetainDays 2555 -WhatIf`.
**Expected:** The dry-run states it *would* switch the rule to **retain-then-delete** plus the reverse
action (back to retain-only) and changes nothing; a follow-up `Get-RetentionComplianceRule` shows the
rule unchanged.

## Test 8 — Deletion behaves as designed (deliberate, after approval)
**Do:** Only after retain-only is validated and approved: enable delete with `-Commit`, then verify the
rule's action.
**Expected:** The rule is **retain-then-delete** for the intended period; content will be deleted only
**after** its period elapses (not immediately). Deletion after the window is irreversible — this is why it
is enabled deliberately.

## Test 9 — Scope is exactly what was intended
**Do:** In the portal, review the policy's locations (and any adaptive-scope rule) against
`Lifecycle Schedule – Map`.
**Expected:** The covered SharePoint sites / OneDrive accounts match the intended scope precisely — no
site is missed, and none is over-retained by accident.

## Test 10 — Reporting evidence is produced
**Do:** Run `DLCSPO-Report.ps1 -CsvPath .\LifecycleReport.csv`.
**Expected:** `Lifecycle – Coverage Report` lists each policy/rule, its SharePoint/OneDrive locations,
period, and action — usable as the management evidence artifact and re-runnable on a schedule.

---
### Pass/fail summary
All gates green on `SPO Lifecycle – Pilot Scope – Stage1` — policy present and retain-only, retained
content held in the Preservation Hold Library, scope exactly as intended, and the coverage report produced
— before enabling deletion or expanding to the estate. Deletion is enabled only as a deliberate, approved
step; any deferred (licensing-gated) capability is recorded explicitly, not silently skipped.


---


# 6. Troubleshooting — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

Symptoms, likely causes, and fixes for the retention lifecycle. Stay in **retain-only pilot** while
diagnosing — reproduce on `SPO Lifecycle – Pilot Scope – Stage1` before enabling deletion or expanding,
and never enable the delete action to "test" a theory.

## "I deleted a file but it's still there" (Preservation Hold Library)
- **This is retention working.** SharePoint/OneDrive retention keeps a copy of deleted-but-retained
  content in the site's **Preservation Hold Library** until its period elapses. The user's view shows the
  file removed; the hold library retains the copy. Confirm in the site's Preservation Hold Library — this
  is expected, not a defect.

## The policy doesn't seem to apply / takes a long time
- **Propagation delay.** New retention policies can take time (often up to ~1 day, longer for large
  scopes) to fully apply across all locations. Confirm the policy is **Enabled** and wait before
  concluding failure.
- **Location not in scope.** Verify the site/account is actually in the policy's SharePoint/OneDrive
  locations (`DLCSPO-Discover.ps1` / the portal). A static scope only covers the URLs you listed.
- **Adaptive scope query mismatch.** If using an adaptive scope, the site/user may not match the query.
  Re-check the adaptive-scope rule and that the scope has finished evaluating.

## Content is being deleted when I expected retain-only
- **A delete action is enabled.** Run `DLCSPO-Validate.ps1 -ExpectDelete:$false`; if it FAILS the "no
  unintended deletion" gate, the rule is retain-then-delete/delete-only. Return it to retain-only with
  `Set-RetentionComplianceRule -Identity <rule> -RetentionComplianceAction Keep` (or
  `DLCSPO-Set-RetentionPolicy.ps1` was run with `-Action EnableDelete` — reverse it).
- **Reminder:** deletion only happens **after** the period elapses, and it is **irreversible**. Keep the
  action retain-only through the pilot; enable deletion only after validation and approval.

## `DLCSPO-Set-RetentionPolicy.ps1 -Commit` fails
- **Not connected / wrong session.** Ensure `Connect-IPPSSession` succeeded
  (`Get-Command Get-RetentionCompliancePolicy` resolves).
- **Insufficient role.** Creating retention policies needs Records Management / Compliance Administrator.
  Confirm in Purview → Roles & scopes / Permissions.
- **Action/parameter name by module version.** The retain-then-delete action name and rule parameters vary
  across ExchangeOnlineManagement versions (e.g. `KeepAndDelete` vs a `-RetentionComplianceAction` value).
  Verify against your version; update the module if it's far behind.
- **Site URL not resolvable.** A SharePoint URL in `-PilotSites` must be a valid, existing site collection
  URL. Confirm the URL and that you have rights to it.

## Adaptive scope options aren't available
- **Licensing.** Adaptive scopes generally require **E5 / E5 Compliance**. `DLCSPO-Check-Prereqs.ps1`
  reports the `Get-AdaptiveScope` signal. Where unavailable, use a **static scope** and schedule a review
  to catch drift — record adaptive scoping as **deferred**.

## Storage is growing unexpectedly
- **Preservation Hold Library growth.** Retained-then-deleted content accumulates in the hold library
  until its period elapses. This is expected; account for it in capacity planning. It is not a reason to
  disable retention — coordinate storage with the schedule length.

## A location won't release content / conflicts with a hold
- **Overlapping holds win.** A location can be under a retention policy, a retention label, and an
  **eDiscovery hold** simultaneously; the **most restrictive** (longest/hold) wins, so content won't
  delete while any hold applies. Check for eDiscovery holds on the location before expecting deletion, and
  coordinate with the eDiscovery owner.

## `DLCSPO-Validate.ps1` reports a property/action mismatch that looks wrong
- **Module-version property shape.** Location and action properties are exposed under different names
  across module versions. Confirm the intended state in the portal (Data Lifecycle Management → the policy)
  and treat the validator line as informational where the portal disagrees; note the module version.

---
### When to stop and escalate
- A required capability is unavailable on your licensing/tenant (e.g. adaptive scopes) — record it
  **deferred**, fall back to static scoping, and route the licensing decision to the owner.
- **The schedule** — periods, what is a record, what may be deleted and when, and any legal hold — is a
  records/compliance/legal determination, not a technical fix. Capture it in `Lifecycle Schedule – Map`
  and defer the determination.
- If retention/deletion behavior can't be reconciled with the policy, keep the scope on the pilot in
  retain-only, gather `DLCSPO-Validate.ps1` + `DLCSPO-Report.ps1` output as evidence, and raise with
  Microsoft support before enabling deletion or expanding.


---


# 7. Best Practices — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

- **Start retain-only; enable deletion deliberately.** The single most important discipline: create the
  policy so it **retains** and deletes nothing, validate that, and enable the **delete** action only after
  approval. Deletion after the window is irreversible — never let it be the default.
- **The schedule is a records determination, not a technical default.** How long content is kept, what is
  a record, and what may be deleted are owned by records-management/compliance/legal. Configure the rules
  the schedule dictates; capture the determinations and approvers in `Lifecycle Schedule – Map`.
- **Pilot on a limited scope before all locations.** Prove the policy on `SPO Lifecycle – Pilot Scope –
  Stage1` — a small set of sites / an adaptive subset — before scoping to the estate. Retention behavior
  and hold-library growth are easier to reason about on a bounded scope.
- **Understand the Preservation Hold Library before you test.** Deleted-but-retained content lands in the
  hold library, so "I deleted it and it's still there" is retention working, not a bug. Account for the
  hold library's **storage growth** in capacity planning.
- **Prefer adaptive scopes for drift — where licensed.** An adaptive scope (rule over site/user
  properties) keeps coverage current as sites and accounts come and go; a static scope must be maintained
  by hand. Where adaptive scopes aren't licensed, use static and **schedule a review** to catch drift.
- **Coordinate with eDiscovery holds and existing labels.** A location can be under a retention policy, a
  retention label, and an eDiscovery hold at once; the most restrictive wins. Check for overlapping holds
  before enabling deletion so you don't fight a hold you didn't know about.
- **Retention policies vs retention labels — use the right tool.** Location-level lifecycle is a policy
  job (this solution); item-level classification and records/file-plan work are labels. Deploy them
  together, but don't try to do item-level records management with a location policy.
- **Communicate before enabling deletion.** Users notice when old content starts disappearing on
  schedule. Tell site owners what will be cleaned up and when before the delete action goes live, so
  cleanup reads as governance, not data loss.
- **Keep automation safe-by-default and secret-free.** Run discovery, validation, and reporting read-only;
  gate every write behind `-WhatIf` → `-Commit`; the delete action behind its own explicit `-Action
  EnableDelete -Commit`. Sign in interactively; no credentials or secrets in a script or a document.
- **Re-report on a schedule.** New sites and OneDrive accounts appear constantly. Re-run
  `DLCSPO-Report.ps1` periodically so `Lifecycle – Coverage Report` stays a live evidence artifact and
  catches locations that fell outside the scope.
- **Keep determinations with their owners.** The solution configures and evidences the lifecycle; the
  schedule, the keep/delete decision, and any legal hold are determinations for records-management,
  compliance, and legal. Keep that separation explicit so a technical rule is never mistaken for a
  records ruling.


---


# 8. Deliverables Summary — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | SharePoint + OneDrive retention/cleanup policies aligned to the schedule; retain-only first, deletion enabled deliberately; how location policies differ from item labels (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: assess policies, design the schedule, create the policy retain-only on the pilot, pilot + observe the hold library, validate, enable deletion deliberately, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Retention policy | `SPO-OneDrive Retention – Policy` |
| Retain-only rule | `SPO-OneDrive – Retain-Only Rule` |
| Retain-then-delete rule | `SPO-OneDrive – Retain-Then-Delete Rule` |
| Pilot scope | `SPO Lifecycle – Pilot Scope – Stage1` |
| Schedule/design map | `Lifecycle Schedule – Map` |
| Coverage report | `Lifecycle – Coverage Report` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DLCSPO-Discover.ps1` | Reports current state: every retention policy and rule, whether each covers SharePoint/OneDrive, its period and action, and any adaptive scopes — Security & Compliance PowerShell; read-only |
| `DLCSPO-Check-Prereqs.ps1` | Prerequisite/health helper: module, connection, the records/retention role and adaptive-scope signals, and existing policies — PASS/GAP per signal; read-only |
| `DLCSPO-Set-RetentionPolicy.ps1` | Configuration/Remediation: creates `SPO-OneDrive Retention – Policy` and its **retain-only** rule scoped to the pilot (`-Action CreatePolicy`), and — as a deliberate, separate step — switches the rule to **retain-then-delete** (`-Action EnableDelete`); **defaults to `-WhatIf`** (prints the plan + reverse action), applies only with `-Commit`; no secrets in code |
| `DLCSPO-Validate.ps1` | Validation: PASS/FAIL that the policy exists, covers the intended locations, the period matches design, and **no unintended delete action** is enabled — read-only |
| `DLCSPO-Report.ps1` | Coverage report — each policy/rule, its SharePoint/OneDrive locations, period, and action — written to CSV as `Lifecycle – Coverage Report`; read-only |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
SharePoint and OneDrive on a lifecycle from Purview — in-scope content retained for the schedule and
cleaned up when it ages out — proven on a limited pilot in retain-only mode before any deletion is enabled,
with the schedule and the keep/delete determination left to the records, compliance, and legal owners who
make it.
