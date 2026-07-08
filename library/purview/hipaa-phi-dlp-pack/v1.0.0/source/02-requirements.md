# 2. Requirements — HIPAA / PHI DLP Pack (Microsoft Purview)

These are the **solution-specific** prerequisites for implementing PHI-focused Purview DLP across
endpoint, cloud, and email. They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles,
S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders,
and a pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to
implement if missing**.

---

## 2.1 Licensing sufficient for the DLP features you will use — especially Endpoint DLP
- **Description:** DLP for **Exchange/SharePoint/OneDrive/Teams** and **built-in SITs** (including the
  HIPAA-relevant SITs — SSN, ICD-9-CM, ICD-10-CM, DEA Number) is broadly available, but **Endpoint
  DLP**, **advanced/custom classifiers**, **Exact Data Match**, and **trainable classifiers** are
  **plan-gated** — typically **Microsoft 365 E5** or the **E5 Compliance** add-on (some capabilities are
  in **preview**). This extends GR-#1 with the DLP-specific plan detail.
- **Why required:** A DLP policy scoped to a location or using a classifier your plan doesn't include
  will not function. Endpoint DLP (a common PHI walk-out path via USB/print) in particular is an
  E5/E5-Compliance capability.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Purview portal → Data Loss Prevention** confirm the **Endpoint DLP** and **Devices** location and
  the classifier types you intend to use are visible. **Flag "verify your licensing/tenant"** —
  availability evolves.
- **How to implement if missing:** Acquire/assign the required licensing (E5 or E5 Compliance) before
  building endpoint or advanced-classifier policies; scope the initial rollout to features your plan
  covers (email + cloud built-in HIPAA SITs work broadly).

## 2.2 DLP-specific least-privilege roles
- **Description:** The **DLP role groups** in the Purview portal — **Compliance Administrator** or
  **Compliance Data Administrator** to create/manage DLP policies, **DLP Compliance Management** for
  policy management, **View-Only DLP Compliance Management** for read-only review, and the **Data Loss
  Prevention** role for alert/incident handling. Global Administrator only where genuinely required.
  Extends GR-#2. For PHI, separate policy authors from alert triagers so PHI evidence access is
  least-privilege.
- **Why required:** Purview enforces fine-grained role groups; DLP configuration and PHI-alert triage
  require the matching role, and least privilege keeps who-can-see-PHI-evidence small.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** (or Microsoft Purview
  roles) — confirm your account's role-group membership includes the DLP roles you need.
- **How to implement if missing:** Assign the least-privilege DLP role group under change control;
  separate policy authors from alert triagers where possible.

## 2.3 Devices onboarded to Purview for Endpoint DLP
- **Description:** Endpoint DLP monitors activities on **onboarded Windows 10/11 and macOS devices**.
  Onboarding is done in **Purview portal → Settings → Device onboarding** (or via Intune / a script /
  Group Policy), and is **shared with Microsoft Defender for Endpoint onboarding** — devices already
  onboarded to Defender for Endpoint are onboarded for Endpoint DLP. Clinician laptops/workstations that
  handle PHI are the priority scope.
- **Why required:** A DLP policy scoped to the **Devices** location does nothing on a device that is not
  onboarded and reporting. Onboarding is the hard prerequisite for any endpoint PHI control (USB/print).
- **How to verify:** **Purview portal → Settings → Device onboarding → Devices** shows onboarded
  devices; confirm target devices appear and are reporting. On a device, confirm the onboarding state
  per Microsoft's documented method.
- **How to implement if missing:** Onboard devices via the Purview device-onboarding package, Intune, or
  Group Policy; confirm the minimum OS build and any required Antimalware/AV state per Microsoft docs
  before scoping endpoint policies.

## 2.4 A PHI classification intent and a HIPAA sensitive-information-type map
- **Description:** A documented view of **what PHI you are protecting** (member/patient identifiers +
  clinical/billing data — e.g. MRN, SSN, diagnosis/ICD codes, insurance/member IDs, DEA numbers) mapped
  to the **SITs/classifiers** that detect it — the built-in **HIPAA template SITs** where they fit, and
  **custom SITs / EDM / trainable classifiers** where they don't (e.g. your MRN format). Extends GR-#4.
- **Why required:** PHI DLP policies key off SITs; without knowing which identifiers matter and which
  SIT detects each (at what confidence and instance count), policies are guesswork and generate false
  positives that kill adoption.
- **How to verify:** **Purview portal → Data classification → Classifiers → Sensitive info types** lists
  built-in and custom SITs; confirm the HIPAA-relevant ones (SSN, ICD-9-CM, ICD-10-CM, DEA Number)
  exist and any custom ones you need are planned. Confirm the PHI categories with the data owners and
  Privacy Officer.
- **How to implement if missing:** Build the SIT map (this solution's Discovery script assesses HIPAA-
  relevant built-in SIT coverage); plan custom SITs / EDM / trainable classifiers for identifiers not
  covered. **Which identifiers legally constitute PHI is a Privacy/compliance determination — deferred.**

## 2.5 Source data for Exact Data Match (only if EDM is used)
- **Description:** For **EDM** SITs, a **sensitive data table** (e.g. a patient/member roster export)
  and a workstation with the **EDM Upload Agent** to hash and upload it — the raw data never leaves your
  control; only salted hashes are uploaded. Ideal for near-zero-FP matching of *your* patient
  identifiers.
- **Why required:** EDM matches against *your actual roster*, which is what drives PHI false positives
  to near zero — but it requires the schema, the hashed upload, and a **refresh cadence** as the roster
  changes.
- **How to verify:** Confirm the source table, the EDM schema, the upload agent host, and a scheduled
  refresh. **Purview portal → Data classification → Exact data matches** shows configured EDM schemas.
- **How to implement if missing:** Define the EDM schema and refresh process (deferred to the data owner
  for *which* fields are in scope); if EDM is not in your plan or not needed, use custom SITs with
  confidence/keyword tuning instead. **Handle the roster export itself as PHI under your own controls.**

## 2.6 A pilot ring, simulation dwell time, and change control (DLP-specific)
- **Description:** A named **pilot user/device ring** (e.g. one clinical or billing department), an
  agreed **simulation dwell time** (how long each policy runs in simulation before enforcement — long
  enough to capture representative clinical/billing traffic), and the **change-control window** for
  moving simulation → enforce. Extends GR-#6.
- **Why required:** PHI DLP is high-impact; enforcing without a simulation baseline and a limited ring
  is how DLP breaks clinical/billing workflows. The house model mandates **simulation first**, then a
  ring, then expand.
- **How to verify:** Confirm the pilot ring membership, that **simulation mode** is selected on each new
  policy, and the approval path to enforce.
- **How to implement if missing:** Define the ring and dwell time and agree change control before
  enabling any enforcement action.

## 2.7 A PHI incident/alert triage owner, destination, and escalation to the Privacy/Security Officer
- **Description:** A named owner (or queue) for **DLP alerts** raised in **Purview portal → Data loss
  prevention → Alerts**, plus where DLP events are reviewed (**Activity Explorer**) and, optionally,
  where they are forwarded (SIEM/Microsoft Sentinel via the Office 365 Management Activity API /
  Defender connectors). Crucially, an **escalation path to the HIPAA Privacy/Security Officer** for any
  match that may be a reportable disclosure. Severity and response actions defined.
- **Why required:** A PHI DLP match with no one to triage it is not a control — and the **breach
  determination is not a technical decision**. Alerts and Activity Explorer are where potential PHI
  disclosures surface; someone must own triage and escalate the *breach* question to Privacy/Security.
- **How to verify:** Confirm the triage owner/queue, the alert-severity scheme, the Privacy/Security
  escalation path, and any SIEM forwarding is configured.
- **How to implement if missing:** Assign the owner, define severity/response and the escalation to the
  Privacy/Security Officer, and (optionally) wire SIEM forwarding before enforcement generates real
  PHI alerts.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | DLP/Endpoint licensing (E5 / E5 Compliance; verify) | Endpoint & advanced classifiers available |
| 2.2 | DLP least-privilege roles | Author + triage roles assigned (authors ≠ triagers) |
| 2.3 | Devices onboarded to Purview | Endpoint PHI location functional |
| 2.4 | PHI classification intent + HIPAA SIT map | Policies key off correct PHI SITs |
| 2.5 | EDM source data + agent (if used) | Near-zero-FP matching on your roster |
| 2.6 | Pilot ring + simulation dwell + change control | Simulate-first enforced |
| 2.7 | PHI alert triage owner + Privacy/Security escalation | Matches acted on; breach question escalated |

> **Deferred to compliance/privacy/legal:** which data is PHI, which identifiers/classifiers legally
> apply, the enforced action per category, the acceptable false-positive threshold, DLP-evidence
> retention, and — decisively — **whether any event is a reportable HIPAA breach**. This solution
> provides the technical configuration and evidence, not the determination.
