# 2. Requirements Guide — Endpoint PowerShell Deployment & Patch Automation Toolkit

Verify **every** requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-infrastructure.md`.

## 2.1 Intune Remediations entitlement
Description: A license that includes Intune Remediations (proactive remediations).
Why: The detect-then-remediate scheduled scripts are an Intune Remediations feature; without the
entitlement the Remediations blade and scheduled runs are unavailable.
Verify: Sign in to `https://intune.microsoft.com`, go to Devices → Manage devices → Remediations
(Scripts and remediations); confirm you can open it and click `Create script package`.
Implement: Assign a qualifying license — Windows 10/11 Enterprise E3 or E5, Education A3 or A5, or the
standalone Intune Plan 1 with the Remediations add-on — to the targeted users/devices.

## 2.2 Microsoft Graph PowerShell SDK
Description: The Microsoft Graph PowerShell SDK on the admin workstation.
Why: The fleet report and the rings/assignment audit read Intune data through Microsoft Graph.
Verify: Run `Get-Module -ListAvailable Microsoft.Graph.Authentication`; run `PSAUTO-Discovery.ps1`,
which checks for the module.
Implement: Run `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.3 Microsoft Graph permissions
Description: Delegated Graph scopes to read device and remediation data.
Why: The report scripts call Graph for managed-device inventory and remediation results.
Verify: When you run `PSAUTO-Report.ps1` the consent prompt lists
`DeviceManagementManagedDevices.Read.All` and `DeviceManagementConfiguration.Read.All`.
Implement: Consent at first sign-in as an Intune Administrator, or have an admin grant the delegated
scopes to the Microsoft Graph PowerShell app.

## 2.4 PowerShell execution policy and 64-bit run
Description: Scripts can run, and remediations run in the 64-bit PowerShell host.
Why: Intune can run remediation scripts in 32-bit by default; registry and file paths differ between
32-bit and 64-bit, which causes false "non-compliant" results.
Verify: Run `Get-ExecutionPolicy -List`; in the remediation's settings confirm
`Run script in 64-bit PowerShell` is set to `Yes`.
Implement: Set the remediation's `Run script in 64-bit PowerShell` to `Yes`; for local runs use
`-ExecutionPolicy Bypass`. Sign your scripts if your policy requires it (see 2.5).

## 2.5 Script signing (if required by policy)
Description: A code-signing certificate, if your execution policy is `AllSigned`.
Why: An `AllSigned` policy refuses unsigned scripts; remediations would fail to run.
Verify: Run `Get-ExecutionPolicy`; if it returns `AllSigned`, scripts must be signed.
Implement: Sign each `.ps1` with `Set-AuthenticodeSignature` using a trusted code-signing
certificate, or set the remediation to `Enforce script signature check = No` only where policy allows.

## 2.6 A results destination (optional)
Description: A folder, share, or Log Analytics workspace for run logs, if you want a durable record
beyond Intune's built-in results.
Why: Intune retains remediation results, but a central log makes auditing and trending easier.
Verify: The chosen folder/share is writable by SYSTEM, or the Log Analytics workspace exists.
Implement: Create the share/workspace and point the deployment/cleanup runner's `-LogPath` at it.

---
## Checklist
- [ ] Intune Remediations entitlement (Remediations blade opens)
- [ ] Microsoft Graph PowerShell SDK installed — `PSAUTO-Discovery.ps1`
- [ ] Graph scopes consented (managed devices + configuration read)
- [ ] Execution policy allows the scripts; remediations set to run 64-bit
- [ ] Scripts signed if policy is `AllSigned`
- [ ] (Optional) Results destination chosen for run logs
- [ ] Pilot + Production device groups created
