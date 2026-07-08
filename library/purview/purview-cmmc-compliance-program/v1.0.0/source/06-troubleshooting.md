# 6. Troubleshooting Guide — Microsoft Purview CMMC Compliance Program

Use `CMMC-Discovery.ps1` for readiness, roles, and licensing; `CMMC-Validation.ps1` to confirm the
technical signals behind the NIST 800-171 actions; `CMMC-Report.ps1` for the `CMMC Score Posture –
Report`; `CMMC-Configuration.ps1` (default `-WhatIf`) to build the action-plan/control-map/evidence
artifacts; and `CMMC-Set-Scope.ps1` (default `-WhatIf`) for least-privilege role membership. **Portal
paths, template names, and cmdlets are plan-/cloud-dependent and evolve — verify against your tenant.**

## A. The CMMC / NIST 800-171 template is not available to create
| Symptom | Cause | Remediation |
|---|---|---|
| Template missing from **Assessment templates** | Premium template not entitled (needs E5 / E5 Compliance / Premium Assessment Add-On) | Verify licensing (Requirement 2.1); run `CMMC-Discovery.ps1` for the SKUs; assign the entitlement |
| Template present but "0 remaining" | Premium **assessment count** exhausted for your seats | Free an assessment or add entitlement; the *number* of premium assessments is seat-gated |
| Template named differently / absent in your cloud | GCC/GCC High feature and naming differences | Confirm the tenant cloud (Requirement 2.2) and the template's availability **in that cloud** with Microsoft |

## B. Compliance Manager role groups missing or misnamed
- `CMMC-Discovery.ps1` / `CMMC-Set-Scope.ps1` reports a role group "not found": Purview role naming
  evolves and differs by cloud. **Verify the exact role-group name** in the portal → `Settings → Roles
  & scopes → Permissions` and pass it to `-RoleGroup`.
- No members returned: confirm the signed-in admin can read role groups (Compliance Administrator /
  Global Reader) and that membership was actually assigned.

## C. Separation-of-duty flag (admin is also a contributor)
- `CMMC-Discovery.ps1` flags an account in both **Administrators** and **Contributors**. This is a
  least-privilege / Access Control concern. Either accept it explicitly with the governance owners, or
  remove the excess membership with `CMMC-Set-Scope.ps1 -RoleGroup 'Compliance Manager Administrators'
  -Remove <user> -Commit`. Keep readers/auditors and any external C3PAO reader **read-only**.

## D. Automatic testing not updating an action's status
- Confirm the **automatic testing** option is enabled: portal → **Compliance Manager → Settings**
  (`CMMC Automatic Testing – Setting`).
- Only **eligible** actions auto-test, and only when the **underlying signal** exists. Run
  `CMMC-Validation.ps1`: if it reports a **GAP** for the family (e.g. audit off, no MFA CA policy), the
  action cannot auto-pass — either remediate the control (piloted in simulation/test) or supply
  **manual** evidence.
- Signals can take time to propagate; re-check after the tenant change settles.

## E. Score looks too high or too low (false pass / false gap)
- **Too high:** an action is marked **Implemented** without proof. Cross-check with
  `CMMC-Validation.ps1`; if the control is absent, set the action back to *Not implemented* and route it
  to the **POA&M**. Never mark implemented without evidence.
- **Too low:** a genuinely-implemented control lacks status/evidence in the portal, or an action is
  **manual** and no evidence was attached. Complete the `CMMC Evidence – Register` and set the status.
- Remember: the **authoritative score/export** is the portal's Compliance Manager export — reconcile to
  it, not to a script.

## F. `CMMC-Validation.ps1` reports a gap you believe is covered
| Symptom | Cause | Remediation |
|---|---|---|
| MFA gap but MFA is on | MFA enforced via Security Defaults or per-user MFA, not a Conditional Access policy | The script reads **CA** policies; record MFA as **manual** evidence, or implement MFA via CA to make it auto-testable |
| DLP/label/retention gap but policies exist | Signed-in account lacks read rights, or wrong cloud endpoint | Ensure the compliance read roles; for GCC High pass `-ExoConnectionUri` / `-GraphEnvironment` |
| Graph section errors | Graph module/scope not consented | `Install-Module Microsoft.Graph`; consent `Policy.Read.All` / `Organization.Read.All` |

## G. `CMMC-Configuration.ps1` won't write the artifacts
- It runs `-WhatIf` by default — pass **`-Commit`** to write.
- It refuses to commit while **field problems** remain: every row needs `Requirement, Family, Action,
  Owner, TargetDate, ImplementationStatus, TestMethod (Automatic|Manual), EvidenceSource`. Fix the
  input CSV and re-run. It makes **no tenant changes** by design — assignments and evidence upload
  happen in the portal.

## H. GCC / GCC High connection issues
- Default endpoints target the Commercial cloud. For government clouds pass `-ExoConnectionUri` (the
  environment's S&C PowerShell URI) and `-GraphEnvironment` (`USGov` / `USGovDoD`) to the scripts, and
  confirm the account exists in that tenant/cloud.

## I. Diagnostics quick reference
```powershell
# Security & Compliance PowerShell (Exchange Online Management module)
Connect-IPPSSession    # add -ConnectionUri <gov URI> for GCC High
Get-RoleGroup | Where-Object Name -like 'Compliance Manager*' | Select-Object Name
Get-RoleGroupMember 'Compliance Manager Contributors' | Select-Object Name
(Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled   # AU signal
Get-DlpCompliancePolicy | Select-Object Name, Mode
Get-Label | Select-Object DisplayName, Priority
Get-RetentionCompliancePolicy | Select-Object Name, Enabled
```
The **assessment score, improvement-action status, evidence upload, and export** are managed in the
Purview **Compliance Manager** portal — the scripts assess readiness and the evidence *behind* the
actions; they do not set assessment status.

## J. What this guide never resolves (by design)
- **Whether the evidence satisfies a CMMC requirement, the target level, the NIST 800-171 DoD
  Assessment Methodology / SPRS score, and certification** — these are **compliance/security/legal/C3PAO
  determinations**. If a stakeholder asks "are we certified?", the answer comes from the assessor, not
  from Compliance Manager or these scripts.

## K. When to escalate
If licensing and cloud are confirmed, the template is available, roles are correct, the underlying
signals pass in `CMMC-Validation.ps1`, and Compliance Manager still does not reflect an action's state
after the change has propagated, collect the output of `CMMC-Discovery.ps1`, `CMMC-Validation.ps1`, and
`CMMC-Report.ps1` and open a Microsoft support case (specify your cloud — Commercial / GCC / GCC High).
