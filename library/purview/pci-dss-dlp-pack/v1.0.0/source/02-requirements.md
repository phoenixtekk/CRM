# 2. Requirements — PCI-DSS DLP Pack (Microsoft Purview)

These are the **solution-specific** prerequisites for implementing cardholder-data DLP across endpoint,
cloud, and email. They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles,
S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders,
and a pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to
implement if missing**.

---

## 2.1 Licensing sufficient for the DLP features you will use — especially Endpoint DLP and EDM
- **Description:** DLP for **Exchange/SharePoint/OneDrive/Teams** using the **built-in Credit Card Number
  SIT** is broadly available, but **Endpoint DLP**, **Exact Data Match (EDM)**, and **trainable
  classifiers** are **plan-gated** — typically **Microsoft 365 E5** or the **E5 Compliance** add-on (some
  capabilities are in **preview**). This extends GR-#1 with the DLP-specific plan detail.
- **Why required:** A DLP policy scoped to a location or using a classifier your plan doesn't include will
  not function. Endpoint DLP and EDM in particular are E5/E5-Compliance capabilities — and EDM is the tool
  that drives PAN false positives toward zero.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Purview portal → Data Loss Prevention** confirm the **Endpoint DLP** / **Devices** location and, under
  **Data classification → Exact data matches**, that EDM is available. **Flag "verify your
  licensing/tenant"** — availability evolves.
- **How to implement if missing:** Acquire/assign the required licensing (E5 or E5 Compliance) before
  building endpoint or EDM policies; scope the initial rollout to features your plan covers (the built-in
  Credit Card SIT across email/cloud works on broadly-available plans).

## 2.2 DLP-specific least-privilege roles
- **Description:** The **DLP role groups** in the Purview portal — **Compliance Administrator** or
  **Compliance Data Administrator** to create/manage DLP policies, **DLP Compliance Management** for policy
  management, **View-Only DLP Compliance Management** for read-only review, and the **Data Loss
  Prevention** role for alert/incident handling. Global Administrator only where genuinely required.
  Extends GR-#2.
- **Why required:** Purview enforces fine-grained role groups; DLP configuration and alert triage require
  the matching role, and least privilege keeps the blast radius small. PCI environments in particular
  expect documented role separation.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** (or Microsoft Purview
  roles) — confirm your account's role-group membership includes the DLP roles you need.
- **How to implement if missing:** Assign the least-privilege DLP role group under change control; separate
  policy authors from alert triagers where possible.

## 2.3 Devices onboarded to Purview for Endpoint DLP
- **Description:** Endpoint DLP monitors PAN-related activities on **onboarded Windows 10/11 and macOS
  devices** — copy to USB, print, upload to unallowed cloud apps, clipboard/paste. Onboarding is done in
  **Purview portal → Settings → Device onboarding** (or via Intune / a script / Group Policy), and is
  **shared with Microsoft Defender for Endpoint onboarding**.
- **Why required:** A DLP policy scoped to the **Devices** location does nothing on a device that is not
  onboarded and reporting — and endpoints are a primary path for card-data exfiltration (a spreadsheet of
  PANs to a USB stick).
- **How to verify:** **Purview portal → Settings → Device onboarding → Devices** shows onboarded devices;
  confirm target devices appear and are reporting. Script #3 provides a licensing/onboarding signal.
- **How to implement if missing:** Onboard devices via the Purview device-onboarding package, Intune, or
  Group Policy; confirm the minimum OS build and required AV/agent state per Microsoft docs before scoping
  endpoint policies.

## 2.4 A card-data classification intent and the PAN detector inventory
- **Description:** A documented view of **what cardholder data you are protecting** (full PAN as the
  primary target; cardholder name / expiry / service code as cardholder data; CVV/track/PIN as Sensitive
  Authentication Data that must not be stored) mapped to the **SITs/classifiers** that detect it — the
  built-in **Credit Card Number** SIT for PAN, plus **EDM** for your real PANs where near-zero false
  positives are required. Extends GR-#4.
- **Why required:** DLP policies key off SITs; card-data DLP anchors on the PAN detector. Without knowing
  which card brands and instance counts matter, policies are guesswork and generate false positives.
- **How to verify:** **Purview portal → Data classification → Classifiers → Sensitive info types** —
  confirm the built-in **Credit Card Number** SIT exists and review its confidence levels and default
  instance count (Discovery script #1 reports coverage).
- **How to implement if missing:** Confirm the built-in PAN SIT; plan an EDM schema for your real card
  numbers if pattern matching over-fires; document which card brands and thresholds are in scope with the
  data owners. *Which flows are in PCI scope is the compliance/QSA determination.*

## 2.5 Source data for Exact Data Match (only if EDM is used for PAN)
- **Description:** For an **EDM** PAN SIT, a **sensitive data table** (an export of your real PANs — handled
  under strict access control) and a workstation with the **EDM Upload Agent** to hash and upload it — the
  raw PANs never leave your control; only salted hashes are uploaded.
- **Why required:** EDM matches against *your actual PANs*, which drives false positives toward zero — but
  it requires the schema, the hashed upload, and a **refresh cadence** as the card data changes. Handling
  the source table is itself a card-data-security activity.
- **How to verify:** Confirm the source table, the EDM schema (`Cardholder PAN – EDM – PCI`), the upload
  agent host, and a scheduled refresh. **Purview portal → Data classification → Exact data matches** shows
  configured EDM schemas.
- **How to implement if missing:** Define the EDM schema and refresh process under card-data handling
  controls (deferred to the data owner for *which* fields are in scope); if EDM is not in your plan or not
  needed, use the built-in Credit Card SIT with confidence/instance/keyword tuning instead.

## 2.6 A pilot ring, simulation dwell time, and change control (DLP-specific)
- **Description:** A named **pilot user/device ring** (`PCI DLP Pilot Ring – Stage1`), an agreed
  **simulation dwell time** (how long each policy runs in simulation before enforcement — long enough to
  capture representative card-data traffic), and the **change-control window** for moving simulation →
  enforce. Extends GR-#6.
- **Why required:** Card-data DLP is high-impact; enforcing without a simulation baseline and a limited ring
  is how DLP breaks legitimate payment/finance workflows. The house model mandates **simulation first**,
  then a ring, then expand.
- **How to verify:** Confirm the pilot ring membership, that **simulation mode** is selected on each new
  policy, and the approval path to enforce.
- **How to implement if missing:** Define the ring and dwell time and agree change control before enabling
  any enforcement action.

## 2.7 A PAN-incident/alert triage owner and destination
- **Description:** A named owner (or queue) for **DLP alerts** raised in **Purview portal → Data loss
  prevention → Alerts** (`PCI DLP Alerts – Triage – Operations`), plus where DLP events are reviewed
  (**Activity Explorer**) and, optionally, forwarded (SIEM/Microsoft Sentinel via the Office 365
  Management Activity API / Defender connectors). Severity and response actions defined — a PAN match is a
  cardholder-data exposure that may require its own handling per your incident-response plan.
- **Why required:** A PAN match with no one to triage it is not a control. Alerts and Activity Explorer are
  where matches surface; someone must own triage, severity, and response — and PCI expects a defined
  incident-response process for cardholder-data events.
- **How to verify:** Confirm the triage owner/queue, the alert-severity scheme, and any SIEM forwarding is
  configured.
- **How to implement if missing:** Assign the owner, define severity/response (aligned to your
  incident-response plan), and (optionally) wire SIEM forwarding before enforcement generates real alerts.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | DLP/Endpoint/EDM licensing (E5 / E5 Compliance; verify) | Endpoint, EDM & advanced classifiers available |
| 2.2 | DLP least-privilege roles | Author + triage roles assigned |
| 2.3 | Devices onboarded to Purview | Endpoint location functional |
| 2.4 | Card-data classification intent + PAN detector inventory | Policies key off the Credit Card SIT (+EDM) |
| 2.5 | EDM source PAN table + agent (if used) | Near-zero-FP PAN matching where needed |
| 2.6 | Pilot ring + simulation dwell + change control | Simulate-first enforced |
| 2.7 | PAN alert/incident triage owner + destination | Card-data matches are acted on |

> **Deferred to compliance/PCI/QSA:** the CDE boundary and PCI scope, which flows are in scope, the
> enforced action per flow, and compliance sign-off/attestation. This solution provides the technical
> configuration and evidence, not the determination or attestation.
