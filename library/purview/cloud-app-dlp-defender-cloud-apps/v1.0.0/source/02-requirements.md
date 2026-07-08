# 2. Requirements — Cloud-App DLP (Defender for Cloud Apps)

These are the **solution-specific** prerequisites for extending DLP to third-party cloud apps with Microsoft
Defender for Cloud Apps (MDCA) — **file policies** (data at rest via API connectors) and **session/access
policies** (real-time via Conditional Access App Control). They build on — and do not repeat — the six
shared prerequisites in **`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege
Purview/compliance roles, S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/
privacy/legal stakeholders, and a pilot scope + change control). Verify each item below before starting the
Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to
implement if missing**.

---

## 2.1 Defender for Cloud Apps licensing and portal access
- **Description:** Microsoft **Defender for Cloud Apps** must be licensed and provisioned for the tenant.
  MDCA is available with **Microsoft 365 E5 / E5 Security / E5 Compliance** or as a standalone plan; content
  inspection using Purview **SITs/sensitivity labels** and **Conditional Access App Control** likewise depend
  on the plan. This extends GR-#1 with the MDCA-specific plan detail.
- **Why required:** No file policy, session policy, or content inspection exists without MDCA licensed and
  turned on. Session control additionally depends on Microsoft Entra Conditional Access (see 2.4).
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Microsoft Defender portal** (security.microsoft.com) confirm the **Cloud apps** node is present and you
  can open **Cloud apps → Policies**. **Flag "verify your licensing/tenant"** — availability evolves.
- **How to implement if missing:** Acquire/assign the required licensing before building policies; MDCA is
  provisioned automatically once licensed — confirm the Cloud apps node appears in the Defender portal.

## 2.2 MDCA least-privilege roles
- **Description:** Access with the least-privilege MDCA/Defender role the task needs — e.g. **Global Reader**
  or a Defender **Security Reader** for read-only discovery, a Cloud App Security **App/Instance admin** or
  **Security Administrator** to create/manage policies and connectors, and separate **alert/incident**
  triage where possible. Global Administrator only where genuinely required. Extends GR-#2.
- **Why required:** MDCA and the Defender portal enforce role-based access; connecting apps, creating
  policies, and taking governance actions require the matching role, and least privilege limits blast radius.
- **How to verify:** **Microsoft Defender portal → Settings → Cloud apps → (role/permissions)** and the
  Entra role assignments — confirm your account holds the role for the action (read vs configure vs triage).
- **How to implement if missing:** Assign the least-privilege role under change control; separate policy
  authors from connector admins and from alert triagers where the org allows.

## 2.3 App connectors (API) for the SaaS apps you will govern at rest
- **Description:** For **file policies**, each target SaaS app must be connected via its **API connector** in
  **Cloud apps → App connectors** (OAuth, using an admin of that app). The connector lets MDCA enumerate
  files, read sharing state, and apply governance actions. Microsoft supports connectors for a defined set
  of apps (e.g. Box, Dropbox, Google Workspace, Salesforce, ServiceNow, and others) — **verify the target
  app has a connector.**
- **Why required:** A **file policy is inert until the app is connected** — MDCA cannot see or act on files
  in an app it has no API connector for.
- **How to verify:** **Cloud apps → App connectors** lists connected apps and their **status** (connected /
  error); confirm the target app is connected and its initial scan has run.
- **How to implement if missing:** Connect each in-scope app via its API connector using an app admin
  account; wait for the initial scan to complete before scoping file policies to it. If an app has no
  connector, session/access controls (2.4) may still apply, but at-rest file governance will not.

## 2.4 Conditional Access App Control routing (for session & access policies)
- **Description:** For **session** and **access** policies, target users and apps must be routed through the
  MDCA reverse proxy by a **Microsoft Entra Conditional Access** policy with **Session → Use Conditional
  Access App Control**. Onboarded apps then appear under **Cloud apps → Conditional Access App Control apps**.
  Some apps auto-onboard (featured apps); others require a one-time onboarding/deployment step per Microsoft
  docs.
- **Why required:** Session/access policies operate **only** on sessions that Entra routes to the proxy — no
  CA App Control policy means no real-time control.
- **How to verify:** **Microsoft Entra → Protection → Conditional Access** shows a policy with the session
  control **Use Conditional Access App Control**; **Cloud apps → Conditional Access App Control apps** lists
  the onboarded app(s). The delivered readiness script reports the CA policy via Microsoft Graph.
- **How to implement if missing:** Create the Entra CA policy (start in **report-only**), scope it to the
  pilot ring and target app(s), and confirm the app onboards. Verify the target app is supported for session
  control before relying on it.

## 2.5 Classification layer — SITs and sensitivity labels for content inspection
- **Description:** MDCA file/session content inspection uses Purview **sensitive information types**
  (built-in / custom / EDM) via the Data Classification Service, and can match on **sensitivity labels**. A
  documented view of *what* sensitive data you are protecting mapped to the SIT/label that detects it is
  required. Extends GR-#4.
- **Why required:** Policies key off SITs/labels; without knowing which data matters and which detector
  finds it, policies are guesswork and generate false positives.
- **How to verify:** **Purview portal → Data classification → Classifiers → Sensitive info types** lists the
  SITs; **Information protection → Labels** lists sensitivity labels. The delivered discovery script reports
  the labels and SITs available for MDCA to use (via S&C PowerShell / Graph). Confirm the data categories
  with the data owners.
- **How to implement if missing:** Build/confirm the SIT and label inventory before authoring policies; plan
  custom SITs / EDM for categories the built-in SITs don't cover (that is a separate Purview task).

## 2.6 A pilot ring, test-mode dwell, and change control (MDCA-specific)
- **Description:** A named **pilot user/group ring** (e.g. `MDCA Pilot Ring – Stage1`), an agreed **dwell
  time** in test mode, and the **change-control window** to move from test to enforce. In MDCA the test-mode
  equivalents are: the **Entra CA policy in report-only**, **session policies set to Monitor only**, and
  **file policies set to alert-only** (no quarantine/label/sharing change). Extends GR-#6.
- **Why required:** Cloud-app DLP is high-impact — a *block download* session policy or a *quarantine* file
  policy enforced with no baseline stops legitimate work. The house model mandates **test/monitor first**,
  then a ring, then expand.
- **How to verify:** Confirm the pilot ring membership, that the CA policy is **report-only**, that session
  policies are **Monitor only** and file policies **alert-only**, and the approval path to enforce.
- **How to implement if missing:** Define the ring and dwell time and agree change control before enabling
  any enforcing action (block / protect / quarantine / remove-sharing).

## 2.7 An alert/incident triage owner and destination
- **Description:** A named owner (or queue) for **MDCA alerts** — surfaced in **Cloud apps → Alerts** and, as
  incidents, in the **Microsoft Defender portal** (and via the Graph security alerts API) — plus where
  matches are reviewed and, optionally, forwarded (SIEM / Microsoft Sentinel). Severity and response actions
  defined.
- **Why required:** A file/session match with no one to triage it is not a control. Alerts and incidents are
  where matches surface; someone must own triage, severity, and response.
- **How to verify:** Confirm the triage owner/queue (`MDCA Alerts – Triage – Operations`), the alert-severity
  scheme, and any SIEM forwarding. The delivered report script reads Cloud-Apps alerts via Graph.
- **How to implement if missing:** Assign the owner, define severity/response, and (optionally) wire SIEM
  forwarding before enforcement generates real alerts.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | MDCA licensing + portal access (verify) | Cloud apps node & policies available |
| 2.2 | MDCA least-privilege roles | Configure vs read vs triage roles assigned |
| 2.3 | App connectors (API) for target apps | File policies functional (at rest) |
| 2.4 | Conditional Access App Control routing | Session/access policies functional (real time) |
| 2.5 | SITs + sensitivity labels | Content inspection keys off correct detectors |
| 2.6 | Pilot ring + test-mode dwell + change control | Report-only/Monitor/alert-first enforced |
| 2.7 | Alert/incident triage owner + destination | Matches are acted on |

> **Deferred to compliance/privacy/legal:** which SaaS apps and data categories are in scope, which
> classifiers legally apply, the governance/session action per category, and any regulatory applicability.
> This solution provides the technical configuration and evidence, not the determination.
