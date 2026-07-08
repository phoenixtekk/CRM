# 2. Requirements — OneDrive for Business DLP (Microsoft Purview)

These are the **solution-specific** prerequisites for implementing Purview DLP for OneDrive for Business.
They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles,
S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders,
and a pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to
implement if missing**.

---

## 2.1 Licensing sufficient for the DLP features you will use
- **Description:** DLP for **OneDrive** and **built-in SITs** is broadly available across Microsoft 365
  compliance plans, but **custom classifiers**, **Exact Data Match (EDM)**, and **trainable
  classifiers** are **plan-gated** — typically **Microsoft 365 E5** or the **E5 Compliance** add-on
  (some capabilities are in **preview**). This extends GR-#1 with the DLP-specific plan detail.
- **Why required:** A policy that relies on a classifier your plan doesn't include will not function.
  Basing detection on built-in SITs keeps the initial rollout inside broadly-available capability.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Purview portal → Data Loss Prevention → Policies → Create policy** confirm the **OneDrive accounts**
  location and the classifier types you intend to use are visible. **Flag "verify your licensing/
  tenant"** — availability evolves.
- **How to implement if missing:** Acquire/assign the required licensing (E5 or E5 Compliance) before
  building custom-classifier/EDM policies; scope the initial rollout to built-in SITs your plan covers.

## 2.2 DLP-specific least-privilege roles
- **Description:** The **DLP role groups** in the Purview portal — **Compliance Administrator** or
  **Compliance Data Administrator** to create/manage DLP policies, **DLP Compliance Management** for
  policy management, **View-Only DLP Compliance Management** for read-only review, and the **Data Loss
  Prevention** role for alert/incident handling. Global Administrator only where genuinely required.
  Extends GR-#2.
- **Why required:** Purview enforces fine-grained role groups; DLP configuration and alert triage require
  the matching role, and least privilege keeps the blast radius small.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** (Microsoft Purview
  roles) — confirm your account's role-group membership includes the DLP roles you need.
- **How to implement if missing:** Assign the least-privilege DLP role group under change control;
  separate policy authors from alert triagers where possible.

## 2.3 OneDrive provisioned and the sharing posture understood
- **Description:** OneDrive for Business must be **provisioned** for the in-scope users, and you should
  know the tenant's current **external-sharing posture** for OneDrive (SharePoint admin / OneDrive
  sharing settings: Anyone / New and existing guests / Existing guests / Only people in your org). DLP
  acts on *sensitive* sharing; the tenant setting governs sharing broadly and is a complementary control.
- **Why required:** A OneDrive DLP policy only sees content and shares that actually exist. Knowing the
  sharing posture tells you how much external-share risk DLP will surface and whether tenant settings
  should be tightened alongside DLP.
- **How to verify:** Confirm OneDrive is provisioned for in-scope users; review the OneDrive/SharePoint
  external-sharing setting (SharePoint admin center → Policies → Sharing, or via SharePoint Online
  PowerShell / Graph SharePoint settings). The delivered scope/health script reports the DLP-side scope
  and, where readable, the tenant sharing signal.
- **How to implement if missing:** Provision OneDrive for the target users; agree the intended
  external-sharing posture with stakeholders (tenant-setting change is a separate, change-controlled
  action from the DLP policy).

## 2.4 A classification intent and a sensitive-information-type inventory
- **Description:** A documented view of **what sensitive data you are protecting** in OneDrive (e.g.
  payment card data, national IDs, health identifiers, customer PII) mapped to the **SITs/classifiers**
  that detect it — built-in SITs where they fit, **custom SITs / EDM / trainable classifiers** where
  they don't. Extends GR-#4.
- **Why required:** DLP policies key off SITs; without knowing which data matters and which SIT detects
  it (at what confidence and instance count), policies are guesswork and generate false positives.
- **How to verify:** **Purview portal → Data classification → Classifiers → Sensitive info types** lists
  built-in and custom SITs; confirm the ones you need exist (or are planned). Confirm the data
  categories with the data owners.
- **How to implement if missing:** Build the SIT inventory (this solution's Discovery script assesses
  built-in vs. custom SIT coverage); plan custom SITs / EDM / trainable classifiers for categories not
  covered.

## 2.5 Source data for Exact Data Match (only if EDM is used)
- **Description:** For **EDM** SITs, a **sensitive data table** (e.g. an export of customer records) and
  a workstation with the **EDM Upload Agent** to hash and upload it — the raw data never leaves your
  control; only salted hashes are uploaded.
- **Why required:** EDM matches against *your actual data*, which is what drives false positives to near
  zero — but it requires the schema, the hashed upload, and a **refresh cadence** as the data changes.
- **How to verify:** Confirm the source table, the EDM schema, the upload-agent host, and a scheduled
  refresh. **Purview portal → Data classification → Exact data matches** shows configured EDM schemas.
- **How to implement if missing:** Define the EDM schema and refresh process (deferred to the data owner
  for *which* fields are in scope); if EDM is not in your plan or not needed, use custom SITs with
  confidence/keyword tuning instead.

## 2.6 A pilot ring, simulation dwell time, and change control (DLP-specific)
- **Description:** A named **pilot user ring** (a mail-enabled security group of OneDrive users), an
  agreed **simulation dwell time** (how long the policy runs in simulation before enforcement — long
  enough to capture representative content and sharing activity), and the **change-control window** for
  moving simulation → enforce. Extends GR-#6.
- **Why required:** DLP is high-impact; enforcing without a simulation baseline and a limited ring is how
  DLP breaks legitimate collaboration. The house model mandates **simulation first**, then a ring, then
  expand.
- **How to verify:** Confirm the pilot-ring group membership, that **simulation mode** is selected on the
  new policy, and the approval path to enforce.
- **How to implement if missing:** Define the ring (`DLP OneDrive Pilot Ring – Stage1`) and dwell time
  and agree change control before enabling any enforcement action.

## 2.7 An incident/alert triage owner and destination
- **Description:** A named owner (or queue) for **DLP alerts** raised in **Purview portal → Data loss
  prevention → Alerts**, plus where DLP events are reviewed (**Activity Explorer**) and, optionally,
  where they are forwarded (SIEM/Microsoft Sentinel via the Office 365 Management Activity API /
  Defender connectors). Severity and response actions defined.
- **Why required:** A DLP match with no one to triage it is not a control. Alerts and Activity Explorer
  are where matches surface; someone must own triage, severity, and response.
- **How to verify:** Confirm the triage owner/queue (`DLP Alerts – OneDrive – Triage`), the
  alert-severity scheme, and any SIEM forwarding is configured.
- **How to implement if missing:** Assign the owner, define severity/response, and (optionally) wire SIEM
  forwarding before enforcement generates real alerts.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | DLP/classifier licensing (E5 / E5 Compliance for custom/EDM/trainable; verify) | Chosen classifiers available |
| 2.2 | DLP least-privilege roles | Author + triage roles assigned |
| 2.3 | OneDrive provisioned + sharing posture understood | Policy has content/shares to act on |
| 2.4 | Classification intent + SIT inventory | Policy keys off correct SITs |
| 2.5 | EDM source data + agent (if used) | Near-zero-FP matching where needed |
| 2.6 | Pilot ring + simulation dwell + change control | Simulate-first enforced |
| 2.7 | Alert/incident triage owner + destination | Matches are acted on |

> **Deferred to compliance/privacy/legal:** which data categories are in scope, which classifiers
> legally apply, the enforced action per category (e.g. block external sharing vs. warn-and-override),
> and any regulatory applicability. This solution provides the technical configuration and evidence, not
> the determination.
