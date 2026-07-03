# Deliverables Summary — Azure Virtual Desktop Remote Access (Azure Government / GCC High)

Everything included in this Government (Azure Government / GCC High) edition, and how the pieces fit together.

> This edition is authored for the US sovereign cloud: admin at **`portal.azure.us`**, clients at **`rdweb.wvd.azure.us`**, scripts on **`AzureUSGovernment`** / Graph **`USGov`**.

---

## Documents (source/)

| Document | What it gives you |
| --- | --- |
| `01-solution-overview.md` | What the solution delivers, the deployment model, and the **Commercial vs Azure Government — what's different** table (portals, feed URLs, endpoints, parity). |
| `02-requirements.md` | Ten solution-specific requirements (R1–R10), each **Description / Why / Verify / Implement**, layered on the Azure global requirements — including the Government endpoint allow-list. |
| `03-implementation.md` | Ordered click-to-implement steps in the Gov portals, **Assess → Configure → Pilot → Validate → Expand**, with GCC-High caveats inline and stage gates. |
| `05-testing.md` | Twelve pass/fail test cases (T1–T12) for Gate 4 and each expansion wave. |
| `06-troubleshooting.md` | Symptom → cause → fix for the common Gov-specific failures (wrong feed, blocked `.us` endpoints, join/MFA, parity). |
| `07-best-practices.md` | Operating guidance: sovereign-cloud discipline, identity, networking, profiles, management, change control, compliance. |
| `gcc-high-parity-notes.md` | Cited Commercial-vs-Azure-Government reference: portals, endpoints, and feature-parity gaps to verify. |
| `executive-summary.md` | One-page summary for decision-makers. |
| `global-requirements-azure-solutions.md` | Shared Azure platform baseline (G1–G6). *(Provided; not part of this authoring pass.)* |

## Scripts (scripts/)

All scripts connect to **US Gov** endpoints (`Connect-AzAccount -Environment AzureUSGovernment`; `Connect-MgGraph -Environment USGov`). Discovery, Validation, and Report are **read-only**; Remediation and Set-ScopeTargeting default to **`-WhatIf`**.

| Script | Purpose | Mode |
| --- | --- | --- |
| `AVDG-Discovery.ps1` | Snapshot the Gov tenant/subscription: provider registration, roles, AVD objects, session hosts, assignments. | Read-only |
| `AVDG-Validation.ps1` | Validate the deployment against pass/fail criteria, including Gov endpoint reachability. | Read-only |
| `AVDG-Report.ps1` | Produce a deployment report (inventory + pass/fail) for the change record. | Read-only |
| `AVDG-Remediation.ps1` | Fix common gaps (e.g., register the resource provider). | `-WhatIf` default |
| `AVDG-Set-ScopeTargeting.ps1` | Build/grow the assignment group in controlled waves. | `-WhatIf` default |

---

## How to use the set
1. **Assess** with `AVDG-Discovery.ps1` and `02-requirements.md`.
2. **Configure** per `03-implementation.md` in `portal.azure.us`.
3. **Pilot** — subscribe Windows/macOS clients to `rdweb.wvd.azure.us`.
4. **Validate** with `AVDG-Validation.ps1` + `05-testing.md`, capture `AVDG-Report.ps1`.
5. **Expand** in waves with `AVDG-Set-ScopeTargeting.ps1`, re-validating each wave.

Consult `gcc-high-parity-notes.md` whenever you rely on a specific feature, and `06-troubleshooting.md` when a step doesn't behave. Keep every change inside an approved window with a documented rollback (R10).
