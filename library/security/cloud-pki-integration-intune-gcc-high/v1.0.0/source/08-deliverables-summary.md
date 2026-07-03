# Deliverables Summary — Cloud PKI Integration with Intune (Government / GCC High)

This solution deploys a **managed certificate program** on a **US sovereign-cloud (GCC High)**
tenant, correctly — right portals, right endpoints, and the decisive Commercial-vs-GCC-High parity
gap (**Cloud PKI is not available in GCC High**) handled by building on the **supported** path:
**trusted-root + SCEP/PKCS certificate profiles via the Intune Certificate Connector**, anchored to
your **AD CS** CA. Proven on a pilot before scale, with a clean forward road to Cloud PKI when it
ships to GCC High.

## Documents

| File | Purpose |
| --- | --- |
| `01-solution-overview.md` | The certificate model on GCC High; **Cloud PKI availability caveat up front**; how the sovereign cloud differs (portals, endpoints, parity); the Assess→Configure→Pilot→Validate→Expand model. Includes a **Commercial vs GCC High** subsection. |
| `02-requirements.md` | Each prerequisite as **Description / Why / Verify / Implement-if-missing** — Cloud-PKI-out-of-scope acknowledgement, GCC High tenant, Gov G3/G5 (Intune Plan 1), Intune roles, AD CS CA, NDES, the Certificate Connector, partner-CA GCC High support, endpoint allow-list, parity confirmation. |
| `03-implementation.md` | Exact ordered steps in the GCC High portals: trust chain, SCEP profile, PKCS profile, Wi-Fi/VPN consumption, renewal/revocation — with GCC-High URLs and the Cloud-PKI caveat + connector caveats inline where they matter, plus the future Cloud PKI migration path. |
| `05-testing.md` | Pass/fail gates from sovereign-cloud sanity and Cloud-PKI-parity acknowledgement through issuance, consumption, renewal, revocation, and script validation. |
| `06-troubleshooting.md` | GCC-High-specific gotchas (Cloud PKI not present, wrong portal/cloud, endpoint blocked, connector/NDES/SCEP failures) plus common certificate failures. |
| `07-best-practices.md` | The assign-once, repeat-everywhere certificate model, tuned for GCC High and the connector back-end. |
| `gcc-high-parity-notes.md` | Reference: per-feature Commercial-vs-GCC-High status with Microsoft citations — headlined by the **Cloud PKI not-available-in-GCC-High / not-planned-for-DoD** finding. |
| `global-requirements-security.md` | Category-level prerequisites shared by all security solutions. |
| `executive-summary.md` | One-page summary for decision-makers (leads with the Cloud PKI availability caveat). |

## Scripts (PowerShell, Microsoft Graph SDK, **US Gov endpoints**)

All scripts connect with **`Connect-MgGraph -Environment USGov`** for GCC High. Read-only tools are
read-only; change tools default to **`-WhatIf`**.

| Script | Role | Default |
| --- | --- | --- |
| `CPKIG-Discovery.ps1` | Inventory certificate connectors, trusted-root profiles, and SCEP/PKCS profiles in the GCC High tenant; confirm Cloud PKI is not in use. | Read-only |
| `CPKIG-Validation.ps1` | Check that the named objects exist and are assigned to the pilot group, and that the connector is healthy; flag gaps. | Read-only |
| `CPKIG-Report.ps1` | Certificate coverage / connector-health / profile-assignment report for review. | Read-only |
| `CPKIG-Remediation.ps1` | Safely remediate detected gaps (e.g. create the pilot group). | **`-WhatIf`** |
| `CPKIG-Set-ScopeTargeting.ps1` | Build/adjust the pilot-scope group (`SG-CPKI-Pilot`) membership and profile targeting for staged expansion. | **`-WhatIf`** |

## Named objects (created and reused verbatim)

`SG-CPKI-Pilot` · trusted profile `Trust-Root-CA` · SCEP profile `SCEP-Device-ClientAuth` · PKCS
profile `PKCS-User-ClientAuth` · connector reference `CertConnector-01`.

## Outcome

A GCC High tenant issuing, trusting, renewing, and revoking device/user certificates through Intune
on the **supported** SCEP/PKCS-via-connector path — with the Cloud PKI parity gap explicitly handled,
read-only scripts to detect drift, and a documented migration to Cloud PKI once Microsoft ships it to
GCC High.

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
