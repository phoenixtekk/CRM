# Microsoft Purview for Education

> **Version 1.0.0** · Category: Purview · Solution code: INDEDU

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview for Education (FERPA)

Schools, districts, colleges, and universities hold some of the most sensitive personal data there
is — **student education records** protected under **FERPA** (the U.S. Family Educational Rights and
Privacy Act), plus staff PII, health and counseling notes, financial-aid data, and research. A
generic, out-of-the-box Purview configuration does not reflect an education institution's specific
data-protection obligations: it leaves a **compliance gap** and a **data-risk exposure**. The fix is
a Purview program **tailored to education** — sensitivity labels, Data Loss Prevention (DLP),
retention/records, and compliance posture aligned to **FERPA** and the way education data actually
flows.

This solution delivers that end to end in **Microsoft Purview**: an education-tailored label taxonomy,
FERPA-oriented DLP, a student-record retention approach, and a Compliance Manager posture —
**configured, piloted in simulation/test where the capability supports it, validated against pass/fail
gates, and made operable**. It is an **industry bundle**: it composes the institution's program and
references the granular Purview capability products (label taxonomy, DLP packs, retention/records,
Compliance Manager) so the pieces fit together for an education tenant rather than being wired up
in isolation.

## What you get
- A plain-language **Solution Overview** of the education-tailored Purview program and the
  **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce)** model.
- A **Requirements Guide** with **verify / implement-if-missing** for every prerequisite —
  compliance licensing (E5 / E5 Compliance where features require it), least-privilege Purview roles,
  in-scope education workloads and data, and the compliance/records/privacy/legal stakeholders. The
  six category-wide Purview requirements are **referenced, not repeated**.
- An **Implementation Guide** of precise, ordered **Purview portal + Security & Compliance PowerShell
  + Graph** steps: publish the education label set, stand up FERPA-oriented DLP in **Test/simulation**,
  configure student-record retention, and set the Compliance Manager posture — each label/policy/object
  **named**, **piloted in simulation first**, with pass/fail gates and rollback.
- **Five PowerShell scripts** — Discovery, Configuration/Remediation (simulation / `-WhatIf` first),
  Validation, Reporting, and a scope/health helper — via **Security & Compliance PowerShell**
  (`Connect-IPPSSession`) and/or **Microsoft Graph**, read-only or `-WhatIf` by default, **no
  credentials in code**.
- **Testing** and **Troubleshooting** guides and a **Best Practices** section for a confident rollout.

## What this delivers
An education institution whose Purview program **fits FERPA and the education data estate** — student
records labeled and protected, DLP catching education-record leaks (proven in simulation before it
blocks anyone), retention aligned to the records schedule, and a defensible, evidenced compliance
posture.

## The deployment model
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)** — build the
labels, DLP, and retention; prove them in simulation/test on a pilot scope; validate against
pass/fail gates; then enforce and expand in waves.

## An honest note
Microsoft Purview capabilities are **heavily licensing-/plan-dependent** (many require **Microsoft 365
E5** or the **E5 Compliance** add-on; some are in preview) and the portal is **actively evolving** —
this package **cites Microsoft's public documentation or flags "verify your licensing/tenant"** rather
than asserting availability or inventing portal paths. **Regulatory, records-retention, and legal
determinations** — FERPA applicability, the records schedule, retention periods, legal holds — are
**deferred to the institution's compliance, records, privacy, and legal functions**. This solution
provides the technical configuration method and the evidence, **not** the determination. High-impact
policies (DLP, labels, retention) are always **piloted in simulation/test first**.

## Outcome
A Microsoft Purview program **tailored to education and aligned to FERPA** — configured, piloted,
validated, and defensible — so the capability is in place and evidenced, not left as a generic
default.


---


# 1. Solution Overview — Microsoft Purview for Education (FERPA)

## What this solution is
This solution stands up a **Microsoft Purview program tailored to education** — one aligned to the way
schools, districts, and higher-education institutions handle **student education records** under
**FERPA**, plus the staff PII, health/counseling, financial-aid, and research data that live alongside
them. Instead of a generic, one-size-fits-all Purview setup, it configures the four core information-
protection and governance capabilities — **sensitivity labels, Data Loss Prevention (DLP),
data-lifecycle/retention & records, and the Compliance Manager posture** — with an **education-fit
taxonomy and rule set**, piloted in **simulation/test** before anything enforces.

It is an **industry bundle**. Rather than treating each capability as an isolated project, it composes
the institution's end-to-end program and **references the granular Purview capability products** — the
sensitivity-label taxonomy, the FERPA/DLP pack, retention & records management, and Compliance Manager —
so the pieces are designed to **fit an education tenant together**: labels feed DLP and retention; DLP
protects the labeled student-record data; retention satisfies the records schedule; Compliance Manager
scores the whole posture.

It is authored for a Microsoft 365 administrator or compliance operator with no prior Purview
deep-dive experience: exact **Purview portal** navigation and **Security & Compliance PowerShell /
Graph** automation, with every label, policy, and object named.

## Why "tailored to education" matters
FERPA governs **education records** — records directly related to a student and maintained by the
institution (or a party acting for it). Purview has no single built-in "FERPA" switch: protecting
education records well means **deciding what an education record is in your tenant**, **classifying it**
(labels + sensitive information types), **preventing its inappropriate sharing** (DLP), **retaining and
disposing of it per the records schedule** (retention/records), and **evidencing the whole thing**
(Compliance Manager + audit). A generic label set and default DLP templates do none of this in
education terms — hence an education-tailored program.

> **What is *not* in this package (deferred to governance).** Whether FERPA applies to a given record,
> the **retention period** for student records, when a **legal hold** is placed, and the institution's
> **records file plan** are **compliance/records/privacy/legal determinations** — not technical
> defaults. This solution provides the **method and the evidence**; the institution's governance
> functions provide the **determination**. Label names, retention periods, and DLP thresholds shown
> here are **illustrative placeholders** to be confirmed with those owners.

## The four capabilities, education-fit
- **Sensitivity labels (education taxonomy).** A small, human-readable label set — e.g.
  `EDU - Public`, `EDU - Internal`, `EDU - Student Record (FERPA)`, `EDU - Highly Confidential` —
  published to staff (and, where appropriate, students) so education records can be marked and
  protected (encryption/marking) consistently. Container labels can protect Teams/SharePoint sites
  used for student data. (References the label-taxonomy granular product.)
- **Data Loss Prevention (FERPA-oriented).** DLP policies that detect **education-record** content
  (student identifiers + names, and the sensitive information types the institution defines) across
  **Exchange, SharePoint, OneDrive, Teams, and endpoints**, and restrict inappropriate sharing —
  **started in Test/simulation mode** so you see what *would* be caught before it blocks anyone.
  (References the FERPA/DLP-pack granular product.)
- **Retention & records (student records).** Retention labels and policies that keep and then dispose
  of student education records per the institution's **records schedule**, with disposition review
  where records management requires it. The **schedule and periods are the records function's
  determination**; Purview enforces them. (References the retention & records granular product.)
- **Compliance posture (Compliance Manager).** A Compliance Manager assessment (e.g. a **FERPA / data-
  protection** template where your licensing includes premium assessments) that scores improvement
  actions and produces evidence — turning the program into a **defensible, measured** posture.
  (References the Compliance Manager granular product.)

## How it works in Microsoft Purview
- Everything is configured in the **Microsoft Purview portal** (`purview.microsoft.com`) and, where the
  M365 admin center governs licensing/roles, there. **Automation** is **Security & Compliance
  PowerShell** (`Connect-IPPSSession`, via the ExchangeOnlineManagement module) and **Microsoft Graph**.
- **Sensitivity labels** are created and **published** via label policies to a **pilot scope**; **DLP**
  policies are created in **Test mode / simulation** and only later set to enforce; **retention** is
  applied via retention labels/policies (and label policies to publish them); **Compliance Manager**
  runs an assessment and tracks improvement actions.
- **Simulation/test first is mandatory.** Auto-labeling supports **simulation**; DLP supports **Test
  (with or without notifications)** before **Enforce**. High-impact changes are never turned straight
  on — they run in simulation/test on a pilot scope, are validated, then expanded to enforce.

## What is authored exactly vs deferred
- **Exact navigation and cmdlets are given** for the **Purview portal**, **Security & Compliance
  PowerShell**, and **Graph** — from Microsoft's public documentation.
- **Licensing/plan dependence is flagged throughout.** Advanced DLP, auto-labeling with simulation,
  premium Compliance Manager assessments, and records management generally require **E5 / E5
  Compliance** — where a capability is plan-gated or in preview, this package says **"verify your
  licensing/tenant"** rather than asserting it.
- **Regulatory/records/legal determinations are deferred** — FERPA applicability, retention periods,
  file plans, and legal holds are the institution's governance calls.
- **Sensitive information types for education records are institution-specific.** There is no universal
  built-in "FERPA" SIT; education-record detection is typically a **combination** of built-in SITs
  (names, U.S. SSN, etc.) plus a **custom SIT** for the institution's **student ID** format — confirm
  and build these with your data owners.

## Benefits
- **Fits FERPA and the education estate** — labels, DLP, and retention designed for student records,
  not a generic default.
- **Safe by construction** — DLP and auto-labeling run in **simulation/test** on a pilot before they
  ever block or relabel.
- **Composed, not piecemeal** — an industry bundle that makes the granular capabilities fit together.
- **Defensible** — Compliance Manager + audit produce the evidence that the program exists and works.
- **Operable + reversible** — every policy is named, validated against pass/fail gates, and has a
  documented rollback.

## Limitations (be honest with buyers)
- **Licensing-gated.** Several capabilities (advanced DLP, auto-labeling simulation, premium Compliance
  Manager assessments, records management) require **E5 / E5 Compliance** — **verify your
  licensing/tenant**; the package flags this at each step.
- **Determinations are not included.** FERPA applicability, retention periods, file plans, and legal
  holds are **deferred** to compliance/records/privacy/legal — this is a technical implementation, not
  legal advice.
- **Education-record detection needs your inputs.** The custom student-ID SIT and the education-record
  DLP conditions must be built from **your** identifiers and data — placeholders are provided to be
  confirmed.
- **The portal evolves.** Purview paths change; where a path is version-dependent the package flags
  **"verify against current Microsoft guidance / your tenant."**

## The standard deployment model
> **Assess** the education data estate and obligations → **Design** the label/DLP/retention/posture →
> **Configure** the labels, DLP (Test), retention, and Compliance Manager → **Pilot in
> simulation/test** on a pilot scope → **Validate** against pass/fail gates → **Expand (enforce)** in
> waves. Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand**, with explicit
> pass/fail gates and a documented rollback for every enforcing change.


---


# 2. Requirements Guide — Microsoft Purview for Education (FERPA)

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** The six category-wide Purview prerequisites (compliance
licensing, least-privilege Purview roles + portal access, Security & Compliance PowerShell + Graph
toolchain, in-scope data sources/classification intent, compliance/records/privacy/legal stakeholders,
and a pilot scope + change control) are in `global-requirements-purview.md` — confirm those **first**;
this guide adds the **education/FERPA-specific** items and does not duplicate the six.

> **Object names used throughout (use verbatim; names/periods are placeholders to confirm with your
> governance owners):**
> sensitivity labels `EDU - Public`, `EDU - Internal`, `EDU - Student Record (FERPA)`,
> `EDU - Highly Confidential`; label policy `EDU - Label Policy - Pilot` (and `- Prod`);
> DLP policy `EDU - FERPA Student Records - DLP - Pilot` (created in **Test/simulation** mode);
> custom sensitive information type `EDU - Student ID`; retention label
> `EDU - Student Education Record`; retention/label policy `EDU - Retention - Student Records - Pilot`;
> Compliance Manager assessment `EDU - FERPA Posture`.

## 2.1 Compliance licensing sufficient for the education capabilities (category G1)
**Description:** The tenant has the **compliance licensing** each capability needs — **E3** for baseline
labeling/DLP, **E5 / E5 Compliance** for advanced DLP, **auto-labeling with simulation**, records
management, and **premium Compliance Manager assessments** (some features are preview).
**Why required:** Most of the education program's higher-value pieces are **plan-gated**; the feature
will not be visible without the right plan.
**How to verify:** M365 admin center → **Billing → Licenses** confirms E5 / E5 Compliance; the feature
is visible in the Purview portal. Run **`EDU-Scope-Health.ps1`** (reports which capabilities the
signed-in tenant exposes). **Verify your licensing/tenant** for any preview capability.
**How to implement if missing:** Assign/purchase the required licensing before starting the affected
step; baseline labeling/DLP can proceed on E3 while advanced pieces wait for E5.

## 2.2 Least-privilege Purview roles for the education operators (category G2)
**Description:** The operators hold the **least-privilege Purview role groups** the work needs —
**Information Protection** (labels), **Compliance Administrator / Compliance Data Administrator** (DLP),
**Records Management** (retention/records), **Compliance Manager** roles, and **Audit** roles — with
Global Administrator only where genuinely required.
**Why required:** Purview uses fine-grained role groups; each configuration area requires the matching
role group membership.
**How to verify:** Purview portal → **Settings → Roles & scopes → Permissions**; confirm membership.
Run **`EDU-Scope-Health.ps1`** (reports role-group membership for the signed-in admin where readable).
**How to implement if missing:** Assign the least-privilege role group under change control; avoid
Global Admin for day-to-day label/DLP/retention work.

## 2.3 In-scope education workloads and the education-record data map (category G4)
**Description:** The **workloads in scope** — Exchange Online, SharePoint Online, OneDrive, Teams, and
**endpoints/devices** (for endpoint DLP) — and a clear statement of **what constitutes an education
record** in your tenant and **where it lives**.
**Why required:** Labels, DLP, and retention all key off the in-scope workloads and the education-record
definition; you cannot target what you have not scoped.
**How to verify:** Confirm the in-scope workloads and the education-record locations with stakeholders;
for endpoint DLP, devices are **onboarded** to Purview (Settings → Endpoint DLP / Defender onboarding).
**How to implement if missing:** Define scope and the education-record data map before authoring
policies; onboard devices before relying on endpoint DLP.

## 2.4 A custom sensitive information type for the institution's student ID
**Description:** A **custom SIT** `EDU - Student ID` matching your **student-identifier format**
(regex/keywords), because there is **no universal built-in "FERPA" or "student record" SIT** — education-
record detection is a **combination** of built-in SITs (names, U.S. SSN, etc.) plus your student ID.
**Why required:** FERPA-oriented DLP and auto-labeling need to recognize education-record content;
your student ID is the most reliable education-specific signal.
**How to verify:** Purview → **Data classification → Sensitive info types** lists `EDU - Student ID`
and test-matches sample values; run **`EDU-Discovery.ps1`** (lists custom SITs).
**How to implement if missing:** Build the custom SIT (Implementation Step 3) from your student-ID
pattern with your data owners; validate match/false-positive rate before using it in policy.

## 2.5 The education sensitivity-label taxonomy is agreed
**Description:** An agreed, small **label taxonomy** for education — `EDU - Public`, `EDU - Internal`,
`EDU - Student Record (FERPA)`, `EDU - Highly Confidential` — with the **protection** each carries
(encryption, marking, container protection) decided with information-protection and privacy owners.
**Why required:** Labels are the backbone the DLP and retention design hangs off; publishing a taxonomy
staff don't understand causes mislabeling.
**How to verify:** The taxonomy + protection intent is documented and approved; run **`EDU-Discovery.ps1`**
to see any labels already present.
**How to implement if missing:** Agree the taxonomy with the information-protection/privacy owners
(references the label-taxonomy granular product) before publishing.

## 2.6 DLP simulation/Test mode available and to be used first (category G6)
**Description:** DLP policies will be created in **Test mode** (with or without policy tips) and
auto-labeling in **simulation**, on a **pilot scope**, **before** any enforcement — confirm the tenant
supports simulation for the capabilities you'll use.
**Why required:** DLP and labeling are **high-impact**; enforcing untested rules blocks legitimate
education work and generates support load. Simulation/Test surfaces what *would* happen safely.
**How to verify:** In the Purview DLP/auto-labeling create flow the **Test / simulation** option is
present; **verify your licensing/tenant** (auto-labeling simulation requires E5).
**How to implement if missing:** If simulation isn't available for a capability, scope the pilot very
narrowly and use monitor-only settings; do not enforce tenant-wide without a pilot.

## 2.7 Records schedule + retention determinations from the records/legal function (category G5)
**Description:** The **records schedule** for student education records — **retention periods**,
**disposition** rules, and any **legal-hold** requirements — provided by the **records-management,
privacy, and legal** stakeholders.
**Why required:** Purview **enforces** retention; it does **not** decide it. The periods and disposition
rules are a **records/legal determination**, not a technical default.
**How to verify:** A documented records schedule with named approvers exists; the retention label
`EDU - Student Education Record` will encode the approved period.
**How to implement if missing:** Obtain the schedule and named approvers before configuring retention;
do not invent retention periods.

## 2.8 Audit (Standard/Premium) enabled for evidence
**Description:** **Purview Audit** is **on** so label, DLP, and retention activity is logged — the
evidence that the program operates (Audit **Premium** adds longer retention and richer events under
E5).
**Why required:** A defensible education-compliance posture needs an **audit trail**; Compliance Manager
and any FERPA inquiry rely on it.
**How to verify:** Purview → **Audit** shows the log **On**; run **`EDU-Discovery.ps1`** (reports audit
config state where readable).
**How to implement if missing:** Turn on Audit (Standard is enabled by default in most tenants; confirm)
and confirm Premium retention if your licensing includes it.

## 2.9 Compliance Manager access + an education assessment template
**Description:** Access to **Compliance Manager** and an **education/FERPA (or data-protection)
assessment template** — premium templates require **E5 Compliance**; the built-in **Data Protection
Baseline** is available more broadly.
**Why required:** Compliance Manager turns the program into a **scored, evidenced posture** with
improvement actions.
**How to verify:** Purview → **Compliance Manager → Assessments**; the desired template is available
(**verify your licensing/tenant** for premium templates).
**How to implement if missing:** If the premium FERPA template isn't licensed, start from the **Data
Protection Baseline** and map education controls to it; add the premium assessment when licensed.

## 2.10 Pilot scope + change control for enforcing changes (category G6)
**Description:** A named **pilot scope** (a group of users/sites for label publishing and DLP Test) and
a **change-control** window before any DLP **Enforce**, label **mandatory** publishing, or retention
**apply** goes tenant-wide.
**Why required:** Every enforcing change is high-impact in an education tenant (blocking staff/students,
relabeling, applying retention). The pilot + change control protect production.
**How to verify:** A named pilot user/site group and an approval window exist.
**How to implement if missing:** Define the pilot group and agree change control before enforcing.

---
## Checklist
- [ ] Compliance licensing sufficient (E3 baseline / E5 for advanced) (2.1 / category G1)
- [ ] Least-privilege Purview role groups on the operators (2.2 / category G2)
- [ ] In-scope education workloads + education-record data map; devices onboarded for endpoint DLP (2.3 / G4)
- [ ] Custom SIT `EDU - Student ID` built and validated (2.4)
- [ ] Education label taxonomy agreed with protection intent (2.5)
- [ ] DLP Test/simulation available and to be used first (2.6 / G6)
- [ ] Records schedule + retention periods + legal-hold reqs from records/legal (2.7 / G5)
- [ ] Purview Audit enabled (Premium where licensed) (2.8)
- [ ] Compliance Manager access + education/FERPA (or baseline) assessment template (2.9)
- [ ] Pilot scope + change-control window agreed (2.10 / G6)


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


# 3. Implementation Guide — Microsoft Purview for Education (FERPA)

Follow these steps **in order**. **Purview portal** navigation and **Security & Compliance PowerShell /
Graph** cmdlets are given from Microsoft's public documentation. Where a capability is **plan-gated or
in preview**, the step flags **"verify your licensing/tenant."** **Regulatory/records/legal
determinations** (FERPA applicability, retention periods, file plans, legal holds) are the institution's
governance calls — this guide configures the **method**, not the determination.

Consoles used:
- **Microsoft Purview portal** — `https://purview.microsoft.com`
- **Microsoft 365 admin center** — `https://admin.microsoft.com` (licensing/roles)
- **Security & Compliance PowerShell** — `Connect-IPPSSession` (ExchangeOnlineManagement module)
- **Microsoft Graph** — reporting/read helpers

> **Model:** Configure labels, DLP (**Test/simulation**), retention, and Compliance Manager; **pilot in
> simulation/test** on the pilot scope; validate against pass/fail gates; then **enforce and expand** in
> waves. **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**

> **Artifact names (use verbatim; names/periods are placeholders to confirm with governance owners):**
> labels `EDU - Public` / `EDU - Internal` / `EDU - Student Record (FERPA)` / `EDU - Highly
> Confidential`; label policy `EDU - Label Policy - Pilot`; custom SIT `EDU - Student ID`; DLP policy
> `EDU - FERPA Student Records - DLP - Pilot` (**Test** mode); retention label `EDU - Student Education
> Record`; retention/label policy `EDU - Retention - Student Records - Pilot`; Compliance Manager
> assessment `EDU - FERPA Posture`.

> **Risk + rollback (read first):** Labels, DLP, and retention are **high-impact**. **Nothing enforces
> in this guide until validated.** DLP is created in **Test** mode; auto-labeling runs in **simulation**;
> labels publish to a **pilot scope** first; retention is applied only after the records owner confirms
> the schedule. **Rollback:** a DLP policy in **Test** blocks no one — to revert, set it back to Test or
> **disable/delete** it; to unpublish labels, **remove the label policy** (or the pilot group from it) —
> the labels remain but stop being offered; auto-labeling **simulation** applies nothing until you
> turn it on. **Retention, once applied, preserves content and is harder to reverse — do not apply
> retention until the records owner has signed off the period** (a retention *label* can be unpublished,
> but content already retained stays retained for the period). Pilot everything on a **small** scope
> first.

---

## Phase 1 — Assess and prepare (no changes)

### Step 1 — Baseline the tenant and confirm licensing/roles
1. Run **`EDU-Scope-Health.ps1`** — it reports the compliance licensing the tenant exposes, the
   operator's Purview role-group membership (where readable), and the in-scope workloads, and flags
   gaps against the Requirements Guide. **Verify your licensing/tenant** for any preview capability.
2. Run **`EDU-Discovery.ps1`** — read-only inventory of existing sensitivity labels, label policies,
   DLP policies (and their mode), retention labels/policies, custom SITs, and audit state, so you build
   **on** the current tenant rather than duplicating.
3. Confirm the education-record **data map** and the **records schedule** with the records/privacy/legal
   owners (Requirements 2.3, 2.7). **Do not invent retention periods.**

---

## Phase 2 — Classification foundation (labels + SIT)

### Step 2 — Create the education sensitivity-label taxonomy
1. Purview → **Information Protection → Sensitivity labels → Create a label** (or `New-Label` in S&C
   PowerShell). Create, in order (parent labels first if you use sublabels):
   - `EDU - Public` — no protection; marking optional.
   - `EDU - Internal` — internal-only; header/footer marking.
   - `EDU - Student Record (FERPA)` — **encryption + content marking** (e.g. "FERPA — Student Record");
     scope to files/emails (and containers if used for student-data sites/Teams).
   - `EDU - Highly Confidential` — strongest encryption/marking for the most sensitive records.
2. Set each label's **protection** (encryption, content marking, container settings) per the taxonomy
   approved in Requirement 2.5. Keep protection **minimal for the pilot** and tighten later.
3. Prefer automation? **`EDU-Set-Configuration.ps1 -Area Labels`** creates the label set via S&C
   PowerShell — default **`-WhatIf`**; add **`-Commit`** to write.

### Step 3 — Build the custom `EDU - Student ID` sensitive information type
1. Purview → **Data classification → Sensitive info types → Create sensitive info type** (or
   `New-DlpSensitiveInformationType`). Name it `EDU - Student ID`; define the **pattern** (regex +
   supporting keywords) that matches **your** student-identifier format, with a confidence level and
   proximity to keywords (e.g. "student ID", "SID").
2. **Test** it against sample values in the create flow; tune to minimize false positives.
3. This SIT plus built-in SITs (names, U.S. SSN, etc.) become the **education-record** condition your
   DLP and (optionally) auto-labeling use. There is **no universal built-in FERPA SIT** — this is the
   education-specific signal you provide.

### Step 4 — Publish the labels to the pilot scope
1. Purview → **Information Protection → Label policies → Publish label** (or `New-LabelPolicy`). Name it
   `EDU - Label Policy - Pilot`; **assign it to the pilot user group** (Requirement 2.10).
2. Set policy options for the pilot (e.g. a **default label** of `EDU - Internal`, **not mandatory**
   yet, allow users to justify downgrades). **Mandatory labeling is an enforcing change — defer it to
   the expand phase.**
3. **Pass/fail gate:** pilot users see the four labels in Office apps within the publish window
   (typically up to a few hours). Validate with the Testing Guide before widening.

---

## Phase 3 — DLP in Test/simulation

### Step 5 — Create the FERPA-oriented DLP policy in Test mode
1. Purview → **Data Loss Prevention → Policies → Create policy** (or `New-DlpCompliancePolicy` +
   `New-DlpComplianceRule`). Name it `EDU - FERPA Student Records - DLP - Pilot`.
2. **Locations:** Exchange, SharePoint, OneDrive, Teams, and **Devices** (endpoint DLP — only if devices
   are onboarded, Requirement 2.3). Scope to the **pilot** where the location supports scoping.
3. **Conditions (education-record detection):** content contains `EDU - Student ID` **AND** (a name SIT
   or U.S. SSN), **OR** the file/email carries the `EDU - Student Record (FERPA)` label. Tune counts and
   confidence to your false-positive tolerance.
4. **Actions:** restrict sharing **outside the organization**, notify the user with a **policy tip**,
   and generate an **incident report** — but set the policy **status to Test** (with or without policy
   tips). **Do not enforce.**
5. Automate with **`EDU-Set-Configuration.ps1 -Area DLP`** — it creates the policy in **Test** mode by
   default; it will **not** enable enforcement even with `-Commit` (enforcement is a deliberate,
   separate, out-of-band change in Step 9).
6. **Pass/fail gate:** the policy exists in **Test**; **`EDU-Validation.ps1`** confirms mode = Test and
   the rule conditions are present.

### Step 6 — (Optional) Auto-labeling in simulation
1. If licensed (**E5**, verify), Purview → **Information Protection → Auto-labeling → Create policy** to
   auto-apply `EDU - Student Record (FERPA)` where education-record content is detected (using the
   `EDU - Student ID` SIT). **Run it in simulation** — it labels **nothing** until you review results
   and turn it on.
2. Let simulation accumulate matches; review the simulated items for accuracy before ever enabling.

---

## Phase 4 — Retention & records (schedule-driven)

### Step 7 — Configure student-record retention (per the approved schedule)
1. **Only after the records owner signs off the schedule** (Requirement 2.7). Purview → **Data
   Lifecycle Management** (or **Records Management** if declaring records) → **Retention labels →
   Create a label** `EDU - Student Education Record`; set the **retention period and disposition** to
   the **records owner's approved values** (placeholder here — do **not** invent).
2. **Publish** the label via a **retention label policy** `EDU - Retention - Student Records - Pilot` to
   the pilot SharePoint/OneDrive/Exchange locations, **or** apply it via an **auto-apply retention
   policy** keyed on the education-record condition (Step 5 logic). Use **disposition review** where
   records management requires human sign-off before deletion.
3. **Pass/fail gate:** the retention label exists with the approved period and is published to the pilot;
   **`EDU-Validation.ps1`** confirms it. Remember retention **preserves content** — confirm the period
   before applying broadly.

---

## Phase 5 — Posture, validate, and expand

### Step 8 — Stand up the Compliance Manager posture
1. Purview → **Compliance Manager → Assessments → Add assessment**; choose the **education/FERPA**
   template if licensed (else the **Data Protection Baseline**), name it `EDU - FERPA Posture`.
2. Work the **improvement actions** the assessment lists, attaching evidence (the labels/DLP/retention
   you configured, plus Audit). This produces the **defensible, scored** posture.

### Step 9 — Validate the pilot, then expand to enforce (waves)
1. Complete the **Testing Guide** pilot gates: labels visible, DLP catching in Test (review the
   simulated/Test matches), retention applied on the pilot, auto-label simulation accurate, audit
   logging.
2. **Only after the gates pass and change control approves**, expand:
   - Create production twins (`EDU - Label Policy - Prod`, `EDU - FERPA Student Records - DLP - Prod`,
     `EDU - Retention - Student Records - Prod`) or widen the pilot policies.
   - **Turn DLP from Test → Enforce** for the production scope (this is the deliberate enforcing change).
   - Publish labels tenant-wide (and consider **mandatory** labeling once staff are trained).
   - Turn **auto-labeling** from simulation → on, after reviewing simulation results.
3. Re-run **`EDU-Validation.ps1`** and **`EDU-Report.ps1`** after each wave; validate before widening.

---
### Order of operations
`Baseline (Scope-Health + Discovery) → create labels → build EDU - Student ID SIT → publish labels to
pilot → DLP in Test (education-record conditions) → (auto-label simulation) → retention per approved
schedule → Compliance Manager posture → validate pilot gates → expand: DLP Test→Enforce, labels
tenant-wide, auto-label on — in waves, validating each`


---


# 5. Testing Guide — Microsoft Purview for Education (FERPA)

Run after the labels, DLP (Test), retention, and Compliance Manager posture are configured
(Implementation Steps 2–8), on the **pilot scope**, and again after each expansion wave. Back each test
with **`EDU-Discovery.ps1`** (inventory), **`EDU-Validation.ps1`** (policy-state checks), and
**`EDU-Report.ps1`** (activity/matches). **No test requires enforcing anything** — DLP stays in **Test**
and auto-labeling in **simulation** until the pilot passes.

## Test 1 — Compliance licensing + roles are sufficient
**Do:** Run **`EDU-Scope-Health.ps1`**.
**Expected:** The tenant exposes the capabilities each step needs (E5/E5 Compliance where required);
the operator holds the least-privilege Purview role groups. Any plan-gated/preview gap is flagged
**"verify your licensing/tenant."**

## Test 2 — The education label taxonomy exists and is published to the pilot
**Do:** Run **`EDU-Discovery.ps1`**; in an Office app signed in as a **pilot** user, open the
**Sensitivity** menu.
**Expected:** `EDU - Public`, `EDU - Internal`, `EDU - Student Record (FERPA)`, `EDU - Highly
Confidential` exist and are **offered to pilot users** (label policy `EDU - Label Policy - Pilot`
assigned to the pilot group); non-pilot users do **not** yet see them.

## Test 3 — Applying the Student Record label protects the file
**Do:** As a pilot user, apply `EDU - Student Record (FERPA)` to a test document.
**Expected:** The label's **protection applies** — content marking appears and (if configured)
encryption restricts access per the label. Downgrade prompts for justification if so configured.

## Test 4 — The `EDU - Student ID` SIT matches education-record content
**Do:** Run **`EDU-Discovery.ps1`** (lists custom SITs); in **Data classification → Sensitive info
types**, test `EDU - Student ID` against sample student-ID values and a non-matching value.
**Expected:** Real student-ID values **match** at the expected confidence; obvious non-matches do
**not**. False-positive rate is acceptable to the data owner.

## Test 5 — DLP is in Test mode with the education-record conditions
**Do:** Run **`EDU-Validation.ps1`**.
**Expected:** `EDU - FERPA Student Records - DLP - Pilot` exists, **mode = Test** (not Enforce), across
the intended locations, with conditions detecting education-record content (`EDU - Student ID` + name/SSN,
or the `EDU - Student Record (FERPA)` label).

## Test 6 — DLP catches a simulated education-record leak (in Test, blocks no one)
**Do:** As a pilot user, attempt to **share externally** a test document containing sample student-ID +
name content (synthetic data only). Then run **`EDU-Report.ps1`**.
**Expected:** The action **is not blocked** (Test mode) but a **policy tip / incident** is generated and
appears in the DLP activity/report — proving the rule *would* catch a real leak before you enforce.

## Test 7 — Auto-labeling simulation is accurate (if configured)
**Do:** If Step 6 was done, review the **auto-labeling simulation** results in the portal.
**Expected:** The simulation flags education-record documents for `EDU - Student Record (FERPA)` with
acceptable accuracy and **labels nothing** — you review before enabling.

## Test 8 — Retention label exists with the approved period and is published
**Do:** Run **`EDU-Validation.ps1`**; check **Data Lifecycle / Records Management → Retention labels**.
**Expected:** `EDU - Student Education Record` exists with the **records owner's approved** period and
disposition, published via `EDU - Retention - Student Records - Pilot` to the pilot locations. (The
period is a **records determination** — this test confirms it matches the signed-off schedule, not that
it is "correct" legally.)

## Test 9 — Audit is logging label/DLP/retention activity
**Do:** Run **`EDU-Discovery.ps1`** (audit state); in Purview → **Audit**, search for recent label/DLP
events from Tests 3 and 6.
**Expected:** Audit is **On** and the label-apply and DLP events are searchable — the evidence trail
exists (Premium retention if licensed).

## Test 10 — Compliance Manager posture is scored with evidence
**Do:** Open **Compliance Manager → `EDU - FERPA Posture`**.
**Expected:** The assessment shows a **score** with improvement actions; the configured labels/DLP/
retention/audit map to actions and evidence is attachable — a defensible, measured posture.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Foundation pass** | Tests 1–4 pass (licensing/roles; labels published to pilot; label protects; Student-ID SIT accurate) |
| **Protection pass** | Tests 5–8 pass (DLP in Test with correct conditions; catches simulated leak; auto-label simulation accurate; retention per approved schedule) |
| **Evidence pass** | Tests 9–10 pass (audit logging; Compliance Manager scored with evidence) |

> Do not expand beyond the pilot or move **DLP Test → Enforce** / labels tenant-wide until all three
> gates pass **and** change control approves. Re-run Tests 5–10 after each expansion wave.


---


# 6. Troubleshooting Guide — Microsoft Purview for Education (FERPA)

Symptom → likely root cause → fix. Use **`EDU-Discovery.ps1`** (inventory), **`EDU-Validation.ps1`**
(policy state), **`EDU-Report.ps1`** (activity/matches), and **`EDU-Scope-Health.ps1`** (licensing/
roles) to confirm before and after each fix. Where a capability is **plan-gated or the portal path is
version-dependent, verify your licensing/tenant / against current Microsoft guidance** rather than
assuming.

## A. Licensing & roles

### A capability (advanced DLP, auto-label simulation, records management, premium assessment) isn't visible
- **Plan-gated.** These require **E5 / E5 Compliance** (some are preview). **Fix:** run
  **`EDU-Scope-Health.ps1`**; assign/purchase the licensing (Requirement 2.1), or use the E3-level
  baseline for now. **Verify your licensing/tenant** for preview features.

### "You don't have permission" creating a label / DLP / retention policy
- **Missing Purview role group.** Labels need **Information Protection**; DLP needs **Compliance
  Administrator/Data Administrator**; retention needs **Records Management**. **Fix:** assign the
  least-privilege role group (Requirement 2.2); confirm in **Roles & scopes → Permissions**.

## B. Sensitivity labels

### Pilot users don't see the education labels in Office
- **Label policy not assigned / still propagating.** Publishing via `EDU - Label Policy - Pilot` can
  take time to reach clients. **Fix:** confirm the pilot group is on the policy (**`EDU-Validation.ps1`**);
  wait the publish window; have the user sign out/in.
- **User not in the pilot group.** **Fix:** add them to the pilot group or confirm scope; non-pilot
  users are **not** meant to see the labels yet.

### Applying `EDU - Student Record (FERPA)` doesn't protect the file
- **Label has no protection configured.** A label without encryption/marking classifies but doesn't
  protect. **Fix:** edit the label → set **encryption + content marking** (Requirement 2.5 / Step 2);
  re-apply.
- **Client cache.** **Fix:** wait for the label refresh / restart the Office app.

## C. Sensitive information type (student ID)

### DLP/auto-label misses obvious education-record documents
- **`EDU - Student ID` SIT pattern too narrow / wrong.** **Fix:** in **Data classification → Sensitive
  info types**, test `EDU - Student ID` against real sample formats; broaden the regex/keywords and
  confidence; **`EDU-Discovery.ps1`** confirms the SIT exists.
- **Relying on a built-in "FERPA" SIT that doesn't exist.** There is **no universal FERPA SIT** — you
  must use `EDU - Student ID` + built-in SITs. **Fix:** build/confirm the custom SIT (Step 3).

### Too many false positives
- **Confidence/proximity too loose.** **Fix:** raise the confidence level and require a nearby keyword
  ("student ID", "SID"); increase the instance count; re-test in Test mode before enforcing.

## D. Data Loss Prevention

### DLP isn't blocking external sharing of student records
- **Policy is in Test mode — by design.** In Test, DLP **detects but does not block**. **Fix:** this is
  expected during the pilot; review matches in **`EDU-Report.ps1`**, and only move **Test → Enforce**
  after the pilot passes and change control approves (Implementation Step 9).
- **Location not covered / device not onboarded.** Endpoint DLP needs devices **onboarded**. **Fix:**
  confirm locations in **`EDU-Validation.ps1`**; onboard devices (Requirement 2.3) for endpoint
  coverage.

### DLP is blocking legitimate teaching/registrar work
- **Conditions too broad / enforced too early.** **Fix:** set the policy back to **Test**
  (**`EDU-Validation.ps1`** flags enforcing policies), tune the education-record conditions, and
  re-validate before re-enforcing. Roll back first, tune second.

### No DLP matches at all in Test
- **Conditions don't match your content, or SIT is off.** **Fix:** confirm the rule uses
  `EDU - Student ID` + name/SSN **or** the `EDU - Student Record (FERPA)` label (**`EDU-Validation.ps1`**);
  test with synthetic student-record content (Testing Test 6).

## E. Auto-labeling

### Auto-labeling isn't applying `EDU - Student Record (FERPA)`
- **Still in simulation — by design.** Simulation **labels nothing**. **Fix:** review simulation
  results; enable only after they're accurate (and licensing supports it — **verify your
  licensing/tenant**).

## F. Retention & records

### Retention label isn't available to apply / not appearing on sites
- **Label policy not published to the location / propagation delay.** **Fix:** confirm
  `EDU - Retention - Student Records - Pilot` targets the pilot locations (**`EDU-Validation.ps1`**);
  allow propagation time.

### Wrong retention period / disposition
- **Period was set without the records owner's sign-off.** Retention is a **records determination**.
  **Fix:** correct the label to the **approved** period/disposition; **note that content already
  retained stays retained for the period** even after a label change — engage the records owner. **Do
  not invent periods.**

### Content was deleted that should have been kept (or vice-versa)
- **Disposition/label mismatch with the schedule.** **Fix:** review the label's retain/delete settings
  against the signed-off schedule with records management; use **disposition review** so deletions
  require human sign-off. Escalate as a **records incident** — this is a governance matter, not just a
  config fix.

## G. Audit & evidence

### Label/DLP/retention activity isn't searchable in Audit
- **Audit off, or event still indexing.** **Fix:** confirm Audit is **On** (Purview → **Audit**;
  **`EDU-Discovery.ps1`** reports state); allow indexing latency; confirm **Premium** retention if you
  need older events (licensing).

### Compliance Manager score isn't moving
- **Improvement actions not worked / evidence not attached.** **Fix:** in `EDU - FERPA Posture`, complete
  the improvement actions and attach the configured labels/DLP/retention/audit as evidence.

---
## Escalation checklist
1. `EDU-Scope-Health.ps1` — licensing sufficient, operator holds the right Purview role groups?
2. `EDU-Discovery.ps1` — labels, `EDU - Student ID` SIT, DLP (and mode), retention labels, audit all present?
3. `EDU-Validation.ps1` — DLP in **Test** (nothing accidentally enforcing), label policy targets the pilot, retention period matches the signed-off schedule, DLP conditions reference the education-record signal?
4. `EDU-Report.ps1` — DLP matches/incidents as expected in Test; label usage and retention coverage sane?
5. Still stuck → capture the symptom and **verify against current Microsoft guidance / your tenant** (Purview paths and plan-gating evolve); route **records/legal/privacy determinations** to the governance owners — they are not technical fixes.


---


# 7. Best Practices — Microsoft Purview for Education (FERPA)

Field-proven recommendations for an education-tailored Purview program that is accurate, defensible,
and low-friction for staff and students.

## Design
- **Let governance own the determinations.** FERPA applicability, retention periods, file plans, and
  legal holds are **records/privacy/legal** calls. Configure Purview to **enforce** them; never invent a
  retention period or decide what an education record is on your own. Capture named approvers.
- **Keep the label taxonomy small and human.** Four labels staff understand (`EDU - Public` →
  `EDU - Highly Confidential`, with `EDU - Student Record (FERPA)`) beat a sprawling set nobody applies
  correctly. Complexity causes mislabeling, which undermines every downstream control.
- **Make the student ID the anchor signal.** Education-record detection is only as good as your
  **custom `EDU - Student ID` SIT**. Invest in getting its pattern and false-positive rate right — it
  is what makes DLP and auto-labeling "understand" education records. There is **no built-in FERPA SIT**.
- **Design labels → DLP → retention as one chain.** Labels classify, DLP protects the labeled/detected
  data, retention keeps and disposes it. Wiring them to the **same** education-record definition keeps
  the program coherent (the whole point of the industry bundle).

## Pilot in simulation/test — always
- **Never enforce first.** Create DLP in **Test** and auto-labeling in **simulation**, on a **pilot
  scope**, every time. Review what *would* happen before it happens. This is the single most important
  habit in a live education tenant.
- **Read the Test/simulation results before enforcing.** A Test DLP policy and an auto-label simulation
  exist to be *reviewed*. Move to Enforce/on only after the matches look right and change control
  approves — then expand in waves, validating each.
- **Use synthetic data for testing.** Test DLP and labels with **fake** student records, never real
  ones — testing must not itself create a FERPA exposure.

## Accuracy and friction
- **Tune for false positives before you enforce.** Over-eager DLP blocks legitimate teaching/registrar
  work and trains staff to route around it. Adjust SIT confidence, instance counts, and conditions in
  Test until precision is acceptable.
- **Publish labels with a sensible default, not mandatory (at first).** Start with a default label and
  optional justification; only make labeling **mandatory** after staff are trained — mandatory is an
  enforcing change.
- **Protect containers used for student data.** Where student records live in specific Teams/SharePoint
  sites, use **container labels** so the site itself carries protection, not just individual files.

## Retention & records (handle with extra care)
- **Retention preserves content — confirm the period first.** Once applied, retained content stays for
  the period even if you unpublish the label. **Do not apply retention until the records owner signs off
  the schedule.** Use **disposition review** where records management requires human sign-off before
  deletion.
- **Separate "retain" from "delete."** Be explicit about whether a label retains-then-deletes,
  retains-only, or deletes-only, and match it to the records schedule — a wrong disposition rule is a
  records incident.

## Evidence & posture
- **Turn Audit on and keep it on.** Label, DLP, and retention activity in the audit log is your evidence
  the program operates. Use **Audit Premium** retention where licensed.
- **Work Compliance Manager continuously.** Treat `EDU - FERPA Posture` improvement actions as a living
  backlog with attached evidence — it turns a pile of policies into a **scored, defensible** posture for
  any FERPA inquiry.

## Operations, automation & security
- **Run the scripts read-only first.** `EDU-Discovery` / `EDU-Validation` / `EDU-Report` /
  `EDU-Scope-Health` are read-only; `EDU-Set-Configuration` defaults to **`-WhatIf`** and creates DLP in
  **Test** even with `-Commit`. Preview before you write; enforcement is always a separate, deliberate,
  human step.
- **Least privilege, no secrets.** Connect with the **least Purview role groups / Graph scopes** each
  task needs; **never** put credentials, tokens, or student data in scripts or source control. Use
  modern-auth / MFA admin accounts.
- **Verify licensing/tenant at every plan-gated step.** Advanced DLP, auto-labeling simulation, records
  management, and premium Compliance Manager assessments require **E5 / E5 Compliance** and the portal
  evolves — confirm availability and paths against **current Microsoft guidance / your tenant** rather
  than assuming.
- **Document rollback for every enforcing change.** Know the revert before you enforce: set DLP back to
  **Test** / disable it; remove the pilot group from the label policy to stop offering labels; remember
  **retained content stays retained** — which is exactly why retention goes last and only after sign-off.


---


# 8. Deliverables Summary — Microsoft Purview for Education (FERPA)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case: an education-tailored, FERPA-aligned Purview program, piloted in simulation/test and defensible |
| 1. Solution Overview | The education-fit program (labels/DLP/retention/posture), why "tailored to education" matters, industry-bundle model, what's authored vs deferred |
| 2. Requirements Guide | Every education/FERPA prerequisite with Verify / Implement-if-missing (the six category Purview GRs referenced, not duplicated) |
| Global Requirements (Purview) | Category-wide Purview prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal + S&C PowerShell + Graph steps: labels → custom Student-ID SIT → publish to pilot → DLP in Test → (auto-label simulation) → retention per approved schedule → Compliance Manager; pilot-in-simulation-first, pass/fail + rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates (nothing enforced) |
| 6. Troubleshooting Guide | Labels, DLP, retention, SIT, licensing, and audit issues by symptom → root cause → fix |
| 7. Best Practices | Field-proven recommendations; pilot-in-simulation discipline; determinations deferred to governance |

## PowerShell scripts (Security & Compliance PowerShell / Microsoft Graph)
| Script | What it does | Safety |
|---|---|---|
| `EDU-Discovery.ps1` | Read-only inventory: sensitivity labels + label policies, DLP policies **and their mode**, retention labels/policies, custom SITs (incl. `EDU - Student ID`), and audit state | Read-only |
| `EDU-Set-Configuration.ps1` | Creates the education label set, the FERPA DLP policy **in Test mode**, and the retention label — `-Area Labels/DLP/Retention` | Default `-WhatIf`; `-Commit` to write; **DLP always created in Test — never enforces** |
| `EDU-Validation.ps1` | Policy-state checks: DLP is in **Test** (flags any enforcing), label policy targets the pilot, retention label has the approved period, DLP conditions reference the education-record signal | Read-only |
| `EDU-Report.ps1` | Activity/coverage: DLP match/incident counts (Test + enforced), label usage, and disposition/retention coverage where readable | Read-only |
| `EDU-Scope-Health.ps1` | Readiness helper: compliance licensing the tenant exposes, operator Purview role-group membership (where readable), in-scope workloads, and gaps vs the Requirements Guide | Read-only |

## What the buyer receives
- This implementation guide as a **PDF** (and, per the factory, a white-label local copy).
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**

## Outcome
A Microsoft Purview program **tailored to education and aligned to FERPA** — an agreed label taxonomy
published to a pilot, a custom student-ID sensitive information type anchoring FERPA-oriented DLP proven
in **Test/simulation** before it blocks anyone, student-record retention enforced to the records
owner's approved schedule, and a **scored, evidenced** Compliance Manager posture — configured,
validated against pass/fail gates, and defensible. Regulatory, records, and legal determinations remain
with the institution's governance functions.
