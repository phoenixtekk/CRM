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
