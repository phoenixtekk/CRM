# Deliverables Summary

## Documentation

| Document | What it covers |
|----------|----------------|
| **01 — Solution Overview** | What Enrollment-Time Grouping is, the Provisioning-Client-owns-the-group mechanism, cross-platform scope (Autopilot device preparation + Apple ADE), the Windows-docs / Apple-doc-gap reality, and the Assess→Configure→Pilot→Validate→Expand model. |
| **02 — Requirements** | The full target-group specification matrix (Security / Assigned / cloud-only / not mail-enabled / not role-assignable / ideally empty), the Intune Provisioning Client owner requirement (AppId `f1346770-…`), admin-can-manage, Intune RBAC scope groups, and Graph PowerShell — each with Description / Why / Verify / Implement. References the category Global Requirements. |
| **03 — Implementation** | Ordered setup for both platforms: create the group to spec, add the Provisioning Client owner (provision the SP if absent), confirm manage + RBAC scope, wire to a Windows Autopilot device-preparation policy and an Apple ADE enrollment profile, wait for propagation, Save, validate — with pass/fail gates and rollback. |
| **05 — Testing** | Validation procedures T1–T7 with expected pass/fail: group spec, owner present, SP + RBAC scope, policy Saves, device joins the group at enrollment, assignments apply, repeatability. |
| **06 — Troubleshooting** | The symptom → root-cause decision tree keyed to the exact error strings, the Azure-log red herring, propagation delay, SP-named-differently (AppId), SP-missing (provision), RBAC scope, unsupported group shape, and the Graph / dev-tools inspection + Microsoft-support escalation path. |
| **07 — Best Practices** | Durable practices for group design, the owner requirement, RBAC/delegation, change control, cross-platform discipline, and noise discipline. |
| **Executive Summary** | One-page outcome, approach, and why it is low-risk. |

## PowerShell (Microsoft Graph) tools

All scripts use modern-auth `Connect-MgGraph` (no stored secrets), request the **least** scopes,
and are **read-only or `-WhatIf` by default**. The fixed AppId
`f1346770-5b25-470b-88bd-d5744ab7952c` is used throughout to identify the Intune Provisioning Client
by identifier, not by its tenant-variable display name.

| Script | What it does | Safe default |
|--------|--------------|--------------|
| **`ETDG-Assess-GroupReadiness.ps1`** | Reports a target group's Type, MembershipType, `onPremisesSyncEnabled`, `mailEnabled`, `isAssignableToRole`, and member count, and whether AppId `f1346770-…` is an **Owner** — pass/fail per prerequisite (R1–R7). | Read-only |
| **`ETDG-Set-ProvisioningClientOwner.ps1`** | Adds the Intune Provisioning Client service principal (by AppId) as an **Owner** of the target group. Previews the change first; commits only with `-WhatIf:$false`. | `-WhatIf` (preview) |
| **`ETDG-Test-EnrollmentGroupPrereqs.ps1`** | Full prerequisite validation: R1–R7 on the group, confirms the SP **exists** in the tenant by AppId, and lists the admin's Intune **RBAC role assignments / scope groups** (R9). | Read-only |
| **`ETDG-Get-DiagnosticReport.ps1`** | Maps an observed error string / state to its likely root cause per the decision tree, and explicitly flags the Azure Activity Log `AuthorizationFailed` entries as an unrelated red herring. Can pull live group state to corroborate. | Read-only |
| **`ETDG-Config.ps1`** | Shared configuration/helper: the fixed AppId, artifact-name defaults, a scope/connection helper, and a one-shot health summary that stitches the readiness + prereq checks into a single scoped run. | Read-only |
