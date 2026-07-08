# Deliverables Summary — GlobalProtect Connect Before Logon (PLAP) for Hybrid Autopilot via Intune

This solution is a complete, self-guided package to deploy **GlobalProtect Connect Before Logon (PLAP)**
during a **Hybrid Azure AD Join Windows Autopilot** provisioning using Microsoft Intune — pilot-first,
rollback-ready, and built to be **diagnosed** as well as deployed. Below is everything included.

## Documentation set (source/)

| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | The scenario (Always On → user-initiated VPN after a security incident; Hybrid Autopilot needs pre-logon DC reachability), what Connect Before Logon (CBL/PLAP) is, the single-Win32-app delivery model (install + `PanSetup` registry + service-readiness wait + `PanGPS.exe -registerplap` + return `3010`), the Autopilot/ESP fit, and the Assess→Configure→Pilot→Validate→Expand model. |
| `02-requirements.md` | Every prerequisite with **Description / Why / Verify / Implement-if-missing** — Intune licensing + Autopilot, the Hybrid-Join profile, Domain Join + ODJ connector, ESP, the GlobalProtect 5.2+ MSI + portal FQDN + auth method, optional PKI, the **Assigned** device group **owned by the Provisioning Client SP**, reboot-sequencing design, and the AV/IMECache exclusion. Includes the Government note. |
| `03-implementation.md` | Exact ordered build with **Gates A–E**: create the Assigned + SP-owned device group, build the single Win32 app (install + registry + readiness wait + `-registerplap` in SYSTEM + `3010`), set System context, detection (GP≥5.2 + `Prelogon=1` + PLAP registered) and return-code mapping, add the app as an **ESP blocking app**, apply the AV/IMECache exclusion, then pilot on Windows 11, validate, and expand. Documents the two-app alternative. |
| `05-testing.md` | The validation test matrix (T1–T10) with explicit **PASS/FAIL** gates, including the decisive pre-logon tunnel + first hybrid domain logon test and the log-capture runbook. |
| `06-troubleshooting.md` | The failure-mode matrix: the **"unzipping" / 0x87D30067** error, the **PLAP tile not visible**, **install fails after reboot / IME state lost**, **ESP hangs on the app**, **Win10-vs-Win11** mismatch, **tunnel up but hybrid first-logon fails**, and **enrollment-time group empty**. |
| `07-best-practices.md` | Field-proven practices for naming, enrollment-time targeting, reboot sequencing, avoiding the unzip failure, Connect Before Logon correctness, Windows 11 testing, fast diagnosis, certificates, and safe operation. |
| `executive-summary.md` | One-page business-outcome summary for stakeholders. |
| `global-requirements-network.md` | Category-level Network prerequisites (shared across Network solutions). |

## PowerShell scripts (scripts/)

Discovery/report/scope-targeting use the **Microsoft Graph PowerShell SDK**; validation and log-capture
run **locally** on the device and need no Graph. Discovery/validation/report/log-capture are **read-only
/ collection-only**; scope-targeting **defaults to `-WhatIf` (preview)** and changes nothing until you
re-run with `-WhatIf:$false`. Each script's header documents its exact purpose, run command, and required
Graph scopes.

| Script | Purpose | Mode |
|---|---|---|
| `GPPLAP-Discovery.ps1` | Readiness sweep across Entra + Intune — finds the Win32 app (and the two-app alternative names), the optional cert profile, the pilot/prod Autopilot **device** groups, flags whether the **Assigned** group has the Provisioning Client SP (`f1346770-5b25-470b-88bd-d5744ab7952c`) as **owner**, and whether the app is referenced as an **ESP blocking app**. | Read-only |
| `GPPLAP-Validation.ps1` | Confirms **on this Windows 11 device** that GlobalProtect is installed and **≥ 5.2**, `PanSetup\Prelogon = 1` with the portal set, the **PLAP credential provider is registered**, and reports join type via `dsregcmd`. Prints an overall PASS/FAIL. | Read-only (local) |
| `GPPLAP-Collect-Logs.ps1` | The test-window diagnostic collector — gathers the IME logs, runs `MdmDiagnosticsTool.exe -area Autopilot;DeviceEnrollment;DeviceProvisioning -zip`, collects GlobalProtect `PanGPS`/`PanGPA` logs and Event Viewer channels, and ZIPs everything to a timestamped folder. | Collection-only (local) |
| `GPPLAP-Report.ps1` | Fleet coverage report — per-app install counts (installed/failed/pending) and the optional cert profile across the Autopilot device groups, with coverage percentages. | Read-only |
| `GPPLAP-Set-ScopeTargeting.ps1` | Creates/populates the pilot (and optional production) Autopilot **device** groups as **Assigned** security groups, adds devices by name, **and sets the Provisioning Client SP as an owner** (required for enrollment-time targeting). | Write, **default `-WhatIf`** |

## The consistent object naming convention

Every artifact is named to a convention and reused verbatim across docs, tests, troubleshooting, and
scripts (so the scripts find objects deterministically):

- Device groups: `PILOT – GlobalProtect PLAP – Autopilot Devices`, `PROD – GlobalProtect PLAP – Autopilot Devices`
- Win32 app (recommended): `GlobalProtect – Connect Before Logon (PLAP) – Win32`
- Two-app alternative: `GlobalProtect – VPN Client – Win32` + `GlobalProtect – PLAP Registration – Win32`
- Optional certificate profile: `GlobalProtect – PLAP – Device Cert (SCEP) – Windows`
- ESP blocking-app reference: `ESP – Autopilot – GlobalProtect PLAP Blocking`

## Vendor boundary (what is deferred)

The **GlobalProtect portal / gateway configuration, the authentication method the portal enforces, and
the GlobalProtect app internals are deferred to Palo Alto Networks' official documentation.** This
solution authors the **Intune, Autopilot, Entra, and Windows** side at full click-by-click detail and
consumes the Palo Alto-supplied **MSI (5.2+)**, **portal FQDN**, and **auth method** as inputs.
