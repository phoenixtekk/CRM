# 2. Requirements Guide — Microsoft Purview SOX Compliance Program

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C
PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot &
change control) are in `global-requirements-purview.md` — this guide adds the SOX-specific detail.

> **Licensing/tenant boundary.** The advanced controls this program relies on — content-aware **DLP**,
> **auto-labeling**, **long-term audit retention**, and **Compliance Manager** premium assessment
> templates — require **Microsoft 365 E5** or the **E5 Compliance** add-on, and some are in preview.
> Where this guide flags "verify your licensing/tenant," confirm the capability is present and the
> portal path is current before relying on it — Purview evolves. Baseline classification, manual
> labels, and Audit Standard are available at lower tiers.

> **Determination boundary.** SOX record-retention periods, which data is financially relevant to ICFR,
> legal holds, and control-design/operating-effectiveness conclusions are **management, internal-audit,
> records, and legal determinations** (GR §5). This solution configures to them and produces evidence;
> it does not make them.

## 2.1 Compliance licensing for the SOX control set
**Description:** Baseline classification, manual sensitivity labels, and **Audit Standard** are broadly available; **advanced DLP** (content-aware conditions, simulation reporting at scale), **auto-labeling**, **long-term audit retention**, and **Compliance Manager premium templates** (a SOX/ICFR-relevant assessment) require **E5** or the **E5 Compliance** add-on.
**Why:** Several program controls are plan-gated; the feature won't be available without the right plan (GR §1).
**Verify:** M365 admin center → `Billing → Licenses`; and run `PURVSOX-Scope.ps1`, which reads `subscribedSkus`/service plans via Graph and reports whether E5/E5-Compliance-bearing plans are present. Confirm **Compliance Manager** and **DLP** are visible in the Purview portal.
**Implement:** Assign/purchase E5 or the E5 Compliance add-on to the in-scope users before expecting the advanced controls; the baseline (manual labels, Audit Standard, basic retention) can proceed at E3.

## 2.2 Least-privilege Purview roles (with SOX-relevant separation)
**Description:** The role groups the program touches: **Compliance Administrator** / **Compliance Data Administrator** (labels, DLP, retention), **Information Protection** roles (labels), **Records Management** (retention), **Audit Manager/Reader** (audit search & retention policies), and **Compliance Manager** access. For SOX **segregation of duties**, the person who *configures* a control should not be the sole party who *reviews its evidence* — separate configuring and reviewing roles.
**Why:** Purview uses fine-grained role groups; configuration requires the matching role, and SoD is itself a SOX control (GR §2).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions` — confirm memberships. `PURVSOX-Scope.ps1` reports the role groups and their members for review.
**Implement:** Assign the least-privilege role groups under change control; document the configure-vs-review separation. Reserve Global Administrator for one-time enablement only.

## 2.3 Security & Compliance PowerShell + Exchange Online PowerShell + Graph
**Description:** The `ExchangeOnlineManagement` module provides **both** `Connect-IPPSSession` (Security & Compliance PowerShell — labels, DLP, retention, and the `*-UnifiedAuditLogRetentionPolicy` cmdlets) **and** `Connect-ExchangeOnline` (`Search-UnifiedAuditLog`, `Get/Set-AdminAuditLogConfig`). `Microsoft.Graph` is used for licensing/role reads.
**Why:** Configuration, evidence collection, and the provided scripts run through these (GR §3). **Note:** most SOX control cmdlets are S&C PowerShell (`Connect-IPPSSession`); audit search/config is Exchange Online (`Connect-ExchangeOnline`).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; both `Connect-IPPSSession` and `Connect-ExchangeOnline` succeed with a modern-auth/MFA admin. `PURVSOX-Scope.ps1` connects and reports which endpoints are reachable.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.4 Unified audit logging enabled (the evidence foundation)
**Description:** `UnifiedAuditLogIngestionEnabled` must be **true** for the tenant so financial-data access, sharing, label, and configuration-change events are captured. On by default for newer tenants but may be off.
**Why:** The audit trail is the primary SOX evidence for IT operations and access; **it is not retroactive** — nothing is captured while ingestion is off (GR §6 change discipline).
**Verify:** `Get-AdminAuditLogConfig | Format-List UnifiedAuditLogIngestionEnabled` (via `Connect-ExchangeOnline`); `PURVSOX-Discovery.ps1` reports the state.
**Implement:** `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true` under change control (activation can take time); enable **before** the review period you intend to evidence.

## 2.5 Defined SOX scope: financial data, systems, and records schedule
**Description:** A documented statement — **from your SOX/ICFR, finance, records, and internal-audit owners** — of which data and workloads are **financially relevant** (SharePoint sites / Teams / mailboxes / OneDrive holding financial reporting data), which **evidence** the external auditor expects, and the **retention schedule** for SOX records.
**Why:** Labels, DLP, and retention key off the in-scope data and the classification/records intent, not technical defaults (GR §4, §5); scoping is a determination, not a guess.
**Verify:** You can name the in-scope workloads/sites, the classification intent for financial data, the retention schedule, and named approvers.
**Implement:** Capture the scope, classification intent, retention schedule, and evidence expectations before authoring any control.

## 2.6 Compliance Manager assessment for SOX/ICFR (if using)
**Description:** **Microsoft Purview Compliance Manager** with an assessment template that maps to your SOX/ICFR control set (a SOX/SOC-type template, or a custom template) so the Purview controls roll up as **improvement actions** with evidence.
**Why:** Compliance Manager is the control-mapping and evidence-rollup surface; it turns the configured controls into an auditable ICFR view.
**Verify:** Purview portal → **Compliance Manager** is visible (licensing 2.1); a SOX/ICFR-relevant template is available to add — **verify template availability for your licensing/tenant** (templates and their names differ by plan and evolve). `PURVSOX-Scope.ps1` flags whether Compliance Manager is reachable.
**Implement:** Add the SOX/ICFR (or a custom) assessment in Compliance Manager and name it `SOX ICFR – Purview Controls – Assessment`; if no suitable template is licensed, map the controls in a custom assessment or maintain the mapping alongside this guide.

## 2.7 A pilot scope and change window
**Description:** A limited **pilot** — a **finance ring** (`SOX Pilot – Finance Ring – Stage1`): a small set of finance users/sites — to validate the label, DLP-in-simulation, retention, and audit controls before tenant-wide enforcement, plus an agreed change window (GR §6).
**Why:** DLP, labels, and retention are high-impact; SOX changes must be change-controlled and reversible. **DLP supports a simulation/test mode that MUST be used before enforcement.**
**Verify:** A named pilot scope and change approval exist; DLP simulation mode is available in your tenant.
**Implement:** Define the finance-ring pilot and change window before configuring; keep DLP in simulation until the pilot passes.
