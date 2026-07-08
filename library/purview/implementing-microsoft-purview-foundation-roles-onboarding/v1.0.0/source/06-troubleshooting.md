# 6. Troubleshooting Guide — Implementing Microsoft Purview: Foundation, Roles & Onboarding

Field issues and how to resolve them, in the order you are likely to hit them. Every check here is safe.

## A capability is missing from the Purview portal
**Symptom:** A capability (insider risk, communication compliance, Audit Premium, DSPM, auto-labeling)
does not appear in the left rail, or shows "upgrade required."
**Cause:** It is not licensed on the current plan — Purview is heavily plan-gated (E5 / E5 Compliance;
some previews).
**Fix:** Run `PURVIMP-Assess-Readiness.ps1` and read the capability-availability lines; confirm the SKU
in `Billing → Licenses`. Record the capability as **deferred (not licensed)** rather than trying to
enable it. Verify availability against your own tenant and plan — the script's plan mapping is
indicative.

## `Connect-IPPSSession` or `Connect-ExchangeOnline` fails
**Symptom:** Connection errors, repeated auth prompts, or "module not found."
**Cause:** Missing/old ExchangeOnlineManagement module, or basic-auth/legacy sign-in.
**Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force`; use a modern-auth/MFA admin
account. Both cmdlets ship in that one module. Close and reopen PowerShell if a stale session is cached.

## `Connect-MgGraph` succeeds but data calls return 403 / "insufficient privileges"
**Symptom:** The readiness/baseline/scope scripts connect but a Graph call is denied.
**Cause:** The delegated scope was not consented (e.g. `SecurityEvents.Read.All`,
`DeviceManagementManagedDevices.Read.All`).
**Fix:** Re-run `Connect-MgGraph` with the scopes listed in the script header and consent; if admin
consent is required, a Global Administrator approves them once in Entra → Enterprise applications. The
foundation needs **read** scopes only.

## A role group named in the matrix "does not exist"
**Symptom:** `PURVIMP-Set-RoleGroups.ps1 -WhatIf` flags `[MISSING]` for a role group.
**Cause:** The built-in role-group name differs in your tenant, or the Purview portal has transitioned
that role into the unified Purview RBAC model, or the role belongs to a capability not licensed.
**Fix:** Verify the exact name in Purview portal → `Settings → Roles & scopes → Role groups` (verify
path) and correct the matrix, or create a custom scoped group with `New-RoleGroup`. Do not assume a
name — the portal is evolving.

## Audit search returns nothing after enabling the unified audit log
**Symptom:** `UnifiedAuditLogIngestionEnabled` reports `True` but an audit search is empty.
**Cause:** Ingestion was just enabled — results can take **up to ~24 hours** to begin appearing, and
history before enablement does not exist (it cannot be back-filled).
**Fix:** Wait and re-search; confirm with `PURVIMP-Enable-CoreServices.ps1`. This is exactly why the
Requirements and Best Practices say to enable audit **early**.

## Content Explorer / Activity Explorer shows "you don't have permission"
**Symptom:** A reviewer cannot open Content or Activity Explorer.
**Cause:** They are not in the **Content Explorer Content Viewer** / **Content Explorer List Viewer**
(or the data-classification) role groups.
**Fix:** Add them with `PURVIMP-Set-RoleGroups.ps1` (dry-run then `-Commit`); confirm with
`PURVIMP-Enable-CoreServices.ps1` that the viewer role groups have members. Access is intentionally
gated — a non-viewer being denied is correct behavior, not a bug.

## `Set-AdminAuditLogConfig` reports the change didn't take / access denied
**Symptom:** `-Commit` on the core-services script errors when enabling audit.
**Cause:** The account lacks the required Exchange Online admin role for `Set-AdminAuditLogConfig`.
**Fix:** Run the one-time enablement as an account with the appropriate admin role (Global Administrator
or an Exchange role that includes the audit-config cmdlet); this is one of the few actions for which
elevated rights are reserved.

## Compliance Manager score / assessment can't be pulled by script
**Symptom:** You expected `PURVIMP-Report-ComplianceBaseline.ps1` to read the Compliance Manager score.
**Cause:** Compliance Manager assessments have **no fully GA PowerShell/Graph write surface** — they are
managed and exported from the portal.
**Fix:** Open Purview portal → Compliance Manager, read the score, export the assessment
(`Assessments → Export`), and re-run the script with `-ComplianceScore <value>`. The script captures the
supporting signals (Secure Score, audit, role posture); the portal export is the assessment record.

## Endpoint count is zero or lower than expected in the scope map
**Symptom:** `PURVIMP-Scope-Config.ps1` reports few/no managed devices.
**Cause:** Devices aren't enrolled in Intune/managed, or the `DeviceManagementManagedDevices.Read.All`
scope wasn't consented — and Purview **device onboarding** is separate from device management.
**Fix:** This is a **readiness** signal, not a blocker for the foundation. Record the endpoint gap as a
hand-off item; tenant-wide device onboarding to Purview is performed in the endpoint-DLP solution
(Purview portal → `Settings → Device onboarding`, verify path).

## A pilot admin can do more (or less) than their function
**Symptom:** Separation-of-duties test fails — e.g. an eDiscovery manager can administer insider risk.
**Cause:** The person is a member of more than one role group, or holds a broad role (Global Admin /
Compliance Administrator) that subsumes the function.
**Fix:** Re-run `PURVIMP-Assess-Readiness.ps1` / `Get-RoleGroupMember`, remove the extra membership with
the reverse command the setup helper printed, and re-test. Keep sensitive role groups minimal, named,
and separate — confirmed with HR/privacy/legal.

---
### When to stop and escalate
- A required capability is **not licensed** and the plan can't be changed → record as deferred and scope
  the program to what you have; do not attempt to force-enable it.
- A **records/retention/legal-hold or insider-risk determination** is being asked of you → escalate to
  compliance, records, privacy, or legal. This foundation provides the technical method and evidence,
  never the determination.
- A portal path in this guide **doesn't match your tenant** → the Purview portal is actively evolving;
  verify the current path in your tenant before proceeding rather than assuming the guide is wrong about
  the *step*.
