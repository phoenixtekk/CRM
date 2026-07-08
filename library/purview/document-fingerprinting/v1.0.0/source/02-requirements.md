# 2. Requirements — Document Fingerprinting (Microsoft Purview)

These are the **solution-specific** prerequisites for fingerprinting standard forms and wiring them to
DLP. They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles,
S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders,
and a pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to
implement if missing**.

---

## 2.1 Licensing sufficient for DLP and document fingerprinting
- **Description:** Document fingerprinting produces a **sensitive information type** consumed by
  **Purview DLP**. Fingerprinting has long been available as part of Exchange/DLP, but the DLP
  **locations** and **actions** you enforce (e.g. endpoint DLP, advanced conditions) are
  **plan-dependent** — several are **Microsoft 365 E5 / E5 Compliance**, and some capabilities are in
  **preview**. This extends GR-#1 with the fingerprint/DLP-specific plan detail.
- **Why required:** A fingerprint SIT is only useful once a DLP policy in a licensed location references
  it. A location or action your plan doesn't include will not function.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Purview portal → Data loss prevention** and **Data classification → Classifiers → Sensitive info
  types** confirm you can create a **Document fingerprint** SIT and target the locations you intend to
  use. **Flag "verify your licensing/tenant"** — availability evolves.
- **How to implement if missing:** Acquire/assign the required licensing before building policies in
  gated locations; scope the initial rollout to features your plan covers (email/SharePoint/OneDrive/
  Teams DLP with a fingerprint SIT is the baseline).

## 2.2 Fingerprint/DLP-specific least-privilege roles
- **Description:** Creating fingerprint SITs and DLP policies requires the **Purview DLP role groups** —
  **Compliance Administrator** or **Compliance Data Administrator** to create/manage SITs and DLP
  policies, **DLP Compliance Management** for policy management, **View-Only DLP Compliance Management**
  for read-only review, and the **Data Loss Prevention** role for alert/incident handling. The
  fingerprint cmdlets (`New-DlpFingerprint`, `New-DlpSensitiveInformationType`) run in **Security &
  Compliance PowerShell** and require the matching role. Global Administrator only where genuinely
  required. Extends GR-#2.
- **Why required:** Purview enforces fine-grained role groups; SIT/DLP configuration and alert triage
  require the matching role, and least privilege keeps the blast radius small.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** — confirm the account's
  role-group membership; confirm `New-DlpSensitiveInformationType` is available in your S&C PowerShell
  session.
- **How to implement if missing:** Assign the least-privilege DLP role group under change control;
  separate SIT/policy authors from alert triagers where possible.

## 2.3 The source form templates to fingerprint (blank/representative, text-based)
- **Description:** For each form you will protect, a **blank or representative copy** of the template in
  a **supported, text-based format** (`.docx`, `.dotx`, `.pdf`, `.txt` and similar) whose **boilerplate
  text is intact** — the fingerprint is built from that text. Scanned/image-only forms have no
  extractable text and cannot be fingerprinted.
- **Why required:** The fingerprint *is* the template's word pattern. A poor source (image-only,
  password-protected, or an already-filled copy with little boilerplate) yields a weak or unusable
  fingerprint.
- **How to verify:** Confirm you hold the current version of each form as a text-based file; open it and
  confirm the boilerplate text is selectable (not a flattened image). Confirm the file is within
  Microsoft's supported **type and size** limits (**verify current limits for your tenant**).
- **How to implement if missing:** Obtain the authoritative blank template from the form owner; if only
  a scan exists, source or recreate a text-based version, or OCR it to extractable text before
  fingerprinting.

## 2.4 A form inventory and classification intent
- **Description:** A documented list of the **standard forms in scope** (name, owner, version,
  sensitivity, the workloads they travel through) mapped to the **fingerprint SIT** that will detect
  each — grouped where several related forms belong in one SIT. Extends GR-#4.
- **Why required:** Fingerprinting is per-form; without knowing *which* forms matter, who owns them, and
  how they move, policy scoping and SIT grouping are guesswork.
- **How to verify:** Confirm the form list, owners, and versions with the business/compliance
  stakeholders; the Discovery script (#1) reports existing fingerprint SITs and DLP coverage as a
  starting baseline.
- **How to implement if missing:** Build the form inventory with the form owners before authoring
  fingerprints; agree which forms group into which SIT.

## 2.5 A form-version refresh process
- **Description:** A named owner and cadence for **re-fingerprinting when a form's template changes** —
  a fingerprint reflects the template *as fingerprinted*; a materially revised form drifts from its
  fingerprint and detection degrades.
- **Why required:** Standard forms are revised. Without a refresh process, detection silently decays as
  the live forms diverge from the fingerprinted template — a false sense of coverage.
- **How to verify:** Confirm the form owner will notify on template changes and that a refresh step
  (add the new template's fingerprint to the SIT, retire the old) is agreed.
- **How to implement if missing:** Define the refresh trigger and owner; a fingerprint SIT can hold
  **multiple fingerprints**, so a revised form is added rather than replaced wholesale.

## 2.6 A pilot ring, simulation dwell time, and change control (DLP-specific)
- **Description:** A named **pilot user ring**, an agreed **simulation dwell time** (how long the policy
  runs in simulation before enforcement — long enough to capture representative form traffic), and the
  **change-control window** for moving simulation → enforce. Extends GR-#6.
- **Why required:** DLP is high-impact; enforcing a form-detection policy without a simulation baseline
  and a limited ring risks blocking legitimate business. The house model mandates **simulation first**,
  then a ring, then expand.
- **How to verify:** Confirm the pilot ring membership, that **simulation mode** is selected on the new
  policy, and the approval path to enforce.
- **How to implement if missing:** Define the ring and dwell time and agree change control before
  enabling any enforcement action.

## 2.7 An incident/alert triage owner and destination
- **Description:** A named owner (or queue) for **DLP alerts** raised on fingerprint matches
  (**Purview → Data loss prevention → Alerts**), plus where matches are reviewed (**Activity Explorer**)
  and, optionally, forwarded (SIEM/Microsoft Sentinel). Severity and response actions defined.
- **Why required:** A form match with no one to triage it is not a control. Someone must own triage,
  severity, and response.
- **How to verify:** Confirm the triage owner/queue, the alert-severity scheme, and any SIEM forwarding.
- **How to implement if missing:** Assign the owner, define severity/response, and (optionally) wire
  SIEM forwarding before enforcement generates real alerts.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | DLP + fingerprint licensing (verify tenant) | SIT creation + target locations available |
| 2.2 | DLP/fingerprint least-privilege roles | SIT/policy authoring + triage roles assigned |
| 2.3 | Source form templates (text-based, blank) | Fingerprintable input in hand |
| 2.4 | Form inventory + classification intent | Policies key off the right forms/SITs |
| 2.5 | Form-version refresh process | Detection stays current as forms change |
| 2.6 | Pilot ring + simulation dwell + change control | Simulate-first enforced |
| 2.7 | Alert/incident triage owner + destination | Matches are acted on |

> **Deferred to compliance/records/privacy/legal:** which forms are in scope, which legal/regulatory
> obligation applies to each, and the enforced action per form. This solution provides the technical
> configuration and evidence, not the determination.
