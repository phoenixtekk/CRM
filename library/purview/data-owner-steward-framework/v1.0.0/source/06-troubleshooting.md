# 6. Troubleshooting Guide — Data-Owner & Steward Framework (Microsoft Purview)

Field issues and how to resolve them, in the order you are likely to hit them. Every check here is safe
(read-only or a `-WhatIf` preview).

## A capability or surface is missing from the Purview portal
**Symptom:** A surface you expected to assign ownership for (records management, Audit Premium, Unified
Catalog governance domains) does not appear, or shows "upgrade required."
**Cause:** It is not licensed on the current plan — Purview is heavily plan-gated (E5 / E5 Compliance; the
Unified Catalog / Data Governance side is consumption-billed via an Azure subscription; some features are
in preview).
**Fix:** Confirm the SKU in `Billing → Licenses` and the linked Azure subscription for Data Governance.
Record the surface as **out-of-scope for ownership assignment for now** rather than forcing it. Verify
availability against your own tenant and plan — the capability set evolves.

## `Connect-IPPSSession` fails or cmdlets are "not recognized"
**Symptom:** Connection errors, repeated auth prompts, or `Get-Label` / `Get-DlpCompliancePolicy` not
found.
**Cause:** Missing/old ExchangeOnlineManagement module, or a basic-auth/legacy sign-in.
**Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force`; use a modern-auth/MFA admin
account; run `Connect-IPPSSession` (Security & Compliance PowerShell) — the label/DLP/retention cmdlets
live there, not in plain Exchange Online. Close and reopen PowerShell if a stale session is cached.

## `DGSTEWARD-Assess-Ownership.ps1` shows everything as "Unowned"
**Symptom:** The inventory runs but every control reports no Owner/Steward.
**Cause:** Ownership has not been applied yet, or it was recorded somewhere other than the object comment
tag the scripts read (`Owner=…; Steward=…`).
**Fix:** This is expected before Step 3. Author the assignment matrix and run
`DGSTEWARD-Set-Stewardship.ps1` (dry-run, then `-Commit` on the pilot). The framework's convention is to
store owner/steward in the object's **comment/metadata**; if your organization records ownership elsewhere
(a CMDB, a separate register), keep the tag in sync so the scripts can evidence coverage.

## The governance-domain rows are skipped
**Symptom:** `DGSTEWARD-Assess-Ownership.ps1` reports governance domains skipped.
**Cause:** No `-DataGovernanceUri` was supplied, or the Unified Catalog data-plane API was not reachable —
the Data Governance experience is evolving and partly in preview, and its API version/path is **not
assumed** by the scripts.
**Fix:** Assign and verify governance-domain **owners/stewards in the Purview portal** (Unified Catalog →
the domain → its roles — verify the path in your tenant). Only supply `-DataGovernanceUri` if you have
confirmed the current data-plane endpoint for your tenant; the script never invents it.

## `DGSTEWARD-Set-Stewardship.ps1` "changed nothing"
**Symptom:** You ran the assignment script and no control was updated.
**Cause:** This is by design — **`-WhatIf` is the default**. Without `-Commit` the script only previews and
prints the reverse command for each intended change.
**Fix:** Review the preview, confirm it matches `Data-Owner/Steward RACI – Design`, then re-run with
`-Commit` — scoped to `Stewardship Pilot Domain – Stage1` first, then expand.

## A role group named in the matrix "does not exist"
**Symptom:** `DGSTEWARD-Set-Stewardship.ps1` warns a role group was not found and skips the member add.
**Cause:** The built-in role-group name differs in your tenant, the Purview portal has moved that role into
the unified Purview RBAC model, or the role belongs to a capability not licensed.
**Fix:** Verify the exact name in Purview portal → `Settings → Roles & scopes → Role groups` (verify path)
and correct the matrix. Do not assume a name — the portal is evolving. The tag write still succeeds; only
the optional role-group add is skipped.

## `Set-Label` / `Set-DlpCompliancePolicy` reports access denied on `-Commit`
**Symptom:** The commit errors when writing the ownership tag to a control.
**Cause:** The account lacks the least-privilege role to edit that object (e.g. Information Protection Admin
for labels, Compliance Administrator for DLP/retention).
**Fix:** Run the commit as an account in the correct built-in role group (Requirement 2.3). Editing a
control's comment is a low-impact metadata change, but it still requires the managing role.

## Named owners/stewards don't resolve in the accountability report
**Symptom:** `DGSTEWARD-Report-Accountability.ps1 -ResolveIdentities` flags `OwnerResolves = False`.
**Cause:** The name is a typo, a display-name that doesn't match the directory, or the person has left —
or the Graph read scopes (`User.Read.All`, `Group.Read.All`) weren't consented.
**Fix:** Prefer **UPNs or security-group names** in the matrix over free-text display names; consent the
read scopes at `Connect-MgGraph` (admin consent once in Entra → Enterprise applications if required);
re-assign any control whose owner/steward has departed. A stale assignment is exactly the gap this report
exists to surface.

## Cadence check shows everything "NEVER-REVIEWED"
**Symptom:** `DGSTEWARD-Check-Cadence.ps1` reports no review dates.
**Cause:** The `Reviewed=`/`ReviewBy=` dates were never written — assignments were made without recording a
review date.
**Fix:** When you assign ownership, include `Reviewed` and `ReviewBy` in the matrix so the tag carries
them; re-run `DGSTEWARD-Set-Stewardship.ps1 -Commit`. Going forward, each re-certification updates
`Reviewed=` (and the script derives `ReviewBy = Reviewed + CadenceDays` if you don't set it explicitly).

## "Who is allowed to hold the Insider Risk / eDiscovery role?"
**Symptom:** Uncertainty over assigning a sensitive role in the RACI.
**Cause:** These roles see sensitive employee content; membership is an HR/privacy/legal **determination**,
not a technical default.
**Fix:** Leave the sensitive-role rows to the HR/privacy/legal-approved list; keep them named, minimal, and
**separate** from general stewardship. The framework implements the assignment they approve — it does not
decide who may hold the role.

## The framework "passed" but ownership drifted a quarter later
**Symptom:** Coverage was 100% at rollout; now controls are unowned or overdue again.
**Cause:** The **review cadence** isn't running or has no owner — a framework without a cadence decays.
**Fix:** Schedule `DGSTEWARD-Check-Cadence.ps1` on the agreed interval, give the cadence a named steward to
run it and a Data Owner accountable for it running, and treat the overdue list as work, not information.
This is the whole point of the cadence deliverable.
