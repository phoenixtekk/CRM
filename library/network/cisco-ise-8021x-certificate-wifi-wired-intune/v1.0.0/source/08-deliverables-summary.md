# Deliverables Summary

Everything included in this solution, and where to use it.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** | One-page business framing: the risk, the outcome, the approach. |
| **01 – Solution Overview** | How 802.1X / EAP-TLS works for Wi-Fi and wired with Cisco ISE as RADIUS authority; the certificate + network-profile model; where Intune delivery meets Cisco switching/wireless. |
| **02 – Requirements** | Every 802.1X-specific prerequisite with **Description / Why / Verify / Implement-if-missing** (CA/Cloud PKI, Certificate Connector, trusted root, SCEP/PKCS, Wi-Fi/wired settings, ISE RADIUS readiness, Entra groups, pilot). |
| **03 – Implementation** | Exact, ordered Intune steps: trusted root → SCEP cert → Wi-Fi 802.1X → wired 802.1X → assign to pilot → confirm ISE → validate → expand. |
| **05 – Testing & Validation** | The three pass/fail gates (cert present, profile applied, ISE auth success) and pilot exit criteria. |
| **06 – Troubleshooting** | The common failure modes: no cert, profile not applied, ISE rejects, supplicant issues, wired-vs-wireless differences. |
| **07 – Best Practices** | Supplicant, certificate renewal, and fail-open vs fail-closed guidance. |
| **Global Requirements (Network)** | Category-level prerequisites shared by all Network solutions. |

## Named objects created (reused verbatim across all docs and scripts)

| Object | Type | Role |
| --- | --- | --- |
| `Cisco 802.1X – Trusted Root` | Intune Trusted certificate profile | Installs the root that signed ISE's server certificate. |
| `Cisco 802.1X – SCEP Cert` | Intune SCEP (or PKCS) certificate profile | Issues the device client certificate (EAP-TLS identity). |
| `Corp Wi-Fi – EAP-TLS` | Intune Wi-Fi profile | WPA2/WPA3-Enterprise + EAP-TLS corporate SSID. |
| `Wired 802.1X – EAP-TLS` | Intune Wired network profile | Wired 802.1X EAP-TLS supplicant. |
| `PILOT – 802.1X Devices` | Entra security group | Pilot assignment target. |
| `Corp – 802.1X Devices` | Entra security group | Production assignment target (Expand phase). |

## PowerShell scripts

All scripts are **read-only** against Microsoft Graph except remediation/scope-targeting, which
**default to `-WhatIf`**. Cisco ISE and network-infrastructure internals are **deferred to vendor
documentation** — no script touches ISE, switches, or the WLC.

| Script | What it does |
| --- | --- |
| **ISE8021X-Discovery.ps1** | Tenant-wide 802.1X readiness: certificate connectors, and the trusted-root / SCEP / PKCS / Wi-Fi / wired 802.1X profiles present in Intune. |
| **ISE8021X-Validation.ps1** | On **this** device: confirms the client certificate and the Wi-Fi + wired 802.1X profiles are applied (the three gates, device side). |
| **ISE8021X-Report.ps1** | Fleet coverage: which devices have the certificate and the Wi-Fi/wired profiles, and where the gaps are. |
| **ISE8021X-Remediation.ps1** | Safely fixes missing profile/cert assignments (adds devices/groups to the right profiles). **Default `-WhatIf`.** |
| **ISE8021X-Set-ScopeTargeting.ps1** | Creates/populates the pilot Entra group(s) used as assignment targets. **Default `-WhatIf`.** |

## Deployment model

**Assess → Configure → Pilot → Validate → Expand**, gated by **cert present → profile applied → ISE
802.1X auth success**, with a documented rollback (remove assignment + network-side fallback) at every
step.
