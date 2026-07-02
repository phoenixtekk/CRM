# Troubleshooting

This guide covers problems with the **method, scripts, and access** used in this solution. For
diagnosing an actual app deployment failure, use the **Diagnostic Playbook** (`03-implementation.md`)
— that is the symptom tree for the apps themselves. This file is about getting the tooling and the
diagnostic process itself to work.

---

## Connecting to Microsoft Graph

**`Connect-MgGraph` fails or the module is missing.**
- Install the SDK: `Install-Module Microsoft.Graph -Scope CurrentUser`.
- Confirm it is present: `Get-Module Microsoft.Graph -ListAvailable`.
- Run PowerShell as your admin account and re-run the script; consent to the requested scopes at the
  sign-in prompt.

**"Insufficient privileges" or consent is required.**
- The read-only scripts need `DeviceManagementApps.Read.All` and
  `DeviceManagementManagedDevices.Read.All`; Remediation/Set-ScopeTargeting also need
  `DeviceManagementApps.ReadWrite.All`.
- If your tenant blocks user consent, have a Global Administrator grant admin consent for the
  Microsoft Graph Command Line Tools app once (Entra → **Enterprise applications**).

**Scripts return no data even though apps exist.**
- Confirm your account has an Intune role that can read apps (R1) and that you signed in to the
  correct tenant. Re-run `Connect-MgGraph -TenantId your-tenant-id` if you belong to multiple
  tenants.

---

## Reading the device logs

**The Intune Management Extension logs are not where expected.**
- Path is `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\` — `ProgramData` is hidden;
  type the full path into Explorer or use `CMTrace`/Notepad.
- Chief files: `IntuneManagementExtension.log` and `AppWorkload.log`. Older entries roll into
  numbered copies — check those for a failure that happened earlier.

**No log entries for the app at all.**
- The device may not be in scope (Not applicable / never assigned). Confirm with
  `INTAPPDX-Discovery.ps1` first.
- Force a sync (`INTAPPDX-Remediation.ps1` or device **Sync**) and check again after the next cycle.

**Cannot access the device locally.**
- Use Intune → **Devices → the device → Collect diagnostics** to package the Management Extension
  logs for download, then read them offline.

---

## Interpreting states

**Console and script disagree on status.**
- The console can lag; Graph (via `INTAPPDX-Validation.ps1`) reflects the last reported state.
  Force a sync and re-read; treat the device log as the final authority.

**Status keeps flipping between Installed and Failed.**
- This is the detection-rule symptom — go to Diagnostic Playbook **Branch B**. It is not a tooling
  problem.

**Everything shows "Not applicable."**
- Confirm the device is in a group the app is assigned to (Discovery). If it is genuinely out of
  scope, Not applicable is correct — adjust the assignment, don't chase requirement rules.

---

## Remediation and targeting scripts

**Remediation made no change.**
- By design: both `INTAPPDX-Remediation.ps1` and `INTAPPDX-Set-ScopeTargeting.ps1` default to
  **-WhatIf** and only print the planned change. Re-run with `-WhatIf:$false` after reviewing it to
  apply.

**Remediation cannot modify the assignment.**
- Read-only rights are enough for Discovery/Validation/Report but not for changes. Assign
  **Intune Administrator** (or Managed apps Update/Assign) per requirement R2 and re-consent to the
  ReadWrite scope.

**A fix looks applied in Intune but the device hasn't changed.**
- Devices apply on their sync cycle. Force a sync and allow a cycle, then re-run
  `INTAPPDX-Validation.ps1`. Do not re-create the app or re-run remediation repeatedly in a tight
  loop — read the log to confirm the app moved forward.

---

## When the method stalls

- **You fixed a stage and it still fails.** You likely fixed a downstream stage while an upstream one
  is still failing. Return to Step 0 of the playbook, re-read the log in pipeline order, and fix the
  **first** failing stage.
- **The failure is intermittent across devices.** Compare a passing device's log to a failing one at
  the same stage; the difference (OS build, architecture, disk space, proxy, existing app version)
  is your cause.
- **Vendor-installer specifics.** Intune-side diagnosis stops at the exit code; decode installer-
  specific exit codes and MSI verbose logs against the vendor's own documentation.
