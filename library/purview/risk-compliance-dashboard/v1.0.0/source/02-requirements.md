# 2. Requirements Guide — Risk & Compliance Dashboard (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide Purview prerequisites (a tenant with the required
**compliance licensing**, least-privilege **Purview roles**, the **Security & Compliance PowerShell +
Graph** toolchain, **in-scope data sources**, **compliance/records/privacy/legal stakeholders**, and a
**pilot scope + change control**) are in `global-requirements-purview.md` — confirm those **first**; this
guide adds the dashboard-specific prerequisites and does not duplicate the six.

> **Object names used throughout (use verbatim):**
> dashboard config `RiskComplianceDashboard.config.json`; collected dataset
> `RiskComplianceDashboard.data.json`; rendered artifacts `RiskComplianceDashboard.html` +
> `RiskComplianceDashboard.csv`; signal-scope label **"Risk & Compliance Dashboard — Signal Scope"**;
> scripts `CMPDASH-Discovery.ps1`, `CMPDASH-Set-Configuration.ps1`, `CMPDASH-Validation.ps1`,
> `CMPDASH-Report.ps1`, `CMPDASH-Scope.ps1`.

## 2.1 Decide which Purview signals are in scope (and licensed)
**Description:** A confirmed list of the signals the dashboard will consolidate — from the eight
candidates: **Compliance Manager, DLP, sensitivity labels, retention/records, Insider Risk,
Communication Compliance, Audit, DSPM** — and, for each, whether it is **licensed and enabled** in your
tenant. Baseline signals (DLP/label/retention enumeration, Audit) need **E3+**; advanced signals
(Insider Risk, Communication Compliance, DSPM, Audit Premium, some Compliance Manager templates) need
**E5 / E5 Compliance**.
**Why required:** The dashboard only shows what the tenant licenses and exposes; an unlicensed signal is a
"not licensed" tile, not a number to fabricate.
**How to verify:** Run **`CMPDASH-Discovery.ps1`** (reports which signals are present/enabled and which
require E5); cross-check the subscription in the M365 admin center (category G1). **Verify your
licensing/tenant** for any signal the script flags as uncertain.
**How to implement if missing:** Assign/purchase the licensing for the signals you require, or scope the
dashboard to the signals you have.

## 2.2 Least-privilege READ roles for each in-scope signal (role separation)
**Description:** The account that collects the dashboard holds only the **least-privilege read roles**
needed: **Compliance Administrator** or **Global Reader** for cross-signal read; **Compliance Data
Administrator** / **Information Protection Reader** for DLP/label/retention enumeration; **View-Only Audit
Logs** (or the **Audit Reader** role) for the audit queries. **Insider Risk** and **Communication
Compliance** figures are **owner-captured by the authorized program owners of those roles — the dashboard
account is NOT granted Insider Risk / Communication Compliance investigator roles** (strict role
separation; HR-sensitive).
**Why required:** Purview uses fine-grained role groups; the collector needs read on each feed but must
**not** accumulate investigative access to HR-sensitive case data.
**How to verify:** Purview portal → **Roles & scopes / Permissions** confirms the read roles; confirm the
dashboard account is **not** in Insider Risk / Communication Compliance investigator role groups.
**How to implement if missing:** Assign the least-privilege read roles under change control; keep the
HR-sensitive investigator roles with their program owners.

## 2.3 Unified audit-log ingestion enabled (Audit)
**Description:** **Unified audit-log ingestion** is turned on so DLP-match, labeling, and other activity
volumes are queryable via **`Search-UnifiedAuditLog`**. Confirm **Audit Standard vs Premium** and the
**retention** that applies (Premium extends retention; some record types need E5).
**Why required:** The DLP-volume and labeling-activity tiles read the unified audit log; if ingestion is
off, those tiles have no source.
**How to verify:** **`CMPDASH-Discovery.ps1`** reports the ingestion state (from
`Get-AdminAuditLogConfig`); Purview portal → **Audit** shows search is available.
**How to implement if missing:** Enable ingestion — **`CMPDASH-Set-Configuration.ps1 -Commit`** can turn
it on (gated), or set it in the portal. Note audit begins capturing from when it is enabled; historical
volume before that date is not available.

## 2.4 Security & Compliance PowerShell + Graph toolchain (category G3)
**Description:** A workstation with **ExchangeOnlineManagement** (`Connect-IPPSSession`) and **Microsoft
Graph PowerShell**, signed in as a modern-auth / MFA-capable admin with the read roles from 2.2.
**Why required:** Collection, validation, and rendering run through these; the scripts call
`Connect-IPPSSession` and/or `Connect-MgGraph`.
**How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed; **`CMPDASH-Scope.ps1`** reports
which feeds the current identity can read.
**How to implement if missing:** Install the modules and confirm modern-auth sign-in (category G3).

## 2.5 Dashboard config: tiles, thresholds, cadence, distribution
**Description:** A **dashboard config** (`RiskComplianceDashboard.config.json`) defining, per signal: the
**metric**, the **RAG thresholds** (e.g. compliance score green ≥ 80, amber 60–79, red < 60 — thresholds
are **your** policy, not a Microsoft default), the **refresh cadence**, the **owner-captured fields** (for
signals with no live read), and the **distribution list** for the rendered dashboard.
**Why required:** RAG status and cadence are organizational decisions; the render step and validation both
key off this config.
**How to verify:** The config exists and validates; **`CMPDASH-Set-Configuration.ps1 -WhatIf`** shows the
tiles/thresholds it would apply.
**How to implement if missing:** Create it with **`CMPDASH-Set-Configuration.ps1`** (default `-WhatIf`;
`-Commit` writes it) and confirm thresholds with your compliance stakeholders.

## 2.6 Owner-captured figures for signals without a reliable public read
**Description:** Named **owners** and a capture cadence for the signals the dashboard **cannot read via a
stable public interface** — **Compliance Manager score**, **Insider Risk** aggregate counts,
**Communication Compliance** aggregate counts, and **DSPM** posture — where Microsoft exposes no reliable
public cmdlet at authoring time.
**Why required:** These tiles must be honest: an owner enters the current figure (from the portal) rather
than the dashboard inventing one; the HR-sensitive figures **must** be entered by the program owner, not
the collector (role separation).
**How to verify:** The config's owner-captured fields have named owners and a "captured on" date;
**`CMPDASH-Validation.ps1`** flags stale owner-captured figures. **Verify your licensing/tenant** —
if Microsoft has since published a stable read interface for one of these, prefer it.
**How to implement if missing:** Assign owners and a capture cadence before the first published dashboard.

## 2.7 Compliance, records, privacy & legal stakeholders (category G5)
**Description:** The **compliance, records, privacy, security, and legal** stakeholders who define what
"good" looks like (RAG thresholds), who receives the dashboard, and who owns each signal — and who make
the **determinations** the dashboard never makes.
**Why required:** Thresholds and the meaning of "red" are policy decisions; HR-sensitive feeds and any
regulatory/records interpretation belong to these functions.
**How to verify:** Named threshold approvers, dashboard recipients, and signal owners exist.
**How to implement if missing:** Identify the owners and agree thresholds/distribution before publishing.

## 2.8 Pilot scope + change control (category G6)
**Description:** A **pilot** run of the dashboard (read-only collection + render, reconciled against the
portal) before it is scheduled and distributed, and a **change-control** window for the one write action
(enabling audit ingestion / writing the config/schedule).
**Why required:** The dashboard must be **reconciled to the source** before anyone trusts it for
decisions; enabling audit ingestion is tenant-wide and high-impact.
**How to verify:** A named pilot window and approver exist; the first run is validated (Testing Guide).
**How to implement if missing:** Agree the pilot and change control before scheduling or distributing.

---
## Checklist
- [ ] In-scope signals decided; each confirmed licensed/enabled (2.1 / category G1)
- [ ] Least-privilege READ roles assigned; collector NOT in Insider Risk / Comm Compliance investigator roles (2.2)
- [ ] Unified audit-log ingestion on; Standard vs Premium + retention noted (2.3)
- [ ] `Connect-IPPSSession` + `Connect-MgGraph` succeed with the read roles (2.4 / category G3)
- [ ] `RiskComplianceDashboard.config.json` created: tiles, RAG thresholds, cadence, distribution (2.5)
- [ ] Owners + capture cadence set for owner-captured signals (Compliance Manager, Insider Risk, Comm Compliance, DSPM) (2.6)
- [ ] Threshold approvers, recipients, and signal owners named (2.7 / category G5)
- [ ] Pilot window + change control agreed for the `-Commit` write (2.8 / category G6)
