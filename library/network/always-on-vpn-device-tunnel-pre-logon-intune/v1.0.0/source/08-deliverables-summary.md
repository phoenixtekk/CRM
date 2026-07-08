# Deliverables Summary — Windows Always On VPN Device Tunnel (Pre-Logon) via Intune

This solution is a complete, self-guided package to deploy the Windows **Always On VPN device tunnel**
— machine-context, IKEv2, machine-certificate authentication, connecting **before user logon** — to
your managed Windows fleet using Microsoft Intune, pilot-first and rollback-ready. Below is everything
included.

## Documentation set (source/)

| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | Why a device tunnel (pre-logon, IKEv2-only, machine-cert-only, one profile), how it's delivered via a Custom OMA-URI ProfileXML in device context, the folded-in certificate lifecycle, benefits, limits, and the Assess→Configure→Pilot→Validate→Expand model. |
| `02-requirements.md` | Every prerequisite with **Description / Why / Verify / Implement-if-missing** — Intune licensing + enrollment, supported Windows edition/join type, the VPN head-end, SCEP/PKCS PKI, the root CA and gateway server cert, connection parameters, admin roles — plus the Commercial vs Government (GCC High) note. |
| `03-implementation.md` | Exact ordered build: create the DEVICE groups, **the certificate lifecycle phase** (Trusted Root CA then SCEP machine cert), author the ProfileXML, build the Custom OMA-URI profile assigned to a DEVICE group, then pilot, validate (pre-logon), and expand — with Gates A–E. |
| `05-testing.md` | The validation test matrix (T1–T8) with explicit **PASS/FAIL** gates, including the decisive **pre-logon** device-tunnel test. |
| `06-troubleshooting.md` | Failure-by-symptom fixes: device tunnel absent, tunnel not connecting, certificate issues, two device tunnels, and script/reporting issues. |
| `07-best-practices.md` | Field-proven practices for naming, device-context assignment, certificate lifecycle, ProfileXML discipline, change control, and safe operation. |
| `executive-summary.md` | One-page business-outcome summary for stakeholders. |
| `global-requirements-network.md` | Category-level Network prerequisites (shared across Network solutions). |

## PowerShell scripts (scripts/)

All five use the **Microsoft Graph PowerShell SDK** except the on-device validation script, which runs
locally with **no** Graph scopes. Discovery/validation/report are **read-only**; remediation and
scope-targeting **default to `-WhatIf` (preview)** and change nothing until you re-run with
`-WhatIf:$false`. Each script's header documents its exact purpose, run command, and required scopes.

| Script | Purpose | Mode |
|---|---|---|
| `AOVDT-Discovery.ps1` | Deployment-readiness sweep across Entra + Intune — finds the Custom ProfileXML profile, the Trusted Root CA and SCEP cert profiles, and the pilot/prod **device** groups, with assignment state. (There is **no app** — the device tunnel is a native VPN profile.) | Read-only |
| `AOVDT-Validation.ps1` | Confirms **on this device** that the `AOVPN Device Tunnel` profile is present (`Get-VpnConnection -AllUserConnection`) and a valid machine certificate with Client Authentication EKU is in `LocalMachine\My`. Prints an overall PASS/FAIL. | Read-only (local) |
| `AOVDT-Report.ps1` | Fleet coverage report — per-profile apply counts (succeeded/failed/pending) for the ProfileXML and certificate profiles, with coverage percentages and an overall figure; optional CSV export. | Read-only |
| `AOVDT-Remediation.ps1` | Safely fixes stragglers — retries (device sync) devices where the ProfileXML errored and adds missing Required assignments to the target **device** group. | Write, **default `-WhatIf`** |
| `AOVDT-Set-ScopeTargeting.ps1` | Creates/populates the pilot (and optional production) Entra **device** security groups used as assignment targets — adding **devices** by name. | Write, **default `-WhatIf`** |

## The consistent object naming convention

Every artifact is named to a convention and reused verbatim across docs, tests, troubleshooting, and
scripts (so the scripts find objects deterministically):

- Device groups: `PILOT – AOVPN Device Tunnel – Devices`, `PROD – AOVPN Device Tunnel – Devices`
- Custom ProfileXML profile: `AOVPN – Device Tunnel – ProfileXML – Windows`
  (VPN profile name inside the XML / OMA-URI path segment: `AOVPN Device Tunnel`)
- Trusted Root CA profile: `AOVPN – Device Tunnel – Trusted Root CA – Windows`
- SCEP machine certificate profile: `AOVPN – Device Tunnel – Machine Cert (SCEP) – Windows`
- Assignment filter (optional): `Filter – AOVPN Device Tunnel – Windows`

## Vendor boundary (what is deferred)

The **VPN gateway head-end** — Windows Server **RRAS** or **Azure VPN Gateway** — including its IKEv2
parameters, address pool/routes, the CA it trusts, and the server certificate it presents, is
**deferred to Microsoft's official documentation**. This solution authors the **Intune, Entra, and
Windows/PKI** side at full click-by-click detail and consumes the head-end's gateway address/FQDN,
IKEv2 settings, and CA trust as inputs.
