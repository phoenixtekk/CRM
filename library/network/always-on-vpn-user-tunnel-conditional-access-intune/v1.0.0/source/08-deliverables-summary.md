# Deliverables Summary — Windows Always On VPN: User Tunnel with Conditional Access via Intune

This solution is a complete, self-guided package to deploy the Windows Always On VPN **user tunnel** to
enrolled Windows devices via Microsoft Intune and gate it with Entra **Conditional Access** —
pilot-first and rollback-ready. Below is everything included.

## Documentation set (source/)

| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | User tunnel vs. device tunnel, the profile-plus-certificate-plus-policy model, IKEv2/SSTP + Always On, where this fits vs. the companion device-tunnel product, and the Assess→Configure→Pilot→Validate→Expand model. |
| `02-requirements.md` | Every prerequisite with **Description / Why / Verify / Implement-if-missing** — Intune licensing + enrolled Windows devices, Entra user groups, a VPN head-end (RRAS/Azure VPN Gateway), a lean user-cert SCEP path + trusted root, Conditional Access availability, and a device compliance policy. |
| `03-implementation.md` | Exact ordered build: trusted root → user SCEP cert → the VPN template profile → the Conditional Access policy, assigned to the named pilot user group, then validate, pilot, expand — with pass/fail gates and a naming table. |
| `05-testing.md` | The validation test matrix (T1–T9) with explicit **PASS/FAIL** gates, including auto-connect-on-sign-in and the Conditional Access report-only check. |
| `06-troubleshooting.md` | Failure-by-symptom fixes: tunnel not auto-connecting, profile not applying, certificate issues, Conditional Access blocking legit users, SSTP-vs-IKEv2, and script/reporting issues. |
| `07-best-practices.md` | Field-proven practices for naming, user-vs-device tunnel, pilot-first, certificates (lean), trusted-network/split-tunnel, Conditional Access, change control, and safe operation. |
| `executive-summary.md` | One-page business-outcome summary for stakeholders. |
| `global-requirements-network.md` | Category-level Network prerequisites (shared across Network solutions). |

## PowerShell scripts (scripts/)

All five use the **Microsoft Graph PowerShell SDK** (validation runs locally, no Graph). Discovery/
validation/report are **read-only**; remediation and scope-targeting **default to `-WhatIf` (preview)**
and change nothing until you re-run with `-WhatIf:$false`. Each script's header documents its exact
purpose, run command, and required Graph scopes.

| Script | Purpose | Mode |
|---|---|---|
| `AOVUT-Discovery.ps1` | Deployment-readiness sweep across Entra + Intune — the trusted-root, user SCEP, and VPN profiles, the Conditional Access policy `CA – AOVPN User Tunnel Access`, and the pilot/prod user groups, with assignment state. | Read-only |
| `AOVUT-Validation.ps1` | Confirms **on this device** that the `AOVPN User Tunnel` VPN connection is present (Always On) and a valid **user** certificate is in `CurrentUser\My`. Prints an overall PASS/FAIL. | Read-only (local) |
| `AOVUT-Report.ps1` | Fleet coverage report — per-profile apply counts (succeeded/failed/pending) for the VPN and user-cert profiles, with coverage percentages and an overall figure; optional CSV export. | Read-only |
| `AOVUT-Remediation.ps1` | Safely fixes stragglers — retries errored devices via sync and adds missing Required assignments to the user target group. | Write, **default `-WhatIf`** |
| `AOVUT-Set-ScopeTargeting.ps1` | Creates/populates the pilot (and optional production) Entra **user** security groups used as assignment targets. | Write, **default `-WhatIf`** |

## The consistent object naming convention

Every artifact is named to a convention and reused verbatim across docs, tests, troubleshooting, and
scripts (so the scripts find objects deterministically):

- User groups: `PILOT – AOVPN User Tunnel Users`, `PROD – AOVPN User Tunnel Users`
- Trusted root profile: `AOVPN – User Tunnel – Trusted Root CA – Windows`
- User SCEP profile: `AOVPN – User Tunnel – User Cert (SCEP) – Windows`
- VPN template profile: `AOVPN – User Tunnel – Profile – Windows` (connection name: `AOVPN User Tunnel`)
- Conditional Access policy: `CA – AOVPN User Tunnel Access`

## Vendor and companion boundaries (what is deferred)

The **VPN gateway / head-end (Windows Server RRAS or an Azure VPN Gateway) and its IKEv2/SSTP + EAP
configuration are deferred to Microsoft's official documentation.** The **device tunnel** and the **full
certificate lifecycle** (PKI design, SCEP/NDES or Cloud PKI stand-up, issuing-CA trust, renewal/revocation)
are covered in depth by the **companion device-tunnel product**. This solution authors the **Intune and
Entra** user-tunnel + Conditional Access side at full click-by-click detail and consumes the head-end
values (gateway FQDN, accepted auth, routes) and PKI inputs (SCEP URL, issuing/root CA) as inputs.
