# 2. Requirements Guide — Microsoft Purview Tenant Assessment

Verify **every** requirement before starting the assessment. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C
PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot &
change control) are in `global-requirements-purview.md` — this guide adds the assessment-specific
detail.

> **Licensing/tenant boundary.** Which Purview capabilities you can assess depends on what your tenant
> has **enabled and licensed**. Advanced capabilities (auto-labeling, advanced DLP, Insider Risk,
> Communication Compliance, Audit Premium, DSPM/DSPM for AI, parts of the Unified Catalog) require
> **Microsoft 365 E5** or the **E5 Compliance** add-on, and some are in **preview**. Where this guide
> flags "verify your licensing/tenant," confirm the entitlement before relying on a reading. A
> capability that is **not licensed / not enabled** is a legitimate assessment result, not a defect.

## 2.1 Compliance licensing across the capabilities in scope
**Description:** The Microsoft 365 compliance licensing for the capabilities you want assessed — **E3** covers baseline labels/DLP/retention/Audit Standard; **E5 / E5 Compliance** unlocks auto-labeling, advanced DLP, Insider Risk, Communication Compliance, Audit Premium, DSPM, and eDiscovery Premium.
**Why:** The assessment can only read a capability that is licensed and enabled; unlicensed capabilities are reported as such, not scored (GR §1).
**Verify:** M365 admin center → `Billing → Licenses`; and run `PURVASSESS-Scope.ps1`, which reads `subscribedSkus`/service plans via Graph and reports which Purview-relevant plans are present.
**Implement:** No purchase is required to *assess* — the assessment simply records what's licensed. Findings will recommend where a missing license blocks a needed capability; that decision is the customer's.

## 2.2 Least-privilege read roles across every capability (Reader-first)
**Description:** Read access to each capability being assessed. The **Global Reader** and **Compliance Administrator** / **Compliance Data Administrator** roles cover most reads; capability-specific reader roles may be needed for **Insider Risk** (Insider Risk Management **Analysts/Investigators** or a read role), **eDiscovery** (eDiscovery **Reader/Manager**), and **Audit** (**Audit Reader**). Reserve Global Administrator for the rare enablement action only.
**Why:** Purview uses fine-grained role groups; a read the account isn't entitled to simply returns nothing or an access error — which would look like a false "gap" (GR §2).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions`; `PURVASSESS-Scope.ps1` reports which capability reads succeed and which throw a permissions error.
**Implement:** Assign the least-privilege **reader** role groups for the in-scope capabilities under change control. Prefer read roles for the assessment; the remediation step (2.5) needs write roles only for the specific quick-win capabilities.

## 2.3 Security & Compliance / Exchange Online PowerShell + Graph
**Description:** The `ExchangeOnlineManagement` module provides **Security & Compliance PowerShell** (`Connect-IPPSSession` — labels, DLP, retention, some Communication Compliance/eDiscovery cmdlets) and **Exchange Online** (`Connect-ExchangeOnline` — audit config, mailbox settings). **Microsoft.Graph** is used for licensing, users/roles, and (where available) security/compliance reads.
**Why:** The assessment tools read across all three; the right endpoint is used for each capability (GR §3). **Note:** several capabilities (Insider Risk, DSPM, Compliance Manager scoring, the Unified Catalog) are **portal-driven** and have limited or no stable PowerShell — the tools flag those for manual portal review rather than invent cmdlets.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; both `Connect-IPPSSession` and `Connect-ExchangeOnline` succeed with a modern-auth/MFA admin; `Connect-MgGraph` succeeds. `PURVASSESS-Scope.ps1` reports which endpoints are reachable.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.4 Confirmed capability inventory (what's actually enabled)
**Description:** A confirmed list of **which Purview capabilities your tenant has enabled** — not the theoretical catalog. Some may be licensed but never turned on (e.g. Insider Risk enabled but no policies, DSPM not yet activated).
**Why:** The assessment scopes to enabled capabilities; "licensed but never configured" is itself a headline finding, and the tool must distinguish *not licensed* from *licensed-but-empty* (GR §4).
**Verify:** In the Purview portal, note which solutions appear under `Solutions`; `PURVASSESS-Scope.ps1` + `PURVASSESS-Discovery.ps1` report each capability as enabled / not enabled / not licensed / portal-only.
**Implement:** No action needed to assess — the inventory is an *output*. Just ensure the roles (2.2) let the tools read each enabled capability.

## 2.5 Write roles only for the quick-win remediations (if remediating)
**Description:** If you intend to apply the safe quick-win fixes (put a DLP policy into simulation, take an auto-labeling policy to simulation, enable a disabled retention policy, enable unified audit), the account needs the **write** role for *those specific capabilities* (e.g. **Compliance Administrator** for DLP/retention/labels; **Audit Manager** / Exchange for audit ingestion) — assigned under change control.
**Why:** Remediation changes configuration; it must be least-privilege and change-controlled, and it is always **simulation/test/pilot-first** (GR §6).
**Verify:** `PURVASSESS-Remediate.ps1 -WhatIf` prints the exact cmdlet it *would* run and reports a permissions error if the write role is missing — nothing changes until `-Commit`.
**Implement:** Grant the specific write role for the capability being remediated, under an approved change window; remove it after if it was granted just for the fix.

## 2.6 Stakeholders for the findings that need a governance decision
**Description:** Named owners in **compliance, records, privacy, security, and legal** who will receive the findings that are **determinations, not technical fixes** — is a retention duration correct, does a DLP rule satisfy a regulation, should an Insider Risk policy exist, is a capability required.
**Why:** Regulatory/records/legal judgments are theirs to make (GR §5); the assessment produces the finding and evidence, the governance function decides.
**Verify:** You can name the owner for each capability's policy decisions.
**Implement:** Identify the owners before the readout so P1/P2 findings that need a decision have a destination.

## 2.7 A remediation pilot scope and change window (if remediating)
**Description:** A limited **pilot scope** (`Purview Assessment – Remediation Pilot – Stage1`) — a small set of users/policies to apply and validate any quick-win fix on before tenant-wide, plus an agreed change window (GR §6). Every Purview policy change here uses **simulation/test/disabled** mode first.
**Why:** Even "safe" fixes (moving a DLP policy's mode, enabling a retention policy) are tenant-impacting; validate small first.
**Verify:** A named pilot scope, confirmation that simulation/test mode is available for the target policy, and change approval exist.
**Implement:** Define the pilot and change window before running `PURVASSESS-Remediate.ps1 -Commit` on anything.
