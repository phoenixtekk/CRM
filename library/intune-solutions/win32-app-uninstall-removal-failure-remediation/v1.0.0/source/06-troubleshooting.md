# Troubleshooting

This guide covers problems with the **method, scripts, and access** used in this solution. To diagnose
an actual removal failure, use the **Diagnostic Playbook** (`03-implementation.md`) — that is the
symptom tree for the apps themselves. This file is about getting the tooling and the diagnostic
process to work.

---

## Connecting to Microsoft Graph

**`Connect-MgGraph` fails or the module is missing.**
- Install the SDK: `Install-Module Microsoft.Graph -Scope CurrentUser`.
- Confirm it is present: `Get-Module Microsoft.Graph -ListAvailable`.
- Run PowerShell as your admin account and re-run the script; consent to the requested scopes at the
  sign-in prompt.

**"Insufficient privileges" or consent is required.**
- The read-only scripts need `DeviceManagementApps.Read.All`,
  `DeviceManagementManagedDevices.Read.All`, and (for `-CheckConflicts`) `Group.Read.All`.
  `APPUNIN-Remediation.ps1` needs `DeviceManagementApps.ReadWrite.All`.
- If your tenant blocks user consent, have a Global Administrator grant admin consent once for the
  **Microsoft Graph Command Line Tools** app at **Entra admin center > Applications > Enterprise
  applications**.

**US Government tenant — the scripts connect to the wrong cloud.**
- Pass `-GraphEnvironment USGov` (GCC High) or `-GraphEnvironment USGovDoD` (DoD). The script then
  calls `Connect-MgGraph -Environment USGov`/`USGovDoD` and targets `https://graph.microsoft.us`
  (DoD: `https://dod-graph.microsoft.us`). The admin console is `https://endpoint.microsoft.us`.
- If a script still reaches the Commercial cloud, run `Disconnect-MgGraph` first — a cached Commercial
  context is being reused — then re-run with the `-GraphEnvironment` flag.

**Scripts return no data even though the app exists.**
- Confirm your account has an Intune role that can read apps (R1) and that you signed in to the
  correct tenant. Re-run `Connect-MgGraph -TenantId <your-tenant-id>` if you belong to multiple
  tenants.

---

## Running the on-device scripts

**`APPUNIN-Discovery.ps1` finds nothing, but the app is clearly installed.**
- Run PowerShell **elevated** — a per-machine registration under HKLM is readable without elevation,
  but the process/service checks and the `C:\Windows\Installer` scan need admin.
- The app may be registered only under **HKCU** for a *different* user's profile than the one you are
  signed in as. That is Branch F — the app is per-user.
- If the app truly has no registration yet Intune reports it installed, the detection rule is matching
  a remnant (Branch C).

**`APPUNIN-LogParser.ps1` reports "no matching lines."**
- Match by the application **GUID** (`-AppId <guid>`) as well as the name — the log often references
  the app id, not the display name.
- The app may never have reached the device (intent conflict — Branch A — or the device is not
  reporting — Branch I). Confirm with `APPUNIN-Validation.ps1` first.
- Older entries roll into numbered log copies; the parser already includes them, but confirm your
  `-LogPath` is correct if the IME logs were relocated.

---

## Reading the IME logs

**The Intune Management Extension logs are not where expected.**
- Path is `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\` — `ProgramData` is hidden; type
  the full path into File Explorer's address bar, or use `CMTrace`/Notepad.
- Chief files: `IntuneManagementExtension.log`, `AppWorkload.log`, and `AgentExecutor.log`. Older
  entries roll into numbered copies — check those for a removal that happened earlier.

**No log entries for the app at all.**
- The device may never have been targeted with the Uninstall intent (Branch A conflict, or a deleted
  app object — Branch I). Confirm assignments with `APPUNIN-Validation.ps1 -CheckConflicts` first.
- Force a sync and re-check after the next cycle.

**Cannot access the device locally.**
- Use **Intune admin center > Devices > Windows > Windows devices > _<device>_ > ... > Collect
  diagnostics** to package the Management Extension logs, then read them offline.

---

## Interpreting states

**Console and script disagree on status.**
- The console can lag; Graph (via `APPUNIN-Validation.ps1`) reflects the last reported state. Force a
  sync and re-read; treat the **device log** as the final authority.

**Status keeps flipping between Not installed and Uninstall failed.**
- This is the detection-loop symptom — go to Diagnostic Playbook **Branch C**. It is not a tooling
  problem.

**Everything shows "Unknown."**
- The devices are not checking in, not failing — Branch I. Confirm **Last check-in time** on the
  device before chasing uninstall-command fixes.

---

## Remediation script

**Remediation made no change.**
- By design: `APPUNIN-Remediation.ps1` defaults to **-WhatIf** and only prints the planned change.
  Re-run with `-WhatIf:$false` after reviewing it to apply.

**Remediation cannot modify the app.**
- Read-only rights are enough for Discovery/Validation/Report/LogParser but not for changes. Assign
  **Intune Administrator** (or **Managed apps** Update/Assign) per requirement R2 and re-consent to
  the ReadWrite scope.

**The corrected uninstall command is set in Intune but the device hasn't changed.**
- Devices apply on their sync cycle. Force a sync and allow a full cycle, then re-run
  `APPUNIN-Validation.ps1`. Do not re-create the app or loop remediation tightly — read the log to
  confirm the app processed the new command.

**The ProductCode-resolving wrapper does not remove the app.**
- Confirm the `-DisplayNamePattern` actually matches the app's registered **DisplayName** on the
  device (check with `APPUNIN-Discovery.ps1`). A pattern that is too specific (an exact version
  string) will not match after an upgrade.

---

## When the method stalls

- **You fixed a stage and it still fails.** You likely fixed a later stage while an earlier one is
  still wrong. Return to Step 0, re-read the log in removal order (**intent → pre-detection →
  command → exit code → post-detection**), and fix the **first** thing that is wrong — usually the
  intent conflict (Branch A) or the detection rule (Branch B/C).
- **Removal works for some devices, not others.** Compare a passing device's `APPUNIN-Discovery.ps1`
  output to a failing one — the difference (app version / ProductCode, HKLM vs HKCU, a running
  process, cached-MSI presence) is your cause.
- **The software is stranded because the app object was deleted.** Re-create the Win32 app with a
  correct Uninstall command and detection rule and assign **Uninstall** (Branch I) — never delete the
  object as a removal method.
