# 8. Deliverables Summary — Microsoft Purview for Manufacturing

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What a Manufacturing-tailored Purview program is — IP protection + CUI/CMMC — how it works, benefits, limitations |
| 2. Requirements Guide | Every Manufacturing prerequisite with Verify / Implement-if-missing (references the Purview category Global Requirements) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal steps — IP+CUI taxonomy, custom SIT, auto-labeling (simulation), DLP audit-then-enforce, retention/records, CMMC/800-171 in Compliance Manager |
| 5. Testing Guide | Validation procedures with pass/fail gates and the DLP audit gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for IP + CUI |

## PowerShell scripts
| Script | What it does |
|---|---|
| `PURVIEW-MFG-Discovery.ps1` | Reports the tenant's sensitivity labels, DLP policies, retention config, and the custom SIT; flags endpoint onboarding and licensing signals |
| `PURVIEW-MFG-Validation.ps1` | Confirms the Manufacturing labels are published, the DLP policy exists (with mode), and the retention policy exists and is on |
| `PURVIEW-MFG-Report.ps1` | Classification + DLP-event coverage summary across the enabled services (IP/CUI focus) |
| `PURVIEW-MFG-Remediation.ps1` | Safe remediation of common gaps (default `-WhatIf`); enables a published-but-off label/retention policy — never auto-enforces DLP |
| `PURVIEW-MFG-Set-ScopeTargeting.ps1` | Builds/updates the `Purview - Manufacturing Pilot` Entra group |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate/test) →
  Validate → Expand (enforce)**, with a DLP audit gate before enforce and a documented rollback.

## Outcome
A Manufacturing-tailored Microsoft Purview program — a clear IP/CUI label taxonomy that travels with
the file, a custom part-number classifier, DLP tuned in audit before it enforces (with export-control
hard-blocks and endpoint coverage), defensible quality/contract/CUI retention, and CMMC / NIST 800-171
evidence in Compliance Manager — proven on a pilot before you scale. **Regulatory, records, and
export-control determinations remain with the organization's compliance, records, legal, and
export-control functions.**
