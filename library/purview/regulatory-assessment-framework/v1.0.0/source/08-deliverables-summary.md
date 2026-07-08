# 8. Deliverables Summary — Regulatory Assessment Framework (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, the map-once/assess-many model, and what's in the box |
| 1. Solution Overview | What the framework is, how it works, the building blocks (assessments, improvement actions, control mapping, groups, evidence), the canonical control set + crosswalk model, the role-separation model, limitations, and the naming convention |
| 2. Requirements Guide | Every framework-specific prerequisite with Verify / Implement-if-missing (per-regulation template licensing, the canonical control set, the crosswalk, role separation, governance owners, the in-scope regulation set + group design, shared-control owners + evidence + automatic testing, toolchain, pilot regulation) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + PowerShell steps — baseline/inventory, define the control set, build the crosswalk, roles-with-separation, create the group + pilot regulation, implement + evidence shared controls, enable automatic testing, validate, report coverage, expand; applicability/adequacy deferred to compliance/legal |
| 5. Testing Guide | Validation procedures with pass/fail gates (separation, licensing, control set + crosswalk, assessment/ownership, map-once/assess-many, evidence accuracy, coverage matrix, safe defaults) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven, evidence-first, map-once recommendations |

## PowerShell scripts
| Script | Purpose | Default safety |
|---|---|---|
| `CMPFRAME-Discovery.ps1` | Readiness + **role-separation** + licensing assessment; prints the `RAF Roles – Separation Evidence` snapshot and the SKUs/entitlement that gate the regulation templates | **Read-only** |
| `CMPFRAME-Configuration.ps1` | **Crosswalk & shared-control-plan builder** — validates the canonical control set and control-to-regulation crosswalk and writes the local `RAF Crosswalk – Register` / `RAF Action Plan – Shared` / `RAF Evidence – Register` (no tenant writes; Compliance Manager is portal-managed) | **`-WhatIf`** (needs `-Commit`) |
| `CMPFRAME-Validation.ps1` | Collects the **technical evidence** behind automatable shared controls — unified audit, DLP/retention/label presence, Conditional Access/MFA — and reports pass/absent per signal | **Read-only** |
| `CMPFRAME-Report.ps1` | **Coverage-matrix rollup** — per-regulation coverage vs gap, shared-control leverage (regulations per control), evidence register, role separation, and licensing; notes the authoritative score/export is the portal | **Read-only** |
| `CMPFRAME-Set-Scope.ps1` | Role/health helper — manage Compliance Manager **role-group membership** for least-privilege separation | **`-WhatIf`** (needs `-Commit`) |

All scripts run through **Security & Compliance PowerShell** (`Connect-IPPSSession`) and/or **Microsoft
Graph** with interactive modern-auth; **no credentials or secrets are embedded**. `CMPFRAME-Configuration.ps1`
and `CMPFRAME-Set-Scope.ps1` are **safe-by-default** (`-WhatIf`) and only make a change when `-Commit` is
supplied. Compliance Manager itself is **portal-managed** — the scripts assess readiness, roles, licensing,
and the technical evidence behind shared controls and structure the crosswalk/coverage plan; they do not
create assessments, set action status, or push the crosswalk (there is no broad public write API for that).

## Artifacts this solution creates (naming convention)
| Artifact | Name |
|---|---|
| Canonical shared-control set | `RAF Control Set – Canonical` |
| Control-to-regulation crosswalk | `RAF Crosswalk – Register` |
| Multi-regulation assessment group | `RAF Group – <Program>` |
| Pilot regulation assessment | `RAF Assessment – <Regulation> – Pilot` |
| Production regulation assessment | `RAF Assessment – <Regulation> – Production` |
| Shared-control action plan | `RAF Action Plan – Shared` |
| Evidence register | `RAF Evidence – Register` |
| Cross-framework coverage matrix | `RAF Coverage – Matrix` |
| Automatic-testing setting | `RAF Automatic Testing – Setting` |
| Role-separation evidence snapshot | `RAF Roles – Separation Evidence` |
| Framework scope / owners record | `RAF Scope – Record` |

## Outcome
Many regulations assessed from **one shared-control framework** in Microsoft Purview — a canonical
control set mapped once via `RAF Crosswalk – Register`, scored across every regulation through control
mapping, with shared controls owned, tested, and evidenced **once** and reused across frameworks. The
**coverage matrix** shows, per regulation, what shared controls satisfy and the remaining gap;
**automatic testing** keeps technical shared controls current; **least-privilege separation** is
enforced. The capability is in place, validated, and audit-ready, with **regulatory applicability and
adequacy in the hands of compliance, records, privacy, and legal**.
