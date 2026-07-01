# 2. Requirements Guide — SCCM Application Migration to Intune Win32

Verify **every** requirement before repackaging. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites (target tenant, Intune licensing, source access,
inventory, enrollment, pilot/waves, change control) are in `global-requirements-migrations.md` and
are assumed here.

## 2.1 Intune licensing and admin rights (target)
Description: An Intune-bearing license plan and the roles to create and assign Win32 apps.
Why: You cannot create `.intunewin` apps or assignments in the target without licensing and rights.
Verify: `https://intune.microsoft.com` loads; you hold Intune Administrator; go to `Apps` → `Windows`.
Implement: Assign M365 E3/E5, Business Premium, or Intune Plan 1; grant least-privilege admin roles.

## 2.2 Configuration Manager read access (source)
Description: Administrative read access to the Configuration Manager site to inventory applications.
Why: The migration begins by exporting each SCCM application's deployment types, detection methods,
requirements, dependencies, and supersedence.
Verify: The Configuration Manager console opens to `Software Library` → `Application Management` →
`Applications`; the Configuration Manager PowerShell module loads; run `SCCMAPP-Discovery.ps1`.
Implement: Obtain a Read-only Analyst (or equivalent) SCCM role and install the ConfigMgr console /
module (`Microsoft.ConfigurationManagement.PowerShell`) on the admin workstation.

## 2.3 Win32 Content Prep Tool
Description: `IntuneWinAppUtil.exe`, the Microsoft tool that wraps a source folder into `.intunewin`.
Why: Every SCCM app is repackaged into an `.intunewin` file before it can be uploaded to Intune.
Verify: `IntuneWinAppUtil.exe` is present on the packaging workstation (e.g. `C:\Tools\IntuneWinAppUtil\`).
Implement: Download the Microsoft Win32 Content Prep Tool and place it on the packaging workstation.

## 2.4 Source installers / content
Description: The original installer media (MSI/EXE + switches) for each in-scope SCCM application.
Why: The Content Prep Tool wraps the source; without clean install media you cannot repackage.
Verify: For each app, the SCCM deployment type's content location resolves and the silent install
command is known; `SCCMAPP-Discovery.ps1` reports the source path and install command.
Implement: Recover the content from the SCCM content source share (`Get-CMDeploymentType` reports the
content path) or the vendor; confirm the silent switches install cleanly on a test device.

## 2.5 Detection method captured per app
Description: The authoritative detection logic for each app (MSI product code, file+version,
registry value, or a detection script) carried over from SCCM.
Why: Intune reports Installed only when the detection rule matches; parity depends on this.
Verify: `SCCMAPP-Discovery.ps1` exports each deployment type's detection method; confirm it is a type
Intune supports (MSI / file / registry / script).
Implement: Where SCCM used a complex/script detection, port the script or convert it to an equivalent
file/registry/MSI rule; record it as the app's detection rule for Step 7 of the implementation.

## 2.6 Dependency and supersedence map
Description: The dependency chains and supersedence relationships between SCCM apps.
Why: Intune must recreate the same prerequisite auto-installs and version-replacement behavior.
Verify: `SCCMAPP-Discovery.ps1` lists each app's dependencies and supersedence; review for cycles.
Implement: Package/create dependency apps first; record which app supersedes which for Step 8.

## 2.7 Packaging workstation
Description: A clean Windows workstation to stage source, run the Content Prep Tool, and test installs.
Why: Repackaging and per-app install testing happen off the production fleet.
Verify: A Windows 10/11 workstation with the Content Prep Tool and space for source + output.
Implement: Provision the workstation; create `C:\Packaging\` (source) and `C:\Packaging\Output\`.

## 2.8 Pilot ring group and coexistence/rollback plan
Description: An Entra security group for the app pilot ring, and a documented coexistence + rollback
approach (SCCM keeps deploying until Intune is validated; revert by re-enabling the SCCM deployment).
Why: Every app is validated on a pilot before broad cutover; cutover must be reversible.
Verify: Entra → `Groups` shows the pilot ring group; the coexistence/rollback plan is written.
Implement: Create the ring groups (or run `SCCMAPP-Set-AppRingTargeting.ps1`); document rollback per
global requirement G7.

---
## Checklist
- [ ] Intune licensing + Intune Administrator — `Apps` → `Windows` reachable
- [ ] Configuration Manager read access + module — `SCCMAPP-Discovery.ps1`
- [ ] Win32 Content Prep Tool present
- [ ] Source installers / content recovered per app
- [ ] Detection method captured per app (Intune-supported type)
- [ ] Dependency + supersedence map reviewed
- [ ] Packaging workstation staged
- [ ] Pilot ring group created; coexistence + rollback plan written
