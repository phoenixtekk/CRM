# 8. Deliverables Summary — Microsoft Defender for Identity

## Documentation (source/)
| Document | Purpose |
|---|---|
| Executive Summary | Business case, the end-to-end outcome, the boundary, and effort |
| 1. Solution Overview | What MDI is — sensors, DSA, honeytokens, sensitive tags, ISPM, detections, the operator console, and how a safe PoC proves it; the three phases; benefits, limitations |
| 2. Requirements Guide | Solution-specific prerequisites (deploy, enable, prove) with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | One continuous playbook — Phase A Deploy (DSA, pilot sensor, tags, honeytokens, ISPM, validate), Phase B Enable (five labs), Phase C Prove (guided PoC), then Expand |
| 5. Testing Guide | Phase-A deploy tests, the Phase-B knowledge-check + capstone, and Phase-C PoC tests, each with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation across all three phases |
| 7. Best Practices | Field-proven recommendations and where to go next |

## Automation assets (scripts/)
| Asset | What it does |
|---|---|
| `MDIFULL-Discovery.ps1` | Read-only readiness (Microsoft Graph Security + AD helpers) — MDI activation/workspace, plan hints, admin roles, every domain controller and OS, DSA readiness, existing sensor health, and candidate no-activity honeytoken accounts. Makes no changes |
| `MDIFULL-Deploy.ps1` | `-WhatIf`-gated change helper — tags sensitive entities (`-Mode SensitiveTag`) and honeytokens (`-Mode Honeytoken`); `-Rollback` guides the clean teardown of the PoC-only scope. Safe preview by default; applies only with `-Apply` |
| `MDIFULL-Validate.ps1` | Read-only validation (`-Check DSA\|Sensor\|Sensitive\|Honeytoken\|Signal\|All`) — confirms the DSA, sensor health, sensitive/honeytoken tags, and (via `MDI Detection Validation – Tenant – Validate`) that the identity tables stream and a test detection is visible |
| `MDIFULL-TestSignal.ps1` | **Benign** PoC test-signal generator — runs harmless read-only directory enumeration and touches the honeytoken (no attack tooling, ever); `-WhatIf` previews |
| `MDIFULL-Report.ps1` | Read-only posture/coverage report — sensor health, Identity Secure Score / ISPM recommendations, baseline drift (`-SaveBaseline`), response-action posture; `-Scorecard` maps PoC observations to your criteria and writes `MDI PoC Scorecard – Pilot DC – Validate` |
| `MDIFULL-LabQueries.kql` | Advanced-hunting KQL pack for the labs and detection validation — recon, lateral movement, honeytoken activity, suspicious-auth volume, single-account investigation, and identity-context queries over the `Identity*` tables |

## Take-home artefacts (produced during the engagement)
- Saved hunting queries: `Recon – Identity – Hunt`, `LateralMovement – Identity – Hunt`, `Honeytoken – Identity – Hunt`, `Investigation – Identity – Hunt`, and `MDI Detection Validation – Tenant – Validate`.
- The honeytoken tag `MDI Honeytoken – Decoy Identity – Pilot` and the sensitive-entity tag `MDI Sensitive Entities – Tier0 – Prod`.
- The `MDI ISPM Shortlist – Tier0 – Prod` remediation shortlist.
- The `MDI Investigation – Identity – Validate` findings document.
- The `MDI PoC Scorecard – Pilot DC – Validate` decision record.

## What the buyer receives
- This solution as a **Word** document and **PDF**.
- All six **automation assets** (five PowerShell scripts with embedded KQL, plus the standalone KQL pack) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — deploy the pilot sensor, enable the team, prove the value, and expand, with response actions kept approval-gated until trusted.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A fully sensored, team-ready, value-proven Defender for Identity delivering ITDR — sensors healthy on every domain controller, the DSA configured, honeytokens planted and Tier-0 tagged, ISPM triaged, detections proven to fire, a team that can investigate unaided, and a scorecard the business can stand behind — the whole lifecycle in one package.
