# 8. Deliverables Summary — Container Labeling (Teams, Groups & Sites)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Container sensitivity labels for Teams/Groups/Sites — privacy, guest access, external sharing, and unmanaged-device access; the three-tier taxonomy; the phased model; limitations; naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (label + Entra ID P1 licensing, Purview/Entra/SharePoint roles, S&C PowerShell + Graph + AIPService + SPO toolchain, `EnableMIPLabels` enablement, published labels, sharing baseline) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + PowerShell + Graph + SPO steps: assess, design taxonomy, enable container labeling, author + publish labels, apply pilot-first, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates, including guest and unmanaged-device behavior |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `IPCONT-Discover-Containers.ps1` | **Discovery** — read-only inventory of every M365 Group/Team and SharePoint site with current privacy, guest-allowed, external sharing, and assigned sensitivity label; flags unlabeled containers. Writes `Container Inventory – Assess` |
| `IPCONT-Set-ContainerLabels.ps1` | **Configuration/Remediation** — `-WhatIf` by default, `-Commit` to apply. `-EnablePrerequisites` performs the one-time tenant enablement (`Group.Unified` `EnableMIPLabels = True` + `Execute-AzureAdLabelSync`); with a targets CSV it applies a named container label to groups (Graph `assignedLabels`) and sites (`Set-SPOSite -SensitivityLabel`), printing the reverse command per change. Pilot-first |
| `IPCONT-Validate-ContainerLabels.ps1` | **Validation** — read-only pass/fail: confirms each target carries the intended label and that privacy, guest access, external sharing, and (where P1) unmanaged-device posture match the label's tier |
| `IPCONT-Report-ContainerLabeling.ps1` | **Reporting** — read-only coverage/posture export across all containers (labeled %, per-container tier and actual privacy/guest/sharing state). Writes `Container Inventory – Report` |
| `IPCONT-Check-Prereqs.ps1` | **Scope/health helper** — read-only: reports `EnableMIPLabels`, presence of container-scoped labels, SharePoint tenant `SharingCapability`/`ConditionalAccessPolicy` baseline, Entra ID P1 signal, and module/connection health. Writes `Container Scope – Map` |

All scripts are **safe by default** — read-only, or a `-WhatIf` preview requiring an explicit `-Commit`
to change anything. No credentials or secrets are stored in code; every script uses interactive
modern-auth (`Connect-IPPSSession` / `Connect-MgGraph` / `Connect-SPOService` / `Connect-AIPService`).

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot → Validate → Expand.**

## Outcome
Teams, Groups, and SharePoint sites governed at the container level — privacy, guest access, external
sharing, and unmanaged-device access set by a named sensitivity label, piloted on a ring, validated
against pass/fail gates, and reported for coverage — so the container is protected, not just the file
inside it, and the posture is defensible and evidenced.
