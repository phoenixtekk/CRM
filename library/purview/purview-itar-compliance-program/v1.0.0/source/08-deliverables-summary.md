# 8. Deliverables Summary — Microsoft Purview ITAR Compliance Program

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What the ITAR export-control program is — label encryption to authorized U.S. persons, DLP hard-block, retention, and Compliance Manager evidence — benefits and limitations |
| 2. Requirements Guide | Every ITAR-specific prerequisite with Verify / Implement-if-missing (licensing + GCC High, roles, scope + authorized persons, detection, recipient model, retention, control baseline) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: baseline + cloud, scope + authorized persons + control map, assessment, action plan & evidence register, technical-data controls (custom SIT, simulation/audit), audit gate, enforce (hard-block), validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates and the DLP audit gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for export-controlled technical data |

## PowerShell scripts
| Script | What it does |
|---|---|
| `ITAR-Discovery.ps1` | Reports the tenant's export-control-relevant posture — labels, DLP policies (and mode), retention, the custom SIT, export-control SITs, audit signal, and Purview role groups (role-separation readiness); read-only |
| `ITAR-Validation.ps1` | Confirms the named objects are in place — ITAR label published, DLP present (and its mode), retention present, audit on — pass/fail with exit code |
| `ITAR-EvidenceReport.ps1` | Cross-control evidence: label inventory, DLP service/mode matrix, per-workload DLP-event counts, and an audit-log sample — optionally exported to CSV for `ITAR Evidence – Register` |
| `ITAR-Remediation.ps1` | Safe remediation of low-risk gaps (default `-WhatIf`) — enables a disabled label/retention policy; **never** auto-enforces DLP (the audit gate is a human decision) |
| `ITAR-Set-Scope.ps1` | Builds/updates the `ITAR - Authorized Persons Pilot` Microsoft Entra security group for piloting and expansion within the authorized-U.S.-person population |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable program following the model: **Assess → Design → Configure → Pilot (simulate) →
  Validate → Expand**, with a DLP audit gate before enforce, a recipient hard-block, and a documented
  rollback.

## Outcome
An ITAR-aligned export-control program in Microsoft Purview — technical data encrypted and restricted to
authorized U.S. persons, DLP that hard-blocks unauthorized recipients (tuned in audit first, with endpoint
coverage), defensible export-record retention, and export-control / NIST 800-171 evidence in Compliance
Manager — proven on a pilot before you scale, and never widened beyond authorized persons. **ITAR
applicability, USML classification, the U.S.-person determination, licenses/agreements, retention
schedules, and any voluntary-disclosure decision remain export-control and legal determinations.**
