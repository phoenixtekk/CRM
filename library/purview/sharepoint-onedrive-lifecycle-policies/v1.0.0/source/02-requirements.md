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
