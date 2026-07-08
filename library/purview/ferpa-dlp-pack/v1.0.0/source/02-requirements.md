# 2. Requirements — FERPA DLP Pack (Microsoft Purview)

These are the **solution-specific** prerequisites for implementing FERPA-aligned education-record DLP across
endpoint, cloud, and email. They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles,
S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and
a pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to implement
if missing**.

---

## 2.1 Licensing sufficient for the DLP features you will use — especially Endpoint DLP
- **Description:** DLP for **Exchange/SharePoint/OneDrive/Teams** and **built-in SITs** is broadly available,
  but **Endpoint DLP**, **advanced/custom classifiers**, **Exact Data Match**, and **trainable classifiers**
  are **plan-gated** — typically **Microsoft 365 E5** or the **E5 Compliance** add-on (some capabilities are
  in **preview**). Many institutions run **Microsoft 365 A3/A5 (Education)** SKUs; confirm the DLP features
  you need are included in your specific A-plan. This extends GR-#1 with the DLP-specific plan detail.
- **Why required:** A DLP policy scoped to a location or using a classifier your plan doesn't include will not
  function. Endpoint DLP and EDM in particular are E5/E5-Compliance (or A5) capabilities.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons (A3/A5/E5/E5
  Compliance); in the **Purview portal → Data Loss Prevention** confirm the **Endpoint DLP** and **Devices**
  location and the classifier types you intend to use are visible. **Flag "verify your licensing/tenant"** —
  availability evolves.
- **How to implement if missing:** Acquire/assign the required licensing before building endpoint or
  advanced-classifier policies; scope the initial rollout to features your plan covers.

## 2.2 DLP-specific least-privilege roles
- **Description:** The **DLP role groups** in the Purview portal — **Compliance Administrator** or
  **Compliance Data Administrator** to create/manage DLP policies, **DLP Compliance Management** for policy
  management, **View-Only DLP Compliance Management** for read-only review, and the **Data Loss Prevention**
  role for alert/incident handling. Global Administrator only where genuinely required. Extends GR-#2.
- **Why required:** Purview enforces fine-grained role groups; DLP configuration and alert triage require the
  matching role, and least privilege keeps the blast radius small — especially important where alert
  evidence may itself contain student PII.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** (or Microsoft Purview
  roles) — confirm your account's role-group membership includes the DLP roles you need.
- **How to implement if missing:** Assign the least-privilege DLP role group under change control; separate
  policy authors from alert triagers where possible.

## 2.3 Devices onboarded to Purview for Endpoint DLP
- **Description:** Endpoint DLP monitors activities on **onboarded Windows 10/11 and macOS devices** —
  faculty and staff laptops are the endpoints where records are copied to USB, printed, or uploaded.
  Onboarding is done in **Purview portal → Settings → Device onboarding** (or via Intune / a script / Group
  Policy) and is **shared with Microsoft Defender for Endpoint onboarding** — devices already onboarded to
  Defender for Endpoint are onboarded for Endpoint DLP.
- **Why required:** A DLP policy scoped to the **Devices** location does nothing on a device that is not
  onboarded and reporting. Onboarding is the hard prerequisite for any endpoint control.
- **How to verify:** **Purview portal → Settings → Device onboarding → Devices** shows onboarded devices;
  confirm target devices appear and are reporting.
- **How to implement if missing:** Onboard devices via the Purview device-onboarding package, Intune, or
  Group Policy; confirm the minimum OS build and any required Antimalware/AV state per Microsoft docs before
  scoping endpoint policies.

## 2.4 An education-record classification intent and a student-identifier SIT inventory
- **Description:** A documented view of **which education records and identifiers you are protecting**
  (student ID numbers, SSNs, grades/transcripts, disciplinary and counseling records, financial-aid data,
  and the PII tied to them) mapped to the **SITs/classifiers** that detect them — built-in SITs where they
  fit (e.g. *U.S. SSN*, *All Full Names*), and a **custom SIT / EDM / trainable classifier** for local
  student identifiers and record types. Extends GR-#4.
- **Why required:** DLP policies key off SITs; there is no reliable built-in "student ID" detector, so
  without a custom SIT tuned to your ID scheme (and knowing at what confidence/instance count it should
  fire), policies are guesswork and generate false positives.
- **How to verify:** **Purview portal → Data classification → Classifiers → Sensitive info types** lists
  built-in and custom SITs; confirm the ones you need exist (or are planned). Confirm the record categories
  and identifier formats with the registrar/data owners.
- **How to implement if missing:** Build the SIT inventory (this solution's Discovery script assesses
  built-in SIT coverage); plan a **`Student ID – Custom SIT – FERPA`** and, where near-zero false positives
  are required, a **`Student Records – EDM – FERPA`** schema.

## 2.5 Source data for Exact Data Match (only if EDM is used)
- **Description:** For **EDM** SITs, a **sensitive data table** (e.g. an export of the Student Information
  System / records) and a workstation with the **EDM Upload Agent** to hash and upload it — the raw data
  never leaves your control; only salted hashes are uploaded.
- **Why required:** EDM matches against *your actual student records*, which is what drives false positives
  to near zero — but it requires the schema, the hashed upload, and a **refresh cadence** as enrollment
  changes.
- **How to verify:** Confirm the source table, the EDM schema, the upload agent host, and a scheduled
  refresh. **Purview portal → Data classification → Exact data matches** shows configured EDM schemas.
- **How to implement if missing:** Define the EDM schema and refresh process (*which* fields are in scope is
  deferred to the registrar/data owner); if EDM is not in your plan or not needed, use a custom SIT with
  confidence/keyword tuning instead.

## 2.6 A pilot ring, simulation dwell time, and change control (DLP-specific)
- **Description:** A named **pilot user/device ring** (`FERPA DLP Pilot Ring – Stage1`), an agreed
  **simulation dwell time** (how long each policy runs in simulation before enforcement — long enough to
  capture representative traffic, ideally spanning a grading or enrollment cycle), and the **change-control
  window** for moving simulation → enforce. Extends GR-#6.
- **Why required:** DLP is high-impact in an academic setting where records move constantly during grading
  and admissions; enforcing without a simulation baseline and a limited ring is how DLP breaks the business.
  The house model mandates **simulation first**, then a ring, then expand.
- **How to verify:** Confirm the pilot ring membership, that **simulation mode** is selected on each new
  policy, and the approval path to enforce.
- **How to implement if missing:** Define the ring and dwell time and agree change control before enabling
  any enforcement action.

## 2.7 An incident/alert triage owner and destination
- **Description:** A named owner (or queue) for **DLP alerts** raised in **Purview portal → Data loss
  prevention → Alerts** (`FERPA DLP Alerts – Triage – Operations`), plus where DLP events are reviewed
  (**Activity Explorer**) and, optionally, where they are forwarded (SIEM/Microsoft Sentinel via the Office
  365 Management Activity API / Defender connectors). Severity and response actions defined. Because alert
  evidence can contain student PII, the triage owner must hold the appropriate least-privilege role.
- **Why required:** A DLP match with no one to triage it is not a control. Alerts and Activity Explorer are
  where matches surface; someone must own triage, severity, and response.
- **How to verify:** Confirm the triage owner/queue, the alert-severity scheme, and any SIEM forwarding is
  configured.
- **How to implement if missing:** Assign the owner, define severity/response, and (optionally) wire SIEM
  forwarding before enforcement generates real alerts.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | DLP/Endpoint licensing (E5 / E5 Compliance / A5; verify) | Endpoint & advanced classifiers available |
| 2.2 | DLP least-privilege roles | Author + triage roles assigned |
| 2.3 | Devices onboarded to Purview | Endpoint location functional |
| 2.4 | Education-record classification intent + student-ID SIT inventory | Policies key off correct SITs |
| 2.5 | EDM source data + agent (if used) | Near-zero-FP matching for real records |
| 2.6 | Pilot ring + simulation dwell + change control | Simulate-first enforced |
| 2.7 | Alert/incident triage owner + destination | Matches are acted on |

> **Deferred to FERPA compliance / registrar / privacy / legal:** which records are FERPA-protected,
> directory vs non-directory treatment, permitted disclosures, the enforced action per category, and
> regulatory applicability. This solution provides the technical configuration and evidence, not the
> determination.
