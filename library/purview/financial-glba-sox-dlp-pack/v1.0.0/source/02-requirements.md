# 2. Requirements — Financial (GLBA/SOX) DLP Pack (Microsoft Purview)

These are the **solution-specific** prerequisites for implementing GLBA/SOX-aligned DLP for financial and
NPI data across endpoint, cloud, and email. They build on — and do not repeat — the six shared
prerequisites in **`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege
Purview roles, S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal
stakeholders, and a pilot scope + change control). Verify each item below before starting the
Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to
implement if missing**.

---

## 2.1 Licensing sufficient for the DLP features you will use — especially Endpoint DLP and advanced classifiers
- **Description:** DLP for **Exchange/SharePoint/OneDrive/Teams** with **built-in financial SITs** is
  broadly available, but **Endpoint DLP**, **Exact Data Match (EDM)**, **document fingerprinting**, and
  **trainable classifiers** are **plan-gated** — typically **Microsoft 365 E5** or the **E5 Compliance**
  add-on (some capabilities are in **preview**). This extends GR-#1 with the DLP-specific plan detail.
- **Why required:** A DLP policy scoped to a location or using a classifier your plan doesn't include will
  not function. Endpoint DLP for finance laptops in particular is an E5/E5-Compliance capability.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Purview portal → Data Loss Prevention** confirm the **Endpoint DLP** / **Devices** location and the
  classifier types (EDM, fingerprinting, trainable) you intend to use are visible. **Flag "verify your
  licensing/tenant"** — availability evolves.
- **How to implement if missing:** Acquire/assign the required licensing (E5 or E5 Compliance) before
  building endpoint or advanced-classifier policies; scope the initial rollout to features your plan
  covers (built-in financial SITs on mail/cloud work at lower tiers).

## 2.2 DLP-specific least-privilege roles (with author/triage separation for finance)
- **Description:** The **DLP role groups** in the Purview portal — **Compliance Administrator** or
  **Compliance Data Administrator** to create/manage DLP policies, **DLP Compliance Management** for policy
  management, **View-Only DLP Compliance Management** for read-only review, and the **Data Loss
  Prevention** role for alert/incident handling. Global Administrator only where genuinely required.
  Because financial matches are sensitive, **separate policy authors from alert triagers** where possible.
  Extends GR-#2.
- **Why required:** Purview enforces fine-grained role groups; DLP configuration and alert triage require
  the matching role, and least privilege plus author/triage separation keeps the blast radius small and
  supports segregation-of-duties expectations relevant to SOX.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** (Microsoft Purview
  roles) — confirm your account's role-group membership includes the DLP roles you need.
- **How to implement if missing:** Assign the least-privilege DLP role group under change control;
  document who authors policies versus who triages financial DLP alerts.

## 2.3 Devices onboarded to Purview for Endpoint DLP (finance/treasury endpoints)
- **Description:** Endpoint DLP monitors activities on **onboarded Windows 10/11 and macOS devices**.
  Onboarding is done in **Purview portal → Settings → Device onboarding** (or via Intune / a script /
  Group Policy) and is **shared with Microsoft Defender for Endpoint onboarding** — devices already
  onboarded to Defender for Endpoint are onboarded for Endpoint DLP. Prioritize **finance, treasury, and
  accounting endpoints** where financial files are handled.
- **Why required:** A DLP policy scoped to the **Devices** location does nothing on a device that is not
  onboarded and reporting. Onboarding is the hard prerequisite for any endpoint control.
- **How to verify:** **Purview portal → Settings → Device onboarding → Devices** shows onboarded devices;
  confirm target finance devices appear and are reporting.
- **How to implement if missing:** Onboard devices via the Purview device-onboarding package, Intune, or
  Group Policy; confirm the minimum OS build and any required Antimalware/AV state per Microsoft docs
  before scoping endpoint policies.

## 2.4 A financial/NPI classification intent and a sensitive-information-type inventory
- **Description:** A documented view of the **financial and NPI data you are protecting** (customer
  account numbers, bank routing/account numbers, card data, SSN/ITIN, GL extracts, financial statements,
  MNPI) mapped to the **SITs/classifiers** that detect it — built-in financial SITs and the **GLBA / U.S.
  Financial Data** DLP templates where they fit, **custom SITs / EDM / fingerprinting / trainable
  classifiers** where they don't. Extends GR-#4.
- **Why required:** DLP policies key off SITs; without knowing which financial data matters and which SIT
  detects it (at what confidence and instance count), policies are guesswork and generate false positives
  on GL codes, invoice IDs, and reference numbers.
- **How to verify:** **Purview portal → Data classification → Classifiers → Sensitive info types** lists
  built-in and custom SITs; confirm the financial ones you need exist (or are planned). Confirm the data
  categories with the data owners / controller's office.
- **How to implement if missing:** Build the SIT inventory (this pack's Discovery script assesses built-in
  financial-SIT coverage); plan custom SITs / EDM / fingerprinting for internal account numbers, GL codes,
  and statement templates not covered by built-ins.

## 2.5 Source data for Exact Data Match and statement fingerprinting (only if used)
- **Description:** For **EDM** SITs, a **sensitive data table** (e.g. an export of customer account
  records) and a workstation with the **EDM Upload Agent** to hash and upload it — raw data never leaves
  your control; only salted hashes are uploaded. For **document fingerprinting**, the **financial-statement
  templates** (e.g. the standard reporting workbook/letter formats) to fingerprint.
- **Why required:** EDM matches against *your actual account data*, driving false positives toward zero;
  fingerprinting matches your *actual statement templates*. Both require the source material and, for EDM,
  a **refresh cadence** as the data changes.
- **How to verify:** Confirm the source table, the EDM schema, the upload-agent host, and a scheduled
  refresh. **Purview portal → Data classification → Exact data matches** shows configured EDM schemas.
- **How to implement if missing:** Define the EDM schema and refresh process (deferred to the data owner
  for *which* fields are in scope); provide statement templates for fingerprinting. If EDM/fingerprinting
  is not in your plan or not needed, use custom SITs with confidence/keyword tuning instead.

## 2.6 A finance pilot ring, simulation dwell time, and change control (DLP-specific)
- **Description:** A named **finance pilot user/device ring** (`DLP Pilot Ring – Finance Stage1`), an
  agreed **simulation dwell time** (long enough to capture representative finance traffic — month-end and
  reporting cycles matter here), and the **change-control window** for moving simulation → enforce.
  Extends GR-#6.
- **Why required:** Financial DLP is high-impact; enforcing without a simulation baseline and a limited
  ring is how DLP breaks month-end close and payments. The house model mandates **simulation first**, then
  a ring, then expand.
- **How to verify:** Confirm the pilot ring membership, that **simulation mode** is selected on each new
  policy, and the approval path to enforce.
- **How to implement if missing:** Define the ring and dwell time (span at least one reporting cycle) and
  agree change control before enabling any enforcement action.

## 2.7 A financial DLP alert triage owner and destination
- **Description:** A named owner (or queue) for **financial DLP alerts** raised in **Purview portal → Data
  loss prevention → Alerts** (`DLP Alerts – Financial – Operations`), plus where events are reviewed
  (**Activity Explorer**) and, optionally, forwarded (SIEM/Microsoft Sentinel via the Office 365
  Management Activity API / Defender connectors). Severity and response actions defined; because matches
  may expose customer NPI, define **who may view match evidence**.
- **Why required:** A financial DLP match with no one to triage it is not a control. Alerts and Activity
  Explorer are where matches surface; someone must own triage, severity, and response — with appropriate
  handling of the NPI in the evidence.
- **How to verify:** Confirm the triage owner/queue, the alert-severity scheme, who may view NPI evidence,
  and any SIEM forwarding is configured.
- **How to implement if missing:** Assign the owner, define severity/response and evidence-access, and
  (optionally) wire SIEM forwarding before enforcement generates real alerts.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | DLP/Endpoint + advanced-classifier licensing (E5 / E5 Compliance; verify) | Endpoint, EDM, fingerprinting, trainable available |
| 2.2 | DLP least-privilege roles + author/triage separation | SoD-aware author + triage roles assigned |
| 2.3 | Finance devices onboarded to Purview | Endpoint location functional on finance endpoints |
| 2.4 | Financial/NPI classification intent + SIT inventory | Policies key off correct financial SITs |
| 2.5 | EDM source data / statement fingerprints (if used) | Near-zero-FP matching where needed |
| 2.6 | Finance pilot ring + simulation dwell + change control | Simulate-first enforced across a reporting cycle |
| 2.7 | Financial alert/incident triage owner + evidence access | NPI matches are acted on and evidence controlled |

> **Deferred to compliance/records/privacy/legal:** which data is NPI under GLBA, which records fall in
> SOX scope, which classifiers legally apply, the enforced action per category, retention obligations, and
> any regulatory applicability. This solution provides the technical configuration and evidence, not the
> determination.
