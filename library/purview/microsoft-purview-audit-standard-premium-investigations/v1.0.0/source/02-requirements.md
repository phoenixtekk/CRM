# 2. Requirements Guide — Microsoft Purview Audit (Standard & Premium)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C
PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot &
change control) are in `global-requirements-purview.md` — this guide adds the audit-specific detail.

> **Licensing/tenant boundary.** Audit Premium capabilities (`MailItemsAccessed` and other high-value
> events, one-year default retention, custom retention policies, ten-year retention, higher Management
> Activity API bandwidth) require **Microsoft 365 E5** or the **E5 Compliance / Audit** add-on and are
> assigned **per user**. Portal paths and search tooling are **evolving** — confirm the current method
> and your entitlements rather than assuming. Where this guide flags "verify your licensing/tenant,"
> do so before relying on the feature.

## 2.1 Compliance licensing for the audit tier you need
**Description:** Audit **Standard** is included with most Microsoft 365 subscriptions; **Audit Premium** (high-value events, one-year retention, custom retention policies) requires **E5** or the **E5 Compliance / Audit** add-on, assigned to the users/mailboxes you want covered. Ten-year retention is a further add-on.
**Why:** `MailItemsAccessed` and long-term retention only exist where the Premium license is assigned; unlicensed users won't generate those events (GR §1).
**Verify:** M365 admin center → `Billing → Licenses`; and run `PURVAUDIT-Discovery.ps1`, which reads `subscribedSkus`/service plans via Graph and reports whether an Audit Premium-bearing plan is present and how many users carry it.
**Implement:** Assign/purchase E5 or the Audit add-on to the in-scope users before expecting Premium events; add the ten-year add-on only if your records schedule requires it.

## 2.2 Audit roles (least-privilege)
**Description:** To **search** the audit log you need the **View-Only Audit Logs** or **Audit Logs** role (in the Exchange Online / Purview role model); the Purview **Audit Manager** and **Audit Reader** role groups package these. To **create retention policies** you need the **Audit Logs** role (write). Reserve Global Administrator for tenant-wide enablement only.
**Why:** Purview uses fine-grained roles; search, configuration, and export each need the matching role (GR §2).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions` — confirm membership of Audit Reader/Manager (or the underlying roles). `PURVAUDIT-Search.ps1` reports a permissions error if the role is missing.
**Implement:** Assign the least-privilege Audit role group under change control; investigators get **Audit Reader**, the configuring admin gets **Audit Manager**.

## 2.3 Exchange Online PowerShell + Security & Compliance PowerShell + Graph
**Description:** The `ExchangeOnlineManagement` module provides **both** `Connect-ExchangeOnline` (for `Search-UnifiedAuditLog`, `Get/Set-AdminAuditLogConfig`, mailbox-audit cmdlets) **and** `Connect-IPPSSession` (Security & Compliance PowerShell, for the `*-UnifiedAuditLogRetentionPolicy` cmdlets). `Microsoft.Graph` is used for licensing reads and the Audit Log Query API.
**Why:** Audit is split across two S&C/Exchange endpoints plus Graph — the scripts use the right one for each task (GR §3). **Note:** retention-policy cmdlets are S&C PowerShell (`Connect-IPPSSession`); search/config cmdlets are Exchange Online (`Connect-ExchangeOnline`).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; both `Connect-ExchangeOnline` and `Connect-IPPSSession` succeed with a modern-auth/MFA admin. `PURVAUDIT-Discovery.ps1` connects and reports which endpoints are reachable.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.4 Unified audit logging enabled
**Description:** `UnifiedAuditLogIngestionEnabled` must be **true** for the tenant. It is on by default for newer tenants but may be off (older tenants, or if disabled).
**Why:** No searchable audit records are written while ingestion is off — and it is not retroactive (GR §6 discipline: change under control).
**Verify:** `Get-AdminAuditLogConfig | Format-List UnifiedAuditLogIngestionEnabled` (via `Connect-ExchangeOnline`); `PURVAUDIT-Discovery.ps1` reports the state.
**Implement:** `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true` (may take time to fully activate) — `PURVAUDIT-Set-RetentionPolicy.ps1 -EnableUnifiedAudit -Commit` performs this under the pilot/change discipline.

## 2.5 Mailbox auditing on (and no unexpected bypass)
**Description:** Mailbox auditing (which produces `MailItemsAccessed`, `Send`, `New-InboxRule`, etc.) should be enabled org-wide, and no in-scope mailbox should be on the **audit bypass** list.
**Why:** Mailbox audit bypass silently suppresses mailbox events for an account — a common reason an investigation finds "nothing" for a specific user.
**Verify:** `Get-OrganizationConfig | Format-List AuditDisabled` (should be `False`); `PURVAUDIT-Discovery.ps1` reports org mailbox-audit state and enumerates any `Get-MailboxAuditBypassAssociation` where bypass is enabled.
**Implement:** Ensure `AuditDisabled` is `False`; remove unintended bypass with `Set-MailboxAuditBypassAssociation -AuditBypassEnabled $false` (change-controlled).

## 2.6 Defined retention & investigation requirements (from compliance/legal)
**Description:** A documented statement — **from your compliance, records, privacy, and legal functions** — of how long which audit evidence must be retained, and which incident scenarios must be answerable.
**Why:** Retention duration and legal-hold obligations are governance determinations, not technical defaults (GR §5); the solution configures to them, it does not decide them.
**Verify:** You can name the required retention per record-type class (e.g. privileged actions, mailbox high-value, sign-ins) and the investigation scenarios in scope, with named approvers.
**Implement:** Capture the retention/investigation requirements and approvals before authoring retention policies.

## 2.7 SIEM / export target and its identity (if exporting)
**Description:** A destination for continuous audit export — a **SIEM** (Microsoft Sentinel, Splunk, etc.) and, for the **Office 365 Management Activity API**, an **Entra app registration** with `ActivityFeed.Read` (and `ActivityFeed.ReadDlp` for DLP events), authenticating with a **certificate** (no client secret in scripts).
**Why:** Export enables continuous monitoring and retention beyond the audit store; the Management Activity API needs an app identity with the right permissions.
**Verify:** The SIEM/target is identified; the app registration exists with the API permissions granted (admin consent); `PURVAUDIT-Export.ps1` (read-only) lists current content subscriptions with the app's certificate.
**Implement:** Register the app, grant + consent the `ActivityFeed.*` permissions, upload a certificate, and record the target — or plan to use a native connector (e.g. Sentinel's Office 365 / Microsoft 365 connector) instead of the raw API.

## 2.8 A pilot scope and change window
**Description:** A limited **pilot** — a small investigator group and a bounded set of record types — to validate search, retention, and export on before tenant-wide change, plus an agreed change window (GR §6).
**Why:** Enabling ingestion, altering retention, and starting export are tenant-impacting; validate them small first.
**Verify:** A named pilot scope (`Audit Pilot – Investigators – Stage1`) and change approval exist.
**Implement:** Define the pilot group and change window before enabling or exporting anything.
