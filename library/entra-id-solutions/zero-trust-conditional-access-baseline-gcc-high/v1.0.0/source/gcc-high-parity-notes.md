# GCC High Parity Notes — Zero Trust Conditional Access Baseline & Rollout

This document is specific to the **Government (GCC High)** edition of this solution. It records the
US Government national-cloud endpoints this Conditional Access baseline uses, the feature-parity
considerations that differ from commercial Entra, and the compliance/data-residency context — framed
around the federal Zero Trust mandate — that motivates GCC High. It does **not** assert availability or
make an authorization decision: every version/preview/plan fact must be **verified against current
Microsoft Government documentation** for your specific cloud (GCC High vs DoD/IL5), and accreditation
determinations belong to your ISSO/compliance function.

## National cloud endpoints

| Purpose | Commercial (do **not** use here) | GCC High / Azure Government (use this) |
|---|---|---|
| Entra / Azure AD admin | `entra.microsoft.com` / `portal.azure.com` | **`portal.azure.us` → Microsoft Entra ID** (Azure Government) — *verify the current GCC High Entra admin-center URL for your tenant* |
| Microsoft 365 admin center | `admin.microsoft.com` | **`portal.office365.us`** (GCC High) — *verify current URL* |
| Sign-in / token (Entra) | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft Graph | `graph.microsoft.com` | **`graph.microsoft.us`** (GCC High) — DoD/IL5 uses `dod-graph.microsoft.us`; **verify your cloud** |
| Graph PowerShell SDK cloud | `Connect-MgGraph` (Global) | **`Connect-MgGraph -Environment USGov`** (DoD/IL5: **`-Environment USGovDoD`**) |

All five scripts (`ENTZTCAG-Discovery.ps1`, `ENTZTCAG-Validate.ps1`, `ENTZTCAG-Report.ps1`,
`ENTZTCAG-Set-Baseline.ps1`, `ENTZTCAG-Set-ScopeTargeting.ps1`) connect with
`Connect-MgGraph -Environment USGov`. `ENTZTCAG-Set-ScopeTargeting.ps1` builds group-member `@odata.id`
bind references from the connected environment's Graph endpoint (so it uses `graph.microsoft.us` in
GCC High and `dod-graph.microsoft.us` in DoD automatically). For a DoD/IL5 tenant, change the
`-Environment` value to `USGovDoD` in each script's `Connect-MgGraph` line.

## Feature-parity considerations

GCC High and DoD frequently **lag commercial Entra** or differ in availability. For this Conditional
Access baseline, treat each of the following as **"verify against current Microsoft Government
documentation"** before you rely on it — do not assume parity, and do not invent availability:

- **Risk-based Conditional Access — `CA004` (sign-in risk) and `CA005` (user risk)** — these depend on
  **Microsoft Entra ID P2 / Identity Protection**. Identity Protection availability, risk-signal
  fidelity, and specific risk conditions **may lag or differ in GCC High/DoD** even where a P2
  (Government) SKU is licensed. **Verify** before designing around them; if unavailable, compensate with
  the non-risk controls (`CA001` MFA + `CA003` compliant/hybrid device everywhere) and note the gap.
- **Authentication strengths (`CA002` phishing-resistant MFA)** — the built-in authentication-strength
  definitions and the exact strength id can differ in the sovereign cloud. **Verify** the
  `Phishing-resistant MFA` strength exists and confirm its id in `ENTZTCAG-Set-Baseline.ps1` matches
  your tenant. (Phishing-resistant MFA is the M-22-09 core requirement — prioritize it.)
- **Device controls (`CA003` compliant / hybrid Entra-joined device)** — depend on **Intune** device
  compliance and/or Entra hybrid join being available and configured in your Gov tenant. **Verify**
  the device signal is present before enforcing.
- **Continuous access evaluation, token protection, and newer session controls** — these and other
  preview or recently-GA capabilities are commonly **delayed or absent** in GCC High/DoD. Do not depend
  on a preview control for a Gov deployment. **Verify.**
- **What-If and Insights & reporting (report-only workbook)** — supported in Azure Government; confirm
  the Log Analytics workspace backing "Insights and reporting" is within your accreditation boundary.
  **Verify.**
- **Workload-identity Conditional Access** (for service accounts) — licensing and availability differ;
  **verify** before planning to govern workload identities with dedicated CA rather than exclusions.

The **report-only-first, break-glass-excluded, wave-based** rollout method is identical to commercial —
no parity concern there. It is the *feature availability* behind individual policies that must be
verified for the sovereign cloud.

## Compliance & data-residency context (why GCC High — and the Zero Trust mandate)

GCC High exists to keep regulated US Government and defense-industrial-base workloads inside a
US-sovereign, US-persons-operated boundary. This Conditional Access baseline is how the federal Zero
Trust mandate is operationalized at the identity plane. Context provided as background, not as an
authorization:

- **OMB M-22-09 — "Moving the U.S. Government Toward Zero Trust Cybersecurity Principles"** — directs
  federal agencies to a Zero Trust architecture and specifically requires **phishing-resistant MFA** for
  staff, contractors, and partners, aligned to the **CISA Zero Trust Maturity Model** and **NIST
  SP 800-207**. The baseline's `CA001` (MFA), `CA002` (phishing-resistant MFA for admins), and `CA007`
  (block legacy auth) are direct implementations of these requirements.
- **CMMC 2.0 / NIST SP 800-171** — DIB contractors handling CUI face parallel access-control and MFA
  expectations (AC and IA control families). This baseline supports, but does not by itself constitute,
  a CMMC assessment.
- **FedRAMP High** — GCC High is designed to support FedRAMP High workloads; confirm the current
  authorization status and boundary for Entra Conditional Access / Identity Protection in your tenant.
- **DoD Impact Levels (IL4 / IL5)** — DoD workloads map to IL4/IL5 in GCC High-DoD; whether this
  deployment is in scope and at which impact level is your **ISSO/compliance determination**.
- **ITAR / EAR data-residency and US-persons handling** — GCC High provides US-only data residency and
  screened US-persons operations required for ITAR/EAR-controlled technical data; confirm your
  data-handling obligations with your compliance/legal function.

**Boundary determinations** — the accreditation boundary, applicable impact level, which apps are
"sensitive," which users are "privileged," how strict guest access must be, and whether a residual risk
or exclusion is acceptable — are the **customer's ISSO, compliance, legal, and security functions'**
decisions. This solution delivers the Zero Trust access controls, the report-only evidence, and the
rollout method — not the authorization.

## DoD (IL5) note

DoD tenants (GCC High-DoD / IL5) differ from GCC High in specific endpoints and availability:

- **Microsoft Graph host is `dod-graph.microsoft.us`** (not `graph.microsoft.us`), and the Graph
  PowerShell environment is **`Connect-MgGraph -Environment USGovDoD`**. Change the `-Environment` value
  in each script's `Connect-MgGraph` line for a DoD tenant; `ENTZTCAG-Set-ScopeTargeting.ps1` then
  resolves the DoD Graph host for bind references automatically.
- **Feature availability can lag GCC High further at IL5** — Identity Protection / risk-based CA,
  authentication strengths, and preview session controls in particular. **Verify each against current
  Microsoft Government documentation for the DoD cloud** before relying on it.
