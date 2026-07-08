# 2. Requirements Guide — Classification Reporting & Analytics (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** The category-wide Purview prerequisites (compliance licensing,
least-privilege Purview roles, Security & Compliance PowerShell + Graph toolchain, in-scope data sources,
compliance/records/privacy/legal stakeholders, and a pilot scope + change control) are in
`global-requirements-purview.md` — confirm those **six first**; this guide adds the reporting-specific
detail and does not duplicate them.

> **Object names used throughout (use verbatim):**
> analyst security group `Purview Classification Reporting - Analysts` (Entra group holding the people who
> read the explorers); built-in Purview role groups `Content Explorer List Viewer` and
> `Content Explorer Content Viewer`; pilot reporting scope label `Classification Reporting - Pilot`;
> export output folder `.\CLSREPORT-out`. No labels, SITs, or policies are created by this solution —
> it reports on whatever already exists.

## 2.1 Licensing that unlocks the explorers (category GR1)
**Description:** A Microsoft 365 tenant licensed for **Data Classification** analytics. **Content
Explorer** aggregate cards are broadly available, but **viewing item content**, **Activity Explorer**,
and **trainable-classifier** signal generally require **Microsoft 365 E5** or the **E5 Compliance**
add-on.
**Why required:** The explorers are plan-gated; without the right plan the surface is missing or shows
only partial (aggregate-only) data.
**How to verify:** M365 admin center → confirm the E5 / E5 Compliance subscription; in the Purview
portal confirm **Content explorer** and **Activity explorer** are present and populated. Run
`CLSREPORT-Discovery.ps1` — it reports the licensing-dependent signals it can see.
**How to implement if missing:** Assign/purchase the required licensing before relying on item-level or
activity reporting. Flag **"verify your licensing/tenant"** in any report footnote where a plan gate
applies.

## 2.2 Least-privilege reporting roles — the two Content Explorer viewer role groups (category GR2)
**Description:** Reading Content Explorer requires membership in **`Content Explorer List Viewer`**
(see the **list** of items and their locations) and/or **`Content Explorer Content Viewer`** (open and
**read the item content**). Activity Explorer is visible to compliance/data-admin roles
(e.g. **Compliance Administrator**, **Compliance Data Administrator**, Information Protection roles).
**Why required:** Purview separates *seeing that content exists* from *reading it*; least-privilege
reporting means analysts get the minimum they need, and **Content Viewer** (which exposes actual
sensitive data) is granted deliberately and sparingly.
**How to verify:** Purview portal → **Roles & scopes → Permissions** (or `Get-RoleGroupMember` in S&C
PowerShell) shows membership of the two role groups; `CLSREPORT-Discovery.ps1` reports current members.
**How to implement if missing:** Add the analyst group (or named individuals) to the least-privilege
role group under change control — **`Content Explorer List Viewer`** for coverage reporting, and
**`Content Explorer Content Viewer`** only for those who must inspect the sensitive items. Handled by
`CLSREPORT-Set-Reporting.ps1` (`-WhatIf` first).

## 2.3 A named reporting-analyst group and role separation
**Description:** An Entra security group **`Purview Classification Reporting - Analysts`** that holds the
people authorized to read classification reports, kept **separate** from the people who *author* labels/
DLP and separate again from records/legal.
**Why required:** Content Explorer content viewing exposes real sensitive data — access must be
least-privilege, auditable, and role-separated; a named group makes grants and revocations clean and
reviewable.
**How to verify:** The group exists with the intended members; role-group membership points at the group
(or its members), not at "Everyone" or a broad admin group.
**How to implement if missing:** Create the group, populate it from the stakeholder list, and target the
role-group membership at it.

## 2.4 Audit ingestion enabled (Activity Explorer's data source)
**Description:** **Unified audit log ingestion** must be **on** for Activity Explorer and for the
`Search-UnifiedAuditLog`-based activity exports to be complete.
**Why required:** Activity Explorer is populated from the audit pipeline; with ingestion off, activity
reporting is empty or partial.
**How to verify:** `Get-AdminAuditLogConfig | Select UnifiedAuditLogIngestionEnabled` (Exchange Online
PowerShell) returns **True**; a `Search-UnifiedAuditLog` for a recent window returns rows.
`CLSREPORT-Discovery.ps1` reports the ingestion state.
**How to implement if missing:** Enable it (`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled
$true`) under change control — surfaced by `CLSREPORT-Set-Reporting.ps1` (`-Commit` gated). Allow time
for the pipeline to backfill before judging coverage.

## 2.5 Existing classification signal to report on (in-scope data — category GR4)
**Description:** There must be **published sensitivity labels**, **retention labels**, **sensitive
information types**, and/or **trainable classifiers** in the tenant, applied across the in-scope
workloads (Exchange, SharePoint, OneDrive, Teams), for the explorers to have anything to show.
**Why required:** Reporting is only as rich as the classification underneath it; a tenant with no
published labels or SIT detections will show near-empty explorers.
**How to verify:** `Get-Label`, `Get-ComplianceTag`, `Get-DlpSensitiveInformationType` return the
expected inventory; Content Explorer shows non-zero counts. `CLSREPORT-Scope-Health.ps1` inventories
what is available to report on.
**How to implement if missing:** Classification design/roll-out is a **separate** solution — this one
reports on the result. If the estate is largely unclassified, note that the coverage numbers are a
**baseline**, not a failure, and reference the labeling/SIT solutions.

## 2.6 A pilot reporting scope and change control (category GR6)
**Description:** A limited **pilot scope** — a subset of sites/mailboxes or a defined reporting boundary
tagged `Classification Reporting - Pilot` — to prove the reporting and dashboards on before granting the
full analyst audience, plus a **change-control** path for the role/audit changes.
**Why required:** Reporting itself is low-risk, but **granting Content Explorer Content Viewer** (which
exposes sensitive data) and **changing audit config** are governed actions that must be piloted and
approved.
**How to verify:** A named pilot scope and approver exist; the initial role grant targets a small pilot
analyst set before the full group.
**How to implement if missing:** Define the pilot scope and change window before running
`CLSREPORT-Set-Reporting.ps1 -Commit`.

## 2.7 PowerShell toolchain — S&C PowerShell + Exchange Online + Graph (category GR3)
**Description:** A workstation with the **ExchangeOnlineManagement** module (provides both
`Connect-IPPSSession` for Security & Compliance PowerShell and `Connect-ExchangeOnline` /
`Search-UnifiedAuditLog` / `Get-AdminAuditLogConfig`) and, optionally, **Microsoft Graph PowerShell**,
with a modern-auth / MFA-capable admin.
**Why required:** The five provided scripts and the exports run through these; `Export-ContentExplorerData`
and `Search-UnifiedAuditLog` live in this toolchain.
**How to verify:** `Connect-IPPSSession` and `Connect-ExchangeOnline` succeed; `Get-Command
Export-ContentExplorerData` resolves (its availability is tenant/version-dependent — **verify**).
**How to implement if missing:** `Install-Module ExchangeOnlineManagement` (and `Microsoft.Graph`),
confirm modern-auth sign-in, then run the scripts.
