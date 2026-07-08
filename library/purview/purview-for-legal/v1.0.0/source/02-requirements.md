# 2. Requirements Guide — Microsoft Purview for Legal

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C
PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot &
change control) are in `global-requirements-purview.md` — this guide adds the **Legal-program** detail.

> **Legal/licensing boundary.** Encryption sensitivity labels, advanced & endpoint DLP,
> records/regulatory-records retention, and Audit Premium require **Microsoft 365 E5** or the **E5
> Compliance** add-on and evolve; confirm your entitlements rather than assuming. **What is privileged,
> how matters map to content, the retention schedule, and whether a matter is under legal hold** are
> **legal/records determinations** — this solution configures the control and produces evidence; it does
> not make the determination. Where this guide flags "verify your licensing/tenant" or "legal/records to
> determine," do so before relying on the item.

## 2.1 Compliance licensing for labels, DLP, retention, and audit evidence
**Description:** The program spans four licensed control domains. **Sensitivity labels with encryption**
and **auto/advanced-classification** need **E5 / E5 Compliance**; **DLP** for Exchange/SharePoint/OneDrive
is broadly available but **Teams DLP and Endpoint DLP** need **E5 / E5 Compliance**; **records /
regulatory-records retention** needs **E5 / E5 Compliance**; **Audit Premium** (long-term retention,
high-value events) needs **E5 / E5 Compliance / Audit add-on**, assigned **per user**.
**Why:** Every control below is plan-gated; the feature won't be available without the right plan (GR §1).
**Verify:** M365 admin center → `Billing → Licenses`; run `INDLEGAL-Discovery.ps1`, which reports whether
information-protection / DLP-endpoint / records / Audit-Premium-bearing plans are present via Graph.
**Confirm plan/service-plan names against your tenant — they change.**
**Implement:** Assign/purchase E5 or the relevant add-ons to the in-scope legal population before
expecting the feature.

## 2.2 Least-privilege roles for each control domain
**Description:** Distinct least-privilege roles — **Information Protection Admin** for sensitivity labels
& policies; **Compliance Administrator / DLP Compliance Management** for DLP; **Records Management /
Retention Management** for retention & disposition; **Audit Manager/Reader** for evidence; **Compliance
Manager** roles for assessments; and, referenced only, **eDiscovery Manager** for legal holds (owned by
legal). Global Administrator only where genuinely required.
**Why:** Purview uses fine-grained role groups; configuration requires the matching role, and hold/eDiscovery
access is legally sensitive and kept with the legal function (GR §2).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions` — confirm membership per domain;
`INDLEGAL-Scope.ps1` reports the role groups it can see and the connection identity.
**Implement:** Assign the least-privilege role groups under change control; keep eDiscovery/hold roles with legal.

## 2.3 Security & Compliance PowerShell + Graph toolchain
**Description:** A workstation with the `ExchangeOnlineManagement` module (for `Connect-IPPSSession` —
`*-Label`/`*-LabelPolicy`, `*-DlpCompliancePolicy`/`*-DlpComplianceRule`, `*-ComplianceTag`,
`*-RetentionCompliancePolicy`, `*-UnifiedAuditLogRetentionPolicy`, and read-only `Get-CaseHoldPolicy`)
and `Microsoft.Graph` (licensing reads), with a modern-auth / MFA admin.
**Why:** All configuration and the provided scripts run through Security & Compliance PowerShell and
Graph (GR §3).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession` and
`Connect-MgGraph` succeed; `INDLEGAL-Discovery.ps1` reports which endpoints are reachable.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`;
`Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.4 In-scope legal population, matters, workloads, and channels
**Description:** The **legal population** in scope (a group/OU of attorneys, paralegals, and legal staff),
the **workloads** holding privileged/matter content (Exchange, SharePoint matter sites, OneDrive, Teams),
the **channels** DLP must cover (email, Teams chat/channels, endpoints), and a **classification intent**
(what privileged / matter-confidential / work-product looks like) to drive labels and DLP.
**Why:** Labels, DLP, and retention controls key off the in-scope population/workloads/matters (GR §4).
**Verify:** Confirm the legal-population group, the matter sites/workloads, the DLP channels, and the
classification approach with legal; `INDLEGAL-Scope.ps1` enumerates the group's members and the
mailboxes/sites in scope (read-only).
**Implement:** Define the legal-population group, matter workloads, and classification intent before
authoring controls.

## 2.5 The obligation-to-control map, privilege scope, and records schedule (from legal/records)
**Description:** A documented statement — **from legal and records** — of which content is **privileged**
vs **matter-confidential**, how matters map to content, what must be **retained and for how long** (the
matter-records schedule), what triggers **disposition review**, and which matters carry a **legal hold**.
**Why:** Privilege determination, matter mapping, retention duration, and hold scope are **legal/records
determinations**, not technical defaults (GR §5); the solution configures to them and evidences them —
it does not decide them.
**Verify:** You can name, per control domain, the obligation, the required label/retention/DLP behavior,
the disposition trigger, and the named approver; these populate the `Control Map – Legal – Purview` register.
**Implement:** Capture the privilege scope, matter map, records schedule, and hold list with approvals
before configuring — especially before any **encryption** label or **regulatory-records** (irreversible) label.

## 2.6 DLP simulation, encryption, and disclosure preconditions
**Description:** For the high-impact controls specifically: agreement to build **DLP in simulation/test
mode** first (surface matches, block nothing), a decision on **encryption** behavior for the privileged
label (who can decrypt — internal only, specific groups, external counsel), and how the labels/DLP should
treat **external sharing** (co-counsel, courts, clients).
**Why:** An encryption label can make content unreadable to intended external recipients, and a DLP block
can interrupt legitimate legal sharing; both must be modeled before enforcement (GR §5/§6).
**Verify:** A named DLP simulation window, the agreed encryption/permission scope for the privileged
label, and the external-sharing exceptions legal requires.
**Implement:** Configure the privileged label's encryption/permissions to legal's decision, **build the
DLP policy in simulation**, and keep it there until match review and sign-off are complete.

## 2.7 Unified audit logging on, and an evidence-retention requirement
**Description:** `UnifiedAuditLogIngestionEnabled` must be **true** so the audit-trail control captures
evidence of label/DLP/retention/hold-related activity, plus a documented statement of how long audit
**evidence** must be retained for legal purposes.
**Why:** No audit evidence is written while ingestion is off, and it is **not retroactive**; retention
duration is a legal/compliance determination (GR §5/§6).
**Verify:** `INDLEGAL-Discovery.ps1` reports `UnifiedAuditLogIngestionEnabled` and existing audit
retention policies.
**Implement:** Enable unified audit under change control (Purview Audit solution / Exchange Online), then
create the evidence-retention policy in the Implementation Guide.

## 2.8 A pilot scope, simulation/test mode, and change control
**Description:** A bounded **pilot scope** (`Legal Pilot – Privileged Data – Stage1` — a small set of
attorneys/paralegals, matter sites, and benign test content) and a **change-control** window. Sensitivity
labels can be published to the pilot first; DLP supports **simulation mode**; retention can be trialed
with a **non-regulatory** label first; audit changes are reversible.
**Why:** Encryption labels, DLP, and records retention are **high-impact** — regulatory records are
effectively irreversible — so every change is piloted in simulation/test/disabled mode before enforcement
(GR §6).
**Verify:** A named pilot scope, confirmation that simulation/test/disabled mode is available for each
control, and a change window/approval path.
**Implement:** Define the pilot scope and agree change control before enabling or enforcing any control —
**never enforce a DLP block or apply a regulatory-records label outside the pilot without explicit
legal/records sign-off, and never create/release a legal hold as part of this work (legal's decision).**
