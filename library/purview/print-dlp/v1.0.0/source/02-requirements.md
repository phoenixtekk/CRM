# 2. Requirements — Print DLP (Microsoft Purview)

These are the **solution-specific** prerequisites for configuring the **Print** restriction for sensitive
content on endpoints. They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles, S&C
PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a
pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to implement
if missing**.

---

## 2.1 Licensing sufficient for Endpoint DLP print restrictions
- **Description:** Endpoint DLP activity restrictions — including the **Print** activity — are **plan-gated**,
  typically **Microsoft 365 E5** or the **E5 Compliance** add-on. Specific print behaviours (printer-group
  differentiation, macOS print) may be **newer or vary by OS/tenant** and are gated on minimum OS builds.
  This extends GR-#1 with the capability-specific plan detail.
- **Why required:** A DLP policy scoped to the Devices location and using the Print activity will not
  function without the required plan; the activity may not even be selectable.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Purview portal → Data Loss Prevention** confirm the **Devices** location and, when authoring a rule, that
  **Print** appears under *"Audit or restrict activities on devices."* **Flag "verify your licensing/tenant"**
  — availability and macOS support evolve.
- **How to implement if missing:** Acquire/assign the required licensing (E5 / E5 Compliance) before building
  the restriction; if a specific print behaviour is unavailable in your tenant/OS, deliver Windows print
  restriction first and revisit the rest when the capability is enabled.

## 2.2 DLP-specific least-privilege roles
- **Description:** The **DLP role groups** in the Purview portal — **Compliance Administrator** or
  **Compliance Data Administrator** to create/manage DLP policies, **DLP Compliance Management** for policy
  management, **View-Only DLP Compliance Management** for read-only review, and the **Data Loss Prevention**
  role for alert/incident handling. Global Administrator only where genuinely required. Extends GR-#2.
- **Why required:** Purview enforces fine-grained role groups; policy authoring and alert triage require the
  matching role, and least privilege keeps the blast radius small.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** — confirm your account's
  role-group membership includes the DLP roles you need.
- **How to implement if missing:** Assign the least-privilege DLP role group under change control; separate
  policy authors from alert triagers where possible.

## 2.3 Devices onboarded to Purview (the hard gate for any endpoint restriction)
- **Description:** Endpoint DLP monitors activities on **onboarded Windows 10/11 and macOS devices**.
  Onboarding is done in **Purview portal → Settings → Device onboarding** (or via Intune / a script / Group
  Policy) and is **shared with Microsoft Defender for Endpoint onboarding** — devices already onboarded to
  Defender for Endpoint are onboarded for Endpoint DLP. Print restriction additionally depends on **minimum
  OS builds** and OS-specific support (Windows print is the most complete; **macOS print support varies —
  verify your tenant**).
- **Why required:** A policy scoped to the **Devices** location does nothing on a device that is not onboarded
  and reporting. Onboarding is the non-negotiable prerequisite for print control.
- **How to verify:** **Purview portal → Settings → Device onboarding → Devices** shows onboarded devices;
  confirm target devices appear and are reporting. Confirm each device meets the minimum OS build documented
  by Microsoft for the Print activity. Script #5 (`DLPPRINT-EndpointReadiness.ps1`) surfaces the readiness
  signals.
- **How to implement if missing:** Onboard devices via the Purview device-onboarding package, Intune, or
  Group Policy; confirm the minimum OS build and any required AV/agent state per Microsoft docs before
  scoping the restriction.

## 2.4 A classification intent — the SITs, classifiers, or labels that mark "sensitive"
- **Description:** A documented view of **which content must not be printed** (e.g. payment card data,
  national IDs, health identifiers, source code, or any item carrying a specific **sensitivity label**)
  mapped to the **detector** that identifies it — built-in SITs where they fit, **custom SITs / EDM /
  trainable classifiers** for gaps, and/or a **sensitivity-label condition**. Extends GR-#4.
- **Why required:** The restriction keys off *what* is sensitive; a print rule with no precise detector
  either catches nothing or catches everything (false-positive flood).
- **How to verify:** **Purview portal → Data classification → Classifiers → Sensitive info types** lists
  built-in and custom SITs; **Information protection → Labels** lists sensitivity labels. Confirm the ones
  you need exist (or are planned) with the data owners.
- **How to implement if missing:** Build the SIT/label inventory (this solution's Discovery script assesses
  built-in SIT coverage and any existing endpoint restrictions); plan custom SITs / EDM / a label condition
  for categories not covered.

## 2.5 Printer-group and app-exception intent
- **Description:** The definition of **which printers are sanctioned** for sensitive output (e.g. a
  locked-down corporate/managed print queue) versus **network**, **local (USB/directly attached)**, and
  **universal / print-to-PDF/XPS** printing that should be audited or blocked — expressed as **printer
  groups** — plus any **applications** whose printing is legitimately exempt. Endpoint DLP evaluates the
  Print activity against **printer groups** and the app lists in **Endpoint DLP settings**.
- **Why required:** Without printer-group differentiation, the restriction catches all legitimate printing to
  the sanctioned corporate queue alongside the risky paths, driving false positives and killing adoption.
- **How to verify:** **Purview portal → Data loss prevention → Endpoint DLP settings → Printer groups**
  shows the defined groups; confirm the sanctioned corporate printers are represented before authoring the
  rule.
- **How to implement if missing:** Capture the sanctioned printer list (name/IP/USB identifiers) from IT,
  define the `Printers – Corporate – Allowed` group and any others, and configure the Endpoint DLP settings
  lists before enforcing.

## 2.6 A pilot ring, simulation dwell time, and change control (endpoint-specific)
- **Description:** A named **pilot user/device ring**, an agreed **simulation/audit dwell time** (how long
  the policy runs in audit before enforcement — long enough to capture representative print activity, e.g.
  through a monthly close or billing cycle where printing spikes), and the **change-control window** for
  moving audit → enforce. Extends GR-#6.
- **Why required:** Print blocking is high-impact and highly visible to users; enforcing without an audit
  baseline and a limited ring is how the control breaks day-to-day work. The house model mandates
  **simulation/audit first**, then a ring, then expand.
- **How to verify:** Confirm the pilot ring membership, that the policy is created in **simulation/audit
  mode**, and the approval path to enforce.
- **How to implement if missing:** Define the ring and dwell time and agree change control before enabling
  any block action.

## 2.7 An incident/alert triage owner and destination
- **Description:** A named owner (or queue) for **DLP alerts** raised in **Purview portal → Data loss
  prevention → Alerts**, plus where restricted-activity events are reviewed (**Activity Explorer**) and,
  optionally, where they are forwarded (SIEM / Microsoft Sentinel via the Office 365 Management Activity API
  / Defender connectors). Severity and response actions defined.
- **Why required:** A restricted print event with no one to triage it is not a control. Alerts and Activity
  Explorer are where matches surface; someone must own triage, severity, and response.
- **How to verify:** Confirm the triage owner/queue (`DLP Alerts – Print – Operations`), the alert-severity
  scheme, and any SIEM forwarding is configured.
- **How to implement if missing:** Assign the owner, define severity/response, and (optionally) wire SIEM
  forwarding before enforcement generates real alerts.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | Endpoint DLP print licensing (E5 / E5 Compliance; verify OS/tenant support) | Print activity available/selectable |
| 2.2 | DLP least-privilege roles | Author + triage roles assigned |
| 2.3 | Devices onboarded to Purview (+ min OS build) | Endpoint location & Print activity functional |
| 2.4 | Classification intent — SITs / classifiers / labels | Restriction keys off the correct detector |
| 2.5 | Printer groups + app exceptions | Corporate printing allowed; risky paths restricted |
| 2.6 | Pilot ring + simulation dwell + change control | Simulate/audit-first enforced |
| 2.7 | Alert/incident triage owner + destination | Restricted prints are acted on |

> **Deferred to compliance/privacy/legal:** which data categories are in scope, which classifiers/labels
> legally apply, the enforced action per category, and any regulatory applicability. This solution provides
> the technical configuration and evidence, not the determination.
