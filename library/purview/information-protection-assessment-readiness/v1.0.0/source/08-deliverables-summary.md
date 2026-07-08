# 8. Deliverables Summary — Information Protection Assessment & Readiness (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case: baseline posture, ranked gaps, a validated fix path |
| 1. Solution Overview | The posture-assessment method, the six dimensions assessed, pilot-in-simulation principle, what's authored vs. deferred |
| 2. Requirements Guide | Every assessment prerequisite with Verify / Implement-if-missing (category Purview GRs referenced, not duplicated) |
| Global Requirements (Purview) | Category-wide Purview prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal + S&C PowerShell + Graph steps: discover (read-only), score, build gap register, roadmap, pilot ONE fix in simulation, validate, hand off — pass/fail gates + rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Connectivity, licensing-gated visibility, scoring, and simulation-pilot issues by symptom → root cause |
| 7. Best Practices | Field-proven recommendations for a defensible assessment and an executable roadmap |

## PowerShell scripts (Security & Compliance PowerShell / Microsoft Graph)
| Script | What it does | Safety |
|---|---|---|
| `IPASSESS-ScopeHealth.ps1` | Scope/health helper: confirms `Connect-IPPSSession` / `Connect-MgGraph`, reports which capabilities (labels, DLP, auto-labeling, SITs) are readable, flags licensing-gated ones as "not available — verify your licensing/tenant" | Read-only |
| `IPASSESS-Discovery.ps1` | Posture inventory: sensitivity labels (with encryption/marking/scope), label policies (publish coverage), DLP policies + rules (Mode/Workload), auto-labeling policies (Mode), and — with `-IncludeSensitiveTypes` — sensitive information types; writes `Information Protection - Estate - Discovery` (CSV) | Read-only |
| `IPASSESS-PilotRemediation.ps1` | Validates ONE recommended fix in SIMULATION: creates an auto-labeling policy in `TestWithoutNotifications` mode (labels nothing) — or previews a pilot-group label publish | Default `-WhatIf`; `-Commit` creates a simulation-only object; never enforces |
| `IPASSESS-Validation.ps1` | Scores the estate against the readiness baseline (six dimensions) PASS/WARN/FAIL, and confirms the pilot object is in simulation mode with nothing enforced | Read-only |
| `IPASSESS-Report.ps1` | Builds `Information Protection - Gaps - Register` (`-Section GapRegister`) and the ranked `Information Protection - Roadmap - Scorecard` (`-Section Roadmap`) with a per-dimension posture scorecard | Read-only |

## What the buyer receives
- This assessment guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand.**

## Outcome
A measured, evidenced **information-protection posture** for Microsoft Purview — a discovery baseline, a
scored gap register, a prioritized roadmap and scorecard, and **one recommended fix proven in
simulation** — so leadership can see exactly where the estate stands and fund the ranked work to close
the gaps. Enforcement/expansion is change-controlled follow-on; regulatory/records/legal determinations
are deferred to the relevant governance functions.
