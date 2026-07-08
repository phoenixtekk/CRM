# 3. Implementation Guide — Classification Reporting & Analytics (Microsoft Purview)

Follow these steps **in order**. Portal navigation is given for both the **new Microsoft Purview portal**
(`https://purview.microsoft.com`) and the **classic compliance portal** (`https://compliance.microsoft.com`)
because Content Explorer / Activity Explorer are **actively moving between them** — where a path is
version-dependent, both are named and you **verify against your current portal**. PowerShell is
**Security & Compliance PowerShell** (`Connect-IPPSSession`) plus **Exchange Online PowerShell**
(`Search-UnifiedAuditLog`, `Get/Set-AdminAuditLogConfig`).

Consoles used:
- **Microsoft Purview portal** — `https://purview.microsoft.com`
- **Classic compliance portal** — `https://compliance.microsoft.com` (fallback for a surface not yet moved)
- **Security & Compliance PowerShell** — `Connect-IPPSSession`
- **Exchange Online PowerShell** — `Connect-ExchangeOnline` (audit config + unified audit log)

> **Model:** Confirm licensing/roles; enable audit + the scoped viewer roles; **pilot** the reporting on
> `Classification Reporting - Pilot`; validate both explorers return data; then **expand** to the full
> analyst group and scheduled exports. **Assess → Design → Configure → Pilot → Validate → Expand.**

> **Artifact names (use verbatim):** analyst group `Purview Classification Reporting - Analysts`;
> role groups `Content Explorer List Viewer` and `Content Explorer Content Viewer`; pilot scope
> `Classification Reporting - Pilot`; export folder `.\CLSREPORT-out`.

> **Risk + rollback (read first):** This solution is **read-and-report** — it creates **no** labels,
> SITs, or policies, so it cannot mislabel or block content. The two governed actions are (a) **granting
> `Content Explorer Content Viewer`**, which exposes real sensitive data to the grantee, and (b)
> **enabling unified audit log ingestion**. Both are piloted and change-controlled. **Rollback:** remove
> members from the role group (`Remove-RoleGroupMember`) to revoke reporting access — revocation takes
> effect on next sign-in / token refresh; audit ingestion, once on, is normally left on (disabling it
> loses activity history — treat as a separate decision). No content is ever modified.

---

## Phase 1 — Assess (read-only, no changes)

### Step 1 — Baseline the reporting readiness
1. Connect: `Connect-IPPSSession` and `Connect-ExchangeOnline`.
2. Run **`CLSREPORT-Discovery.ps1`**. It reports, read-only:
   - licensing-dependent signals it can see (whether Content/Activity Explorer data is returnable);
   - current membership of **`Content Explorer List Viewer`** and **`Content Explorer Content Viewer`**;
   - **`UnifiedAuditLogIngestionEnabled`** state;
   - an inventory count of **sensitivity labels**, **retention labels**, and **sensitive information
     types** available to report on.
3. **Pass/fail gate:** you have a written baseline of licensing, roles, audit state, and available
   classification signal. If audit ingestion is **False** or no labels/SITs exist, resolve those
   (Requirements 2.4 / 2.5) before expecting meaningful reports.

### Step 2 — Confirm the classification signal to report on
1. Run **`CLSREPORT-ScopeHealth.ps1`**. It lists the **published** sensitivity labels (`Get-Label`),
   retention labels (`Get-ComplianceTag`), and SITs (`Get-DlpSensitiveInformationType`) — the tag set
   Content Explorer can break down by — and flags health signals (audit lag, empty inventory).
2. **Pass/fail gate:** a non-empty inventory of tags to report on, or an explicit note that the estate is
   a **baseline** (largely unclassified) — a valid finding, not a failure.

---

## Phase 2 — Design

### Step 3 — Design the analyst group and role split
1. In Entra, confirm/create the security group **`Purview Classification Reporting - Analysts`** and
   populate it from the stakeholder list (Requirement 2.3).
2. Decide the **role split**: everyone who needs coverage reporting → **`Content Explorer List Viewer`**;
   only those who must **open sensitive items** → **`Content Explorer Content Viewer`** (kept minimal).
   Record who gets which and why (least-privilege justification).
3. Decide the **pilot analyst subset** (a few named people) for the first grant.

### Step 4 — Design the dashboard shape
1. Decide the two dashboard views: **Coverage** (from `Export-ContentExplorerData` — items per label /
   retention label / SIT / classifier, by location) and **Activity** (from `Search-UnifiedAuditLog` —
   label lifecycle + DLP matches + egress over a rolling window).
2. Choose the surface: **Excel** (bundled workbook from the CSV exports) for a quick start, or **Power
   BI / Fabric** for a live model. *(Power BI licensing/build is the buyer's; this solution delivers the
   CSVs and the column shape the model binds to — pattern-level, not a determination.)*

---

## Phase 3 — Configure (governed; pilot first)

### Step 5 — Enable unified audit log ingestion (if not already on)
1. Preview first: **`CLSREPORT-Configure.ps1 -EnableAudit -WhatIf`** — shows the intended change.
2. When approved under change control: **`CLSREPORT-Configure.ps1 -EnableAudit -Commit`**. This runs
   `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`.
3. **Pass/fail gate:** `Get-AdminAuditLogConfig` shows **True**. Allow the pipeline time to populate
   before judging activity coverage.

### Step 6 — Grant the scoped Content Explorer viewer roles (pilot subset)
1. Preview: **`CLSREPORT-Configure.ps1 -GrantListViewer -Members <pilot analysts> -WhatIf`** and, for
   those who need content, **`-GrantContentViewer -Members <minimal set> -WhatIf`**.
2. When approved: re-run with **`-Commit`**. This calls `Add-RoleGroupMember -Identity "Content Explorer
   List Viewer"` (and `"Content Explorer Content Viewer"`) for the named members.
3. **Pass/fail gate:** `Get-RoleGroupMember` shows the pilot analysts in the intended role group(s), and
   only the minimal set in **Content Viewer**.

### Step 7 — Open the explorers as a pilot analyst
1. As a pilot analyst, open **Content Explorer**:
   - New portal: **Purview portal → Information Protection → Content explorer** (or **Data loss
     prevention → Explorers**);
   - Classic: **compliance.microsoft.com → Data classification → Content explorer**.
   Confirm you can see counts by **label / retention label / SIT / classifier** and drill to a location.
2. Open **Activity Explorer**:
   - New portal: **Purview portal → Data loss prevention → Activity explorer** (or under **Information
     Protection**); Classic: **compliance.microsoft.com → Data classification → Activity explorer**.
   Confirm recent activity rows appear and filter by **activity type** and **label**.
3. **Verify against your current portal** — if a menu differs, the surface has moved; the data is the same.

---

## Phase 4 — Pilot & Validate

### Step 8 — Produce the pilot reports
1. Run **`CLSREPORT-Report.ps1 -Days 30 -OutputFolder .\CLSREPORT-out`**. It writes:
   - `coverage-by-tag.csv` — items per sensitivity label / retention label / SIT (from
     `Export-ContentExplorerData`, where licensed);
   - `activity-summary.csv` — label lifecycle + DLP + egress activity counts over the window (from
     `Search-UnifiedAuditLog`).
2. Load the CSVs into the chosen dashboard (Excel workbook or Power BI). Confirm the two views render.

### Step 9 — Validate against pass/fail gates
1. Run **`CLSREPORT-Validate.ps1`**. It checks and reports PASS/FAIL for:
   - audit ingestion **enabled**;
   - the pilot analysts present in the intended role group(s), Content Viewer minimal;
   - Content Explorer export returns **≥ 1** item for at least one tag (or an explicit "baseline / empty
     estate" note);
   - `Search-UnifiedAuditLog` returns **≥ 1** classification/DLP activity row in the window (or a
     "no activity yet — allow ingestion time" note).
2. **Gate:** all applicable checks **PASS** (empty-estate and ingestion-lag are explained, not failed)
   before expanding.

---

## Phase 5 — Expand & Operate

### Step 10 — Expand to the full analyst audience
1. Re-run **`CLSREPORT-Configure.ps1 -GrantListViewer -Members <full analyst group> -Commit`** (and
   Content Viewer only for the minimal approved set) to move from the pilot subset to the full
   **`Purview Classification Reporting - Analysts`** audience.
2. **Pass/fail gate:** `Get-RoleGroupMember` matches the approved audience; no unintended broad grants.

### Step 11 — Schedule the reports and health checks
1. Schedule **`CLSREPORT-Report.ps1`** (e.g. weekly) to refresh `.\CLSREPORT-out` for the dashboard.
2. Schedule **`CLSREPORT-ScopeHealth.ps1`** (e.g. weekly) to catch **role-group drift** (unexpected new
   members of Content Viewer), **audit lag**, and **new/removed labels** that change the report shape.
3. Review with compliance/records/privacy on a cadence. **Determinations** arising from the reports
   (e.g. "this content must be relabeled/retained/investigated") are **routed to the owning governance
   function** — this solution provides the evidence, not the ruling.
