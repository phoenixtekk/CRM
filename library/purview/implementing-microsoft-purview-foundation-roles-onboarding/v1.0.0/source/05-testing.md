# 5. Testing Guide — Implementing Microsoft Purview: Foundation, Roles & Onboarding

Run after building the readiness baseline and after each configuration step. Every test is safe
(read-only or a `-WhatIf` preview). Validate on the `Purview Pilot Ring – Stage1` before treating the
tenant as production-ready.

## Test 1 — Readiness is complete and licensing is understood
**Do:** Run `PURVIMP-Assess-Readiness.ps1`; compare its SKU list against `Billing → Licenses` in the
M365 admin center.
**Expected:** The compliance SKUs match the admin center; the script correctly reports E3 vs E5 / E5
Compliance, and you can name which Purview capabilities are available vs deferred.

## Test 2 — Role matrix dry-run makes no changes
**Do:** Run `PURVIMP-Set-RoleGroups.ps1 -MatrixPath .\Purview-Role-Matrix.csv -WhatIf`; afterward run
`Get-RoleGroupMember` on an affected role group.
**Expected:** The dry-run lists the intended additions and prints the reverse (`Remove-RoleGroupMember`)
command for each; membership is unchanged — `-WhatIf` truly changed nothing.

## Test 3 — Role groups resolve least-privilege
**Do:** After `-Commit` on the pilot ring, run `PURVIMP-Assess-Readiness.ps1` (or `Get-RoleGroupMember`).
**Expected:** Each function's role group contains exactly the intended named members; no pilot admin
holds a role beyond their function; the sensitive role groups (Insider Risk Management, Communication
Compliance, eDiscovery Manager) contain only the HR/legal-approved members and are separate from general
compliance administration.

## Test 4 — Unified audit log is ingesting
**Do:** Run `PURVIMP-Enable-CoreServices.ps1`; in the Purview portal run an audit search over the last
day (`Audit → Search`, verify path).
**Expected:** `UnifiedAuditLogIngestionEnabled` reports `True` and the audit search returns recent
events. (If just enabled, allow up to ~24 hours for results to appear.)

## Test 5 — Content and Activity Explorer render for viewers
**Do:** As a member of the Content Explorer viewer role groups, open `Data classification → Content
explorer` and `→ Activity explorer` (verify path).
**Expected:** Both surfaces load; a non-viewer account cannot open them — the visibility roles gate
access correctly.

## Test 6 — Workload scope map is accurate
**Do:** Run `PURVIMP-Scope-Config.ps1`; review `Purview Workload Scope – Map`.
**Expected:** Every in-scope workload (Exchange, SharePoint, OneDrive, Teams) shows connected; endpoint
onboarding status is reported accurately (onboarded / ready / not-yet-onboarded) and any gap is recorded
as a hand-off item.

## Test 7 — Compliance Manager baseline is captured
**Do:** Run `PURVIMP-Report-ComplianceBaseline.ps1 -ComplianceScore <portal score>`; open Compliance
Manager in the portal.
**Expected:** `Purview Compliance Baseline – Report` records the portal compliance score plus the
supporting signals (Secure Score, audit status, role posture), and the portal assessment export is
stored alongside it.

## Test 8 — Separation of duties holds
**Do:** Have a pilot eDiscovery manager attempt an insider-risk admin action, and an insider-risk
analyst attempt an eDiscovery action.
**Expected:** Each is denied outside their function — the least-privilege boundaries are effective.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Foundation pass** | Tests 1–8 pass on `Purview Pilot Ring – Stage1`: readiness understood, roles least-privileged and separated, audit ingesting, Explorers rendering, scope mapped, baseline captured |
| **Expand pass** | Tests 2–3 pass again after broadening role-group membership from the pilot ring to the full named set, with audit/Explorer/baseline still healthy — ready to hand off to the capability solutions |
