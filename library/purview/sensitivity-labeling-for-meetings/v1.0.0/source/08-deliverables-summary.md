# 8. Deliverables Summary — Sensitivity Labeling for Meetings (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Meeting sensitivity labels — lobby, recording, chat, copy, content protection, and invite encryption; how they govern the meeting (not the files) and complement file/email labels (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: assess labels + Teams baseline, design taxonomy, author meeting labels (Meetings scope + portal settings), publish to pilot, pilot on real meetings, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| General meeting label | `Meeting – General` |
| Confidential meeting label | `Meeting – Confidential` |
| Highly Confidential meeting label | `Meeting – Highly Confidential` |
| Label policy | `Meeting Labels – Policy` |
| Pilot ring (users) | `Meeting Labels – Pilot Ring – Stage1` |
| Scope/design map | `Meeting Scope – Map` |
| Coverage report | `Meeting Labels – Coverage Report` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `IPMEET-Discover.ps1` | Reports current state: every sensitivity label and whether any is scoped to Meetings, the label policies publishing them, and the Teams meeting-policy baseline (lobby / recording / chat) — Security & Compliance PowerShell + MicrosoftTeams; read-only |
| `IPMEET-Check-Prereqs.ps1` | Prerequisite/health helper: modules, connections, roles, the Teams-Premium and Meetings-scope signals, and whether meeting labels already exist — PASS/GAP per signal; read-only |
| `IPMEET-Set-MeetingLabel.ps1` | Configuration/Remediation: creates the meeting label objects and publishes/points the `Meeting Labels – Policy` at the pilot (or expansion) users; **defaults to `-WhatIf`** (prints the plan + reverse action), applies only with `-Commit`; meeting-protection settings are completed in the portal; no secrets in code |
| `IPMEET-Validate.ps1` | Validation: PASS/FAIL that each intended meeting label exists with the Meetings scope, is published in `Meeting Labels – Policy` to the intended users, and the Teams baseline is compatible — read-only |
| `IPMEET-Report.ps1` | Coverage report of meeting labels — each label, its scope, and its publication/target coverage — written to CSV as `Meeting Labels – Coverage Report`; read-only |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
Sensitive meetings protected from Purview — lobby, recording, chat, copy, and content protection driven
by a named sensitivity label and the invite encrypted — proven on a pilot ring before you scale, with the
determination of which meeting is sensitive, and any records/legal-hold obligation on a recording, left to
the owners who make it.
