# 2. Requirements Guide — Technical Blocker Mitigation: Defender for Cloud

Verify **every** requirement before diagnosing. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, Log Analytics workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to running the Defender for Cloud blocker diagnostics**. Objects you create are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Read-only access to the affected subscriptions and connectors
**Description:** **Security Reader** or **Reader** on the Azure subscriptions (and read access to the security connectors) in scope, plus Az PowerShell signed in to the correct tenant.
**Why:** The diagnostics read plan state, coverage, connector status, and assessments across the subscriptions — all read-only — to pinpoint the blocker.
**Verify:** `Connect-AzAccount` succeeds; `Get-AzSecurityPricing` returns plan states for a subscription. `TBMMDC-Discovery.ps1` reports the subscriptions and roles it resolved.
**Implement-if-missing:** Assign **Security Reader / Reader** at the subscription (or management-group) scope.

## 2.2 Az PowerShell modules available
**Description:** The **Az.Accounts**, **Az.Security**, **Az.Resources**, and **Az.PolicyInsights** modules on the workstation running the diagnostics.
**Why:** Plan state, auto-provisioning, assessments, and policy compliance are exposed through Az cmdlets and ARM REST.
**Verify:** `Get-Module -ListAvailable Az.Security` returns a current version; `TBMMDC-Discovery.ps1` installs Az if missing.
**Implement-if-missing:** `Install-Module Az -Scope CurrentUser` (or at least the modules above).

## 2.3 The affected scope defined
**Description:** A named subset of the subscriptions / connectors exhibiting the blocker — the ones you will re-test the fix against before resuming. Name it `MDC Blocker Triage – Affected Scope – Diagnose`.
**Why:** Fixes are validated on the affected scope first (per `global-requirements-defender.md` G6) before touching the whole estate.
**Verify:** The list of affected subscription IDs / connector names exists; `TBMMDC-Validate.ps1` checks their state.
**Implement-if-missing:** Document the affected subscriptions/connectors as `MDC Blocker Triage – Affected Scope – Diagnose`.

## 2.4 Log Analytics workspace reachable (where used)
**Description:** The **Log Analytics workspace** Defender for Cloud is configured to use (for agent-based data / continuous export), reachable and access-controlled.
**Why:** Coverage gaps often trace to a workspace the agent cannot reach or is not linked to; you must be able to read the workspace/agent linkage.
**Verify:** The workspace exists and the affected machines' agents point at it; `TBMMDC-Coverage.ps1` reports agent/workspace linkage hints. (See `global-requirements-defender.md` G7.)
**Implement-if-missing:** Confirm/relink the workspace per current Defender for Cloud guidance for the fix step.

## 2.5 Multicloud connector onboarding artifacts known (AWS/GCP)
**Description:** For AWS/GCP blockers, know how the connector was onboarded — the **CloudFormation** (AWS) or **Terraform / gcloud** (GCP) role/permissions the connector uses.
**Why:** Connector failures are almost always a role/permission problem; you must know the onboarding method to diagnose and re-run it.
**Verify:** `TBMMDC-Discovery.ps1` lists security connectors and their state; you can view the AWS role / GCP service account used. *Verify current multicloud onboarding requirements.*
**Implement-if-missing:** Locate the connector onboarding artifacts (or plan to re-run onboarding) with whoever owns the AWS/GCP account.

## 2.6 A place to store the diagnostic output and support bundle
**Description:** A secure location for the JSON snapshots the scripts write and for the support bundle `MDC Support Bundle – <case> – Escalate`.
**Why:** The before/after snapshots prove the blocker cleared, and the bundle is what you attach to a Microsoft support case.
**Verify:** A working folder exists with least-privilege access; `TBMMDC-Report.ps1` writes there.
**Implement-if-missing:** Create a restricted working folder; do not store subscription IDs / cloud-account identifiers in shared/unsecured locations.

---
## Checklist
- [ ] Security Reader / Reader on the affected subscriptions + Az signed in — `TBMMDC-Discovery.ps1`
- [ ] Az modules (Az.Accounts / Az.Security / Az.Resources / Az.PolicyInsights) installed
- [ ] Affected scope `MDC Blocker Triage – Affected Scope – Diagnose` documented
- [ ] Log Analytics workspace reachable / linkage known — `TBMMDC-Coverage.ps1`
- [ ] Multicloud connector onboarding artifacts known (AWS CloudFormation / GCP Terraform)
- [ ] Secure working folder for snapshots and the support bundle
