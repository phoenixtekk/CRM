# 8. Deliverables Summary — AI Data-Exposure Assessment (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What the assessment measures (AI access surface, reachability, priority risk, fix-path validation), the availability/licensing caveat, the assessment-vs-remediation boundary, the outcome-vs-determination boundary, and the naming convention |
| 2. Requirements Guide | Every exposure-assessment prerequisite with Verify / Implement-if-missing (licensing, least-privilege roles, auditing, labels+DLP baseline, Copilot/AI in scope, sharing signal, simulation discipline) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + PowerShell steps: confirm scope, discover the access surface, measure reachability, rank the priority risks, validate the fix in simulation, validate the evidence, hand off the baseline, set a re-assessment cadence |
| 5. Testing Guide | Validation procedures with explicit pass/fail and the simulation validation gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for measuring and ranking exposure safely |

## PowerShell scripts
All are safe-by-default (read-only, or `-WhatIf` / simulation unless `-Commit` — and even then simulation
only, never enforcing), use `Connect-IPPSSession` and/or `Connect-MgGraph`, and store **no** credentials.
| Script | What it does |
|---|---|
| `AIEXPOSE-ScopeCheck.ps1` | Read-only scope/health helper: confirms sign-in, reports whether **auditing** is on, enumerates the licensing-dependent controls (labels, DLP, auto-labeling), and probes for Copilot/AI interaction records. Writes `AIEXPOSE Scope Check – Estate – Assess`. Resolves Requirements 2.1–2.5 |
| `AIEXPOSE-Discovery.ps1` | Read-only discovery of the AI access surface **and** reachability. Inventories sensitivity labels, label policies, DLP policies/rules, auto-labeling policies (and, with `-IncludeSensitiveTypes`, the sensitive info types), then measures the AI/Copilot interaction activity and SharePoint/OneDrive broad-sharing signal from the audit log (RecordType/Operations parameterized). Writes `AI Access Scope – Estate – Discovery`, `Sensitive Exposure – Estate – Assess`, `AI Reachability – Copilot – Assess`, and `Oversharing Exposure – Sites – Assess` |
| `AIEXPOSE-RiskRegister.ps1` | Read-only reporting: scores and ranks the exposure findings (reachability breadth + no-lever penalty) into the prioritized `Exposure Risk Register – Estate – Rank`, each row with Score, Rationale, and suggested fix family. Reads only local CSVs |
| `AIEXPOSE-PilotRemediation.ps1` | Configuration/remediation fix-path validation helper. Defaults to `-WhatIf`; with `-Commit` creates an auto-labeling policy in **simulation** (`Exposure Remediation – Pilot – Simulation`, labels nothing), or produces the prioritized sharing-restriction target list — **never enforces** |
| `AIEXPOSE-Validate.ps1` | Read-only validation: confirms all expected exports exist and are consistent (scope check, discovery, reachability, oversharing, and a descending-ranked register) and that any pilot policy is in **simulation** mode. Writes `AIEXPOSE Validate – Estate – Assess` |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate) → Validate →
  Expand (enforce, handed off)**.

## Outcome
AI data exposure made **visible, quantified, and defensible**: the AI access surface inventoried, what
Copilot/AI could reach measured, the priority risks scored and ranked into a register, and the recommended
fix path validated in **simulation** — every step read-only or simulation, changing no content — so an
organization can make an informed, evidenced decision about AI adoption. Turning the validated fix into an
enforced reduction program is a scoped follow-on. Regulatory, records, and legal determinations remain with
the organization's governance functions; this solution delivers the technical method and the evidence.
