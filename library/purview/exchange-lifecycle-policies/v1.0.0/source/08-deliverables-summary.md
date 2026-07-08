# 8. Deliverables Summary — Exchange Lifecycle Policies: Microsoft Purview

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The two engines (Purview retention + Exchange MRM cleanup), why deletion is high-impact, precedence, and the Assess→Design→Configure→Pilot→Validate→Expand model (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (licensing, roles, both toolchain connections, the records schedule, holds, cleanup design, pilot ring, MFA cadence) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: assess, design with records/legal, configure retention + MRM scoped to the pilot, pilot (retain-first), validate, expand — each policy/tag/scope named, with rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates — including the blast-radius check that nothing outside scope is touched |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Pilot ring (mail-enabled security group) | `SG-DLCEXO-Pilot` |
| Purview retention policy (Exchange) | `DLCEXO-Retention-Exchange-Pilot` |
| Purview retention rule | `DLCEXO-Rule-Exchange-Keep7yrThenDelete` |
| MRM cleanup retention policy | `DLCEXO-MRM-Cleanup-Standard` |
| RPT — Deleted Items age-out | `DLCEXO-Tag-DeletedItems-30d` |
| RPT — Junk Email age-out | `DLCEXO-Tag-JunkEmail-30d` |
| DPT — move old mail to archive | `DLCEXO-Tag-Default-MoveToArchive-2yr` |

*(Durations are placeholders — use the values from your records schedule.)*

## PowerShell scripts
| Script | What it does |
|---|---|
| `DLCEXO-Discovery.ps1` | Read-only inventory of what already governs the mailboxes: Purview retention policies/rules scoped to Exchange, MRM retention tags/policies, the org default MRM policy, per-mailbox archive + litigation-hold status (Connect-IPPSSession + Connect-ExchangeOnline) |
| `DLCEXO-Set-Scope.ps1` | Records the pilot/expansion scope — pilot group, target retain duration, disposition, cleanup tags — as a read-only scope manifest to configure against; changes nothing |
| `DLCEXO-Configure.ps1` | Creates/updates the Purview retention policy + rule (Exchange) and the MRM cleanup policy + tags, scoped to the pilot; **defaults to `-WhatIf`**, applies only with `-Commit`; supports `-Disposition Retain` for retain-first; no secrets in code |
| `DLCEXO-Report.ps1` | Coverage/health report: which mailboxes are in the Purview policy scope, MRM policy assignment coverage, archive enablement, and mailbox-size signal (read-only) |
| `DLCEXO-Test-Readiness.ps1` | Consolidated PASS/GAP pilot gate: licensing/role signal, policy scope = pilot only, rule matches the approved schedule, MRM assigned to pilot, holds honored, and the blast-radius (no out-of-scope mailbox) check (read-only) |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
Mail governed on policy in Microsoft Purview — retained for as long as the schedule requires and no
longer, with Deleted Items/Junk aged out and old mail tiered to the archive — proven on a bounded pilot
before any destructive action reaches production, with the retention schedule, holds, and disposition
determinations left to the records, privacy, and legal owners who make them.
