# 8. Deliverables Summary — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case: why objectGUID breaks on a domain consolidation and what the switch delivers |
| 1. Solution Overview | The scenario, why objectGUID breaks and mS-DS-ConsistencyGuid survives, what the switch does, why it is seamless, and clear scope |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (version, current anchor, empty precondition, connector permission, backup, Quest stamp, AD FS ports, roles, tenant) |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps with Gates A-E: Assess -> Configure -> Pilot -> Validate -> Expand |
| 5. Testing Guide | Validation procedures with pass/fail gates, incl. the decisive Quest hard-match test |
| 6. Troubleshooting Guide | Field issues and remediation (wizard refusal, access denied, duplicates, AD FS, version, multi-forest) |
| 7. Best Practices | Field-proven recommendations for a safe, one-way anchor migration |

## PowerShell scripts
| Script | What it does |
|---|---|
| `SRCANCHOR-Assess.ps1` | Reports the current source anchor, the installed Entra Connect Sync version, and whether mS-DS-ConsistencyGuid is populated anywhere in-scope, with a readiness verdict (read-only) |
| `SRCANCHOR-Test-Preconditions.ps1` | Enumerates the in-scope OUs and lists any objects whose mS-DS-ConsistencyGuid is already set — the blocker (read-only) |
| `SRCANCHOR-Check-Permissions.ps1` | Verifies the AD DS connector (sync) account has Write mS-DS-ConsistencyGuid on each in-scope OU, per-OU PASS/FAIL (read-only) |
| `SRCANCHOR-Validate.ps1` | Post-change: confirms the anchor is now mS-DS-ConsistencyGuid, the seed equals the prior immutableId, and (if Graph) the Entra user's onPremisesImmutableId is unchanged (read-only) |
| `SRCANCHOR-Report.ps1` | Run/coverage report: in-scope object count, count populated, recent ADSync run errors, and a duplicate-risk check; optional CSV (read-only) |

## What the buyer receives
- This implementation guide as a PDF (`SRCANCHOR-Solution.pdf`).
- All five PowerShell scripts in a single ZIP (`SRCANCHOR-Scripts.zip`).
- A repeatable process: Assess -> Configure -> Pilot -> Validate -> Expand, with explicit Gates A-E.

## Outcome
A source anchor migrated from objectGUID to mS-DS-ConsistencyGuid on a live deployment — seamlessly for
existing users, with the connector permission and backup in place, proven by a Quest ODM hard-match on
a pilot before the production waves run. The domain consolidation proceeds without orphaning a single
Entra identity.
