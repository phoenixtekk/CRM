# Deliverables Summary

This solution delivers a complete, repeatable method plus tooling for diagnosing and fixing **Win32
app uninstall / removal failures** in Microsoft Intune.

## Documents

| Document | What it gives you |
|---|---|
| **Solution Overview** (`01-solution-overview.md`) | How Intune processes an Uninstall intent (intent reconciliation, detection-gated removal, exit-code mapping, install context), the diagnostic model, and the named objects the solution creates. |
| **Global Requirements** (`global-requirements-intune-solutions.md`) | Category-level prerequisites (tenant, Intune, enrollment, Windows baseline, network). |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites — Intune roles, Graph scopes, device + IME-log access, the original packaging record, a pilot group — each with Description / Why / Verify / Implement, plus the US Government (GCC High / DoD) targeting note. |
| **Diagnostic Playbook** (`03-implementation.md`) | Step 0 fact-finding plus nine removal-failure branches (A–I): intent conflict, detection-said-gone, detection loop, stale ProductCode (1605), wrong command/switches (1603), per-user vs per-machine context, app-in-use (1618), supersedence removal, reporting/lifecycle — each with symptom → why → exact fix → re-validate. |
| **Testing** (`05-testing.md`) | The four removal gates: gone from the device, uninstall returned success, Intune agrees, and it stays gone — plus a full-removal regression check. |
| **Troubleshooting** (`06-troubleshooting.md`) | Fixes for problems with the method, scripts, and access themselves. |
| **Best Practices** (`07-best-practices.md`) | Package-time discipline (uninstall command, detection rules, unambiguous intents, return-code mapping) that prevents removal failures. |
| **Executive Summary** (`executive-summary.md`) | The business case in one page. |

## PowerShell scripts

All Graph-based scripts use the Microsoft Graph PowerShell SDK and accept
`-GraphEnvironment Global | USGov | USGovDoD` for US Government tenants. Discovery, Validation,
Report, and LogParser are strictly **read-only**. Remediation defaults to **-WhatIf** — it shows the
planned change and makes no modification unless you re-run with `-WhatIf:$false`.

| Script | Purpose | Access |
|---|---|---|
| **APPUNIN-Discovery.ps1** | On the device: resolve the real MSI **ProductCode**, the registered **UninstallString**/**QuietUninstallString**, HKLM vs HKCU registration, whether the cached MSI still exists in `C:\Windows\Installer`, and any running app processes/services. | Read-only (local) |
| **APPUNIN-Validation.ps1** | Per-device uninstall/detection state for an app from Graph, mapped to the four gates; with `-CheckConflicts`, flags devices targeted by both an install and an uninstall intent and reports supersedence depth. | Read-only (Graph) |
| **APPUNIN-Report.ps1** | Fleet-wide removal report — per app, counts of notInstalled / uninstallFailed / pendingInstall / unknown, to separate real failures from non-reporting devices. | Read-only (Graph) |
| **APPUNIN-LogParser.ps1** | Parse the IME logs (`IntuneManagementExtension.log`, `AppWorkload.log`, `AgentExecutor.log`) for an app and print the uninstall sequence: resolved intent, pre-detection, uninstall command, exit code, post-detection. | Read-only (local) |
| **APPUNIN-Remediation.ps1** | Guarded fixes: correct an app's Uninstall command (including a ProductCode-resolving wrapper), correct a detection rule, remove a conflicting assignment, or force a device re-sync. | -WhatIf default (Graph) |

## How the pieces fit

1. Confirm **Requirements**.
2. Run **Step 0** — read reported state, list assignments (**Validation -CheckConflicts**), read the
   device (**Discovery**), read the **IME log** (**LogParser**).
3. Follow the **Diagnostic Playbook** branch (A–I) that matches your symptom.
4. Apply the fix; use **Remediation** (gated) to correct the command / detection / assignment.
5. Prove it with the four **Testing** gates on `APPUNIN – Uninstall – Pilot` (via **Validation** +
   **Discovery**).
6. Expand to `APPUNIN – Uninstall – Production` and track fleet health with **Report**, following
   **Best Practices**.
