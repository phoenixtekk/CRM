# 3. Implementation Guide — SCCM Application Migration to Intune Win32

Follow these steps **in order**. Inventory (Step 1) runs against the **Configuration Manager
console** (`Software Library` → `Application Management` → `Applications`) and module. Repackaging
(Step 3) runs on the packaging workstation. Everything else is in the **Microsoft Intune admin
center** (`https://intune.microsoft.com` → `Apps` → `Windows`).

> **Model:** Inventory every SCCM app and its constructs, repackage each into `.intunewin` with
> detection/requirement/dependency parity, assign to a pilot ring, validate install + detection,
> then expand to broad and retire the SCCM deployment. The pilot ring is the gate — a bad repackage
> never reaches production, and SCCM keeps deploying (coexistence) until Intune is proven.

## Named objects (reuse these names verbatim everywhere)
We use the `<Purpose> – <Scope> – <Stage>` convention so every object is self-describing and
searchable. For the worked example app `LOB Reader` (SCCM application `LOB Reader`, MSI deployment
type, installer `LOBReader.msi`):

| Object | Name to create |
|---|---|
| Pilot ring group | `App Migration – Pilot Devices – Ring 1` |
| Broad ring group | `App Migration – Broad Devices – Ring 2` |
| Migrated Win32 app | `LOB Reader – Win32 – Migrated` |
| Dependency Win32 app | `VC++ Redistributable x64 – Win32 – Dependency` |
| Superseded prior app | `LOB Reader – Win32 – Prior Version` |
| Detection rule identifier | `LOB Reader – Detection – MSI ProductCode` |
| Requirement rule | `LOB Reader – Requirement – x64 MinOS22H2` |

## Step 1 — Inventory the SCCM application estate
1. In the Configuration Manager console: `Software Library` → `Application Management` →
   `Applications`. Review the in-scope applications.
2. Run `SCCMAPP-Discovery.ps1` (uses `Get-CMApplication` / `Get-CMDeploymentType`) to export, per
   app: deployment types, detection methods, install/uninstall commands, requirements,
   dependencies, and supersedence, plus the content source path.
3. Review the export and confirm each app has a captured, Intune-supported detection method
   (Requirement 2.5) and a known silent install command (Requirement 2.4).

## Step 2 — Prioritize into migration waves
1. Sort the inventory into waves: start with simple MSI apps, high value, low dependency depth.
2. Defer App-V, script-heavy, or user-context deployment types to a packaging-decision wave — these
   may need rework rather than a straight repackage (see Overview limitations).
3. Record the wave order; the pilot ring migrates first within each wave.

## Step 3 — Repackage the app into a `.intunewin`
1. On the packaging workstation, confirm the Win32 Content Prep Tool is present (Requirement 2.3):
   `IntuneWinAppUtil.exe` in `C:\Tools\IntuneWinAppUtil\`.
2. Stage the clean source folder from the SCCM content source, e.g. `C:\Packaging\LOBReader\` with
   `LOBReader.msi` inside.
3. Run `IntuneWinAppUtil.exe` (interactive, or scripted) pointing at the source folder and the setup
   file, output to `C:\Packaging\Output\`.
4. Confirm `C:\Packaging\Output\LOBReader.intunewin` is produced. This is the file you upload.

## Step 4 — Create the ring groups
1. Entra → `Groups` → `New group` → `Security` → name `App Migration – Pilot Devices – Ring 1`
   (a few representative devices that today receive the SCCM deployment). `Create`.
2. Create `App Migration – Broad Devices – Ring 2` (the rest of the target scope). `Create`.
   (Or run `SCCMAPP-Set-AppRingTargeting.ps1`.)

## Step 5 — (If needed) Repackage and create the dependency app first
If the SCCM app declared a dependency, repackage and create that app **before** the main app.
1. Wrap the runtime (Step 3) and, in Intune → `Apps` → `Windows` → `Add`, create a Win32 app named
   `VC++ Redistributable x64 – Win32 – Dependency`.
2. Give it its own correct install/uninstall commands and a detection rule (e.g. its registry key).
3. You do **not** assign the dependency separately — it can auto-install via the main app's
   dependency declaration in Step 9.

## Step 6 — Create the migrated Win32 app
1. Intune → `Apps` → `Windows` → `Add`. For `App type` choose `Windows app (Win32)`. `Select`.
2. `App package file`: browse to `C:\Packaging\Output\LOBReader.intunewin`. `OK`.
3. `App information`: `Name` = `LOB Reader – Win32 – Migrated`; set `Publisher` and a short
   `Description`. `Next`.

## Step 7 — Set install/uninstall commands and behavior (carry over from SCCM)
On the `Program` tab, reuse the SCCM deployment type's programs (from the Step 1 export):
1. `Install command`: e.g. `msiexec /i "LOBReader.msi" /qn /norestart`.
2. `Uninstall command`: e.g. `msiexec /x {PRODUCT-GUID} /qn /norestart`.
3. `Install behavior`: `System` (per-device; correct for most SCCM-deployed line-of-business apps).
4. `Device restart behavior`: `No specific action` (the `/norestart` switch handles reboots).
5. `Return codes`: keep the defaults (`0`, `1707` success; `3010` soft reboot; `1641` hard reboot;
   `1618` retry) unless the vendor documents others. `Next`.

## Step 8 — Author requirement rules to match SCCM
On the `Requirements` tab, mirror the SCCM requirement rules from the Step 1 export:
1. `Operating system architecture`: e.g. `64-bit`.
2. `Minimum operating system`: your floor, e.g. `Windows 11 22H2`.
3. `Add` any custom requirement only if SCCM had one, named
   `LOB Reader – Requirement – x64 MinOS22H2` (a file, registry, or script rule). `Next`.

## Step 9 — Author detection rules to match SCCM (parity)
On the `Detection rules` tab, choose `Manually configure detection rules` (more reliable than auto),
then `Add` the rule captured in Requirement 2.5, identified as `LOB Reader – Detection – MSI
ProductCode`:
- `Rule type: MSI` → enter the SCCM detection method's `MSI product code` `{PRODUCT-GUID}` (best for
  MSIs); optionally check the product version.
- *Alternative (EXE apps)* — `Rule type: File` → path `C:\Program Files\LOB\Reader\`, file
  `LOBReader.exe`, `Detection method: version`, operator `greater than or equal to`, value the SCCM
  version.
- *Alternative* — `Rule type: Registry` → the app's uninstall key + a `DisplayVersion` check.
- *Alternative (script detection in SCCM)* — `Rule type: Use a custom detection script` → upload the
  ported detection script.

Use **exactly one** authoritative detection rule type per app — the same logic SCCM used. `Next`.

## Step 10 — Declare dependencies and supersedence to match SCCM
1. `Dependencies` tab → `Add` → select `VC++ Redistributable x64 – Win32 – Dependency` → set
   `Automatically install` = `Yes` so it installs first if missing (matches the SCCM dependency).
   `Next`.
2. `Supersedence` tab (when the SCCM app superseded an older one) → `Add` → select the prior app
   `LOB Reader – Win32 – Prior Version` → choose `Uninstall previous version = Yes` (clean replace)
   or `No` (in-place upgrade), matching the SCCM supersedence behavior. `Next`.

## Step 11 — Assign to the pilot ring (start coexistence)
1. `Assignments` tab → under `Required` → `Add group` → select
   `App Migration – Pilot Devices – Ring 1`. (Use `Available for enrolled devices` instead if the
   SCCM deployment was Available/optional via Software Center.)
2. Do **not** assign the broad ring yet — the pilot is the gate. `Next` → `Review + create` →
   `Create`.
3. **Coexistence:** leave the SCCM deployment in place for these devices for now — SCCM continues to
   deploy until the Intune app is validated on the same pilot devices.

## Step 12 — Apply and validate on the pilot (per-app gate)
1. On a pilot device, sync policy (`Settings` → `Accounts` → `Access work or school` → `Info` →
   `Sync`).
2. Run `SCCMAPP-Validation.ps1` to confirm the app installed and the Intune detection rule matches
   what SCCM detected (install/detection parity). Complete the **Testing Guide**.
3. Run `SCCMAPP-Report.ps1` to confirm Intune reports `Installed` for the pilot devices.
4. **Gate:** the app passes only when install + detection parity holds on the pilot. If it fails,
   fix the package and re-validate; the SCCM deployment (still live) means users never lose the app.

## Step 13 — Retire the SCCM deployment for the pilot, then expand
1. Once the pilot passes, in the Configuration Manager console remove/disable the SCCM `Deployment`
   for that app to the pilot devices (coexistence → cutover for Ring 1).
2. In Intune, edit the app's `Assignments` → under `Required` → `Add group` →
   `App Migration – Broad Devices – Ring 2`. `Save`.
3. Validate the broad ring, then retire the SCCM deployment for the broad scope.
4. Re-run `SCCMAPP-Report.ps1` each cycle for repackage coverage + deployment success, and chase any
   `Failed` devices with `SCCMAPP-Remediation.ps1` (default `-WhatIf`).

---
### Order of operations
`Inventory SCCM apps → prioritize waves → repackage .intunewin → ring groups → dependency app →
migrated app → install/uninstall commands → requirements → detection → dependencies + supersedence →
assign pilot (coexistence) → validate parity → retire SCCM (pilot) + expand broad → retire SCCM (broad)`
