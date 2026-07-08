# Microsoft Purview Data Lifecycle & Records Management

> **Version 1.0.0** · Category: Purview · Solution code: PURVDLM

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

Across Microsoft 365 — Exchange, SharePoint, OneDrive, and Teams — the organization accumulates content
it is obligated to **retain** for a defined period and then **dispose** of on schedule. When that
obligation is unenforced, the content becomes liability: over-retained data inflates breach and eDiscovery
exposure, under-retained data breaks a regulatory or legal obligation, and content that is never reviewed
accumulates indefinitely. This solution implements **data lifecycle and records management org-wide in
Microsoft Purview** so tenant data is kept and disposed on a defensible schedule — retention policies and
labels applied across all four workloads, records declared and locked in place, and disposition made
evidenced and defensible.

**Outcome.** Tenant-wide **retention policies** as the safety net and **retention labels** for the
records-grade categories; **records management** with a reportable **file plan**, **regulatory records**
where legally required, and **event-based retention** for the cases the calendar cannot handle (keep *N
years after termination / expiry / end-of-life*); a working **disposition-review** workflow where a named
reviewer approves disposal and Microsoft Purview keeps proof of what was disposed, by whom, and when.
Ungoverned data becomes governed records — retained and disposed on schedule across M365.

**Approach.** The work is **org-wide (tenant scope)** and **aligned to the organization's broader
Microsoft Purview program** — it reuses that program's foundations rather than rebuilding DLP, sensitivity
labels, or data governance, and it defers SharePoint library-level mechanics to the SharePoint records
product. It implements the **retention schedule provided by records, compliance, and legal**; it does not
author retention periods or make legal determinations. Delivery follows a disciplined, pilot-first model —
**Assess → Design → Configure → Pilot → Validate → Expand** — with the schedule mapped to policies and
labels, staged disabled and published to a bounded pilot scope, validated against explicit pass/fail
gates, and only then enforced tenant-wide with adaptive scopes. Five PowerShell tools (Security &
Compliance PowerShell and Graph) handle posture assessment, retention-policy/label configuration,
records/file-plan/disposition configuration, compliance reporting, and scope/health — read-only or dry-run
(`-WhatIf`) by default, with no credentials in code.

**Why it is low-risk.** Tenant-wide retention and records declaration are high-impact, so nothing touches
production content until it is proven on a pilot. Assessment is read-only; policies are staged **disabled**
and labels published to the pilot scope before enforcement; every change has a documented rollback, and the
**irreversible** actions (regulatory records, completed disposition, elapsed event-based deletions) are
explicitly flagged as no-rollback and gated on records/legal sign-off. Plan- and cloud-dependent behavior
(records management, adaptive scopes, event-based retention, Government-cloud portal paths) is flagged for
tenant verification rather than assumed. The result: M365 data governed on a defensible schedule — nothing
kept forever by accident, nothing disposed too early — with liability turned into evidenced, defensible
records.


---


# 1. Solution Overview — Microsoft Purview Data Lifecycle & Records Management

## What this solution is
Across Microsoft 365 — Exchange mailboxes, SharePoint sites, OneDrive accounts, and Teams chats and
channels — the organization accumulates content it is obligated to **retain** for a defined period and
then **dispose** of on schedule. When neither is enforced, that content becomes liability:
over-retained data inflates eDiscovery and breach exposure, under-retained data breaks a regulatory or
legal obligation, and content that is never reviewed for disposal accumulates forever. This solution is
a repeatable, pilot-first method to implement **data lifecycle and records management org-wide in
Microsoft Purview**: retention **policies** and retention **labels** across Exchange/SharePoint/
OneDrive/Teams, **records management** (records declaration, the file plan, regulatory records, and
event-based retention), **disposition review**, and **defensible disposal** — all mapped to the
organization's retention schedule — so data is kept and disposed on policy across the whole tenant.

It is deliberately **org-wide (tenant scope)**. Microsoft Purview treats data lifecycle management
(retention policies and labels) and records management (records + file plan + disposition) as
tenant-level solutions that apply across all four workloads at once. This product implements that
org-wide layer. The **SharePoint-scoped records/retention product** covers SharePoint-specific
mechanics — default library labels, in-place records inside document libraries, PnP-driven
site/library application, adaptive site scopes — in depth; where this solution needs SPO detail it
**references** that product rather than duplicating it.

## Retention policies vs retention labels — the core distinction
The single most important design decision in Microsoft Purview data lifecycle management is **policy
vs label**, and this solution treats it as first-class:

- A **retention policy** applies a single retention **outcome** (retain, delete, or retain-then-delete
  for one duration) to **whole locations** — all Exchange mailboxes, all SharePoint sites, all OneDrive
  accounts, all Microsoft 365 Groups, Teams chats/channels — **without touching individual items**.
  There is no user action, nothing is visible on the item, and it is the tenant-wide **safety net**:
  "everything in SharePoint is kept for at least N years." One policy can span multiple workloads.
- A **retention label** is applied to **individual items or documents** (a message, a file, a library's
  default) and can carry richer behavior a policy cannot: **records declaration** (mark as record /
  regulatory record), **event-based retention** (start the clock on an event, not a date),
  **disposition review**, and **file-plan descriptors**. Labels are published for users to apply,
  auto-applied by condition, or set as a library/folder default.

Policies are the broad floor; labels are the precise, records-grade instrument. The reference design
uses **both**: tenant-wide retention policies as the baseline, and retention labels for the categories
that require records, events, or a reviewed disposition. *(Retention precedence resolves conflicts when
both touch the same item — see "Retention precedence" below.)*

## What this solution is NOT (the deferred boundary)
- **The retention schedule itself is not authored here.** *Which* content is a record, *how long* each
  category is retained, the retention **trigger/event**, and the **disposition authority** are
  determined by the organization's **records-management, compliance, privacy, and legal** functions.
  This solution takes that schedule as input and implements it faithfully across M365; it does not
  invent retention periods, record status, or legal determinations.
- **Legal holds and eDiscovery determinations** (what to preserve for a matter, when a hold attaches or
  releases) belong to legal/eDiscovery, not to this lifecycle/records configuration.
- **Sensitivity (information-protection) labels, DLP, and the broader Purview data-governance program**
  are referenced and aligned to, not rebuilt here.
- **SharePoint-specific records mechanics** are the province of the SharePoint records/retention
  product — referenced, not re-documented.

## Why this matters
- Retention that lives only in a policy binder is not enforced. A retention **policy** or **label** in
  Microsoft Purview is enforcement the platform executes across Exchange, SharePoint, OneDrive, and
  Teams — consistently, on a timer, without relying on users.
- A **record** (or regulatory record) label locks content against premature edit or deletion — the
  defensibility a regulator or auditor expects — and the **file plan** makes the whole records inventory
  reportable (retention authority, category, department, citation).
- **Event-based retention** solves the hard cases the calendar cannot: keep an employee record for *N
  years after termination*, a contract for *N years after expiry*, a product record for *N years after
  end-of-life* — the clock starts on the **event**, triggered when it happens.
- **Disposition review** turns "delete on expiry" into a governed, evidenced decision: a named reviewer
  approves disposal (or extends/relabels), and Microsoft Purview keeps proof of what was disposed, by
  whom, and when.
- Doing this **pilot-first**, with policies staged and labels published to a bounded scope before
  tenant-wide enforcement, avoids the high-impact failure mode of an org-wide retention or records
  misconfiguration that locks or deletes content wrongly.

## How it works (org-wide)
1. **Retention labels** are created in Microsoft Purview → **Records management → File plan** (or **Data
   lifecycle management → Labels**). A label carries a **retention action** (retain / delete /
   retain-then-delete), a **duration**, a **retention trigger** (item created, last modified, labeled,
   or an **event**), and optionally a **records** setting (mark as record, or regulatory record),
   **file-plan descriptors**, and a **disposition review** with named reviewers.
2. **Retention policies** are created in **Data lifecycle management → Policies**. Each policy applies a
   retention outcome to selected **locations** — Exchange, SharePoint, OneDrive, Microsoft 365 Groups,
   Teams channel messages, Teams chats — as the tenant-wide safety net, with no per-item action.
3. **Label policies** publish labels (users apply them) or **auto-apply** them by condition (keyword,
   sensitive-info type, or trainable classifier) across the same locations.
4. **Records declaration** happens when a **record** or **regulatory-record** label is applied: the item
   becomes an in-place record — it stays where it is but is locked against edit/delete/move per its
   version and rules, with an auditable declare/undeclare trail. Regulatory records are one-way and
   cannot be unlocked or shortened.
5. **The file plan** organizes the label inventory with descriptors — **retention authority**,
   **category / sub-category**, **department**, **citation**, **reference ID** — so the records program
   is reportable and defensible, and labels can be imported/exported in bulk.
6. **Event-based retention** uses **event types**: a label's clock is set to start on an event (e.g.
   `Employee termination`, `Contract expiration`); when the event occurs, a **retention event** is
   raised (with the asset ID / keyword that matches the affected content) and the retention period
   begins for all matching items.
7. **Disposition review** runs at the end of the retention period for any label configured with
   reviewers: the item enters the **Disposition** queue in Microsoft Purview, a reviewer approves
   permanent deletion, extends retention, relabels, or applies a different label — and the decision is
   evidenced.
8. **Defensible disposition** is the outcome: content is disposed only after its schedule expires and
   (where required) a review is approved, and Microsoft Purview retains a **disposition record** as
   proof.
9. The whole configuration is delivered through the house model — **Assess → Design → Configure → Pilot
   → Validate → Expand** — so the schedule is proven on a bounded pilot scope before it is enforced
   tenant-wide.

## The reference design
- **Inputs (from records/legal):** the retention schedule — categories, retention periods, triggers
  (date vs event), record vs non-record vs regulatory, disposition authority (auto vs review, and who
  reviews), and the applicable regulatory citations.
- **Policies (the floor):** one or more tenant-wide **retention policies** per workload (or a single
  multi-workload policy) as the baseline safety net — e.g. `Retention Policy – Tenant-Baseline –
  Pilot`, staged with locations selected and left **disabled** until validated.
- **Labels (records-grade):** one retention/record label per schedule category, named consistently and
  imported with **file-plan descriptors** so the file plan is reportable — plain retention, **record**,
  or **regulatory record** as records/legal designate.
- **Application:** **published** label policies where users apply labels; **auto-apply** policies for
  categories detectable by condition; default library labels for SharePoint (deferred to the SPO
  records product for that mechanic).
- **Events:** **event types** for the event-based categories (termination, expiry, end-of-life) with a
  defined trigger source and the operational process to raise the event.
- **Disposition:** single- or multi-stage disposition review with named reviewer groups for the
  categories that require a human approval before disposal.
- **Scopes:** **static** scopes for the pilot; **adaptive** (query-driven) scopes as an option for
  expansion so a policy tracks locations automatically. *Adaptive scopes and several records features
  are plan-dependent — verify your licensing in your tenant.*

## Retention precedence (design with it, validate it)
When multiple retention outcomes touch the same item, Microsoft's **principle of retention** decides
the result, in order: **(1) Retention wins over deletion** — if anything says retain, the item is kept;
**(2) the longest retention period wins**; **(3) explicit (label) wins over implicit (policy)**; **(4)
the shortest deletion period wins**. Design labels and policies with this in mind, and **validate the
effective outcome** on pilot content — never assume the result of overlapping policies and labels.

## What you can control
- Which workloads and locations are in scope (Exchange / SharePoint / OneDrive / Groups / Teams), and
  whether coverage is by tenant-wide policy, published/auto-applied label, or both.
- Which schedule categories become labels, and whether each is a plain retention label, a **record**, or
  a **regulatory record** (regulatory records cannot be unlocked — use only where records/legal require).
- How labels are applied (published, auto-applied, or default) and whether retention is **date-based** or
  **event-based**.
- Whether a category ends in automatic disposal or **disposition review**, and who the reviewers are.
- The pilot scope, the pass/fail gates, and the rollback — before any tenant-wide expansion.

## Limitations (be honest with buyers)
- **Advanced lifecycle/records features are plan-dependent.** Auto-apply policies, adaptive scopes,
  records management (record/regulatory-record labels, the file plan), event-based retention, and
  multi-stage disposition review generally require the appropriate compliance licensing (commonly an
  **E5 / E5 Compliance-class** plan or add-on) — **verify what your tenant is licensed for.**
- **Retention and deletion are eventually consistent, not instant.** Policy application, label
  propagation, event processing, and disposition run on service timers; expect propagation delays (often
  hours to a few days, and up to 7 days for some policy application) — do not judge a pilot on the first
  minutes.
- **Regulatory records are one-way.** A regulatory-record label cannot be removed or changed and its
  retention cannot be shortened. Use it only where records/legal explicitly require it.
- **A record label locks content.** Owners/users lose edit/delete on declared items by design;
  communicate this before applying record labels to live content.
- **Retention precedence governs overlaps.** Multiple policies/labels on the same content resolve by the
  principle above — validate the effective outcome, don't assume it.
- **Disposition review is a portal workflow.** Reviewers act in the Purview **Disposition** area; the
  provided reporting surfaces label/policy coverage and configuration, and points reviewers to the
  portal queue rather than approving disposals from a script.
- **Commercial vs Government cloud paths differ.** Portal URLs and some feature availability differ in
  GCC / GCC High / DoD (e.g. `*.office365.us`, `Connect-IPPSSession -ConnectionUri`) — **verify the
  portal path and feature in your cloud.**

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and the Purview admin surfaces. The standard set:

| Artifact | Name |
|---|---|
| Tenant-wide baseline retention policy | `Retention Policy – Tenant-Baseline – Pilot` |
| Workload retention policy (e.g. Exchange) | `Retention Policy – Exchange-3yr – Pilot` |
| Retention label (general category) | `Retention Label – General-3yr – Pilot` |
| Record label (record category) | `Record Label – Contracts-7yr – Pilot` |
| Regulatory record label (where required) | `Regulatory Record Label – Financial-7yr – Pilot` |
| Auto-apply label policy | `Label Policy – Contracts-AutoApply – Pilot` |
| Published label policy (manual apply) | `Label Policy – User-Publish – Pilot` |
| Event type (event-based retention) | `Event Type – Employee-Termination` |
| File-plan retention authority | `Authority – Records-Schedule-2026` |
| Pilot scope (static) | `Scope – Lifecycle-Pilot – Static` |
| Adaptive scope (expansion) | `Scope – Lifecycle-Prod – Adaptive` |
| Disposition reviewer group (stage 1) | `Disposition Reviewers – Records – Stage1` |
| Assessment export | `Retention Posture – Tenant – Discovery` |
| Compliance report | `Lifecycle Compliance – Tenant – Report` |

When the pilot passes and you expand to production, mint the production equivalents by swapping the
`– Pilot` stage for `– Prod` (e.g. `Record Label – Contracts-7yr – Prod`) — never edit a validated
pilot artifact in place.

## The standard deployment model
> **Assess** current tenant retention/records posture and ingest the retention schedule → **Design** the
> policy/label/scope/event map → **Configure** policies, labels, records, the file plan, events, and
> disposition → **Pilot** on `Scope – Lifecycle-Pilot – Static` (policies disabled / labels published to
> the pilot) → **Validate** against explicit pass/fail gates → **Expand** tenant-wide with adaptive
> scopes and enabled policies.

Tenant-wide retention, records declaration, and disposition are **high-impact** — a wrong retention
period, an over-broad auto-apply, or a mistaken regulatory-record label is expensive or irreversible.
Every production change goes through change control with a documented rollback, and nothing expands past
the pilot until the gates in Section 5 pass.


---


# 2. Requirements

These are the **solution-specific** prerequisites for implementing data lifecycle and records
management org-wide in Microsoft Purview. They build **on** the shared Purview category requirements in
**`global-requirements-purview.md`** (a Microsoft 365 tenant with the required Purview/compliance
licensing; least-privilege Purview roles and portal access; the Security & Compliance PowerShell +
Graph toolchain; the in-scope data sources/workloads; the compliance/records/privacy/legal
stakeholders; and a pilot scope with change control). Do not repeat those — verify them first, then
confirm the lifecycle/records-specific prerequisites below. Each is stated as **Description / Why /
Verify / Implement if missing.**

---

## 2.1 Compliance licensing for records & advanced retention
- **Description:** The Microsoft 365 / Microsoft Purview licensing that unlocks the features this
  solution uses — basic retention policies and labels are broadly available, but **records management**
  (record and regulatory-record labels, the file plan), **auto-apply** label policies, **adaptive
  scopes**, **event-based retention**, and **disposition review** are generally in an **E5 / E5
  Compliance-class** plan or the equivalent Purview add-on.
- **Why required:** These capabilities are **plan-gated**; without the right plan the records labels,
  auto-apply policies, adaptive scopes, and disposition reviews in the design cannot be created.
- **Verify:** In the Microsoft 365 admin center → Billing → Licenses, confirm the compliance plan/
  add-on. In the Microsoft Purview portal, confirm both **Data lifecycle management** and **Records
  management** solutions are visible. *Feature-to-plan mapping changes — verify the exact entitlement in
  your tenant.*
- **Implement if missing:** Have licensing assign/purchase the required compliance plan or add-on to the
  admin and any accounts that will manage records, before configuration.

## 2.2 The retention schedule (input from records & legal)
- **Description:** The authoritative **retention schedule** for the tenant's content: the categories,
  each category's **retention period**, its **trigger** (created / last-modified / labeled / **event**),
  whether it is a **record** or **regulatory record**, the applicable **regulatory citation/authority**,
  and the **disposition authority** (automatic vs review, and who reviews).
- **Why required:** This solution **implements** the schedule; it does not author it. Policies and labels
  are a direct translation of the schedule — without it there is nothing correct to configure.
- **Verify:** Confirm records/legal has provided (or signed off) a schedule naming each category, period,
  trigger, record status, citation, and disposition path — or at least a pilot subset of categories.
- **Implement if missing:** This is **deferred to the records-management / compliance / legal
  functions** — request the schedule before configuring. Do not invent retention periods, record status,
  event triggers, or disposition rules.

## 2.3 Roles for lifecycle & records management
- **Description:** The least-privilege role groups to create and manage retention/records in Microsoft
  Purview: **Records Management** or **Compliance Administrator** / **Compliance Data Administrator** for
  labels, policies, the file plan, and events; **Disposition Management** for reviewers; and the
  workload admin rights (Exchange / SharePoint) where item- or location-level application requires them.
- **Why required:** Creating labels, publishing/auto-applying policies, building the file plan, raising
  events, and acting on disposition each require the corresponding Purview role; disposition reviewers
  must be in **Disposition Management** or they cannot see the queue.
- **Verify:** Microsoft Purview portal → **Roles & scopes → Permissions (role groups)** — confirm the
  admin's membership; confirm reviewers are in **Disposition Management**.
- **Implement if missing:** Have a Global Admin / Compliance Admin add the accounts to the least-
  privilege role groups under change control. Grant **Disposition Management** only to the named reviewer
  accounts.

## 2.4 In-scope workloads and their state (Exchange / SPO / OneDrive / Teams)
- **Description:** Confirmation of which **workloads and locations** are in scope and that they are in a
  state retention can apply to — Exchange mailboxes, SharePoint sites, OneDrive accounts, Microsoft 365
  Groups, and **Teams** chats and channel messages (Teams retention is configured through its own
  locations and interacts with the underlying group/mailbox).
- **Why required:** A retention policy keys off the locations selected; Teams and Groups have specific
  location behaviors, and OneDrive/SharePoint retention depends on the site/account existing. Scoping the
  wrong locations either under-covers or over-covers content.
- **Verify:** Confirm the in-scope workloads with stakeholders; confirm Teams/Groups are included or
  excluded deliberately; identify any locations that must be excluded (e.g. a journaling mailbox).
- **Implement if missing:** Define the location scope per workload before authoring policies; document
  any deliberate exclusions.

## 2.5 Existing Purview program posture (alignment, not duplication)
- **Description:** Knowledge of the organization's **existing Microsoft Purview posture** — sensitivity
  (information-protection) labels, DLP policies, and any retention labels/policies already in force — so
  this org-wide lifecycle/records work **aligns** to it rather than conflicting or duplicating, and so
  **retention precedence** is understood before adding overlapping policies.
- **Why required:** Retention outcomes interact via Microsoft's retention-precedence rules; an unaware
  new policy can conflict with an existing one. Sensitivity labels and DLP are owned by the broader
  Purview program and must not be re-implemented here.
- **Verify:** Enumerate existing labels/policies (`Get-ComplianceTag`, `Get-RetentionCompliancePolicy`,
  `Get-RetentionComplianceRule`) and confirm which are owned by the broader program; note any existing
  tenant-wide retention that a new policy would overlap.
- **Implement if missing:** Engage the Purview program owners; capture the existing baseline (the
  assessment script does this) before adding policies or labels.

## 2.6 SharePoint records mechanics (referenced, not rebuilt)
- **Description:** For the SharePoint portion of scope, the **SharePoint-specific records/retention
  mechanics** — default library labels, in-place records inside document libraries, PnP-driven
  site/library application, and adaptive **site** scopes — which are implemented in depth by the
  **SharePoint records/retention product**.
- **Why required:** This org-wide product configures the tenant-level policies, labels, file plan,
  events, and disposition; the SharePoint-library-level application detail is that product's province.
  Duplicating it risks divergent guidance.
- **Verify:** Confirm whether the SharePoint records/retention product is in play for SPO sites; if so,
  align label names and defer library-application mechanics to it.
- **Implement if missing:** Where SPO library-level records work is required, use the SharePoint
  records/retention product for that mechanic and keep the label inventory consistent across both.

## 2.7 Lifecycle/records automation toolchain
- **Description:** The **Security & Compliance PowerShell** endpoint (`Connect-IPPSSession` from the
  **ExchangeOnlineManagement** module) for retention labels, policies, records, file-plan descriptors,
  and events (`Get-ComplianceTag`, `New-RetentionCompliancePolicy`/`Rule`,
  `New-FilePlanProperty*`, `New-ComplianceRetentionEventType`, `New-ComplianceRetentionEvent`), and
  **Microsoft Graph PowerShell** for supporting reads — a modern-auth / MFA-capable admin.
- **Why required:** The provided scripts and the configuration steps run through Security & Compliance
  PowerShell (and Graph for supporting reads); both must connect.
- **Verify:** `Connect-IPPSSession` succeeds and `Get-ComplianceTag` / `Get-RetentionCompliancePolicy`
  return without error; `Connect-MgGraph` succeeds where used. In Government clouds, confirm the correct
  `-ConnectionUri` / endpoint.
- **Implement if missing:** Install the **ExchangeOnlineManagement** and **Microsoft.Graph** modules and
  confirm modern-auth sign-in before running steps. Never store credentials in scripts.

## 2.8 Change control and a documented rollback for lifecycle/records
- **Description:** An approved change window and a **rollback plan** specific to retention/records: how
  to disable/unpublish a retention policy or label policy, how to remove a non-regulatory retention
  label, and how a non-regulatory record is un-declared — plus the explicit note that **regulatory
  records, completed disposition, and elapsed event-based deletions cannot be rolled back**.
- **Why required:** Tenant-wide retention and records declaration are high-impact; a documented,
  rehearsed rollback is the safety net for the reversible parts and forces a conscious decision on the
  irreversible parts.
- **Verify:** Confirm a change ticket, an approver, and a written rollback covering policy/label disable,
  label removal, and record un-declaration for the pilot categories.
- **Implement if missing:** Author the rollback (Section 3 provides the steps), get change-control
  sign-off, and explicitly flag any **regulatory-record** category as **no-rollback** before applying it.


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


# 3. Implementation Guide

This is the ordered, pilot-first method to implement data lifecycle and records management org-wide in
Microsoft Purview. It follows the house model — **Assess → Design → Configure → Pilot → Validate →
Expand** — and every artifact is named per the convention in Section 1 and reused verbatim in the
scripts. **Retention, records, and disposition changes are high-impact**: policies are staged
**disabled**, labels are published to the **pilot scope only**, and nothing expands tenant-wide until
the Section 5 gates pass. The **retention schedule and all legal determinations are inputs from
records/legal** — this guide implements them, it does not author them.

> **Portal paths evolve and are cloud-dependent.** Paths below are Microsoft Purview portal
> (`purview.microsoft.com`) as of authoring; in GCC/GCC High/DoD the URL and some features differ
> (`*.office365.us`). **Verify the path and feature availability in your tenant/cloud** before relying
> on it. Where a step is plan-dependent, it is flagged.

---

## Stage 0 — Connect and confirm prerequisites
1. Confirm Section 2 prerequisites: compliance licensing (2.1), the retention schedule from records/legal
   (2.2), roles (2.3), in-scope workloads (2.4), existing posture (2.5), and change control (2.8).
2. Connect the toolchain from an MFA-capable admin workstation:
   ```powershell
   Connect-IPPSSession                 # Security & Compliance PowerShell (add -ConnectionUri for Gov clouds)
   Connect-MgGraph -Scopes "Directory.Read.All"   # supporting reads only
   ```
3. Run **`Resolve-RetentionScope.ps1`** to confirm module/connection health and surface plan/cloud hints
   before touching anything. **Pass/fail:** both connections succeed and the script reports the expected
   cloud and that Data lifecycle + Records management are reachable.

## Stage 1 — Assess (read-only)
1. Run **`Assess-RetentionRecordsPosture.ps1`** to produce `Retention Posture – Tenant – Discovery`: the
   existing retention labels (`Get-ComplianceTag`, including which are record/regulatory), retention
   policies and rules and their **locations/enabled state**
   (`Get-RetentionCompliancePolicy` / `Get-RetentionComplianceRule`), existing **event types**
   (`Get-ComplianceRetentionEventType`), and **file-plan** descriptors already defined.
2. Review the baseline with the Purview program owners (2.5): what already exists, what a new policy would
   **overlap**, and which labels are owned by the broader program.
3. **Pass/fail (Assess gate):** a complete inventory export exists; overlaps with existing retention are
   identified and understood against retention precedence; no destructive action was taken (read-only).

## Stage 2 — Design (map the schedule to Purview)
Translate the records/legal retention schedule into a concrete artifact map. Produce a design table with,
for each schedule category:
- **Category → artifact:** whether it is covered by a tenant-wide **policy** (the floor), a **label**
  (records/events/review), or both.
- **Retention action + duration:** retain / delete / retain-then-delete, and the period.
- **Trigger:** created / last-modified / labeled / **event** (and which event type).
- **Record status:** none / record / **regulatory record** (regulatory only where records/legal require).
- **File-plan descriptors:** retention **authority**, **category/sub-category**, **department**,
  **citation**, **reference ID**.
- **Disposition:** automatic vs **review** (single/multi-stage) and the named reviewer group.
- **Locations:** which workloads (Exchange / SPO / OneDrive / Groups / Teams).

Name every artifact now (Section 1 table) and record the **pilot scope** `Scope – Lifecycle-Pilot –
Static` (the bounded users/sites/mailboxes to prove on). **Pass/fail (Design gate):** every schedule
category maps to a named artifact with action, duration, trigger, record status, descriptors, disposition,
and locations; records/legal has signed off the mapping (especially any regulatory-record and event-based
categories).

## Stage 3 — Configure (build, staged safe)
Build in this order. **Configuration scripts default to `-WhatIf`/dry-run and only write with `-Commit`.**

### 3a. File plan descriptors (records reportability)
Create the file-plan descriptors the labels will reference so the records inventory is reportable from the
start (S&C PowerShell):
```powershell
New-FilePlanPropertyAuthority   -Name "Authority – Records-Schedule-2026"
New-FilePlanPropertyCategory    -Name "Contracts"
New-FilePlanPropertySubCategory -Name "Vendor-Contracts"
New-FilePlanPropertyCitation    -Name "SOX"      -CitationUrl "https://contoso.example/citations/sox"
New-FilePlanPropertyDepartment  -Name "Finance"
New-FilePlanPropertyReferenceId -Name "REC-CON-001"
```
*(Use the descriptor names your records schedule defines — the above are placeholders. `New-ComplianceTag
-FilePlanProperty` attaches these to a label; the config script builds this object for you.)*

### 3b. Event types (event-based retention)
For each event-based category, create the **event type** the label will use:
```powershell
New-ComplianceRetentionEventType -Name "Event Type – Employee-Termination"
New-ComplianceRetentionEventType -Name "Event Type – Contract-Expiration"
```
Record the operational process for **raising** the event (who, when, and the asset ID / keyword that will
match the affected content). The event itself is raised later (Stage 5 / operations), not at config time.

### 3c. Retention labels (records-grade categories)
Create the retention/record labels via **`Set-RetentionPolicyAndLabels.ps1`** (which wraps
`New-ComplianceTag` with `-WhatIf` default). Each label carries its action, duration, trigger, optional
records setting, file-plan descriptors, and — where reviewed — reviewer emails. Examples of the intent the
script commits with `-Commit`:
```powershell
# Plain retention label (date-based)
New-ComplianceTag -Name "Retention Label – General-3yr – Pilot" -RetentionAction Keep `
  -RetentionDuration 1095 -RetentionType ModificationAgeInDays

# Record label with disposition review (event-based, records-grade)
New-ComplianceTag -Name "Record Label – Contracts-7yr – Pilot" -IsRecordLabel $true `
  -RetentionAction KeepAndDelete -RetentionDuration 2555 -RetentionType EventAgeInDays `
  -EventType "Event Type – Contract-Expiration" -ReviewerEmail "records-reviewers@contoso.com" `
  -FilePlanProperty $filePlanObject

# Regulatory record label — ONE-WAY. Only where records/legal require; gated behind an explicit switch.
New-ComplianceTag -Name "Regulatory Record Label – Financial-7yr – Pilot" -Regulatory $true `
  -RetentionAction Keep -RetentionDuration 2555 -RetentionType CreationAgeInDays
```
> **Regulatory records are irreversible.** The config script refuses to set `-Regulatory` without an
> explicit confirmation switch and a records/legal sign-off reference. Do not apply regulatory labels in a
> pilot beyond a disposable test item.

### 3d. Retention policies (the tenant-wide floor)
Create the baseline retention policy **disabled**, with the in-scope locations, then attach its rule
(action + duration). `Set-RetentionPolicyAndLabels.ps1` stages this with `-WhatIf`; with `-Commit` it runs:
```powershell
New-RetentionCompliancePolicy -Name "Retention Policy – Tenant-Baseline – Pilot" -Enabled $false `
  -ExchangeLocation All -SharePointLocation All -OneDriveLocation All `
  -ModernGroupLocation All -TeamsChannelLocation All -TeamsChatLocation All
New-RetentionComplianceRule -Policy "Retention Policy – Tenant-Baseline – Pilot" `
  -RetentionComplianceAction Keep -RetentionDuration 1095 -RetentionDurationDisplayHint Days
```
For the pilot, scope the policy to the **pilot locations only** (specific mailboxes/sites) rather than
`All`, or use an **adaptive scope** limited to the pilot — created in **Data lifecycle management →
Adaptive scopes** and attached with `-AdaptiveScopeLocation`. **Leave `-Enabled $false` until validated.**

### 3e. Label policies (publish / auto-apply to the pilot)
Publish labels to the pilot users, or auto-apply by condition, scoped to the pilot:
```powershell
# Publish labels for users to apply (pilot scope)
New-RetentionCompliancePolicy -Name "Label Policy – User-Publish – Pilot" `
  -ExchangeLocation "pilotuser@contoso.com" -SharePointLocation "https://contoso.sharepoint.com/sites/LifecyclePilot"
New-RetentionComplianceRule -Policy "Label Policy – User-Publish – Pilot" `
  -PublishComplianceTag "Retention Label – General-3yr – Pilot"

# Auto-apply a label by condition (pilot scope) — condition from the schedule, not invented
New-RetentionCompliancePolicy -Name "Label Policy – Contracts-AutoApply – Pilot" `
  -SharePointLocation "https://contoso.sharepoint.com/sites/LifecyclePilot"
New-RetentionComplianceRule -Policy "Label Policy – Contracts-AutoApply – Pilot" `
  -ApplyComplianceTag "Record Label – Contracts-7yr – Pilot" -ContentMatchQuery '"master services agreement"'
```
*(SharePoint default-library-label application is deferred to the SharePoint records/retention product.)*

### 3f. Disposition reviewers
Ensure the named reviewer accounts are in the **Disposition Management** role group (2.3) so the labels'
`-ReviewerEmail` recipients can act on the Disposition queue in the portal. **Pass/fail (Configure gate):**
every designed artifact exists (labels, policies disabled, label policies pilot-scoped, event types, file
plan), reviewers are in Disposition Management, and no policy is enabled tenant-wide yet.

## Stage 4 — Pilot (prove on the bounded scope)
1. **Enable the pilot-scoped policy:** set `Retention Policy – Tenant-Baseline – Pilot` (scoped to pilot
   locations) `-Enabled $true`; confirm the label policies are published/auto-applying to the pilot only.
2. Apply/observe labels on pilot content: publish appears for pilot users; auto-apply matches; a record
   label **locks** a declared test item; an event-based label shows "retention starts on event".
3. Raise a **test retention event** for an event-based category on a disposable test asset:
   ```powershell
   New-ComplianceRetentionEvent -Name "TEST – Contract-Expiration – Pilot" `
     -EventType "Event Type – Contract-Expiration" -EventTags "Record Label – Contracts-7yr – Pilot" `
     -AssetId "TEST-ASSET-001"
   ```
4. Allow for **propagation** (hours to days — do not judge in minutes). Then run the Stage 5 validation.
5. **Pass/fail (Pilot gate):** on pilot content, policies and labels apply as designed, records lock,
   event-based retention triggers, and disposition-configured items are routed to review — all without
   affecting content outside the pilot scope.

## Stage 5 — Validate
Run **`Get-RetentionDispositionReport.ps1`** to produce `Lifecycle Compliance – Tenant – Report` and work
the Section 5 test procedures. Every gate has an explicit pass/fail. Do not expand until all pass.

## Stage 6 — Expand (enforce tenant-wide)
1. Mint the **production** artifacts by swapping `– Pilot` for `– Prod` (never edit a validated pilot
   artifact in place): e.g. `Retention Policy – Tenant-Baseline – Prod`, `Record Label – Contracts-7yr –
   Prod`, `Label Policy – User-Publish – Prod`.
2. Broaden locations to the full workloads (or attach **adaptive scopes** so policies track locations
   automatically), and enable under change control.
3. Stage the rollout in **rings** (e.g. by department/site) rather than a single tenant-wide flip where
   the schedule allows; re-run reporting after each ring.
4. **Pass/fail (Expand gate):** production policies/labels apply across the in-scope workloads, the
   compliance report shows expected coverage, disposition queues are populated for reviewed categories,
   and no unexpected retention conflicts appear.

---

## Rollback (per stage)
- **Retention/label policies (reversible):** disable the policy (`Set-RetentionCompliancePolicy -Enabled
  $false`) or reduce its locations; unpublish a label policy by disabling/removing its rule. Disabling a
  **retain-and-delete** policy stops future deletions from that policy.
- **Retention labels (reversible if not a record):** remove a non-record label from items and delete the
  unused label. A published label can be unpublished; auto-apply can be disabled.
- **Records (partly reversible):** a **non-regulatory** record can be **un-declared** by a records manager
  (auditable); this restores edit/delete. **Do this only per records/legal direction.**
- **IRREVERSIBLE — no rollback:** a **regulatory-record** label (cannot be removed/shortened), a
  **completed disposition** (content permanently deleted), and an **elapsed event-based deletion**. These
  are gated on records/legal sign-off and must never be exercised beyond a disposable test item in pilot.

Every production change carries a change ticket, an approver, and this rollback written out for the
specific categories in scope, with irreversible categories explicitly flagged **no-rollback**.


---


# 5. Testing & Validation

Ten procedures, each with an explicit **pass/fail**. Run them at the **Pilot** and **Expand** gates. Most
retention/records behavior is **eventually consistent** — allow for service propagation (hours to a few
days) before declaring a fail. Use the provided scripts where noted; never approve a real disposition or
apply a regulatory-record label to production content as a test.

---

### T1 — Toolchain & scope health
- **Do:** Run `Resolve-RetentionScope.ps1`.
- **Pass:** `Connect-IPPSSession` (and Graph where used) succeed; the correct cloud is reported; Data
  lifecycle management and Records management are reachable; the pilot scope resolves.
- **Fail:** any connection fails, the wrong cloud/endpoint is reported, or the scope does not resolve.

### T2 — Baseline inventory captured (read-only)
- **Do:** Run `Assess-RetentionRecordsPosture.ps1`.
- **Pass:** `Retention Posture – Tenant – Discovery` lists existing labels (with record/regulatory flags),
  policies + rules with locations/enabled state, event types, and file-plan descriptors; overlaps with any
  existing retention are identified.
- **Fail:** the inventory is incomplete, or the script wrote any change (it must be read-only).

### T3 — Retention labels created as designed
- **Do:** `Get-ComplianceTag` for each designed label.
- **Pass:** each label exists with the correct action, duration, retention type/trigger, record/regulatory
  flag, file-plan descriptors, and (where reviewed) reviewer emails — matching the Stage 2 design.
- **Fail:** any label is missing or its action/duration/trigger/record status differs from the design.

### T4 — Retention policy staged and pilot-scoped
- **Do:** `Get-RetentionCompliancePolicy` and `Get-RetentionComplianceRule` for `Retention Policy –
  Tenant-Baseline – Pilot`.
- **Pass:** the policy exists, its rule has the designed action/duration, and it is scoped to the **pilot
  locations** (or a pilot adaptive scope) — and was **disabled** until the pilot gate.
- **Fail:** the policy is enabled tenant-wide before validation, mis-scoped, or the rule differs from design.

### T5 — Label publish / auto-apply reaches the pilot
- **Do:** As a pilot user, confirm published labels are selectable (Outlook/SharePoint/OneDrive); create
  content matching an auto-apply condition and wait for propagation.
- **Pass:** published labels appear for pilot users only; auto-apply applies the designed label to matching
  pilot content; no content outside the pilot scope is affected.
- **Fail:** labels do not appear, apply to the wrong scope, or the wrong label is auto-applied.

### T6 — Records declaration locks content
- **Do:** Apply a record label to a disposable pilot test item; attempt to edit/delete/move it.
- **Pass:** the item is declared an in-place record and is locked against edit/delete/move per its rules,
  with a declare entry in the audit trail.
- **Fail:** the item remains editable/deletable, or no record was declared. *(Do not test regulatory
  records on any item you are not prepared to keep permanently.)*

### T7 — Event-based retention triggers
- **Do:** For an event-based label, raise a **test** retention event on a disposable asset
  (`New-ComplianceRetentionEvent … -AssetId TEST-ASSET-001`).
- **Pass:** the retention clock starts on the matching content when the event is raised (visible after
  propagation); before the event the item shows "retention starts on event".
- **Fail:** the clock never starts, or starts on the wrong content / at the wrong time.

### T8 — Disposition routes to review
- **Do:** For a category configured with reviewers, confirm the reviewer accounts are in **Disposition
  Management** and can see the Purview **Disposition** area; drive a short-duration disposable test label
  to expiry (or inspect the configuration).
- **Pass:** at end of retention, the item enters the Disposition queue and a named reviewer can approve
  deletion / extend / relabel; the decision is evidenced. Reviewers see only what their role allows.
- **Fail:** the item auto-deletes when a review was required, reviewers cannot see the queue, or no
  disposition record is kept.

### T9 — Retention precedence produces the intended effective outcome
- **Do:** On a pilot item touched by more than one policy/label, reason through Microsoft's precedence
  (retention > deletion; longest retention wins; explicit > implicit; shortest deletion wins) and confirm
  the observed outcome.
- **Pass:** the effective retention/deletion matches the intended design after precedence is applied.
- **Fail:** the effective outcome differs from intent (redesign the overlapping artifacts — do not force it).

### T10 — Compliance report reflects reality
- **Do:** Run `Get-RetentionDispositionReport.ps1` to produce `Lifecycle Compliance – Tenant – Report`.
- **Pass:** the report shows label coverage, policy locations/enabled state, records-configured counts, and
  pending-disposition pointers consistent with what was configured and observed in T3–T8.
- **Fail:** the report disagrees with observed state, or omits configured artifacts.

---

**Overall gate.** The pilot passes only when T1–T10 pass on the pilot scope with no effect outside it.
Expansion passes only when T3–T10 pass at production scope with expected coverage and no unexpected
retention conflicts. Any fail on an **irreversible** artifact (regulatory record, disposition) halts the
rollout pending records/legal review.


---


# 6. Troubleshooting

Common failure modes when implementing data lifecycle and records management org-wide in Microsoft
Purview, and how to resolve them. Most retention/records behavior is **eventually consistent** — before
treating something as broken, confirm it is not simply **propagation latency** (see the last item).
Portal paths and feature availability are **cloud-dependent** — verify in your tenant/cloud.

---

### Cannot connect / cmdlets missing
- **Symptom:** `Connect-IPPSSession` fails, or `Get-ComplianceTag` / `New-RetentionCompliancePolicy` /
  `New-FilePlanProperty*` / `New-ComplianceRetentionEventType` are "not recognized."
- **Likely cause:** Not connected to Security & Compliance PowerShell; the **ExchangeOnlineManagement**
  module is missing/old; or the session lacks the **Records management** scope/plan.
- **Resolve:** Install/update `ExchangeOnlineManagement`; run `Connect-IPPSSession` (with `-ConnectionUri`
  for GCC/GCC High/DoD). Run `Resolve-RetentionScope.ps1` to confirm connectivity, cloud, and reachable
  solutions. If records/file-plan/event cmdlets are absent, confirm the **E5/E5 Compliance-class**
  licensing and the **Records Management / Compliance Administrator** role.

### "Insufficient permissions" creating labels, policies, or the file plan
- **Symptom:** Access-denied on `New-ComplianceTag`, `New-RetentionCompliancePolicy`, or
  `New-FilePlanProperty*`.
- **Likely cause:** The admin is not in the required Purview role group.
- **Resolve:** Add the account to **Records Management** or **Compliance Administrator** /
  **Compliance Data Administrator** (Purview portal → Roles & scopes → Permissions). Reviewers need
  **Disposition Management**. Re-check with `Get-RoleGroupMember` / the portal after assignment
  (propagation can take time).

### A published retention label doesn't appear for users
- **Symptom:** Pilot users don't see the label in Outlook/SharePoint/OneDrive.
- **Likely cause:** Label-publish **propagation delay** (can take a day or more); the label policy's
  locations don't include the user; or the client hasn't refreshed.
- **Resolve:** Confirm the label policy (`Label Policy – User-Publish – Pilot`) targets the pilot
  user/site; allow up to a few days; have the user sign out/in. Verify with `Get-RetentionComplianceRule`
  that `PublishComplianceTag` names the correct label.

### Auto-apply isn't labeling matching content
- **Symptom:** Content that should match an auto-apply condition stays unlabeled.
- **Likely cause:** Auto-apply runs on a service timer and can take **7+ days** for existing content; the
  `ContentMatchQuery` / sensitive-info-type condition doesn't actually match; or the location isn't in
  scope; or the plan doesn't include auto-apply.
- **Resolve:** Confirm the condition against real content (test the KQL query), confirm the location is in
  the policy, confirm licensing, and **wait for the timer** before judging. Auto-apply of a records label
  is still subject to the same latency.

### A record label isn't locking content
- **Symptom:** After applying a record label, the item can still be edited/deleted.
- **Likely cause:** The label was created without `-IsRecordLabel $true`; propagation hasn't completed; or
  the label applied is a plain retention label, not the record label.
- **Resolve:** Verify with `Get-ComplianceTag` that `IsRecordLabel` is true; confirm the correct label was
  applied; allow for propagation. Remember a **regulatory** record is a stronger, one-way lock — don't
  confuse the two.

### Event-based retention clock never starts
- **Symptom:** Items with an event-based label stay in "retention starts on event" and never begin
  counting.
- **Likely cause:** No **retention event** was raised, the event's **asset ID / keyword** doesn't match
  the content, or the label's `EventType` differs from the event's type.
- **Resolve:** Raise the event with `New-ComplianceRetentionEvent` using the exact asset ID/keyword that
  matches the content and the same event type the label uses. Confirm the label's `RetentionType` is an
  `Event*` type and its `EventType` name matches. Allow for propagation after the event is raised.

### Disposition items never reach reviewers
- **Symptom:** Content expires but nothing appears in the Disposition queue, or reviewers can't see it.
- **Likely cause:** The label has no `ReviewerEmail`; reviewers aren't in **Disposition Management**; or
  retention hasn't actually elapsed yet.
- **Resolve:** Confirm the label's reviewers (`Get-ComplianceTag`), add the reviewer accounts to
  **Disposition Management**, and confirm the retention period has genuinely expired. Disposition is
  actioned in **Records management → Disposition** in the portal — the report script points there rather
  than approving disposals itself.

### Content is retained (or deleted) differently than expected — retention conflict
- **Symptom:** The effective retention/deletion on an item doesn't match a single policy or label you set.
- **Likely cause:** **Retention precedence** across overlapping policies/labels: retention wins over
  deletion; the **longest** retention wins; **explicit** (label) beats **implicit** (policy); the
  **shortest** deletion wins.
- **Resolve:** Enumerate every policy/label touching the content (`Assess-RetentionRecordsPosture.ps1`),
  reason through precedence, and **redesign** the overlapping artifacts to produce the intended effective
  outcome — do not try to force a result against the precedence rules.

### Government-cloud portal path or feature differs / is missing
- **Symptom:** A portal path from the guide 404s, an endpoint fails, or a feature isn't present in
  GCC/GCC High/DoD.
- **Likely cause:** Sovereign-cloud differences — different URLs (`*.office365.us`), different
  `Connect-IPPSSession -ConnectionUri`, and some features lag or are unavailable.
- **Resolve:** Use the correct sovereign endpoint and portal URL for your cloud, and **verify feature
  availability in your tenant** before relying on it. Treat any Commercial-vs-Government difference as a
  tenant-verify item, not an error.

### It "isn't working" — but it's actually propagation latency
- **Symptom:** A just-made change (policy enable, label publish, auto-apply, event, disposition) hasn't
  taken effect.
- **Likely cause:** Normal **eventual consistency** — application, label propagation, auto-apply, event
  processing, and disposition run on service timers (hours to several days; some policy application up to
  7 days).
- **Resolve:** Wait the expected window before re-testing; don't stack "fixes" on top of a change that
  simply hasn't propagated. Re-run `Get-RetentionDispositionReport.ps1` after the window to confirm state.


---


# 7. Best Practices

Durable practices for running data lifecycle and records management org-wide in Microsoft Purview. They
encode the house model — pilot-first, evidence-based, records/legal-owned determinations — into
day-to-day operation.

## Governance & ownership
- **Records/legal own the schedule; you own the implementation.** Never invent a retention period, record
  status, event trigger, or disposition rule. Treat the schedule as the source of truth and keep a
  traceable link from each Purview artifact back to its schedule category and regulatory citation (use
  file-plan descriptors for exactly this).
- **Keep a single label inventory.** One retention/record label per schedule category, named per the
  convention, reused across workloads and across the SharePoint records product — do not mint duplicate
  labels per workload.
- **Separate duties.** Records managers configure labels and the file plan; **Disposition Management**
  reviewers act on the queue and nothing else; workload admins apply where needed. Grant least privilege
  and review membership periodically.

## Policy vs label discipline
- **Use policies as the floor, labels for precision.** A tenant-wide retention **policy** is the safety
  net ("keep everything for at least N years"); reserve **labels** for records, event-based retention,
  disposition review, and file-plan reportability. Don't try to express records-grade behavior with a
  bare policy.
- **Design for retention precedence, then validate it.** Whenever policies and labels overlap, reason
  through precedence (retention > deletion; longest retention wins; explicit > implicit; shortest deletion
  wins) *and confirm the effective outcome on real content*. Precedence is a design input, not an
  afterthought.
- **Scope tightly, then widen.** Start policies on pilot locations or a pilot adaptive scope; expand to
  `All` or a production adaptive scope only after validation. Prefer **adaptive scopes** for production so
  coverage tracks the estate automatically.

## Records & the file plan
- **Reserve regulatory records for genuine legal mandates.** A regulatory-record label is **one-way** —
  it cannot be removed, changed, or shortened. Use it only where records/legal explicitly require, gate it
  behind an explicit sign-off, and never test it on content you are not prepared to keep forever.
- **Populate file-plan descriptors from day one.** Retention **authority**, **category**, **department**,
  **citation**, and **reference ID** make the records inventory reportable and defensible — fill them as
  you create labels, not later.
- **Communicate the lock before you apply it.** A record label removes edit/delete by design; tell content
  owners before declaring records in a live location.

## Event-based retention
- **Define the event source and the raise process.** An event type is only useful if someone/something
  reliably **raises** the event (with the asset ID / keyword that matches the content) when it happens.
  Document who raises `Employee-Termination` / `Contract-Expiration` events and integrate it with the
  system of record (HR/CLM) where possible.
- **Test events on disposable assets.** Prove the trigger and the resulting clock on a test asset before
  wiring the real process.

## Change-safety
- **Stage disabled, publish to pilot, then enforce.** Policies are created disabled; labels are published
  to the pilot scope; enforcement is a deliberate, change-controlled step after the gates pass.
- **Ring your rollout.** Expand by department/site/workload ring rather than a single tenant-wide flip;
  re-run the compliance report after each ring.
- **Write the rollback — and flag the irreversible parts.** Reversible: disable/unpublish policies and
  labels, remove non-record labels, un-declare non-regulatory records. **No-rollback:** regulatory
  records, completed disposition, elapsed event-based deletions. Every change ticket states which is which.

## Operations & evidence
- **Report on a cadence.** Run the compliance report regularly; watch label coverage, policy
  locations/enabled state, records counts, and pending-disposition backlog — a growing disposition backlog
  is an operational risk, not just a metric.
- **Work the disposition queue.** Reviewed disposition only stays defensible if reviewers actually act;
  monitor the backlog and reviewer coverage.
- **Respect eventual consistency.** Application, propagation, event processing, and disposition run on
  timers (hours to days). Build that latency into expectations and never judge a change in the first
  minutes.
- **Verify by cloud.** In GCC/GCC High/DoD, confirm portal paths, endpoints (`Connect-IPPSSession
  -ConnectionUri`), and feature availability — do not assume Commercial parity.
- **Keep automation credential-free.** All scripts use interactive modern auth; never embed secrets. Keep
  assessment/reporting read-only and configuration `-WhatIf`-by-default with an explicit `-Commit`.

## Alignment with the broader program
- **Don't rebuild what the program owns.** Sensitivity labels, DLP, and tenant-wide data governance belong
  to the broader Purview program — align to them, don't duplicate.
- **Defer SharePoint library mechanics.** Default library labels, in-place records inside libraries, and
  PnP-driven application are the SharePoint records/retention product's province — keep label names
  consistent and defer that mechanic rather than re-documenting it.


---


# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
- **Solution Overview** — what org-wide data lifecycle & records management is; the **retention policy
  vs retention label** distinction; how records declaration, the file plan, regulatory records,
  event-based retention, and disposition review work across Exchange/SharePoint/OneDrive/Teams;
  retention precedence; the reference design; what's deferred to records/legal, to the broader Purview
  program, and to the SharePoint records product; limitations; and the deployment model.
- **Requirements Guide** — solution-specific prerequisites (compliance licensing for records/advanced
  retention; the retention schedule from records/legal; lifecycle/records roles incl. Disposition
  Management; in-scope workloads; existing Purview posture; SharePoint mechanics referenced not rebuilt;
  the S&C PowerShell / Graph toolchain; change control + rollback), each with how to verify and
  implement, building on the Purview category global requirements.
- **Implementation Guide** — Assess → Design → Configure → Pilot → Validate → Expand, with every
  artifact named, file plan / event types / labels / policies / label policies / disposition built in
  order, policies staged **disabled** and labels published to the pilot scope, explicit pass/fail gates
  per stage, and a documented rollback that flags the **irreversible** parts (regulatory records,
  completed disposition, elapsed event deletions).
- **Testing & Validation** — 10 procedures, each with an explicit pass/fail, covering toolchain/scope,
  baseline inventory, labels, staged policy, publish/auto-apply, records lock, event-based trigger,
  disposition routing, retention precedence, and the compliance report.
- **Troubleshooting** — common failure modes (connection/roles/plan, labels/policies not appearing or
  applying, records not locking, events not triggering, disposition not routing, retention conflicts,
  Government-cloud paths, propagation latency) and resolutions.
- **Best Practices** — governance/ownership, policy-vs-label discipline, records & file plan,
  event-based retention, change-safety, operations & evidence, and alignment with the broader program.
- **Executive Summary** — the outcome, approach, and why it is low-risk, for decision-makers.

## PowerShell scripts (5)
All use modern-auth `Connect-IPPSSession` (Security & Compliance PowerShell) and `Connect-MgGraph` where
noted; **no hardcoded credentials**. Assessment and reporting are read-only; configuration scripts
default to dry-run / `-WhatIf` and only write when `-Commit` is passed; regulatory-record actions are
gated behind an explicit `-AllowRegulatory -SignOffRef`.

1. **`Resolve-RetentionScope.ps1`** — *Scope/health helper (read-only).* Checks S&C PowerShell (and
   optional Graph) connectivity, reports the detected cloud/endpoint, confirms Data lifecycle / Records
   management cmdlets are reachable, and resolves the pilot scope — the preflight before Stage 3.
2. **`Assess-RetentionRecordsPosture.ps1`** — *Discovery (read-only).* Inventories existing retention
   labels (record/regulatory flags), retention policies + rules with **workload locations and enabled
   state**, event types, and file-plan descriptors; flags overlaps for retention-precedence review.
   Produces `Retention Posture – Tenant – Discovery` (CSVs).
3. **`Set-RetentionPolicyAndLabels.ps1`** — *Retention-policy + label config helper (`-WhatIf`
   default).* Creates/verifies retention **labels** (`New-ComplianceTag`) and a tenant/pilot retention
   **policy + rule** (`New-RetentionCompliancePolicy`/`-Rule`) from a JSON design; policies are created
   **disabled** and label policies scoped to pilot locations. Dry-run by default; writes with `-Commit`;
   refuses regulatory labels without `-AllowRegulatory -SignOffRef`.
4. **`Set-RecordsFilePlanDisposition.ps1`** — *Records/file-plan/event/disposition config helper
   (`-WhatIf` default).* Creates/verifies **file-plan descriptors** (`New-FilePlanProperty*`) and
   **event types** (`New-ComplianceRetentionEventType`), and validates records/disposition wiring
   (record/regulatory labels and reviewer emails, plus the Disposition Management reminder). Dry-run by
   default; writes with `-Commit`.
5. **`Get-RetentionDispositionReport.ps1`** — *Retention/disposition compliance report (read-only).*
   Compiles label coverage (record/regulatory/event/reviewed/file-plan), policy locations + enabled
   state, and event-type counts into `Lifecycle Compliance – Tenant – Report` (CSV + HTML), flagging
   gaps and pointing reviewers to the portal Disposition queue.
