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
