# 2. Requirements Guide — Workspace ONE to Intune Application Rebuild & Repackaging

Verify every requirement before rebuilding any app. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites (target tenant, licensing, source access,
inventory, enrollment, pilot group, change control) are in `global-requirements-migrations.md` and
are assumed — the items below are specific to the application rebuild.

## 2.1 Intune app-management admin rights
Description: An admin who can create and assign apps in Intune (Intune Administrator, or a custom
role with Mobile apps read/create/assign).
Why: Every rebuild action — adding apps, authoring detection, assigning groups — requires app
write rights in the target.
Verify: `https://intune.microsoft.com` to Apps to All apps loads and Add is available.
Implement: Assign Intune Administrator or a custom role granting Mobile apps permissions.

## 2.2 Source app inventory export from Workspace ONE
Description: An export of the in-scope Workspace ONE apps with, per app: name, type, version,
install/uninstall logic, detection criteria, requirements, assignment groups and intent, and any
app-configuration payload.
Why: You cannot rebuild what you have not inventoried; this export is the source of truth the rebuild
maps against.
Verify: You hold a current source-app export (CSV/JSON) covering every in-scope app.
Implement: Produce the export from the Workspace ONE console / API. The exact source-console export
procedure is deferred to VMware documentation; run `WS1APP-Discovery.ps1` afterward to compare what
already exists in Intune against this list.

## 2.3 Windows Win32 Content Prep Tool (for internal Win32 apps)
Description: The Microsoft Win32 Content Prep Tool (`IntuneWinAppUtil.exe`) on a packaging
workstation, to wrap internal Windows installers into `.intunewin`.
Why: Internal EXE/MSI apps must be repackaged to `.intunewin` before Intune can deploy them.
Verify: `IntuneWinAppUtil.exe` is present (e.g. `C:\Tools\IntuneWinAppUtil\`).
Implement: Download the Win32 Content Prep Tool from Microsoft and place it on the packaging
workstation. Not needed for store or managed mobile apps.

## 2.4 Original installer media for internal Win32 apps
Description: The clean source installer (EXE/MSI) and any silent-install switches for each internal
Win32 app being rebuilt.
Why: Repackaging to `.intunewin` requires the original media and the silent install/uninstall
commands; the source platform stored a copy, not the build recipe.
Verify: For each internal app, you have the installer file and its documented silent commands.
Implement: Re-obtain the installer and silent switches from the vendor or your software repository.

## 2.5 Per-platform app channels (store/mobile)
Description: The Intune connections for the platforms in scope — Microsoft Store integration for new
Store apps, the Apple VPP/ABM and APNs plumbing for iOS apps, and managed Google Play for Android.
Why: Store and managed mobile apps are referenced from these channels, not repackaged; the channel
must be live before those apps can be added.
Verify: In Intune, Tenant administration to Connectors and tokens shows the relevant connector/token
Active for each platform in scope (also covered by global requirement G5).
Implement: Configure the Apple VPP/ABM token, APNs certificate, and managed Google Play connection
per the platforms you are rebuilding.

## 2.6 Captured detection criteria per Win32 app
Description: For each internal Win32 app, the authoritative detection signal — MSI product code, an
installed file path and version, or a registry uninstall key plus `DisplayVersion`.
Why: Intune detection must reflect what the installer actually leaves on disk, not the source
platform's detection record; a wrong rule causes endless reinstall loops or false "installed".
Verify: For each app you can state exactly one authoritative detection rule (and its value).
Implement: Capture the MSI product code (`Get-Package`), the installed EXE path/version, or the
uninstall registry key on a reference machine before building the app.

## 2.7 Assignment mapping (source groups to Entra groups)
Description: A mapping from each Workspace ONE assignment (smart group) to a Microsoft Entra security
group, with the intent (required, available, or uninstall) recorded per app.
Why: Assignment parity is what guarantees the same users/devices receive the same app after cutover;
without the map you cannot rebuild the deployment workflow.
Verify: Each in-scope app has a target Entra group and intent recorded in the inventory.
Implement: Create or identify the Entra groups (use `WS1APP-Set-AppAssignmentTargeting.ps1` to build
the ring groups) and record the source-to-target group mapping per app.

## 2.8 A pilot device set and a pilot Entra group
Description: A small set of representative enrolled devices per platform and an Entra pilot group, to
validate each rebuilt app before fleet assignment.
Why: Every app passes the validation gate on a pilot before it reaches the broad ring.
Verify: Entra to Groups shows the pilot group; pilot devices are enrolled in Intune.
Implement: Create the pilot group (also global requirement G6) and enroll representative devices.

---
## Checklist
- [ ] Intune app-management admin rights
- [ ] Source app inventory export from Workspace ONE — `WS1APP-Discovery.ps1`
- [ ] Win32 Content Prep Tool on a packaging workstation
- [ ] Original installer media + silent commands for internal Win32 apps
- [ ] Per-platform app channels (Store / Apple VPP-ABM-APNs / managed Google Play) Active
- [ ] Captured detection criteria per Win32 app
- [ ] Assignment mapping (source groups to Entra groups) with intent
- [ ] Pilot device set and pilot Entra group
