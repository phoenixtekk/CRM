# 2. Requirements Guide — Intune Win32 Application Packaging & Deployment

Verify **every** requirement before packaging or deploying. Each entry:
**Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Throughout this solution we use a **worked example app** so every rule is concrete: a generic
line-of-business installer named `Contoso LOB Suite` shipped as `ContosoLOB.msi` (with placeholder
source path `C:\Packaging\ContosoLOB\`). Replace the names and paths with your own app.

## 2.1 Licensing
**Description:** Intune (Plan 1). Win32 app deployment is a built-in Intune capability.
**Why:** Intune stores the `.intunewin`, runs the IME, and reports app install state.
**Verify:** M365 admin center -> **Billing -> Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included), or standalone Intune Plan 1.

## 2.2 Device enrollment and the Intune Management Extension
**Description:** Targeted Windows devices enrolled in Intune; the IME present and healthy.
**Why:** Win32 apps are installed only by the IME on enrolled devices.
**Verify:** Intune -> **Devices -> All devices** lists the device; run `WIN32-Validation.ps1` (checks
for the `Microsoft Intune Management Extension` service).
**Implement:** Enable automatic enrollment and enroll the device. The IME installs automatically once
a Win32 app or PowerShell script is assigned to the device.

## 2.3 The Microsoft Win32 Content Prep Tool
**Description:** `IntuneWinAppUtil.exe`, Microsoft's free tool that wraps source into `.intunewin`.
**Why:** Intune only accepts the `.intunewin` package format for Win32 apps.
**Verify:** The tool is present on your packaging workstation (run `WIN32-New-IntuneWinPackage.ps1`,
which locates or prompts for it).
**Implement:** Download it from Microsoft's official repository at
`https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool` (Releases). Place
`IntuneWinAppUtil.exe` in a known folder such as `C:\Tools\IntuneWinAppUtil\`. Do not redistribute
the tool inside this package; obtain the current version from Microsoft.

## 2.4 A clean packaging source folder
**Description:** A folder containing the installer (the **setup file**) plus everything it needs.
**Why:** The Content Prep Tool captures one source folder; missing files cause install failures.
**Verify:** Your source folder (e.g. `C:\Packaging\ContosoLOB\`) holds the installer and any
transforms/config it references, and nothing extra.
**Implement:** Stage the installer (`ContosoLOB.msi`) and dependencies into one folder; remove stray
files. Note the **setup file name** — you pass it to the Content Prep Tool.

## 2.5 Known, tested install and uninstall command lines
**Description:** The exact silent install and silent uninstall commands for the app.
**Why:** Intune runs these verbatim; an interactive or wrong command stalls or fails the deployment.
**Why these specific examples:** MSIs use `msiexec`; EXEs use a vendor-specific silent switch.
**Verify:** Run the commands manually on a clean test VM and confirm a silent, successful install and
a clean uninstall, both returning exit code `0`.
**Implement (worked example, MSI):**
- Install: `msiexec /i "ContosoLOB.msi" /qn /norestart`
- Uninstall: `msiexec /x {PRODUCT-GUID} /qn /norestart`
For an EXE installer, use the vendor's documented silent switch (commonly
`setup.exe /silent /norestart` or `/S`); confirm it in the vendor docs.

## 2.6 A reliable detection method
**Description:** A deterministic way to confirm the app is installed (MSI product code, a file with a
version, or a registry value).
**Why:** Detection drives Intune's reported state; a guess causes false Installed/Failed results.
**Verify:** After a manual install, capture the MSI **product code**, or the installed
**file + version** (e.g. `C:\Program Files\Contoso\LOB\ContosoLOB.exe`, version `4.2.0`), or the
uninstall **registry key**.
**Implement:** Choose one: MSI product code (best for MSIs), file-version rule, or registry-value
rule. Record the chosen value — you enter it as the detection rule and reuse it in
`WIN32-Validation.ps1`.

## 2.7 Requirement rule values
**Description:** The device conditions the app needs (architecture, minimum OS build, disk space).
**Why:** Requirement rules stop the app from targeting devices that cannot run it (reported
**Not applicable** rather than failed).
**Verify:** Confirm the app's supported architecture (typically **64-bit**) and minimum Windows
version from the vendor.
**Implement:** Plan an x64 architecture requirement and a minimum OS build; add a custom
file/registry/script requirement only if the app has a special prerequisite.

## 2.8 Dependencies identified (if any)
**Description:** Any runtime or component the app needs *before* it installs (e.g. a C++ redistributable).
**Why:** Out-of-order installs fail; Intune dependencies enforce install order.
**Verify:** Confirm from the vendor whether a runtime is required and whether it is already deployed
as its own Win32 app.
**Implement:** Package the prerequisite as its own Win32 app first, then declare it as a dependency
of the main app (see Implementation Step 7).

## 2.9 Source / distribution hygiene
**Description:** A versioned, backed-up store of each `.intunewin` and its source folder.
**Why:** You must be able to rebuild or re-upload a package and trace which version is deployed.
**Verify:** Each package lives in a versioned folder (e.g. `\\share\Packages\ContosoLOB\4.2.0\`).
**Implement:** Adopt a `App\Version\` folder convention; keep the source folder alongside the
`.intunewin` so you can rebuild it.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Devices enrolled; IME healthy — `WIN32-Validation.ps1`
- [ ] Win32 Content Prep Tool downloaded from Microsoft
- [ ] Clean packaging source folder staged
- [ ] Tested silent install + uninstall command lines (exit `0`)
- [ ] Reliable detection value captured (product code / file+version / registry)
- [ ] Requirement rule values planned (x64, min OS build)
- [ ] Dependencies identified and packaged (if any)
- [ ] Versioned package store / source hygiene in place
- [ ] Pilot + Broad Entra ring groups created (`WIN32-Set-RingTargeting.ps1`)
