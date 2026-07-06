# Vault ↔ Purview Coexistence — eDiscovery, Legal Hold & Retention

> **Version 1.0.0** · Category: Google · Solution code: GWVAULT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

During a transition between Microsoft 365 and Google Workspace, your organization's records live in
**two governance ecosystems at once** — Microsoft Purview over the M365 estate and Google Vault over
the Workspace estate. Legal and compliance must be able to hold, retain, and discover across **both**.
The dangerous assumption is that a hold placed in one tool reaches the other. It does not. A single
custodian frequently has data on both sides, so a preservation gap here is a legal risk, not a
technical inconvenience.

This is a complete, deploy-it-in-order package for designing **Vault ↔ Purview coexistence** for
eDiscovery, legal hold, and retention — written for a competent administrator partnering with legal
and eDiscovery stakeholders. It gives you the repeatable way to establish what is governed where,
configure Google Vault retention and holds, map them to their Purview counterparts, run defensible
discovery across both systems, and prove it all on a controlled pilot before you scale.

## What you get
- A plain-language Solution Overview of the dual-ecosystem governance model — what data lives in
  Purview vs Vault during coexistence, and how holds, retention, and discovery are coordinated across
  the two (parallel holds, longer-of-two retention, most-restrictive-wins, cross-system reconciliation).
- A Requirements Guide with verify / implement-if-missing for every prerequisite — a Vault-capable
  Workspace edition, Purview eDiscovery access and licensing, legal/eDiscovery stakeholders, a
  retention policy, a matter naming convention, and a pilot custodian scope.
- An Implementation Guide of precise, ordered steps: configure Vault retention rules and holds inside
  named matters, map each to a parallel Purview eDiscovery case/hold, define the discovery workflow
  across both, validate on a pilot, then expand.
- Five PowerShell scripts for retention/hold discovery across the estate, per-scope hold and retention
  validation, a coverage/gap report, safe remediation (default `-WhatIf`), and a scope helper.
- Testing and Troubleshooting guides with explicit validation gates — holds effective, retention
  applied, discovery returns — plus Best Practices for defensible eDiscovery.

## What this delivers
Defensible eDiscovery, legal hold, and retention across **both** Google Vault and Microsoft Purview
— every custodian held and discoverable on both ecosystems, retention aligned so neither side purges a
held record, and discovery reconciled into a single production — with no compliance gap during
coexistence, proven on a pilot before you scale.

## A note on scope: technical mapping, not legal advice
This package provides the **technical** mapping of governance across Vault and Purview. Whether a
retention period, hold scope, or discovery approach satisfies a specific legal or regulatory
obligation is a determination for **legal/records counsel** — engaged here as a named stakeholder.
Vendor-specific specifics (Vault's Gemini-app hold/retention support, the evolving Purview eDiscovery
experience) are cited from current documentation or flagged **"verify in your tenant,"** never invented.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a pilot gate and a rollback at every stage.

## Outcome
A coexistence governance model a single administrator can run and legal can defend at audit: what's
governed where is mapped, Vault holds and retention are configured and mirrored to Purview, discovery
runs across both and reconciles, and the whole loop is proven on a pilot custodian scope before the
full population depends on it — with legal/records counsel owning the legal determinations throughout.


---


# 1. Solution Overview — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

## The problem this solves
During a Microsoft-to-Google (or dual-suite) transition, your organization's electronically stored
information (ESI) lives in **two governance ecosystems at once**: **Microsoft Purview** governs the
Microsoft 365 estate (Exchange Online mailboxes, SharePoint, OneDrive, Teams), and **Google Vault**
governs the Google Workspace estate (Gmail, Drive, Chat, Meet, Groups, Calendar, Voice, Sites, and —
per recent Google updates — the Gemini app). Legal and compliance must be able to **hold, retain,
and discover across both**. The single most dangerous misconception is that a hold placed in one tool
somehow reaches the other. **It does not.** Coexistence is defensible only when holds, retention, and
discovery are *coordinated by design* across the two systems — not assumed to sync.

> **Vendor boundary.** Google Vault (`vault.google.com`), the Google Admin console
> (`admin.google.com`), and the Microsoft **Purview portal** (`purview.microsoft.com`) are authored
> click-by-click from each vendor's current public documentation. Vault's **Gemini app** hold/
> retention support and Purview's evolving **eDiscovery** experience are cited or flagged **"verify in
> your tenant."** **This solution provides the *technical* mapping of governance across the two
> ecosystems; it is not legal advice.** Whether a given retention period, hold scope, or discovery
> approach satisfies a specific regulation or legal obligation is a determination for **legal/records
> counsel** — engage them as named stakeholders (global requirement 6).

## What is governed where (during coexistence)
| Data / workload | Governed by | Preservation & discovery surface |
|---|---|---|
| Gmail, Google Chat, Google Groups, Google Voice | **Google Vault** | Vault retention rules + holds; Vault search/export |
| Google Drive files, Google Sites, Meet recordings, Calendar | **Google Vault** | Vault retention rules + holds; Vault search/export |
| Google **Gemini app** messages | **Google Vault** *(newer capability — verify in your tenant)* | Vault retention rules + litigation holds for the Gemini app |
| Exchange Online mailboxes (incl. Teams 1:1/group chat, card, meeting/call data) | **Microsoft Purview** | Retention policies/labels, Litigation Hold, eDiscovery holds |
| SharePoint sites, OneDrive accounts (incl. Teams channel files) | **Microsoft Purview** | Retention policies/labels, eDiscovery holds (Preservation Hold library) |
| Teams channel conversations | **Microsoft Purview** | Held via the Team's group mailbox + SharePoint site |

The **boundary follows the data's home**: content created and stored in Workspace is a Vault matter;
content created and stored in M365 is a Purview matter. During coexistence a *single custodian* often
has data on **both** sides (e.g. a mailbox migrating from Exchange to Gmail, or files in both OneDrive
and Drive), which is exactly why holds must be issued in parallel.

## How holds and retention map across the two ecosystems
There is **no automatic synchronization** between Vault and Purview. The mapping is operational, not
technical:

- **Legal hold → issue in parallel.** A custodian under legal hold must be placed on hold in **both**
  Vault (a hold inside a Vault **matter**) **and** Purview (an **eDiscovery hold policy** inside an
  eDiscovery **case**), for every workload where that custodian has data. One playbook, two systems,
  the same named custodians on each side.
- **Retention → align to the longer of the two.** Where the same class of record exists on both
  sides, set the retention period on each platform to the **longer** of the two schedules, so the
  stricter obligation is satisfied by default and content is not purged out from under a hold.
- **Most-restrictive-preservation-wins (within each platform).** On each side, multiple preservation
  sources can coexist and any one is enough to keep content:
  - **Vault:** a **hold** retains data **indefinitely** and **takes precedence** over default and
    custom retention rules. (Source: Google Vault Help.)
  - **Purview:** eDiscovery holds, retention policies, retention labels, **Litigation Hold**, delay
    holds, and Single Item Recovery each independently preserve content — the most restrictive wins.
    (Source: Microsoft Learn.)
- **Discovery → collect from both, reconcile in one place.** Defensible discovery searches **both**
  Vault (search + export by matter) **and** Purview (search + export by case), then reconciles the two
  export sets into a single production so nothing in the coexistence gap is missed.

## The coexistence eDiscovery model
1. **Inventory the estate** — which custodians and record classes live in Vault, in Purview, or
   (during migration) in both. This is the coverage map every hold and search works from.
2. **Name matters/cases once, reuse everywhere** — a matter/case name that is identical on both
   platforms (e.g. `Litigation – Acme v. Example – Hold`) so a custodian's Vault matter and Purview
   case are unmistakably the same legal matter.
3. **Hold in parallel** — issue the hold in Vault and in Purview for every workload the custodian
   touches; record both hold IDs against the one matter.
4. **Retain to the longer schedule** — align Vault retention rules and Purview retention policies so
   neither side purges a record the other must keep.
5. **Discover across both** — run the matched search on each side, export, and reconcile.
6. **Prove it on a pilot** — validate the whole loop (hold effective, retention applied, discovery
   returns the right data on both sides) on a small pilot before extending to all custodians.

## Benefits
- **No coexistence gap** — every custodian is held and discoverable on **both** ecosystems, so a
  transition does not create a preservation blind spot.
- **Defensible by design** — parallel holds, longer-of-two retention, and cross-system reconciliation
  are documented and repeatable, not ad hoc.
- **One playbook, two systems** — a single matter naming convention and custodian list drives both
  Vault and Purview, so legal reasons about *the matter*, not the tooling.
- **Proven before scaled** — the pilot gate confirms holds are effective and discovery returns data
  before the whole custodian population depends on it.
- **Audit-ready** — coverage/gap reporting shows exactly what is held and retained where.

## Limitations (be honest with buyers)
- **No cross-system sync.** Vault and Purview do not talk to each other; parallel administration is
  inherent to coexistence and is the work this solution operationalizes.
- **This is the technical mapping, not legal advice.** Retention *periods*, hold *triggers*, and
  what "defensible" requires for a given matter are legal/records-counsel determinations — engage
  them. This package does not interpret regulation.
- **Licensing gates capability on each side.** Vault requires a Vault-capable Workspace edition;
  Purview eDiscovery holds require an eligible license on **every held user** (frontline tiers such as
  F1/F3 cannot be the *target* of an eDiscovery hold; query-based/custodian-scoped holds require E5/
  A5/G5-class or the E5 Compliance / eDiscovery add-ons). **Verify licensing before you begin.**
- **Evolving surfaces.** Vault's Gemini-app hold/retention support and the Purview eDiscovery
  experience are changing — admin paths are flagged **"verify in your tenant"** and volatile
  specifics are deferred to the vendors' documentation, never invented.

## The deployment model
> **Assess what's governed where → Configure Vault retention/holds and map to Purview → Pilot with a
> small custodian scope → Validate holds effective / retention applied / discovery returns on both →
> Expand.** The pattern is **Assess → Configure → Pilot → Validate → Expand**, with an explicit pilot
> gate and a documented rollback for every production change.


---


# 2. Requirements Guide — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-google.md`.

> **Vendor boundary.** Google Vault and Google Admin console paths, and the Microsoft **Purview
> portal** paths, are authored from each vendor's current public documentation. Vault's **Gemini-app**
> hold/retention support and the evolving Purview eDiscovery experience are flagged **"verify in your
> tenant."** Retention *periods* and hold *triggers* are **legal/records-counsel determinations** —
> this guide covers the technical prerequisites, not the legal ones.

## 2.1 Vault-capable Google Workspace edition + Vault privileges
**Description:** A Google Workspace edition that includes **Google Vault**, with an admin account holding **Vault privileges** (Manage Matters, Manage Holds, Manage Searches/Exports, Manage Retention as needed).
**Why:** All Google-side retention, holds, search, and export are performed in Vault; without a Vault-capable edition and Vault privileges there is no Google-side governance surface.
**Verify:** Sign in to `vault.google.com` — if Vault loads and **Matters** / **Retention** are visible, the edition and privileges are present. In the Admin console, confirm Vault is on for the relevant OUs (**Apps → Google Workspace → Vault**) and privileges under **Account → Admin roles** (Vault privileges) / **Security → Access and data controls → Vault**.
**Implement:** Acquire a Vault-capable Workspace edition through Google or an authorized reseller; turn Vault on for the relevant OUs and assign an admin role with the required Vault privileges (reserve super-admin for tenant-wide changes).

## 2.2 Microsoft Purview eDiscovery access + eligible licensing
**Description:** Access to the **Microsoft Purview portal** (`purview.microsoft.com`) with **eDiscovery** permissions, and — critically — an **eligible license on every user whose content will be held**.
**Why:** The Microsoft-side estate (Exchange, SharePoint, OneDrive, Teams) is held and discovered in Purview. eDiscovery holds require an eligible license on each **held** user; frontline tiers (Office 365 F1/F3) **cannot be the target** of an eDiscovery hold, and query-based / custodian-scoped holds require higher tiers (M365 E5/A5/G5 or the E5 Compliance / E5 eDiscovery & Audit add-ons). (Source: Microsoft Learn.)
**Verify:** Sign in to `purview.microsoft.com`; the **eDiscovery** solution card and **Cases** are available. Confirm each in-scope custodian's assigned subscription includes eDiscovery-hold rights.
**Implement:** Assign eDiscovery permissions/roles; **before** placing a user on hold, assign the required subscription/add-on to any custodian whose tier lacks hold rights (placing an unlicensed user on hold is not supported).

## 2.3 Estate inventory — what's governed where
**Description:** A documented map of which custodians and record classes live in **Vault** (Workspace), in **Purview** (M365), or — during migration — in **both**.
**Why:** Every hold and search works from this coverage map; a custodian with data on both sides must be held on both. Without the inventory, coexistence gaps are invisible.
**Verify:** Run `GWVAULT-Discovery.ps1` (enumerates Vault matters/holds/retention and flags Purview-side coverage to confirm) and review `GWVAULT-Report.ps1`. Cross-check Vault **Matters/Retention** and Purview **Cases/Hold policies**.
**Implement:** Complete the inventory in Implementation Step 1 before configuring holds.

## 2.4 Retention policy (records schedule) — legally approved
**Description:** An organization **retention/records schedule** — approved by legal/records counsel — defining how long each record class must be kept (and when it may be deleted).
**Why:** Vault retention rules and Purview retention policies must both be configured to this schedule; where a class exists on both sides, both are aligned to the **longer** of the two so nothing is purged out from under a hold. The *periods themselves* are a legal determination, not a technical default.
**Verify:** A written, counsel-approved retention schedule exists and names the record classes in scope on each platform.
**Implement:** Obtain the approved schedule from legal/records before configuring any retention rule; do not invent retention periods.

## 2.5 Matter / case naming convention (identical across both)
**Description:** A naming convention so a legal matter is named **identically** in Vault (a **matter**) and Purview (an eDiscovery **case**), in the form `<Purpose> – <Scope> – <Stage>` — e.g. `Litigation – Acme v. Example – Hold`.
**Why:** Parallel holds are only defensible if a custodian's Vault matter and Purview case are unmistakably the same legal matter; matched names make coverage auditable and reconciliation reliable.
**Verify:** The convention is agreed with legal/eDiscovery; matched names are reserved. Or run `GWVAULT-Set-ScopeTargeting.ps1` (default `-WhatIf`) to preview a matched matter scope.
**Implement:** Agree the convention with legal; reserve the matched matter/case names before creating holds (Implementation Step 2).

## 2.6 Legal / eDiscovery stakeholders + change control
**Description:** Engagement with **legal, records management, and eDiscovery** stakeholders (the hold owners and approvers), and a documented change/rollback process for hold, retention, and discovery changes.
**Why:** Holds, retention periods, and discovery scope are legal decisions with legal consequences (spoliation risk if under-preserved; cost/over-collection risk if over-preserved). Legal owns the *what*; this solution operationalizes the *how*. A pilot gate and rollback are mandatory (global requirement 6).
**Verify:** Named legal/eDiscovery owners and approvers are confirmed; a change ticket exists with an approver, a window, and a rollback step (e.g. release a hold, revert a retention rule).
**Implement:** Identify the legal/eDiscovery owners and obtain the hold list and retention schedule; record the change and rollback before touching production.

## 2.7 Pilot custodian scope
**Description:** A small **pilot scope of custodians** (an OU/group on the Google side and the matching users on the Microsoft side) to validate the whole hold → retention → discovery loop before extending to all custodians.
**Why:** The coexistence loop (parallel holds effective, retention applied, discovery returns on both) must be proven small before the full population depends on it (pilot gate + rollback).
**Verify:** A named pilot custodian scope exists on both platforms. Or run `GWVAULT-Set-ScopeTargeting.ps1` to preview/create the Google-side scope group.
**Implement:** Create the pilot scope group with `GWVAULT-Set-ScopeTargeting.ps1` (or Admin console → **Directory → Groups**), and identify the matching Purview custodians.

## 2.8 Search/export readiness (both platforms)
**Description:** The ability to run and **export** searches on both sides — Vault **search + export** (by matter) and Purview **search + export** (by case) — and a place to reconcile the two export sets.
**Why:** Defensible discovery collects from both ecosystems and reconciles into one production; if either side cannot export, the coexistence discovery is incomplete.
**Verify:** In Vault, a matter can run a search and export; in Purview, a case search can export. Confirm the operator holds the export privileges on both.
**Implement:** Grant Vault search/export privileges and Purview eDiscovery export roles; define where reconciled productions are assembled and stored under counsel's direction.

---
## Checklist
- [ ] Vault-capable Workspace edition + Vault privileges (Matters/Holds/Retention/Search-Export)
- [ ] Purview portal eDiscovery access **and eligible license on every held custodian**
- [ ] Estate inventory — what's governed where (`GWVAULT-Discovery.ps1` / `GWVAULT-Report.ps1`)
- [ ] Counsel-approved retention/records schedule (periods are a legal determination)
- [ ] Matched matter/case naming convention reserved on both platforms
- [ ] Legal/eDiscovery stakeholders named; change control / rollback documented
- [ ] Pilot custodian scope created on both platforms
- [ ] Search/export readiness confirmed on Vault and Purview


---


# Global Requirements — Google Workspace & Gemini Solutions

These requirements apply to **every** solution in the **Google** category. They are the common
foundation each Google Workspace / Gemini solution assumes is already in place (or stands up as part
of its own Requirements section). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every Google solution).** The **Google Admin console**
> (admin.google.com), **Google Cloud / Cloud Identity**, and the **Microsoft / Entra** sides are
> authored at exact, current click-by-click detail from the vendors' public documentation. **Gemini
> Enterprise** capabilities that are in preview or rolling out are **cited or flagged "verify in your
> tenant"** — never invented. **Third-party migration tools** (e.g. for mail/Drive/Chat data movement)
> and **third-party enterprise apps** (ServiceNow, SAP, Databricks, etc.) are integrated at the
> pattern/architectural level; their internal console steps are deferred to the vendor's own docs.

## 1. Google Workspace / Cloud Identity tenant
- **Description:** A provisioned Google Workspace (or Cloud Identity) tenant with a **super-admin**
  account for configuration, and the appropriate Workspace edition/licensing for the capability in
  scope (e.g. Enterprise Plus for Vault/CAA/DLP, Gemini/AI add-on where required).
- **Why required:** All configuration, policy, and API work is performed against this tenant.
- **How to verify:** Sign in to **admin.google.com** as a super-admin; confirm edition and license
  counts under **Billing / Subscriptions**.
- **How to implement if missing:** Provision the tenant and licenses through Google or an authorized
  reseller before starting.

## 2. Source Microsoft 365 / Entra environment (for migration & coexistence)
- **Description:** For migration/coexistence/identity solutions, administrative access to the source
  **Microsoft 365** tenant and **Microsoft Entra ID** (Global Administrator or the least-privilege
  roles the solution names).
- **Why required:** Migration, directory sync, SSO federation, and coexistence read from and change
  the Microsoft side.
- **How to verify:** Confirm access to the M365 admin center and the Entra admin center with the
  required role.
- **How to implement if missing:** Obtain the role from the M365/Entra tenant owner.

## 3. DNS control for the routed domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF, DKIM, DMARC, TXT, CNAME) for the
  domains being migrated, coexisting, or verified.
- **Why required:** Domain verification, mail routing/coexistence, and authentication all depend on
  DNS changes.
- **How to verify:** Confirm access to the authoritative DNS zone for each domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow changes are high-impact).

## 4. Identity & provisioning source of truth
- **Description:** A defined **identity source of truth** (on-prem AD, Entra ID, or an HR/IGA system)
  and the sync mechanism (e.g. **Google Cloud Directory Sync (GCDS)** or SCIM-based provisioning).
- **Why required:** Consistent users/groups across ecosystems underpin SSO, licensing, and access.
- **How to verify:** Confirm which directory is authoritative and how objects flow into Google.
- **How to implement if missing:** Define the source of truth and provisioning model before configuring
  SSO or migrating.

## 5. A pilot scope (OU / group) and change control
- **Description:** A **pilot organizational unit or group** to validate on before fleet-wide rollout,
  and a **change-control** process for production changes (especially mail flow, DNS, identity, and DLP).
- **Why required:** Every solution follows an **Assess → Configure → Pilot → Validate → Expand** model;
  the pilot proves the design and change control protects production.
- **How to verify:** Confirm a named pilot OU/group exists and a change window/approval path is available.
- **How to implement if missing:** Create a pilot OU/group and agree the change-control process with the
  owners before making production changes.

## 6. Security, compliance & governance stakeholders
- **Description:** Engagement with the **security (CISO), legal/eDiscovery, and data-governance**
  stakeholders whose policies the configuration must satisfy (DLP, retention, Vault/Purview, and any
  regulatory regime such as ITAR/DFARS/Assured Controls where applicable).
- **Why required:** Data governance, eDiscovery, DLP, and regulated-workload settings must align to
  enterprise policy and legal requirements, not just technical defaults.
- **How to verify:** Confirm the applicable policies and named stakeholders/approvers.
- **How to implement if missing:** Identify the owners and obtain the policy/compliance requirements
  before configuring governance controls.

*The deployment model across every Google solution is the same: **Assess → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback for production changes.*


---


# 3. Implementation Guide — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

Follow these steps **in order**, working in **Google Vault** (`vault.google.com`) and the **Google
Admin console** (`admin.google.com`) on the Workspace side, and the **Microsoft Purview portal**
(`purview.microsoft.com`) on the Microsoft side.

> **Model:** Establish what's governed where **first**, then configure Vault retention and holds
> inside named matters, mirror each to a parallel Purview eDiscovery case/hold, define the discovery
> workflow across both, validate on a small pilot custodian scope, and only then expand. Vault and
> Purview **do not sync** — holds are issued in parallel.

> **Not legal advice.** Retention *periods*, hold *triggers*, and what "defensible" requires for a
> given matter are **legal/records-counsel determinations**. Configure to the counsel-approved
> schedule and hold list; do not invent periods or scope.

> **Verify in your tenant.** Vault's **Gemini-app** hold/retention support and the evolving Purview
> **eDiscovery** experience change over time; the paths below reflect current public documentation —
> confirm exact toggles for your editions and defer volatile specifics to the vendors' documentation.

Name every object exactly as shown, in the form `<Purpose> – <Scope> – <Stage>`, and use the **same
matter/case name on both platforms** — verbatim across scripts, holds, and reports.

## Step 1 — Inventory what's governed where (read-only)
1. Run `GWVAULT-Discovery.ps1` to enumerate the Google-side governance state: existing Vault
   **matters**, **holds**, and **retention rules** (default + custom), and the apps each covers
   (Gmail, Drive, Chat, Meet, Groups, Calendar, Voice, Sites, and the Gemini app where available).
2. Run `GWVAULT-Report.ps1` to produce the coverage/gap summary — which custodians and record classes
   are held/retained in Vault, and which require a matching Purview hold.
3. In the **Purview portal → eDiscovery → Cases**, note existing cases and **Hold policies**; in
   **Solutions → Data Lifecycle Management / Records management**, note retention policies/labels.
4. Record the custodians who have data on **both** sides (the migration overlap) as the parallel-hold
   worklist. **Do not release or narrow any existing hold.**

## Step 2 — Create the matter and case (matched names)
1. In **Vault → Matters → Create**, create the matter using the agreed name, e.g.
   `Litigation – Acme v. Example – Hold`. Reuse an existing matter if the legal matter already has one.
2. In the **Purview portal → eDiscovery → Cases → Create case**, create a case with the **same name**.
3. Record both identifiers against the one legal matter so the Vault matter and the Purview case are
   unmistakably the same matter (this is what makes the parallel hold auditable).

## Step 3 — Configure Google Vault retention (to the approved schedule)
1. In **Vault → Retention**, set/confirm **Default retention rules** and, where a record class needs a
   different period, **Custom retention rules** — scoped to the relevant service (Gmail, Drive, Chat,
   Meet, Groups, Voice, Sites, and the Gemini app where available) and OU, to the **counsel-approved**
   schedule.
2. Where the same record class also lives in M365, set the Vault period to the **longer** of the Vault
   and Purview schedules so neither side purges a record the other must keep.
3. Heed Vault's warning: modifying/deleting retention rules can allow services to **purge** data users
   expect to keep — change retention only under change control with counsel sign-off.
4. Remember the precedence: in Vault, a **hold** retains data **indefinitely** and **takes precedence**
   over default and custom retention rules. (Source: Google Vault Help.)

## Step 4 — Place the Google Vault legal hold (inside the matter)
1. In **Vault → Matters →** *(your matter)* **→ Holds → Create hold**. Name the hold with the matter
   convention (e.g. `Litigation – Acme v. Example – Hold`).
2. Choose the **service** to hold (e.g. Gmail, Drive, Chat, Groups, Voice, Sites, Meet, and the Gemini
   app where available) and the **accounts or an OU** to preserve — the pilot custodians in this pass.
3. Save the hold. Vault holds preserve data indefinitely regardless of retention rules or user
   deletion — confirm each in-scope service and custodian is covered.

## Step 5 — Mirror the hold in Microsoft Purview (parallel hold)
1. In the **Purview portal → eDiscovery → Cases →** *(the matched case)* **→ Hold policies →
   Create policy**. Give it the matched name and a description.
2. On **Manage data sources**, add the **same custodians** and the workloads they touch on the M365
   side: **Exchange mailboxes** (also preserves Teams 1:1/group chat, card, and meeting/call data
   stored in the mailbox) and **SharePoint sites / OneDrive accounts** (also preserves Teams channel
   files). For a **Team / Microsoft 365 group**, add the group's mailbox **and** SharePoint site — and
   add members' own mailboxes/OneDrive if their individual data is in scope (group membership is a
   point-in-time snapshot at hold creation).
3. Choose the hold scope: an **infinite** hold on all content, or a **query-based** hold (condition
   builder or KeyQL) with an optional date range, per counsel's instruction.
4. Select **Apply hold**. Allow up to **24 hours** for the hold to take effect. Confirm on the hold's
   **Details** tab that each location shows **on hold**.
5. Record the Purview hold policy against the same matter as the Vault hold — the custodian is now held
   on **both** ecosystems.

## Step 6 — Configure Microsoft Purview retention (align to the longer schedule)
1. In the **Purview portal → Data Lifecycle Management / Records management → Retention policies (and
   labels)**, set/confirm retention for the M365 workloads (Exchange, SharePoint, OneDrive, Teams) to
   the **counsel-approved** schedule.
2. Where a record class also lives in Workspace, set the Purview period to the **longer** of the two so
   it matches the Vault side. Remember most-restrictive-wins: eDiscovery holds, retention policies/
   labels, Litigation Hold, delay holds, and Single Item Recovery each independently preserve content.
3. Do **not** rely on retention to preserve for an active matter — the **hold** is the preservation
   instrument; retention governs the ongoing schedule.

## Step 7 — Define the cross-system discovery workflow
1. **Search each side by the matched matter/case:** in **Vault → Matters →** *(matter)* **→ Search**,
   scope by custodian/service/date; in **Purview → eDiscovery → Cases →** *(case)*, build the matching
   search (condition builder / KeyQL) across the M365 data sources.
2. **Export from each side:** run the Vault export and the Purview export for the same scope.
3. **Reconcile into one production:** assemble the two export sets into a single, de-duplicated
   production under counsel's direction, so content in the coexistence overlap is neither missed nor
   double-counted. Document the reconciliation so the collection is defensible.

## Step 8 — Validate the pilot
1. Run `GWVAULT-Validation.ps1` for the pilot scope: confirms, per custodian, that a Vault hold exists
   in the matter across the in-scope services, that Vault retention matches the approved schedule, and
   flags the Purview-side hold/retention to confirm in the portal.
2. Run `GWVAULT-Report.ps1` to confirm coverage: every pilot custodian is held on **both** sides and no
   in-scope record class is unretained.
3. Perform the **discovery probe** in the Testing Guide: run the matched search on both platforms for a
   known pilot item and confirm it is returned and exportable from the correct side(s). Confirm the
   Purview hold shows **on hold** (allow 24h) and Vault preservation is effective. Complete the pilot
   gate with legal/eDiscovery sign-off.

## Step 9 — Expand to all custodians
1. Only after the pilot passes: extend the matched matter/case holds to the remaining custodians in
   controlled waves, keeping Vault and Purview in parallel for each.
2. Re-run `GWVAULT-Report.ps1` after each wave to confirm both-sides coverage and no gaps.
3. Stand up recurring **coverage reviews** — re-run `GWVAULT-Discovery.ps1` on a schedule and reconcile
   Vault matters against Purview cases so a migrating custodian never falls out of hold on one side.

---
### Order of operations
`Inventory what's governed where → Matter + matched case → Vault retention → Vault hold → Purview
parallel hold → Purview retention (longer-of-two) → Cross-system discovery workflow → Validate
(pilot) → Expand`


---


# 5. Testing Guide — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

Run after the pilot matter/case and parallel holds are configured (Implementation Step 8), and re-run
after each expansion wave. The most important tests are the **coexistence probes** — proving a
custodian is held on **both** ecosystems and that discovery returns the right data from each. Each
check below is a **validation gate**.

> **Not legal advice.** These tests confirm the *technical* state (hold effective, retention applied,
> discovery returns). Whether the preserved scope satisfies the legal obligation is a legal/records-
> counsel determination.

## Test 1 — Vault hold effective on the matter
**Do:** Run `GWVAULT-Validation.ps1` for the pilot scope. In **Vault → Matters →** *(matter)* **→ Holds**, confirm the hold covers each in-scope service and custodian.
**Expected:** A Vault hold exists in the matter across the in-scope services (Gmail, Drive, Chat, etc.); held data is preserved indefinitely, taking precedence over retention rules.

## Test 2 — Purview parallel hold effective (same custodians)
**Do:** In **Purview → eDiscovery → Cases →** *(matched case)* **→ Hold policies →** *(policy)* **→ Details**, confirm each location shows **on hold** (allow up to 24h after apply).
**Expected:** The same custodians are held in Purview across their M365 workloads (Exchange, SharePoint/OneDrive, Teams-associated mailbox+site) — held on **both** ecosystems, under the matched matter name.

## Test 3 — Matter/case names match across platforms
**Do:** Compare the Vault matter name and the Purview case name for the pilot matter.
**Expected:** Identical names (`<Purpose> – <Scope> – <Stage>`), so the two holds are unmistakably the same legal matter.

## Test 4 — Vault retention applied to the approved schedule
**Do:** In **Vault → Retention**, confirm default and custom rules match the counsel-approved schedule for each in-scope service/OU. Run `GWVAULT-Validation.ps1`.
**Expected:** Vault retention matches the approved schedule; where a class also lives in M365, the Vault period is the **longer** of the two.

## Test 5 — Purview retention aligned (longer-of-two)
**Do:** In **Purview → Data Lifecycle / Records management → Retention policies (and labels)**, confirm the M365 retention matches the approved schedule and is aligned to the longer period for shared classes.
**Expected:** Purview retention matches the schedule and is aligned with Vault; most-restrictive-preservation-wins holds for any content also under a hold.

## Test 6 — Coexistence coverage: no custodian held on only one side
**Do:** Run `GWVAULT-Report.ps1`; review the coverage/gap output for the pilot custodians, cross-checking Vault matters against Purview cases.
**Expected:** Every pilot custodian who has data on both sides is held on **both**; no custodian is held on only one ecosystem.

## Test 7 — Discovery probe: matched search returns on both sides
**Do:** For a known pilot item, run the matched search in **Vault → Matters →** *(matter)* **→ Search** and in **Purview → eDiscovery → Cases →** *(case)*, and export from each.
**Expected:** The item is found and exportable from the correct side(s); the two export sets reconcile into a single production with no coexistence-gap item missed.

## Test 8 — Retention does not purge held content
**Do:** Confirm (with counsel) that a held record whose retention period has lapsed is still preserved by the hold on each platform.
**Expected:** The hold preserves the content regardless of retention (Vault hold precedence; Purview most-restrictive-wins) — nothing under a hold is purged.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–3 and 6–7 pass — the same custodians are held on both ecosystems under a matched matter name, and the matched search returns/exports from both |
| **Expand pass** | Tests 1–2, 4–6 pass for each newly held custodian wave before proceeding to the next |


---


# 6. Troubleshooting Guide — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

Use `GWVAULT-Discovery.ps1` / `GWVAULT-Validation.ps1` for the current Google-side state,
`GWVAULT-Report.ps1` for the both-sides coverage picture, and `GWVAULT-Remediation.ps1` (default
`-WhatIf`) to close a Vault-side coverage gap. Cross-check live state in **Vault → Matters** and the
**Purview portal → eDiscovery → Cases**.

> **Not legal advice.** This guide resolves *technical* faults (a hold not effective, a coverage gap,
> a search not returning). Whether the preserved scope is legally sufficient is a legal/records-counsel
> determination.

> **Verify in your tenant.** Vault's Gemini-app hold/retention support and the Purview eDiscovery
> experience evolve — confirm exact paths for your editions and defer volatile specifics to the
> vendors' documentation.

## A. A custodian is held on only one ecosystem (the coexistence gap)
| Symptom | Cause | Remediation |
|---|---|---|
| Custodian held in Vault but not Purview (or vice versa) | Parallel hold missed — holds do not sync | Run `GWVAULT-Report.ps1` to find the one-sided custodians; place the missing hold on the other platform (Vault matter hold, or Purview eDiscovery hold policy) under the matched matter name |
| Migrating custodian dropped out of hold mid-migration | Data moved from M365 to Workspace; only the old side was held | Re-run `GWVAULT-Discovery.ps1`; ensure the custodian is held on **both** sides for the migration overlap window |
| New group member not preserved | Purview group hold is a point-in-time snapshot at creation | Re-add the group as a data source (or add the member's mailbox/OneDrive) to refresh membership |

## B. Vault hold not preserving expected data
| Symptom | Cause | Remediation |
|---|---|---|
| A service's data not held | The hold doesn't include that service | Edit the hold in **Vault → Matters →** *(matter)* **→ Holds** to add the service (Gmail, Drive, Chat, Meet, Groups, Voice, Sites, Gemini app where available) |
| Data purged that should be kept | Retention rule modified/deleted without a hold covering it | Vault warns that changing retention can purge data; place a **hold** (takes precedence over retention) for anything under an active matter, and restore retention under change control |
| Gemini-app messages not held | Gemini-app hold/retention support is newer | Confirm the capability is available for your edition (**verify in your tenant**); add the Gemini app to the hold/retention where present |

## C. Purview hold not effective
- The hold can take **up to 24 hours** to take effect — check the hold policy's **Details** tab for
  each location's **hold status** before concluding it failed.
- **Licensing:** an eDiscovery hold requires an eligible license on **every held user**; frontline
  (F1/F3) users cannot be a hold target. Assign the required subscription/add-on, then reapply.
- **Teams/Groups scope:** holding a Team holds only the group mailbox + site — add members' mailboxes
  and OneDrive if their individual data is in scope.
- **Location changed:** if a SharePoint/OneDrive URL or a UPN changed, edit the hold's data sources and
  reapply so the scope stays accurate.

## D. Retention conflicts / purge risk
- **Purge out from under a hold:** align the two schedules to the **longer** period for shared classes,
  and rely on the **hold** (not retention) to preserve an active matter — Vault hold precedence and
  Purview most-restrictive-wins both keep held content.
- **Over-retention:** if content is kept longer than the approved schedule, confirm which preservation
  source is holding it (hold, retention policy/label, Litigation Hold, delay hold, Single Item
  Recovery on the Purview side) and release the correct one **only** with counsel sign-off.

## E. Discovery returns incomplete or mismatched results
| Symptom | Cause | Remediation |
|---|---|---|
| Item missing from a production | Searched only one platform | Run the matched search on **both** Vault and Purview and reconcile the two export sets |
| Duplicate items across productions | Coexistence overlap not de-duplicated | Reconcile Vault and Purview exports into a single de-duplicated production under counsel's direction |
| Encrypted/partially-indexed items missed by a query-based hold | Query conditions ineffective on such items | On Purview, limit query-based hold conditions to Date/Participants/Type; on both, prefer an infinite hold where completeness matters |

## F. Diagnostics quick reference
```powershell
# Read-only Google-side state and both-sides coverage
.\GWVAULT-Discovery.ps1
.\GWVAULT-Report.ps1

# Confirm the Vault hold/retention held for the pilot scope (Purview side flagged to confirm)
.\GWVAULT-Validation.ps1

# Preview closing a Vault-side coverage gap before applying
.\GWVAULT-Remediation.ps1 -WhatIf
```
Portal checks: **Vault → Matters** (holds) / **Vault → Retention**; **Purview portal → eDiscovery →
Cases → Hold policies** (Details tab for hold status) and **Data Lifecycle / Records management →
Retention policies**. *(Verify exact paths in your tenant.)*

## G. When to escalate
If holds are effective on **both** ecosystems, retention is aligned, and discovery still returns
incomplete or inconsistent results — capture the matter/case names, the custodian and workload, the
exact search, and the per-location hold status from each platform, and open a support case with
Google Workspace (Vault) and/or Microsoft (Purview) as appropriate. **Any question of legal
sufficiency (is the hold/scope defensible?) goes to legal/records counsel, not to support.** Volatile
Vault Gemini-app and Purview eDiscovery specifics are deferred to the vendors' documentation.


---


# 7. Best Practices — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

Field-proven recommendations for defensible eDiscovery across both ecosystems.

- **Assume nothing syncs — hold in parallel.** A hold in Vault does not reach Purview and vice versa.
  For every custodian, issue the hold on **both** platforms for every workload they touch. One
  playbook, two systems, the same named custodians on each side.
- **Name the matter once, identically on both.** Use the same `<Purpose> – <Scope> – <Stage>` name for
  the Vault matter and the Purview case so the two holds are unmistakably the same legal matter and
  coverage is auditable.
- **Map what's governed where before you hold anything.** Know which custodians and record classes live
  in Vault, in Purview, or (during migration) in both — the both-sides overlap is exactly where
  coexistence gaps hide.
- **Retain to the longer of the two.** Where a record class exists on both platforms, set each side's
  retention to the **longer** schedule so the stricter obligation is satisfied by default and nothing
  is purged out from under a hold.
- **Let the hold, not retention, preserve an active matter.** In Vault a hold takes precedence over
  retention and preserves indefinitely; in Purview most-restrictive-preservation-wins. Retention
  governs the ongoing schedule — the hold governs the matter.
- **Preserve the whole Microsoft footprint.** On the Purview side, holding a Team means holding the
  Team's group mailbox **and** SharePoint site; 1:1/group chat and OneDrive files live in individual
  mailboxes/accounts — add those custodians explicitly. Group membership on a hold is a point-in-time
  snapshot, so re-add groups when membership changes.
- **Mind the timing and licensing on Purview.** eDiscovery holds can take up to 24 hours to take
  effect, and require an eligible license on **every held user** (frontline F1/F3 cannot be a hold
  target). Confirm licensing before you place the hold, not after.
- **Discover across both and reconcile.** Run the matched search on each platform, export from both,
  and reconcile into a single de-duplicated production under counsel's direction — so no
  coexistence-overlap item is missed or double-counted, and the collection is defensible.
- **Always pilot the whole loop.** Prove parallel-hold-effective, retention-applied, and
  discovery-returns on a small custodian scope before extending to the full population — the pilot gate
  is "held and discoverable on both," not "a hold exists somewhere."
- **Keep legal/records counsel in the driver's seat.** Retention periods, hold triggers, and
  discovery scope are legal determinations. This is the technical mapping; counsel owns the legal call
  and signs off at each gate.
- **Watch the migration boundary.** As custodians move from M365 to Workspace, data can exist on both
  sides mid-migration and then shift — re-run coverage checks so a migrating custodian never drops out
  of hold on one ecosystem.
- **Verify evolving surfaces in your tenant.** Vault's Gemini-app hold/retention support and the
  Purview eDiscovery experience change; confirm each path for your editions and defer volatile
  specifics to the vendors' documentation rather than assuming.
- **Test discovery on a cadence, not just at crisis.** Rehearse the cross-system search/export/
  reconcile regularly so your first real hold is not your first rehearsal, and document the cadence for
  audit and repeatability.


---


# 8. Deliverables Summary — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The dual-ecosystem governance model — what's governed in Vault vs Purview, and how holds/retention/discovery are coordinated across both |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: inventory, matched matter/case, Vault retention + hold, Purview parallel hold + retention, cross-system discovery, pilot, expand |
| 5. Testing Guide | Validation gates with coexistence and discovery probes and pass/fail criteria |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for defensible eDiscovery across both ecosystems |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GWVAULT-Discovery.ps1` | Read-only: retention/hold discovery across the estate — Vault matters, holds, and retention rules (per service), with Purview-side coverage flagged to confirm |
| `GWVAULT-Validation.ps1` | Read-only: per-scope retention/hold validation — Vault hold present in the matter across in-scope services, retention matches the approved schedule; Purview side flagged to confirm |
| `GWVAULT-Report.ps1` | Read-only: coverage/gap report — which custodians are held/retained in Vault vs Purview, so no custodian is held on only one ecosystem |
| `GWVAULT-Remediation.ps1` | Safe remediation (default `-WhatIf`): applies a Vault hold to matched custodians in a matter to close a coverage gap; reports Purview-side gaps for parallel action |
| `GWVAULT-Set-ScopeTargeting.ps1` | Creates the pilot custodian scope group / matched matter scope (idempotent, default `-WhatIf`) for controlled rollout |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Scope note
This package delivers the **technical mapping** of governance across Google Vault and Microsoft
Purview. Retention *periods*, hold *triggers*, and what "defensible" requires for a specific matter
are **legal/records-counsel determinations**, engaged as a named stakeholder throughout. Vendor
specifics (Vault's Gemini-app hold/retention support, the evolving Purview eDiscovery experience) are
cited from current documentation or flagged **"verify in your tenant,"** never invented.

## Outcome
Defensible eDiscovery, legal hold, and retention across **both** Google Vault and Microsoft Purview —
what's governed where is mapped, Vault holds and retention are configured and mirrored to Purview in
parallel, retention is aligned to the longer schedule, discovery runs across both and reconciles into
one production, and the whole loop is proven on a pilot custodian scope before the full population
depends on it — with no compliance gap during coexistence.
