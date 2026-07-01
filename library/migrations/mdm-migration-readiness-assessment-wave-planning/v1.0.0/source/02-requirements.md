# 2. Requirements Guide — MDM Migration Readiness Assessment & Wave Planning

Verify **every** requirement before assessing. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (target tenant, target licensing, source access,
inventory, enrollment, pilot/wave structure, change control) are in `global-requirements-migrations.md`
and are assumed; the items below are specific to running this assessment and wave-planning work.

## 2.1 Read access to the current (source) MDM
**Description:** Administrative read access to the MDM you are migrating *from* (Workspace ONE,
MobileIron/Ivanti, Jamf, ManageEngine, SOTI, Configuration Manager, Intune, etc.).
**Why:** The estate is inventoried from the source console; without read access you cannot enumerate
devices, apps, profiles, compliance, or enrollment types.
**Verify:** You can sign in to the source console and open the device, app, and profile lists.
**Implement-if-missing:** Request a read-only admin role / API credential from the source platform
owner; this assessment never requires write access to the source.

## 2.2 An inventory export method (per source MDM)
**Description:** A way to export the source estate to CSV — a console export, a reporting view, or an
API pull — covering devices, OS/platform, apps, profiles, compliance, enrollment type, and owner.
**Why:** The assessment scripts read generic CSV/inventory inputs so they stay vendor-neutral; you
need a repeatable export to feed them.
**Verify:** You can produce a CSV of in-scope devices with at least device name, OS/platform, owner,
and enrollment type columns.
**Implement-if-missing:** Use the source console's export/report feature, or its API, to produce the
CSV. Map its columns to the input schema documented in the Implementation Guide.

## 2.3 (Optional) Microsoft Graph access — when the current or target MDM is Intune-adjacent
**Description:** Microsoft Graph PowerShell SDK and read scopes
(`DeviceManagementManagedDevices.Read.All`, `DeviceManagementConfiguration.Read.All`,
`DeviceManagementApps.Read.All`) where Intune is the source *or* the target.
**Why:** When Intune is in the picture, the discovery script can pull a live, structured inventory
directly instead of relying only on CSV exports.
**Verify:** `Connect-MgGraph` succeeds with the read scopes; `Get-MgDeviceManagementManagedDevice`
returns devices.
**Implement-if-missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`; consent to the read
scopes. This is optional — the assessment runs CSV-only for any non-Intune source.

## 2.4 Target-platform context (what you are migrating to)
**Description:** A documented statement of the target platform, its supported OS baselines, and its
enrollment channels for each in-scope platform.
**Why:** Readiness is scored relative to the target — a device on an OS the target no longer supports
is a readiness gap, not just an inventory line.
**Verify:** You can name the target platform and its minimum supported OS per platform in scope.
**Implement-if-missing:** Capture the target's supported-OS matrix and enrollment prerequisites (see
`global-requirements-migrations.md` G2 and G5) before scoring readiness.

## 2.5 A workstation to run the assessment scripts
**Description:** A Windows workstation with PowerShell 5.1 or PowerShell 7, able to reach the source
export and (optionally) Microsoft Graph, with write access to an output folder for the artifacts.
**Why:** The five PowerShell scripts generate the inventory, validation, report, and cohort artifacts
to disk.
**Verify:** `\$PSVersionTable.PSVersion` shows 5.1+ or 7+; you can write to the chosen output folder.
**Implement-if-missing:** Use any managed admin workstation; create an output folder (e.g.
`C:\MDMRDY`) and run the scripts from the `scripts` folder of this package.

## 2.6 Stakeholder input (owners, criticality, change windows)
**Description:** Business input on which users/departments/devices are executive, shared, kiosk, or
mission-critical, and any blackout/change-window constraints.
**Why:** Risk scoring and wave sequencing depend on business criticality and change windows that no
inventory export contains.
**Verify:** You have a named contact per department/region who can confirm criticality and windows.
**Implement-if-missing:** Run a short stakeholder intake; record criticality and constraints as input
columns so they feed the `Risk Register – MDM Migration – Assess` and the
`Wave Plan – MDM Migration – Configure`.

## 2.7 Defined scope boundary
**Description:** A written statement of what is in and out of scope (sites, platforms, ownership
types, retired devices).
**Why:** An unbounded inventory inflates risk and waves with devices that should be excluded or
decommissioned, not migrated.
**Verify:** The scope statement names included platforms/sites and explicitly excludes retired or
out-of-scope devices.
**Implement-if-missing:** Agree the scope boundary with the migration sponsor before inventory; encode
exclusions as a filter on the CSV input.

---
## Checklist
- [ ] Read access to the current (source) MDM
- [ ] An inventory export method that produces CSV (devices, OS, apps, profiles, compliance, enrollment, owner)
- [ ] (Optional) Microsoft Graph read access when Intune is source or target
- [ ] Target-platform context (supported OS baselines + enrollment channels)
- [ ] A workstation with PowerShell 5.1/7 and an output folder
- [ ] Stakeholder input on criticality and change windows
- [ ] A written scope boundary (in/out of scope)
- [ ] Category global requirements confirmed (`global-requirements-migrations.md`)
