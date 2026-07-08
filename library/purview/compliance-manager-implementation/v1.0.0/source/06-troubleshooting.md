# 6. Troubleshooting Guide — Microsoft Purview Compliance Manager Implementation

Field issues and how to resolve them. **Symptom → Likely cause → Resolution.** Confirm the basics
first: correct licensing, the right Compliance Manager role, and a successful `Connect-IPPSSession` /
`Connect-MgGraph`. Portal paths, template availability, and cmdlets are plan-dependent and evolve —
**verify against your tenant.**

## Compliance Manager isn't visible, or a template can't be created
**Likely cause:** The admin lacks a Compliance Manager role, or the template is a **premium/custom**
one your plan doesn't entitle.
**Resolution:** Ensure your account is in a Compliance Manager role group (Requirement 2.2). The **Data
Protection Baseline** is available to all tenants; **premium** templates require **E5 / E5 Compliance /
Premium Assessment Add-On** and the **count** is seat-dependent (Requirement 2.1). Confirm entitlement
in the M365 admin center — **verify with Microsoft licensing, don't assume**. `CMPMGR-Discovery.ps1`
reports the SKUs it can read.

## A Compliance Manager role group is missing (`Get-RoleGroup` returns nothing)
**Likely cause:** The exact role-group name differs in your tenant, or the group isn't provisioned.
**Resolution:** Purview role naming evolves — verify the exact names in `Settings → Roles & scopes →
Permissions`. Compliance Administrator / Compliance Data Administrator / Global Administrator also grant
access. Adjust the name you pass to `CMPMGR-Set-Scope.ps1` to match your tenant.

## The same person is both an Administrator and a Contributor (separation note)
**Likely cause:** One identity added to **Compliance Manager Administrators** *and* **Contributors**.
**Resolution:** Grant the **minimum** role each person needs — administrators don't also need the
contributor role. Remove the overlap with `CMPMGR-Set-Scope.ps1` (`-WhatIf` then `-Commit`), or record
governance acceptance for a stated reason. `CMPMGR-Discovery.ps1` flags the overlap.

## `CMPMGR-Configuration.ps1` didn't write any files
**Likely cause:** It ran in the default **`-WhatIf`** mode (by design).
**Resolution:** Review the plan it printed; re-run with **`-Commit`** (and `-OutDir`) to write
`CM-Action-Plan-Pilot.csv` / `CM-Evidence-Register.csv`. Remember this tool makes **no tenant changes** —
assignments and evidence upload are done in the Purview portal from these artifacts.

## `CMPMGR-Configuration.ps1` reports validation issues
**Likely cause:** The input CSV has blank owners/dates, an unrecognized status value, or a missing
evidence source.
**Resolution:** Fix the flagged rows. `ImplementationStatus` must be one of *Not implemented /
Implemented / Alternative implementation / Planned / Out of scope*; `TestStatus` one of *Not assessed /
Passed / Failed - low|medium|high risk*; every action needs an **owner**, a valid **TargetDate**, and
an **EvidenceSource** (Requirement 2.5).

## The Compliance Score looks wrong or hasn't moved after implementing a control
**Likely cause:** The improvement action's status wasn't updated, automatic testing isn't enabled/eligible
for it, or the control was implemented in a way the signal doesn't detect.
**Resolution:** Confirm the action's **implementation** and **test** status in the portal; enable
**automatic testing** (`CM Automatic Testing – Setting`, Requirement 2.6) for eligible actions; for
others, set the status manually with evidence. Cross-check the underlying control with
`CMPMGR-Validation.ps1`. Score updates for automatic tests can take time to propagate.

## An action shows "Implemented" but the control isn't actually there (false pass)
**Likely cause:** The status was set manually without proof, or a stale automatic result.
**Resolution:** Run `CMPMGR-Validation.ps1` — if it reports the control **Absent**, correct the action's
status; never mark implemented without evidence. This is exactly the cross-check the validator exists for.

## `CMPMGR-Validation.ps1` reports a control "Absent" that you believe is configured
**Likely cause:** The admin lacks read rights to that area, the Graph scope wasn't granted, or the
control is configured in a place the check doesn't read (e.g. security defaults vs Conditional Access).
**Resolution:** Ensure the account can read DLP/retention/labels (S&C PowerShell) and that
`Connect-MgGraph -Scopes Policy.Read.All` succeeded for Conditional Access. The tool checks common
signals; some controls have alternative implementations — record those as **manual** evidence.

## `Get-Label` / `Get-DlpCompliancePolicy` / `Get-RetentionCompliancePolicy` not recognised
**Likely cause:** Not connected via `Connect-IPPSSession`, or an outdated ExchangeOnlineManagement module.
**Resolution:** `Import-Module ExchangeOnlineManagement`; `Update-Module ExchangeOnlineManagement`;
`Connect-IPPSSession` (Security & Compliance PowerShell — **not** `Connect-ExchangeOnline`).

## Automatic testing isn't updating any actions
**Likely cause:** Automatic testing is off, the actions aren't eligible for it, or the underlying signal
is absent.
**Resolution:** Enable automatic testing in **Compliance Manager → Settings**; note that only **eligible**
actions auto-test (Requirement 2.6). For ineligible actions, plan manual evidence. Verify the underlying
control exists with `CMPMGR-Validation.ps1`.

## Shared control implemented once, but a second assessment still shows it not done
**Likely cause:** The action is customer-managed and set on one assessment only, or the control isn't a
shared/mapped control across those templates.
**Resolution:** Confirm the action is a **shared** (or Microsoft-managed) control; for shared controls,
updating it in one place should reflect across mapped assessments. If it's not mapped, it must be
implemented per assessment. Control mapping is a template property — verify in the portal.

## `CMPMGR-Set-Scope.ps1 -Commit` fails to add/remove a member
**Likely cause:** The signed-in admin can't manage role-group membership, the member identity is wrong,
or the role-group name doesn't match your tenant.
**Resolution:** Use an admin permitted to manage role groups; pass the member's exact UPN/primary SMTP;
confirm the role-group name (`Get-RoleGroup`). Re-run `-WhatIf` to preview before `-Commit`.

## "Does this evidence satisfy the regulation? Are we compliant?"
**Not a tool question.** Compliance Manager produces the **score and evidence**; **whether a regulation
applies and whether the evidence satisfies it is a compliance/records/privacy/legal determination.**
Route the posture and evidence (`CM Score Posture – Report`, `CM Evidence – Register`) to those functions
for the adequacy decision — the tool provides method and proof, not the verdict.
