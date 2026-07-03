# Deliverables Summary — Government / GCC High edition

Everything included in the **Government (GCC High / DoD)** edition of *DISA STIG Compliance for Windows 10 & 11 in Microsoft Intune*, and what each piece is for.

## Documents (`source/`)

| Document | Purpose |
| --- | --- |
| **01-solution-overview.md** | What the solution is, the problem it solves, and a **Commercial vs GCC High / DoD — what's different** table (portals, Graph, parity). Names the reusable objects and the deployment model. |
| **02-requirements.md** | Every prerequisite with **verify** + **implement-if-missing**, GCC-High/DoD-specific (Gov tenant, Gov licensing, sovereign portal access, Gov endpoints, Graph US Gov, DISA benchmark, Advanced Analytics). Restates global requirements only where the sovereign cloud changes them. |
| **03-implementation.md** | Click-by-click ordered steps in the **`*.us`** portals, gated **Assess → Configure → Pilot → Validate → Expand**, with GCC-High/DoD caveats inline. |
| **05-testing.md** | Pass/fail **gate** criteria for each phase, plus a pre-flight "am I in the right cloud" test and maintenance/regression testing. |
| **06-troubleshooting.md** | Symptom-first fixes, rooted in the three common GCC High failure modes (wrong cloud/URL, SSL-inspected `*.us` endpoints, assuming Commercial-only features). |
| **07-best-practices.md** | Operating principles: sovereign-cloud discipline, STIG content governance, object hygiene, safe change management. |
| **gcc-high-parity-notes.md** | **Cited** Commercial-vs-GCC-High/DoD reference — portals, Graph environments, endpoints, supported/planned/unavailable features, and the STIG audit baseline — each pinned to a Microsoft US Gov source, all flagged **"verify for GCC High/DoD."** |
| **executive-summary.md** | One-page, decision-maker framing of value, risk, and outcome. |
| **08-deliverables-summary.md** | This inventory. |
| *global-requirements-intune-solutions.md* | Category-level prerequisites (provided; not authored here). |

## Scripts (`scripts/`)

All five connect to **US Gov Microsoft Graph** and support **`-Environment USGov`** (GCC High) and **`-Environment USGovDoD`** (DoD). The read-only three make **no changes**; the two change-making scripts default to **`-WhatIf`**.

| Script | Type | Purpose |
| --- | --- | --- |
| **STIGG-Discovery.ps1** | Read-only | Inventories existing configuration/ADMX/custom profiles, compliance policies, security baselines, and target groups so you don't collide or duplicate before configuring. |
| **STIGG-Validation.ps1** | Read-only | Confirms assignments match the intended object set; flags conflicts, drift, and unassigned profiles at each gate. |
| **STIGG-Report.ps1** | Read-only | Emits a JSON/CSV **evidence** artifact of profile/compliance/baseline state for a target group — the audit record for Validate and each Expand wave. |
| **STIGG-Remediation.ps1** | **Change (default `-WhatIf`)** | Previews then (with `-WhatIf:$false`) applies approved fixes for drifted/misassigned objects. |
| **STIGG-Set-ScopeTargeting.ps1** | **Change (default `-WhatIf`)** | Previews then applies group creation and profile/policy **assignment** (pilot → prod waves) in bulk. |

## What is deliberately **not** included

- **DISA STIG rule content** — rule IDs, CCIs, severities, check/fix text. These are authored by **DISA** and obtained from the **DoD Cyber Exchange** (`public.cyber.mil`) and read in **STIG Viewer**. This solution supplies the **Intune delivery and validation mechanism**, and a rule→setting mapping method — not the rules themselves.
- **Tenant secrets** — no tokens, keys, or credentials are shipped or required to be embedded; scripts authenticate interactively to US Gov Graph.

## How the pieces work together

1. **Read** `01`/`02`, satisfy requirements, sign in to **`intune.microsoft.us`**.
2. **Assess** with `STIGG-Discovery.ps1` and the DISA benchmark (STIG Viewer).
3. **Configure** objects per `03` (Settings Catalog / ADMX / custom + compliance + optional audit baseline).
4. **Pilot → Validate** with `STIGG-Validation.ps1` + `STIGG-Report.ps1` against `SG-STIG-Pilot-Devices`, passing each **gate** in `05`.
5. **Expand** in waves with `STIGG-Set-ScopeTargeting.ps1` and `STIGG-Remediation.ps1` (both `-WhatIf` first), re-validating per wave.
6. **Sustain** per `07` and re-pilot on each DISA benchmark update.

Every step runs in the **sovereign `*.us`** cloud with **`-Environment USGov`/`USGovDoD`**, with parity gaps handled per **`gcc-high-parity-notes.md`**.
