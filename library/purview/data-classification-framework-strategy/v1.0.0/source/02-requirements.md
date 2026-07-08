# 2. Requirements Guide — Data Classification Framework & Strategy

Verify **every** requirement below before starting the Implementation Guide. These are the
**solution-specific** prerequisites for building the classification framework and its reference
implementation; they build on the shared **Global Requirements — Microsoft Purview Solutions**
(compliance licensing, least-privilege roles, Security & Compliance PowerShell + Graph toolchain,
in-scope workloads, compliance/records/legal stakeholders, and a pilot scope with change control).
Read the Global Requirements first; this guide does not repeat them.

> **Deferral note (governance / records / legal).** The **number of tiers, their names and
> definitions, the handling rules, the DLP enforcement decisions, the retention periods/actions, and
> any regulatory applicability** referenced here are **determinations owned by your governance,
> compliance, records, privacy, and legal functions** — not technical defaults. This solution
> provides the **framework method, the crosswalk, and the configuration + evidence**; it does not
> decide the scheme or the schedule. Confirm every tier, condition, and period with the accountable
> owner before enforcing.

---

## 2.1 Licensing for labels, DLP, and retention
- **Description:** Manual sensitivity labels, content marking, and encryption, plus baseline retention labels and DLP, are available at the Microsoft 365 E3 tier. **Advanced DLP** (some conditions, endpoint/cloud coverage), **auto-labeling**, **adaptive scopes**, and the **Data classification / activity & content explorer** reporting used for coverage require **Microsoft 365 E5** or the **E5 Compliance** add-on.
- **Why required:** The tier labels and a basic tier-aligned DLP/retention baseline can be built at E3; the coverage reporting and some advanced DLP conditions are E5-tier.
- **How to verify:** M365 admin center → subscriptions/add-ons; confirm the relevant feature is visible in the Purview portal (Information Protection, Data Loss Prevention, Data Lifecycle Management, Data classification). **Verify your licensing/tenant** — Microsoft's licensing tables are the authority.
- **How to implement if missing:** Build the framework and reference labels/retention at E3; assign E5 / E5 Compliance for the pilot before relying on advanced DLP conditions or coverage reporting.

## 2.2 Least-privilege roles across all three control families
- **Description:** Because the framework spans labels, DLP, and retention, the implementer needs (least privilege): **Information Protection Admin** (sensitivity labels + label policies), **Compliance Administrator** or **DLP Compliance Management** (DLP policies/rules), and **Records Management** or **Compliance Administrator** (retention labels + policies). Global Administrator is **not** required for day-to-day framework work.
- **Why required:** The cmdlets used are gated per family — `New-Label`/`New-LabelPolicy` (Information Protection), `New-DlpCompliancePolicy`/`New-DlpComplianceRule` (DLP), `New-ComplianceTag`/`New-RetentionCompliancePolicy` (retention).
- **How to verify:** Purview portal → **Roles & scopes → Permissions**; confirm the account is in the matching role groups.
- **How to implement if missing:** Add the account to the least-privilege role groups under change control; allow role propagation before running cmdlets.

## 2.3 Security & Compliance PowerShell connectivity
- **Description:** A workstation with the **ExchangeOnlineManagement** module (which provides `Connect-IPPSSession` for Security & Compliance PowerShell) and, where Graph is used for evidence, **Microsoft Graph PowerShell** — with a modern-auth / MFA-capable admin account.
- **Why required:** All five provided scripts and every configuration cmdlet run through `Connect-IPPSSession`.
- **How to verify:** `Connect-IPPSSession` succeeds and `Get-Label`, `Get-DlpCompliancePolicy`, and `Get-ComplianceTag` return without error.
- **How to implement if missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; confirm modern-auth sign-in. See the Global Requirements for the full toolchain.

## 2.4 An agreed tier model and classification standard (governance input)
- **Description:** The **tier model** — how many tiers, their names, definitions, and handling rules — agreed with governance/compliance owners, and the **classification standard** (the written scheme) this solution will document and implement. The four-tier model in §1 is a starting point, not a mandate.
- **Why required:** Every downstream artifact (labels, DLP, retention) keys off the tier model; without an agreed scheme the crosswalk is arbitrary.
- **How to verify:** A signed-off tier list (names + definitions + handling rules) exists and the accountable owner has approved it.
- **How to implement if missing:** Facilitate the tier-model decision with governance owners before authoring the crosswalk; capture it in the standard document.

## 2.5 In-scope workloads and the classifying conditions per tier
- **Description:** The **workloads in scope** (Exchange, SharePoint, OneDrive, Teams; endpoints where DLP/labeling apply) and the **conditions that define each tier in data** — the sensitive information types, keywords, or classifiers that make content "Confidential" or "Restricted" for both auto-labeling later and the DLP baseline now.
- **Why required:** The DLP baseline and any auto-labeling key off the in-scope workloads and the tier conditions; without agreed conditions the tiers can't be detected in content.
- **How to verify:** Confirm the in-scope workloads and the priority sensitive info types / classifiers with data owners; validate the info types exist in Purview → *Data classification → Sensitive info types*.
- **How to implement if missing:** Define the conditions per tier before authoring the DLP baseline and before any auto-labeling engagement.

## 2.6 A pilot ring and a test/simulation-first commitment
- **Description:** A named **pilot ring** (a small group of users/sites) to publish the tier labels to first, and an explicit commitment that the **tier-aligned DLP baseline is created in *test* mode** (`TestWithNotifications`/`TestWithoutNotifications`) and validated before enforcement, and that **encrypting labels and any retention delete actions are piloted** before broad rollout.
- **Why required:** DLP blocking, encryption, and retention deletion are high-impact and hard to reverse cleanly; the house model requires a test/simulate pass first.
- **How to verify:** Confirm the pilot ring membership (the group backing `CLS Policy – Pilot – Ring1`), a change window, and an approver.
- **How to implement if missing:** Create the pilot group and agree the change-control path before publishing or enforcing anything.

## 2.7 Rights-management (encryption) prerequisites for the protected tiers
- **Description:** For the tiers whose label **encrypts** (`Confidential`, `Restricted`), the tenant's **Azure Rights Management / unified labeling protection** service must be active, and you must decide the **rights model** (which users/groups get which usage rights) per encrypting label.
- **Why required:** An encrypting label cannot protect if the protection service is not enabled; the rights definition is required input to `New-Label -EncryptionEnabled`.
- **How to verify:** Confirm the protection (Rights Management) service is **activated**; confirm the target groups for each encrypting label's rights exist.
- **How to implement if missing:** Activate the protection service and create/confirm the mail-enabled security groups used in the rights definitions before building the protected-tier labels.
