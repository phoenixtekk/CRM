# Deliverables Summary — Device Compliance Policies (Government / GCC High edition)

Everything included in this solution and how the pieces fit together. All scripts connect to
**US Gov Microsoft Graph** with **`-Environment USGov`** (use `USGovDoD` for DoD).

## Documents

| File | Purpose |
| --- | --- |
| `executive-summary.md` | One-page business case for the GCC High edition. |
| `01-solution-overview.md` | What the solution does, the **Commercial vs GCC High** map, deployment model, object naming. |
| `02-requirements.md` | Prerequisites in sovereign-cloud form (verify/implement) + Assess exit gate. |
| `03-implementation.md` | Click-by-click build in `intune.microsoft.us`, with parity caveats inline and stage gates. |
| `05-testing.md` | Seven pass/fail validation tests, including the DHA parity check. |
| `06-troubleshooting.md` | GCC-High-specific symptoms, causes, and fixes. |
| `07-best-practices.md` | Hygiene, design, parity handling, safe rollout, evidence. |
| `gcc-high-parity-notes.md` | **Cited** Commercial-vs-GCC-High reference (the source of truth for parity claims). |
| `08-deliverables-summary.md` | This file. |
| `global-requirements-intune-solutions.md` | Category-level prerequisites (G1–G7) shared by all Intune solutions. |

## Scripts (`scripts/`)

| Script | Type | What it does |
| --- | --- | --- |
| `DCPG-Discovery.ps1` | Read-only | Inventories device compliance policies, their assignments, and noncompliance actions in the GCC High tenant. Baseline before you build. |
| `DCPG-Validation.ps1` | Read-only | Pass/fail checks that the named objects (`CP-Win-Baseline-GovHigh`, `SG-Compliance-Pilot`, `MT-Compliance-Noncompliant-GovHigh`) exist and are pilot-scoped, and that you're on `USGov`. |
| `DCPG-Report.ps1` | Read-only | Per-device compliance rollup (compliant / noncompliant / counts) for status reporting and audit evidence. |
| `DCPG-Remediation.ps1` | **Default `-WhatIf`** | Previews and (with `-Commit`) applies safe corrective actions — e.g. re-scoping a policy off All-devices back to the pilot group, or attaching the noncompliance notification. |
| `DCPG-Set-ScopeTargeting.ps1` | **Default `-WhatIf`** | Builds/grows the pilot and wave security groups and previews assignment changes; applies only with `-Commit`. |

## How the deliverables map to the deployment stages

| Stage | Documents | Scripts |
| --- | --- | --- |
| **Assess** | `02-requirements.md`, `gcc-high-parity-notes.md` | `DCPG-Discovery.ps1` |
| **Configure** | `03-implementation.md` §1 | `DCPG-Validation.ps1` |
| **Pilot** | `03-implementation.md` §2, `05-testing.md` | `DCPG-Set-ScopeTargeting.ps1` |
| **Validate** | `05-testing.md`, `06-troubleshooting.md` | `DCPG-Validation.ps1`, `DCPG-Report.ps1` |
| **Expand** | `03-implementation.md` §4, `07-best-practices.md` | `DCPG-Set-ScopeTargeting.ps1`, `DCPG-Remediation.ps1` |

## Named objects (reused throughout)

- `SG-Compliance-Pilot` — Entra pilot security group.
- `CP-Win-Baseline-GovHigh` — Windows baseline compliance policy.
- `MT-Compliance-Noncompliant-GovHigh` — noncompliance email notification.
- `CA-Require-Compliant-GovHigh` — Conditional Access gate (require compliant device).

## Running the scripts

```
powershell -ExecutionPolicy Bypass -File .\DCPG-Discovery.ps1
```

Each script connects with `-Environment USGov`, prompts for the Graph scopes it needs, and
(for Discovery/Validation/Report) makes **no changes**. `DCPG-Remediation.ps1` and
`DCPG-Set-ScopeTargeting.ps1` default to **`-WhatIf`** — review the previewed plan, then re-run
with **`-Commit`** to apply.
