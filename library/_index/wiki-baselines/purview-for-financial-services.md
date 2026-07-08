# Microsoft Purview for Financial Services

> **Version 1.0.0** · Category: Purview · Solution code: INDFIN

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview for Financial Services

**White-label · Purview / Industry (FINRA · SEC · GLBA)**

Financial Services firms carry specific data-protection and books-and-records obligations — protecting
customer nonpublic personal information (NPI) under **GLBA / Reg S-P**, preserving communications and
records under **SEC Rule 17a-4 / FINRA Rule 4511** and **SEC Rule 204-2**, and supervising employee
communications under **FINRA Rule 3110**. Microsoft Purview can deliver all of this — but rolled out
carelessly, labels confuse users, Data Loss Prevention (DLP) floods advisers and traders with false
positives, retention either deletes too much or locks the wrong thing forever, and supervision creates
privacy risk.

This is a complete, deploy-it-in-order package for standing up a **Financial Services-tailored Purview
program** with a repeatable, safe method: an FS sensitivity-label taxonomy that protects NPI and MNPI,
DLP policies that start in audit and are tuned before they enforce, retention/records aligned to the
firm's schedule (with an immutability mechanism for SEC/FINRA/CFTC electronic-records rules applied
only after sign-off), and a communication-compliance program with strict role separation. It is
written for an administrator with no prior Purview experience.

## What you get
- A plain-language Solution Overview of the four capabilities — sensitivity labels, DLP, data
  lifecycle & records, communication compliance — and how they align to FINRA/SEC/GLBA.
- A Requirements Guide with verify / implement-if-missing for every FS-specific prerequisite,
  including separated communication-compliance roles.
- An Implementation Guide of precise, ordered steps in the Microsoft Purview portal.
- Five PowerShell scripts for discovery, validation, a classification/DLP report, safe remediation,
  and a pilot-scope group builder — read-only or `-WhatIf` by default, no credentials in code.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A named, reusable set of objects — an FS label taxonomy, auto-labeling for NPI, DLP policies,
retention labels/records, and a supervision policy — deployed on the assess-design-configure-pilot
model with a mandatory DLP audit gate before enforce, a records/legal sign-off gate before
Preservation Lock, and a documented rollback.

## Boundary
The package delivers the **technical method and evidence**, not the regulatory determination. The
record set, retention periods, regulatory-record declarations, the supervision scheme, and any
FINRA/SEC/GLBA applicability are deferred to the firm's compliance, records, privacy, and legal
functions. Purview capabilities are licensing-dependent (largely **E5 / E5 Compliance**) and the
portal evolves — verify your licensing/tenant.

## The standard deployment model
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**

## Outcome
A Financial Services Purview program — NPI/MNPI protected, DLP tuned in audit before it enforces,
retention/records aligned to the firm's schedule with an immutability mechanism for SEC/FINRA/CFTC
rules, and supervision with role separation — proven on a pilot before you scale, and defensible.


---


# 1. Solution Overview — Microsoft Purview for Financial Services

## What this delivers
This solution stands up a **Financial Services-tailored Microsoft Purview program** — sensitivity
labels, Data Loss Prevention (DLP), data lifecycle & records management, and communication
compliance — configured to support a firm's obligations under **FINRA**, the **SEC**, and the
**Gramm-Leach-Bliley Act (GLBA / Reg S-P)**. Every policy is deployed on the house model, piloted in
**simulation / test** where the capability supports it, validated against pass/fail gates, and only
then enforced and expanded.

> **Boundary you must honor.** This solution supplies the **technical configuration method and the
> evidence** — not the regulatory determination. Which records are in scope, the exact retention
> periods, the supervision/lexicon requirements, and the applicability of any rule are **compliance,
> records, privacy, and legal determinations** and are deferred to those functions. Purview features
> are **licensing-/plan-dependent** (much of this requires **Microsoft 365 E5** or the **E5
> Compliance** add-on) and the portal evolves — **verify your licensing/tenant** before relying on a
> capability.

## The four Purview capabilities this program combines
1. **Sensitivity labels** — persistent classification (for example `FS Public`, `FS Internal`,
   `FS Confidential (NPI/GLBA)`, `FS Restricted (MNPI)`) that can encrypt, mark, and restrict sharing
   of nonpublic personal information (NPI) and material nonpublic information (MNPI). The protection
   travels with the file.
2. **Data Loss Prevention (DLP)** — policies that detect financial and customer data (bank account and
   ABA routing numbers, SSNs, card numbers, SWIFT/IBAN, or a matched sensitivity label) and act —
   audit, warn, or block — as users share it across Exchange, SharePoint, OneDrive, Teams, and managed
   endpoints. Microsoft ships **U.S. Gramm-Leach-Bliley Act (GLBA)** and **U.S. Financial Data**
   policy templates as starting points (verify availability in your tenant).
3. **Data lifecycle & records management** — retention labels and policies that keep books-and-records
   for the required period and control disposition. A retention label can be configured as a
   **regulatory record** and a retention policy can carry a **Preservation Lock** so the configuration
   itself becomes immutable — the mechanism Microsoft positions (per its published Cohasset Associates
   assessment) for **SEC Rule 17a-4(f)**, **FINRA Rule 4511(c)**, and **CFTC Rule 1.31(c)–(d)**
   electronic-records requirements. *Whether a given record must be preserved this way is a
   records/legal determination.*
4. **Communication compliance** — supervisory review of employee communications for regulatory risk.
   Purview ships financial-services templates (for example **Monitor for regulatory compliance**,
   **Monitor for money laundering**, **Monitor for stock manipulation**, **Monitor for gifts and
   entertainment**), supporting a firm's **FINRA Rule 3110** supervision program. *The
   supervision scheme, lexicons, and any case outcome are compliance/legal determinations.*

## How it works
1. You agree a small **FS label taxonomy** with the data owners and publish it to a pilot group with a
   label policy; auto-labeling can apply the NPI label automatically by content match — first in
   **simulation**.
2. DLP policies reference financial sensitive-information types and/or the FS labels. Each policy is
   deployed in **test/audit** mode first; you review the matches (the **DLP audit gate**), tune out
   false positives, and only then enforce.
3. **Retention labels and policies** set how long communications and books-and-records live and what
   happens at end-of-life (retain, delete, or declare a **regulatory record** with disposition
   review). **Preservation Lock** is applied only after the records/legal owner confirms the schedule.
4. A **communication compliance** policy is stood up in a limited pilot for supervisory review, with
   strict **role separation** (admin vs. analyst vs. investigator) and privacy-by-design.
5. Every action is logged in the Purview **audit** and **Activity explorer**, so classification, DLP,
   records, and supervision coverage is reportable and defensible.

## What you can control
- The FS label taxonomy, order/priority, and each label's protection (encryption, marking, sharing
  limits for NPI and MNPI).
- Where labels publish and whether auto-labeling applies the NPI label by content match.
- DLP scope (Exchange, SharePoint, OneDrive, Teams, endpoints), the financial sensitive-info types or
  labels a policy matches, and the action (audit, notify, block).
- Retention duration, trigger, end-of-life action, **regulatory-record** declaration, disposition
  review, and **Preservation Lock**.
- The communication-compliance policy scope, conditions/templates, and reviewer role separation.

## Benefits
- **Protection that travels** — a sensitivity label encrypts and marks NPI/MNPI so it stays protected
  outside the firm.
- **Fewer leaks, fewer false positives** — DLP tuned in audit before enforcement blocks real customer-
  data leakage without blocking legitimate work.
- **Defensible books-and-records** — communications and records kept and disposed on a defined
  schedule, with an immutability mechanism aligned to SEC/FINRA/CFTC electronic-records rules.
- **Supervisable communications** — a communication-compliance program that supports FINRA 3110
  supervision with privacy-by-design and role separation.
- **Reportable coverage** — classification, DLP, records, and supervision evidence visible per service.

## Limitations (be honest with buyers)
- Auto-labeling at rest, endpoint DLP, records management, communication compliance, and Audit
  (Premium) require the higher Microsoft 365 / Purview plans (E5 or the E5 Compliance add-on) — the
  Requirements Guide names the licensing; **verify your tenant**.
- **Preservation Lock is effectively irreversible** — once applied you cannot make the retention
  policy less restrictive or remove locations. Apply it **only** after the records/legal owner signs
  off the schedule.
- **Regulatory alignment is not automatic.** Configuring Purview does not, by itself, make a firm
  compliant; the determinations (what is a record, how long, what is supervised) are the firm's, and
  Microsoft's 17a-4 positioning rests on a specific configuration described in its Cohasset
  assessment — confirm with your compliance and legal owners.
- Communication compliance is **HR/privacy-sensitive** — pseudonymization and strict role separation
  are required; outcomes are deferred to HR/legal.
- Encryption applied by a label can affect legacy/third-party apps; pilot before broad enforcement.

## The standard deployment model
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).** Labels and
> auto-labeling run in **simulation**, DLP runs in **audit** behind a mandatory audit gate,
> communication compliance runs on a **limited pilot**, and **Preservation Lock** is applied only
> after records/legal sign-off — each stage with explicit pass/fail gates and a documented rollback.


---


# 2. Requirements Guide — Microsoft Purview for Financial Services

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared Purview requirements) — this guide names the **Financial Services-specific** licensing, roles,
scope, and stakeholders and does not repeat the six.

> **Determination boundary.** Requirements that name a regulation (FINRA/SEC/GLBA) describe the
> **technical prerequisite**, not the regulatory obligation. The applicability, the record set, the
> retention periods, and the supervision scheme are **compliance/records/privacy/legal
> determinations** — capture them from those owners; do not infer them here.

## 2.1 Microsoft 365 + Purview licensing for the FS capabilities
**Description:** Licensing that covers all four capabilities this program uses. Sensitivity labels and
basic DLP are in Microsoft 365 E3 / Business Premium; **auto-labeling at rest, endpoint DLP, records
management, communication compliance, and Audit (Premium)** require **Microsoft 365 E5** or the **E5
Compliance** add-on.
**Why:** The FS capabilities (auto-labeling NPI at rest, endpoint DLP, regulatory records,
communication compliance) are plan-gated and will not appear without the higher plan.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; confirm the feature is visible in the
Purview portal; run `FS-Purview-Discovery.ps1`.
**Implement:** Assign the required plan before starting; **verify your tenant** — availability evolves.

## 2.2 Least-privilege Purview roles, with role separation for communication compliance
**Description:** The operator holds the least-privilege roles for each capability — for example
**Compliance Administrator** (or **Information Protection Admin** + **Data Loss Prevention**),
**Records Management**, and for supervision the **Communication Compliance** role groups. Communication
compliance MUST use **separated roles**: *Communication Compliance Admins* (configure), *Analysts*
(triage pseudonymized alerts), and *Investigators* (resolve cases) held by **different** people.
**Why:** Purview uses fine-grained role groups; supervision is HR/privacy-sensitive and its roles must
be separated so no single person configures policy, triages, and investigates.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles and scopes → Role groups**; confirm
membership and that the three communication-compliance roles are held by different people.
**Implement:** Assign the least-privilege role groups under change control; separate the three
communication-compliance roles. Reserve Global Administrator for tenant-wide changes only.

## 2.3 FS sensitivity-label taxonomy defined (NPI / MNPI)
**Description:** A short, agreed set of labels with clear meaning — the taxonomy this solution
publishes: `Sensitivity Label - FS Public`, `Sensitivity Label - FS Internal`,
`Sensitivity Label - FS Confidential (NPI/GLBA)`, `Sensitivity Label - FS Restricted (MNPI)`.
**Why:** Labels only work if users understand them; NPI (GLBA nonpublic personal information) and MNPI
(material nonpublic information) need distinct handling and the taxonomy must say so.
**Verify:** A one-page taxonomy exists (label name, meaning, protection, who applies it).
**Implement:** Agree a 3–5 label taxonomy with data owners and compliance before configuring
(Implementation Step 1).

## 2.4 Records schedule and supervision scheme from compliance/records/legal
**Description:** The **record set and retention schedule** (which communications and books-and-records,
kept how long, disposed how) and the **supervision scheme** (which communications are reviewed, by
whom, with what lexicons) — supplied by the compliance, records, and legal owners.
**Why:** Retention durations, regulatory-record declarations, Preservation Lock, and the communication-
compliance policy are **business/legal decisions**, not IT defaults; without them the configuration
will be wrong or over-reaching. Example anchors the firm's owners may reference — **FINRA Rule 4511 /
SEC Rule 17a-4** (broker-dealer books & records), **SEC Rule 204-2** (investment-adviser records),
**FINRA Rule 3110** (supervision), **GLBA / Reg S-P** (protection of NPI) — *cited for context only;
applicability and periods are the firm's determination.*
**Verify:** A named owner and a written schedule/supervision requirement exist per record category.
**Implement:** Obtain the schedule and supervision requirement from the owners; capture the source so
it is defensible. Do **not** apply Preservation Lock until this is signed off.

## 2.5 In-scope workloads and data sources
**Description:** The **workloads** in scope for FS data — Exchange, SharePoint, OneDrive, Teams, and
endpoints — and the customer/financial data types that drive labels, DLP, and retention (NPI, account
data, MNPI).
**Why:** Purview policies key off the in-scope workloads and the classification scheme.
**Verify:** Confirm the in-scope workloads and the financial data types with stakeholders; run
`FS-Purview-Discovery.ps1` for what exists today.
**Implement:** Define scope and the FS classification intent before authoring policies.

## 2.6 Pilot scope (users and, for endpoint DLP, devices)
**Description:** A Microsoft Entra security group `Purview - FS Pilot Users` for label/DLP/retention/
supervision piloting and — for endpoint DLP — devices onboarded to Microsoft Purview.
**Why:** Every policy is piloted before firm-wide rollout; DLP and supervision in particular must run
in audit/limited-pilot first.
**Verify:** Entra → **Groups** — `Purview - FS Pilot Users` exists; Purview → **Settings → Device
onboarding** shows pilot devices onboarded (endpoint DLP only).
**Implement:** Build the pilot group with `FS-Purview-Set-ScopeTargeting.ps1`; onboard pilot devices
via the Purview device-onboarding package.

## 2.7 Audit logging enabled
**Description:** Microsoft Purview audit (unified audit log) is on.
**Why:** DLP tuning, records evidence, supervision, and coverage reporting read audit/activity data.
**Verify:** Purview → **Audit** returns results; run `FS-Purview-Report.ps1`.
**Implement:** Turn on auditing in the Purview **Audit** solution; allow time for events to populate.

## 2.8 Change control — enforce, records lock, and supervision
**Description:** A documented change-control / rollback process for (a) switching any DLP policy from
audit to enforce, (b) declaring a **regulatory record** or applying **Preservation Lock**, and (c)
activating a communication-compliance policy.
**Why:** Enforce-mode DLP can block work; **Preservation Lock is effectively irreversible**;
supervision is HR/privacy-sensitive. Each needs a pilot gate, named approver, and rollback.
**Verify:** A change ticket exists per change with an approver, pilot scope, and rollback (revert DLP
to test; **note that a locked retention policy cannot be rolled back**; disable the supervision
policy).
**Implement:** Record the change, name the pilot scope, define the rollback, and get approval —
especially records/legal sign-off before any Preservation Lock.

---
## Checklist
- [ ] M365 + Purview licensing (E5 / E5 Compliance for auto-labeling, endpoint DLP, records, comms compliance) — `FS-Purview-Discovery.ps1`
- [ ] Least-privilege roles assigned; communication-compliance roles **separated** (Admin/Analyst/Investigator)
- [ ] FS label taxonomy defined (Public / Internal / Confidential-NPI / Restricted-MNPI)
- [ ] Records schedule + supervision scheme obtained from compliance/records/legal (periods/applicability = their determination)
- [ ] In-scope workloads + FS data types confirmed
- [ ] Pilot group `Purview - FS Pilot Users` created — `FS-Purview-Set-ScopeTargeting.ps1`
- [ ] Endpoint devices onboarded (endpoint DLP only)
- [ ] Purview audit logging enabled — `FS-Purview-Report.ps1`
- [ ] Change control + rollback for enforce / records-lock / supervision (records+legal sign-off before Preservation Lock)


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


# 3. Implementation Guide — Microsoft Purview for Financial Services

Follow these steps **in order**, in the **Microsoft Purview portal** (`https://purview.microsoft.com`).
Portal paths are current at authoring — the portal evolves, so **verify the path in your tenant**; if a
node is absent it is usually **licensing** (Requirement 2.1).

> **Model:** Design the FS label taxonomy → publish it → auto-label NPI in **simulation** → build DLP
> in **audit** and tune (the DLP audit gate) before enforcing → set retention/records and apply
> **Preservation Lock only after records/legal sign-off** → stand up communication compliance on a
> **limited pilot** — piloting each on `Purview - FS Pilot Users` before you expand. Pattern:
> Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand.

> **Determinations are deferred.** Retention periods, regulatory-record declarations, the supervision
> scheme, and any FINRA/SEC/GLBA applicability are **compliance/records/legal** decisions (Requirement
> 2.4). The steps below configure the mechanism; the owners supply the values.

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| Sensitivity labels | `Sensitivity Label - FS Public`, `Sensitivity Label - FS Internal`, `Sensitivity Label - FS Confidential (NPI/GLBA)`, `Sensitivity Label - FS Restricted (MNPI)` |
| Label policy | `Label Policy - FS Taxonomy - Pilot` |
| Auto-labeling policy | `Auto-Label - FS NPI (GLBA) - Simulation` |
| DLP policy | `DLP Policy - FS NPI and Financial - Test` (renamed to `... - Enforce` at the gate) |
| Retention labels | `Retention Label - FS Broker-Dealer Records (SEC 17a-4) - 6yr`, `Retention Label - FS Adviser Records (SEC 204-2) - 5yr` |
| Retention policy | `Retention Policy - FS Communications Supervision - 6 Year` |
| Communication-compliance policy | `Comm Compliance - FS Supervision (FINRA 3110) - Pilot` |
| Pilot group | `Purview - FS Pilot Users` |

## Step 1 — Design the FS label taxonomy (Assess/Design)
1. With the data owners and compliance, agree the labels and the protection each applies:
   - `Sensitivity Label - FS Public` — no protection; shareable externally (e.g. published disclosures).
   - `Sensitivity Label - FS Internal` — internal business data; no encryption.
   - `Sensitivity Label - FS Confidential (NPI/GLBA)` — encrypt; restrict to the organization; for
     customer nonpublic personal information (GLBA / Reg S-P).
   - `Sensitivity Label - FS Restricted (MNPI)` — encrypt; restrict to a **named group** (e.g. deal
     team / information-barrier segment); for material nonpublic information.
2. Record each label's meaning, protection, and who applies it (the taxonomy one-pager, Requirement 2.3).

## Step 2 — Create the sensitivity labels
1. Purview portal → **Information Protection → Sensitivity labels → Create a label**.
2. **Name and tooltip:** enter the label name (e.g. `Sensitivity Label - FS Confidential (NPI/GLBA)`)
   and a user-facing tooltip. **Next**.
3. **Scope:** select **Items** (files and emails). **Next**.
4. **Encryption:** **Configure encryption** for `FS Confidential (NPI/GLBA)` (permissions **All Users
   in <org>**) and `FS Restricted (MNPI)` (permissions a **named group**). Leave `FS Public` /
   `FS Internal` unencrypted. **Next**.
5. **Content marking:** add a header/footer/watermark if required (e.g. `CONFIDENTIAL — NPI`). **Next**.
6. **Auto-labeling for items:** leave off here (configured centrally in Step 4). **Next → Create**.
7. Repeat for each label **in sensitivity order** (`FS Public` → `FS Internal` → `FS Confidential
   (NPI/GLBA)` → `FS Restricted (MNPI)`). Label order sets priority.

## Step 3 — Publish the labels with a label policy
1. Purview portal → **Information Protection → Sensitivity labels → Label policies → Publish labels**.
2. **Choose labels to publish:** add all four. **Next**.
3. **Assign to users and groups:** add `Purview - FS Pilot Users` for the pilot. **Next**.
4. **Policy settings:** optionally require justification for downgrading a label and require a label
   for new items. **Next**.
5. **Default label:** optionally set `FS Internal` as default. **Next**.
6. **Name:** `Label Policy - FS Taxonomy - Pilot`. **Next → Submit**.

## Step 4 — Auto-label NPI in SIMULATION
1. Purview portal → **Information Protection → Auto-labeling → Create auto-labeling policy**.
2. **Choose the information to label:** pick the **U.S. Financial Data** / **U.S. Gramm-Leach-Bliley
   Act (GLBA)** template or **Custom** (verify template availability in your tenant). **Next**.
3. **Name:** `Auto-Label - FS NPI (GLBA) - Simulation`. **Next**.
4. **Locations:** select **Exchange email**, **SharePoint sites**, **OneDrive accounts** as needed;
   scope to pilot locations. **Next**.
5. **Rules:** define the condition (e.g. **U.S. Bank Account Number**, **ABA Routing Number**,
   **U.S. Social Security Number**, **Credit Card Number**) and set the label to apply to
   `Sensitivity Label - FS Confidential (NPI/GLBA)`. **Next**.
6. **Run the policy in simulation mode** — do **not** turn it on. **Next → Create**. Review simulation
   matches before turning it on.

## Step 5 — Build the DLP policy in AUDIT (test) mode
1. Purview portal → **Data Loss Prevention → Policies → Create policy**.
2. **Category / template:** choose **U.S. Gramm-Leach-Bliley Act (GLBA)** or **U.S. Financial Data**
   (or **Custom**). **Next**.
3. **Name:** `DLP Policy - FS NPI and Financial - Test`. **Next**.
4. **Locations:** enable **Exchange email**, **SharePoint sites**, **OneDrive accounts**, **Teams chat
   and channel messages**, and **Devices** (endpoint DLP) as licensed. Scope to `Purview - FS Pilot
   Users` where the location supports user scoping. **Next**.
5. **Rules:** match the financial sensitive-information types (e.g. **U.S. Bank Account Number**,
   **ABA Routing Number**, **SWIFT Code**, **U.S. Social Security Number**, **Credit Card Number**)
   and/or the label `Sensitivity Label - FS Confidential (NPI/GLBA)`. Set actions to **audit only**;
   enable **policy tips** for visibility but do **not** block. **Next**.
6. **Policy mode:** select **Run the policy in test mode** (with policy tips). **Next → Submit**. The
   policy now audits without blocking.

## Step 6 — Pilot and tune (the DLP audit gate)
1. Let the audit-mode policy run against `Purview - FS Pilot Users` for the agreed window.
2. Review matches in Purview → **Data Loss Prevention → Alerts** and **Activity explorer**; run
   `FS-Purview-Report.ps1` for a classification and DLP-event summary.
3. Tune the rules to remove false positives (raise confidence levels, require a minimum instance count,
   add exceptions).
4. **Gate:** only when the audit shows the policy matches real NPI/financial data and not routine work
   do you proceed to enforce (Step 7). If still noisy, keep tuning — do **not** enforce.

## Step 7 — Switch DLP to ENFORCE (after the gate)
1. Purview portal → **Data Loss Prevention → Policies →** open `DLP Policy - FS NPI and Financial -
   Test` → **Edit**.
2. Rename it `DLP Policy - FS NPI and Financial - Enforce` so the stage is visible.
3. **Rules:** change the action to **Block** (or **Block with override**) as the business requires;
   keep policy tips on. **Next**.
4. **Policy mode:** select **Turn the policy on**. **Next → Submit**. Enforcement applies to the pilot
   first; widen in Step 11.
5. **Rollback (if needed):** set the policy mode back to **Test mode** (audit) or turn the policy off.

## Step 8 — Create retention labels for FS books-and-records
1. Purview portal → **Data Lifecycle Management → Retention labels → Create a label**.
2. Create `Retention Label - FS Broker-Dealer Records (SEC 17a-4) - 6yr` and
   `Retention Label - FS Adviser Records (SEC 204-2) - 5yr` (period and applicability **as supplied by
   records/legal**, Requirement 2.4). **Next**.
3. **Retention settings:** **Retain items for** the agreed period, **Start of the retention period**
   based on when items were created/labeled, then the end action: **Delete**, **Retain only**, or —
   where the record must be immutable — **Mark items as a regulatory record** (records management).
   **Next → Create**.
   > **Regulatory record is effectively permanent for its retention period and cannot be un-marked.**
   > Only declare it where the records/legal owner confirms it is required.

## Step 9 — Create the retention/supervision policy (and Preservation Lock only after sign-off)
1. Purview portal → **Data Lifecycle Management → Retention policies → New retention policy**.
2. **Name:** `Retention Policy - FS Communications Supervision - 6 Year`. **Next**.
3. **Locations:** enable **Exchange mailboxes**, **SharePoint sites**, **OneDrive accounts**, and
   **Teams** as required by the record set. Scope to `Purview - FS Pilot Users` for the pilot. **Next**.
4. **Retention settings:** **Retain items for** the agreed period, then the agreed end action. **Next →
   Submit**. The policy starts **unlocked** and scoped to the pilot.
5. **Preservation Lock (immutability for SEC 17a-4(f) / FINRA 4511(c) / CFTC 1.31):** apply **only
   after** the records/legal owner signs off the schedule (Requirement 2.8), using
   `Set-RetentionCompliancePolicy -Identity "<name>" -RestrictiveRetention $true`.
   > **This is effectively irreversible** — once locked you cannot shorten the period, remove
   > locations, or disable the policy. There is **no rollback**. Do not lock during the pilot.
6. For records requiring reviewed disposition, configure **Records Management → File plan** and enable
   **disposition review** so deletions are reviewed, not automatic.

## Step 10 — Stand up communication compliance on a LIMITED pilot
1. Confirm the **role separation** from Requirement 2.2 (Admin / Analyst / Investigator held by
   different people) and privacy settings (**pseudonymization on**).
2. Purview portal → **Communication Compliance → Policies → Create policy** → choose a template such as
   **Monitor for regulatory compliance** (or **Detect money laundering / stock manipulation / gifts &
   entertainment** as the supervision scheme requires, Requirement 2.4). **Next**.
3. **Name:** `Comm Compliance - FS Supervision (FINRA 3110) - Pilot`.
4. **Users/scope:** scope to `Purview - FS Pilot Users` only for the pilot. Set the **review
   percentage** low to start. Apply the **lexicon/conditions** supplied by compliance. **Next → Submit**.
5. Route pseudonymized alerts to the **Analyst** role for triage; escalate to **Investigator** only per
   the firm's process. *Any case outcome is a compliance/HR/legal determination — the tool provides the
   evidence, not the decision.*

## Step 11 — Validate, then expand
1. Complete the Testing Guide against `Purview - FS Pilot Users`.
2. Run `FS-Purview-Validation.ps1` (labels published, DLP present, retention present, comms policy
   present) and `FS-Purview-Report.ps1` (classification + DLP-event coverage).
3. Widen scope: republish `Label Policy - FS Taxonomy - Pilot`, the DLP enforce policy, the retention
   policy, and the communication-compliance policy from `Purview - FS Pilot Users` to broader groups
   (or **All users / All locations**) once the pilot passes. Turn auto-labeling on (out of simulation)
   after its simulation is clean. Apply **Preservation Lock** only after records/legal sign-off.
4. Re-validate each expansion with `FS-Purview-Validation.ps1` and `FS-Purview-Report.ps1`.

---
### Order of operations
`FS taxonomy → labels → label policy → auto-label NPI (simulation) → DLP (audit) → audit gate → DLP (enforce) → retention labels/records → retention policy → (Preservation Lock after sign-off) → communication compliance (pilot) → validate → expand`


---


# 5. Testing Guide — Microsoft Purview for Financial Services

Run after publishing to `Purview - FS Pilot Users` (Implementation Step 3 onward), before the DLP
audit gate (Step 6), and again after each expansion. Tests validate the **mechanism and evidence** —
they do not judge regulatory sufficiency, which is the compliance/records/legal owners' call.

## Test 1 — FS labels published and visible
**Do:** In Outlook / Word (web or desktop) as a pilot user, open the **Sensitivity** button. Or run
`FS-Purview-Validation.ps1`.
**Expected:** All four labels appear (`Sensitivity Label - FS Public` through
`Sensitivity Label - FS Restricted (MNPI)`) via `Label Policy - FS Taxonomy - Pilot`.

## Test 2 — NPI/MNPI label protection applies
**Do:** Apply `Sensitivity Label - FS Confidential (NPI/GLBA)` to a test document and try to open it as
an out-of-scope external user; apply `Sensitivity Label - FS Restricted (MNPI)` and confirm only the
named group can open it.
**Expected:** The document is encrypted/marked; external/out-of-group users are denied per the label's
permissions.

## Test 3 — NPI auto-labeling simulation matches
**Do:** Purview → **Information Protection → Auto-labeling →** open `Auto-Label - FS NPI (GLBA) -
Simulation` → **Simulation**.
**Expected:** The simulation lists items matching the rule (e.g. files with bank-account / routing /
SSN data) and does **not** flag routine, non-sensitive content. It applies nothing while in simulation.

## Test 4 — DLP is auditing (before the gate)
**Do:** As a pilot user, email a test message containing fake bank-account/routing or SSN data to an
external address; check Purview → **Data Loss Prevention → Alerts** and **Activity explorer**. Or run
`FS-Purview-Report.ps1`.
**Expected:** `DLP Policy - FS NPI and Financial - Test` records the match (policy tip shown, no block)
— the audit gate has data to review.

## Test 5 — DLP enforces (after the gate)
**Do:** After Step 7, repeat Test 4 against `DLP Policy - FS NPI and Financial - Enforce`.
**Expected:** The action now blocks (or blocks-with-override) per the enforce rule; the event is logged.

## Test 6 — Retention label applied and honored
**Do:** Apply `Retention Label - FS Broker-Dealer Records (SEC 17a-4) - 6yr` to a test item and attempt
to delete it.
**Expected:** The item is retained for the period (or declared a **regulatory record** and blocked from
deletion / un-marking) per the label.

## Test 7 — Retention policy scoped (and lock state correct)
**Do:** Confirm `Retention Policy - FS Communications Supervision - 6 Year` is applied to the pilot
locations (Purview → **Data Lifecycle Management → Retention policies →** open the policy). Or run
`FS-Purview-Validation.ps1`.
**Expected:** The policy shows **On** and scoped to the pilot mailboxes/sites/OneDrive/Teams. During
the pilot it should be **unlocked** (Preservation Lock is applied only after records/legal sign-off,
Step 9.5).

## Test 8 — Communication-compliance policy live with role separation
**Do:** Confirm `Comm Compliance - FS Supervision (FINRA 3110) - Pilot` exists and is scoped to
`Purview - FS Pilot Users`; confirm the Admin/Analyst/Investigator roles are held by different people
and that alerts are pseudonymized. Generate a benign test communication matching a lexicon term as a
pilot user.
**Expected:** A pseudonymized alert reaches the **Analyst** role for triage; the Admin cannot also act
as Investigator. *No case outcome is judged here — evidence only.*

## Test 9 — Coverage report
**Do:** Run `FS-Purview-Report.ps1`.
**Expected:** A summary of classification (labeled items), DLP events, and DLP service coverage across
the enabled workloads, so coverage and gaps are visible.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4, 6–8 pass on `Purview - FS Pilot Users`; the DLP audit shows real matches and acceptable noise; comms roles are separated |
| **Audit gate** | DLP audit reviewed and tuned; only then is Test 5 (enforce) run |
| **Records/legal sign-off** | Preservation Lock (Step 9.5) applied **only after** records/legal sign-off — never during the pilot |
| **Expand pass** | Tests 1, 4/5, 7, 8, 9 pass after widening scope beyond the pilot |


---


# 6. Troubleshooting Guide — Microsoft Purview for Financial Services

Use `FS-Purview-Discovery.ps1` for the tenant's current config, `FS-Purview-Validation.ps1` to confirm
the named objects are in place, `FS-Purview-Report.ps1` for classification and DLP-event coverage, and
`FS-Purview-Remediation.ps1` (default `-WhatIf`) for safe fixes. Remediation **never** enforces DLP and
**never** applies Preservation Lock.

## A. FS sensitivity labels not appearing for users
| Symptom | Cause | Remediation |
|---|---|---|
| No Sensitivity button / labels missing | Label policy not published to the user, or publish still propagating | Confirm the user is in `Purview - FS Pilot Users`; verify `Label Policy - FS Taxonomy - Pilot` targets them; allow up to 24 hours to propagate |
| Labels appear but no encryption on NPI/MNPI | Label scoped to items but encryption not configured | Edit the label (`Sensitivity Label - FS Confidential (NPI/GLBA)` / `... FS Restricted (MNPI)`), enable **Configure encryption**, republish |
| Wrong label order/priority | Labels created out of sensitivity order | Reorder `FS Public` → `FS Internal` → `FS Confidential (NPI/GLBA)` → `FS Restricted (MNPI)`; order sets priority |

## B. NPI auto-labeling not labeling
- Confirm `Auto-Label - FS NPI (GLBA) - Simulation` is turned on (not left in simulation). Simulation
  reports matches but applies nothing.
- Auto-labeling for SharePoint/OneDrive at rest requires the higher plan; verify licensing with
  `FS-Purview-Discovery.ps1`.
- Check the rule's financial sensitive-information types and confidence — too high a confidence or
  instance count can suppress matches on bank-account / routing / SSN data.

## C. DLP is too noisy (false positives)
- Expected before the audit gate — keep `DLP Policy - FS NPI and Financial - Test` in test/audit and
  tune. Raise match confidence, require a higher instance count, and add exceptions (e.g. known
  internal financial systems).
- Review matches in Purview → **Data Loss Prevention → Alerts** and **Activity explorer**; run
  `FS-Purview-Report.ps1`.
- Do **not** switch to enforce until the noise is acceptable — a blocked-work storm on advisers/traders
  undermines the program.

## D. DLP not blocking after enforce
| Symptom | Cause | Remediation |
|---|---|---|
| Enforce policy does not block | Policy left in test mode, or scope excludes the user | Confirm `DLP Policy - FS NPI and Financial - Enforce` mode is **Turn the policy on**; confirm the user/location is in scope |
| Endpoint (device) rules never fire | Device not onboarded to Purview | Onboard the device (Purview → **Settings → Device onboarding**); verify with `FS-Purview-Discovery.ps1` |
| Teams/SharePoint not covered | Location not enabled on the policy | Edit the policy and enable the missing location |

## E. Retention / records issues
- **Nothing retained:** confirm `Retention Policy - FS Communications Supervision - 6 Year` shows **On**
  and is scoped to the correct locations; run `FS-Purview-Validation.ps1`.
- **Cannot shorten/disable/unscope a retention policy:** it is **locked** with Preservation Lock — this
  is **irreversible by design**. There is no rollback; the policy stays as configured for its life.
  This is expected once records/legal have signed off and you locked it (Step 9.5). Confirm the lock
  state with `FS-Purview-Discovery.ps1`.
- **Cannot un-mark a regulatory record:** a retention label marked as a **regulatory record** cannot be
  removed for its retention period — this is intended for SEC 17a-4-style immutability. Verify it was
  only applied where records/legal required it.
- **Records deleted unreviewed:** enable **disposition review** on the file plan so items are reviewed
  before deletion rather than auto-deleted.

## F. Communication compliance (supervision) issues
| Symptom | Cause | Remediation |
|---|---|---|
| Communication Compliance node/cmdlet absent | Licensing (E5 / E5 Compliance) or missing role | Verify licensing; add the operator to the correct **Communication Compliance** role group (see role separation, Requirement 2.2) |
| No alerts generated | Policy scope too narrow, review percentage too low, or lexicon/conditions not matching | Confirm `Comm Compliance - FS Supervision (FINRA 3110) - Pilot` is scoped to `Purview - FS Pilot Users`, raise the review percentage, and confirm the compliance-supplied lexicon |
| One person can configure, triage, and investigate | Roles not separated | Separate the **Admin / Analyst / Investigator** roles across different people; this is a privacy/role-separation requirement, not optional |
| Reviewer sees real identities during triage | Pseudonymization off | Turn on pseudonymization in **Communication Compliance → Settings** |

*Any supervision case **outcome** is a compliance/HR/legal determination — the tool provides the
evidence, not the decision.*

## G. Licensing / feature missing
- Auto-labeling at rest, endpoint DLP, records management, communication compliance, and Audit
  (Premium) require Microsoft 365 E5 or the E5 Compliance add-on. If a feature is absent from the
  portal, verify the plan with `FS-Purview-Discovery.ps1` and Requirement 2.1, and **verify your
  tenant** — the portal evolves.

## H. Diagnostics quick reference
```powershell
# Security & Compliance PowerShell (Exchange Online Management module)
Connect-IPPSSession
Get-Label | Select-Object DisplayName, Priority, ContentType
Get-LabelPolicy | Select-Object Name, Enabled
Get-DlpCompliancePolicy | Select-Object Name, Mode, Enabled
Get-RetentionCompliancePolicy | Select-Object Name, Enabled, Mode, RestrictiveRetention  # RestrictiveRetention = Preservation Lock
Get-ComplianceTag | Select-Object Name, RetentionDuration, RetentionAction
# Communication compliance (role-gated):
Get-SupervisoryReviewPolicyV2 | Select-Object Name, Enabled
```
For classification and DLP events, use the Purview **Activity explorer** and the unified audit log
(Requirement 2.7).

## I. When to escalate
If a policy is published and propagated, the user/location is in scope, licensing is correct, and the
capability still does not behave after 24 hours and an `FS-Purview-Remediation.ps1` run, collect the
output of `FS-Purview-Discovery.ps1` and `FS-Purview-Validation.ps1` and open a Microsoft support case.
For any **records-retention, regulatory-record, supervision, or FINRA/SEC/GLBA applicability**
question, escalate to the firm's **compliance, records, privacy, or legal** owners — those are
determinations, not support issues.


---


# 7. Best Practices — Microsoft Purview for Financial Services

- **Defer the determinations, own the mechanism.** Configure the labels, DLP, retention/records, and
  supervision precisely — but take the record set, retention periods, regulatory-record declarations,
  and the supervision scheme from **compliance, records, privacy, and legal**. Capture the source for
  each so the configuration is defensible in an exam.
- **Keep the taxonomy small and FS-meaningful.** Three to five labels people can reason about beats a
  dozen nobody uses. Make `FS Confidential (NPI/GLBA)` and `FS Restricted (MNPI)` distinct and give
  each a plain tooltip so users know NPI from MNPI.
- **Simulate auto-labeling for NPI.** Always run `Auto-Label - FS NPI (GLBA) - Simulation` in
  simulation and review matches before turning it on — it labels customer data at scale and mistakes
  are visible to users.
- **Audit DLP before you enforce.** The single most important practice: run every DLP policy in
  test/audit, review matches, tune out false positives, then enforce. A blocked-work storm on
  advisers/traders is the fastest way to lose trust in DLP.
- **Tune with confidence levels and instance counts.** Reduce false positives on financial
  sensitive-info types (bank account, routing, SSN, card) by raising match confidence and requiring a
  minimum instance count rather than a single hit.
- **Treat Preservation Lock as one-way.** A locked retention policy **cannot** be shortened, unscoped,
  or disabled — it is the immutability mechanism Microsoft positions for SEC 17a-4(f) / FINRA 4511(c) /
  CFTC 1.31, but there is **no rollback**. Lock **only** after records/legal sign-off, never during the
  pilot, and never to "tidy up."
- **Separate the communication-compliance roles.** Admin (configure), Analyst (triage pseudonymized
  alerts), Investigator (resolve) must be **different people** — privacy-by-design and role separation
  protect both employees and the firm. Keep pseudonymization on and start the review percentage low.
- **Name every object by purpose and stage.** Use `<Purpose> - <Scope> - <Stage>` (e.g. rename
  `DLP Policy - FS NPI and Financial - Test` to `... - Enforce` at the gate) so the portal shows where
  each policy sits in its lifecycle.
- **Report coverage regularly.** Track labeled-item, DLP-event, and DLP service coverage with
  `FS-Purview-Report.ps1` and chase gaps (unlabeled NPI locations, workloads with no DLP, mailboxes
  outside the retention policy).
- **Verify licensing before you promise a capability.** Auto-labeling at rest, endpoint DLP, records
  management, communication compliance, and Audit (Premium) are E5 / E5 Compliance features and the
  portal evolves — confirm with `FS-Purview-Discovery.ps1` and **verify your tenant** rather than
  assuming a node exists.
- **Document the objects and the rollback.** Record the label taxonomy, policy names, scopes, and the
  rollback (revert DLP to audit; disable the unlocked retention policy; disable the supervision policy)
  — and note explicitly that a **locked** retention policy has no rollback.


---


# 8. Deliverables Summary — Microsoft Purview for Financial Services

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The FS Purview program — labels, DLP, retention/records, communication compliance — aligned to FINRA/SEC/GLBA; benefits, limitations |
| 2. Requirements Guide | Every FS-specific prerequisite with Verify / Implement-if-missing (licensing, separated roles, records schedule, pilot) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal steps (labels, auto-label NPI simulation, DLP audit-then-enforce, retention/records + Preservation Lock after sign-off, communication compliance pilot) |
| 5. Testing Guide | Validation procedures with pass/fail gates, the DLP audit gate, and records/legal sign-off gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `FS-Purview-Discovery.ps1` | Reports the tenant's sensitivity labels, DLP policies, retention labels/policies (with lock state), and communication-compliance policies; flags endpoint onboarding and licensing signals (read-only) |
| `FS-Purview-Validation.ps1` | Confirms the expected FS labels are published, the DLP policy exists (and its mode), the retention policy exists/enabled, and the communication-compliance policy exists |
| `FS-Purview-Report.ps1` | Classification + DLP-event coverage summary across the enabled services (read-only) |
| `FS-Purview-Remediation.ps1` | Safe remediation of common gaps (default `-WhatIf`); enables a published-but-off label/retention policy only — never enforces DLP, never applies Preservation Lock |
| `FS-Purview-Set-ScopeTargeting.ps1` | Builds/updates the `Purview - FS Pilot Users` scope Entra group (Graph; `-WhatIf` supported) |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate/test) →
  Validate → Expand (enforce)**, with a DLP audit gate before enforce, a records/legal sign-off gate
  before Preservation Lock, and a documented rollback.

## Boundary
This package delivers the **technical configuration and evidence** for a Financial Services Purview
program. The **regulatory, records-retention, supervision, and legal determinations** (record set,
retention periods, regulatory-record declarations, supervision scheme, FINRA/SEC/GLBA applicability)
are deferred to the firm's compliance, records, privacy, and legal functions.

## Outcome
A Financial Services-tailored Microsoft Purview program — an FS label taxonomy protecting NPI and MNPI,
DLP tuned in audit before it enforces, retention/records aligned to the firm's schedule with an
immutability mechanism for SEC/FINRA/CFTC electronic-records rules, and a supervision program with
role separation — configured, piloted, validated, and defensible.
