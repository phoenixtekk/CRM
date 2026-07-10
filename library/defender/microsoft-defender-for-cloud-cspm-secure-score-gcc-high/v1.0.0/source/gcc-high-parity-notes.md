# GCC High Parity Notes — Microsoft Defender for Cloud: CSPM & Secure Score Remediation

This document is specific to the **Government (GCC High)** edition of this solution. It records the
US Government national-cloud endpoints this solution uses, the feature-parity considerations that
differ from commercial Azure, and the compliance/data-residency context that motivates GCC High. It
does **not** assert availability or make an authorization decision — every version/preview/plan fact
must be **verified against current Microsoft Government documentation** for your specific cloud
(GCC High vs DoD/IL5), and accreditation determinations belong to your ISSO/compliance function.

## National cloud endpoints

| Purpose | Commercial (do **not** use here) | GCC High / Azure Government (use this) |
|---|---|---|
| Azure management portal | `portal.azure.com` | **`portal.azure.us`** (Azure Government) |
| Defender / unified security portal | `security.microsoft.com` | **`security.microsoft.us`** |
| Sign-in / token (Azure AD/Entra) | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft Graph | `graph.microsoft.com` | **`graph.microsoft.us`** (GCC High) — DoD/IL5 uses `dod-graph.microsoft.us`; **verify your cloud** |
| Azure Resource Manager | `management.azure.com` | `management.usgovcloudapi.net` (Az PowerShell selects this via `-Environment AzureUSGovernment`) |
| Az PowerShell cloud | `Connect-AzAccount` (AzureCloud) | **`Connect-AzAccount -Environment AzureUSGovernment`** |
| Microsoft Graph PowerShell | `Connect-MgGraph` | **`Connect-MgGraph -Environment USGov`** (DoD: `-Environment USGovDoD`) — this solution is Az-based, noted for cross-reference |

All five scripts (`DEFCSPMG-Discovery.ps1`, `DEFCSPMG-Validate.ps1`, `DEFCSPMG-Report.ps1`,
`DEFCSPMG-Enable-CSPM.ps1`, `DEFCSPMG-Hunt.ps1`) default their connection to
`Connect-AzAccount -Environment AzureUSGovernment`. If you authenticate manually, include that switch
or the Az context targets commercial Azure and returns nothing for a Gov tenant.

## Feature-parity considerations

GCC High and DoD frequently **lag commercial Azure** or lack features entirely. For this Defender for
Cloud CSPM solution, treat each of the following as **"verify against current Microsoft Government
documentation"** before you rely on it — do not assume parity, and do not invent availability:

- **Defender CSPM plan (CloudPosture) availability and pricing** — the paid Defender CSPM plan and its
  per-resource pricing may differ or arrive later in GCC High/DoD. *Verify current availability and
  pricing for your Gov tenant.*
- **Agentless machine/disk scanning** — snapshot-based agentless scanning may be delayed or region-
  constrained in the sovereign cloud. *Verify it is available and supported in your Azure Government
  region.*
- **Attack-path analysis & cloud security graph (risk hunting)** — these Defender CSPM capabilities may
  lag or behave differently in GCC High/DoD; `DEFCSPMG-Hunt.ps1 -Mode AttackPaths` may return nothing
  if the feature/graph is not yet available. *Verify.*
- **Data-aware security posture** — data-sensitivity discovery may be limited or unavailable. *Verify.*
- **AWS/GCP multicloud connectors** — cross-cloud connectors and the third-party clouds they reach are
  often **not** available (or restricted) from GCC High/DoD. Do not plan multicloud posture on the
  assumption it works; *verify connector support for Azure Government first.*
- **Regulatory-compliance standards catalog** — the set of built-in compliance standards offered in the
  regulatory-compliance dashboard can differ in Gov clouds (the Microsoft cloud security benchmark is
  generally present; government-specific standards vary). *Verify which standards are assignable.*
- **Preview features and newest capabilities** — anything in preview on commercial is likely **absent or
  later** in GCC High/DoD. Do not depend on preview features for a Gov deployment. *Verify.*
- **Continuous export / Log Analytics** — supported in Azure Government, but confirm the workspace and
  region are within your accreditation boundary. *Verify.*

## Compliance & data-residency context (why GCC High)

GCC High exists to keep regulated US Government and defense-industrial-base workloads inside a US-sovereign,
US-persons-operated boundary. Relevant context for this solution — provided as technical background, not
as an authorization:

- **FedRAMP High** — GCC High is designed to support FedRAMP High workloads; confirm the current
  authorization status and boundary for Defender for Cloud in your tenant.
- **DoD Impact Levels (IL4 / IL5)** — DoD workloads map to IL4/IL5 in Azure Government / GCC High-DoD.
  Whether this deployment falls in scope, and at which impact level, is your **ISSO/compliance
  determination**, not this guide's.
- **CMMC 2.0** — DIB contractors handling CUI use GCC High to help meet CMMC/NIST SP 800-171 control
  expectations. Posture management and Secure Score evidence support, but do not constitute, a CMMC
  assessment.
- **ITAR / EAR data-residency** — GCC High provides US-only data residency and US-persons support
  needed for ITAR/EAR-controlled technical data. Confirm your data-handling obligations with your
  compliance/legal function.
- **US-persons handling** — GCC High operations personnel are screened US persons; if this is a
  contractual requirement, confirm it applies to every service in scope.

**Boundary determinations** — the accreditation boundary, applicable impact level, which standards
apply, and whether a residual risk or exemption is acceptable — are the **customer's ISSO, compliance,
legal, and security functions'** decisions. This solution provides the technical posture-management
controls, scoring, and evidence, not the authorization.

## DoD (IL5) note

DoD tenants (GCC High-DoD / IL5) differ from GCC High in specific endpoints and availability:

- **Microsoft Graph host is `dod-graph.microsoft.us`** (not `graph.microsoft.us`). This solution is
  Az-based, but any Graph-adjacent tooling must target the DoD host — **verify your cloud**.
- **Graph PowerShell** uses `Connect-MgGraph -Environment USGovDoD`; **Az PowerShell** still uses
  `-Environment AzureUSGovernment` for both GCC High and DoD.
- **Feature availability can lag GCC High further** at IL5 (Defender CSPM plan features, agentless
  scanning, attack paths, multicloud). **Verify each against current Microsoft Government documentation
  for the DoD cloud** before relying on it.
