# 3. Implementation Guide — Workspace ONE to Intune Application Rebuild & Repackaging

Follow these steps in order. Inventory and packaging happen on a workstation; everything else is in
the Microsoft Intune admin center (`https://intune.microsoft.com`). Source-side export from
Workspace ONE is deferred to VMware documentation — this guide tells you what to obtain, then is
exact on the Intune side.

> Model: inventory the source apps, map each to an Intune type, rebuild each with correct detection
> and requirements, recreate the assignment workflow, then pilot, validate per app, and expand. The
> per-app validation gate is the rule: no app reaches the broad ring until it installs and is
> detected on a pilot device.

## Named objects (reuse these names verbatim everywhere)
Every object follows `<Purpose> – <Scope> – <Stage>` so it is self-describing and searchable. The
worked example below rebuilds an internal Win32 line-of-business app `Acme Field Suite` (installer
`AcmeField.msi`, version 4.2.0), a public Windows store app, and an iOS store app.

| Object | Name to create |
|---|---|
| Pilot ring group (Windows) | `App Rebuild – Pilot Devices – Ring 1` |
| Broad ring group (Windows) | `App Rebuild – Broad Devices – Ring 2` |
| Pilot ring group (mobile users) | `App Rebuild – Pilot Users – Ring 1` |
| Broad ring group (mobile users) | `App Rebuild – Broad Users – Ring 2` |
| Rebuilt main Win32 app | `Acme Field Suite – Win32 – v4.2.0` |
| Dependency Win32 app | `VC++ Redistributable x64 – Win32 – Dependency` |
| Superseded prior rebuilt app | `Acme Field Suite – Win32 – v4.1.0` |
| Detection rule identifier | `Acme Field Suite – Detection – MSI ProductCode` |
| Requirement rule | `Acme Field Suite – Requirement – x64 MinOS22H2` |
| Rebuilt Store app | `Company Reader – Store – Public` |
| Rebuilt iOS store app | `Company Reader – iOS – Public` |
| App configuration policy | `Acme Field Suite – AppConfig – Managed` |

## Step 1 — Inventory and map the source app estate (Assess)
1. Obtain the Workspace ONE source-app export (Requirement 2.2). The source-console export procedure
   is deferred to VMware documentation.
2. Run `WS1APP-Discovery.ps1` to enumerate what already exists in Intune (`mobileApps`) and produce
   a source-vs-target gap list — apps still to rebuild, by type.
3. For each app, record its Intune target type from the mapping table in the Solution Overview, plus
   its detection criterion (Requirement 2.6) and assignment mapping (Requirement 2.7).
4. Prioritize: critical line-of-business apps and the most-assigned apps first; one-off or
   low-criticality apps last.

## Step 2 — Build the assignment ring groups (Configure)
1. Entra to Groups to New group to Security to `App Rebuild – Pilot Devices – Ring 1` (a few
   representative Windows devices). Create. (Or run `WS1APP-Set-AppAssignmentTargeting.ps1`.)
2. Create `App Rebuild – Broad Devices – Ring 2` (the rest of the Windows fleet).
3. For mobile, create `App Rebuild – Pilot Users – Ring 1` and `App Rebuild – Broad Users – Ring 2`
   (mobile apps are commonly user-targeted). Create.

## Step 3 — Rebuild an internal Win32 app — wrap the source
1. On the packaging workstation, confirm the Win32 Content Prep Tool is present (Requirement 2.3) at
   `C:\Tools\IntuneWinAppUtil\`.
2. Stage the clean source folder `C:\Packaging\AcmeField\` with `AcmeField.msi` inside (Requirement
   2.4).
3. Wrap it: `IntuneWinAppUtil.exe -c C:\Packaging\AcmeField -s AcmeField.msi -o C:\Packaging\Output`.
4. Confirm `C:\Packaging\Output\AcmeField.intunewin` is produced — this is the file you upload.

## Step 4 — (If needed) Rebuild the dependency app first
If the app needs a runtime, rebuild and create it before the main app so it can be referenced.
1. Wrap the runtime (Step 3) and create a Win32 app named `VC++ Redistributable x64 – Win32 –
   Dependency` with its own install/uninstall commands and detection rule (its registry key).
2. You do not assign the dependency separately — it auto-installs via the main app's dependency
   declaration in Step 8.

## Step 5 — Create the rebuilt main Win32 app in Intune
1. Intune to Apps to Windows to Add. For App type choose Windows app (Win32). Select.
2. App package file: browse to `C:\Packaging\Output\AcmeField.intunewin`. OK.
3. App information: Name = `Acme Field Suite – Win32 – v4.2.0`; set Publisher and a short
   Description. Next.

## Step 6 — Set install/uninstall commands and behavior
On the Program tab, recreate the source app's silent logic (Requirement 2.4):
1. Install command: `msiexec /i "AcmeField.msi" /qn /norestart`
2. Uninstall command: `msiexec /x {PRODUCT-GUID} /qn /norestart`
3. Install behavior: System (per-device; correct for most line-of-business apps).
4. Device restart behavior: No specific action (the `/norestart` switch handles reboots).
5. Return codes: leave the defaults (`0` and `1707` success, `3010` soft reboot, `1641` hard reboot,
   `1618` retry) unless the vendor documents others. Next.

## Step 7 — Author requirement and detection rules (parity, not copy)
On the Requirements tab:
1. Operating system architecture: 64-bit.
2. Minimum operating system: your floor (e.g. Windows 11 22H2).
3. Add a custom requirement only if needed, named `Acme Field Suite – Requirement – x64 MinOS22H2`.
   Next.

On the Detection rules tab, choose Manually configure detection rules (more reliable than auto),
then Add the rule you captured in Requirement 2.6, identified as
`Acme Field Suite – Detection – MSI ProductCode`:
- Rule type MSI to enter the MSI product code `{PRODUCT-GUID}` (best for MSIs); optionally check the
  product version.
- Alternative (EXE apps) — Rule type File to path `C:\Program Files\Acme\Field\`, file
  `AcmeField.exe`, Detection method version, operator greater than or equal to, value `4.2.0`.
- Alternative — Rule type Registry to the app's uninstall key plus a `DisplayVersion` value check.

Use exactly one authoritative detection rule type per app. Next.

## Step 8 — Declare dependencies and supersedence
1. Dependencies tab to Add to select `VC++ Redistributable x64 – Win32 – Dependency` to set
   Automatically install = Yes so it installs first if missing. Next.
2. Supersedence tab (when replacing an older rebuilt version) to Add to select
   `Acme Field Suite – Win32 – v4.1.0` to choose Uninstall previous version = Yes (clean replace) or
   No (in-place upgrade), per the installer's behavior. Next.

## Step 9 — Rebuild store and managed mobile apps
These are referenced, not repackaged.
1. Public Windows app: Apps to Windows to Add to App type Microsoft Store app (new). Search the Store,
   select the exact app, name it `Company Reader – Store – Public`. Set install behavior. Next.
2. iOS store app: Apps to iOS/iPadOS to Add to App type iOS store app. Search the App Store, select
   the exact app (confirm the exact publisher and bundle ID so you pick the right one, not a
   similarly-named app), name it `Company Reader – iOS – Public`. Next. (Internal iOS apps use App
   type Line-of-business app with the `.ipa`.)
3. Android app: Apps to Android to Add to App type Managed Google Play app; approve and select the
   app in managed Google Play, then sync.

## Step 10 — Recreate app configuration
For managed apps that carried a configuration payload in the source (Requirement 2.2):
1. Apps to App configuration policies to Add to Managed devices (or Managed apps).
2. Name `Acme Field Suite – AppConfig – Managed`; target the platform and the rebuilt app; recreate
   the configuration keys and values from the source payload (values are recreated, not byte-copied).
3. Assign to the same groups as the app. Create.

## Step 11 — Recreate the assignment workflow (pilot first)
For each rebuilt app, edit Assignments and recreate the source intent — but pilot first:
1. Required: Add group to `App Rebuild – Pilot Devices – Ring 1` (Windows) or
   `App Rebuild – Pilot Users – Ring 1` (mobile). Use Available for enrolled devices instead if the
   source app was optional via a portal.
2. Uninstall: add an Uninstall assignment only where the source workflow removed the app.
3. Do not assign the broad ring yet — the pilot is the gate. Save.

## Step 12 — Validate each app on a pilot device (the gate)
1. On a pilot device, sync policy (Settings to Accounts to Access work or school to Info to Sync).
2. Run `WS1APP-Validation.ps1` (Win32: pass the detection type and value) to confirm the app
   installed and the detection rule matches.
3. Run `WS1APP-Report.ps1` to confirm Intune reports the app Installed for the pilot devices via the
   app `installSummary` and per-device `deviceStatuses`. Complete the Testing Guide.
4. An app passes the gate only when it installs cleanly and Intune detects it on the pilot. Chase any
   Failed device with `WS1APP-Remediation.ps1` (default `-WhatIf`).

## Step 13 — Expand to the broad ring and retire the source assignment
1. Only after an app passes its validation gate, edit its Assignments to Required to Add group to
   `App Rebuild – Broad Devices – Ring 2` (or `App Rebuild – Broad Users – Ring 2`). Save.
2. Re-run `WS1APP-Report.ps1` over the next cycle and chase any Failed devices.
3. Per the coexistence and rollback plan (global requirement G7), retire the Workspace ONE assignment
   for that app only after Intune deployment is confirmed healthy — avoiding a double-install during
   coexistence.

---
### Order of operations
`Inventory + map source apps -> Ring groups -> Wrap .intunewin (Win32) -> Dependency app ->
Main Win32 app -> Commands -> Requirements + detection -> Dependencies + supersedence ->
Store/mobile apps -> App configuration -> Assign pilot -> Validate per app (gate) ->
Expand broad -> Retire source assignment`
