# 6. Troubleshooting Guide — Classification Reporting & Analytics (Microsoft Purview)

Field issues and fixes. Most stem from **licensing/availability** (Content Explorer content viewing,
Activity Explorer, and `Export-ContentExplorerData` are plan-gated and the portal is evolving), **audit
ingestion being off or still catching up**, an **empty/baseline estate** (little is classified yet — a
legitimate finding), or a **tenant-specific audit RecordType / Content Explorer TagType** that differs from
the default. When a portal path or cmdlet differs from this guide, confirm the current equivalent rather
than assuming. The five scripts are `CLSREPORT-Discovery.ps1`, `CLSREPORT-Configure.ps1`,
`CLSREPORT-Validate.ps1`, `CLSREPORT-Report.ps1`, and `CLSREPORT-ScopeHealth.ps1`.

## Content Explorer or Activity Explorer is missing, or shows only aggregate cards
- **Likely cause:** Licensing (Requirement 2.1) or role membership (Requirement 2.2). Item-level content
  viewing and Activity Explorer generally require **Microsoft 365 E5 / E5 Compliance**; aggregate cards are
  more broadly available.
- **Fix:** Confirm the subscription/add-ons in the M365 admin center and your role in Purview → Roles &
  scopes. Run `CLSREPORT-Discovery.ps1` to see which licensing-dependent signals your session can return. If
  the plan genuinely lacks the surface, note the gate in the report footnote and report on what is available
  — do not treat aggregate-only as a bug. **Verify your licensing/tenant.**

## The explorer isn't where this guide says (menu path differs)
- **Cause:** Content Explorer and Activity Explorer are **moving between** the classic compliance portal
  (`compliance.microsoft.com → Data classification`) and the new Purview portal
  (`purview.microsoft.com → Information Protection / Data loss prevention`).
- **Fix:** Try both known locations (Implementation Step 7) and **verify against your current portal** — the
  surface has moved, the data is the same.

## `CLSREPORT-Configure.ps1` made no change
- **Cause:** It is **safe-by-default** — without `-Commit` it runs in preview (`-WhatIf`) mode and only
  prints what it *would* do.
- **Fix:** Read the previewed actions, obtain change-control approval, then re-run with `-Commit`. Confirm
  you also passed the intended switches (`-EnableAudit`, `-GrantListViewer`, `-GrantContentViewer`) and
  `-Members`.

## Audit ingestion shows False (Activity Explorer / activity export empty)
- **Cause:** Unified audit log ingestion is off (Requirement 2.4) — Activity Explorer and
  `Search-UnifiedAuditLog` have no source.
- **Fix:** `CLSREPORT-Configure.ps1 -EnableAudit -WhatIf` to preview, then `-Commit` under change control
  (`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`). **Then wait** — allow the pipeline to
  backfill before judging activity coverage. `CLSREPORT-Validate.ps1` and `CLSREPORT-ScopeHealth.ps1` report
  the current state.

## `Search-UnifiedAuditLog` returns nothing or errors
- **Cause:** Not connected to Exchange Online, ingestion off, the window predates ingestion being on, or an
  invalid RecordType.
- **Fix:** `Connect-ExchangeOnline`; confirm ingestion True; widen `-Days` within the retained window; and
  confirm the `-RecordTypes` values are current for your tenant (they evolve — **verify** in Purview →
  Audit). Note audit data has ingestion latency — very recent activity may not appear yet.

## `CLSREPORT-Report.ps1` coverage-by-tag.csv is empty or all VERIFY
- **Cause 1 — export cmdlet absent:** `Export-ContentExplorerData` is licensing-/version-dependent and does
  not resolve in every tenant. **Fix:** The script falls back to the **published tag inventory** and flags
  `VERIFY (portal)` — capture the Content Explorer counts from the **portal** for those tags, and note
  **"verify your licensing/tenant"** (Req 2.1).
- **Cause 2 — baseline estate:** Genuinely little is classified. **Fix:** Record as **baseline coverage** (a
  finding to route to governance), reference the labeling/SIT solutions — not a failure (Req 2.5).

## `CLSREPORT-Validate.ps1` reports FAIL on role membership
- **Cause:** The expected analysts aren't in **List Viewer**, or **Content Viewer** exceeds the minimal
  threshold / contains an unexpected member (role-group drift).
- **Fix:** For missing List Viewer members, grant via `CLSREPORT-Configure.ps1 -GrantListViewer -Members …
  -Commit`. For an over-populated or drifted **Content Viewer** (which exposes sensitive data), remove the
  unexpected members with `Remove-RoleGroupMember -Identity "Content Explorer Content Viewer" -Member <upn>`
  and investigate how they were added.

## An analyst can see item lists but not open content (or vice versa)
- **Cause:** Purview separates the two viewer roles — **`Content Explorer List Viewer`** shows the list/
  location; **`Content Explorer Content Viewer`** opens the item content.
- **Fix:** Grant the specific role the task needs (least-privilege). Content Viewer exposes real sensitive
  data — grant it only to the minimal approved set (Req 2.2), and only after change-control approval.

## Revocation didn't take effect
- **Cause:** Role-group changes apply on the next sign-in / token refresh.
- **Fix:** Have the user sign out and back in (or wait for token refresh), then re-run
  `CLSREPORT-Validate.ps1`. Confirm the removal targeted the correct role group.

## `CLSREPORT-ScopeHealth.ps1` shows a workload "not reporting in"
- **Cause:** That workload produced no events for the RecordType in the window — could be no activity,
  ingestion lag, or a RecordType that doesn't match how your tenant logs.
- **Fix:** Confirm classification/DLP activity has actually occurred on that workload; widen `-Days`; and
  confirm the `-RecordTypes` are current (**verify** in Purview → Audit). An empty window shortly after
  enabling ingestion is **lag**, not a failure.

## `Export-ContentExplorerData` / `Export-ActivityExplorerData` "not recognized"
- **Cause:** The export cmdlet is unlicensed or not present in this tenant/module version.
- **Fix:** Confirm E5 / E5 Compliance and the reporting role (Req 2.1 / 2.2). Where the cmdlet is genuinely
  absent, use the **Content Explorer / Activity Explorer portal** for that data and flag **"verify your
  licensing/tenant"** — the reporting still stands, sourced from the portal plus `Search-UnifiedAuditLog`.

## The dashboard tiles broke after a script run
- **Cause:** The dashboard binds to the CSV **column names** written by `CLSREPORT-Report.ps1`
  (`coverage-by-tag.csv`, `activity-summary.csv`); a shape change breaks the binding.
- **Fix:** Confirm the CSVs came from the **current** `CLSREPORT-Report.ps1` and re-point the dashboard at
  its column names. Keep the dashboard bound to the script output, not to a fixed portal export.

## The solution "changed" something
- **It should not have.** Only `CLSREPORT-Configure.ps1` writes, only with `-Commit`, and only to (a) audit
  ingestion config and (b) viewer role-group membership — never to content, labels, SITs, or policy. If you
  believe more changed, run `CLSREPORT-Validate.ps1`, review the role-group membership, and remove any
  unintended grant with `Remove-RoleGroupMember`.

## Escalation boundary
Regulatory, records-retention, and legal questions — *which* content must be relabeled or retained, whether
an activity is a *policy violation*, legal-hold implications — are **not** resolved here. Capture the
technical evidence (the coverage and activity exports, the validation output) and route the determination to
your compliance, records, privacy, and legal functions (GR §5). Standing up label/DLP **enforcement** is a
separate, change-controlled solution, not part of this reporting implementation.
