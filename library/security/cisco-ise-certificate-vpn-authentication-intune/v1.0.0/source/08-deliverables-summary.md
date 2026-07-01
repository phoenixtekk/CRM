# 8. Deliverables Summary — Certificate-Based VPN Authentication for Cisco ISE with Intune

## What's in this solution
A complete, self-guided package to replace password-based Cisco VPN sign-in with **certificate-based
EAP-TLS authentication** — certificates issued from **Intune** (SCEP or PKCS) with a trust chain
**Cisco ISE** validates, deployed pilot-first and rollback-ready.

## Documents
| File | What it gives you |
| --- | --- |
| `01-solution-overview.md` | How EAP-TLS certificate VPN auth works with ISE as the RADIUS authority; SCEP vs PKCS; the trust chain ISE must validate; where Intune delivery meets the Cisco head-end. |
| `02-requirements.md` | Every prerequisite (CA/Cloud PKI, Certificate Connector/NDES, trusted-root + SCEP/PKCS profiles, Entra groups, ISE for EAP-TLS, head-end, revocation) with Description / Why / Verify / Implement. |
| `03-implementation.md` | Ordered, click-by-click steps: scope groups → Trusted Root profile → SCEP/PKCS profile → confirm cert lands → validate ISE EAP-TLS → pilot → expand, with pass/fail gates and rollback. |
| `05-testing.md` | Seven validation tests with explicit gates (cert present, chain valid, ISE auth success). |
| `06-troubleshooting.md` | The failure modes: no cert, chain incomplete, ISE rejects EAP-TLS, renewal failures — with concrete fixes. |
| `07-best-practices.md` | Renewal, revocation, and key-protection practices for steady-state operation. |
| `global-requirements-security.md` | Category-level prerequisites shared across all security solutions. |
| `executive-summary.md` | One-page business case for decision-makers. |

## PowerShell scripts (read-only / safe by default)
| Script | Purpose | Default posture |
| --- | --- | --- |
| `CISECERT-Discovery.ps1` | Certificate readiness: Intune certificate connectors + trusted-root/SCEP/PKCS profiles (Graph). | Read-only |
| `CISECERT-Validation.ps1` | Confirm the VPN cert + full chain are present on **this** device (local cert store checks). | Read-only |
| `CISECERT-Report.ps1` | Certificate deployment + expiry coverage across the fleet (Graph). | Read-only |
| `CISECERT-Remediation.ps1` | Safely re-trigger missing/failed cert issuance. | `-WhatIf` by default |
| `CISECERT-Set-ScopeTargeting.ps1` | Create/populate the pilot/broad Entra group(s). | `-WhatIf` by default |

All Graph scripts require the Microsoft Graph PowerShell SDK and read-only scopes (Remediation and
group creation request write scopes only for their explicit `-Apply` action).

## Named objects you will create (reuse verbatim)
- `Cisco VPN – Trusted Root` (and `Cisco VPN – Trusted Root (Intermediate)` if applicable)
- `Cisco VPN – SCEP Device Cert` / `Cisco VPN – SCEP User Cert` / `Cisco VPN – PKCS User Cert`
- `PILOT – Cisco Cert VPN Users` / `BROAD – Cisco Cert VPN Users`

## Vendor boundary
The Intune / Entra / certificate side is documented at exact, click-by-click detail. **Cisco ISE and
VPN head-end (ASA / Secure Firewall) console configuration — trust-store import, Certificate
Authentication Profile, policy sets, identity sources, RADIUS/VPN connection profiles — is deferred
to Cisco's official documentation.** This solution guarantees ISE receives a correct, complete,
chain-valid EAP-TLS certificate to authenticate.

## Definition of done
Every targeted VPN user authenticated by a certificate Cisco ISE trusts — no passwords, issued from
Intune, proven on a pilot (Gates 0–6) before expanding to the fleet (Gate 7), with renewal and
revocation operationalized and a rollback path kept available throughout.
