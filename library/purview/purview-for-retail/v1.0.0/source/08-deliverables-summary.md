# 8. Deliverables Summary — Microsoft Purview for Retail

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What the retail Purview program delivers — labels, auto-labeling, PCI + PII DLP, retention/records, PCI-DSS compliance baseline — benefits, limitations, and the PCI-scope posture |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (retail-/PCI-specific, on top of the category GR) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal steps (labels, label policy, auto-label simulation, PCI + PII DLP audit-then-block, retention/records, PCI-DSS Compliance Manager) |
| 5. Testing Guide | Validation procedures with pass/fail gates and the DLP audit gate (synthetic/test data only) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for a retail/PCI rollout |

## PowerShell scripts
| Script | What it does |
|---|---|
| `RETAIL-Discovery.ps1` | Reports the tenant's sensitivity labels, DLP policies (PCI/PII, mode), retention policies, the Credit Card Number + PII sensitive-info types, and endpoint/licensing signals |
| `RETAIL-Configuration.ps1` | Safe remediation/config helper (default `-WhatIf`) — enables a published-but-off label policy and a disabled retention policy; **never** auto-switches DLP to block (the audit gate is a human decision) |
| `RETAIL-Validation.ps1` | Confirms the expected labels are published, both DLP policies (PCI + PII) exist and reports their mode, and the retention policy exists and is on |
| `RETAIL-Report.ps1` | Classification + DLP-event coverage summary across the enabled services (PAN/PII by workload) |
| `RETAIL-Set-Scope.ps1` | Builds/updates the `Purview - Retail Pilot` Entra group and runs a quick scope/health check |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate/test) →
  Validate → Expand (enforce)**, with a DLP audit gate before any policy blocks and a documented
  rollback.

## Outcome
A Retail-tailored Microsoft Purview program — a clear label taxonomy, auto-labeling that maps where
PAN lives, PCI and customer-PII DLP tuned in audit before it blocks, retention that meets the retail
records schedule while minimizing payment-data storage, and a PCI-DSS compliance baseline — configured,
piloted, validated, and evidenced, with all regulatory/PCI/records determinations left to the
organization's compliance, QSA, records, privacy, and legal functions.
