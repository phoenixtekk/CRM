# Disposition Review Program — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: DLCDISPO

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

At the end of a retention period, content in Microsoft 365 is either **deleted automatically** or **held
for a human to review first**. Automatic deletion is blind: nothing confirms the content is truly out of
obligation, nothing records why it was disposed, and there is no proof for an auditor or regulator that the
deletion was deliberate and authorised. That gap is a compliance and data-risk exposure. This solution
stands up a **disposition review program in Microsoft Purview** — a multi-stage review workflow with named
reviewers, strict role separation, and a defensible **proof-of-disposal** evidence trail — so content is
reviewed, not blindly deleted, and every disposal is accountable and provable.

**Outcome.** Retention labels configured with **disposition review** so expiring content routes to a
reviewer instead of deleting automatically; **single-stage** review where one authority suffices and
**multi-stage** review (e.g. records → compliance → legal) where accountability requires sequential
sign-offs, with disposal occurring only after the **final** stage approves; reviewers wired with the
**Disposition Management** permission — and nothing more — so the person disposing content is not the person
who set the schedule; and, at the end of each cycle, a retained **disposition record / proof of disposal**
plus audit events showing what was disposed, by whom, and when. Blind deletion becomes governed,
evidenced, defensible disposal.

**Approach.** The work is deliberately **narrow** — it implements the **review layer** on top of retention
labels and **defers the retention schedule and records/legal determinations** (which categories require
review, how many stages, who reviews, and every disposition decision) to the organisation's records,
compliance, and legal functions and to the org-wide Data Lifecycle & Records Management product, which it
references rather than rebuilds. Reviewers approve dispositions **in the Microsoft Purview portal**; the
tooling configures, validates, and reports on the program but never approves, extends, or deletes on a
reviewer's behalf. Delivery follows a disciplined, pilot-first model — **Assess → Design → Configure →
Pilot → Validate → Expand** — proving a **complete review-and-dispose cycle**, including its proof of
disposal, on a bounded pilot scope with short-duration disposable test content before any production
content is governed. Five PowerShell tools (Security & Compliance PowerShell and Graph) handle posture
assessment, disposition-label configuration, reviewer-permission wiring, and evidence reporting — read-only
or dry-run (`-WhatIf`) by default, with no credentials in code.

**Why it is low-risk.** Permanent disposal is irreversible and role separation is a compliance control, so
nothing governs production content until a full cycle is proven on disposable test content. Assessment is
read-only and surfaces the exact gap this program closes (labels that auto-delete where review is required);
configuration is staged and pilot-scoped; reviewers are least-privileged into Disposition Management; and
the one **irreversible** action — a completed disposition — is explicitly flagged no-rollback, exercised
only on test content in pilot, and left as the reviewer's (records/legal) determination in production.
Plan- and cloud-dependent behaviour (multi-stage review availability, the multi-stage property shape,
Government-cloud portal paths) is flagged for tenant verification rather than assumed. The result: content
reviewed before permanent deletion, disposal made accountable and provable — a compliance gap turned into
evidenced, defensible disposition.


---


# 1. Solution Overview — Disposition Review Program (Microsoft Purview)

## What this solution is
At the end of a retention period, content in Microsoft 365 is either **deleted automatically** or **held
for a human to review first**. Automatic deletion is efficient but blind: nothing confirms the content is
truly out of obligation, nothing records *why* it was disposed, and there is no proof for an auditor or
regulator that the deletion was deliberate and authorised. **Disposition review** is the control that
turns "delete on expiry" into a governed, evidenced decision — one or more named reviewers examine each
expiring item and approve permanent deletion, extend retention, or relabel it, and Microsoft Purview keeps
a **proof of disposal** for what was disposed, by whom, and when.

This solution is a repeatable, pilot-first method to stand up a **multi-stage disposition review program
in Microsoft Purview**: retention labels configured with **single- and multi-stage** disposition review,
named **reviewer stages** with strict role separation, the **Disposition Management** permission wired so
reviewers can act, a working evidence/proof trail, and a validated **defensible disposal** outcome —
piloted on a bounded scope and proven against explicit pass/fail gates before it governs real content.

## Scope: the review workflow, not the retention schedule
This product is deliberately **narrow**. It implements the **disposition-review layer** — the reviewer
stages, the permission model, the evidence, and the defensible-disposal proof — on top of retention labels.
It does **not** re-author the organisation's broader retention/records program:

- **The retention schedule is an input, not built here.** *Which* content is retained, for *how long*,
  and *whether* a category ends in review or automatic disposal are determined by the organisation's
  **records-management, compliance, privacy, and legal** functions and are typically implemented by the
  **org-wide Data Lifecycle & Records Management product**. This solution takes those labels/categories as
  given and adds (or verifies) the **disposition-review** behaviour on them.
- **The disposition decision itself is deferred.** This solution delivers the *method* by which a reviewer
  approves, extends, or relabels — and the evidence of that action — but **whether** a specific item should
  be deleted, kept, or held is the reviewer's (records/legal) determination, never a technical default and
  never made by a script.
- **Legal holds / eDiscovery preservation** override disposition and belong to legal/eDiscovery — content
  under hold is not disposed; this solution respects that boundary and does not manage holds.

Where retention-label, policy, event-based-retention, records-declaration, or file-plan mechanics are
needed, this solution **references** the org-wide Data Lifecycle & Records Management product rather than
re-documenting them.

## Why this matters
- **Blind auto-deletion is a defensibility gap.** If content is deleted the instant its label expires,
  there is no record of a decision — only a gap where evidence should be. Disposition review inserts a
  documented, accountable checkpoint before irreversible deletion.
- **Multi-stage review encodes real accountability.** Many organisations require more than one sign-off
  before high-value content is destroyed — e.g. a records manager, then compliance, then legal. Microsoft
  Purview supports **multiple review stages** on a label so each stage approves in sequence and disposal
  happens only after the **final** stage approves. *(Multi-stage disposition review is plan-dependent and
  the stage model evolves — verify availability and the exact configuration in your tenant.)*
- **Evidence is the product.** When an item is disposed after review, Microsoft Purview retains a
  **disposition record** (proof of disposal) and writes **audit events** — the artefact a regulator or
  auditor asks for. A review program that produces no evidence is not defensible; this solution treats the
  proof trail as a first-class deliverable.
- **Role separation protects the process.** Reviewers must hold the **Disposition Management** permission
  to see and act on the queue — and *only* that, so the person disposing content is not the same person who
  set the schedule. Getting this wrong either blocks reviewers (they cannot see the queue) or over-grants.
- **Doing it pilot-first avoids the high-impact failure mode.** A mis-scoped or mis-configured disposition
  label can route the wrong content to review — or worse, let content auto-delete when a review was
  required. Everything is proven on a **bounded pilot scope** with short-duration disposable test content
  before it governs production.

## How disposition review works in Microsoft Purview
1. **Disposition review is a property of a retention label.** A label whose retention action is
   **retain-then-delete** (`KeepAndDelete`) can have **disposition review enabled** instead of automatic
   deletion. At the end of the retention period the item is **not** deleted — it enters the **Disposition**
   queue for review. Labels are created/edited in Microsoft Purview → **Records management → File plan /
   Labels** (path evolves — verify in your tenant).
2. **Single-stage review** names one set of reviewers (`-ReviewerEmail`) — one approval disposes the item.
3. **Multi-stage review** defines an **ordered list of stages**, each with its own reviewers (via
   `-MultiStageReviewProperty`). Stage 1 approves → the item advances to Stage 2 → … → the **final** stage
   approves → the item is disposed. Any stage can instead **extend** retention or **relabel** the item,
   which stops disposal. *(Verify the multi-stage parameter shape and stage limit in your tenant — this
   capability is newer and its configuration has changed across releases.)*
4. **Reviewers act in the portal.** Named reviewers work the queue in Microsoft Purview → **Records
   management → Disposition**, where each can **permanently delete**, **extend the retention period**, or
   **apply a different retention label**. They must be in the **Disposition Management** role group to see
   the queue; they see only the labels for which they are a reviewer.
5. **Notifications drive the queue.** Reviewers receive email when items await them and periodic reminders;
   disposition settings control reminders and (where available) what happens to overdue stages. *(Confirm
   the notification/overdue behaviour in your tenant — settings evolve.)*
6. **Defensible disposal is the outcome.** Content is deleted **only after the final review stage
   approves**, and Microsoft Purview retains a **disposition record** as proof of disposal plus **audit**
   events — the evidence trail this program exists to produce.

## The reference design
- **Inputs (from records/legal):** which retention labels/categories require review, how many **stages**,
  who reviews at each stage, and the disposition authority. (This solution implements the design; it does
  not decide the stages or the reviewers.)
- **Disposition labels:** retain-then-delete retention labels with review enabled — single-stage where one
  sign-off suffices, multi-stage where accountability requires sequential approvals — named per the
  convention below. Where these labels already exist (from the org-wide records product), this solution
  **verifies and, where needed, adds** the review configuration rather than re-minting them.
- **Reviewer stages:** each stage's reviewers are a **mail-enabled security group** (so membership is
  managed once), and every member is placed in the **Disposition Management** role group. Typical stages:
  `Records → Compliance → Legal`.
- **Application:** disposition labels are **published** to (or **auto-applied** within) the **pilot scope**
  only, via a pilot-scoped label policy — never tenant-wide until validated.
- **Evidence:** the proof-of-disposal / disposition-record trail plus audit events, surfaced by the
  reporting script and the portal Disposition export.
- **Scope:** a **static pilot scope** to prove on, with short-duration disposable test labels so a full
  review cycle can be exercised without waiting years.

## Naming convention (used in every doc and script)
Every artefact this solution creates or verifies is named `<Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, and the Purview admin surfaces:

| Artefact | Name |
|---|---|
| Retain-then-delete label, single-stage review | `Disposition Label – Records-7yr – Pilot` |
| Retain-then-delete label, multi-stage review | `Disposition Label – Contracts-7yr-MS – Pilot` |
| Stage 1 reviewer group (records) | `Disposition Reviewers – Records – Stage1` |
| Stage 2 reviewer group (compliance) | `Disposition Reviewers – Compliance – Stage2` |
| Stage 3 reviewer group (legal) | `Disposition Reviewers – Legal – Stage3` |
| Built-in permission for reviewers | `Disposition Management` (built-in role group) |
| Label policy publishing disposition labels | `Label Policy – Disposition-Publish – Pilot` |
| Auto-apply label policy (by condition) | `Label Policy – Disposition-AutoApply – Pilot` |
| Pilot scope (static) | `Scope – Disposition-Pilot – Static` |
| Assessment export | `Disposition Posture – Tenant – Discovery` |
| Evidence / compliance report | `Disposition Evidence – Tenant – Report` |

When the pilot passes and you expand, mint the production equivalents by swapping the `– Pilot` stage for
`– Prod` — never edit a validated pilot artefact in place.

## Limitations (be honest with buyers)
- **Disposition review — especially multi-stage — is plan-dependent.** It generally requires an **E5 / E5
  Compliance-class** plan or the equivalent Microsoft Purview add-on, and the **multi-stage** model is
  newer than single-stage. **Verify what your tenant is licensed for and the exact configuration shape.**
- **Reviewers act in the portal; scripts do not approve dispositions.** The provided tooling **configures,
  validates, and reports on** the review program and points reviewers to the portal Disposition queue —
  it never approves, extends, or deletes on a reviewer's behalf. The determination is human (records/legal).
- **Disposed items are not enumerable via a supported cmdlet.** The actual per-item disposition proof is
  exported from the portal **Disposition** area (and corroborated by the audit log); the reporting script
  surfaces label/stage/reviewer *configuration* and points to that export rather than inventing an item list.
- **Everything is eventually consistent.** Label application, expiry, entry into the queue, notifications,
  and disposal run on service timers (hours to days). Use short-duration test labels in pilot; never judge
  a cycle in the first minutes.
- **Permanent deletion is irreversible.** An approved final-stage disposition permanently deletes content.
  In pilot, exercise the full cycle only on **disposable test content** you are prepared to lose.
- **Legal hold overrides disposition.** Content on legal hold / eDiscovery hold is not disposed even after
  review approval; hold management is out of scope and owned by legal/eDiscovery.
- **Commercial vs Government cloud paths differ.** Portal URLs and some feature availability differ in
  GCC / GCC High / DoD (`*.office365.us`, `Connect-IPPSSession -ConnectionUri`) — **verify in your cloud.**

## The standard deployment model
> **Assess** the current disposition posture (which labels review vs auto-delete, existing reviewers and
> permissions) → **Design** the stage/reviewer map from the records/legal requirement → **Configure**
> disposition-review labels, reviewer stages, and the Disposition Management permission → **Pilot** on
> `Scope – Disposition-Pilot – Static` with short-duration disposable test content → **Validate** against
> explicit pass/fail gates (including a full review cycle and its evidence) → **Expand** to production
> labels/scope under change control.

Permanent disposal is **irreversible** and role separation is a compliance control — so nothing governs
production content until the pilot cycle, including its proof of disposal, has passed the gates in
Section 5, and every production change goes through change control with a documented rollback.


---


# 2. Requirements

These are the **solution-specific** prerequisites for standing up a disposition review program in
Microsoft Purview. They build **on** the shared Purview category requirements in
**`global-requirements-purview.md`** (a Microsoft 365 tenant with the required Purview/compliance
licensing; least-privilege Purview roles and portal access; the Security & Compliance PowerShell + Graph
toolchain; the in-scope data sources/workloads; the compliance/records/privacy/legal stakeholders; and a
pilot scope with change control). Do not repeat those — verify them first, then confirm the
disposition-specific prerequisites below. Each is stated as **Description / Why / Verify / Implement if
missing.**

---

## 2.1 Compliance licensing for disposition review (single- and multi-stage)
- **Description:** The Microsoft 365 / Microsoft Purview licensing that unlocks **disposition review** on
  retention labels. Single-stage review and records management generally require an **E5 / E5
  Compliance-class** plan or the equivalent Purview add-on; **multi-stage** disposition review is newer and
  its availability may differ.
- **Why required:** Disposition review is **plan-gated** — without the right entitlement the label editor
  will not offer "review disposition" and `New-ComplianceTag`/`Set-ComplianceTag` will not accept the
  reviewer/multi-stage properties.
- **Verify:** In the Microsoft 365 admin center → Billing → Licenses confirm the compliance plan/add-on. In
  the Microsoft Purview portal, confirm **Records management** is visible and that a retain-then-delete
  label offers a **disposition review** option (single and, where licensed, multi-stage). *Feature-to-plan
  mapping changes — verify the exact entitlement and the multi-stage capability in your tenant.*
- **Implement if missing:** Have licensing assign/purchase the required compliance plan or add-on to the
  admin and to every reviewer account before configuration.

## 2.2 The disposition-review requirement (input from records & legal)
- **Description:** The authoritative statement of **which retention categories/labels require review**
  before disposal (versus automatic deletion), **how many stages** each requires, **who reviews at each
  stage**, and the **disposition authority** (who may finally approve deletion). This is a specific slice of
  the organisation's retention schedule.
- **Why required:** This solution **implements** the review requirement; it does not author it. The stages,
  the reviewers, and the decision to review-versus-auto-delete are all determined by records/compliance/
  legal — without them there is nothing correct to configure.
- **Verify:** Confirm records/legal has provided (or signed off) the list of review categories, the stage
  count and order per category, the named reviewer population per stage, and the final disposition
  authority — or at least a pilot subset.
- **Implement if missing:** This is **deferred to the records-management / compliance / legal functions** —
  request the requirement before configuring. Do not invent review stages, reviewer identities, or the
  decision to review versus auto-delete.

## 2.3 Roles: reviewers in Disposition Management, and least-privilege config
- **Description:** The permission model with strict **role separation** — the **Disposition Management**
  role group for every reviewer (so they can see and act on the Disposition queue), plus **Records
  Management** or **Compliance Administrator / Compliance Data Administrator** for the admin who creates and
  configures the labels and reviewer stages. A reviewer must be **both** a named reviewer on the label
  **and** a member of **Disposition Management** to act.
- **Why required:** Reviewers who are not in **Disposition Management** cannot see the queue at all;
  configuration of labels/stages requires the corresponding records/compliance role. Keeping these separate
  ensures the person disposing content is not necessarily the person who set the schedule.
- **Verify:** Microsoft Purview portal → **Roles & scopes → Permissions (role groups)** — confirm every
  reviewer is in **Disposition Management** and that the configuring admin holds Records Management /
  Compliance Administrator. Confirm reviewers are **not** over-granted beyond what review requires.
- **Implement if missing:** Add each reviewer account (or a mail-enabled group's members) to **Disposition
  Management** under change control; grant the admin the least-privilege records/compliance role. Grant
  Disposition Management **only** to named reviewers.

## 2.4 Reviewer groups and mailboxes (stage reviewers)
- **Description:** A **mail-enabled security group per stage** (e.g. `Disposition Reviewers – Records –
  Stage1`) whose members are the stage's reviewers, so stage membership is managed in one place; each
  reviewer must have a **mailbox** to receive disposition notifications, and each must also be in
  **Disposition Management** (2.3).
- **Why required:** Disposition-review stages are addressed by reviewer email (individual or mail-enabled
  group); notifications and reminders require a mailbox; managing reviewers via a group avoids editing the
  label every time membership changes.
- **Verify:** Confirm each stage has a mail-enabled security group (or an agreed reviewer email set), that
  members are mailbox-enabled, and that group membership matches the records/legal reviewer population.
- **Implement if missing:** Create the mail-enabled security groups per stage, populate them from the
  records/legal reviewer list, and add their members to Disposition Management (2.3).

## 2.5 Existing retention labels and disposition posture (verify, don't duplicate)
- **Description:** Knowledge of the **retention labels already in force** — particularly retain-then-delete
  labels — and whether each currently ends in **automatic deletion** or **disposition review**, plus any
  existing reviewers. Retention labels themselves are typically owned by the **org-wide Data Lifecycle &
  Records Management product**; this solution **adds/verifies** review behaviour on them rather than
  re-minting labels.
- **Why required:** Adding a second disposition label for a category that already has one causes confusion
  and precedence surprises; and a label that silently **auto-deletes** where review is required is the exact
  gap this program closes — you must find it first.
- **Verify:** Enumerate existing labels (`Get-ComplianceTag`) and identify which are retain-then-delete,
  which have review enabled (single/multi-stage), and which delete automatically; confirm ownership with the
  records program.
- **Implement if missing:** Engage the org-wide records program owners; capture the existing label baseline
  (the assessment script does this) before creating or modifying disposition labels, and keep label names
  consistent across both products.

## 2.6 Legal hold / eDiscovery boundary (respect, don't manage)
- **Description:** Awareness that content under **legal hold** or **eDiscovery hold** is exempt from
  disposal even after a review is approved, and confirmation that hold management stays with **legal /
  eDiscovery** and is out of this solution's scope.
- **Why required:** Disposition must never delete content that is under a preservation obligation; treating
  hold as someone else's owned control keeps this program inside its boundary and avoids a defensibility
  failure.
- **Verify:** Confirm with legal/eDiscovery that holds are managed separately and that held content is
  understood to be exempt from disposition; do not attempt to enumerate or alter holds from this solution.
- **Implement if missing:** Establish the hand-off: this program routes expiring content to review; legal/
  eDiscovery owns holds. Flag any content class where hold and disposition interact for legal's attention.

## 2.7 Disposition automation toolchain
- **Description:** The **Security & Compliance PowerShell** endpoint (`Connect-IPPSSession` from the
  **ExchangeOnlineManagement** module) for retention labels, disposition-review properties, and role-group
  membership (`Get-/New-/Set-ComplianceTag`, `Get-/Add-RoleGroupMember`), and **Microsoft Graph PowerShell**
  for supporting reads (group/mailbox validation) — a modern-auth / MFA-capable admin.
- **Why required:** The provided scripts and the configuration steps run through Security & Compliance
  PowerShell (and Graph for supporting reads); both must connect.
- **Verify:** `Connect-IPPSSession` succeeds and `Get-ComplianceTag` / `Get-RoleGroupMember -Identity
  "Disposition Management"` return without error; `Connect-MgGraph` succeeds where used. In Government
  clouds, confirm the correct `-ConnectionUri` / endpoint.
- **Implement if missing:** Install the **ExchangeOnlineManagement** and **Microsoft.Graph** modules and
  confirm modern-auth sign-in before running steps. Never store credentials in scripts.

## 2.8 Change control and a documented rollback for disposition
- **Description:** An approved change window and a **rollback plan** specific to disposition: how to
  **disable/unpublish** a disposition label policy, how to **change a label from review back to a staged
  state**, and the explicit note that **a completed (approved) disposition permanently deletes content and
  cannot be rolled back**.
- **Why required:** Disposal is high-impact and partly irreversible; a documented rollback is the safety net
  for the reversible parts (label policy, publication, reviewer membership) and forces a conscious decision
  on the irreversible part (an approved deletion).
- **Verify:** Confirm a change ticket, an approver, and a written rollback covering label-policy disable/
  unpublish and reviewer-group changes for the pilot categories, with completed disposition flagged
  **no-rollback**.
- **Implement if missing:** Author the rollback (Section 3 provides the steps), get change-control sign-off,
  and explicitly flag **completed disposition** as no-rollback before any production content is governed.


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

This is the ordered, pilot-first method to stand up a multi-stage disposition review program in Microsoft
Purview. It follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** — and
every artefact is named per the convention in Section 1 and reused verbatim in the scripts. **Disposition
is high-impact and partly irreversible**: disposition labels are published to the **pilot scope only**, the
full review cycle is exercised on **short-duration disposable test content**, and nothing governs production
until the Section 5 gates pass. **The review requirement (which labels review, how many stages, who
reviews) is an input from records/legal** — this guide implements it, it does not author it. **Reviewers
approve dispositions in the portal; no script deletes, extends, or relabels on their behalf.**

> **Portal paths evolve and are cloud-dependent.** Paths below are Microsoft Purview portal
> (`purview.microsoft.com`) as of authoring; in GCC/GCC High/DoD the URL and some features differ
> (`*.office365.us`). **Verify the path and feature availability in your tenant/cloud** before relying on
> it. Where a step is plan-dependent (multi-stage review especially), it is flagged.

---

## Stage 0 — Connect and confirm prerequisites
1. Confirm Section 2 prerequisites: compliance licensing incl. multi-stage (2.1), the review requirement
   from records/legal (2.2), roles incl. **Disposition Management** (2.3), reviewer groups/mailboxes (2.4),
   existing label posture (2.5), the legal-hold boundary (2.6), the toolchain (2.7), and change control
   (2.8).
2. Connect the toolchain from an MFA-capable admin workstation:
   ```powershell
   Connect-IPPSSession                              # Security & Compliance PowerShell (add -ConnectionUri for Gov clouds)
   Connect-MgGraph -Scopes "Group.Read.All","User.Read.All"   # supporting reads only (reviewer/group validation)
   ```
3. Run **`Resolve-DispositionScope.ps1`** to confirm module/connection health, report the detected cloud/
   endpoint, confirm Records-management / disposition cmdlets are reachable, and resolve the **Disposition
   Management** role group and the pilot scope. **Pass/fail:** connections succeed, the expected cloud is
   reported, `Get-ComplianceTag` and `Get-RoleGroupMember -Identity "Disposition Management"` return, and
   the pilot scope resolves.

## Stage 1 — Assess (read-only)
1. Run **`Assess-DispositionPosture.ps1`** to produce `Disposition Posture – Tenant – Discovery`: every
   retention label (`Get-ComplianceTag`) with its **retention action**, and for retain-then-delete labels
   whether disposition review is **enabled** (single vs multi-stage), the **reviewer stages** and their
   reviewers, plus the **Disposition Management** role-group membership (`Get-RoleGroupMember`).
2. The script flags the key gaps: **retain-then-delete labels that auto-delete with no review**, **reviewed
   labels whose reviewers are not in Disposition Management** (they cannot act), and **stages with empty or
   unresolved reviewers**.
3. Review the baseline with records/legal and the org-wide records program (2.5): which labels *should*
   require review, which already do, and which are owned elsewhere.
4. **Pass/fail (Assess gate):** a complete label + reviewer + permission inventory exists; the auto-delete
   labels that records/legal require to be reviewed are identified; no change was made (read-only).

## Stage 2 — Design (map the review requirement to Purview)
Translate the records/legal review requirement into a concrete artefact map. Produce a design table with,
for each review category:
- **Category → label:** the retain-then-delete retention label that carries the review (existing label from
  the org-wide records product, or a new `Disposition Label – … – Pilot`).
- **Stages:** single-stage, or an **ordered** list of stages (e.g. `Records → Compliance → Legal`).
- **Reviewers per stage:** the mail-enabled group per stage (`Disposition Reviewers – <Function> – StageN`)
  and its members — all of whom go into **Disposition Management**.
- **Retention action + duration:** retain-then-delete and the period (from the schedule — not invented). For
  the **pilot**, define short-duration disposable test labels so a full cycle completes in the pilot window.
- **Application:** publish or auto-apply, scoped to `Scope – Disposition-Pilot – Static` only.
- **Evidence expectation:** the proof-of-disposal / audit trail to be captured at the end of the cycle.

Name every artefact now (Section 1 table) and record the pilot scope. **Pass/fail (Design gate):** every
review category maps to a named label with stage count/order, per-stage reviewer groups, action/duration,
application method, and pilot scope; records/legal has signed off the stage model and reviewer population,
and confirmed the final disposition authority.

## Stage 3 — Configure (build, staged safe)
Build in this order. **Configuration scripts default to `-WhatIf`/dry-run and only write with `-Commit`.**

### 3a. Reviewer stages and the Disposition Management permission
Ensure every reviewer can actually act **before** any content reaches the queue. Run
**`Set-DispositionReviewers.ps1`** to validate each stage's mail-enabled group resolves and every member is
in **Disposition Management**, adding missing members with `-Commit`:
```powershell
# Reviewers must be in the Disposition Management role group to see/act on the queue (S&C PowerShell)
Add-RoleGroupMember -Identity "Disposition Management" -Member "records-reviewer@contoso.com"
Get-RoleGroupMember  -Identity "Disposition Management"     # verify
```
*(Grant Disposition Management **only** to named reviewers — role separation, 2.3.)*

### 3b. Disposition-review labels (single- and multi-stage)
Create or update the retention labels with disposition review via **`Set-DispositionReview.ps1`** (which
wraps `New-ComplianceTag` / `Set-ComplianceTag` with a `-WhatIf` default and drives from a JSON design).
Where the label already exists (org-wide records product), the script **adds/verifies** the review
configuration rather than re-creating it. The intent the script commits with `-Commit`:
```powershell
# Single-stage disposition review (retain-then-delete; one reviewer set)
New-ComplianceTag -Name "Disposition Label - Records-7yr - Pilot" -RetentionAction KeepAndDelete `
  -RetentionDuration 2555 -RetentionType ModificationAgeInDays `
  -ReviewerEmail "disposition-reviewers-records@contoso.com"

# Multi-stage disposition review (ordered stages; disposal only after the FINAL stage approves)
# NOTE: the multi-stage property shape is newer and has changed across releases — VERIFY in your tenant.
$multiStage = @{
    MultiStageReviewSettings = @(
        @{ StageName = "Records";    Reviewers = @("disposition-reviewers-records@contoso.com") },
        @{ StageName = "Compliance"; Reviewers = @("disposition-reviewers-compliance@contoso.com") },
        @{ StageName = "Legal";      Reviewers = @("disposition-reviewers-legal@contoso.com") }
    )
} | ConvertTo-Json -Depth 4
New-ComplianceTag -Name "Disposition Label - Contracts-7yr-MS - Pilot" -RetentionAction KeepAndDelete `
  -RetentionDuration 2555 -RetentionType ModificationAgeInDays -MultiStageReviewProperty $multiStage
```
> **Confirm the parameter shape.** `-MultiStageReviewProperty` and its stage schema are relatively new and
> the exact property names/limits have changed between releases. The script builds this object for you and
> **echoes it under `-WhatIf`** so you can confirm it against the current Microsoft docs and your tenant
> **before** committing. Do not assume the shape above without verifying.

### 3c. Publish / auto-apply the disposition labels to the pilot scope
Make the labels available on pilot content only, via a pilot-scoped label policy:
```powershell
# Publish for pilot users to apply (pilot scope only)
New-RetentionCompliancePolicy -Name "Label Policy - Disposition-Publish - Pilot" `
  -SharePointLocation "https://contoso.sharepoint.com/sites/DispositionPilot" `
  -ExchangeLocation "pilotuser@contoso.com"
New-RetentionComplianceRule -Policy "Label Policy - Disposition-Publish - Pilot" `
  -PublishComplianceTag "Disposition Label - Records-7yr - Pilot"

# OR auto-apply by a condition from the schedule (pilot scope) — condition provided, not invented
New-RetentionCompliancePolicy -Name "Label Policy - Disposition-AutoApply - Pilot" `
  -SharePointLocation "https://contoso.sharepoint.com/sites/DispositionPilot"
New-RetentionComplianceRule -Policy "Label Policy - Disposition-AutoApply - Pilot" `
  -ApplyComplianceTag "Disposition Label - Contracts-7yr-MS - Pilot" -ContentMatchQuery '"master services agreement"'
```
*(Retention-label/policy mechanics in depth are the org-wide Data Lifecycle & Records Management product's
province — referenced here, scoped to the pilot.)*

**Pass/fail (Configure gate):** every designed disposition label exists with the correct action, duration,
and **review configuration** (single/multi-stage as designed); every stage's reviewers are in **Disposition
Management**; the label policy is scoped to the **pilot only**; and nothing is published tenant-wide.

## Stage 4 — Pilot (prove a full review cycle on the bounded scope)
1. Apply a **short-duration disposable test** disposition label to test content in `Scope – Disposition-
   Pilot – Static` (publish for pilot users, or let auto-apply match). Use a test label with a very short
   retention so the item reaches expiry within the pilot window.
2. Let the item **reach expiry** and enter the **Disposition** queue (Microsoft Purview → **Records
   management → Disposition**). Confirm reviewers receive **notification** email.
3. **Exercise the full cycle in the portal** as the reviewers:
   - Confirm each stage's reviewers see **only** their labels' items.
   - **Single-stage:** one reviewer approves permanent deletion → item is disposed.
   - **Multi-stage:** Stage 1 approves → item advances to Stage 2 → … → **final** stage approves → item is
     disposed. Also test the **extend** and **relabel** actions on separate test items (they stop disposal).
4. After the (test) disposition completes, **capture the evidence**: the disposition record / proof of
   disposal in the portal and the corresponding **audit** events. Run `Get-DispositionEvidenceReport.ps1`
   to compile the configuration + evidence pointers.
5. Allow for **propagation** (hours to days — do not judge in minutes). **Pass/fail (Pilot gate):** on pilot
   content, review-enabled items route to review (never auto-delete), stages advance in order, disposal
   occurs only after the **final** approval, extend/relabel stop disposal, reviewers see only their scope,
   and a **proof-of-disposal + audit trail exists** — all without affecting content outside the pilot.

## Stage 5 — Validate
Work the Section 5 test procedures; every gate has an explicit pass/fail, including the **evidence** gate.
Run **`Get-DispositionEvidenceReport.ps1`** to produce `Disposition Evidence – Tenant – Report`. Do not
expand until all pass.

## Stage 6 — Expand (govern production content)
1. Mint the **production** artefacts by swapping `– Pilot` for `– Prod` (never edit a validated pilot
   artefact in place): e.g. `Disposition Label – Records-7yr – Prod`, `Label Policy – Disposition-Publish –
   Prod`. Use the **real** retention durations from the schedule (not the short test durations).
2. Publish/auto-apply the production disposition labels to the in-scope locations under change control —
   staged in **rings** (by department/site) rather than a single tenant-wide flip where the schedule allows.
3. Confirm reviewer stages and Disposition Management membership are in place at production scale; re-run
   the evidence report after each ring.
4. **Pass/fail (Expand gate):** production disposition labels apply across the in-scope locations, the
   Disposition queue populates for review categories, disposal occurs only after final-stage approval, and
   the evidence report shows expected coverage with no review category silently auto-deleting.

---

## Rollback (per stage)
- **Label policies / publication (reversible):** disable or unpublish the label policy
  (`Set-RetentionCompliancePolicy -Enabled $false`, or remove/disable its rule) so the disposition label is
  no longer published/auto-applied. Content already labelled keeps its label until changed.
- **Review configuration on a not-yet-expired label (reversible):** a disposition label whose items have not
  yet reached expiry can have its review configuration adjusted or the label removed from items; adjust
  reviewer-group membership (`Remove-RoleGroupMember`, edit the mail-enabled group) as needed.
- **Reviewer permission (reversible):** remove an account from **Disposition Management**
  (`Remove-RoleGroupMember -Identity "Disposition Management"`) to revoke queue access.
- **IRREVERSIBLE — no rollback:** a **completed (approved) disposition** — content is permanently deleted.
  This is why the full cycle is exercised only on **disposable test content** in pilot and why the final
  disposition authority is records/legal. Never exercise a real disposition to "test" rollback.

Every production change carries a change ticket, an approver, and this rollback written out for the specific
categories in scope, with **completed disposition** explicitly flagged **no-rollback**.


---


# 5. Testing & Validation

Ten procedures, each with an explicit **pass/fail**. Run them at the **Pilot** and **Expand** gates.
Disposition behaviour is **eventually consistent** — allow for service propagation (hours to days) before
declaring a fail, and use **short-duration disposable test labels** so a full cycle completes in the pilot
window. **Never approve a real production disposition as a test** — exercise the delete path only on
disposable test content you are prepared to lose.

---

### T1 — Toolchain, cloud & permission health
- **Do:** Run `Resolve-DispositionScope.ps1`.
- **Pass:** `Connect-IPPSSession` (and Graph where used) succeed; the correct cloud is reported;
  `Get-ComplianceTag` and `Get-RoleGroupMember -Identity "Disposition Management"` return; the pilot scope
  resolves.
- **Fail:** any connection fails, the wrong cloud/endpoint is reported, the Disposition Management role
  group is unreachable, or the scope does not resolve.

### T2 — Baseline posture captured (read-only)
- **Do:** Run `Assess-DispositionPosture.ps1`.
- **Pass:** `Disposition Posture – Tenant – Discovery` lists retention labels with action, and for
  retain-then-delete labels whether review is enabled (single/multi-stage), the stages and reviewers, and
  Disposition Management membership; **auto-delete-with-no-review** labels are flagged; the script made no
  change (read-only).
- **Fail:** the inventory is incomplete, the auto-delete gap is not surfaced, or the script wrote anything.

### T3 — Disposition labels configured as designed
- **Do:** `Get-ComplianceTag` for each designed disposition label.
- **Pass:** each label exists with `RetentionAction = KeepAndDelete`, the correct duration/trigger, and the
  designed **review configuration** — single-stage `ReviewerEmail`, or multi-stage stages in the **correct
  order** with the correct reviewers — matching the Stage 2 design.
- **Fail:** any label is missing, auto-deletes when review was designed, or its stage count/order/reviewers
  differ from the design.

### T4 — Reviewers can actually act (Disposition Management)
- **Do:** `Get-RoleGroupMember -Identity "Disposition Management"`; cross-check against every stage's
  reviewer group; as a reviewer, open Microsoft Purview → **Records management → Disposition**.
- **Pass:** every stage reviewer is in **Disposition Management** and can see the Disposition area; reviewers
  see **only** the labels for which they are a reviewer; no non-reviewer is over-granted.
- **Fail:** a reviewer is missing from Disposition Management (cannot see the queue), a reviewer sees items
  outside their scope, or accounts are over-granted.

### T5 — Label publish / auto-apply reaches the pilot only
- **Do:** As a pilot user, confirm the disposition label is selectable (Outlook/SharePoint/OneDrive), or
  create content matching an auto-apply condition and wait for propagation.
- **Pass:** the disposition label appears for / applies to pilot content only; no content outside
  `Scope – Disposition-Pilot – Static` is affected.
- **Fail:** the label does not appear, applies to the wrong scope, or the wrong label is applied.

### T6 — Expiring content routes to review (does NOT auto-delete)
- **Do:** Let a short-duration disposable test item reach expiry; observe the **Disposition** queue.
- **Pass:** at end of retention the item **enters the Disposition queue** for review and is **not** deleted;
  reviewers receive notification email.
- **Fail:** the item auto-deletes when a review was required, never appears in the queue, or no notification
  is sent.

### T7 — Single-stage disposition completes and disposes
- **Do:** For a single-stage test label, have the reviewer **approve permanent deletion** in the portal.
- **Pass:** the item is permanently disposed after the single approval; a disposition record / proof of
  disposal is produced.
- **Fail:** approval does not dispose the item, or no proof is recorded.

### T8 — Multi-stage advances in order and disposes only after the final stage
- **Do:** For a multi-stage test label, approve **Stage 1** and observe advancement; on separate test items,
  exercise **extend retention** and **relabel/apply different label**.
- **Pass:** approval advances the item to the **next** stage; disposal occurs **only after the final stage
  approves**; **extend** and **relabel** stop disposal and behave as designed; a non-final approval never
  deletes.
- **Fail:** the item disposes before the final stage, stages advance out of order, or extend/relabel do not
  stop disposal. *(If your tenant does not offer multi-stage, record it as plan-limited and validate
  single-stage only.)*

### T9 — Proof of disposal & audit evidence exist (defensibility)
- **Do:** After a (test) disposition completes, capture the **disposition record / proof of disposal** in
  the portal Disposition export and the corresponding **audit** events (`Search-UnifiedAuditLog`).
- **Pass:** an exportable proof-of-disposal exists for the disposed item (what, who approved each stage,
  when) and matching audit events are present — the defensible-disposal evidence trail.
- **Fail:** no proof of disposal is retained, the reviewer/stage attribution is missing, or audit events are
  absent.

### T10 — Evidence/compliance report reflects reality
- **Do:** Run `Get-DispositionEvidenceReport.ps1` to produce `Disposition Evidence – Tenant – Report`.
- **Pass:** the report shows, per label, the review configuration (single/multi-stage, stages, reviewers),
  Disposition Management coverage, and flags gaps (auto-delete-no-review labels, reviewers-not-in-DM,
  empty stages), and points to the portal Disposition export + audit log for the item-level proof —
  consistent with T3–T9.
- **Fail:** the report disagrees with observed state, omits configured labels, or fails to flag a known gap.

---

**Overall gate.** The pilot passes only when T1–T10 pass on the pilot scope with no effect outside it —
including a **full review cycle** (T6–T9) proven on disposable test content with its evidence trail.
Expansion passes only when T3–T10 pass at production scope with expected coverage and **no review category
silently auto-deleting**. Any fail on the **irreversible** path (a completed disposition without the
designed stages/approvals, or missing proof of disposal) halts the rollout pending records/legal review.


---


# 6. Troubleshooting

Common failure modes when standing up and running a disposition review program in Microsoft Purview, with
causes and resolutions. Most disposition behaviour is **eventually consistent** — allow for service
propagation (hours to days) before treating slow behaviour as a fault. **No fix here approves, extends, or
deletes a disposition** — those are reviewer (records/legal) actions in the portal.

---

## Connection, licensing & roles

**`Connect-IPPSSession` fails or `Get-ComplianceTag` errors.**
- Cause: module missing/old, non-modern-auth account, or wrong cloud endpoint.
- Fix: install/update **ExchangeOnlineManagement**; sign in with an MFA-capable admin; in GCC/GCC High/DoD
  pass the correct `-ConnectionUri`. Run `Resolve-DispositionScope.ps1` to confirm health and cloud.

**The label editor doesn't offer "disposition review" (or multi-stage).**
- Cause: the tenant lacks the required compliance entitlement, or multi-stage is not available on that plan.
- Fix: verify the compliance plan/add-on (2.1) in the M365 admin center; confirm **Records management** is
  visible and that a retain-then-delete label offers review. Multi-stage is newer and plan-dependent —
  **verify availability in your tenant**; fall back to single-stage where multi-stage is not offered.

**Admin can create labels but can't manage disposition, or vice versa.**
- Cause: role split not applied — creating labels needs Records Management / Compliance Administrator;
  seeing the queue needs **Disposition Management**.
- Fix: grant the configuring admin the least-privilege records/compliance role and reviewers **Disposition
  Management** (2.3) — deliberately separate, per role-separation best practice.

## Reviewers can't see or act on the queue

**A reviewer opens Records management → Disposition and sees nothing / no queue.**
- Cause: the reviewer is **not in the Disposition Management role group** (most common), or no items have
  reached expiry yet, or the reviewer isn't a named reviewer on any expiring label.
- Fix: `Get-RoleGroupMember -Identity "Disposition Management"` and confirm the reviewer is present; add
  with `Add-RoleGroupMember` (or run `Set-DispositionReviewers.ps1 -Commit`). Confirm the reviewer is a
  reviewer on a label whose items have actually expired. Allow for propagation after adding to the role.

**A reviewer sees items they shouldn't (wrong scope).**
- Cause: the reviewer is a reviewer on more labels than intended, or a stage's reviewer group has extra
  members.
- Fix: reviewers see only the labels they are a reviewer for — audit the stage groups and the label reviewer
  lists (`Assess-DispositionPosture.ps1`); tighten the mail-enabled group membership.

**Reviewers aren't getting notification / reminder email.**
- Cause: reviewer has no mailbox, notifications/reminders are disabled in disposition settings, or mail is
  filtered.
- Fix: confirm each reviewer is mailbox-enabled (2.4); check the disposition notification/reminder settings
  in the portal (**verify the exact setting location in your tenant** — it evolves); check mail flow/junk.

## Labels & routing

**Content is auto-deleting instead of routing to review.**
- Cause: the label is retain-then-delete **without disposition review enabled** — the exact gap this program
  closes.
- Fix: `Get-ComplianceTag` the label; if review is not configured, add it (`Set-DispositionReview.ps1`) so
  the category routes to review. `Assess-DispositionPosture.ps1` flags every auto-delete-no-review label.

**`New-/Set-ComplianceTag -MultiStageReviewProperty` is rejected or the stages don't take.**
- Cause: the multi-stage property **shape/name has changed across releases**, the plan doesn't support
  multi-stage, or the JSON depth/keys don't match the current schema.
- Fix: run `Set-DispositionReview.ps1 -WhatIf` to **echo** the property object and compare it against
  current Microsoft docs and your tenant before committing; confirm the plan supports multi-stage; adjust
  the JSON to the current schema. Where multi-stage isn't available, use single-stage `-ReviewerEmail`.

**The disposition label isn't appearing for pilot users / not auto-applying.**
- Cause: label policy not published to the pilot locations, still propagating, or the auto-apply condition
  doesn't match.
- Fix: confirm the `Label Policy – Disposition-Publish – Pilot` (or `-AutoApply`) policy is scoped to the
  pilot locations and enabled; allow propagation (hours to days); verify the `-ContentMatchQuery` matches
  test content.

## Disposition cycle & evidence

**An item reached expiry but never entered the Disposition queue.**
- Cause: propagation latency, the label doesn't actually have review enabled, or the item is under a **legal
  hold** (hold overrides disposition).
- Fix: allow time; re-confirm the label's review config (T3); check whether the item is on hold — held
  content is exempt from disposal and stays out of the disposition path (legal/eDiscovery owns holds, 2.6).

**Multi-stage item disposed before the final stage (or didn't advance).**
- Cause: mis-configured stage order, or extend/relabel not behaving as expected.
- Fix: re-verify stage order in `Get-ComplianceTag`; disposal must occur **only after the final stage** —
  re-run T8. If a stage isn't advancing, confirm that stage's reviewers are in Disposition Management and
  are acting on the correct item.

**No proof of disposal / audit evidence after a disposition completed.**
- Cause: looking in the wrong place — disposition items aren't enumerable via a supported cmdlet.
- Fix: export the **disposition record / proof of disposal** from the portal **Records management →
  Disposition** area and corroborate with `Search-UnifiedAuditLog`. `Get-DispositionEvidenceReport.ps1`
  compiles the configuration and points to these sources; the item-level proof lives in the portal export +
  audit log, not in a cmdlet inventory.

**The evidence report disagrees with what I see in the portal.**
- Cause: stale run (propagation), or the report is reading a different scope than expected.
- Fix: re-run `Get-DispositionEvidenceReport.ps1` after propagation; confirm the labels/scope it read match
  the pilot/production scope; the report reflects **configuration** — item-level truth is the portal export.

## Cloud & latency

**GCC / GCC High / DoD paths or cmdlets differ.**
- Cause: Government clouds use different portal URLs (`*.office365.us`) and connection endpoints, and some
  features differ.
- Fix: use the correct `Connect-IPPSSession -ConnectionUri`, verify portal paths and disposition/multi-stage
  availability in your cloud — do not assume Commercial parity.

**Everything is slow / a pilot cycle isn't completing.**
- Cause: normal eventual consistency — application, expiry, queue entry, notification, and disposal run on
  service timers.
- Fix: use **short-duration disposable test labels** so expiry occurs within the pilot window; allow hours
  to days for each transition; never judge a cycle in the first minutes.


---


# 7. Best Practices

Durable practices for running a disposition review program in Microsoft Purview. They encode the house
model — pilot-first, evidence-based, records/legal-owned determinations, strict role separation — into
day-to-day operation.

## Governance & ownership
- **Records/legal own the decision; you own the workflow.** Never invent which categories require review,
  how many stages, who reviews, or the disposition outcome. This program delivers the *method* and the
  *evidence*; the determination to delete, extend, or relabel is the reviewer's (records/legal) call.
- **Keep the review requirement traceable.** Maintain a link from each disposition label back to the
  records/legal requirement that says it must be reviewed and to the stage/reviewer decision — so the
  configuration is auditable against its authority.
- **Align to the org-wide records program, don't duplicate it.** Retention labels, policies, event-based
  retention, records declaration, and the file plan are the Data Lifecycle & Records Management product's
  province. This program **adds/verifies disposition review** on those labels and keeps label names
  consistent — it does not mint parallel labels.

## Role separation (a compliance control, not a convenience)
- **Reviewers get Disposition Management and nothing more.** Membership in **Disposition Management** is
  what lets a reviewer see and act on the queue; grant it **only** to named reviewers and keep it separate
  from the admin who configures labels/stages, so the person disposing content is not the person who set the
  schedule.
- **Manage stage reviewers via mail-enabled groups.** Address each stage with a mail-enabled security group
  and manage membership there — never hard-code individual reviewers into the label, which forces a label
  edit on every personnel change. Keep each group's members in Disposition Management.
- **Review permission membership periodically.** Reviewers change roles; a stale Disposition Management
  membership is both a broken queue (missing reviewers) and an over-grant (departed reviewers) — audit it.

## Multi-stage design
- **Add stages only where accountability requires them.** Each stage is a real sign-off, not decoration —
  more stages mean slower disposal and larger backlogs. Use single-stage where one authority suffices;
  reserve multi-stage (e.g. `Records → Compliance → Legal`) for genuinely high-value categories.
- **Order stages deliberately and validate the order.** Disposal happens only after the **final** stage —
  design the sequence from the records/legal requirement and prove advancement order in pilot; never assume
  it.
- **Verify the multi-stage capability in your tenant.** Multi-stage disposition review is newer than
  single-stage, is plan-dependent, and its configuration shape has changed across releases — confirm
  availability and the exact property model against current Microsoft docs before relying on it.

## Change-safety
- **Publish to pilot, prove a full cycle, then govern production.** Disposition labels are published to the
  pilot scope with short-duration disposable test content so a **complete** review-and-dispose cycle
  (including proof of disposal) is validated before any production content is governed.
- **Ring your rollout.** Expand by department/site/workload ring rather than a single tenant-wide flip;
  re-run the evidence report after each ring and confirm no review category is silently auto-deleting.
- **Write the rollback — and flag the irreversible part.** Reversible: disable/unpublish the label policy,
  adjust reviewer-group and Disposition Management membership, change review config on not-yet-expired
  labels. **No-rollback:** a completed (approved) disposition permanently deletes content. Every change
  ticket states which is which and never exercises a real disposition to test rollback.

## Operations & evidence
- **Work the disposition queue on a cadence.** Reviewed disposition is only defensible if reviewers actually
  act. Monitor the pending-disposition backlog and reviewer coverage per stage — a growing backlog is an
  operational and compliance risk, not just a metric. Ensure notifications/reminders are enabled.
- **Treat proof of disposal as the deliverable.** The value of this program is the evidence: for each
  disposed item, *what* was disposed, *who* approved each stage, and *when*. Export the disposition record
  from the portal and corroborate with the audit log; retain it per your evidence-retention requirement.
- **Report regularly.** Run the evidence/compliance report on a schedule; watch review-config coverage,
  Disposition Management membership, empty stages, and the auto-delete-no-review gap.
- **Respect eventual consistency.** Application, expiry, queue entry, notification, and disposal run on
  timers (hours to days). Build that latency into expectations and never judge a cycle in the first minutes.
- **Respect the legal-hold boundary.** Content under legal/eDiscovery hold is exempt from disposal even
  after review approval — hold management stays with legal/eDiscovery; do not attempt to manage holds from
  this program.
- **Keep automation credential-free and safe-by-default.** All scripts use interactive modern auth; never
  embed secrets. Assessment and reporting stay read-only; configuration is `-WhatIf`-by-default with an
  explicit `-Commit`; no script approves, extends, or deletes a disposition.

## Cloud & plan discipline
- **Verify by cloud.** In GCC/GCC High/DoD, confirm portal paths, endpoints (`Connect-IPPSSession
  -ConnectionUri`), and feature availability — do not assume Commercial parity.
- **Verify by plan.** Disposition review (and multi-stage in particular) is plan-gated. Confirm the tenant's
  entitlement and the current configuration shape before designing, rather than assuming a capability is
  present.


---


# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
- **Solution Overview** — what a disposition review program is; the scope boundary (the **review workflow**,
  not the retention schedule or the disposition decision); how single- and **multi-stage** disposition
  review works on a retain-then-delete label in Microsoft Purview; the reviewer/permission model with role
  separation; how defensible disposal and the proof-of-disposal evidence trail work; the reference design;
  what's deferred to records/legal and to the org-wide records product; limitations; and the deployment
  model.
- **Requirements Guide** — solution-specific prerequisites (compliance licensing for single/multi-stage
  review; the review requirement from records/legal; roles incl. **Disposition Management** with role
  separation; reviewer groups/mailboxes; existing label posture verified not duplicated; the legal-hold
  boundary; the S&C PowerShell / Graph toolchain; change control + rollback), each with how to verify and
  implement, building on the Purview category global requirements.
- **Implementation Guide** — Assess → Design → Configure → Pilot → Validate → Expand, with every artefact
  named, reviewer stages and Disposition Management wired **before** content reaches the queue, single- and
  multi-stage disposition labels built (multi-stage property echoed under `-WhatIf` for verification),
  labels published to the **pilot scope** only, a **full review cycle** exercised on short-duration
  disposable test content, explicit pass/fail gates per stage, and a documented rollback that flags the
  **irreversible** completed-disposition.
- **Testing & Validation** — 10 procedures, each with an explicit pass/fail, covering toolchain/permission
  health, baseline posture, label review-config, reviewer ability to act, pilot-scoped application,
  route-to-review (no auto-delete), single-stage disposal, multi-stage ordering + extend/relabel, the
  proof-of-disposal + audit evidence trail, and the evidence/compliance report.
- **Troubleshooting** — common failure modes (connection/roles/plan, reviewers can't see the queue, labels
  auto-deleting instead of reviewing, multi-stage property rejected, notifications not arriving, items not
  entering the queue, disposal not completing, missing proof of disposal, legal-hold interaction,
  Government-cloud paths, propagation latency) and resolutions.
- **Best Practices** — governance/ownership, role separation as a compliance control, multi-stage design,
  change-safety, operations & evidence, and cloud/plan discipline.
- **Executive Summary** — the outcome, approach, and why it is low-risk, for decision-makers.

## PowerShell scripts (5)
All use modern-auth `Connect-IPPSSession` (Security & Compliance PowerShell) and `Connect-MgGraph` where
noted; **no hardcoded credentials**. Assessment and reporting are read-only; configuration scripts default
to dry-run / `-WhatIf` and only write when `-Commit` is passed; **no script approves, extends, or deletes a
disposition** — reviewers act in the portal.

1. **`Resolve-DispositionScope.ps1`** — *Scope/health helper (read-only).* Checks S&C PowerShell (and
   optional Graph) connectivity, reports the detected cloud/endpoint, confirms retention-label and
   **Disposition Management** role-group cmdlets are reachable, and resolves the pilot scope — the preflight
   before Stage 3.
2. **`Assess-DispositionPosture.ps1`** — *Discovery (read-only).* Inventories retention labels and, for
   retain-then-delete labels, whether disposition review is enabled (single vs multi-stage), the review
   stages and reviewers, and **Disposition Management** membership; flags the key gaps
   (auto-delete-no-review labels, reviewers not in Disposition Management, empty/unresolved stages).
   Produces `Disposition Posture – Tenant – Discovery` (CSVs).
3. **`Set-DispositionReview.ps1`** — *Disposition-label config helper (`-WhatIf` default).* Creates or
   updates retain-then-delete retention labels with **single- or multi-stage** disposition review from a
   JSON design (`New-ComplianceTag` / `Set-ComplianceTag`, `-ReviewerEmail` / `-MultiStageReviewProperty`),
   and publishes/auto-applies them to the pilot scope. Dry-run by default; **echoes the multi-stage property
   for verification** under `-WhatIf`; writes only with `-Commit`; never approves a disposition.
4. **`Set-DispositionReviewers.ps1`** — *Reviewer permission/stage helper (`-WhatIf` default).* Validates
   each stage's mail-enabled reviewer group resolves and that every member is in the **Disposition
   Management** role group, adding missing members (`Add-RoleGroupMember`) with `-Commit`; reports
   over-grants and empty stages. Enforces role separation; dry-run by default.
5. **`Get-DispositionEvidenceReport.ps1`** — *Disposition evidence/compliance report (read-only).* Compiles
   per-label review configuration (single/multi-stage, stages, reviewers), Disposition Management coverage,
   and gap flags into `Disposition Evidence – Tenant – Report` (CSV + HTML), and points to the portal
   **Disposition** export and the audit log for the item-level proof of disposal (disposition items are not
   enumerable via a supported cmdlet). Makes no changes.
