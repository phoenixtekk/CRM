# 8. Deliverables Summary — Microsoft Purview GDPR Compliance Program

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What the GDPR program is — Compliance Manager scoring, article-to-control mapping, DSR method, and evidence — benefits and limitations |
| 2. Requirements Guide | Every GDPR-specific prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: baseline & roles, article map, GDPR assessment, action plan & evidence register, personal-data controls (simulation/audit), DSR method, enforce, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates and the DLP audit gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GDPR-Discovery.ps1` | Reports the tenant's GDPR-relevant posture — labels, DLP policies (and mode), retention, EU personal-data sensitive-information types, audit signal, and Purview role groups (role-separation readiness); read-only |
| `GDPR-Validation.ps1` | Confirms the named objects are in place — personal-data label published, DLP present (and its mode), retention present, audit on — pass/fail with exit code |
| `GDPR-EvidenceReport.ps1` | Cross-control evidence: label inventory, DLP service/mode matrix, per-workload DLP-event counts, and an audit-log sample — optionally exported to CSV for `GDPR Evidence – Register` |
| `GDPR-Remediation.ps1` | Safe remediation of low-risk gaps (default `-WhatIf`) — enables a disabled label/retention policy; **never** auto-enforces DLP (the audit gate is a human decision) |
| `GDPR-Set-Scope.ps1` | Builds/updates the `GDPR - Pilot Scope` Microsoft Entra security group for piloting and expansion |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable program following the model: **Assess → Design → Configure → Pilot (simulate) →
  Validate → Expand**, with a DLP audit gate before enforce, a wired DSR runbook, and a documented
  rollback.

## Outcome
A GDPR-aligned program in Microsoft Purview — obligations mapped to Purview controls, scored in
Compliance Manager, personal-data protection piloted in simulation/audit before it enforces, a DSR
method that answers access/erasure/portability requests on the clock, and a centralized evidence
register — configured, validated, and **defensible**. GDPR applicability, lawful basis, ROPA content,
DPIA outcomes, and evidence adequacy remain compliance/privacy/legal determinations.
