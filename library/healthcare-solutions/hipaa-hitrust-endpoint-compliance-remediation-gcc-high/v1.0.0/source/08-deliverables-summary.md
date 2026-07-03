# 8. Deliverables Summary — HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender) — Government (GCC High)

This solution ships as a documentation set plus a script toolkit, authored for the **US sovereign cloud
(GCC High)**. Together they let an administrator map the controls, build and gate the enforcement,
remediate vulnerabilities, and produce audit-ready evidence on clinical Windows endpoints — using the
**`.us` portals**, **US Gov service endpoints**, and **US Gov Microsoft Graph**.

> The deliverables provide **technical enforcement and evidence** on a sovereign tenant. They do not
> constitute HIPAA compliance or HITRUST certification — those require organizational policy, risk
> analysis, training, BAAs, physical safeguards, and authorized assessment.

## Documentation

| # | Document | Purpose |
|---|---|---|
| 1 | **Solution Overview** (`01-solution-overview.md`) | What the solution does on GCC High, scope, outcomes, the portal table, and the **Commercial vs GCC High — what's different** section. |
| 2 | **Requirements** (`02-requirements.md`) | Solution-specific prerequisites R1–R12 tuned for GCC High (US Gov licensing, Defender-for-GCC-High onboarding, Entra ID P1, BitLocker hardware, the `HIPAA – Clinical Endpoints` group, evidence store, change control) with verify/implement steps on the `.us` portals. |
| 3 | **Global Requirements — Healthcare Solutions** (`global-requirements-healthcare-solutions.md`) | Category-wide tenant/identity/network/data-handling baseline (GR1–GR9), applied on the sovereign portals. |
| 4 | **Implementation** (`03-implementation.md`) | Phase-by-phase build (Assess → Configure → Gate → Remediate → Evidence → Operate) with full `.us` navigation paths, named objects, and GCC-High caveats inline where they matter. |
| 5 | **Testing & Validation** (`05-testing.md`) | Gates 0–6 (on GCC High cloud, Compliant, CA blocks, safeguards enforced, exposure reduced, evidence produced) with expected results and evidence. |
| 6 | **Best Practices** (`07-best-practices.md`) | Operating guidance for a sovereign tenant: `.us` hygiene, naming/traceability, policy design, CA rollout, TVM, evidence, change control. |
| 7 | **Troubleshooting** (`06-troubleshooting.md`) | Common failure modes and fixes, including a dedicated **GCC High wrong-cloud / endpoint** section. |
| 8 | **Executive Summary** (`executive-summary.md`) | Business-level summary for decision-makers. |
| 9 | **GCC High Parity Notes** (`gcc-high-parity-notes.md`) | The **cited** Commercial-vs-GCC High/DoD parity reference — portals, API/Graph URIs, licensing, connectivity, and the Intune + Defender feature gaps that change the design. |

## Scripts (PowerShell, Microsoft Graph — US Gov `-Environment USGov`)

All scripts use the **`HIPAACOMPG-`** prefix, carry the standard header block, connect to **US Gov
Graph** (`graph.microsoft.us`), and default to read-only. Change scripts default to **`-WhatIf`**.

| # | Script | What it does |
|---|---|---|
| 1 | **`HIPAACOMPG-Discovery.ps1`** | Tenant readiness on GCC High: confirms the session is on **USGov**, then the named compliance policy + configuration baselines, Defender onboarding readiness, the CA gate, and BitLocker state. Read-only. |
| 2 | **`HIPAACOMPG-Validation.ps1`** | Per-device validation: compliant, encrypted, key safeguards present. Emits **PASS/FAIL**. Read-only. |
| 3 | **`HIPAACOMPG-Report.ps1`** | Consolidated audit evidence (compliance state + exposure context + safeguard status) to **CSV** for the sovereign evidence repository. Read-only. |
| 4 | **`HIPAACOMPG-Remediation.ps1`** | Safe remediation: assigns `HIPAA – Clinical Endpoints` to any policy missing it. Defaults to **`-WhatIf`**; applies only with `-WhatIf:$false -Confirm:$false`. |
| 5 | **`HIPAACOMPG-Set-ScopeTargeting.ps1`** | Creates/ensures the `HIPAA – Clinical Endpoints` scope group and applies an Intune **scope tag** to the named policies. Defaults to **`-WhatIf`**. |

## Visual asset

- **`HIPAACOMPG-hero.png`** — hero image for the solution listing.

## How the deliverables fit together

1. Read the **Requirements**, **Global Requirements**, and **GCC High Parity Notes**; close gaps on the
   `.us` portals.
2. Run **`HIPAACOMPG-Discovery.ps1`** to confirm you are on **USGov** and baseline tenant readiness.
3. Follow the **Implementation** to build the named compliance policy, configuration baselines (BitLocker,
   lock, AV, firewall, Update ring, access), and the CA gate; then run the Defender TVM remediation
   workflow. Use **`HIPAACOMPG-Set-ScopeTargeting.ps1`** to ensure the scope group and scope tags.
4. Validate with the **Testing** gates using **`HIPAACOMPG-Validation.ps1`**.
5. Produce evidence with **`HIPAACOMPG-Report.ps1`**; remediate drift with **`HIPAACOMPG-Remediation.ps1`**
   (`-WhatIf` then apply).
6. Operate continuously per **Best Practices**, using **Troubleshooting** as needed.
