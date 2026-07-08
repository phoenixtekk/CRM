# Microsoft Purview for Manufacturing

> **Version 1.0.0** · Category: Purview · Solution code: INDMFG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview for Manufacturing

**White-label · Purview Solutions**

Manufacturers carry two data obligations at once: the **intellectual property** that *is* the business
— CAD/CAM designs, process specs, formulas, bills of material, firmware — and, for the defense supply
chain, **Controlled Unclassified Information (CUI)** that must be protected to **CMMC / NIST SP 800-171**
(including export-controlled **ITAR / EAR** technical data). Left to generic defaults, that data leaks
through supplier email, USB drives, and browser uploads, and a CMMC assessment finds no evidence the
controls exist. Microsoft Purview fixes this — but rolled out carelessly, labels confuse engineers,
Data Loss Prevention (DLP) floods the help desk with false positives, and retention deletes too much
or nothing at all.

This is a complete, deploy-it-in-order package that stands up a **Manufacturing-tailored Purview
program**: an IP/CUI sensitivity-label taxonomy whose protection **travels with the file** to
suppliers and OEMs, a **custom classifier for your part/drawing numbers**, DLP that starts in audit
and is tuned before it enforces (with export-control hard-blocks and endpoint coverage), defensible
quality/contract/CUI retention, and **CMMC / NIST 800-171 evidence** tracked in Compliance Manager. It
is written for an administrator with no prior Purview experience.

## What you get
- A plain-language Solution Overview of the IP + CUI program and how sensitivity labels, a custom SIT,
  auto-labeling, DLP, and retention/records work together for Manufacturing.
- A Requirements Guide with verify / implement-if-missing for every Manufacturing prerequisite.
- An Implementation Guide of precise, ordered steps in the Microsoft Purview portal.
- Five PowerShell scripts for configuration discovery, coverage validation, a classification and DLP
  event report, safe remediation of gaps, and a pilot-scope group builder.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A named, reusable set of objects — an IP/CUI label taxonomy, a `SIT - MFG Part/Drawing Number`
classifier, auto-labeling (simulated first), a `DLP Policy - Manufacturing IP and CUI` policy, and
quality/contract retention — deployed on the assess-design-pilot model with a mandatory **DLP audit
gate** before any policy switches to enforce, and a documented rollback.

## The standard deployment model
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**

## Scope boundary
The solution provides the **technical configuration and evidence**. **CMMC / CUI applicability, the
export-control (ITAR/EAR) determination, retention schedules, and records file plans are legal and
compliance determinations** deferred to the organization's compliance, records, privacy, legal, and
export-control functions.

## Outcome
Manufacturing IP and CUI classified, protected, retained, and evidenced with Microsoft Purview —
protection that travels to suppliers, DLP tuned in audit before it enforces, and CMMC / NIST 800-171
readiness — proven on a pilot before you scale.


---


# 1. Solution Overview — Microsoft Purview for Manufacturing

## What this delivers
This solution stands up a **Manufacturing-tailored Microsoft Purview program** — sensitivity labels,
Data Loss Prevention (DLP), retention/records, and compliance posture — aligned to the two data
obligations that define the sector: **protecting intellectual property (IP)** (CAD/CAM designs,
process specs, formulas, bills of material, firmware/source) and **safeguarding Controlled
Unclassified Information (CUI)** for defense-supply-chain work under **CMMC / NIST SP 800-171**
(including export-controlled technical data — **ITAR / EAR**). It is delivered end to end in
Microsoft Purview: designed, configured, **piloted in simulation/test**, validated against pass/fail
gates, then expanded to enforcement.

## Why Manufacturing is different
- **IP is the crown jewel.** Designs, tooling, process know-how, and firmware are the business — a
  leaked drawing or BOM is a competitive and contractual loss, not just a compliance ticket.
- **CUI / CMMC obligations.** Manufacturers in the defense industrial base (DIB) must protect CUI to
  **NIST SP 800-171** and evidence it for **CMMC** assessment; several 800-171 controls map directly
  to Purview (media protection, access control, audit, and — with Microsoft's guidance — CUI
  labelling and DLP).
- **Export control.** Technical data under **ITAR / EAR** must not reach unauthorized (often foreign)
  persons — a DLP and labelling concern with legal weight.
- **Heavy external sharing.** OEMs, suppliers, and contract manufacturers exchange drawings and specs
  constantly; protection must travel with the file, not stop at the tenant boundary.

## How it works in Purview
1. A small, Manufacturing-specific **sensitivity-label taxonomy** (Public → Internal →
   Confidential-IP → CUI, with an export-controlled variant) is published so labels appear in Office,
   Outlook, and the web and **travel with the file** (encryption + visual marking).
2. **Auto-labeling and custom classifiers** help identify IP and CUI at scale (a custom
   sensitive-information type for drawing/part numbers; the CUI trainable classifier where licensed),
   run first in **simulation**.
3. **DLP policies** detect CUI, export-controlled data, and IP markers across Exchange, SharePoint,
   OneDrive, Teams, and managed endpoints — deployed **audit-first**, tuned, then enforced.
4. **Retention & records** keep quality, contract, and CUI records for the required period and dispose
   of them defensibly; **records management** makes regulatory records immutable with disposition
   review.
5. **Compliance Manager** tracks the **CMMC / NIST 800-171** improvement actions so the program is
   evidenced, not just configured.

## What you can control
- The label taxonomy, label order/priority, and the protection each label applies (encryption,
  marking, sharing restrictions) — tuned for IP and CUI.
- Where labels publish and whether **auto-labeling / trainable classifiers** apply them by content.
- DLP scope (Exchange, SharePoint, OneDrive, Teams, endpoint devices), the sensitive-information
  types / labels a policy matches (CUI, ITAR/EAR, IP part-number patterns), and the action
  (audit → notify → block).
- Retention duration, trigger, and end-of-life action (delete, retain, or declare a record), plus
  disposition review for records.

## Benefits
- **IP that travels protected** — a label encrypts and marks a drawing or spec so it stays protected
  when shared to a supplier or OEM.
- **CUI safeguarded and evidenced** — DLP + labels + audit map to NIST 800-171 / CMMC and produce the
  evidence an assessor expects.
- **Fewer leaks, fewer false positives** — DLP tuned in audit before it blocks real risk without
  blocking legitimate manufacturing work.
- **Defensible retention** — quality and contract records kept and disposed on a defined schedule.

## Limitations (be honest with buyers)
- Auto-labeling at rest, endpoint DLP, trainable classifiers, and advanced records require the higher
  **Microsoft 365 E5 / E5 Compliance** plans; the Requirements Guide names the licensing — **verify
  your licensing/tenant**.
- **CMMC / CUI applicability, the export-control determination (ITAR/EAR), retention schedules, and
  records file plans are legal/compliance determinations** — this solution provides the technical
  method and evidence, **not** the determination; those are deferred to your compliance, records,
  privacy, legal, and export-control functions.
- Purview protects data **in Microsoft 365**; OT/shop-floor systems, PLM/PDM, and CAD file shares
  outside M365 are out of scope unless their data lands in M365 workloads.
- Encryption applied by a label can affect legacy CAD/engineering apps that do not understand the
  protection — **pilot before broad enforcement**.

## The standard deployment model
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)**, with a **DLP
> audit gate** before any policy enforces, simulation for auto-labeling, and a documented rollback.


---


# 2. Requirements Guide — Microsoft Purview for Manufacturing

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (licensing,
least-privilege roles, S&C PowerShell/Graph toolchain, in-scope data, compliance/records/legal
stakeholders, and a pilot scope with change control) — this guide adds the **Manufacturing-specific**
prerequisites and does not repeat the six.

## 2.1 Microsoft 365 + Purview compliance licensing (IP + CUI features)
**Description:** Licensing that includes the capabilities this program uses. Sensitivity labels and
baseline DLP ship in **Microsoft 365 E3 / Business Premium**; **auto-labeling at rest, endpoint DLP,
trainable classifiers, advanced records management, and Compliance Manager premium assessments**
require **Microsoft 365 E5** (or the **E5 Compliance / Information Protection & Governance** add-on).
DIB tenants often run in **GCC / GCC High** — confirm the CUI-appropriate cloud.
**Why:** The IP/CUI features here are plan-gated and cloud-gated; they will not appear without the
right plan (and, for CUI, often the government cloud).
**Verify:** M365 admin center → **Billing → Licenses**; confirm the feature is visible in the Purview
portal; run `PURVIEW-MFG-Discovery.ps1`. **Verify your licensing/tenant** — availability evolves.
**Implement:** Assign the required plan (E3/Business Premium for labels + basic DLP; **E5 or the E5
Compliance add-on** for auto-labeling at rest, endpoint DLP, trainable classifiers, advanced records,
Compliance Manager). Confirm the correct sovereign cloud with your compliance/legal team for CUI.

## 2.2 Least-privilege Purview roles
**Description:** The operator holds the least-privilege roles to create labels, DLP, retention, and to
read compliance posture — for example **Compliance Administrator** (or **Information Protection Admin**
plus **Data Loss Prevention** roles) and, for records/disposition, **Records Management**; **Compliance
Manager** read/assessment roles for the CMMC template.
**Why:** Purview uses fine-grained role groups; Global Administrator alone is not the least-privilege
choice.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles and scopes → Role groups**; confirm
membership.
**Implement:** Assign the least-privilege role group under change control; reserve Global Administrator
for tenant-wide changes.

## 2.3 Manufacturing data classification decided (IP + CUI + export control)
**Description:** A one-page classification decision from the business: what is **IP** (designs, CAD/CAM,
process specs, formulas, BOMs, firmware/source), what is **CUI** (per the contract / DFARS 252.204-7012),
and what is **export-controlled** (**ITAR / EAR**) — feeding the label taxonomy this solution publishes.
**Why:** Labels, DLP conditions, and retention are business/legal decisions, not IT defaults; the
CUI and export-control determinations are made by compliance/legal/export-control, not by IT.
**Verify:** A named data owner exists per category and a marked CUI/export-control determination is
recorded (or explicitly deferred to the responsible function).
**Implement:** Convene data owners + compliance/legal/export-control to agree the categories and
markings **before** authoring policies (Implementation Step 1). **Determinations are deferred** to
those functions.

## 2.4 Custom classification building blocks (part/drawing numbers, CUI)
**Description:** The identifiers that flag Manufacturing IP — e.g. a **drawing/part-number pattern** —
captured so a **custom sensitive-information type (SIT)** can detect them, plus a decision on using the
**CUI trainable classifier / CUI SITs** (availability varies by plan/cloud — **verify your tenant**).
**Why:** Generic financial/PII detectors miss engineering IP; a custom SIT keyed to your part-number
format materially improves DLP and auto-labeling accuracy.
**Verify:** A sample of real part/drawing numbers and their format (regex-able) exists; confirm CUI
classifier availability in the Purview portal.
**Implement:** Provide sample identifiers so `SIT - MFG Part/Drawing Number` can be built
(Implementation Step 4); confirm CUI SIT/classifier availability before relying on it.

## 2.5 Pilot scope (users and, for endpoint DLP, devices)
**Description:** A Microsoft Entra security group of pilot users — engineering + a CUI/contracts
team — named `Purview - Manufacturing Pilot`, and, for endpoint DLP, **engineering workstations
onboarded to Microsoft Purview** (the same onboarding used by Defender for Endpoint).
**Why:** Every policy is piloted before rollout; DLP must run in audit on a pilot first, and endpoint
rules (copy to USB, print a drawing, upload to a browser) require onboarded devices.
**Verify:** Entra → **Groups** shows the group; Purview → **Settings → Device onboarding → Devices**
shows pilot devices (endpoint DLP only); run `PURVIEW-MFG-Discovery.ps1`.
**Implement:** Build the group with `PURVIEW-MFG-Set-ScopeTargeting.ps1`; onboard pilot engineering
devices via the Purview onboarding package (or Intune).

## 2.6 Supplier / external-sharing model agreed
**Description:** How drawings and specs are shared externally (OEMs, suppliers, contract
manufacturers) — the collaboration boundaries the labels/DLP must respect (e.g. **encrypt-and-restrict
to named partner domains**, block export-controlled data to unauthorized recipients).
**Why:** Manufacturing lives on external collaboration; protection that blocks legitimate supplier
sharing will be bypassed, while unrestricted sharing leaks IP/CUI.
**Verify:** A list of trusted partner domains and the allowed sharing pattern per label exists.
**Implement:** Capture partner domains and the per-label sharing rule with the business before
configuring label encryption and DLP recipient conditions.

## 2.7 Audit logging enabled
**Description:** Microsoft Purview **audit** (unified audit log) is on — the evidence source for DLP
tuning, CUI access, and CMMC audit-control evidence.
**Why:** DLP tuning, coverage reporting, and 800-171/CMMC audit evidence read audit/activity data.
**Verify:** Purview → **Audit**; searching returns results; run `PURVIEW-MFG-Report.ps1`.
**Implement:** Turn on auditing in the Purview **Audit** solution and allow time for events to
populate.

## 2.8 Records schedule & CMMC/NIST 800-171 requirements captured
**Description:** The **retention schedule** (quality records, contract/CUI records, export records)
and the **CMMC / NIST 800-171** control set the program must evidence — sourced from records
management, compliance, and the contract (DFARS), not guessed.
**Why:** Retention durations and records determinations are legal/records decisions; CMMC control
scope drives which Purview controls you evidence in Compliance Manager.
**Verify:** A records schedule source and the applicable CMMC level / 800-171 baseline are documented
with named approvers.
**Implement:** Obtain the schedule and control baseline from records/compliance; load the **NIST
800-171 / CMMC** assessment template in **Compliance Manager** (Implementation Step 10). **Retention
and records determinations are deferred** to records/compliance/legal.

## 2.9 Change control for enforce-mode changes
**Description:** A documented change-control / rollback process for switching any DLP policy from
audit to enforce, turning auto-labeling out of simulation, or activating a retention policy that
deletes content.
**Why:** Enforce-mode DLP can block engineering/supplier work; auto-labeling mistakes are user-visible;
retention deletion is irreversible.
**Verify:** A change ticket exists with an approver, a pilot scope, and a documented rollback.
**Implement:** Record the change, name the pilot scope, define the rollback, and get approval before
enforcing.

---
## Checklist
- [ ] M365 + Purview licensing (E3/Business Premium for labels + basic DLP; **E5 / E5 Compliance** for auto-labeling at rest, endpoint DLP, trainable classifiers, advanced records, Compliance Manager); correct sovereign cloud for CUI — `PURVIEW-MFG-Discovery.ps1`
- [ ] Least-privilege Purview roles assigned (Compliance Admin / Information Protection + DLP; Records Management)
- [ ] Manufacturing classification decided — IP / CUI / export-controlled (determinations by compliance/legal/export-control)
- [ ] Custom SIT identifiers (part/drawing numbers) supplied; CUI classifier availability confirmed
- [ ] Pilot group `Purview - Manufacturing Pilot` created; engineering devices onboarded (endpoint DLP) — `PURVIEW-MFG-Set-ScopeTargeting.ps1`
- [ ] Supplier / external-sharing model + trusted partner domains agreed
- [ ] Purview audit logging enabled — `PURVIEW-MFG-Report.ps1`
- [ ] Records schedule + CMMC/NIST 800-171 baseline captured (records/compliance)
- [ ] Change control + rollback for enforce-mode / auto-labeling / retention deletion


---


# Global Requirements — Microsoft Purview Solutions

These requirements apply to **every** solution in the **Purview** category (implementing and managing
Microsoft Purview, sensitivity & retention labels, DLP, data lifecycle & records, insider risk,
communication compliance, audit, data security posture management, and data governance). Verify each
before starting a solution's implementation steps.

> **Vendor boundary (applies to every Purview solution).** The **Microsoft Purview portal**
> (purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
> (`Connect-IPPSSession`), and **Microsoft Graph** are authored at exact, current click-by-click /
> cmdlet detail from Microsoft's public documentation. Microsoft Purview features are heavily
> **licensing-/plan-dependent** (many require **Microsoft 365 E5** or the **E5 Compliance** add-on;
> some are in preview) and the portal is **actively evolving** — capability availability and portal
> paths are **cited or flagged "verify your licensing/tenant"**, never asserted or invented.
> **Regulatory, records-retention, and legal determinations** (retention schedules, records file plans,
> legal holds, insider-risk case actions, regulatory applicability) are **deferred to the organization's
> compliance, records, privacy, and legal functions** — the solutions provide the technical
> configuration method and evidence, not the determination. Automation is **PowerShell** (Security &
> Compliance PowerShell / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with the required Purview/compliance licensing
- **Description:** A Microsoft 365 tenant with the **compliance licensing** the capability requires
  (E3 for baseline; **E5 / E5 Compliance** for advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, DSPM, etc.).
- **Why required:** Most Purview capabilities are plan-gated; the feature won't be available without the
  right plan.
- **How to verify:** In the M365 admin center confirm the subscription/add-ons; check the feature is
  visible in the Purview portal.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Purview roles (least-privilege) and portal access
- **Description:** Access with the least-privilege **Purview / compliance role** the solution names
  (e.g. Compliance Administrator, Compliance Data Administrator, Information Protection, Records
  Management, Insider Risk, eDiscovery, Audit roles), with Global Administrator only where required.
- **Why required:** Purview uses fine-grained role groups; configuration requires the matching role.
- **How to verify:** Purview portal → **Roles & scopes / Permissions** — confirm the role membership.
- **How to implement if missing:** Assign the least-privilege role group under change control.

## 3. Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
  ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, modern-auth / MFA-capable admin.
- **Why required:** Configuration, automation, and the provided scripts run through these.
- **How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed with the admin account.
- **How to implement if missing:** Install the modules and confirm modern-auth sign-in before running steps.

## 4. Data sources & scope in scope
- **Description:** The **workloads and data sources** in scope (Exchange, SharePoint, OneDrive, Teams,
  endpoints/devices, and — for data governance — the broader data estate) and a **data-classification /
  sensitivity** intent to drive labels, DLP, and retention.
- **Why required:** Purview policies key off the in-scope workloads and the classification scheme.
- **How to verify:** Confirm the in-scope workloads and the classification/sensitivity approach with
  stakeholders.
- **How to implement if missing:** Define the scope and classification intent before authoring policies.

## 5. Compliance, records, privacy & legal stakeholders
- **Description:** Engagement with the **compliance, records-management, privacy, security, and legal**
  stakeholders whose policies the configuration must satisfy (retention schedules, records file plans,
  regulatory obligations, insider-risk and communication-compliance policy, legal hold).
- **Why required:** Purview configuration must align to enterprise policy and legal/records requirements,
  not technical defaults; several capabilities have HR/legal sensitivity.
- **How to verify:** Confirm the applicable policies, the records schedule, and named approvers.
- **How to implement if missing:** Identify the owners and capture the requirements before configuring.

## 6. A pilot scope and change control
- **Description:** A **pilot scope** (users/sites/policies in simulation or a limited ring) to validate
  on before tenant-wide enforcement, and a **change-control** process — most Purview policies support a
  **simulation / test / disabled** mode that MUST be used before enforcement.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot (simulate) → Validate
  → Expand (enforce)** model; DLP, labels, retention, and insider-risk changes are high-impact.
- **How to verify:** Confirm a named pilot scope, that simulation/test mode is available, and a change
  window/approval path.
- **How to implement if missing:** Define the pilot and agree change control before enforcing anything.

*The deployment model across every Purview solution is the same: **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)**, with explicit pass/fail gates and a documented rollback.
Automation is delivered as **PowerShell** (Security & Compliance PowerShell / Graph) — never with
hardcoded credentials or secrets. Regulatory/records/legal determinations are deferred to the relevant
governance functions.*


---


# 3. Implementation Guide — Microsoft Purview for Manufacturing

Follow these steps **in order**, in the **Microsoft Purview portal** (`https://purview.microsoft.com`).
Portal paths and cmdlets are current at authoring; Purview evolves and features are licensing-/cloud-
dependent — **verify your licensing/tenant** and treat any absent feature as a plan/cloud gap
(Requirement 2.1), not a mistake in the steps.

> **Model:** Design a Manufacturing taxonomy (IP + CUI) → publish labels → add auto-labeling /
> custom classifiers in **simulation** → build DLP in **audit** and tune it (the **DLP audit gate**)
> before enforcing → set retention/records → track CMMC/800-171 in Compliance Manager — piloting each
> on `Purview - Manufacturing Pilot` before you expand. Pattern: **Assess → Design → Configure →
> Pilot (simulate/test) → Validate → Expand (enforce)**.

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| Sensitivity labels | `Sensitivity Label - MFG-Public`, `Sensitivity Label - MFG-Internal`, `Sensitivity Label - MFG-Confidential-IP`, `Sensitivity Label - MFG-CUI`, `Sensitivity Label - MFG-CUI-Export-Controlled` |
| Label policy | `Label Policy - Manufacturing Taxonomy - All Users` |
| Custom SIT | `SIT - MFG Part/Drawing Number` |
| Auto-labeling policy | `Auto-Label - CUI and Export-Controlled - Pilot` |
| DLP policy | `DLP Policy - Manufacturing IP and CUI - Audit` (renamed to `... - Enforce` at the gate) |
| Retention label | `Retention Label - Quality and Contract Records - 7 Year` |
| Retention policy | `Retention Policy - Manufacturing Baseline - 5 Year` |
| Compliance assessment | `Assessment - CMMC / NIST 800-171 - Manufacturing` |

## Step 1 — Design the Manufacturing taxonomy (Assess/Design)
1. With data owners **and** compliance/legal/export-control, agree the labels and the protection each
   applies. A Manufacturing-tailored starting set:
   - `Sensitivity Label - MFG-Public` — cleared for public release; no protection.
   - `Sensitivity Label - MFG-Internal` — internal business data; no encryption.
   - `Sensitivity Label - MFG-Confidential-IP` — designs/specs/BOMs/firmware; **encrypt**, restrict to
     the organization **and named partner domains** (Requirement 2.6).
   - `Sensitivity Label - MFG-CUI` — Controlled Unclassified Information; **encrypt**, restrict to
     authorized users; **CUI header/footer marking**.
   - `Sensitivity Label - MFG-CUI-Export-Controlled` — ITAR/EAR technical data; **encrypt**, restrict
     to authorized **U.S. persons / named recipients only**; export-control marking.
2. Record each label's meaning, protection, marking, and who applies it. **The CUI and export-control
   determinations are made by compliance/legal/export-control** — capture them, don't invent them.

## Step 2 — Create the sensitivity labels
1. Purview portal → **Information Protection → Sensitivity labels → Create a label**.
2. **Name and tooltip:** enter the label name (e.g. `Sensitivity Label - MFG-CUI`) and a user-facing
   tooltip. **Next**.
3. **Scope:** select **Items** (files and emails). **Next**.
4. **Encryption:** choose **Configure encryption** for `MFG-Confidential-IP`, `MFG-CUI`, and
   `MFG-CUI-Export-Controlled`; set permissions — for `MFG-Confidential-IP` allow the org **and** the
   named partner domains; for the CUI labels restrict to authorized users/recipients only. Leave
   `MFG-Public` / `MFG-Internal` unencrypted. **Next**.
5. **Content marking:** add a header/footer/watermark where required — e.g. `CUI` for `MFG-CUI` and an
   export-control banner for `MFG-CUI-Export-Controlled`. **Next**.
6. **Auto-labeling for items:** leave off here (configured centrally in Step 5). **Next → Create the
   label**.
7. Repeat for each label, creating them in sensitivity order
   (`MFG-Public` → `MFG-Internal` → `MFG-Confidential-IP` → `MFG-CUI` →
   `MFG-CUI-Export-Controlled`). Label order sets priority.

## Step 3 — Publish the labels with a label policy
1. Purview portal → **Information Protection → Sensitivity labels → Label policies → Publish labels**.
2. **Choose labels to publish:** add all five taxonomy labels. **Next**.
3. **Assign to users and groups:** add `Purview - Manufacturing Pilot` for the pilot. **Next**.
4. **Policy settings:** require a **justification for downgrading** a label and (optionally) **require
   a label** for new items — important for IP/CUI hygiene. **Next**.
5. **Default label / mandatory labeling:** set a default (for example `MFG-Internal`) if the org wants
   one. **Next**.
6. **Name:** `Label Policy - Manufacturing Taxonomy - All Users`. **Next → Submit**.

## Step 4 — Build the custom sensitive-information type (IP detection)
1. Purview portal → **Data classification → Classifiers → Sensitive info types → Create sensitive info
   type**.
2. **Name:** `SIT - MFG Part/Drawing Number`. **Next**.
3. **Pattern:** add a **primary element** as a **regular expression** matching your part/drawing-number
   format (from Requirement 2.4), optionally with **supporting keywords** (e.g. `drawing`, `rev`,
   `assembly`, `BOM`). Set a **confidence level** and **character proximity**. **Next → Create**.
4. Test it with **Test** using sample content before relying on it. (For CUI, also confirm whether the
   built-in **CUI trainable classifier / CUI SITs** are available in your plan/cloud — **verify your
   tenant** — and prefer them where present.)

## Step 5 — Configure auto-labeling in SIMULATION
1. Purview portal → **Information Protection → Auto-labeling → Create auto-labeling policy**.
2. **Choose the information to label:** pick **Custom** (to use `SIT - MFG Part/Drawing Number` and/or
   the CUI classifier). **Next**.
3. **Name:** `Auto-Label - CUI and Export-Controlled - Pilot`. **Next**.
4. **Locations:** select **SharePoint sites**, **OneDrive accounts**, and **Exchange email** as needed;
   scope to pilot locations. **Next**.
5. **Rules:** condition = `SIT - MFG Part/Drawing Number` (and/or the CUI classifier); set the label to
   apply — `Sensitivity Label - MFG-Confidential-IP` for IP, `Sensitivity Label - MFG-CUI` for CUI
   matches. **Next**.
6. **Test the policy first:** choose **Run policy in simulation mode** — do **not** turn it on. **Next
   → Create**. Review simulation matches (Step 7 / Testing) before turning it on.

## Step 6 — Build the DLP policy in AUDIT mode
1. Purview portal → **Data Loss Prevention → Policies → Create policy**.
2. **Category / template:** choose **Custom** (Manufacturing IP/CUI is not a stock template). **Next**.
3. **Name:** `DLP Policy - Manufacturing IP and CUI - Audit`. **Next**.
4. **Locations:** enable **Exchange email**, **SharePoint sites**, **OneDrive accounts**, **Teams chat
   and channel messages**, and **Devices** (endpoint DLP) as licensed. Scope to
   `Purview - Manufacturing Pilot` where the location supports user scoping. **Next**.
5. **Rules:** add rules that match:
   - the label `Sensitivity Label - MFG-CUI` **or** `Sensitivity Label - MFG-Confidential-IP`,
   - `SIT - MFG Part/Drawing Number`, and
   - export-control indicators (the **ITAR / EAR** sensitive-information types where available — **verify
     your tenant**), with a **recipient condition** blocking send to domains outside the trusted
     partner list (Requirement 2.6).
   Set actions to **audit only** — enable **policy tips** for visibility but do **not** block. For
   endpoint rules, audit **copy to USB / removable media, print, and upload to unallowed browsers**.
   **Next**.
6. **Policy mode:** select **Run the policy in test mode** (policy tips on). **Next → Submit**. The
   policy now audits without blocking.

## Step 7 — Pilot and tune (the DLP audit gate)
1. Let the audit-mode policy run against `Purview - Manufacturing Pilot` for the agreed window.
2. Review matches in Purview → **Data Loss Prevention → Alerts** and **Activity explorer**; run
   `PURVIEW-MFG-Report.ps1` for a classification and DLP-event summary. Review the auto-labeling
   **simulation** results too.
3. Tune to remove false positives — adjust the SIT confidence/proximity, instance counts, and
   exceptions (e.g. legitimate supplier domains).
4. **Gate:** only when the audit shows the policy matches real IP/CUI/export-controlled data and not
   routine engineering work do you proceed to enforce (Step 8). If it is still noisy, keep tuning —
   **do not enforce**.

## Step 8 — Switch DLP to ENFORCE (after the gate)
1. Purview portal → **Data Loss Prevention → Policies →** open `DLP Policy - Manufacturing IP and CUI -
   Audit` → **Edit**.
2. Rename it to `DLP Policy - Manufacturing IP and CUI - Enforce` so the stage is visible.
3. **Rules:** change the action to **Block** (or **Block with override** for internal recipients) as
   the business requires; keep the export-control rule as **hard block**. Keep policy tips on. **Next**.
4. **Policy mode:** select **Turn the policy on**. **Next → Submit**. Enforcement applies to the pilot
   scope first; widen in Step 11.
5. **Rollback (if needed):** set the policy mode back to **Test mode** (audit) or turn the policy off.

## Step 9 — Create retention labels (quality / contract / CUI records)
1. Purview portal → **Data Lifecycle Management → Retention labels → Create a label**.
2. **Name:** `Retention Label - Quality and Contract Records - 7 Year`. **Next**.
3. **Retention settings:** **Retain items for** the period from your records schedule (Requirement 2.8;
   7 years shown as a placeholder — **the schedule is a records/compliance determination**), start of
   period based on when items were created (or labeled). End action: **Delete**, or **Mark as a
   record** (records management) where the item must be immutable (e.g. CUI/contract records). **Next →
   Create**.

## Step 10 — Create a retention policy + records file plan
1. Purview portal → **Data Lifecycle Management → Retention policies → New retention policy**.
2. **Name:** `Retention Policy - Manufacturing Baseline - 5 Year`. **Next**.
3. **Locations:** enable **Exchange mailboxes**, **SharePoint sites**, **OneDrive accounts**, and
   **Teams** as required. Scope to `Purview - Manufacturing Pilot` for the pilot. **Next**.
4. **Retention settings:** retain for the baseline period from the schedule, then delete or retain-only.
   **Next → Submit**.
5. For regulatory/CUI records, configure **Records Management → File plan** to publish record labels and
   enable **disposition review** so deletions are reviewed, not automatic. **File-plan content and
   schedules are records/compliance determinations.**

## Step 11 — Track CMMC / NIST 800-171, then validate and expand
1. Purview portal → **Compliance Manager → Assessments → Add assessment**; select the **CMMC** /
   **NIST SP 800-171** template (availability varies by plan/cloud — **verify your tenant**) and name
   it `Assessment - CMMC / NIST 800-171 - Manufacturing`. Work the **improvement actions** that map to
   the labels/DLP/retention/audit you configured; capture the evidence.
2. Complete the Testing Guide against `Purview - Manufacturing Pilot`; run `PURVIEW-MFG-Validation.ps1`
   (labels published, DLP present, retention present) and `PURVIEW-MFG-Report.ps1` (coverage).
3. **Expand:** republish `Label Policy - Manufacturing Taxonomy - All Users`, the DLP **Enforce**
   policy, and the retention policy from the pilot to broader groups (or **All users** / **All
   locations**) once the pilot passes. Turn auto-labeling **on** (out of simulation) only after its
   simulation is clean.
4. Re-validate each expansion with `PURVIEW-MFG-Validation.ps1` and `PURVIEW-MFG-Report.ps1`.

---
### Order of operations
`Taxonomy (IP+CUI) → labels → label policy → custom SIT → auto-labeling (simulation) → DLP (audit) →
audit gate → DLP (enforce) → retention labels → retention policy/records → CMMC/800-171 in Compliance
Manager → validate → expand`


---


# 5. Testing Guide — Microsoft Purview for Manufacturing

Run after publishing to `Purview - Manufacturing Pilot` (Implementation Step 3 onward), before the DLP
audit gate (Step 7), and again after each expansion.

## Test 1 — Labels published and visible
**Do:** In Outlook / Word (web or desktop) as a pilot user, open the **Sensitivity** button. Or run
`PURVIEW-MFG-Validation.ps1`.
**Expected:** All five taxonomy labels appear (`Sensitivity Label - MFG-Public` through
`Sensitivity Label - MFG-CUI-Export-Controlled`) via `Label Policy - Manufacturing Taxonomy - All
Users`.

## Test 2 — IP label protection travels externally
**Do:** Apply `Sensitivity Label - MFG-Confidential-IP` to a test drawing and share it to (a) a listed
trusted partner domain and (b) a non-listed external address.
**Expected:** The file is encrypted/marked; the trusted partner can open per the label's permissions;
the non-listed external recipient is denied.

## Test 3 — CUI / export-control label restricts
**Do:** Apply `Sensitivity Label - MFG-CUI` (and separately `MFG-CUI-Export-Controlled`) to a test
item and attempt to open it as an out-of-scope/unauthorized user.
**Expected:** The item is encrypted and shows the CUI / export-control marking; the unauthorized user
is denied per the label's permissions.

## Test 4 — Custom SIT detects a part/drawing number
**Do:** Purview → **Data classification → Sensitive info types →** open `SIT - MFG Part/Drawing Number`
→ **Test**, using sample content containing a real-format part number and some decoy text.
**Expected:** The SIT matches the part/drawing number at the configured confidence and does **not**
match the decoys.

## Test 5 — Auto-labeling simulation matches
**Do:** Purview → **Information Protection → Auto-labeling →** open
`Auto-Label - CUI and Export-Controlled - Pilot` → **Simulation**.
**Expected:** The simulation lists items containing part/drawing numbers or CUI markers and proposes
the correct label — and does not flag routine, non-sensitive content.

## Test 6 — DLP is auditing (before the gate)
**Do:** As a pilot user, email a test message containing a labelled IP/CUI file (or a part number) to
an external address; check Purview → **Data Loss Prevention → Alerts** and **Activity explorer**. Or
run `PURVIEW-MFG-Report.ps1`.
**Expected:** `DLP Policy - Manufacturing IP and CUI - Audit` records the match (policy tip shown, no
block) — the audit gate has data to review.

## Test 7 — DLP enforces (after the gate)
**Do:** After Step 8, repeat Test 6 against `DLP Policy - Manufacturing IP and CUI - Enforce`; also try
to send an export-controlled item to an unauthorized recipient, and (endpoint) copy a labelled drawing
to a USB drive.
**Expected:** The action now blocks (or blocks-with-override for internal); the export-control send is
hard-blocked; the USB copy is blocked/audited per the endpoint rule; each event is logged.

## Test 8 — Retention label applied and honored
**Do:** Apply `Retention Label - Quality and Contract Records - 7 Year` to a test item and attempt to
delete it.
**Expected:** The item is retained for the period (or declared a record and blocked from deletion) per
the label.

## Test 9 — Retention policy scoped
**Do:** Confirm `Retention Policy - Manufacturing Baseline - 5 Year` is applied to the pilot locations
(Purview → **Data Lifecycle Management → Retention policies →** open the policy). Or run
`PURVIEW-MFG-Validation.ps1`.
**Expected:** The policy shows **On** and scoped to the pilot mailboxes/sites/OneDrive/Teams.

## Test 10 — CMMC / 800-171 evidence + coverage report
**Do:** In **Compliance Manager**, open `Assessment - CMMC / NIST 800-171 - Manufacturing` and confirm
the configured controls show progress/evidence. Run `PURVIEW-MFG-Report.ps1`.
**Expected:** The mapped improvement actions reflect the labels/DLP/retention/audit you deployed; the
report summarizes classification and DLP events across the enabled services so coverage and gaps are
visible.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6, 8–9 pass on `Purview - Manufacturing Pilot`; the DLP audit shows real IP/CUI matches and acceptable noise |
| **Audit gate** | DLP audit reviewed and tuned; auto-labeling simulation clean; only then is Test 7 (enforce) run |
| **Expand pass** | Tests 1, 6/7, 9, 10 pass after widening scope beyond the pilot |


---


# 6. Troubleshooting Guide — Microsoft Purview for Manufacturing

Common field issues for the Manufacturing IP + CUI program and how to resolve them. Objects are named
verbatim from the Implementation Guide. Most problems are **licensing/cloud gaps**, **replication
delay**, or **audit-not-yet-tuned** — not step mistakes. When a feature is simply absent, treat it as a
plan/cloud gap (Requirement 2.1) and **verify your licensing/tenant** before assuming a fault.

## A label or feature is missing from the portal
- **Symptom:** Auto-labeling at rest, endpoint DLP, trainable classifiers, or advanced records don't
  appear.
- **Likely cause:** These need **Microsoft 365 E5 / E5 Compliance**; DIB tenants often need **GCC /
  GCC High** for CUI. Basic labels + DLP ship in E3/Business Premium.
- **Resolve:** Run `PURVIEW-MFG-Discovery.ps1` to see what the tenant exposes; confirm the plan in the
  M365 admin center; assign the required add-on. **Verify your licensing/tenant** — availability
  evolves and is cloud-dependent.

## New labels don't show in Office / Outlook for pilot users
- **Symptom:** `Sensitivity Label - MFG-*` labels aren't visible after publishing.
- **Likely cause:** **Replication delay** (labels/policies can take hours to appear), the user isn't in
  `Purview - Manufacturing Pilot`, or the client hasn't refreshed.
- **Resolve:** Confirm publication with `PURVIEW-MFG-Validation.ps1`; verify the user is in the pilot
  group (`PURVIEW-MFG-Set-ScopeTargeting.ps1`); have them restart the Office app / re-sign-in; allow
  time to propagate before re-publishing.

## The custom SIT matches too much or too little
- **Symptom:** `SIT - MFG Part/Drawing Number` fires on ordinary text, or misses real part numbers.
- **Likely cause:** Regex too broad/narrow, wrong **confidence level**, or too-wide **character
  proximity**; missing supporting keywords.
- **Resolve:** Open the SIT → **Test** with real and decoy samples; tighten the regex, raise the
  confidence, add supporting keywords (`drawing`, `rev`, `assembly`, `BOM`), and reduce proximity.
  Where the plan provides the built-in **CUI classifier/SITs**, prefer them for CUI.

## Auto-labeling simulation shows nothing (or wrong labels)
- **Symptom:** `Auto-Label - CUI and Export-Controlled - Pilot` simulation is empty or mislabels.
- **Likely cause:** Simulation needs time to crawl; the rule condition or target label is wrong; the
  in-scope locations hold no matching content yet.
- **Resolve:** Allow the simulation to complete; confirm the condition uses `SIT - MFG Part/Drawing
  Number` (and/or the CUI classifier) and applies the correct label; seed a pilot site with sample IP/
  CUI content and re-run. Never turn the policy on until the simulation is clean.

## DLP policy tips don't appear / no audit events
- **Symptom:** No policy tips or Activity-explorer events from `DLP Policy - Manufacturing IP and CUI -
  Audit`.
- **Likely cause:** Policy still deploying; **audit logging off** (Requirement 2.7); the location isn't
  in scope; endpoint devices not onboarded.
- **Resolve:** Confirm auditing is on and returning results; run `PURVIEW-MFG-Report.ps1` for the
  event summary; verify the policy's locations and pilot scoping; for endpoint rules, confirm devices
  show under **Settings → Device onboarding**.

## DLP blocks legitimate supplier / engineering work
- **Symptom:** After enforce, real drawings/specs to trusted partners are blocked.
- **Likely cause:** The policy was enforced before the **audit gate** was clean, or the trusted partner
  domains (Requirement 2.6) aren't in the recipient exceptions.
- **Resolve:** **Rollback** — set `DLP Policy - Manufacturing IP and CUI - Enforce` back to **Test
  mode** (audit); add the trusted partner domains as exceptions; keep export-control as a hard block;
  re-tune in audit, then re-enforce only after the gate passes.

## Label encryption breaks a legacy CAD / engineering app
- **Symptom:** An encrypted `MFG-Confidential-IP` / `MFG-CUI` file won't open in a legacy app.
- **Likely cause:** The application doesn't understand Microsoft Purview encryption/rights.
- **Resolve:** Pilot encryption on a small scope first; for apps that can't consume protection, adjust
  the label's encryption/permissions or exclude those file paths from auto-labeling; validate with data
  owners before broad enforcement.

## Endpoint DLP rules don't fire (USB / print / upload)
- **Symptom:** Copy-to-USB, print, or browser-upload of a labelled drawing isn't audited/blocked.
- **Likely cause:** Engineering workstations aren't **onboarded** to Purview, or **Devices** isn't a
  location on the policy.
- **Resolve:** Onboard devices (the Defender for Endpoint / Intune onboarding), confirm they appear
  under device onboarding, and ensure the DLP policy includes **Devices** with the endpoint actions.

## Retention isn't applying (or deleted too much)
- **Symptom:** `Retention Label - Quality and Contract Records - 7 Year` or `Retention Policy -
  Manufacturing Baseline - 5 Year` doesn't behave as expected.
- **Likely cause:** Policy still propagating; wrong locations; duration/end-action from a **guess**
  rather than the records schedule.
- **Resolve:** Confirm the policy is **On** and scoped (`PURVIEW-MFG-Validation.ps1`); use **disposition
  review** so nothing auto-deletes unreviewed. **Retention durations and records determinations are
  records/compliance/legal calls** — confirm the schedule before activating deletion.

## CMMC / NIST 800-171 assessment template not available
- **Symptom:** `Assessment - CMMC / NIST 800-171 - Manufacturing` can't be created.
- **Likely cause:** The premium **Compliance Manager** template needs E5 / E5 Compliance and varies by
  cloud.
- **Resolve:** Confirm the plan; **verify your tenant**. Where the template is absent, evidence the same
  controls against the available baseline and record the gap — **the CMMC applicability is a compliance
  determination**, deferred.

## PowerShell can't connect or a cmdlet is missing
- **Symptom:** `Connect-IPPSSession` fails, or `Get-Label` / `Get-DlpCompliancePolicy` is unavailable.
- **Likely cause:** ExchangeOnlineManagement module missing/old, or MFA/modern-auth blocked.
- **Resolve:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; sign in with an MFA-capable
  Compliance Administrator; retry. A cmdlet that stays missing after a good connection is a plan/cloud
  gap — **verify your tenant.**

---
### Escalation & rollback
| Situation | Action |
|---|---|
| DLP enforce disrupts work | Revert to **Test mode** (audit); fix exceptions; re-run the audit gate |
| Auto-labeling mislabels | Turn the policy back to **simulation**; fix the rule; re-simulate |
| Retention deleting wrongly | Disable the retention policy; enable **disposition review**; confirm the schedule with records/legal |
| Feature genuinely absent | Treat as licensing/cloud gap (Req 2.1) — **verify your licensing/tenant**, not a step error |
| Records / CUI / export-control question | **Determination deferred** to compliance/records/legal/export-control — capture, don't decide |


---


# 7. Best Practices — Microsoft Purview for Manufacturing

- **Classify IP and CUI separately — and let the business/legal decide the lines.** Keep a small
  taxonomy (`MFG-Public` → `MFG-Internal` → `MFG-Confidential-IP` → `MFG-CUI` →
  `MFG-CUI-Export-Controlled`) people can reason about. The **CUI and export-control (ITAR/EAR)
  determinations are legal/compliance calls** — capture them, never invent them.
- **Protect what travels.** Manufacturing runs on external sharing; use label **encryption scoped to
  named partner domains** for `MFG-Confidential-IP` so a shared drawing stays protected, and restrict
  the CUI labels to authorized recipients only. Protection that travels beats a network boundary.
- **Build a custom SIT for your part/drawing numbers.** Generic financial/PII detectors miss
  engineering IP; a `SIT - MFG Part/Drawing Number` keyed to your real format is the single biggest
  accuracy win for DLP and auto-labeling. Prefer the built-in **CUI classifier/SITs** for CUI where
  your plan/cloud provides them.
- **Simulate auto-labeling.** Always run `Auto-Label - CUI and Export-Controlled - Pilot` in
  simulation and review matches before turning it on — it labels IP/CUI at scale and mistakes are
  visible to engineers and suppliers.
- **Audit DLP before you enforce.** The single most important practice: run
  `DLP Policy - Manufacturing IP and CUI - Audit` in test mode, review matches, tune out false
  positives (legitimate supplier domains, decoy part numbers), and only then enforce. A blocked-work
  storm on the shop floor is the fastest way to lose trust in DLP.
- **Hard-block export-controlled data; block-with-override elsewhere.** Treat ITAR/EAR sends to
  unauthorized recipients as a hard block; for internal IP, block-with-override plus a policy tip
  keeps engineers productive while capturing the risk decision.
- **Cover the endpoint.** Onboard engineering workstations so endpoint DLP can govern **copy to USB,
  print, and browser upload** of labelled drawings — the common real-world IP-leak paths.
- **Name every object by purpose and stage.** Use `<Purpose> - <Scope> - <Stage>` (rename
  `... - Audit` to `... - Enforce` at the gate) so the portal shows exactly where each policy sits in
  its lifecycle.
- **Match retention to the records schedule, and use disposition review.** Set durations from the
  records/DFARS schedule (a records/compliance determination), not a guess; use disposition review for
  CUI/contract records so nothing is auto-deleted unreviewed. Deletion is irreversible.
- **Evidence CMMC / NIST 800-171 as you go.** Work the mapped improvement actions in Compliance
  Manager (`Assessment - CMMC / NIST 800-171 - Manufacturing`) while you configure, so the program is
  assessor-ready — configuration without evidence is not compliance.
- **Verify licensing and cloud for CUI.** Auto-labeling at rest, endpoint DLP, trainable classifiers,
  and advanced records need E5 / E5 Compliance; DIB tenants often need **GCC / GCC High** for CUI —
  **verify your licensing/tenant** rather than assuming a feature is present.
- **Document the objects and the rollback.** Record the taxonomy, SIT, policy names, partner domains,
  scopes, and the rollback (revert DLP to audit; auto-labeling back to simulation; disable a retention
  policy) for repeatability and change control.


---


# 8. Deliverables Summary — Microsoft Purview for Manufacturing

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What a Manufacturing-tailored Purview program is — IP protection + CUI/CMMC — how it works, benefits, limitations |
| 2. Requirements Guide | Every Manufacturing prerequisite with Verify / Implement-if-missing (references the Purview category Global Requirements) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal steps — IP+CUI taxonomy, custom SIT, auto-labeling (simulation), DLP audit-then-enforce, retention/records, CMMC/800-171 in Compliance Manager |
| 5. Testing Guide | Validation procedures with pass/fail gates and the DLP audit gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for IP + CUI |

## PowerShell scripts
| Script | What it does |
|---|---|
| `PURVIEW-MFG-Discovery.ps1` | Reports the tenant's sensitivity labels, DLP policies, retention config, and the custom SIT; flags endpoint onboarding and licensing signals |
| `PURVIEW-MFG-Validation.ps1` | Confirms the Manufacturing labels are published, the DLP policy exists (with mode), and the retention policy exists and is on |
| `PURVIEW-MFG-Report.ps1` | Classification + DLP-event coverage summary across the enabled services (IP/CUI focus) |
| `PURVIEW-MFG-Remediation.ps1` | Safe remediation of common gaps (default `-WhatIf`); enables a published-but-off label/retention policy — never auto-enforces DLP |
| `PURVIEW-MFG-Set-ScopeTargeting.ps1` | Builds/updates the `Purview - Manufacturing Pilot` Entra group |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate/test) →
  Validate → Expand (enforce)**, with a DLP audit gate before enforce and a documented rollback.

## Outcome
A Manufacturing-tailored Microsoft Purview program — a clear IP/CUI label taxonomy that travels with
the file, a custom part-number classifier, DLP tuned in audit before it enforces (with export-control
hard-blocks and endpoint coverage), defensible quality/contract/CUI retention, and CMMC / NIST 800-171
evidence in Compliance Manager — proven on a pilot before you scale. **Regulatory, records, and
export-control determinations remain with the organization's compliance, records, legal, and
export-control functions.**
