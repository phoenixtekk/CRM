# 3. Implementation Guide — Sensitivity Labeling for Power BI & Microsoft Fabric (Microsoft Purview)

Follow these steps in order. The model is **Assess → Design → Configure → Pilot → Validate → Expand**.
Every write is **piloted on `Analytics Labels – Pilot Ring – Stage1` / a pilot workspace first**,
previewed with `-WhatIf`, and reversible. Named objects are introduced once and reused everywhere:

| Object | Name |
|---|---|
| Sensitivity labels (existing) | `General`, `Confidential`, `Highly Confidential` |
| Label policy publishing to BI creators | `Analytics Labels – Policy` |
| Tenant-setting delegation group | `BI Labeling – Enabled Users` |
| Pilot ring (users) / pilot workspace | `Analytics Labels – Pilot Ring – Stage1` |
| Scope/design map | `Analytics Scope – Map` |
| Coverage report | `Analytics Labels – Coverage Report` |

> **Two surfaces, two jobs.** The **label lifecycle** (author/publish the sensitivity labels) is done in
> Purview and is scriptable. **Turning labeling, source inheritance, export restriction, and mandatory
> labeling ON for analytics** is done in the **Power BI/Fabric admin portal → Tenant settings →
> Information protection**, delegated to `BI Labeling – Enabled Users`. Use the scripts for the safe
> label-policy lifecycle and for validation/reporting; complete the tenant settings in the admin portal.
> **Verify each setting's availability and name against your licensing/tenant.**

## Step 0 — Connect (all steps)
Open PowerShell 5.1+ or 7+ and connect with a modern-auth/MFA admin:
```powershell
Connect-IPPSSession                 # Security & Compliance PowerShell (labels + policies)
Connect-PowerBIServiceAccount       # Power BI (read-only workspace inventory here)
```
Keep credentials out of scripts — sign in interactively. **Pass/fail:** both connections succeed and
`Get-Label` / `Get-PowerBIWorkspace` return without error.

## Step 1 — Assess current state (Assess)
1. Run `IPPBI-Discover.ps1`. Read-only, it reports: every sensitivity label and the label policies
   publishing them; the in-scope **Power BI/Fabric workspaces**; and a checklist of the
   information-protection **tenant settings** to confirm in the admin portal (the script cannot read all
   tenant settings, so it prints them to verify).
2. Run `IPPBI-Check-Prereqs.ps1` — modules/connections, roles, the label and Power BI licensing signals,
   and whether labels are published — PASS/GAP per signal.
3. Record every GAP against the Requirements checklist and remediate before configuring.
   **Pass/fail:** the discovery inventory and prereq report complete; the tenant-setting checklist is
   captured in `Analytics Scope – Map`.

## Step 2 — Design the analytics labeling (Design)
1. With your stakeholders, confirm which sensitivity labels apply to analytics, whether **source
   inheritance** and **export restriction** are on, and where **mandatory labeling** will eventually
   apply.
2. Define `BI Labeling – Enabled Users` and the **pilot workspace/group**; map in-scope workspaces to the
   intent. Record everything in `Analytics Scope – Map`.
3. Confirm which capabilities your licensing supports (Pro/PPU/capacity, AIP entitlement, Fabric-item
   coverage); mark any unsupported control **deferred**.
   **Pass/fail:** `Analytics Scope – Map` is agreed and signed off; which content is which label is owned
   by stakeholders, not by IT.

## Step 3 — Publish the labels and enable the tenant settings (Configure)
Do this **for the pilot first** — the delegation group and pilot workspace only.

1. **Publish labels to BI creators (scriptable).** Point `Analytics Labels – Policy` at the pilot
   creators:
   ```powershell
   .\IPPBI-Set-InfoProtection.ps1 -Action PublishPolicy -PolicyMembers "BI-Labeling-Pilot@contoso.com" -WhatIf
   .\IPPBI-Set-InfoProtection.ps1 -Action PublishPolicy -PolicyMembers "BI-Labeling-Pilot@contoso.com" -Commit
   ```
   Confirm the labels appear in the Power BI service label picker for a policy member.
2. **Enable the tenant settings (admin portal).** Power BI/Fabric **admin portal → Tenant settings →
   Information protection**. Scope each to `BI Labeling – Enabled Users`:
   - **Allow users to apply sensitivity labels for content** — **On**.
   - **Apply sensitivity labels from data sources to their data in Power BI** (source inheritance) —
     **On** (where inheritance is in scope).
   - **Restrict content with protected labels from being accessed by unsupported apps/exports** and the
     related **export** protections — configure per design so exports inherit the label + encryption.
   - **Mandatory label policy for Power BI** — **leave Off during the pilot**.
   Use `IPPBI-Set-InfoProtection.ps1 -Action ShowTenantSettings` to print the exact checklist to apply.
   **Pass/fail:** `Get-Label` shows the labels; `Get-LabelPolicy` shows `Analytics Labels – Policy` scoped
   to the pilot creators; the label picker appears in the service for a pilot member and the tenant
   settings are enabled for `BI Labeling – Enabled Users`.

## Step 4 — Pilot on real content (Pilot)
1. In the pilot workspace, have creators apply each label to real (or representative) semantic models,
   reports, and Fabric items.
2. Where a labeled source feeds a report, confirm the label **inherits** into the content. Then **export
   to Excel** and confirm the exported file carries the label and its protection.
   **Pass/fail:** labels apply to artifacts, inherit from labeled sources, and inherit to exports;
   discrepancies are recorded for troubleshooting, not worked around.

## Step 5 — Validate the pilot (Pilot → Validate)
1. Run `IPPBI-Validate.ps1`. Read-only, it confirms the labels exist and are published in `Analytics
   Labels – Policy` to the pilot creators, and prints the tenant-setting gates to confirm in the admin
   portal — PASS/FAIL per gate.
2. Have a pilot creator confirm real behavior end-to-end: label an artifact, inherit from a labeled
   source, export to Excel and open the protected file.
3. Complete the **Testing Guide** on the pilot. **Pass/fail:** all Testing-Guide gates pass on
   `Analytics Labels – Pilot Ring – Stage1`.

## Step 6 — Expand to the estate (Expand)
1. Broaden `Analytics Labels – Policy` to all intended BI creators and add the remaining workspaces/users
   to `BI Labeling – Enabled Users` (or set the tenant settings to the whole organization once validated).
2. Enable **mandatory label policy for Power BI** only after the pilot validates and stakeholders
   approve; communicate the change to creators first.
3. Run `IPPBI-Report.ps1 -CsvPath .\AnalyticsLabelsReport.csv` to produce `Analytics Labels – Coverage
   Report` — the labels, their publication/target coverage, and the in-scope workspaces — as the
   management evidence artifact, and re-run it on a schedule.
   **Pass/fail:** labels are published to all intended creators; the tenant settings are enabled at the
   intended scope; the report shows the taxonomy present and targeted as designed.

---
### Rollback
- **Un-publish** by removing a label from `Analytics Labels – Policy` (portal, or `Set-LabelPolicy ...
  -RemoveLabel`) or narrowing the policy back to the pilot creators.
- **Disable a tenant setting** in the Power BI/Fabric admin portal (or re-scope it back to `BI Labeling –
  Enabled Users`) to stop labeling/inheritance/mandatory labeling immediately — settings changes take
  effect going forward, not retroactively.
- **Turn mandatory labeling off** first if it generates creator friction; keep source/export inheritance
  on. Keep `Analytics Scope – Map` as the record of the intended state.

### Order of operations
`Assess labels + tenant settings → design intent + map → publish labels to pilot creators → enable tenant
settings for pilot group (labeling + inheritance + export) → pilot on real content → validate → expand
(+ mandatory labeling) → report coverage`
