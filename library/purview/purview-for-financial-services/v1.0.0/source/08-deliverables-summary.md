# 8. Deliverables Summary — Microsoft Purview for Financial Services

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The FS Purview program — labels, DLP, retention/records, communication compliance — aligned to FINRA/SEC/GLBA; benefits, limitations |
| 2. Requirements Guide | Every FS-specific prerequisite with Verify / Implement-if-missing (licensing, separated roles, records schedule, pilot) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal steps (labels, auto-label NPI simulation, DLP audit-then-enforce, retention/records + Preservation Lock after sign-off, communication compliance pilot) |
| 5. Testing Guide | Validation procedures with pass/fail gates, the DLP audit gate, and records/legal sign-off gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `FS-Purview-Discovery.ps1` | Reports the tenant's sensitivity labels, DLP policies, retention labels/policies (with lock state), and communication-compliance policies; flags endpoint onboarding and licensing signals (read-only) |
| `FS-Purview-Validation.ps1` | Confirms the expected FS labels are published, the DLP policy exists (and its mode), the retention policy exists/enabled, and the communication-compliance policy exists |
| `FS-Purview-Report.ps1` | Classification + DLP-event coverage summary across the enabled services (read-only) |
| `FS-Purview-Remediation.ps1` | Safe remediation of common gaps (default `-WhatIf`); enables a published-but-off label/retention policy only — never enforces DLP, never applies Preservation Lock |
| `FS-Purview-Set-ScopeTargeting.ps1` | Builds/updates the `Purview - FS Pilot Users` scope Entra group (Graph; `-WhatIf` supported) |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate/test) →
  Validate → Expand (enforce)**, with a DLP audit gate before enforce, a records/legal sign-off gate
  before Preservation Lock, and a documented rollback.

## Boundary
This package delivers the **technical configuration and evidence** for a Financial Services Purview
program. The **regulatory, records-retention, supervision, and legal determinations** (record set,
retention periods, regulatory-record declarations, supervision scheme, FINRA/SEC/GLBA applicability)
are deferred to the firm's compliance, records, privacy, and legal functions.

## Outcome
A Financial Services-tailored Microsoft Purview program — an FS label taxonomy protecting NPI and MNPI,
DLP tuned in audit before it enforces, retention/records aligned to the firm's schedule with an
immutability mechanism for SEC/FINRA/CFTC electronic-records rules, and a supervision program with
role separation — configured, piloted, validated, and defensible.
