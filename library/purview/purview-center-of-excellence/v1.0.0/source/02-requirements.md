# 2. Requirements Guide — Microsoft Purview Center of Excellence

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

> **Foundation assumed.** This solution governs a tenant where the Purview foundation is already in
> place (portal organized, core services on, unified audit ingesting, workloads connected). If that
> foundation is missing, stand it up first — the CoE is the *operating model* layered over a working
> Purview tenant, not the initial enablement.

## 2.1 Compliance licensing inventory (what the CoE can govern)
**Description:** A confirmed inventory of the tenant's **compliance licensing** — E3 for baseline
capabilities, **Microsoft 365 E5** or the **E5 Compliance** add-on for advanced DLP, auto-labeling,
insider risk, communication compliance, Audit Premium (long-term retention), and DSPM.
**Why:** The CoE's remit is bounded by what the plan unlocks; you cannot govern a capability the tenant
cannot run (Global Requirement 1).
**Verify:** Microsoft 365 admin center → `Billing → Licenses` shows the subscriptions/add-ons; run
`OPSCOE-ScopeCheck.ps1` — it reports the compliance SKUs present (via Graph) and which governed
capabilities are visible. Confirm capabilities appear in the Purview portal.
**Implement:** Record each licensed capability as **in remit** and each unlicensed one as
**out-of-scope for now** — do not attempt to govern a capability the tenant cannot use.

## 2.2 Least-privilege governance access (Compliance Administrator, not blanket Global Admin)
**Description:** An account holding **Compliance Administrator** to read the estate and manage role
groups, plus a named **Global Administrator** reserved only for the one-time actions that genuinely
require it (e.g. consenting Graph scopes). Everyday CoE work uses the least-privilege compliance role,
per Global Requirement 2.
**Why:** The CoE exists to enforce least privilege and separation of duties; running it from an
over-granted Global Admin contradicts the standard it publishes.
**Verify:** Purview portal → `Settings → Roles & scopes → Role groups` (verify path in your tenant) —
confirm your account is in **Compliance Administrator**. `Connect-IPPSSession` succeeds and
`Get-RoleGroup` returns.
**Implement:** Add the account to **Compliance Administrator**; reserve a named Global Administrator
only for consent/one-time setup.

## 2.3 Security & Compliance PowerShell + Exchange Online + Graph toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (provides
`Connect-IPPSSession` for Security & Compliance PowerShell **and** `Connect-ExchangeOnline` for the
audit-config cmdlets and role-group membership) and the **Microsoft Graph PowerShell SDK**, with a
modern-auth/MFA admin account (Global Requirement 3).
**Why:** Every script runs through S&C PowerShell (labels/DLP/retention/role groups), Exchange Online
PowerShell (audit config, `Add-RoleGroupMember`), and/or Graph (licensing, directory).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Authentication`;
`Connect-IPPSSession` and `Connect-MgGraph` both succeed. `OPSCOE-ScopeCheck.ps1` reports connectivity.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and
`Install-Module Microsoft.Graph -Scope CurrentUser`; confirm modern-auth sign-in.

## 2.4 Graph read scopes (read-first, no write scopes for governance reads)
**Description:** Delegated Graph scopes for the read-only inventory and scorecard:
`Organization.Read.All`, `Directory.Read.All`, `User.Read.All`, `RoleManagement.Read.Directory`. No
write scopes are required by the governance scripts.
**Why:** The scope, discovery, and register scripts read licensing, directory, and role data through
Graph; keeping to read scopes matches the safe-by-default posture.
**Verify:** Run `OPSCOE-ScopeCheck.ps1 -UseGraph` (read-only) — it connects with the read scopes and
reports if consent is missing.
**Implement:** Consent at first `Connect-MgGraph`; if admin consent is required, a Global Administrator
approves the scopes once in Entra (`Identity → Applications → Enterprise applications`).

## 2.5 A named CoE governance board (least-privilege, separated) and role-group matrix
**Description:** A named **governance board** — chair plus function representatives for information
protection, records, insider risk, communication compliance, eDiscovery, and audit — mapped to
**built-in Purview role groups** with **separation of duties** (insider risk / communication compliance
/ eDiscovery separate from governance administration), captured as a **role-group matrix** (CSV).
**Why:** The board is the decision body of the CoE; its least-privilege, separated membership is the
first standard the CoE enforces on itself (Global Requirements 2 and 5).
**Verify:** The matrix names each seat and its role group; `OPSCOE-ApplyStandards.ps1 -WhatIf` previews
the membership changes without applying them; `Get-RoleGroupMember` shows current membership.
**Implement:** Author `Purview CoE Charter – Board` and the matrix CSV; populate role groups with
`OPSCOE-ApplyStandards.ps1 -Commit` (adds named members to built-in role groups; creates custom scoped
groups only where needed).

## 2.6 The CoE standards, agreed and captured
**Description:** The **house rules** agreed and written down: the **naming convention**
(`<Purpose> – <Capability> – <State>`), the **ownership + review-cadence** rule (default quarterly),
the **simulation/test-first** rule, the **change-control/versioning** rule, and the
**separation-of-duties** rule — captured as `Purview CoE Standards – Baseline`.
**Why:** Standards are what `OPSCOE-Validate.ps1` checks against; without a captured baseline there is
nothing to validate conformance or detect drift against.
**Verify:** The standards baseline exists and names the pattern, cadence, and gates. `OPSCOE-Validate.ps1`
loads it and evaluates conformance.
**Implement:** Agree the standards with compliance/records/privacy/legal stakeholders (Global
Requirement 5); capture them as the standards baseline before governing the estate.

## 2.7 An intake workflow and change control
**Description:** A defined **intake workflow** (Request → Triage → Design → Pilot in simulation →
Validate → Board approval → Enforce → Register) and a **change-control** process with a change window
and approval path (Global Requirement 6).
**Why:** Intake is the gate that keeps ungoverned, unowned, or un-simulated policies out of the tenant;
change control makes every change reversible and auditable.
**Verify:** The workflow is documented with an owner per stage; a change window/approval path exists;
an intake request template (`Purview CoE Intake – Request`) is ready.
**Implement:** Document the workflow and template; agree change control before enforcing any governed
artifact.

## 2.8 A complete, readable inventory of governed Purview artifacts
**Description:** Read access to the artifacts the CoE will govern — **sensitivity labels and label
policies**, **DLP policies and rules**, **retention policies/labels and rules**, **auto-labeling
policies**, and (where licensed and readable) **communication-compliance policies** and **audit
retention policies** — so the register can be built from the live tenant.
**Why:** The register and drift detection are only as complete as what the account can read; some
capabilities (insider risk especially) are portal-managed with limited PowerShell and are governed by
attestation rather than enumeration.
**Verify:** `OPSCOE-Discovery.ps1` (read-only) enumerates each readable artifact type and flags which
are unlicensed or portal-only in this tenant.
**Implement:** Ensure the account holds the least-privilege read roles for each in-remit capability;
for portal-only capabilities, record them in the register by attestation with a named owner.

## 2.9 Stakeholders and the determination boundary
**Description:** Engagement with **compliance, records, privacy, security, and legal** stakeholders
(Global Requirement 5) and an explicit, recorded **determination boundary** — the CoE governs method,
naming, ownership, lifecycle, and the simulation-first gate; the stakeholders own retention schedules,
records file plans, legal holds, insider-risk/communication-compliance case actions, and regulatory
applicability.
**Why:** The CoE must not silently make regulatory/records/legal determinations; the boundary keeps the
governance operating model separate from the decisions it supports.
**Verify:** Named approvers per capability are recorded in `Purview CoE Charter – Board`; the boundary
is written into the charter.
**Implement:** Identify owners and record the boundary before the CoE takes an artifact to *enforce*.

## 2.10 A pilot artifact in simulation/test
**Description:** A single **pilot artifact** (`Purview CoE Pilot – Stage1`) — for example one DLP or
auto-labeling policy — taken through the full intake workflow in **simulation/test mode** to prove the
gate before governing the estate (Global Requirement 6).
**Why:** The intake gate must itself be validated end-to-end (Request → simulate → validate → board
approval) before it is trusted for every future change.
**Verify:** The pilot artifact is in simulation/test with recorded evidence; `OPSCOE-Validate.ps1`
passes it against the standards.
**Implement:** Choose a low-risk artifact, run it through intake in simulation, and only then treat the
gate as production-ready.

---
## Checklist
- [ ] Compliance licensing inventoried; in-remit vs out-of-scope capabilities recorded
- [ ] Compliance Administrator access confirmed; Global Admin reserved for one-time consent
- [ ] ExchangeOnlineManagement + Microsoft Graph SDK installed; `Connect-IPPSSession` / `Connect-MgGraph` succeed
- [ ] Graph read scopes consented (no write scopes needed for governance reads)
- [ ] CoE board named, separated, and mapped to built-in role groups; matrix CSV ready
- [ ] CoE standards agreed and captured as `Purview CoE Standards – Baseline`
- [ ] Intake workflow documented; change control and request template ready
- [ ] Governed-artifact inventory readable; portal-only capabilities recorded by attestation
- [ ] Stakeholders named per capability; determination boundary written into the charter
- [ ] `Purview CoE Pilot – Stage1` in simulation/test with recorded evidence
