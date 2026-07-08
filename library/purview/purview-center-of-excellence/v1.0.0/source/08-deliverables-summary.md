# 8. Deliverables Summary — Microsoft Purview Center of Excellence

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The CoE operating model — governance board (least-privilege, separated), standards, intake workflow, and lifecycle cadence — plus the naming convention, limitations, and determination boundary |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + S&C PowerShell + Graph steps: assess the estate, author charter/standards/intake, apply the board role model and standard tags pilot-first (`-WhatIf` → `-Commit`), pilot the intake gate in simulation, validate every gate, expand to the full estate and run the cadence |
| 5. Testing Guide | Nine pass/fail governance-gate tests + a cadence checklist |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `OPSCOE-ScopeCheck.ps1` | Read-only scope/health helper: confirms S&C PowerShell / Exchange Online / Graph sign-in, reports compliance SKUs present, and lists which governed capabilities are visible vs unlicensed/portal-only. Writes `Purview CoE Scope – Assess` |
| `OPSCOE-Discovery.ps1` | Read-only estate inventory: enumerates every readable governed artifact (labels, label policies, DLP policies+rules, retention policies/labels+rules, auto-labeling, and where readable communication-compliance / audit-retention), with name, type, state, and naming-standard conformance. Writes `Purview CoE Register – Governed` |
| `OPSCOE-ApplyStandards.ps1` | Configuration/remediation helper: populates the CoE board's built-in role groups from a matrix (creating custom scoped groups where needed) and optionally stamps a non-disruptive `CoE-Owner/Review` tag onto policy `Comment` fields. **`-WhatIf` by default**, `-Commit` to apply, `-Restore` to revert stamps; prints the reverse command for every change. Never changes policy rules/scope/enforcement |
| `OPSCOE-Validate.ps1` | Read-only governance-gate validation: naming conformance, ownership + review-date coverage, the simulation-first (enforced-without-evidence) gate, separation of duties, and register-to-tenant reconciliation. Writes `Purview CoE Lifecycle – Review` with per-artifact PASS/FAIL/WARN |
| `OPSCOE-Register.ps1` | Read-only reporting: builds the governance scorecard — counts by capability, % naming-conformant, % owned, % review-dated, enforced-without-evidence count, and next-review-due list. Writes `Purview CoE Scorecard – Report` |

All scripts are **safe by default** — read-only, or a `-WhatIf` preview requiring an explicit `-Commit`
to change anything (and `ApplyStandards` writes only role-group membership and a metadata `Comment`
stamp — never a policy's rules, scope, or enforcement state). No credentials or secrets are stored in
code; every script uses interactive modern-auth (`Connect-IPPSSession` / `Connect-ExchangeOnline` /
`Connect-MgGraph`) and guards `Get-Command` so unlicensed or portal-only capabilities are skipped, not
failed.

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable governance operating model following the model: **Assess → Design → Configure → Pilot →
  Validate → Expand.**

## Outcome
A standing **Purview Center of Excellence** — a named, least-privilege, separated governance board;
written standards (naming, ownership, simulation-first, change-control, separation of duties); a
single intake gate that keeps ungoverned and un-simulated policies out of the tenant; and a lifecycle
cadence with drift detection and a decommission path — so Purview governance is institutionalized,
every governed artifact is owned and defensible, and the audit answer is one scorecard export. The CoE
governs the method and the evidence; regulatory, records, and legal determinations remain with the
organization's compliance, records, privacy, and legal functions.
