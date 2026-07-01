# Deliverables Summary — Cisco Secure Client (AnyConnect) VPN via Intune

This solution is a complete, self-guided package to deploy the Cisco Secure Client and its VPN
profiles across Windows, macOS, iOS, and Android using Microsoft Intune — pilot-first and
rollback-ready. Below is everything included.

## Documentation set (source/)

| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | The app-plus-profile model, per-platform delivery (Win32 / macOS PKG / iOS & Android store app + profile), auth options, benefits, limits, and the Assess→Configure→Pilot→Validate→Expand model. |
| `02-requirements.md` | Every prerequisite with **Description / Why / Verify / Implement-if-missing** — Intune licensing + enrollment, Entra groups, the Cisco head-end/ISE, installers + XML profile, APNs, Managed Google Play, macOS PKG signing, certificate infrastructure. |
| `03-implementation.md` | Exact ordered build: package the client per platform, build the VPN device-configuration profiles, assign to the named pilot group, validate, pilot, expand — with pass/fail gates and a naming table. |
| `05-testing.md` | The validation test matrix (T1–T8) with explicit **PASS/FAIL** gates, including the decisive manual VPN-connect test. |
| `06-troubleshooting.md` | Failure-by-symptom fixes: install failures, profile not applying, certificate issues, VPN won't connect, and script/reporting issues. |
| `07-best-practices.md` | Field-proven practices for naming, pilot-first, packaging, certificates, change control, and safe operation. |
| `executive-summary.md` | One-page business-outcome summary for stakeholders. |
| `global-requirements-network.md` | Category-level Network prerequisites (shared across Network solutions). |

## PowerShell scripts (scripts/)

All five use the **Microsoft Graph PowerShell SDK**. Discovery/validation/report are **read-only**;
remediation and scope-targeting **default to `-WhatIf` (preview)** and change nothing until you
re-run with `-WhatIf:$false`. Each script's header documents its exact purpose, run command, and
required Graph scopes.

| Script | Purpose | Mode |
|---|---|---|
| `CSCVPN-Discovery.ps1` | Deployment-readiness sweep across Entra + Intune — enrollment connectors (APNs, Managed Google Play), the four Secure Client apps, the four VPN profiles, the optional SCEP cert profile, and the pilot/prod groups, with assignment state. | Read-only |
| `CSCVPN-Validation.ps1` | Confirms **on this device** that the Secure Client is installed and its VPN profile (and, optionally, a device certificate) is present. Prints an overall PASS/FAIL. | Read-only (local) |
| `CSCVPN-Report.ps1` | Fleet coverage report — per-app install and per-profile apply counts (installed/failed/pending) with coverage percentages and an overall figure; optional CSV export. | Read-only |
| `CSCVPN-Remediation.ps1` | Safely fixes stragglers — retries failed installs via device sync and adds missing Required assignments to the target group. | Write, **default `-WhatIf`** |
| `CSCVPN-Set-ScopeTargeting.ps1` | Creates/populates the pilot (and optional production) Entra security groups used as assignment targets. | Write, **default `-WhatIf`** |

## The consistent object naming convention

Every artifact is named to a convention and reused verbatim across docs, tests, troubleshooting, and
scripts (so the scripts find objects deterministically):

- Groups: `PILOT – Cisco VPN Users`, `PROD – Cisco VPN Users`
- Apps: `Cisco Secure Client – VPN – Win32` / `– macOS PKG` / `– iOS` / `– Android`
- VPN profiles: `Cisco Secure Client – VPN – Profile – Windows` / `– macOS` / `– iOS` / `– Android`
- Certificate profile: `Cisco Secure Client – VPN – Device Cert (SCEP)`

## Vendor boundary (what is deferred)

The **Cisco Secure Client console, the VPN Profile Editor / XML internals, and the VPN head-end
(ASA / Firepower FTD / ISE) configuration are deferred to Cisco's official documentation.** This
solution authors the **Intune and Entra** side at full click-by-click detail and consumes the
Cisco-supplied installers, VPN profile XML, gateway FQDN, tunnel-group, and auth method as inputs.
