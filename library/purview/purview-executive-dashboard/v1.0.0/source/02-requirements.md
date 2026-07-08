# 2. Requirements Guide — Microsoft Purview Executive Dashboard

Verify **every** requirement before building the dashboard. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C PowerShell
+ Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot & change control)
are in `global-requirements-purview.md` — this guide adds the dashboard-specific detail.

> **Licensing/tenant boundary.** The signals this dashboard summarizes are **licensing-gated**:
> **DSPM**, **Insider Risk**, **Content Explorer**, and advanced **DLP** require **Microsoft 365 E5**
> or the **E5 Compliance** add-on (some are in **preview**); **Compliance Manager** and baseline labels/
> DLP/retention are broader but premium assessments are still gated. Some values (Compliance Manager
> **score**, Insider Risk **aggregate**, DSPM **recommendations**) have **no stable public automation
> surface in every tenant** and are read from the portal. Where this guide flags *"verify your
> licensing/tenant,"* do so before relying on the metric — the dashboard shows what you have, it never
> invents a number.

## 2.1 Compliance/data-governance licensing for the signals you want to show
**Description:** The dashboard's coverage depends on what's licensed: **Compliance Manager** (baseline included broadly; premium assessments = E5/E5 Compliance), **sensitivity labels** and **retention** (E3 baseline; auto-labeling/advanced = E5), **DLP** (E3 baseline; advanced classifiers/analytics = E5), **Content Explorer** (E5), **Insider Risk** and **DSPM** (E5/E5 Compliance; some preview).
**Why:** A KPI can only be populated where its source capability is licensed; unlicensed sources are shown as *"not licensed / verify tenant,"* never fabricated (GR §1).
**Verify:** M365 admin center → `Billing → Licenses`; and run `OPSEXEC-Discovery.ps1`, which reads `subscribedSkus`/service plans via Graph and reports which signal sources are licensed/reachable.
**Implement:** Assign/purchase the plan for any source you require on the page (e.g. E5 Compliance for DSPM/Insider Risk/Content Explorer) before expecting that KPI to populate.

## 2.2 Least-privilege reader roles across the signal sources
**Description:** Read access to each source: **Compliance Administrator** or **Compliance Data Administrator** (or the narrower **Global Reader**) for Compliance Manager, labels, DLP, and retention inventory; **Content Explorer** requires **Content Explorer List/Content Viewer** roles; **Insider Risk** requires an **Insider Risk Management** reader role held by a *separate* person (role separation). The dashboard author needs **read** across the sources — not write, not investigation access.
**Why:** Purview uses fine-grained role groups; a reader-only dashboard needs the matching read roles, and Insider Risk is deliberately walled off (GR §2, §5).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions` — confirm the read roles; `OPSEXEC-Scope.ps1` reports a permissions error against any source the account can't read.
**Implement:** Assign the least-privilege **read** roles under change control; keep **Insider Risk** roles separate from the dashboard-author role (the author sees only aggregate counts, never case detail).

## 2.3 Security & Compliance PowerShell + Graph toolchain
**Description:** The `ExchangeOnlineManagement` module for `Connect-IPPSSession` (Security & Compliance PowerShell — `Get-Label`, `Get-DlpCompliancePolicy`, `Get-RetentionCompliancePolicy`, `Export-ActivityExplorerData`, `Export-ContentExplorerData`), and `Microsoft.Graph` for licensing reads and any Graph reporting/security surface used.
**Why:** The scripts collect signals through these endpoints (GR §3). **Note:** `Export-ContentExplorerData` and some reports are **preview/tenant-dependent** — confirm availability.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession` and `Connect-MgGraph` succeed with a modern-auth/MFA admin. `OPSEXEC-Discovery.ps1` connects and reports which endpoints/cmdlets are reachable.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.4 An agreed metric set and thresholds (from compliance stakeholders)
**Description:** A documented statement — **from your compliance, records, privacy, and security functions** — of *which* KPIs belong on the executive page and what **green/amber/red thresholds** mean for each (e.g. what compliance score, what DLP volume, what label coverage is "acceptable").
**Why:** Whether a number is *good* is a governance judgement, not a technical default (GR §5); the dashboard reports the measurement and colours it against **agreed** thresholds — it doesn't decide what's adequate.
**Verify:** You can name each KPI, its source, its owner, and its threshold band; captured in `Exec Metrics – Compliance Signals – Definition`.
**Implement:** Run a short workshop with the stakeholders to agree the metric set and thresholds before building the page.

## 2.5 In-scope workloads, labels, DLP policies, and assessments (for coverage numbers)
**Description:** The **denominator** for every coverage KPI: which workloads (Exchange, SharePoint, OneDrive, Teams, endpoints) count toward retention/label coverage, which **published labels** and **DLP policies** are the in-scope set, and which **Compliance Manager assessments** are the ones executives care about.
**Why:** "Label coverage = 60%" is meaningless without a defined scope; the coverage percentages key off the in-scope set (GR §4).
**Verify:** `OPSEXEC-Scope.ps1` lists published labels, DLP policies, retention policies, and workloads so you can confirm the in-scope set; the numbers are recorded in the metric definition.
**Implement:** Define the in-scope workloads/labels/policies/assessments with stakeholders before computing coverage.

## 2.6 Portal-read values and who provides them (Compliance Manager score, Insider-Risk aggregate, DSPM)
**Description:** Values that many tenants can't pull via a stable public API — the **Compliance Manager score**, the **Insider Risk aggregate** alert count by severity, and the **DSPM open recommendations** count — are **read from the Purview portal** by the appropriately-roled owner and entered into the metric definition, **with the read date recorded**.
**Why:** These are portal-primary in many tenants; the dashboard must not scrape or invent them, and Insider Risk must stay **aggregate/de-identified** with **role separation** (GR §2, §5).
**Verify:** The metric definition has a named owner and a read date for each portal-only value; `OPSEXEC-Validate.ps1` flags any portal-only value that is **stale** (older than your refresh window).
**Implement:** Assign an owner for each portal-only value and agree how often they refresh it; **verify the current supported automation method for your tenant** in case an API is now available.

## 2.7 A render/distribution target (HTML/CSV, optional Power BI)
**Description:** Where the one-pager is produced and delivered — the scripts emit **HTML + CSV** by default (self-contained, no external calls); optionally the CSV/snapshot feeds a **Power BI** report for a richer visual. Distribution is `Exec Dashboard – C-Suite – Distribution` (e.g. a secured SharePoint location or an emailed PDF).
**Why:** The deliverable is a *page*, so a defined output/format and a secured distribution channel are needed; executives receive a summary, not portal access.
**Verify:** The output folder and distribution channel are agreed; `OPSEXEC-Report.ps1` writes the HTML/CSV to the target and (optionally) the Power BI-ready dataset.
**Implement:** Choose the output location and distribution method (and Power BI, if used) before scheduling the refresh.

## 2.8 A pilot draft, refresh cadence, and change window
**Description:** A **pilot** — the one-pager built as `Exec Dashboard – Pilot – Stage1` and every number checked against its source **before** any executive sees it — plus an agreed **refresh cadence** (typically monthly for trend, with an on-demand rebuild) and a change window for scheduling the collection (GR §6).
**Why:** An executive dashboard that's wrong once loses trust permanently; validate small first, then schedule (GR §6 discipline).
**Verify:** A named pilot draft and refresh cadence exist, and the scheduled-collection change is approved.
**Implement:** Define the pilot, cadence, and change window before publishing or scheduling anything.
