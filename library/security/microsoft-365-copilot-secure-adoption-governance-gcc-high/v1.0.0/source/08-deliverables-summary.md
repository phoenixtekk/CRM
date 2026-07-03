# Deliverables Summary — Microsoft 365 Copilot Secure Adoption & Governance (GCC High)

Everything included in the Government (GCC High) edition, and how the pieces fit together.

## Documents

| Document | What it covers |
| --- | --- |
| **Solution Overview** (`01-solution-overview.md`) | What the solution does; **Commercial vs GCC High — what's different**; the Copilot-availability caveat (GA in GCC High, Dec 2025); named objects; deployment model |
| **Requirements Guide** (`02-requirements.md`) | Every prerequisite — GCC High tenant, G3/G5 Gov licensing + Copilot add-on, roles, sovereign portal access, US Gov endpoints, Graph `-Environment USGov`, CUI label taxonomy — each with Verify / Implement |
| **Implementation Guide** (`03-implementation.md`) | Ordered click-by-click on the `*.us` portals: Assess → Configure (labels, DLP, Restricted SharePoint Search, remediation) → Pilot → Validate → Expand, with GCC-High caveats inline |
| **Testing Guide** (`05-testing.md`) | Pass/fail suites: governance posture, oversharing behavior (the core proof), parity expectations, evidence report |
| **Troubleshooting Guide** (`06-troubleshooting.md`) | GCC-High-specific gotchas — wrong environment, wrong portal, RSS availability, licensing, web grounding, agent limits |
| **Best Practices** (`07-best-practices.md`) | Govern-before-grant, sovereign-surface discipline, respecting parity gaps, gated rollout, ongoing hygiene |
| **GCC High Parity Notes** (`gcc-high-parity-notes.md`) | **Cited** reference for every Commercial-vs-GCC-High difference |
| **Executive Summary** (`executive-summary.md`) | One-page leadership brief |

## PowerShell scripts (`scripts/`)

All scripts connect to **US Gov Microsoft Graph** (`-Environment USGov`). Discovery, Validation, and
Report are **read-only**. Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview only)
and require an explicit, deliberate apply.

| Script | Purpose | Safety |
| --- | --- | --- |
| `COPILOTG-Discovery.ps1` | Enumerate oversharing exposure, unlabeled sites, OneDrive sharing, Copilot license assignments | Read-only |
| `COPILOTG-Validation.ps1` | Pass/fail checks: RSS on & scoped, CUI label published, DLP enforced, license scope, allow-list hygiene | Read-only |
| `COPILOTG-Report.ps1` | Consolidated evidence report (posture + validation) for change record / sign-off | Read-only |
| `COPILOTG-Remediation.ps1` | Flag/remove broadly-shared sites from the allow-list, sites missing labels | **-WhatIf by default** |
| `COPILOTG-Set-ScopeTargeting.ps1` | Build/populate `SG-COPILOTG-Pilot` / `SG-COPILOTG-Wave2` for staged rollout | **-WhatIf by default** |

## How they work together

1. **Discovery** establishes the baseline (Assess).
2. **Remediation** (preview → apply) and the portal steps close the gaps (Configure).
3. **Set-ScopeTargeting** builds the pilot group; you license it (Pilot).
4. **Validation** + **Report** prove the guardrails hold (Validate) — the gate before you **Expand**.

## Named objects (used consistently across all deliverables)

- `SG-COPILOTG-Pilot`, `SG-COPILOTG-Wave2` — staged-rollout security groups
- `DLP-COPILOTG-CUI` — DLP policy keyed to the CUI sensitivity label
- `Copilot Search Allowed Sites` — Restricted SharePoint Search allow-list
- CUI sensitivity label — **your organization's mandated taxonomy** (placeholder shown as
  `CUI//BASIC`)

## Definition of done

Discovery baseline captured; guardrails configured on the `*.us` portals; pilot licensed to
`SG-COPILOTG-Pilot`; Validation all-pass and oversharing spot-check confirms no leakage; Report
attached to the change ticket; parity gaps recorded as observed. Then, and only then, expand.
