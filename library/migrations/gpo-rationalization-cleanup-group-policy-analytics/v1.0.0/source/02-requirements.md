# 2. Requirements Guide — GPO Rationalization & Cleanup with Group Policy Analytics

Verify **every** requirement before you begin. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites (the Entra ID tenant, Intune licensing, source
access, inventory, pilot/wave structure, change control) are in `global-requirements-migrations.md`
and are assumed here.

## 2.1 Access to export GPOs
**Description:** Administrative read access to Active Directory Group Policy and a domain-joined admin
workstation that can run the Group Policy Management Console (GPMC).
**Why:** Rationalization begins by inventorying and exporting every GPO; the export is both the Group
Policy analytics input and your retained record.
**Verify:** Open GPMC; you can see the domain's GPOs and right-click to back up/export a GPO.
**Implement-if-missing:** Install RSAT Group Policy Management Tools
(`Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0`) and obtain a
Group Policy read/backup role from the AD owner.

## 2.2 The GroupPolicy PowerShell module
**Description:** The `GroupPolicy` module (`Get-GPO`, `Get-GPOReport`) on the admin workstation.
**Why:** The discovery, validation, and report scripts use it to enumerate and export GPOs
programmatically.
**Verify:** `Get-Module -ListAvailable -Name GroupPolicy` returns the module; run
`GPORAT-Discovery.ps1`.
**Implement-if-missing:** Install RSAT Group Policy Management Tools as in 2.1.

## 2.3 Intune with Group Policy analytics
**Description:** Microsoft Intune access with the Group Policy analytics report available.
**Why:** Group Policy analytics is the scoring engine — it produces each GPO's migration readiness
percentage and supported/not-supported/needs-review breakdown.
**Verify:** Sign in to `https://intune.microsoft.com` and open **Reports > Group Policy analytics**;
the **Import** action is present.
**Implement-if-missing:** Confirm Intune licensing and the Intune Administrator role per
`global-requirements-migrations.md` (G2).

## 2.4 Microsoft Graph access (for scope groups and analytics reporting)
**Description:** The `Microsoft.Graph` PowerShell module and consent for `Group.ReadWrite.All` and
`DeviceManagementConfiguration.Read.All`.
**Why:** The report and backlog scripts read Intune Group Policy migration reports and build the Entra
scope groups via Graph.
**Verify:** `Connect-MgGraph` succeeds with the scopes above; run `GPORAT-Report.ps1 -UseGraph`.
**Implement-if-missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`; have an admin grant
consent for the listed scopes.

## 2.5 A rationalization owner
**Description:** A named person (or small group) accountable for the keep/retire/consolidate/replace
decisions and for signing off retirements.
**Why:** Group Policy analytics scores coverage but cannot judge business intent; retiring a GPO is a
decision that needs an owner.
**Verify:** A named owner is recorded in the rationalization register.
**Implement-if-missing:** Assign the owner before classifying; route retirements through change
control per `global-requirements-migrations.md` (G7).

## 2.6 A change window and rollback for link changes
**Description:** A change window for unlinking/removing dead and duplicate GPOs, and the retained GPO
exports as the rollback source.
**Why:** Unlinking a GPO changes what applies to live devices; it must be reversible.
**Verify:** A change window is approved and the export folder from `GPORAT-Discovery.ps1` is retained.
**Implement-if-missing:** Schedule the window; keep the export folder as the backup before any
remediation.

---
## Checklist
- [ ] Access to export GPOs (GPMC + Group Policy read/backup role)
- [ ] GroupPolicy PowerShell module present — `GPORAT-Discovery.ps1`
- [ ] Intune with Group Policy analytics (Reports > Group Policy analytics > Import)
- [ ] Microsoft Graph access — `Group.ReadWrite.All`, `DeviceManagementConfiguration.Read.All`
- [ ] A named rationalization owner
- [ ] Change window + retained GPO export as rollback
- [ ] Pilot scope group planned (per global requirements)
