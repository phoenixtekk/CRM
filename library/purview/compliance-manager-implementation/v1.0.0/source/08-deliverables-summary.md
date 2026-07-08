# 8. Deliverables Summary — Microsoft Purview Compliance Manager Implementation

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, the measure-don't-enforce model, and what's in the box |
| 1. Solution Overview | What Compliance Manager is, how it works, the four building blocks (assessments, improvement actions, control mapping, evidence), the role-separation model, limitations, and the naming convention |
| 2. Requirements Guide | Every Compliance-Manager-specific prerequisite with Verify / Implement-if-missing (base + premium/custom licensing, role separation, governance owners, in-scope templates/grouping, action owners + evidence, automatic testing, toolchain, pilot) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + PowerShell steps — baseline the score, roles-with-separation, create the pilot assessment, build the action plan + evidence register, enable automatic testing, validate, expand; applicability/adequacy deferred to compliance/legal |
| 5. Testing Guide | Validation procedures with pass/fail gates (separation, licensing, assessment/ownership, evidence accuracy, control mapping, reporting, safe defaults) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven, evidence-first recommendations |

## PowerShell scripts
| Script | Purpose | Default safety |
|---|---|---|
| `CMPMGR-Discovery.ps1` | Readiness + **role-separation** + licensing assessment; prints the `CM Roles – Separation Evidence` snapshot and the SKUs it can read | **Read-only** |
| `CMPMGR-Configuration.ps1` | Improvement-action **plan & evidence-register builder** — validates the owner-provided action list and writes the local `CM Action Plan – Pilot` / `CM Evidence – Register` (no tenant writes; Compliance Manager is portal-managed) | **`-WhatIf`** (needs `-Commit`) |
| `CMPMGR-Validation.ps1` | Collects the **technical evidence** behind automatable improvement actions — unified audit, DLP/retention/label presence, Conditional Access/MFA — and reports pass/absent per signal | **Read-only** |
| `CMPMGR-Report.ps1` | **Score posture rollup** — action-status breakdown, evidence register, role separation, and licensing; notes the authoritative score/export is the portal | **Read-only** |
| `CMPMGR-Set-Scope.ps1` | Role/health helper — manage Compliance Manager **role-group membership** for least-privilege separation | **`-WhatIf`** (needs `-Commit`) |

All scripts run through **Security & Compliance PowerShell** (`Connect-IPPSSession`) and/or **Microsoft
Graph** with interactive modern-auth; **no credentials or secrets are embedded**. `CMPMGR-Configuration.ps1`
and `CMPMGR-Set-Scope.ps1` are **safe-by-default** (`-WhatIf`) and only make a change when `-Commit` is
supplied. Compliance Manager itself is **portal-managed** — the scripts assess readiness, roles, and the
technical evidence behind improvement actions and structure the action/evidence plan; they do not create
assessments or set action status (there is no broad public write API for that).

## Artifacts this solution creates (naming convention)
| Artifact | Name |
|---|---|
| Baseline assessment (pilot) | `CM Assessment – Baseline – Pilot` |
| Production assessment (per regulation) | `CM Assessment – <Regulation> – Production` |
| Improvement-action plan (pilot) | `CM Action Plan – Pilot` |
| Evidence register | `CM Evidence – Register` |
| Automatic-testing setting | `CM Automatic Testing – Setting` |
| Score posture report | `CM Score Posture – Report` |
| Role-separation evidence snapshot | `CM Roles – Separation Evidence` |
| Assessment scope / owners record | `CM Scope – Record` |

## Outcome
Compliance turned into a **measured, evidenced score** in Microsoft Purview — assessments created,
improvement actions owned and tested, control mapping leveraged, and evidence attached and defensible —
with **automatic testing** keeping technical actions current and **least-privilege separation** enforced.
The capability is in place, validated, and audit-ready, with **regulatory applicability and adequacy in
the hands of compliance, records, privacy, and legal**.
