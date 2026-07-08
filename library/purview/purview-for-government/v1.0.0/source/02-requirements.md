# 2. Requirements Guide — Microsoft Purview for Government

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C PowerShell +
Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot & change control) are in
`global-requirements-purview.md` — this guide adds the **Government-program** detail (CJIS/CMMC/ITAR,
sensitivity labels, DLP/endpoint DLP, and the sovereign-cloud specifics).

> **Regulatory/licensing/cloud boundary.** Label encryption, auto-labeling, advanced and **endpoint DLP**,
> Audit Premium, and premium Compliance Manager templates require **Microsoft 365 E5** or the **E5
> Compliance** add-on (in the government SKU) and evolve; behavior and endpoints **differ by cloud**
> (GCC/GCC High/DoD). **Which data is CJI/CUI/ITAR, which CMMC level applies, retention schedules, and
> whether a configuration satisfies CJIS/CMMC/NIST 800-171/ITAR** are **compliance/security/records/legal
> determinations** — this solution configures the control and produces evidence; it does not make the
> determination, and makes **no authorization/certification claim.** Where this guide flags "verify your
> licensing/tenant/cloud," do so before relying on the item.

## 2.1 Government tenant, cloud, and compliance licensing
**Description:** A Microsoft 365 **government** tenant, and knowledge of **which cloud** it is —
**Commercial**, **GCC**, **GCC High**, or **DoD**. The program's control domains are plan-gated:
**sensitivity-label encryption + auto-labeling** and **advanced/endpoint DLP** need **E5 / E5 Compliance**;
**Audit Premium** (long-term retention, high-value events) needs **E5 / E5 Compliance / Audit add-on**;
premium **Compliance Manager** templates are licensing-gated. ITAR/CUI workloads are frequently **required**
to run in **GCC High** or higher.
**Why:** Every control below is plan- and cloud-gated; the feature may be unavailable, or behave/route
differently, without the right plan and cloud (GR §1).
**Verify:** M365 admin center → `Billing → Licenses`; confirm the cloud (GCC/GCC High/DoD) with your tenant
admin; run `INDGOV-Discovery.ps1`, which reports whether label/DLP/Audit-Premium-bearing plans are present
via Graph. **Confirm plan/service-plan names against your tenant and cloud — they differ and change.**
**Implement:** Assign/purchase E5 or the relevant add-ons to in-scope users; where ITAR/CUI mandates it,
confirm the tenant is in the required cloud **before** relying on the controls.

## 2.2 Least-privilege roles for labels, DLP, records, and audit
**Description:** Distinct least-privilege roles per domain — **Information Protection** (Admin/Analyst/
Investigator/Reader) for **sensitivity labels**; **Compliance Administrator / DLP Compliance Management** for
**DLP and endpoint DLP**; **Records Management / Retention Management** for retention; **Audit Manager/Reader**
for evidence; **Compliance Manager** roles for the assessment. Global Administrator only where genuinely
required.
**Why:** Purview uses fine-grained role groups; configuration requires the matching role, and separating
duties (who configures vs who reviews DLP matches / reads audit evidence) is itself a control (GR §2).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions` — confirm membership per domain;
`INDGOV-Scope.ps1` reports the role groups it can see and the connection identity.
**Implement:** Assign the least-privilege role groups under change control; document who may read DLP matches
and audit evidence (they are sensitive).

## 2.3 Security & Compliance PowerShell + Graph toolchain — with the correct cloud endpoints
**Description:** A workstation with the `ExchangeOnlineManagement` module (for `Connect-IPPSSession` —
sensitivity labels `*-Label`/`*-LabelPolicy`, DLP `*-DlpCompliancePolicy`/`*-DlpComplianceRule`, retention
`*-ComplianceTag`/`*-RetentionCompliancePolicy`, `*-UnifiedAuditLogRetentionPolicy`) and `Microsoft.Graph`
(licensing reads), with a modern-auth/MFA admin. **In a sovereign cloud you must pass the cloud endpoint:**
`Connect-IPPSSession -ConnectionUri <your cloud's S&C endpoint>` and `Connect-MgGraph -Environment
USGov|USGovDoD`.
**Why:** All configuration and the provided scripts run through S&C PowerShell and Graph; **the default
(commercial) endpoints will not connect a GCC High/DoD tenant** (GR §3).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession` (with the cloud
`-ConnectionUri` if applicable) and `Connect-MgGraph -Environment …` succeed; `INDGOV-Discovery.ps1` reports
which endpoints are reachable. **Confirm the exact `-ConnectionUri`/`-Environment` for your cloud from
Microsoft's current documentation.**
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; `Install-Module Microsoft.Graph
-Scope CurrentUser`; record your cloud's connection parameters in the runbook.

## 2.4 In-scope controlled data, workloads, endpoints, and classification intent
**Description:** The **CJI / CUI / ITAR data** in scope, the **workloads** holding it (Exchange, SharePoint,
OneDrive, Teams) and the **endpoints/devices** to control (for endpoint DLP), plus a **classification
intent** (which sensitivity label maps to CJI, CUI, ITAR) that drives labels and DLP. **Endpoint DLP requires
devices to be onboarded.**
**Why:** Labels, DLP, and endpoint DLP key off the in-scope data/workloads/devices and the classification
scheme (GR §4).
**Verify:** Confirm the in-scope controlled-data types, workloads, and (for endpoint DLP) onboarded devices
with security/compliance; `INDGOV-Scope.ps1` enumerates the target population, in-scope mailboxes/sites, and
reports device-onboarding readiness pointers (read-only).
**Implement:** Define the controlled-data scope and classification intent, and onboard the pilot devices for
endpoint DLP, before authoring policies. **Which data *is* CJI/CUI/ITAR is a compliance/security
determination.**

## 2.5 The obligation-to-control map (from compliance/security/records/legal)
**Description:** A documented statement — **from compliance, security, records, and legal** — of which
obligations are in scope (CJIS Security Policy, CMMC level / NIST SP 800-171, ITAR), which data each governs,
what must be **retained and for how long**, and who approves. This populates
`Control Map – Gov – Purview`.
**Why:** Rule applicability, CMMC level, data classification, and retention duration are
**regulatory/security/legal determinations**, not technical defaults (GR §5); the solution configures to them
and evidences them — it does not decide them.
**Verify:** You can name, per obligation, the controlled-data type, the required control (label/DLP/retention/
audit), and the named approver.
**Implement:** Capture the obligation-to-control map and retention schedule with approvals before configuring
— especially before publishing an **encrypting** label or enforcing any **DLP**.

## 2.6 ITAR / encryption / access preconditions
**Description:** For the ITAR and encrypting-label controls specifically: agreement on **who may decrypt**
(e.g. U.S.-person access constraints for ITAR technical data), the label's **encryption/rights** definition,
whether **guest/external** access must be blocked, and the disposition of DLP matches involving controlled
data.
**Why:** An encrypting label changes who can open a file, and ITAR access is a legal constraint — mis-scoped
access or decryption is a control failure and potentially an export event (GR §5, and the category's
sensitivity rules). **Whether a given access configuration satisfies ITAR is legal's determination.**
**Verify:** Named decryption/access rules, an approved encryption/rights definition per label, and a
sign-off on external-access posture.
**Implement:** Obtain the access/encryption sign-off; define the label's rights in-portal; **pilot the label
on non-production content** and confirm access outcomes before broad publish.

## 2.7 Unified audit logging on, and an evidence-retention requirement
**Description:** `UnifiedAuditLogIngestionEnabled` must be **true** so the audit-trail control captures
evidence, plus a documented statement of how long audit **evidence** must be retained (e.g. for CJIS/CMMC
audit-log requirements).
**Why:** No audit evidence is written while ingestion is off, and it is **not retroactive**; retention
duration is a compliance determination (GR §5/§6).
**Verify:** `INDGOV-Discovery.ps1` reports `UnifiedAuditLogIngestionEnabled` and existing audit retention
policies. **Confirm long-term retention is licensed/available in your cloud.**
**Implement:** Enable unified audit under change control, then create the evidence-retention policy in the
Implementation Guide.

## 2.8 A pilot scope, simulation/test mode, and change control
**Description:** A bounded **pilot scope** (`Gov Pilot – Controlled Data – Stage1` — a small set of users/
sites/devices) and a **change-control** window. **DLP and endpoint DLP support a simulation/test mode** that
MUST be used before enforcement; encrypting labels are piloted on non-production content first; retention/
audit changes are reversible.
**Why:** Encrypting labels, DLP, endpoint DLP, and retention are **high-impact** — a DLP block can halt
mission work and an encrypting label changes access — so every change is piloted in simulation/test mode
before enforcement (GR §6).
**Verify:** A named pilot scope, confirmation that simulation/test mode is available for DLP/endpoint DLP in
your cloud, and a change window/approval path.
**Implement:** Define the pilot scope and agree change control before enabling or enforcing any control —
**never move a DLP policy from simulation to enforce, or publish an encrypting label broadly, without
validation and sign-off.**
