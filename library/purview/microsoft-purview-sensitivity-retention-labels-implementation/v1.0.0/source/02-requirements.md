# 2. Requirements Guide — Sensitivity & Retention Labels (Implementation)

Verify **every** requirement below before starting the Implementation Guide. These are the
**solution-specific** prerequisites for building sensitivity and retention labels; they build on the
shared **Global Requirements — Microsoft Purview Solutions** (licensing, least-privilege roles,
Security & Compliance PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal
stakeholders, and a pilot scope with change control). Read the Global Requirements first; this guide
does not repeat them.

> **Deferral note (records/legal).** The **retention periods, disposition actions, records
> declarations, and any legal holds** referenced here are **determinations owned by your records,
> compliance, privacy, and legal functions** — not technical defaults. This solution provides the
> **configuration method and evidence**; it does not decide the schedule. Confirm every period and
> action with the accountable owner before enforcing.

---

## 2.1 Licensing for labels, protection, and auto-labeling
- **Description:** Manual sensitivity labels, content marking, and encryption are available broadly (Microsoft 365 E3 tier covers manual sensitivity labeling and encryption). **Client-side automatic labeling** and **service-side auto-labeling** for SharePoint/OneDrive/Exchange, along with several advanced classifiers, require **Microsoft 365 E5** or the **E5 Compliance** add-on. Retention labels and retention label policies are available at E3; **adaptive scopes** and advanced retention features are E5-tier.
- **Why required:** The auto-labeling and adaptive-scope steps in this solution will not be available without the right plan.
- **How to verify:** M365 admin center → subscriptions/add-ons; confirm the relevant feature is visible in the Purview portal (Information Protection → *Auto-labeling*; Data Lifecycle Management → *Adaptive scopes*). **Verify your licensing/tenant** — Microsoft's licensing tables are the authority.
- **How to implement if missing:** Assign/purchase E5 or E5 Compliance for the pilot users before configuring auto-labeling; you can still implement manual labels + publishing at E3.

## 2.2 Information Protection & Records Management roles (least privilege)
- **Description:** The Purview role groups this solution needs: **Information Protection Admin** (create/manage sensitivity labels and label policies and auto-labeling), and **Records Management** or **Compliance Administrator** (create/manage retention labels, retention policies, and adaptive scopes). Global Administrator is **not** required for day-to-day label work.
- **Why required:** Sensitivity-label cmdlets (`New-Label`, `New-LabelPolicy`, `New-AutoSensitivityLabelPolicy`) and retention cmdlets (`New-ComplianceTag`, `New-RetentionCompliancePolicy`, `New-AdaptiveScope`) are gated by these role groups.
- **How to verify:** Purview portal → **Roles & scopes → Permissions**; confirm your admin account is in *Information Protection* and *Records Management* (or *Compliance Administrator*).
- **How to implement if missing:** Add the admin to the least-privilege role group under change control; wait for role propagation before running cmdlets.

## 2.3 Security & Compliance PowerShell connectivity
- **Description:** A workstation with the **ExchangeOnlineManagement** module (which provides `Connect-IPPSSession` for Security & Compliance PowerShell) and, where Graph is used for evidence, **Microsoft Graph PowerShell** — with a modern-auth / MFA-capable admin account.
- **Why required:** All five provided scripts and every configuration cmdlet run through `Connect-IPPSSession`.
- **How to verify:** `Connect-IPPSSession` succeeds and `Get-Label` returns without error.
- **How to implement if missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; confirm modern-auth sign-in. See the Global Requirements for the full toolchain.

## 2.4 In-scope workloads and a classification scheme
- **Description:** The **workloads in scope** (Exchange, SharePoint, OneDrive, Teams; endpoints where client-side labeling applies) and the **classification/sensitivity scheme** that drives the taxonomy — the sensitive information types, keywords, or trainable classifiers that define what "Confidential" or "Financial" actually means in your data.
- **Why required:** Auto-labeling rules and retention scoping key off the in-scope workloads and the classification conditions; without an agreed scheme the labels are arbitrary.
- **How to verify:** Confirm the in-scope workloads and the sensitive info types / classifiers with stakeholders; validate the info types exist in Purview → *Data classification → Sensitive info types*.
- **How to implement if missing:** Define the scheme and the priority sensitive info types before authoring auto-labeling rules.

## 2.5 A pilot ring and a simulation-first commitment
- **Description:** A named **pilot ring** (a small group of users/sites) to publish labels to first, and an explicit commitment that **service-side auto-labeling is created in *simulation* mode** and validated before enforcement, and that **encrypting labels and retention (delete) labels are piloted** before broad rollout.
- **Why required:** Encryption and auto-labeling/retention deletion are high-impact and hard to reverse cleanly; the house model requires a simulate/test pass first.
- **How to verify:** Confirm the pilot ring membership (e.g. the group backing `SL Policy – Pilot – Ring1`), a change window, and an approver.
- **How to implement if missing:** Create the pilot group and agree the change-control path before publishing anything.

## 2.6 Rights-management (encryption) prerequisites
- **Description:** For sensitivity labels that **encrypt**, the tenant's **Azure Rights Management / unified labeling protection** service must be active, and you must decide the **rights model** (which users/groups get which usage rights — e.g. Co-Author, Reviewer, View-only) per encrypting label.
- **Why required:** An encrypting label cannot be published or will fail to protect if the protection service is not enabled; the rights definition is required input to `New-Label -EncryptionEnabled`.
- **How to verify:** Purview / Microsoft 365 → confirm the protection (Rights Management) service is **activated**; confirm the target groups for each encrypting label's rights exist.
- **How to implement if missing:** Activate the protection service and create/confirm the mail-enabled security groups used in the rights definitions before building encrypting labels.

## 2.7 Adaptive-scope query attributes are populated
- **Description:** For **adaptive scopes**, the directory/site **attributes the query keys off** (e.g. `Department`, `CountryOrRegion`, a SharePoint site property) must be reliably populated on the target users/sites.
- **Why required:** An adaptive scope built on `Department -eq "Finance"` only covers users whose `Department` attribute is actually set; sparse attributes mean silent gaps in retention coverage.
- **How to verify:** Sample the target population and confirm the query attribute is populated; run the scope preview before binding it to a policy.
- **How to implement if missing:** Backfill the attribute (HR sync / directory hygiene) before relying on the adaptive scope; document the coverage assumption.
