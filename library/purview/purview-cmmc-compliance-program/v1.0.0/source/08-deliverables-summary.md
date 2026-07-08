# 8. Deliverables Summary — Microsoft Purview CMMC Compliance Program

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What a Purview-backed CMMC program is — Compliance Manager, the CMMC Level 2 / NIST 800-171 template, control mapping, evidence — benefits, limitations, C3PAO boundary |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (licensing, cloud, roles, CUI boundary/SSP, owners) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal + PowerShell/Graph steps (baseline, roles, assessment, action plan + control map, automatic testing, validate, expand) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does | Safe default |
|---|---|---|
| `CMMC-Discovery.ps1` | Reports licensing SKUs, the Compliance Manager role-group membership (`CMMC Roles – Separation Evidence`), and audit-log readiness; flags admins who are also contributors | Read-only |
| `CMMC-Validation.ps1` | Confirms the underlying technical signals behind automatable NIST 800-171 actions (unified audit AU, MFA/Conditional Access AC/IA, DLP/retention/label/encryption MP/SC) | Read-only |
| `CMMC-Report.ps1` | `CMMC Score Posture – Report` — role separation, technical-signal coverage by family, licensing; notes the authoritative score/SPRS are separate | Read-only |
| `CMMC-Configuration.ps1` | Builds the local `CMMC Action Plan – Pilot`, `CMMC Control Map – NIST 800-171`, and `CMMC Evidence – Register` from the owner-provided list (no tenant write — Compliance Manager has no write API) | `-WhatIf` unless `-Commit` |
| `CMMC-Set-Scope.ps1` | Assigns/removes Compliance Manager role-group membership for least-privilege separation | `-WhatIf` unless `-Commit` |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP (read-only or `-WhatIf` by default; no credentials in
  code).
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate/test) →
  Validate → Expand**, with pass/fail gates, a documented rollback, and CMMC certification / assessment
  determinations deferred to the C3PAO and compliance/security/legal.

## Outcome
A **defensible, evidenced CMMC compliance program in Microsoft Purview** — the CMMC Level 2 / NIST
800-171 requirements mapped to configured controls and owned improvement actions, technical evidence
validated from the tenant, automatic testing where it applies, and a maintained posture report — proven
on a pilot assessment before you scale toward the C3PAO assessment. The certification determination
remains the assessor's; this delivers the program and the evidence that make it defensible.
