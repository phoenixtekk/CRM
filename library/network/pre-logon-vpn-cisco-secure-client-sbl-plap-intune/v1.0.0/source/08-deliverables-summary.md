# Deliverables Summary — Pre-Logon VPN with Cisco Secure Client Start Before Logon (SBL/PLAP) via Intune

This solution is a complete, self-guided package to deploy Cisco Secure Client with **Start Before
Logon (SBL/PLAP)** to Windows devices using Microsoft Intune — so the VPN tunnel comes up **before**
Windows logon — pilot-first and rollback-ready, with the device-certificate lifecycle folded in. Below
is everything included.

## Documentation set (source/)

| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | Why pre-logon matters (first remote logon, off-network password resets, GPO/DC reachability), how SBL works (PLAP / `vpnplap64.dll`, the two required artifacts, Core-then-SBL order, `UseStartBeforeLogon=true`), how it's delivered via Intune, why a device certificate, and the Assess→Configure→Pilot→Validate→Expand model. |
| `02-requirements.md` | Every prerequisite with **Description / Why / Verify / Implement-if-missing** — Windows-only scope, Intune licensing + enrollment, Entra groups, the Cisco head-end/ISE, the **Core + Start Before Logon** installers, the **SBL-enabled** XML, the **device-cert** decision, PKI/SCEP infrastructure, and certificate renewal policy. |
| `03-implementation.md` | Exact ordered build: create groups, **deploy the trusted root then the device SCEP certificate**, package the Win32 app that installs **Core then SBL** and drops the SBL-enabled XML, build the Windows VPN profile, assign to the pilot group, validate, pilot, expand — with pass/fail **Gates A–E** and a naming table. |
| `05-testing.md` | The validation test matrix (T1–T9) with explicit **PASS/FAIL** gates, including the decisive manual test — lock/sign out, click the **"Network sign-in"** (PLAP) option, connect, then log on with the tunnel up. |
| `06-troubleshooting.md` | Failure-by-symptom fixes: PLAP option not showing, tunnel up but logon fails, certificate missing/wrong, install failures, and script/reporting issues. |
| `07-best-practices.md` | Field-proven practices for naming, the three SBL non-negotiables, pilot-first, device-certificate lifecycle, packaging, change control, and safe operation. |
| `executive-summary.md` | One-page business-outcome summary for stakeholders. |
| `global-requirements-network.md` | Category-level Network prerequisites (shared across Network solutions). |

## PowerShell scripts (scripts/)

Four of the five use the **Microsoft Graph PowerShell SDK**; the on-device validation script runs
locally with no Graph. Discovery/report are **read-only**; on-device validation is **read-only local**;
remediation and scope-targeting **default to `-WhatIf` (preview)** and change nothing until you re-run
with `-WhatIf:$false`. Each script's header documents its exact purpose, run command, and required
Graph scopes.

| Script | Purpose | Mode |
|---|---|---|
| `SBLVPN-Discovery.ps1` | Deployment-readiness sweep across Entra + Intune — the Win32 app, the Windows VPN profile, the trusted-root and SCEP device-cert profiles, and the pilot/prod groups, with assignment state. | Read-only |
| `SBLVPN-Validation.ps1` | Confirms **on this device** that the Secure Client is installed, **Start Before Logon / PLAP is present** (`vpnplap64.dll` and/or the PLAP credential-provider registration), the VPN profile XML has `<UseStartBeforeLogon>true`, and (optionally) a device certificate is in `LocalMachine\My`. Prints an overall PASS/FAIL. | Read-only (local) |
| `SBLVPN-Report.ps1` | Fleet coverage report — Win32 app install counts and VPN/cert profile apply counts (installed/failed/pending) with coverage percentages and an overall figure; optional CSV export. | Read-only |
| `SBLVPN-Remediation.ps1` | Safely fixes stragglers — retries failed installs via device sync and adds missing Required assignments to the target group. | Write, **default `-WhatIf`** |
| `SBLVPN-Set-ScopeTargeting.ps1` | Creates/populates the pilot (and optional production) Entra security groups used as assignment targets (mailNickname prefix `sblvpn-`). | Write, **default `-WhatIf`** |

## The consistent object naming convention

Every artifact is named to a convention and reused verbatim across docs, tests, troubleshooting, and
scripts (so the scripts find objects deterministically):

- Groups: `PILOT – Pre-Logon VPN (SBL) Users`, `PROD – Pre-Logon VPN (SBL) Users`
- Win32 app: `Cisco Secure Client – Pre-Logon (SBL) – Win32`
- VPN profile: `Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows`
- Trusted root CA profile: `Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows`
- SCEP device certificate profile: `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows`
- Assignment filter (optional): `Filter – Pre-Logon VPN – Windows`

## Vendor boundary (what is deferred)

The **Cisco Secure Client console, the VPN Profile Editor / XML internals (including where
`UseStartBeforeLogon` is set), head-end CA trust, and the VPN head-end (ASA / Firepower FTD / ISE)
configuration are deferred to Cisco's official documentation.** This solution authors the **Intune,
Entra, and Windows** side at full click-by-click detail and consumes the Cisco-supplied Core + Start
Before Logon modules, the SBL-enabled VPN profile XML, gateway FQDN, tunnel-group, and auth method as
inputs.
