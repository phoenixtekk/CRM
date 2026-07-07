# SharePoint Online Records, Retention & Information Governance

> **Version 1.0.0** · Category: SharePoint · Solution code: SPORECS

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

SharePoint Online holds content the organization is obligated to **retain** and then **dispose** of on
schedule. When that obligation is unenforced, the content becomes liability: over-retained data
inflates breach and eDiscovery exposure, under-retained data breaks a regulatory or legal obligation,
and content that is never reviewed accumulates indefinitely. This solution applies **records and
retention governance to SharePoint content** so it is retained, declared, and disposed on schedule —
labels and policies applied, records declared and locked in place, and disposition made defensible.

**Outcome.** Retention labels and policies applied to SharePoint sites and libraries; records declared
as in-place records (locked against premature edit or deletion); a working disposition-review workflow
where a named reviewer approves disposal, and Microsoft Purview keeps proof of what was disposed, by
whom, and when. Ungoverned content becomes governed records — retained and disposed on schedule.

**Approach.** The work is **scoped to SharePoint content and aligned to the organization's broader
Microsoft Purview program** — it reuses that program's foundations rather than rebuilding DLP,
sensitivity labels, or tenant-wide strategy. It implements the **records/retention schedule provided by
records, compliance, and legal**; it does not author retention periods or make legal determinations.
Delivery follows a disciplined, pilot-first model — **Assess → Design → Configure → Pilot → Validate →
Expand** — with the records/retention schedule mapped to retention and record labels, applied first to
a bounded pilot site set, validated against explicit pass/fail gates, and only then expanded
tenant-wide with adaptive scopes. Five PowerShell tools (Security & Compliance PowerShell and PnP)
handle assessment, label/policy application, records/disposition configuration, compliance reporting,
and scope/health — read-only or dry-run (`-WhatIf`) by default, with no credentials in code.

**Why it is low-risk.** Tenant-wide retention and records declaration are high-impact, so nothing
touches production content until it is proven on a pilot. Assessment is read-only; configuration is
staged disabled and dry-run before it is enabled; every change has a documented rollback, and the
**irreversible** actions (regulatory records, completed disposition) are explicitly flagged as
no-rollback and gated on records/legal sign-off. Plan- and cloud-dependent behavior (advanced records
features, Government-cloud portal paths) is flagged for tenant verification rather than assumed. The
result: SharePoint content governed on schedule, with the liability of ungoverned content turned into
defensible, evidenced records.


---


# 1. Solution Overview — SharePoint Online Records, Retention & Information Governance

## What this solution is
SharePoint Online holds a growing mass of content — contracts, financial records, policies, project
files, HR documents — that the organization is obligated to **retain** for a defined period and then
**dispose** of on schedule. When neither happens, the content becomes liability: over-retained data
inflates eDiscovery and breach exposure, under-retained data breaks a regulatory or legal obligation,
and content that is never reviewed for disposal accumulates indefinitely. This solution is a
repeatable, pilot-first method to apply **records and retention governance to SharePoint content**:
create retention labels and policies, apply them to sites and libraries, declare records (in-place),
run the disposition-review workflow, and dispose defensibly — so SharePoint content is retained,
declared, and disposed on schedule.

It is **scoped to SharePoint Online content** and **aligned to the broader Microsoft Purview
program**, not a replacement for it. Data Loss Prevention, sensitivity (information-protection)
labels, Exchange/Teams retention, insider-risk, and the tenant-wide Purview data-governance strategy
are the province of the organization's overall Purview product/program; this solution reuses that
program's foundations and focuses the records/retention mechanics on SharePoint sites and libraries.

## What this solution is NOT (the deferred boundary)
- **The records schedule itself is not authored here.** *Which* content is a record, *how long* each
  category is retained, the retention **trigger**, and the disposition **authority** are determined by
  the organization's **records-management, compliance, and legal** functions. This solution takes that
  schedule as input and implements it faithfully in SharePoint; it does not invent retention periods
  or legal determinations.
- **Legal holds and eDiscovery determinations** (what to preserve for a matter, when a hold attaches
  or releases) belong to legal/eDiscovery, not to this records/retention configuration.
- **DLP, sensitivity labels, and the broader Purview program** are referenced, not re-built here.

## Why this matters
- Retention that lives only in a policy binder is not enforced. A retention **label** and **policy**
  in Microsoft Purview, applied to SharePoint content, is enforcement the platform executes.
- A **record label** locks content in place (in-place records) so it cannot be edited or deleted
  before its schedule allows — the defensibility a regulator or auditor expects.
- **Disposition review** turns "delete on expiry" into a governed, evidenced decision: a named
  reviewer approves disposal (or extends/relabels), and Microsoft Purview keeps proof of what was
  disposed, by whom, and when.
- Doing this **pilot-first**, on a bounded site set with explicit gates and a rollback, avoids the
  high-impact failure mode of a tenant-wide retention or records misconfiguration that locks or
  deletes content wrongly.

## How it works
1. **Retention labels** are created in Microsoft Purview (Records management → File plan). A label
   carries a **retention action** (retain, delete, or retain-then-delete), a **duration**, a
   **retention trigger** (when the clock starts: item created, last modified, labeled, or an event),
   and optionally a **records** setting (mark as record or regulatory record) and a **disposition
   review** with named reviewers.
2. **Retention policies** apply a retention **outcome** to whole SharePoint locations (all sites, or
   specific sites) without a per-item label — the tenant-wide safety net. **Label policies** publish
   labels so users/owners can apply them, or **auto-apply policies** apply a label automatically to
   content that matches a condition (keyword, sensitive-info type, or trainable classifier).
3. **Application to SharePoint** happens three ways: a **default library label** (every item in a
   document library inherits the label), a **published label** applied by content owners, or an
   **auto-apply** policy. A default label is the workhorse for library-scoped records.
4. **Records declaration** happens when a **record** (or regulatory record) label is applied:
   SharePoint declares the item an **in-place record** — it stays in its library but is locked against
   edit/delete/move per the record's version and rules, with an auditable declare/undeclare trail.
5. **Disposition review** runs at the end of the retention period for any label configured with
   reviewers: the item enters the **Disposition** queue in Microsoft Purview, a reviewer approves
   permanent deletion, extends retention, applies a different label, or relabels — and the decision is
   evidenced.
6. **Defensible disposition** is the outcome: content is disposed only after its schedule expires and
   (where required) a review is approved, and Microsoft Purview retains a **disposition record** as
   proof.
7. The whole configuration is delivered through the house model — **Assess → Design → Configure →
   Pilot → Validate → Expand** — so the retention/records schedule is proven on a pilot site set
   before it is expanded tenant-wide.

## The reference design
- **Inputs (from records/legal):** the records/retention schedule — categories, retention periods,
  triggers, record vs non-record, disposition authority.
- **Labels:** one retention/record label per schedule category, named consistently, imported with
  **file-plan descriptors** (retention authority, category, sub-category) so the file plan is
  reportable.
- **Policies:** a tenant-wide **retention policy** as the baseline safety net for all SharePoint
  sites; **auto-apply** or **default-library-label** application for the record categories; a
  **published label policy** where owners apply labels manually.
- **Scopes:** **static** scopes (named sites) for the pilot; **adaptive** scopes (query-driven) as an
  option for expansion so the policy tracks sites automatically. *Adaptive scopes and some records
  features are plan-dependent — verify your licensing in your tenant.*
- **Records:** record or regulatory-record labels for the categories records/legal designate;
  in-place records so content is governed without moving it to a separate records center.
- **Disposition:** single- or multi-stage disposition review with named reviewer groups for the
  categories that require a human approval before disposal.

## What you can control
- Which SharePoint sites and libraries are in scope (start with the pilot site set).
- Which schedule categories become labels, and whether each is a plain retention label, a **record**,
  or a **regulatory record** (regulatory records cannot be unlocked — use only where records/legal
  require it).
- How labels are applied: default library label, published for manual apply, or auto-apply by
  condition.
- Whether a category ends in automatic disposal or **disposition review**, and who the reviewers are.
- The pilot scope, the pass/fail gates, and the rollback — before any tenant-wide expansion.

## Limitations (be honest with buyers)
- **Advanced records/retention features are plan-dependent.** Auto-apply policies, adaptive scopes,
  regulatory records, event-based retention, multi-stage disposition review, and the records-
  management file plan generally require the appropriate compliance licensing (commonly an E5/E5
  Compliance-class plan or add-on) — **verify what your tenant is licensed for in your tenant.**
- **Retention and deletion are eventually consistent, not instant.** Labels, policy application, and
  disposition run on service timers; expect propagation delays (often hours to a few days) — do not
  judge a pilot on the first minutes.
- **Regulatory records are one-way.** A regulatory-record label cannot be removed or changed and its
  retention cannot be shortened. Use it only where records/legal explicitly require it.
- **A record label locks content.** Owners lose edit/delete on declared items by design; communicate
  this before applying record labels to a live library.
- **Principle of retention precedence still applies.** When multiple retention outcomes touch the same
  content, Microsoft's retention-conflict rules (retention wins over deletion; longest wins; explicit
  over policy; shortest deletion wins) decide the result — design labels/policies with this in mind
  and validate the effective outcome, don't assume.
- **Commercial vs Government cloud paths differ.** Portal URLs and some feature availability differ in
  GCC/GCC High/DoD (e.g. `*.office365.us`) — **verify the portal path and feature in your cloud.**

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and the Purview/SharePoint admin surfaces. The standard set:

| Artifact | Name |
|---|---|
| Retention label (general category) | `Retention Label – General-3yr – Pilot` |
| Record label (record category) | `Record Label – Contracts – Pilot` |
| Regulatory record label (where required) | `Regulatory Record Label – Financial-7yr – Pilot` |
| Tenant-wide baseline retention policy | `Retention Policy – SPO-Baseline – Pilot` |
| Auto-apply label policy | `Label Policy – Contracts-AutoApply – Pilot` |
| Published label policy (manual apply) | `Label Policy – Owner-Publish – Pilot` |
| Pilot site scope (static) | `Scope – Records-Pilot – Static` |
| Adaptive scope (expansion) | `Scope – Records-Prod – Adaptive` |
| Disposition reviewer group (stage 1) | `Disposition Reviewers – Records – Stage1` |
| Assessment export | `Retention Posture – SPO – Discovery` |
| Compliance report | `Records Compliance – SPO – Report` |

When the pilot passes and you expand to production, mint the production equivalents by swapping the
`– Pilot` stage for `– Prod` (e.g. `Record Label – Contracts – Prod`) — never edit a validated pilot
artifact in place.

## The standard deployment model
> **Assess** current SharePoint retention/records posture and ingest the records schedule → **Design**
> the label/policy/scope map → **Configure** labels, policies, records, and disposition → **Pilot** on
> `Scope – Records-Pilot – Static` → **Validate** against explicit pass/fail gates → **Expand**
> tenant-wide with adaptive scopes.

Tenant-wide retention, records declaration, and disposition are **high-impact** — a wrong retention
period, an over-broad auto-apply, or a mistaken regulatory-record label is expensive or irreversible.
Every production change goes through change control with a documented rollback, and nothing expands
past the pilot until the gates in Section 5 pass.


---


# 2. Requirements

These are the **solution-specific** prerequisites for applying records, retention, and information
governance to SharePoint Online content. They build **on** the shared SharePoint category
requirements in **`global-requirements-sharepoint.md`** (M365 tenant + SharePoint/OneDrive licensing;
least-privilege SharePoint admin access; the SPO Management Shell / PnP / Graph toolchain; the
information-architecture and identity/group source of truth; a pilot scope and change control; and the
security/compliance/records stakeholders). Do not repeat those — verify them first, then confirm the
records/retention-specific prerequisites below. Each is stated as **Description / Why / Verify /
Implement if missing.**

---

## 2.1 Compliance licensing for records & advanced retention
- **Description:** The Microsoft 365 / Microsoft Purview licensing that unlocks the records and
  retention features this solution uses — retention labels and policies, **records management** (record
  and regulatory-record labels, file plan), **auto-apply** policies, **adaptive scopes**, **event-based
  retention**, and **disposition review**. These are generally in an E5 / E5 Compliance-class plan or
  the equivalent Purview add-on.
- **Why required:** Basic retention policies exist broadly, but records declaration, auto-apply,
  adaptive scopes, and disposition review are **plan-dependent** — without the right plan the labels
  and policies in the design cannot be created.
- **Verify:** In the Microsoft 365 admin center → Billing → Licenses, confirm the compliance plan/
  add-on. In the Microsoft Purview portal, confirm **Records management** and **Data lifecycle
  management** solutions are available. *Feature-to-plan mapping changes — verify the exact entitlement
  in your tenant.*
- **Implement if missing:** Have licensing assign/purchase the required compliance plan or add-on to
  the admin and any accounts that will manage records, before configuration.

## 2.2 The records / retention schedule (input from records & legal)
- **Description:** The authoritative **records/retention schedule** for SharePoint content: the
  categories, each category's **retention period**, its **trigger** (created / last-modified / labeled
  / event-based), whether it is a **record** or **regulatory record**, and the **disposition
  authority** (automatic vs review, and who reviews).
- **Why required:** This solution **implements** the schedule; it does not author it. Labels and
  policies are a direct translation of the schedule. Without it there is nothing correct to configure.
- **Verify:** Confirm records/legal has provided (or signed off) a schedule that names each category,
  period, trigger, record status, and disposition path.
- **Implement if missing:** This is **deferred to the records-management / compliance / legal
  functions** — request the schedule (or a pilot subset of categories) before configuring. Do not
  invent retention periods, record status, or disposition rules.

## 2.3 Roles for records & retention management
- **Description:** The least-privilege roles to create and manage retention/records: **Records
  Management** or **Compliance Administrator** / **Compliance Data Administrator** role group in
  Microsoft Purview for labels/policies/file plan, plus **Disposition Management** for reviewers, and
  **SharePoint Administrator** for site/library-level application. (Assigned via role groups in the
  Purview portal / Entra roles.)
- **Why required:** Creating labels, publishing/auto-applying policies, configuring records, and acting
  on disposition each require the corresponding Purview role; applying default library labels at the
  site requires SharePoint admin/site rights.
- **Verify:** In the Microsoft Purview portal → Roles & scopes → Permissions (role groups), confirm the
  admin's membership; confirm reviewers are in **Disposition Management**.
- **Implement if missing:** Have a Global Admin / Compliance Admin add the accounts to the least-
  privilege role groups under change control. Grant **Disposition Management** only to the named
  reviewer accounts.

## 2.4 Existing Purview program posture (alignment, not duplication)
- **Description:** Knowledge of the organization's **existing Microsoft Purview posture** — sensitivity
  (information-protection) labels, DLP policies, existing retention labels/policies, and any
  tenant-wide retention already in force — so this SharePoint records/retention work **aligns** to it
  rather than conflicting or duplicating.
- **Why required:** Retention outcomes interact via Microsoft's retention-precedence rules; an
  unaware new policy can conflict with an existing one. Sensitivity labels and DLP are owned by the
  broader Purview program and must not be re-implemented here.
- **Verify:** Enumerate existing labels/policies (`Get-ComplianceTag`, `Get-RetentionCompliancePolicy`)
  and confirm which are owned by the broader program. Confirm no conflicting SharePoint-scoped
  retention already exists for the pilot sites.
- **Implement if missing:** Engage the Purview program owners; capture the existing baseline (the
  assessment script does this) before adding labels/policies.

## 2.5 A pilot SharePoint site set with representative content
- **Description:** A bounded set of SharePoint sites/libraries — `Scope – Records-Pilot – Static` —
  containing content representative of the schedule categories (e.g. a contracts library, a finance
  library), on which to prove the configuration before tenant-wide expansion.
- **Why required:** Records declaration and disposition are high-impact and partly irreversible
  (regulatory records especially). The pilot proves the label→apply→declare→dispose chain on real,
  bounded content with a rollback available.
- **Verify:** Confirm the named pilot sites exist, their owners are informed, and the content maps to
  the pilot's schedule categories.
- **Implement if missing:** Stand up or nominate pilot sites and confirm owner awareness (a record
  label will lock content) before applying anything.

## 2.6 SharePoint records/retention automation toolchain
- **Description:** On top of the category toolchain (SPO Management Shell / PnP / Graph), the
  **Security & Compliance PowerShell** endpoint (`Connect-IPPSSession` from the Exchange Online
  Management module) for retention labels/policies and records cmdlets (`Get-ComplianceTag`,
  `New-RetentionCompliancePolicy`, etc.), and **PnP PowerShell** for applying default library labels
  (`Get-PnPLabel` / `Set-PnPLabel`).
- **Why required:** The provided scripts and the configuration steps use Security & Compliance
  PowerShell for labels/policies/records and PnP for library-level label application; both are needed.
- **Verify:** `Connect-IPPSSession` and `Connect-PnPOnline` both succeed with the admin's modern-auth
  (MFA) sign-in; `Get-ComplianceTag` and `Get-PnPLabel` return without error.
- **Implement if missing:** Install the **ExchangeOnlineManagement** and **PnP.PowerShell** modules,
  register the PnP Entra app registration where interactive/app auth requires it, and confirm both
  connections. Never store credentials in scripts.

## 2.7 Change control and a documented rollback for records/retention
- **Description:** An approved change window and a **rollback plan** specific to retention/records:
  how to remove a default library label, unpublish/disable a policy, and (for non-regulatory records)
  how content is unlocked — plus the explicit note that **regulatory records and elapsed disposition
  cannot be rolled back**.
- **Why required:** Tenant-wide retention and records declaration are high-impact; a documented,
  rehearsed rollback is the safety net for the reversible parts and forces a conscious decision on the
  irreversible parts.
- **Verify:** Confirm a change ticket, an approver, and a written rollback covering label removal,
  policy disable, and record un-declaration for the pilot categories.
- **Implement if missing:** Author the rollback (Section 3 provides the steps), get change-control
  sign-off, and explicitly flag any regulatory-record category as **no-rollback** before applying it.


---


# Global Requirements — SharePoint Online & OneDrive Solutions

These requirements apply to **every** solution in the **SharePoint** category (SharePoint Online
architecture & provisioning, external sharing, OneDrive for Business, migration to SPO, permissions,
search, and records/retention). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every SharePoint solution).** The **SharePoint admin center**, the
> **Microsoft 365 admin center**, the **SharePoint Online Management Shell** and **PnP PowerShell**,
> and **Microsoft Graph** are authored at exact, current click-by-click / cmdlet detail from Microsoft's
> public documentation. Where a capability, setting, or portal path is **plan- or version-dependent**
> (storage limits, sharing controls, Syntex/records features, Commercial vs Government cloud), it is
> **cited or flagged "verify in your tenant"** — never invented. **Third-party migration and governance
> tools** (e.g. ShareGate, Migration Manager, AvePoint) are integrated at the pattern level; their
> consoles are deferred to the vendor's docs. Automation is **PowerShell** (SPO Management Shell / PnP /
> Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with SharePoint Online / OneDrive and licensing
- **Description:** A Microsoft 365 tenant with **SharePoint Online** and **OneDrive for Business** and
  the licensing the capability requires (e.g. an E-plan for advanced records/retention, Syntex where used).
- **Why required:** All site, sharing, OneDrive, and records configuration depends on the right plan.
- **How to verify:** In the M365 admin center confirm the SharePoint/OneDrive subscription and add-ons.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Administrative access (least-privilege SharePoint roles)
- **Description:** Access with the least-privilege role the solution names — typically **SharePoint
  Administrator** (and Global Administrator only where genuinely required, e.g. tenant-wide sharing).
- **Why required:** Tenant/site settings, sharing, provisioning, and records changes require the role.
- **How to verify:** Confirm the role in the M365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. SharePoint Online Management Shell / PnP + Graph toolchain
- **Description:** A workstation with the **SharePoint Online Management Shell** and/or **PnP
  PowerShell** (and Graph PowerShell where used), modern-auth / MFA-capable admin sign-in (PnP app
  registration where required).
- **Why required:** Configuration, automation, and the provided scripts run through SPO/PnP/Graph.
- **How to verify:** `Connect-SPOService` / `Connect-PnPOnline` succeeds; modules installed.
- **How to implement if missing:** Install the modules; register the PnP app where needed; confirm sign-in.

## 4. Information architecture & identity/group source of truth
- **Description:** A defined **information-architecture** intent (hub/site structure, taxonomy) and the
  identity/group source (Entra ID groups, M365 Groups backing team sites) that drives access.
- **Why required:** Provisioning, permissions, search, and governance key off the IA and groups.
- **How to verify:** Confirm the intended hub/site structure and which groups model is authoritative.
- **How to implement if missing:** Define the IA and group model (often the Architecture solution) first.

## 5. A pilot scope and change control
- **Description:** A **pilot site collection / hub / user set** to validate on before tenant-wide
  rollout, and a **change-control** process for production changes (sharing, permissions, retention,
  migration cutover are high-impact).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; tenant-wide sharing/permission/retention changes are high-impact.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Create a pilot scope and agree change control before production changes.

## 6. Security, compliance & records stakeholders
- **Description:** Engagement with the **security, compliance/records, and data-governance** stakeholders
  whose policies the configuration must satisfy (external sharing, permissions, retention/records,
  sensitivity).
- **Why required:** Sharing, permission, and records settings must align to enterprise policy.
- **How to verify:** Confirm the applicable policies and named approvers.
- **How to implement if missing:** Identify the owners and capture requirements before configuring governance.

*The deployment model across every SharePoint solution is the same: **Assess → Design → Configure →
Pilot → Validate → Expand**, with explicit pass/fail gates and a documented rollback for production
changes. Automation is delivered as **PowerShell** (SPO Management Shell / PnP / Graph) — never with
hardcoded credentials or secrets in code.*


---


# 3. Implementation

Follow the house model — **Assess → Design → Configure → Pilot → Validate → Expand** — in order. Every
artifact is named per the convention in Section 1 and reused verbatim. Do not expand past the pilot
until the gates in Section 5 pass. Portal paths are given for the **Microsoft Purview portal**
(`purview.microsoft.com`); some tenants still use the classic **Microsoft Purview compliance portal**
(`compliance.microsoft.com`), and **Government clouds use different URLs (e.g. `*.office365.us`) —
verify the portal path in your cloud.** PowerShell is **Security & Compliance PowerShell**
(`Connect-IPPSSession`) for labels/policies/records and **PnP PowerShell** for library-level
application.

> **Safety posture.** Read-only assessment first. Every configuration script defaults to a dry-run /
> `-WhatIf` and only writes when `-Commit` is passed. Regulatory records and elapsed disposition are
> **irreversible** — treat them as no-rollback.

---

## Stage 0 — Connect and confirm scope

1. Connect the toolchain with modern auth (no stored credentials):
   ```powershell
   Connect-IPPSSession -UserPrincipalName admin@contoso.onmicrosoft.com   # Security & Compliance PowerShell
   Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/RecordsPilot -Interactive
   ```
   *For Government clouds pass the appropriate `-ConnectionUri` / `-AzureADAuthorizationEndpointUri`
   (S&C) and `-AzureEnvironment` (PnP) — verify the endpoints for your cloud.*
2. Confirm the pilot scope `Scope – Records-Pilot – Static` exists (the named pilot sites/libraries)
   and that owners know a record label will lock content.

**Gate 0 (pass/fail):** both connections succeed and the pilot sites resolve. If either fails, stop and
fix the toolchain/roles (Section 2) before continuing.

---

## Stage 1 — Assess (read-only)

1. **Baseline the existing Purview posture.** Enumerate what already exists so the new design aligns
   and does not conflict:
   ```powershell
   Get-ComplianceTag | Select-Object Name,IsRecordLabel,Regulatory,RetentionAction,RetentionDuration
   Get-RetentionCompliancePolicy | Select-Object Name,Enabled,Mode,SharePointLocation
   ```
2. **Assess the SharePoint content posture** with the discovery script:
   ```powershell
   .\Assess-SpoRetentionPosture.ps1 -Sites @("https://contoso.sharepoint.com/sites/RecordsPilot") -OutputPath .\out
   ```
   It enumerates the pilot sites' document libraries, reads the **default retention label** on each
   library (`Get-PnPLabel`), counts items with/without a label, and cross-references existing tenant
   labels/policies — writing `Retention Posture – SPO – Discovery` (CSV).
3. **Reconcile against the schedule.** Line the discovery output up against the records/legal schedule
   (Requirement 2.2): which categories exist as content in the pilot, which have no label yet, and
   which sites overlap existing retention.

**Gate 1 (pass/fail):** the pilot content is inventoried, the existing Purview baseline is captured,
and every pilot schedule category maps to real content. If a category has no representative content in
the pilot, either add a pilot library for it or descope it for now.

---

## Stage 2 — Design (map the schedule to labels, policies, and scopes)

Design on paper (or in the design workbook) before configuring. Produce three maps:

1. **Label map** — one **retention label** per schedule category. For each, record from the schedule:
   retention **action** (Retain / Delete / Retain-then-delete), **duration**, **trigger**
   (`CreationAgeInDays` / `ModificationAgeInDays` / `TaggedAgeInDays` / `EventAgeInDays`), **record
   status** (none / record / regulatory record), and **disposition** (automatic / review + reviewers).
   Name each per convention, e.g.:
   - `Retention Label – General-3yr – Pilot` (Delete after 3y from creation, no record)
   - `Record Label – Contracts – Pilot` (Retain 6y from event, record, disposition review)
   - `Regulatory Record Label – Financial-7yr – Pilot` (Retain-then-delete 7y, **regulatory record** —
     only if records/legal require the irreversible lock)
2. **Policy / application map** — how each label reaches content:
   - `Retention Policy – SPO-Baseline – Pilot` — a location-based **retention policy** on the pilot
     sites as the safety net (retain-only baseline; never a tenant-wide delete in a pilot).
   - `Label Policy – Contracts-AutoApply – Pilot` — **auto-apply** the contracts label by condition
     (keyword / sensitive-info type / trainable classifier) where the schedule allows automatic
     classification.
   - **Default library label** — for a library whose entire contents are one category (e.g. a
     contracts library), set the label as the library default so every item inherits it.
   - `Label Policy – Owner-Publish – Pilot` — **publish** labels so owners can apply them manually
     where classification must be human.
3. **Scope map** — pilot uses **static** scopes (`Scope – Records-Pilot – Static`, the named sites).
   Design the **adaptive** scope `Scope – Records-Prod – Adaptive` (a site query, e.g. by site
   property/URL) for expansion, but do not attach it until Stage 6.

**Gate 2 (pass/fail):** every schedule category has exactly one designed label with action, duration,
trigger, record status, and disposition specified; each label has a designated application method; and
the retention-precedence interaction with existing policies (Requirement 2.4) has been checked. Get
records/legal sign-off on the label map before configuring.

---

## Stage 3 — Configure (labels, policies, records, disposition)

Create everything in a **disabled / unpublished / dry-run** posture first; nothing applies to content
until Stage 4 (Pilot).

### 3a. Create the retention & record labels
Create labels in the portal (**Purview → Records management → File plan → Create a label**, or **Data
lifecycle management → Retention labels**) or via PowerShell. Import **file-plan descriptors**
(retention authority, category, sub-category) so the file plan is reportable. Examples:

```powershell
# General retention label (no record) — delete 3 years after creation
New-ComplianceTag -Name "Retention Label – General-3yr – Pilot" `
  -RetentionAction Delete -RetentionDuration 1095 -RetentionType CreationAgeInDays `
  -Comment "Delete 3y from creation. Category from records schedule."

# Record label — retain 6y, mark as record, route to disposition review
New-ComplianceTag -Name "Record Label – Contracts – Pilot" `
  -RetentionAction Keep -RetentionDuration 2190 -RetentionType TaggedAgeInDays `
  -IsRecordLabel $true -ReviewerEmail @("dispositionreviewers@contoso.com") `
  -Comment "Contracts. Record. Disposition review at end of retention."
```
- `-IsRecordLabel $true` makes the label declare content a **record** (in-place record, locked).
- `-Regulatory $true` makes it a **regulatory record** — **irreversible**; use only where records/legal
  require it, and never in a reversible pilot unless explicitly approved.
- `-ReviewerEmail` routes the label to **disposition review** at end of retention (the reviewers are
  the `Disposition Reviewers – Records – Stage1` group). *Multi-stage review and event-based retention
  are plan-dependent — verify in your tenant.*
- The `Set-SpoRecordsDisposition.ps1` helper builds/validates the record + disposition configuration
  and defaults to `-WhatIf`.

### 3b. Configure the disposition reviewers
1. In **Purview → Roles & scopes → Permissions**, ensure the reviewer accounts are in the
   **Disposition Management** role group — this is what lets `dispositionreviewers@contoso.com` see the
   disposition queue.
2. Confirm each record/label that ends in review names the correct reviewer group; single-stage for the
   pilot, multi-stage only where the schedule requires it.

### 3c. Create the retention policies (disabled)
```powershell
# Location-based baseline safety net on the pilot sites — retain-only, created disabled
New-RetentionCompliancePolicy -Name "Retention Policy – SPO-Baseline – Pilot" `
  -SharePointLocation "https://contoso.sharepoint.com/sites/RecordsPilot" -Enabled $false
New-RetentionComplianceRule -Policy "Retention Policy – SPO-Baseline – Pilot" `
  -RetentionComplianceAction Keep -RetentionDuration Unlimited
```
- Create it **`-Enabled $false`**; you enable it in Stage 4.
- For **auto-apply**, create `Label Policy – Contracts-AutoApply – Pilot` similarly (a retention policy
  whose rule uses `-ApplyComplianceTag "Record Label – Contracts – Pilot"` with a match condition),
  disabled, then enable in the pilot. The `Apply-SpoRetentionLabels.ps1` helper builds these and
  defaults to `-WhatIf`; pass `-Commit` only under change control.

### 3d. Set default library labels (do not apply yet)
For a single-category library, plan the **default label** application; the helper stages it and only
writes with `-Commit`:
```powershell
Set-PnPLabel -List "Documents" -Label "Record Label – Contracts – Pilot" -SyncToItems $true
```
Stage this command for the pilot library but hold it until Stage 4.

**Gate 3 (pass/fail):** all designed labels exist; policies exist **disabled/unpublished**; reviewers
are in Disposition Management; no content has been affected yet. Verify with `Get-ComplianceTag` and
`Get-RetentionCompliancePolicy` (Enabled = False).

---

## Stage 4 — Pilot (apply to `Scope – Records-Pilot – Static` only)

Apply to the pilot sites only, one change at a time, watching each propagate before the next.

1. **Publish/enable manual labels first** (lowest impact): enable `Label Policy – Owner-Publish – Pilot`
   so pilot owners can apply labels; confirm the labels appear in the pilot library's **Apply label**
   column after propagation (can take up to a day).
2. **Set the default library label** on the pilot single-category library:
   ```powershell
   Set-PnPLabel -List "Documents" -Label "Record Label – Contracts – Pilot" -SyncToItems $true
   ```
   New and existing items inherit the label; record items become **in-place records** (locked).
3. **Enable the baseline retention policy** and any auto-apply policy on the pilot:
   ```powershell
   Set-RetentionCompliancePolicy -Identity "Retention Policy – SPO-Baseline – Pilot" -Enabled $true
   ```
4. **Declare a test record and confirm the lock:** apply `Record Label – Contracts – Pilot` to a test
   document, then confirm it cannot be edited/deleted (SharePoint blocks it; the activity is audited).
5. **Exercise disposition (accelerated where possible):** for a label whose retention has elapsed (use a
   short-duration test label or an item already past its trigger), confirm the item appears in
   **Purview → Records management → Disposition**, and have a `Disposition Reviewers – Records – Stage1`
   reviewer **approve disposal** (or extend/relabel) — confirming a **disposition record** is retained.

**Gate 4 (pass/fail):** on the pilot only — labels are applied, a record is declared and demonstrably
locked, the baseline policy is enabled, and one disposition decision has been made and evidenced, with
no unexpected content impact. Run `Test-SpoRetentionRecords.ps1` (Section 5) and require all checks
green before Stage 5.

---

## Stage 5 — Validate

Run the validation procedures in **Section 5 (Testing)** against the pilot. Confirm label coverage on
the pilot libraries, record lock behavior, policy enabled-state, disposition-review routing, and the
disposition record. Produce `Records Compliance – SPO – Report` with
`Get-SpoRecordsComplianceReport.ps1`. Records/legal signs off that the implemented behavior matches the
schedule.

**Gate 5 (pass/fail):** every test in Section 5 passes on the pilot and records/legal has signed off.
Any failure loops back to Stage 3/4 — do not expand.

---

## Stage 6 — Expand (tenant-wide, under change control)

1. **Mint production artifacts** by swapping `– Pilot` for `– Prod` (e.g. `Record Label – Contracts –
   Prod`) — never edit a validated pilot artifact in place.
2. **Attach the adaptive scope** `Scope – Records-Prod – Adaptive` (a site query) to the production
   policies so new/changed sites are covered automatically. *Adaptive scopes are plan-dependent —
   verify in your tenant.*
3. **Roll out in waves**, not all-at-once: enable production policies scope-by-scope, re-running
   `Test-SpoRetentionRecords.ps1` and `Get-SpoRecordsComplianceReport.ps1` after each wave.
4. **Operate the disposition queue** as a recurring duty: reviewers work the queue on cadence; the
   report tracks coverage, records declared, and pending dispositions over time.

**Gate 6 (pass/fail):** each production wave passes the same validation as the pilot before the next
wave; the disposition queue is being worked; the compliance report shows the intended coverage.

---

## Rollback (documented, rehearsed)

Roll back the **reversible** parts; consciously accept the **irreversible** ones.

- **Disable a policy:** `Set-RetentionCompliancePolicy -Identity "<name>" -Enabled $false` — stops the
  policy applying/enforcing.
- **Remove a default library label:** `Set-PnPLabel -List "<library>" -Label "" ` (clear) or re-set to
  a benign label; existing item labels may need per-item removal.
- **Un-declare a (non-regulatory) record:** a user/admin with rights can remove the record label; the
  un-declare is audited.
- **IRREVERSIBLE — no rollback:** a **regulatory-record** label cannot be removed or shortened, and a
  **completed disposition** (approved permanent deletion) cannot be undone. Confirm records/legal
  sign-off before applying any regulatory-record label or approving any disposal. This is why the
  pilot uses non-regulatory records wherever possible.

Every production change references its change ticket and this rollback before it is made.


---


# 5. Testing & Validation

Run these on `Scope – Records-Pilot – Static` before any expansion, and re-run after each production
wave. Each test states the procedure and an explicit **Pass / Fail**. Retention and disposition run on
service timers — allow for propagation (often hours to a few days) before judging a Fail. Use the
provided scripts where noted; all are read-only except where a `-Commit` is explicitly passed.

---

## Test 1 — Labels exist and match the schedule
- **Procedure:** `Get-ComplianceTag | Where-Object Name -like "*Pilot*" | Select-Object Name,IsRecordLabel,Regulatory,RetentionAction,RetentionDuration,RetentionType,ReviewerEmail`.
  Compare each label's action, duration, trigger, record status, and reviewers to the records/legal
  schedule.
- **Pass:** every pilot schedule category has exactly one label whose settings match the schedule.
- **Fail:** any label missing, duplicated, or with a setting that differs from the schedule.

## Test 2 — Labels are applied to the pilot libraries
- **Procedure:** `Get-PnPLabel -List "Documents"` on each pilot library; run
  `Assess-SpoRetentionPosture.ps1` and read the coverage columns in `Retention Posture – SPO –
  Discovery`.
- **Pass:** each single-category pilot library reports its intended default label; labeled-item count
  matches expectation (allowing for propagation).
- **Fail:** a pilot library has no default label where one was intended, or coverage is materially
  below expectation after propagation.

## Test 3 — Record declaration locks content
- **Procedure:** apply `Record Label – Contracts – Pilot` to a test document; attempt to edit, delete,
  and move it.
- **Pass:** SharePoint blocks edit/delete/move (in-place record); the declare action appears in the
  audit log.
- **Fail:** the item can be edited/deleted after the record label is applied, or no audit entry exists.

## Test 4 — Regulatory-record irreversibility is understood (only if in scope)
- **Procedure:** confirm any `Regulatory Record Label – *` category is explicitly approved by
  records/legal and applied only where required; verify `Regulatory = True` on the label.
- **Pass:** every regulatory-record label is records/legal-approved and no regulatory record was
  applied to pilot content that was meant to stay reversible.
- **Fail:** a regulatory-record label was applied without sign-off, or applied to content that should
  have been a normal record.

## Test 5 — Retention policies are in the intended state
- **Procedure:** `Get-RetentionCompliancePolicy | Select-Object Name,Enabled,Mode; Get-RetentionComplianceRule -Policy "Retention Policy – SPO-Baseline – Pilot"`.
- **Pass:** the pilot baseline (and any auto-apply) policy is **Enabled = True**, scoped to the pilot
  sites only, with the designed retention action/duration; nothing tenant-wide is enabled in the pilot.
- **Fail:** a policy is disabled when it should be enabled, scoped beyond the pilot, or has a
  wrong action/duration.

## Test 6 — Auto-apply reaches matching content
- **Procedure:** for `Label Policy – Contracts-AutoApply – Pilot`, place a document matching the
  condition (keyword / sensitive-info type / classifier) in a pilot library; after propagation, confirm
  the label auto-applied.
- **Pass:** matching content receives the label automatically within the expected propagation window;
  non-matching content does not.
- **Fail:** matching content is never labeled, or the policy over-applies to non-matching content.

## Test 7 — Disposition review routes to reviewers
- **Procedure:** confirm reviewers are in the **Disposition Management** role group; for a label whose
  retention has elapsed (test/short-duration label), confirm the item appears in **Purview → Records
  management → Disposition** for `Disposition Reviewers – Records – Stage1`.
- **Pass:** the expired item is in the disposition queue and visible to the named reviewers only.
- **Fail:** the item never enters the queue, or is visible to accounts outside Disposition Management.

## Test 8 — A disposition decision is evidenced (defensible disposition)
- **Procedure:** have a reviewer **approve disposal** (or extend/relabel) on the queued test item;
  confirm the outcome and that a **disposition record / proof of disposal** is retained.
- **Pass:** the decision executes (disposed / extended / relabeled) and Purview retains an auditable
  disposition record naming the reviewer, decision, and date.
- **Fail:** the decision does not execute, or no disposition record is retained.

## Test 9 — Alignment with the broader Purview program (no conflict)
- **Procedure:** review the retention-precedence interaction of the new pilot labels/policies against
  pre-existing retention (from `Get-RetentionCompliancePolicy` and the Stage-1 baseline). Confirm no
  pilot content is unintentionally over-retained or deleted by a conflict.
- **Pass:** the effective retention outcome on pilot content matches the schedule after precedence
  rules; sensitivity labels/DLP owned by the broader program are untouched.
- **Fail:** a conflict changes the effective outcome, or this solution altered a broader-program
  artifact it should not own.

## Test 10 — Full compliance report reconciles
- **Procedure:** run `Get-SpoRecordsComplianceReport.ps1` to produce `Records Compliance – SPO –
  Report`; reconcile label coverage %, records declared count, and pending-disposition count against
  expectations.
- **Pass:** the report generates and its figures reconcile with the schedule and the pilot design.
- **Fail:** the report errors, or figures diverge from expectation without an explained cause.

---

**Overall pilot gate:** Tests 1–3, 5, 7, 8, and 10 must **Pass** (and 4, 6, 9 where those features are
in scope) before Stage 6 expansion. Any Fail loops back to Implementation Stage 3/4.


---


# 6. Troubleshooting

Common failure modes and resolutions, ordered roughly by where they appear in the deployment model.
Retention, application, and disposition run on **service timers** — before treating anything as
broken, confirm you have allowed for propagation (often hours to a few days).

---

## Connection & permissions

**`Connect-IPPSSession` fails or `Get-ComplianceTag` errors with access denied.**
- Cause: the account is not in a Purview role group (Records Management / Compliance Administrator), or
  the ExchangeOnlineManagement module is missing/old.
- Resolve: confirm the role group membership (Requirement 2.3), update the module
  (`Update-Module ExchangeOnlineManagement`), and reconnect. Run `Resolve-SpoRecordsScope.ps1` to
  pre-flight module and connection health.

**`Connect-PnPOnline` fails or `Set-PnPLabel` is denied.**
- Cause: no SharePoint admin/site rights, or the PnP Entra app registration isn't consented for the
  auth mode you're using.
- Resolve: confirm SharePoint Administrator or site rights, register/consent the PnP app where required
  (category Requirement 3), and reconnect with `-Interactive`.

**Government cloud: portal or connect endpoint not found.**
- Cause: Commercial URLs/endpoints used in a GCC/GCC High/DoD tenant.
- Resolve: use the Government endpoints (portal `*.office365.us` and the matching S&C/PnP connection
  parameters) — **verify the exact paths for your cloud**; do not assume Commercial paths apply.

---

## Labels & policies

**A published label does not appear for owners to apply.**
- Cause: propagation delay, or the label policy is unpublished/disabled, or the site isn't in the
  policy's scope.
- Resolve: confirm `Label Policy – Owner-Publish – Pilot` is enabled and scoped to the pilot site; wait
  for propagation (can take up to a day); re-check `Get-RetentionCompliancePolicy`.

**`New-ComplianceTag` fails or a feature (auto-apply / adaptive scope / regulatory) is unavailable.**
- Cause: the tenant is not licensed for that plan-dependent feature.
- Resolve: confirm the compliance licensing (Requirement 2.1) — **verify the entitlement in your
  tenant**; if unlicensed, redesign to a feature the tenant has (e.g. default library label instead of
  auto-apply) or acquire the plan.

**A default library label was set but existing items are not labeled.**
- Cause: `-SyncToItems` not used, or propagation still in progress, or per-item labels already present
  take precedence.
- Resolve: set the default with `Set-PnPLabel -SyncToItems $true`; allow propagation; check individual
  items in the library's label column after the timer runs.

**Effective retention on content is not what the schedule says.**
- Cause: retention **precedence** — another policy/label is interacting (retention beats deletion;
  longest wins; explicit beats policy; shortest deletion wins).
- Resolve: enumerate every policy/label touching the content (`Get-RetentionCompliancePolicy`,
  `Get-ComplianceTag`), reason through precedence, and validate the **effective** outcome (Test 9).
  Align with the broader Purview program owners if the conflict is with a program-owned policy.

---

## Records declaration

**Applying a record label does not lock the item (still editable/deletable).**
- Cause: the label is not actually a record label (`IsRecordLabel` false), or propagation is
  incomplete.
- Resolve: `Get-ComplianceTag -Identity "<label>"` and confirm `IsRecordLabel = True` (set it with
  `Set-SpoRecordsDisposition.ps1`); wait for propagation; re-test the edit/delete block (Test 3).

**A regulatory-record label was applied by mistake.**
- Cause: `-Regulatory $true` set without sign-off — this is **irreversible**.
- Resolve: there is **no rollback** for a regulatory record; the content is locked for its full
  retention. Prevent recurrence — the `Set-SpoRecordsDisposition.ps1` helper refuses `-Regulatory`
  without `-ConfirmRegulatory`, and regulatory records require records/legal sign-off (Requirement 2.7,
  Test 4).

---

## Disposition review

**Expired items never appear in the disposition queue.**
- Cause: the label has no reviewers (`ReviewerEmail` empty, so disposal is automatic), retention hasn't
  actually elapsed yet, or propagation is pending.
- Resolve: confirm the label carries reviewers (`Get-ComplianceTag`); confirm the retention trigger and
  duration mean the item is genuinely past due; allow the disposition timer to run. Use a short-duration
  test label to exercise the flow (Test 7).

**Reviewers cannot see the disposition queue.**
- Cause: the reviewer accounts are not in the **Disposition Management** role group.
- Resolve: add them (Requirement 2.3 / Implementation 3b); `Set-SpoRecordsDisposition.ps1` validates
  reviewer membership and warns when an account is missing.

**A disposition was approved by mistake and content was deleted.**
- Cause: an approved permanent disposal executed.
- Resolve: a **completed disposition cannot be undone**. Recover from backup/retention grace only if
  still within any applicable window, and tighten reviewer training and the review stage. This is why
  high-value categories use review (not auto-disposal) and change control gates the pilot.

---

## Reporting & scope

**`Get-SpoRecordsComplianceReport.ps1` shows pending disposition as `n/a`.**
- Cause: the disposition-count cmdlet isn't available in the tenant/session (plan- or module-dependent).
- Resolve: read pending disposition from **Purview → Records management → Disposition** in the portal;
  the coverage and record-label figures in the report are still valid — **verify disposition counts in
  your tenant**.

**Assessment/report shows a library as `(unable to read)` for its label.**
- Cause: insufficient rights on that library, or a transient PnP error.
- Resolve: confirm rights on the specific site/library and re-run; the scripts continue past a single
  library error so one failure doesn't abort the whole run.


---


# 7. Best Practices

Durable practices for applying and operating records, retention, and information governance on
SharePoint Online content. These outlast any single rollout.

## Governance & scope
- **Implement the schedule; never author it.** Records periods, triggers, record status, and
  disposition authority come from records/legal. If the schedule is silent or ambiguous, get a decision
  in writing before configuring — do not guess a retention period.
- **Stay in your lane relative to Purview.** This is SharePoint-scoped records/retention. Sensitivity
  labels, DLP, insider-risk, and Exchange/Teams retention belong to the broader Purview program —
  reference and align, don't duplicate or override.
- **One label per schedule category, named consistently.** `<Purpose> – <Scope> – <Stage>` everywhere
  (portal, PowerShell, docs). Mint `– Prod` artifacts from validated `– Pilot` ones; never edit a
  validated artifact in place.

## Labels, records & disposition
- **Prefer default library labels for single-category libraries.** It is the most reliable way to get
  consistent coverage without relying on users to label each item.
- **Use record labels for defensibility, regulatory records sparingly.** A record label locks content
  in place (auditable, reversible by un-declare). A **regulatory record is irreversible** — reserve it
  for categories records/legal explicitly mandate, and communicate the lock before applying.
- **Route high-value categories through disposition review.** Automatic disposal is fine for low-risk
  categories; anything a regulator or auditor may question should end in a human-approved, evidenced
  disposition.
- **Keep reviewer access least-privilege.** Only named reviewers belong in the **Disposition
  Management** role group; review the membership periodically.
- **Import file-plan descriptors.** Retention authority / category / sub-category on each label makes
  the file plan reportable and the audit story defensible.

## Change safety
- **Pilot-first, always.** Prove the label→apply→declare→dispose chain on a bounded static scope before
  touching the tenant. Enable policies **disabled-then-enabled**, one change at a time, watching each
  propagate.
- **Respect propagation.** Retention, application, and disposition run on timers — do not judge a
  configuration in the first minutes, and build the delay into test plans and comms.
- **Understand retention precedence before you layer policies.** Retention beats deletion; longest
  retention wins; explicit beats policy; shortest deletion wins. Design and then **validate the
  effective outcome** on real content — never assume the last policy wins.
- **Baseline safety net, not tenant-wide delete, in a pilot.** A pilot retention policy should be
  retain-only; introduce deletion outcomes only after the schedule and behavior are proven.
- **Document and rehearse rollback, and flag the no-rollback parts.** Know exactly how to disable a
  policy and remove a default label; explicitly mark regulatory records and completed dispositions as
  irreversible.

## Automation & operations
- **Safe-by-default automation.** Assessment/reporting read-only; configuration scripts dry-run /
  `-WhatIf` unless `-Commit`. Modern-auth `Connect-*` only — never store credentials or secrets in
  scripts.
- **Work the disposition queue on cadence.** Disposition is an ongoing operational duty, not a one-time
  event; a growing backlog is a governance risk.
- **Report on a schedule.** Track label coverage %, records declared, and pending dispositions over
  time with `Get-SpoRecordsComplianceReport.ps1`; a downward trend in un-labeled content and a worked
  disposition queue is the health signal.
- **Verify plan-dependent features in your tenant and cloud.** Auto-apply, adaptive scopes, regulatory
  records, event-based retention, and multi-stage review are licensing-gated; portal URLs and feature
  availability differ in Government clouds (`*.office365.us`). Confirm before you design around them.


---


# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
- **Solution Overview** — what SharePoint records/retention is, how labels/policies/records/disposition
  work, the reference design, what's deferred to records/legal and to the broader Purview program,
  limitations, and the deployment model.
- **Requirements Guide** — solution-specific prerequisites (compliance licensing; the records schedule
  from records/legal; records/retention roles; existing Purview posture; a pilot site set; the S&C
  PowerShell / PnP toolchain; change control + rollback), each with how to verify and implement,
  building on the SharePoint category global requirements.
- **Implementation Guide** — Assess → Design → Configure → Pilot → Validate → Expand, with every
  artifact named, explicit pass/fail gates per stage, and a documented rollback (including the
  irreversible parts).
- **Testing & Validation** — 10 procedures, each with an explicit pass/fail, covering labels, records
  lock, policies, auto-apply, disposition routing, defensible disposition, Purview alignment, and the
  compliance report.
- **Troubleshooting** — common failure modes (connection/roles, labels not appearing, records not
  locking, disposition not routing, retention conflicts, Government-cloud paths) and resolutions.
- **Best Practices** — durable governance, label/record/disposition, change-safety, and operations
  practices.
- **Executive Summary** — the outcome, approach, and why it is low-risk, for decision-makers.

## PowerShell scripts (5)
All use modern-auth `Connect-*` (Security & Compliance PowerShell via `Connect-IPPSSession`, PnP via
`Connect-PnPOnline`); no hardcoded credentials. Assessment and reporting are read-only; configuration
scripts default to dry-run / `-WhatIf` and only write when `-Commit` is passed.

1. **`Assess-SpoRetentionPosture.ps1`** — *Discovery (read-only).* Enumerates the in-scope SharePoint
   sites' document libraries, reads each library's default retention label (`Get-PnPLabel`), counts
   labeled vs unlabeled items, and cross-references existing tenant retention labels/policies
   (`Get-ComplianceTag`, `Get-RetentionCompliancePolicy`). Produces `Retention Posture – SPO –
   Discovery` (CSV).
2. **`Apply-SpoRetentionLabels.ps1`** — *Retention-label + policy apply (`-WhatIf` default).* Builds/
   verifies retention labels and location/auto-apply policies (`New-ComplianceTag`,
   `New-RetentionCompliancePolicy`/`Rule`) and stages default library labels (`Set-PnPLabel`). Reports
   the intended changes by default; only creates/applies when `-Commit` is passed.
3. **`Set-SpoRecordsDisposition.ps1`** — *Records-declaration + disposition config (`-WhatIf`
   default).* Configures/validates record and regulatory-record labels (`-IsRecordLabel`,
   `-Regulatory`, `-ReviewerEmail`) and confirms the Disposition Management reviewer wiring. Dry-run by
   default; writes only with `-Commit`; refuses to set `-Regulatory` without an explicit confirmation
   switch.
4. **`Get-SpoRecordsComplianceReport.ps1`** — *Retention/records compliance report.* Compiles label
   coverage %, records-declared counts, and pending-disposition counts across the scope into
   `Records Compliance – SPO – Report` (CSV/HTML). Read-only.
5. **`Resolve-SpoRecordsScope.ps1`** — *Scope/health helper.* Resolves the pilot/prod site+library
   scope, checks module/connection health (`Connect-IPPSSession` / `Connect-PnPOnline`), and surfaces
   plan/cloud hints (compliance licensing, Government-cloud endpoints) before configuration. Read-only.
