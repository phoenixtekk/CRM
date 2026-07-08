# 3. Implementation Guide — Risk & Compliance Dashboard (Microsoft Purview)

Follow these steps **in order**. **Security & Compliance PowerShell** (`Connect-IPPSSession`),
**Microsoft Graph**, and **Microsoft Purview portal** (`purview.microsoft.com`) steps are given
cmdlet- / click-exact **for the feeds that have a reliable public interface**. Signals with **no stable
public read** (Compliance Manager score, Insider Risk / Communication Compliance detail, DSPM) are
**owner-captured** — named and deferred, never invented. The category prerequisites in
`global-requirements-purview.md` (licensing, roles, toolchain, stakeholders, pilot) are assumed in place.

Consoles / interfaces used:
- **Microsoft Purview portal** — `https://purview.microsoft.com`
- **Security & Compliance PowerShell** — `Connect-IPPSSession` (ExchangeOnlineManagement module)
- **Microsoft Graph** — `Connect-MgGraph` (read scopes only)

> **Model:** Assess which signals are licensed/readable → design the tiles/thresholds/cadence → configure
> collection + rendering and pilot it **read-only / `-WhatIf`** → validate the numbers against the portal
> → expand (schedule, add signals, distribute).
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand.**

> **Artifact names (use verbatim):** config `RiskComplianceDashboard.config.json`; dataset
> `RiskComplianceDashboard.data.json`; rendered `RiskComplianceDashboard.html` + `RiskComplianceDashboard.csv`;
> signal-scope label **"Risk & Compliance Dashboard — Signal Scope"**.

> **Risk + rollback (read first):** The dashboard is a **read-only reporting layer** — collection,
> validation, and rendering **change no policy** and make **no determination**. The **only** write action
> is in `CMPDASH-Set-Configuration.ps1` and is **`-Commit`-gated**: (a) writing the local config/schedule,
> and (b) optionally enabling **unified audit-log ingestion** (tenant-wide, high-impact — pilot + change
> control). **Everything defaults to `-WhatIf` / read-only.** **Rollback:** delete the local config/data/
> HTML artifacts to remove the dashboard (no tenant change); if audit ingestion was enabled by `-Commit`
> and you must revert, disable it in the portal / with `Set-AdminAuditLogConfig` under change control
> (note: disabling audit reduces your evidence — confirm with compliance first). **Insider Risk /
> Communication Compliance are aggregate-only and owner-captured — the dashboard never reads or exposes
> case content.**

---

## Phase 1 — Assess (what is licensed and readable)

### Step 1 — Discover the available signals and audit state
1. Connect read-only: `Connect-IPPSSession` and `Connect-MgGraph -Scopes 'AuditLog.Read.All','SecurityEvents.Read.All'`.
2. Run **`CMPDASH-Discovery.ps1`**. It reports, per signal: **present/enabled**, whether it requires
   **E5**, the **DLP / label / retention policy counts**, and the **unified audit-log ingestion** state.
3. Run **`CMPDASH-Scope.ps1`** to confirm **which feeds the current identity can actually read** (role
   check) and each feed's **freshness/health**. Note any signal flagged **"verify your licensing/tenant"**
   — those become **owner-captured** tiles (Step 4), not live reads.

### Step 2 — Confirm role separation
1. Confirm the collector identity holds only least-privilege **read** roles (Requirement 2.2) and is
   **not** a member of **Insider Risk Management** or **Communication Compliance** investigator role
   groups. `CMPDASH-Scope.ps1` reports the identity's readable feeds; the HR-sensitive feeds should show
   **"aggregate/owner-captured — not read by this account."**

---

## Phase 2 — Design (tiles, thresholds, cadence)

### Step 3 — Author the dashboard config
1. Create **`RiskComplianceDashboard.config.json`** with **`CMPDASH-Set-Configuration.ps1 -WhatIf`**
   (preview) — it emits the config scaffold. For each in-scope signal set:
   - the **metric** (e.g. DLP: enforced-policy count + match volume over `-WindowDays`),
   - the **RAG thresholds** (**your** policy — e.g. compliance score green ≥ 80 / amber 60–79 / red < 60;
     DLP simulation-only policies amber; audit ingestion off = red),
   - the **source** (`live` for read feeds, `owner-captured` for Compliance Manager / Insider Risk /
     Communication Compliance / DSPM),
   - the **refresh cadence** and the **distribution list**.
2. Confirm thresholds with your compliance stakeholders (Requirement 2.7) — the numbers are policy, not a
   Microsoft default.

### Step 4 — Assign owners for owner-captured signals
1. In the config, set the **owner** and **capture cadence** for each `owner-captured` signal
   (Compliance Manager score; Insider Risk aggregate counts; Communication Compliance aggregate counts;
   DSPM posture). The **HR-sensitive figures must be entered by the program owner**, not the collector.
2. Record a **"captured on"** date per field so **`CMPDASH-Validation.ps1`** can flag stale figures.

---

## Phase 3 — Configure & pilot (read-only / `-WhatIf`)

### Step 5 — (If needed) enable unified audit-log ingestion — `-Commit`, piloted
1. If Step 1 showed ingestion **off** and you need the DLP/label volume tiles, enable it under change
   control: **`CMPDASH-Set-Configuration.ps1 -EnableAuditIngestion -WhatIf`** to preview, then
   **`-EnableAuditIngestion -Commit`** to apply (calls `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`).
2. Audit begins capturing **from now**; historical volume before this date is not available. If ingestion
   is already on, skip this step.

### Step 6 — Write the config/schedule — `-Commit`, piloted
1. Preview with **`CMPDASH-Set-Configuration.ps1 -WhatIf`**; when the tiles/thresholds are agreed, write
   the config with **`CMPDASH-Set-Configuration.ps1 -Commit`**. This writes **only local files** (the
   config and, if requested, a scheduled-task scaffold) — it changes **no** Purview policy.

### Step 7 — Pilot collection + render (read-only)
1. Run **`CMPDASH-Report.ps1`** (read-only). It **collects** every `live` signal (DLP/label/retention
   enumeration + `Search-UnifiedAuditLog` volume over `-WindowDays`), merges the **owner-captured**
   figures from the config, writes the normalized **`RiskComplianceDashboard.data.json`**, and renders
   **`RiskComplianceDashboard.html`** + **`RiskComplianceDashboard.csv`** with RAG tiles.
2. Open the HTML dashboard. Every tile should show its **value, RAG status, and source badge**
   (`live` vs `owner-captured`), and any unlicensed/unreadable signal should read **"not licensed / verify
   your tenant"** — never a fabricated number.

---

## Phase 4 — Validate (reconcile to source)

### Step 8 — Reconcile the dashboard against the portal (pilot gate)
1. Run **`CMPDASH-Validation.ps1`**. It re-reads each `live` signal and **reconciles** it against the
   value in `RiskComplianceDashboard.data.json` (policy counts match; DLP volume within tolerance;
   audit-ingestion state correct), and **flags stale owner-captured figures** past their cadence.
2. Manually spot-check a **live** tile against the portal (e.g. DLP policy count in Purview → **Data loss
   prevention → Policies** equals the dashboard's), and confirm each **owner-captured** tile matches the
   figure the program owner recorded. Complete the **Testing Guide** pilot gate before scheduling.

---

## Phase 5 — Expand (schedule, add signals, distribute)

### Step 9 — Schedule the refresh
1. Schedule **`CMPDASH-Report.ps1`** at the cadence in the config (e.g. Windows Task Scheduler / a runbook)
   under a **least-privilege service identity** with the read roles from 2.2 — **no secrets in the
   script**; use an interactive modern-auth or managed identity per your standard.
2. Re-run **`CMPDASH-Validation.ps1`** after the first scheduled run to confirm the automated numbers still
   reconcile.

### Step 10 — Distribute and add signals in waves
1. Distribute **`RiskComplianceDashboard.html`** to the recipients in the config (e.g. a compliance
   SharePoint page or an emailed artifact). Do **not** distribute the raw dataset if any owner-captured
   figure is sensitive beyond the intended audience.
2. Add further signals in **waves** — start with the `live` feeds you can reconcile, add `owner-captured`
   tiles as owners commit to a cadence. Re-validate after each addition. **Verify your licensing/tenant**
   before promising a tile whose interface is flagged uncertain.

---
### Order of operations
`Discover signals + audit state → confirm role separation → author config (tiles/thresholds/cadence) →
assign owner-captured owners → (enable audit ingestion, -Commit) → write config (-Commit) → pilot collect
+ render (read-only) → reconcile against portal (gate) → schedule → distribute + add signals in waves`
