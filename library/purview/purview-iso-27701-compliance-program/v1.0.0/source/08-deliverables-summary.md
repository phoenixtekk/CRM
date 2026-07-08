# 8. Deliverables Summary — Microsoft Purview ISO 27701 Compliance Program

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What the ISO 27701 PIMS program is — Compliance Manager scoring, clause-to-control mapping, DSR method, and evidence — benefits and limitations |
| 2. Requirements Guide | Every ISO 27701-specific prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: baseline & roles, scope + controller/processor + clause map, ISO 27701 assessment, action plan & evidence register, PII controls (simulation/audit), DSR method, enforce, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates and the DLP audit gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `ISO27701-Discovery.ps1` | Reports the tenant's PIMS-relevant posture — labels, DLP policies (and mode), retention, PII sensitive-information types, any existing ISO 27001 assessment (reuse), audit signal, and Purview role groups (role-separation readiness); read-only |
| `ISO27701-Validation.ps1` | Confirms the named objects are in place — PII label published, DLP present (and its mode), retention present, audit on — pass/fail with exit code |
| `ISO27701-EvidenceReport.ps1` | Cross-control evidence: label inventory, DLP service/mode matrix, per-workload DLP-event counts, and an audit-log sample — optionally exported to CSV for `ISO 27701 Evidence – Register` |
| `ISO27701-Remediation.ps1` | Safe remediation of low-risk gaps (default `-WhatIf`) — enables a disabled label/retention policy; **never** auto-enforces DLP (the audit gate is a human decision) |
| `ISO27701-Set-Scope.ps1` | Builds/updates the `ISO 27701 - Pilot Scope` Microsoft Entra security group for piloting and expansion |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable program following the model: **Assess → Design → Configure → Pilot (simulate) →
  Validate → Expand**, with a DLP audit gate before enforce, a wired DSR runbook, and a documented
  rollback.

## Outcome
An ISO/IEC 27701-aligned PIMS in Microsoft Purview — PIMS requirements mapped to Purview controls,
scored in Compliance Manager, personal-data protection piloted in simulation/audit before it enforces, a
DSR method that answers PII-principal requests, and a centralized evidence register — configured,
validated, and **defensible**. ISO 27701 applicability, PIMS scope, the controller/processor
determination, retention schedules, evidence adequacy, and the **certification decision** remain
compliance/privacy/legal/auditor determinations.
