# 3. Implementation Guide — Intune Win32 Application Packaging & Deployment

Follow these steps **in order**. Packaging (Step 1) happens on a packaging workstation; everything
else is in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** Wrap the source, create the Win32 app with correct commands, author detection and
> requirement rules, model dependencies and supersedence, assign to a **pilot** ring, validate, then
> expand to **broad**. The pilot ring is the gate — a bad build never reaches production.

## Named objects (reuse these names verbatim everywhere)
We use the `<Purpose> – <Scope> – <Stage>` naming convention so every object is self-describing and
searchable. For the worked example app `Contoso LOB Suite` (installer `ContosoLOB.msi`):

| Object | Name to create |
|---|---|
| Pilot ring group | `App Deployment – Pilot Devices – Ring 1` |
| Broad ring group | `App Deployment – Broad Devices – Ring 2` |
| Main Win32 app | `Contoso LOB Suite – Win32 – v4.2.0` |
| Dependency Win32 app | `VC++ Redistributable x64 – Win32 – Dependency` |
| Superseded prior app | `Contoso LOB Suite – Win32 – v4.1.0` |
| Detection rule identifier | `Contoso LOB Suite – Detection – MSI ProductCode` |
| Requirement rule | `Contoso LOB Suite – Requirement – x64 MinOS22H2` |

## Step 1 — Wrap the source into a `.intunewin`
1. On the packaging workstation, confirm the **Win32 Content Prep Tool** is present (see Requirement
   2.3). Place `IntuneWinAppUtil.exe` in `C:\Tools\IntuneWinAppUtil\`.
2. Stage the clean source folder `C:\Packaging\ContosoLOB\` with `ContosoLOB.msi` inside.
3. Run the helper: `WIN32-New-IntuneWinPackage.ps1 -SourceFolder C:\Packaging\ContosoLOB -SetupFile ContosoLOB.msi -OutputFolder C:\Packaging\Output`.
4. Confirm `C:\Packaging\Output\ContosoLOB.intunewin` is produced. This is the file you upload.

## Step 2 — Create the ring groups
1. Entra -> **Groups -> New group** -> **Security** -> name `App Deployment – Pilot Devices – Ring 1`
   (a few representative devices). **Create**. (Or run `WIN32-Set-RingTargeting.ps1`.)
2. Create `App Deployment – Broad Devices – Ring 2` (the rest of the fleet). **Create**.

## Step 3 — (If needed) Package and create the dependency app first
If the app needs a runtime, package and create it **before** the main app so it can be referenced.
1. Wrap the runtime (Step 1) and create a Win32 app named `VC++ Redistributable x64 – Win32 – Dependency`.
2. Give it its own correct install/uninstall commands and a detection rule (e.g. its registry key).
3. You do **not** have to assign the dependency separately — it can be auto-installed via the main
   app's dependency declaration in Step 7.

## Step 4 — Create the main Win32 app
1. Intune -> **Apps -> Windows -> Add**. For **App type** choose **Windows app (Win32)**. **Select**.
2. **App package file:** browse to `C:\Packaging\Output\ContosoLOB.intunewin`. **OK**.
3. **App information:** **Name** = `Contoso LOB Suite – Win32 – v4.2.0`; set **Publisher** and a short
   **Description**. **Next**.

## Step 5 — Set install/uninstall commands and behavior
On the **Program** tab:
1. **Install command:** `msiexec /i "ContosoLOB.msi" /qn /norestart`
2. **Uninstall command:** `msiexec /x {PRODUCT-GUID} /qn /norestart`
3. **Install behavior:** **System** (per-device; correct for most line-of-business apps).
4. **Device restart behavior:** **No specific action** (the `/norestart` switch handles reboots).
5. **Return codes:** leave the defaults (`0` = success, `1707` = success, `3010` = soft reboot,
   `1641` = hard reboot, `1618` = retry) unless the vendor documents others. **Next**.

## Step 6 — Author requirement rules
On the **Requirements** tab:
1. **Operating system architecture:** **64-bit**.
2. **Minimum operating system:** select your floor (e.g. **Windows 11 22H2**).
3. **Add** any custom requirement only if needed, named `Contoso LOB Suite – Requirement – x64 MinOS22H2`
   (a file, registry, or script rule). **Next**.

## Step 7 — Author detection rules
On the **Detection rules** tab, choose **Manually configure detection rules** (more reliable than
auto), then **Add** the rule you captured in Requirement 2.6, identified as
`Contoso LOB Suite – Detection – MSI ProductCode`:
- **Rule type: MSI** -> enter the **MSI product code** `{PRODUCT-GUID}` (best for MSIs); optionally
  check the product version.
- *Alternative (EXE apps)* — **Rule type: File** -> path `C:\Program Files\Contoso\LOB\`, file
  `ContosoLOB.exe`, **Detection method: version**, operator **greater than or equal to**, value `4.2.0`.
- *Alternative* — **Rule type: Registry** -> the app's uninstall key + a `DisplayVersion` value check.

Use **exactly one** authoritative detection rule type per app. **Next**.

## Step 8 — Declare dependencies and supersedence
1. **Dependencies** tab -> **Add** -> select `VC++ Redistributable x64 – Win32 – Dependency` ->
   set **Automatically install** = **Yes** so it installs first if missing. **Next**.
2. **Supersedence** tab (when replacing an older version) -> **Add** -> select the prior app
   `Contoso LOB Suite – Win32 – v4.1.0` -> choose **Uninstall previous version = Yes** (clean
   replace) or **No** (in-place upgrade), per the installer's behavior. **Next**.

## Step 9 — Assign to the pilot ring
1. **Assignments** tab -> under **Required** -> **Add group** -> select
   `App Deployment – Pilot Devices – Ring 1`. (Use **Available for enrolled devices** instead if the
   app should be optional via Company Portal.)
2. Do **not** assign the broad ring yet — the pilot is the gate. **Next -> Review + create -> Create**.

## Step 10 — Apply and validate on a pilot device
1. On a pilot device, sync policy (**Settings -> Accounts -> Access work or school -> Info -> Sync**).
2. Run `WIN32-Validation.ps1 -DetectionType MSI -ProductCode {PRODUCT-GUID}` to confirm the install
   and that the detection rule matches. Complete the **Testing Guide**.
3. Run `WIN32-Report.ps1` to confirm Intune reports **Installed** for the pilot devices.

## Step 11 — Expand to the broad ring
1. Only after the pilot passes the Testing Guide gate, edit the app's **Assignments** -> under
   **Required** -> **Add group** -> `App Deployment – Broad Devices – Ring 2`. **Save**.
2. Re-run `WIN32-Report.ps1` over the next cycle and chase any **Failed** devices with
   `WIN32-Remediation.ps1` (default `-WhatIf`).

---
### Order of operations
`Wrap .intunewin -> Ring groups -> Dependency app -> Main app -> Install/uninstall commands ->
Requirements -> Detection -> Dependencies + supersedence -> Assign pilot -> Validate -> Expand broad`
