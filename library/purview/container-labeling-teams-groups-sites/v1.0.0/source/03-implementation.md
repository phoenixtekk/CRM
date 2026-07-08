# 3. Implementation Guide — Container Labeling (Teams, Groups & Sites)

Follow these steps **in order**. Work spans the **Microsoft Purview portal** (purview.microsoft.com), the
**Microsoft 365 / Entra admin centers**, **Security & Compliance PowerShell** (`Connect-IPPSSession`),
**Microsoft Graph**, and **SharePoint Online Management Shell** (`Connect-SPOService`). Writes are
previewed with `-WhatIf` before `-Commit`. Artifact names follow the convention from the Overview and are
reused verbatim.

> **Model:** Assess the tenant + container estate → design the label taxonomy → enable container
> labeling, author + publish labels → apply to a **pilot ring** (containers + users) → validate every
> gate → expand. Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
>
> **Portal paths are cited as of authoring and the Purview portal is evolving — verify each path in your
> own tenant.** The unmanaged-device access control is **licensing-dependent (Entra ID P1) — verify
> against your plan** (Requirement 2.1). Container settings are **high-impact** (guest access, external
> sharing, device access) — pilot on the ring before the estate.

## Step 1 — Assess the tenant and container estate (Assess)
1. Run `IPCONT-Check-Prereqs.ps1 -CsvPath .\ContainerScope.csv`. Read-only, it reports: the
   `Group.Unified` `EnableMIPLabels` state, whether container-scoped labels exist, the SharePoint tenant
   `SharingCapability` and `ConditionalAccessPolicy` baseline, Entra ID P1 signal, and module/connection
   health. It writes `Container Scope – Map`.
2. Run `IPCONT-Discover-Containers.ps1 -CsvPath .\ContainerInventory.csv`. Read-only, it enumerates every
   M365 Group/Team and SharePoint site with its current **privacy**, **guest-allowed**, **external
   sharing**, and **assigned sensitivity label**, flagging unlabeled containers. It writes
   `Container Inventory – Assess`.
3. **Pass/fail:** you have a complete inventory of containers with current posture, and you know whether
   container labeling is enabled and whether the tenant sharing baseline supports your intended taxonomy.

## Step 2 — Design the container label taxonomy (Design)
1. Build `Container Labels – Taxonomy – Design` — the three tiers and their exact settings:

   | Label | Privacy | Guest access | External sharing | Unmanaged-device access |
   |---|---|---|---|---|
   | `Container – General` | Private | Allowed | New and existing guests | Allow full access |
   | `Container – Confidential` | Private | Existing guests only | Existing guests only | Allow limited, web-only access |
   | `Container – Highly Confidential` | Private | Not allowed | Only people in your organization | Block access |

2. Map each in-scope container to a tier with your **data-owner/compliance stakeholders** — the tier
   assignment is their determination; you implement it. Record the mapping in the inventory.
3. **Pass/fail:** every in-scope container has an agreed target tier, and each tier's settings are
   expressible under the tenant sharing baseline and licensing (device-access needs Entra ID P1).

## Step 3 — Enable container labeling and author + publish the labels (Configure)
1. **Enable container labeling (one-time, tenant-level).** Dry-run first:
   `IPCONT-Set-ContainerLabels.ps1 -EnablePrerequisites -WhatIf` — it shows it would set the
   `Group.Unified` directory setting `EnableMIPLabels = True` and run `Execute-AzureAdLabelSync`. Apply
   with `-EnablePrerequisites -Commit` (Global/Groups Admin). Writes `Container Labeling – Enablement`.
   **Verify the current enablement method against Microsoft guidance for your tenant** — the
   directory-settings surface is evolving.
2. **Author the labels in the Purview portal** → `Information protection → Labels → Create a label`
   (verify path). For each tier, on the **Scope** page select **Groups & sites**, then on the protection
   pages set:
   - **Privacy and external user access** → Privacy = **Private**; "Let group owners add people outside
     the org as guests" = per tier (`General`: on; `Confidential`: existing only; `Highly Confidential`:
     off).
   - **External sharing and device access** (name varies — verify) → external sharing per tier; and
     **"Use Conditional Access to protect labeled SharePoint sites"** → `General`: full access;
     `Confidential`: **limited, web-only access**; `Highly Confidential`: **block access**. The
     device-access options require **Entra ID P1** — verify.
3. **Publish the labels.** Create the label policy **`Container Labels – Groups & Sites – Policy`** →
   include the three container labels → publish to the **pilot user group** first (not all users).
   Optionally set the policy's **default label for containers** to `Container – General` so new
   containers are governed by default. Confirm with `Get-Label` / `Get-LabelPolicy`.
4. **Pass/fail:** `EnableMIPLabels` reports `True`; the three container labels exist with Groups & sites
   scope; the policy is published to the pilot users; the labels appear when a pilot user creates a
   Team/site.

## Step 4 — Apply labels to the pilot ring (Configure, pilot-first)
1. Prepare a targets CSV (`ContainerName`, `Identity` [group id or site URL], `Label`) for the
   `Container Labels – Pilot Ring – Stage1` containers.
2. Dry-run: `IPCONT-Set-ContainerLabels.ps1 -TargetsPath .\PilotTargets.csv -WhatIf`. With `-WhatIf` (the
   default) it makes **no changes** — it prints, per container, the label it *would* apply (groups via
   Graph `assignedLabels`, sites via `Set-SPOSite -SensitivityLabel`) and the exact **reverse** command.
3. Read every line against the taxonomy and the pilot ring. Apply with `-TargetsPath .\PilotTargets.csv
   -Commit`. Only the pilot-ring containers are touched.
4. **Pass/fail + rollback:** each pilot container reports the intended label; privacy/guest/sharing
   change to match. Rollback = re-apply the prior label (or clear it) with the reverse command the script
   prints for each change.

## Step 5 — Validate the pilot ring (Pilot → Validate)
1. Run `IPCONT-Validate-ContainerLabels.ps1 -TargetsPath .\PilotTargets.csv`. Read-only, it confirms each
   target carries the intended label **and** that privacy, guest access, external sharing, and (where P1)
   unmanaged-device posture match the label's definition — pass/fail per container.
2. Have a pilot owner confirm real behavior: a Private/guest-free `Highly Confidential` Team rejects an
   external invite; a `Confidential` site opens **web-only** from an unmanaged device (no download).
3. Complete the **Testing Guide** on the ring. **Pass/fail:** all Testing-Guide gates pass on
   `Container Labels – Pilot Ring – Stage1`.

## Step 6 — Expand to the estate (Expand)
1. Broaden `Container Labels – Groups & Sites – Policy` from the pilot user group to all intended users
   (portal). Confirm the labels surface at container creation tenant-wide.
2. Apply labels to the wider container estate in waves: build the full targets CSV from the inventory,
   dry-run `-WhatIf`, review, `-Commit` per wave. Re-run `IPCONT-Validate-ContainerLabels.ps1` after each
   wave.
3. Run `IPCONT-Report-ContainerLabeling.ps1 -CsvPath .\ContainerReport.csv` to produce
   `Container Inventory – Report` — the coverage percentage and posture across all containers — as the
   management evidence artifact, and re-run it on a schedule to keep coverage healthy.
4. **Pass/fail:** coverage of in-scope containers meets the agreed target; the report shows privacy,
   guest, sharing, and device posture matching each container's assigned tier.

---
### Order of operations
`Assess tenant + estate → design taxonomy → enable container labeling (EnableMIPLabels + sync) → author
labels (Groups & sites) → publish policy to pilot users → apply labels to pilot ring (-WhatIf then
-Commit) → validate ring → expand policy + apply in waves → report coverage`
