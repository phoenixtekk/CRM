# 2. Requirements — CMMC / CUI DLP Pack (Microsoft Purview)

These are the **solution-specific** prerequisites for implementing CUI-tuned Purview DLP for CMMC / DFARS /
NIST SP 800-171 alignment. They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles,
S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and
a pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to implement
if missing**.

> **Determination boundary.** Whether a NIST SP 800-171 / CMMC practice is **satisfied**, the SPRS score,
> and the assessment outcome are decided by your **compliance function and a C3PAO** — not by this pack.
> *Which* data is CUI, *which* CUI categories/markings apply, and the *enforced action* are compliance /
> contracts / legal determinations. This pack provides the technical control and evidence.

---

## 2.1 A CUI marking & labeling decision (the prerequisite that makes DLP possible)
- **Description:** A documented **CUI marking and sensitivity-labeling decision** from your compliance/
  contracts function: the **CUI banner and portion markings** you use (per the **NARA CUI Registry** /
  32 CFR Part 2002 — e.g. `CUI`, `CUI//SP-CTI`, `CUI//SP-EXPT`), and the **Purview sensitivity label(s)**
  (`CUI`, with sub-labels per category if used) that carry those markings. DLP in this solution keys off the
  **label** and the **markings**.
- **Why required:** There is **no built-in "CUI" detector**. DLP can only act on CUI that is **marked or
  labeled**; the marking/label decision is the input the whole program depends on.
- **How to verify:** Confirm the marking scheme with compliance; in **Purview portal → Information protection
  → Sensitivity labels**, confirm the `CUI` label (and any sub-labels) exist and are **published** to the
  CUI-handling users.
- **How to implement if missing:** Have compliance define the marking scheme and stand up the `CUI`
  sensitivity label(s) with the correct content marking (and encryption where required) **before** building
  marking-keyed DLP. *Which markings/categories apply is a compliance determination, not a technical one.*

## 2.2 Licensing sufficient for CUI DLP — especially Endpoint DLP and label-based conditions
- **Description:** DLP for **Exchange/SharePoint/OneDrive/Teams** and **built-in SITs** is broadly available,
  but **Endpoint DLP**, **sensitivity-label-based DLP conditions**, **custom classifiers**, and **Exact Data
  Match** are typically **Microsoft 365 E5** or the **E5 Compliance** add-on (some capabilities are in
  **preview**). Extends GR-#1.
- **Why required:** A policy that scopes the Devices location or matches on a **sensitivity label** requires
  the plan that includes those capabilities; otherwise the policy will not function.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Purview portal → Data Loss Prevention** confirm the **Devices** location and the **"content contains
  sensitivity label"** condition are available. **Flag "verify your licensing/tenant."**
- **How to implement if missing:** Acquire/assign E5 / E5 Compliance before building endpoint or label-based
  policies; scope the initial rollout to features your plan covers.

## 2.3 Tenant type confirmed — Commercial vs GCC vs GCC High
- **Description:** The **cloud environment** the CUI enclave lives in — **Commercial, GCC, or GCC High** —
  confirmed, because feature availability, portal URLs, and some SIT/label behaviors **differ** between them.
  Many CUI/CDI (and export-controlled) workloads run in **GCC High**.
- **Why required:** Portal paths and capability availability this solution cites are from Microsoft's public
  docs for Commercial/GCC; **GCC High can differ** and must be verified rather than assumed. *Whether CUI
  must reside in GCC High (e.g. for ITAR/export-controlled categories) is a compliance/contracts
  determination.*
- **How to verify:** Confirm the tenant type with your admins; confirm the correct Purview portal endpoint
  for that environment and that the features you plan to use are present there.
- **How to implement if missing:** Determine the tenant type before authoring; treat every portal path/
  capability as **"verify in your (GCC High) tenant"** and adjust where Microsoft's GCC High docs differ.

## 2.4 CUI-handling scope (enclave) and included/excluded population
- **Description:** The **users, groups, sites, and devices that handle CUI** — the CUI enclave — identified
  as the DLP **included** scope, with the rest of the tenant **excluded** (or covered by a lighter policy).
  Extends GR-#4.
- **Why required:** CUI DLP should focus enforcement where CUI actually is; scoping to the enclave reduces
  false positives and blast radius, and keeps the control defensible.
- **How to verify:** Confirm the enclave membership (users/groups/sites/devices) with the CUI program owner;
  confirm the groups exist in the tenant to scope policies against.
- **How to implement if missing:** Define the enclave and the security groups/site list before scoping
  policies; the delivered scope helper reports and (with `-Commit`) sets the included/excluded scope.

## 2.5 Devices onboarded to Purview for Endpoint DLP
- **Description:** Endpoint DLP monitors activities on **onboarded Windows 10/11 and macOS devices**.
  Onboarding is done in **Purview portal → Settings → Device onboarding** (or via Intune / script / Group
  Policy) and is **shared with Microsoft Defender for Endpoint onboarding**.
- **Why required:** A DLP policy scoped to the **Devices** location does nothing on a device that is not
  onboarded and reporting — and CUI often walks out via USB/print on endpoints.
- **How to verify:** **Purview portal → Settings → Device onboarding → Devices** shows onboarded devices;
  confirm the CUI-handling devices appear and are reporting.
- **How to implement if missing:** Onboard devices via the Purview package, Intune, or Group Policy; confirm
  the minimum OS build and required agent/AV state per Microsoft docs before scoping endpoint policies.

## 2.6 CUI marking keyword list / custom SIT source (backs up the label)
- **Description:** The exact **CUI banner and portion-marking strings** (and any category keyword lists — CTI,
  export-control, etc.) to build the `CUI Banner Marking – Custom SIT – Classification` keyword SIT that
  catches marked-but-unlabeled CUI. Supplied by compliance from your marking policy.
- **Why required:** The label is the primary signal but does not cover CUI that arrives marked-but-unlabeled
  (e.g. from a partner) or is authored before labeling. The marking SIT is the backstop — and it must use
  **your real markings**, not invented strings.
- **How to verify:** Confirm the marking strings with compliance; test the resulting custom SIT in the SIT
  wizard's **Test** step against known-marked sample text.
- **How to implement if missing:** Obtain the marking list from compliance and build the keyword SIT; if a
  category is conceptual (not string-based), evaluate a trainable classifier (verify availability/plan).

## 2.7 A pilot ring, simulation dwell time, and change control (CUI-specific)
- **Description:** A named **CUI pilot ring** (`CUI DLP Pilot Ring – Stage1`), an agreed **simulation dwell
  time** (long enough to capture representative CUI traffic), and the **change-control window** for moving
  simulation → enforce. Extends GR-#6.
- **Why required:** CUI DLP is high-impact and touches contract-critical work; enforcing without a simulation
  baseline and a limited ring is how the control breaks the business and gets disabled. Simulation-first is
  mandated by the house model.
- **How to verify:** Confirm the ring membership, that **simulation mode** is selected on each new policy,
  and the approval path to enforce.
- **How to implement if missing:** Define the ring and dwell time and agree change control before enabling
  any enforcement action.

## 2.8 An incident/alert triage owner, destination, and evidence retention
- **Description:** A named owner (or queue) for **CUI DLP alerts** (`CUI DLP Alerts – Triage – Operations`)
  in **Purview → Data loss prevention → Alerts**, where events are reviewed (**Activity Explorer**), where
  they are forwarded (SIEM / Microsoft Sentinel, if used), and how the **evidence is retained** for
  assessment/audit.
- **Why required:** A CUI match with no triage is not a control — and CMMC/DFARS expect an **auditable
  evidence trail** of incident handling. Someone must own triage, severity, response, and evidence retention.
- **How to verify:** Confirm the triage owner/queue, the severity scheme, any SIEM forwarding, and the
  evidence-retention location/period.
- **How to implement if missing:** Assign the owner, define severity/response and retention, and (optionally)
  wire SIEM forwarding before enforcement generates real alerts. *Incident-reporting obligations under DFARS
  are a compliance/legal determination.*

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | CUI marking & sensitivity-label decision | DLP has a marking/label to key off |
| 2.2 | Licensing (E5 / E5 Compliance; label-based + endpoint) | Endpoint & label conditions available |
| 2.3 | Tenant type confirmed (Commercial/GCC/**GCC High**) | Paths/features verified, not assumed |
| 2.4 | CUI enclave scope (included/excluded) | Enforcement focused on CUI population |
| 2.5 | Devices onboarded to Purview | Endpoint location functional |
| 2.6 | CUI marking keyword SIT source | Marked-but-unlabeled CUI still caught |
| 2.7 | Pilot ring + simulation dwell + change control | Simulate-first enforced |
| 2.8 | Alert triage owner + destination + evidence retention | Matches acted on and evidenced |

> **Deferred to compliance / contracts / legal / C3PAO:** which data is CUI, which categories/markings apply,
> the enforced action per condition, DFARS incident-reporting obligations, GCC High residency requirements,
> and **all CMMC / NIST SP 800-171 control-satisfaction and assessment determinations**. This solution
> provides the technical configuration and evidence, not the determination.
