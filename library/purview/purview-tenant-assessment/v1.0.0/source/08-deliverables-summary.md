# 8. Deliverables Summary — Microsoft Purview Tenant Assessment

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What a Purview tenant assessment is, the 11 capabilities it covers, how findings and priorities are produced, honest limitations, and the naming convention. |
| **2. Requirements Guide** | Assessment-specific prerequisites (licensing across capabilities, least-privilege **reader** roles, S&C/Exchange + Graph toolchain, confirmed capability inventory, write roles + pilot only if remediating) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: preflight, inventory every enabled capability, design the findings/priority scheme, produce the register/scorecard, apply safe quick-win fixes simulation-first, validate, readout & track — pilot-first with pass/fail gates and rollback. |
| **5. Testing & Validation** | Ten gates from "preflight clean" to "readout delivered & backlog owned," each with method / pass / fail action. |
| **6. Troubleshooting** | Why a capability reads empty (permissions vs genuinely empty vs portal-only), licensing/latency effects, remediation and rollback issues — and their fixes. |
| **7. Best Practices** | Assess the whole estate, don't let a permission gap look like a coverage gap, be honest about portal-only capabilities, prioritize by risk, fix simulation-first, keep the governance line bright, re-run as a baseline. |

## PowerShell tools (5)
All discovery/validation/report tools are **read-only**; the remediation tool runs **`-WhatIf` by
default** and writes only on `-Commit`, always simulation/test/pilot-first. No credentials or secrets are
embedded. Labels/DLP/retention/eDiscovery reads use **Security & Compliance PowerShell**
(`Connect-IPPSSession`); audit uses **Exchange Online PowerShell** (`Connect-ExchangeOnline`);
licensing/roles use **Microsoft Graph**. Portal-only capabilities are flagged for manual review.

| Script | Role | Default |
|---|---|---|
| `PURVASSESS-Scope.ps1` | Scope/health helper: licensing signals, per-capability read/role check, endpoint connectivity preflight. | Read-only |
| `PURVASSESS-Discovery.ps1` | Assess: inventory every enabled capability's configuration; tag each enabled / not enabled / not licensed / portal-only. | Read-only |
| `PURVASSESS-Remediate.ps1` | Configure/Remediate the safe quick wins (DLP→simulation, auto-label→simulation, enable disabled retention, enable unified audit) — simulation/test/pilot-first, with `-Revert`. | `-WhatIf` (writes on `-Commit`) |
| `PURVASSESS-Validate.ps1` | Validate: re-read the remediated capabilities and confirm each fix reached its target state. | Read-only |
| `PURVASSESS-Report.ps1` | Report: build the findings register, priority matrix (P1/P2/P3), and per-capability scorecard from the inventory. | Read-only |

## Named artifacts produced
- Findings register: `Purview Assessment – Tenant – Findings`.
- Priority matrix: `Purview Assessment – Priorities – P1P2P3`.
- Capability scorecard: `Purview Assessment – Capabilities – Scorecard`.
- Remediation pilot scope: `Purview Assessment – Remediation Pilot – Stage1`.
- Executive readout: `Purview Assessment – Tenant – Readout`.

## Definition of done
- **Preflight clean** — licensing, reader roles, and endpoints confirmed; no permission gap masking a coverage gap.
- **Every enabled capability inventoried** — each of the 11 tagged enabled / not enabled / not licensed / portal-only, nothing silently skipped.
- **Findings register complete and prioritized** — each finding with capability, observation, evidence source, risk, recommendation, and P1/P2/P3.
- **Scorecard** reflects the inventory; **readout** delivered and walked with stakeholders.
- **Safe quick-win fixes** applied simulation/test/pilot-first, **validated green**, with rollback recorded.
- **Non-remediated findings** routed as a governed backlog (governance decision / build engagement / deferred) with owners, and the **re-baseline cadence scheduled**.

> **Boundary:** this solution delivers the technical assessment, prioritized findings, and safe
> stabilization. **Whether a policy is correct — retention durations, a rule's regulatory sufficiency,
> whether a capability is required, any records or legal-hold obligation — is deferred to your
> compliance, records, privacy, and legal functions.** Capability availability is
> **licensing-/tenant-dependent and evolving — verify against your entitlements and current Microsoft
> documentation.**
