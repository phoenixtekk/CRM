# 8. Deliverables Summary — Microsoft Purview for Healthcare (HIPAA/PHI)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What a Healthcare-tailored Purview program is — PHI labels, auto-labeling, DLP, retention/records — benefits, limitations, scope boundary |
| 2. Requirements Guide | Every Healthcare/PHI prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide Purview prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal steps (PHI labels, label policy, auto-labeling simulation, DLP audit-then-enforce, retention/records from your schedule, optional DSPM for AI) |
| 5. Testing Guide | Validation procedures with pass/fail gates and the DLP audit gate (synthetic PHI only) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations tuned for PHI and clinical continuity |

## PowerShell scripts
| Script | What it does |
|---|---|
| `PHI-Discovery.ps1` | Reports the tenant's sensitivity labels, DLP policies, and retention config; flags DLP already enforcing, endpoint onboarding, and licensing signals |
| `PHI-Validation.ps1` | Confirms the expected PHI labels are published, the HIPAA DLP policy exists (reports mode), and the retention policy exists and is on |
| `PHI-Report.ps1` | PHI classification + DLP-event coverage summary across the enabled services (HIPAA evidence) |
| `PHI-Remediation.ps1` | Safe remediation of common gaps (default `-WhatIf`); enables a published-but-off label/retention policy — never auto-enforces DLP |
| `PHI-Set-ScopeTargeting.ps1` | Builds/updates the PHI pilot / care-team scope Entra security groups |

All scripts are **read-only or `-WhatIf`/`-Apply`-gated by default**, use **Security & Compliance
PowerShell** (`Connect-IPPSSession`) and/or **Microsoft Graph**, and contain **no credentials or
secrets**.

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate/test) →
  Validate → Expand (enforce)**, with a DLP audit gate before enforce and a documented rollback.

## Scope boundary (restated)
Regulatory, records-retention, and legal determinations — which data is a designated record set, how
long medical records must be retained, records file plans, legal holds, and insider-risk /
communication-compliance case actions — are **deferred to your compliance, records, privacy, and legal
functions**. This solution provides the technical configuration method and the evidence, not the
determination. Purview features are **licensing-/plan-dependent and evolving — verify your
licensing/tenant**.

## Outcome
PHI classified, protected, and retained with Microsoft Purview — a clear PHI label taxonomy with
auto-labeling, HIPAA DLP tuned in audit before it enforces, and retention that meets your records
schedule without over- or under-deleting — proven on a pilot before you scale, and defensible.
