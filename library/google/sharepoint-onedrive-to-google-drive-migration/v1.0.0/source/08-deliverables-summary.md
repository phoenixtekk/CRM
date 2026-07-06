# 8. Deliverables Summary — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The SPO/OneDrive → Drive/Shared Drives mapping model, permission/sharing translation, and the deployment model (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: discover, define the mapping, pilot + per-item validate, then migrate by wave and validate |
| 5. Testing Guide | Per-item / per-wave validation gates with pass/fail criteria |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Shared-drive structure, permissions/sharing, and method |

## Named mapping artifacts
| Artifact | Name |
|---|---|
| Content + structure mapping | `GWDRIVE Mapping - Content & Structure - Source to Target` |
| Permission/role translation table | `GWDRIVE Mapping - Permissions - Level to Role` |
| Identity mapping table | `GWDRIVE Mapping - Identity - Source to Google` |
| Sharing translation rules | `GWDRIVE Mapping - Sharing - Link & Grant Rules` |
| Pilot scope | `GWDRIVE Pilot - Scope - Wave 0` |
| Per-wave migration + validation runbook | `GWDRIVE Runbook - Migrate & Validate - Per Wave` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GWDRIVE-Discovery.ps1` | Inventories the source SharePoint sites/libraries and OneDrives: item/folder counts, structure, permission principals, and sharing (Microsoft Graph, read-only) |
| `GWDRIVE-Validation.ps1` | Per-item migration + permission validation: files present, roles match the translation, no dropped principals, sharing translated (read-only) |
| `GWDRIVE-Report.ps1` | Renders coverage and an itemized exception list: items migrated vs source and permission/sharing pass rate (read-only) |
| `GWDRIVE-Remediation.ps1` | Safe remediation of identity-map / permission gaps; runs with `-WhatIf` by default |
| `GWDRIVE-Set-ScopeTargeting.ps1` | Builds a wave's target group in Microsoft Entra from a members/scope CSV; runs with `-WhatIf` by default |

## The migration playbook (outline)
A single reusable playbook the migration runs from, assembled from the artifacts above:

1. **Discovery baseline** — source sites/libraries/OneDrives, counts, structure, principals, sharing.
2. **Content + structure map** — `GWDRIVE Mapping - Content & Structure - Source to Target`: which
   sites/libraries become which Shared Drives; which OneDrives become which My Drives.
3. **Permission/role translation** — `GWDRIVE Mapping - Permissions - Level to Role`: each source
   level → Google role, owner-confirmed.
4. **Identity map** — `GWDRIVE Mapping - Identity - Source to Google`: every principal resolved to a
   Google identity (completeness is a gate).
5. **Sharing rules** — `GWDRIVE Mapping - Sharing - Link & Grant Rules`: direct grants, organization
   links, and anyone-with-the-link translated deliberately.
6. **Pilot** — `GWDRIVE Pilot - Scope - Wave 0`: a representative site + OneDrive sample, validated
   per item.
7. **Per-wave runbook** — `GWDRIVE Runbook - Migrate & Validate - Per Wave`: build wave group → migrate
   → validate files/permissions/sharing → report → remediate → pass.
8. **Close out / cut over** — confirm access at mapped roles, brief users on greyed-out folders, set
   source read-only / decommission only after validation is clean.

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable Drive migration following the model: Assess, then Configure, then Pilot, then Validate,
  then Expand.

## Outcome
SharePoint Online and OneDrive content on Google Drive / Shared Drives with **permissions and sharing
intact** — mapped deliberately, validated per item — proven on a pilot before scaling, and migrated
wave by wave so files land in the right shared drives with the right access.
