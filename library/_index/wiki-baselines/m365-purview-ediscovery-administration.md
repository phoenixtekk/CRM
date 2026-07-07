# Microsoft 365 Purview eDiscovery Administration — Content Search, Cases, Holds & Export

> **Version 1.0.0** · Category: Security · Solution code: MSEDISC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft 365 Purview eDiscovery Administration

## Outcome
Your organization runs **Microsoft 365 eDiscovery end to end — search, hold, review, export — as a
defensible, repeatable workflow** across Exchange, SharePoint, OneDrive, and Teams. Instead of
ad-hoc content searches that do not hold up, every legal, regulatory, or investigation request is
handled inside a named **case**, with a scoped **search**, an effective **hold**, and — where the
matter warrants it — a Premium **review set**, **analytics/de-duplication**, and a **defensible
export** with a load file and audit trail ready for legal.

## Approach
The solution operates the three eDiscovery tiers deliberately: **Content Search** for scoped
collection, **eDiscovery (Standard)** for cases and preservation holds, and **eDiscovery (Premium)**
for custodians, review sets, analytics, and structured export. It follows a pilot-first model —
**Assess → Design → Configure → Pilot → Validate → Expand** — proving the full case → search → hold
→ review → export flow on a non-sensitive **pilot matter** before any live matter runs. Every
artifact is named to the matter (`eDiscovery Case – Matter-A – Pilot`, `Hold Policy – Matter-A –
Pilot`, `Export – Matter-A – Pilot`) and the same names flow through the tests and the five included
PowerShell tools. It is deliberately scoped to the eDiscovery *workflow* — distinct from Purview
DLP, sensitivity labels, and retention.

## Why it is low-risk
- **Legal owns the determination; IT executes and evidences it.** Scope, custodians, holds, and
  production are legal/records decisions — the solution supplies the technical method and the audit
  evidence, never the legal call.
- **Least-privilege and scoped.** eDiscovery power is granted through the **eDiscovery Manager /
  Administrator** role groups (not Global Admin), with optional **compliance boundaries** where
  policy requires separation.
- **Safe-by-default automation.** The five PowerShell tools are **read-only or dry-run (`-WhatIf`)**
  by default and require an explicit `-Apply` to create a search, place a hold, or set a filter —
  with modern authentication and **no credentials or secrets in code**.
- **Pilot gates and rollback.** High-impact actions (broad holds, exports) are proven on the pilot
  matter first, behind explicit pass/fail gates (search scoped, hold effective, export complete and
  defensible), with a documented rollback.

The result is eDiscovery that is **complete, defensible, and repeatable** — at a fraction of the cost
of outside eDiscovery consulting — while keeping legal in control of every determination.


---


# 1. Solution Overview — Microsoft 365 Purview eDiscovery Administration

## What Microsoft Purview eDiscovery is
Microsoft Purview eDiscovery is Microsoft 365's built-in capability for **finding, preserving,
reviewing, and exporting** content in response to legal, regulatory, and internal-investigation
requests. It reaches across the workloads where enterprise content lives — **Exchange Online**
mailboxes, **SharePoint Online** and **OneDrive for Business** sites, and **Microsoft Teams** chats,
channel messages, and files (Teams messages are stored in the participants' mailboxes; Teams files
live in SharePoint/OneDrive). It exists in tiers of increasing capability:

1. **Content Search** — an ad-hoc search-and-export tool. You define a keyword/condition query,
   pick locations, estimate the hits, preview, and export. No case container, no custodian tracking,
   no analytics. Good for quick, one-off collection; **not** a defensible matter workflow on its own.
2. **eDiscovery (Standard)** — adds a **case** container that groups searches and, critically, adds
   **holds** (a case hold preserves in-place content so it cannot be permanently deleted while the
   matter is open). Standard is Content Search + cases + holds + export.
3. **eDiscovery (Premium)** — adds a defensible end-to-end workflow: **custodians** (people/data
   sources formally associated with the matter, each with a custodian hold and communications),
   **review sets** (collected content copied into a static, reviewable set), **analytics** (near-
   duplicate detection, email threading, themes) and **de-duplication**, tagging/redaction, and
   structured **export** with a load file. Premium is the tier legal teams rely on for large,
   defensible matters.

> **This solution is scoped to the eDiscovery *workflow* — search, hold, review, export.** It is
> deliberately **distinct** from the other Purview capabilities: **DLP** (data loss prevention),
> **sensitivity labels** (classification/encryption), and **retention/records** (keep-and-delete
> schedules). Those protect and govern data proactively; eDiscovery *finds and produces* it
> reactively for a matter. A separate Purview solution covers DLP/labels/retention.

## How it works (the eDiscovery model)
1. **A request arrives** (litigation, regulator, HR/investigation). Legal defines the scope —
   custodians, date range, subject matter, keywords. **The legal/records function owns the
   determination of what is in scope and what must be held**; you provide the technical method and
   the evidence that it was done correctly and completely.
2. **You design the query** — keywords and conditions expressed as **KQL** (Keyword Query Language)
   plus condition filters (date range, sender/recipient, file type, sensitive-info type). A tightly
   scoped query is defensible; an over-broad one is expensive and noisy.
3. **You create a case** and run **Content Searches** inside it against the chosen locations,
   review the **statistics** (item count, size, locations with hits), and refine the query until the
   scope is right.
4. **You place holds** — a case hold (Standard) or custodian hold (Premium) preserves the in-scope
   content so routine deletion or retention expiry cannot destroy it while the matter is open.
5. **(Premium) You collect into a review set**, run **analytics** (email threading, near-duplicate
   and de-duplication, themes) to cut review volume, tag/redact, and then **export** the reviewed
   content with a load file for outside counsel or the requesting authority.
6. **Every action is auditable** — case activity, search runs, hold changes, and exports are logged
   in the Purview audit log, which is the evidence that the collection was complete and defensible.

## The reference design
- **One case per matter**, named `eDiscovery Case – <Matter> – <Stage>` (e.g.
  `eDiscovery Case – Matter-A – Pilot`). All searches, holds, custodians, review sets, and exports
  for that matter live inside it and reuse the matter name.
- **Named, versioned searches** — `Content Search – <Matter>-<Purpose> – <Stage>`
  (e.g. `Content Search – Matter-A-Keywords – Pilot`). You iterate the query; the name stays stable.
- **Holds named to the matter** — `Hold Policy – <Matter> – <Stage>` and
  `Hold Rule – <Matter> – <Stage>`; custodians named `Custodian – <upn> – <Matter>`.
- **Review set and export named to the matter** — `Review Set – <Matter> – <Stage>` and
  `Export – <Matter> – <Stage>`.
- **Least-privilege roles** — operators are members of the **eDiscovery Manager** role group (they
  see only their own cases); a small number of **eDiscovery Administrator** members can see all
  cases and manage holds. Global Administrator is *not* used to run matters.
- **Compliance boundaries (optional)** — where the organization must restrict which custodians a
  given eDiscovery team can search (for example, by region or business unit), a **compliance
  security filter** scopes searches. The *policy* of who may search whom is a legal/HR decision.

## Benefits
- **Defensible and repeatable** — a case, a named search, a hold, an audit trail: the same
  documented pattern every matter, so collection is complete and provable rather than ad-hoc.
- **Complete across M365** — one workflow reaches Exchange, SharePoint, OneDrive, and Teams,
  including Teams messages that many ad-hoc tools miss.
- **Less review, lower cost** — Premium analytics (threading, near-dup, de-dup) cut the volume that
  reaches expensive human/outside-counsel review.
- **Least-privilege and scoped** — role groups and optional compliance boundaries mean eDiscovery
  power is granted narrowly, not via Global Admin.

## Limitations (be honest with buyers)
- **Tier gating.** Content Search and eDiscovery (Standard) are broadly available; **custodians,
  review sets, analytics/de-duplication, and structured export are eDiscovery (Premium)** and
  require the higher licensing (Microsoft 365 E5 / E5 eDiscovery and Audit add-on). The Requirements
  Guide names the licensing — **verify in your tenant**.
- **The eDiscovery experience was modernized.** Microsoft unified the classic *Standard* and
  *Premium* experiences into a **new eDiscovery** UI in the Purview portal (`purview.microsoft.com`);
  menu paths and some feature names differ from older screenshots. Where a path is version-dependent
  this guide flags **"verify in your tenant."**
- **Legal determinations are not ours to make.** What is in scope, who is a custodian, what must be
  held, and what is produced are **legal/records decisions** — this solution supplies the technical
  method and evidence, never the determination.
- **Holds and preservation have edge cases.** A hold preserves content but does not stop a user from
  editing/deleting their working copy (the preserved copy is retained in the recoverable/preservation
  location). Very large collections, unindexed/partially-indexed items, and encrypted content need
  explicit handling — covered in Troubleshooting.
- **Government clouds differ.** GCC High / DoD use different portal hosts (for example
  `*.office365.us`) and some features lag Commercial — **verify in your tenant**.

## The standard deployment model
> **Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first, with explicit pass/fail
> gates and a documented rollback. For eDiscovery this reads: **assess licensing/roles/in-scope
> workloads → design the case, query, and hold naming → configure roles and (optionally) compliance
> boundaries → run a *pilot matter* end-to-end (case → search → hold → review → export) → validate
> the gates (search scoped, hold effective, export complete and defensible) → expand the pattern to
> live matters.** Placing a broad hold or exporting is **high-impact** and is always piloted on a
> narrow, non-sensitive test matter first, with the case-hold rollback documented before you begin.


---


# 2. Requirements Guide — Microsoft 365 Purview eDiscovery Administration

Verify **every** requirement before running a matter. Each entry: **Description · Why · Verify ·
Implement-if-missing.** This solution has no shared category-requirements file — all prerequisites
are below.

## 2.1 Microsoft 365 + eDiscovery licensing
**Description:** Licensing that covers the tier you will use. **Content Search** and **eDiscovery
(Standard)** cases and holds are available in most enterprise plans (for example Microsoft 365 E3);
**eDiscovery (Premium)** — custodians, review sets, analytics/de-duplication, and structured export —
requires **Microsoft 365 E5** (or the **E5 eDiscovery and Audit** add-on), and custodians placed on
Premium hold each need an eligible license.
**Why:** Premium features simply do not appear without the plan; running a matter that needs review
sets/analytics on E3 licensing will fail at collection.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; and open
`https://purview.microsoft.com` → **eDiscovery** — if you cannot create custodians/review sets, you
are on Standard only. Run `MSEDISC-Discovery.ps1` (reports which case types/holds exist). **Plan
names and gating change — verify in your tenant.**
**Implement:** Assign E5 / E5 eDiscovery and Audit to the eDiscovery operators and to custodians who
will be placed on a Premium custodian hold.

## 2.2 eDiscovery roles (least privilege)
**Description:** Operators hold the **eDiscovery Manager** role group (run searches, manage their own
cases); a small number hold **eDiscovery Administrator** (see all cases, manage holds, act on any
matter). Within eDiscovery Manager, distinguish **Manager** members (own cases only) from
**Administrator** members.
**Why:** eDiscovery is powerful — it can read anyone's mail and files. Grant it narrowly through the
role groups, **not** through Global Administrator.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles & scopes → Permissions →
Microsoft Purview solutions → eDiscovery Manager**; or PowerShell `Get-RoleGroupMember "eDiscovery
Manager"` / `Get-RoleGroupMember "eDiscovery Administrator"`. Run `MSEDISC-Discovery.ps1`.
**Implement:** Add operators to **eDiscovery Manager**; add the lead(s) as **eDiscovery
Administrator**. Remove any standing Global Admin use for matters.

## 2.3 Audit logging enabled
**Description:** The Microsoft Purview **unified audit log** is turned on so case, search, hold, and
export activity is recorded.
**Why:** The audit trail is the *evidence of defensibility* — it proves the hold was placed, the
search run, and the export completed. Legal will ask for it.
**Verify:** Purview → **Audit** — a search returns results. Run `MSEDISC-Report.ps1` (surfaces
eDiscovery-related audit activity).
**Implement:** Turn on auditing in the **Audit** solution; allow time for events to populate.

## 2.4 In-scope workloads identified
**Description:** A written list of which workloads the matter must cover — Exchange mailboxes,
SharePoint sites, OneDrive accounts, and Teams (chats/channels/files) — and any that are explicitly
out of scope.
**Why:** Search locations and hold locations are chosen from these; missing a workload (e.g.
forgetting that Teams chat lives in mailboxes) makes the collection incomplete.
**Verify:** A scope note exists naming custodians and their mailboxes/sites/OneDrive/Teams.
**Implement:** Work with legal to enumerate custodians and map each to their Exchange mailbox,
OneDrive URL, SharePoint sites, and Teams membership.

## 2.5 Legal/records stakeholder and scope determination
**Description:** A named legal, compliance, or records owner who **decides** the matter scope —
custodians, date range, keywords, what must be held, and what is produced.
**Why:** Scope, hold, and production are **legal determinations**, not IT defaults. IT executes and
evidences them; IT does not decide them.
**Verify:** A matter intake record exists with a named legal owner, scope, and a hold instruction.
**Implement:** Establish a matter-intake step: legal signs off scope and hold before configuration
begins.

## 2.6 PowerShell modules and connectivity
**Description:** The **ExchangeOnlineManagement** module (provides Security & Compliance PowerShell,
`Connect-IPPSSession`) for Content Search/Standard automation, and — for Premium automation — the
**Microsoft.Graph.Security** module (Microsoft Graph eDiscovery API).
**Why:** The scripts in this solution use Security & Compliance PowerShell for Content Search, cases,
and holds; Premium custodian/review-set/export automation is via Microsoft Graph. Exact Graph cmdlet
parameters are version-dependent — **verify in your tenant**.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Security`;
`Connect-IPPSSession` succeeds with modern auth (MFA).
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and
`Install-Module Microsoft.Graph.Security -Scope CurrentUser`. Use modern auth only — **no stored
credentials or app secrets in scripts.**

## 2.7 Pilot matter (non-sensitive)
**Description:** A safe, non-sensitive **pilot matter** and a willing pilot custodian (for example an
IT test account) used to walk the full case → search → hold → review → export flow before touching a
real matter.
**Why:** Holds and exports are high-impact; the pattern is proven on `eDiscovery Case – Matter-A –
Pilot` first, then applied to live matters.
**Verify:** A pilot custodian account and a scratch matter name exist.
**Implement:** Nominate a pilot custodian (seed some test mail/files/Teams messages) and reserve the
name `Matter-A`.

## 2.8 Compliance boundary decision (if required)
**Description:** A decision on whether eDiscovery must be **scoped** so a given eDiscovery team can
only search a subset of the org (for example by region or agency), enforced with a **compliance
security filter**.
**Why:** In multi-region/multi-agency tenants, allowing every eDiscovery Manager to search everyone
may violate policy; the boundary must be defined *before* matters run.
**Verify:** A written boundary policy exists (which team may search which population). PowerShell
`Get-ComplianceSecurityFilter` shows configured filters.
**Implement:** With legal/HR, define the boundary; create filters with `MSEDISC-Scope.ps1`
(`New-ComplianceSecurityFilter`). The *policy* is a legal/HR determination; the script only
implements it.

## 2.9 Change control + rollback for holds and exports
**Description:** A documented change-control and rollback process for placing/removing a hold and for
running an export.
**Why:** A broad hold affects preservation across many mailboxes/sites and an export moves potentially
sensitive content; both need an approver, a pilot gate, and a defined rollback.
**Verify:** A change ticket exists with approver, pilot scope, and rollback (remove the case-hold
rule/policy; delete the review set/export). 
**Implement:** Record the change, name the pilot matter, define the rollback, and get legal approval
before placing a live hold or running a live export.

---
## Checklist
- [ ] eDiscovery licensing confirmed (Standard vs **Premium/E5**) — `MSEDISC-Discovery.ps1` — *verify in tenant*
- [ ] Roles assigned: **eDiscovery Manager** (+ **eDiscovery Administrator** lead), no Global Admin for matters
- [ ] Unified audit log enabled — `MSEDISC-Report.ps1`
- [ ] In-scope workloads mapped per custodian (Exchange / SharePoint / OneDrive / Teams)
- [ ] Named legal/records owner + scope & hold determination on record
- [ ] Modules installed (`ExchangeOnlineManagement`, `Microsoft.Graph.Security`); modern auth works
- [ ] Pilot matter `Matter-A` + pilot custodian ready
- [ ] Compliance-boundary decision made (filters via `MSEDISC-Scope.ps1` if required)
- [ ] Change control + rollback for holds and exports


---


# 3. Implementation Guide — Microsoft 365 Purview eDiscovery Administration

Follow the deployment model **Assess → Design → Configure → Pilot → Validate → Expand**. Every
artifact is **named** with the convention `<Purpose> – <Scope> – <Stage>` and the **same name is
reused** in testing, troubleshooting, and the scripts. Run the whole flow on the **pilot matter
`Matter-A`** first; only after the validation gates pass do you apply the pattern to a live matter.

Portal: `https://purview.microsoft.com` → **eDiscovery** (Government clouds use a different host,
e.g. `*.office365.us` — **verify in your tenant**). PowerShell: `Connect-IPPSSession` (Security &
Compliance) for Content Search/Standard; **Microsoft.Graph.Security** for Premium.

> **Legal owns the determination** of scope, custodians, holds, and production. The steps below are
> the technical method; do not place a live hold or export without the legal sign-off from
> Requirement 2.5.

---

## Stage A — Assess (read-only, no changes)
1. **Confirm tier, roles, and audit.** Run **`MSEDISC-Discovery.ps1`**. It reports eDiscovery role-
   group membership, existing cases/searches/holds, and whether audit is on. Confirm you have
   **eDiscovery Manager/Administrator** (Requirement 2.2) and know whether the tenant has **Premium**
   (Requirement 2.1). Resolve any gap before continuing.
2. **Record the in-scope workloads** per custodian from Requirement 2.4 (Exchange mailbox, OneDrive
   URL, SharePoint sites, Teams membership). Remember Teams **messages** are collected via the
   custodian's **mailbox** and Teams **files** via **SharePoint/OneDrive**.

**Gate A (pass/fail):** roles present, audit on, tier known, in-scope workloads mapped. Fail → stop
and fix (Requirements 2.1–2.4).

---

## Stage B — Design (on paper)
3. **Name the matter and artifacts.** For the pilot use:
   - Case: `eDiscovery Case – Matter-A – Pilot`
   - Search: `Content Search – Matter-A-Keywords – Pilot`
   - Hold policy / rule: `Hold Policy – Matter-A – Pilot` / `Hold Rule – Matter-A – Pilot`
   - (Premium) Custodian: `Custodian – <pilotUPN> – Matter-A`; Review set: `Review Set – Matter-A –
     Pilot`; Export: `Export – Matter-A – Pilot`.
4. **Design the query (KQL + conditions).** With legal's keywords, draft a **KQL** query for
   `ContentMatchQuery`, for example:
   `(subject:"Project Falcon" OR body:"Project Falcon") AND (received>=2024-01-01 AND received<=2024-12-31)`.
   Prefer explicit **conditions** (date range, participants, `kind:`/`filetype:`, sensitive-info
   type) over broad free-text. Keep the first pass **narrow** — you widen only if it under-collects.

**Gate B:** named artifacts and a written, scoped KQL query approved by legal. Fail → refine.

---

## Stage C — Configure scope & boundaries (once per tenant)
5. **(Optional) Compliance boundary.** If Requirement 2.8 requires scoping which population an
   eDiscovery team may search, create a **compliance security filter** with **`MSEDISC-Scope.ps1`**
   (dry-run by default; `-Apply` to commit). It wraps `New-ComplianceSecurityFilter` — the *policy*
   (who may search whom) is legal/HR's determination; the script only implements it. Skip if not
   required.

**Gate C:** boundary filters exist and validate (or are explicitly out of scope). Fail → fix filter
definition.

---

## Stage D — Configure & run the pilot matter

### Content Search / Standard (Security & Compliance PowerShell or portal)
6. **Create the case.** Portal: **eDiscovery → Cases → Create a case** named
   `eDiscovery Case – Matter-A – Pilot`. PowerShell (Standard):
   `New-ComplianceCase -Name "eDiscovery Case – Matter-A – Pilot" -CaseType eDiscovery`.
7. **Build the search.** Use **`MSEDISC-Search.ps1`** — **dry-run by default**; it echoes the
   `New-ComplianceSearch`/`Start-ComplianceSearch` it *would* run and only creates/starts when you
   pass `-Apply`. It creates `Content Search – Matter-A-Keywords – Pilot` scoped to the in-scope
   locations (`-ExchangeLocation`, `-SharePointLocation`, or `All` for an estimate) with your
   `-ContentMatchQuery` KQL, then starts it. Portal equivalent: inside the case, **Searches → New
   search**, add locations + query.
8. **Review the statistics and refine.** Run **`MSEDISC-Report.ps1`** (or portal **search →
   Statistics**) to read item count, size, and locations with hits for `Content Search –
   Matter-A-Keywords – Pilot`. **Preview** a sample (`New-ComplianceSearchAction -Preview`). If the
   query over- or under-collects, refine the KQL (Step 4) and re-run **`MSEDISC-Search.ps1 -Apply`**.
   Iterate until scope is right — the search **name stays the same**.
9. **Place the hold (Standard).** Once legal confirms preservation, create a **case hold** with
   **`MSEDISC-CaseHold.ps1`** (dry-run by default; `-Apply` to commit). It creates
   `Hold Policy – Matter-A – Pilot` (`New-CaseHoldPolicy` over the custodian mailboxes/sites) and
   `Hold Rule – Matter-A – Pilot` (`New-CaseHoldRule`, optionally query-based). Portal equivalent:
   case → **Holds → Create**.

### eDiscovery (Premium) — custodians, review set, analytics, export (E5)
> Premium steps use the **new eDiscovery** UI and the **Microsoft.Graph.Security** cmdlets; exact
> parameters are version-dependent — **verify in your tenant**. `MSEDISC-Report.ps1` reports Premium
> case/hold/export status where the Graph module is available.
10. **Add custodians.** In the Premium case, **Data sources → Custodians → Add** each custodian
    (`Custodian – <pilotUPN> – Matter-A`), selecting their mailbox, OneDrive, SharePoint, and Teams.
    Placing a **custodian hold** here preserves their content. (Graph:
    `New-MgSecurityCaseEdiscoveryCaseCustodian` — verify parameters.)
11. **Collect into a review set.** Create a **collection/search**, estimate, then **commit/add to a
    review set** named `Review Set – Matter-A – Pilot`. This copies matching content into a static,
    reviewable set.
12. **Run analytics / de-duplication.** On the review set, run **Analytics** — email **threading**,
    **near-duplicate** detection, **themes** — and enable **de-duplication** so only unique items
    reach review. This is where review volume (and cost) drops.
13. **Review, tag, redact.** Reviewers apply tags (responsive/privileged) and redactions in the
    review set. **Legal makes responsiveness/privilege calls; you operate the tooling.**
14. **Export defensibly.** From the review set, **Export** `Export – Matter-A – Pilot` with the
    chosen options (native/redacted, metadata **load file**, item report). Download and record the
    export report as evidence. (Standard/Content Search export equivalent:
    `New-ComplianceSearchAction -SearchName "Content Search – Matter-A-Keywords – Pilot" -Export`.)

**Gate D (the core pilot gate):** case created; search scoped and previewed; hold **effective**
(preserving); (Premium) review set collected, analytics run, export **complete with a load file and
report**. Fail any → do not proceed to a live matter.

---

## Stage E — Validate
15. Run the **testing procedures in `05-testing.md`** against the pilot matter, and
    **`MSEDISC-Report.ps1`** for the evidence pack (search stats, hold status, export report). All
    gates must pass.

**Gate E:** every test in Section 5 passes; the audit log shows the case, search, hold, and export
activity. Fail → remediate before expanding.

---

## Stage F — Expand
16. **Apply the pattern to live matters.** For each real matter, repeat Stages B–E with the matter's
    real name (e.g. `eDiscovery Case – Matter-B – Prod`), legal-approved scope, and legal sign-off
    for holds/exports. Never skip the pilot gate for a new *type* of matter (new workload, cross-
    region custodians, very large collection).

---

## Rollback (documented before you place a live hold or export)
- **Remove a hold:** delete `Hold Rule – Matter-A – Pilot` then `Hold Policy – Matter-A – Pilot`
  (portal: case → Holds → remove; PowerShell `Remove-CaseHoldRule` / `Remove-CaseHoldPolicy`).
  Preservation stops going forward; content already preserved is released per its retention.
  **Do not remove a hold on a live matter without legal approval** — it may destroy preservation.
- **Undo a search/collection:** searches are non-destructive; delete the search
  (`Remove-ComplianceSearch`) or the review set/collection to discard.
- **Undo an export:** delete the export job and the downloaded package; the source content is
  unchanged.
- **Compliance filter:** `Remove-ComplianceSecurityFilter` to revert a boundary change.


---


# 5. Testing & Validation — Microsoft 365 Purview eDiscovery Administration

Run these against the **pilot matter** (`eDiscovery Case – Matter-A – Pilot` and its named
artifacts) before applying the pattern to any live matter. Each test states the **procedure** and the
**expected pass/fail**. `MSEDISC-Report.ps1` produces the evidence pack for most of them.

## Test 1 — Roles are least-privilege
**Procedure:** Run `MSEDISC-Discovery.ps1`; or Purview → **Settings → Roles & scopes** → check
**eDiscovery Manager** / **eDiscovery Administrator** membership.
**Pass:** Operators are in eDiscovery Manager; the lead is in eDiscovery Administrator; no standing
Global Admin is used to run matters.
**Fail:** Matters are run as Global Admin, or operators lack the role group (see Requirement 2.2).

## Test 2 — Case exists and is scoped
**Procedure:** Portal → **eDiscovery → Cases**; or `Get-ComplianceCase -Identity "eDiscovery Case –
Matter-A – Pilot"`.
**Pass:** The case exists with the exact name and the expected members/custodians.
**Fail:** No case, wrong name, or unexpected members.

## Test 3 — Search is scoped and returns expected hits
**Procedure:** Run `MSEDISC-Report.ps1` (or portal search **Statistics**) for `Content Search –
Matter-A-Keywords – Pilot`; **preview** a sample.
**Pass:** Item count/size are in the expected order of magnitude for the seeded pilot content;
preview shows on-topic items across the in-scope workloads (including Teams messages via the mailbox).
**Fail:** Zero hits when content was seeded, an implausibly large count (over-broad query), or a
workload with no hits that should have some (query/location scope wrong — refine per Implementation
Step 8).

## Test 4 — Query correctness (over/under-collection)
**Procedure:** Compare preview results against the known seeded pilot items.
**Pass:** In-scope items are found; obvious out-of-scope items (wrong date range, wrong subject) are
**not** returned.
**Fail:** Known in-scope items are missing (under-collection) or clearly out-of-scope items appear
(over-collection). Tune KQL/conditions and re-run `MSEDISC-Search.ps1 -Apply`.

## Test 5 — Hold is effective (preservation)
**Procedure:** Run `MSEDISC-Report.ps1` to confirm `Hold Policy – Matter-A – Pilot` /
`Hold Rule – Matter-A – Pilot` are **enabled**; then, as the pilot custodian, delete a seeded held
item and confirm it is still recoverable/preserved (recoverable items / preservation hold).
**Pass:** Hold policy and rule are enabled over the correct locations; the deleted item remains
preserved and discoverable.
**Fail:** Hold shows disabled/error, or a held item is permanently gone (see Troubleshooting).

## Test 6 — (Premium) Review set collected and analytics ran
**Procedure:** In the Premium case, open `Review Set – Matter-A – Pilot`; confirm items were added and
that **Analytics** (threading / near-dup) and **de-duplication** completed.
**Pass:** The review set contains the collected items; analytics/de-dup show completed and reduced
the duplicate/near-dup count.
**Fail:** Empty review set, or analytics failed/incomplete (check licensing — Requirement 2.1 — and
job status).

## Test 7 — Export is complete and defensible
**Procedure:** Run/inspect `Export – Matter-A – Pilot` (Premium) or the Content Search
`-Export` action; download the package and open the **export/results report** and the metadata
**load file**.
**Pass:** Export status **Completed**; item counts match the review-set/search estimate; the load
file and export report are present and readable.
**Fail:** Export errored or partial, item counts do not reconcile, or no load file/report (not
defensible — investigate before producing anything to legal).

## Test 8 — Audit trail present
**Procedure:** Run `MSEDISC-Report.ps1` (audit section) or Purview → **Audit** and search for the
case/search/hold/export activity for `Matter-A`.
**Pass:** Audit records exist for case creation, search runs, hold changes, and export.
**Fail:** No audit activity (audit disabled — Requirement 2.3 — or insufficient time to populate).

## Test 9 — (If configured) Compliance boundary enforced
**Procedure:** As a scoped eDiscovery Manager, attempt to search a population **outside** the
boundary; check `Get-ComplianceSecurityFilter` via `MSEDISC-Scope.ps1`.
**Pass:** The filter exists and the out-of-boundary search returns no out-of-scope custodians.
**Fail:** A scoped operator can search outside their boundary (filter missing/misconfigured).

---
## Validation gate summary (all must pass before a live matter)
- [ ] Roles least-privilege (Test 1)
- [ ] Case scoped correctly (Test 2)
- [ ] **Search scoped**, plausible hits, right workloads (Tests 3–4)
- [ ] **Hold effective** / preservation proven (Test 5)
- [ ] (Premium) Review set + analytics/de-dup complete (Test 6)
- [ ] **Export complete + defensible** (load file + report) (Test 7)
- [ ] Audit trail present (Test 8)
- [ ] Compliance boundary enforced, if configured (Test 9)


---


# 6. Troubleshooting — Microsoft 365 Purview eDiscovery Administration

Common failure modes and how to resolve them. Object names use the pilot convention (`eDiscovery Case
– Matter-A – Pilot`, `Content Search – Matter-A-Keywords – Pilot`, `Hold Policy – Matter-A – Pilot`);
substitute your matter. Start most diagnostics with `MSEDISC-Discovery.ps1` and `MSEDISC-Report.ps1`.

## Access & roles

### "You don't have permission" / can't see a case
**Cause:** The operator is not in an eDiscovery role group, or is an **eDiscovery Manager** (who sees
only their **own** cases) trying to open someone else's case.
**Resolve:** Confirm membership with `MSEDISC-Discovery.ps1` or Purview → **Settings → Roles &
scopes**. Add the operator to **eDiscovery Manager**; for cross-case visibility add to **eDiscovery
Administrator** (Requirement 2.2). Do **not** work around this with Global Admin.

### `Connect-IPPSSession` fails or hangs
**Cause:** Module missing/old, or modern-auth/MFA prompt blocked.
**Resolve:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; run interactively so the
MFA prompt appears. In Government clouds pass the correct environment/host — **verify in your
tenant**. Never store credentials to bypass the prompt.

## Licensing / tier

### Custodians, review sets, or analytics are missing from the portal
**Cause:** The tenant/operator has **eDiscovery (Standard)** only — custodians, review sets,
analytics/de-dup, and structured export are **Premium (E5 / E5 eDiscovery and Audit)** features.
**Resolve:** Confirm licensing (Requirement 2.1) in the admin center and with `MSEDISC-Discovery.ps1`;
assign E5/add-on to operators and to custodians who will be placed on a Premium custodian hold.
Menu names differ since the eDiscovery experience was modernized — **verify in your tenant**.

## Search & query

### Search returns zero hits (but content exists)
**Cause:** Query too narrow, wrong locations, or content not yet indexed.
**Resolve:** Re-check the KQL and date range (Implementation Step 4); confirm the in-scope
`-ExchangeLocation`/`-SharePointLocation`; preview with `New-ComplianceSearchAction -Preview`. Widen
one condition at a time and re-run `MSEDISC-Search.ps1 -Apply` — the search **name stays the same**.
Newly created/seeded content can take time to index.

### Search returns far too much
**Cause:** Over-broad free-text query or `All` locations left on after the estimate.
**Resolve:** Add explicit conditions (date range, participants, `kind:`/`filetype:`), scope locations
to the actual custodians, and re-run. Read the statistics with `MSEDISC-Report.ps1` to confirm the
count drops to a plausible range (Testing Test 4).

### Teams messages or Teams files are missing from results
**Cause:** Teams **1:1/channel messages** are stored in the participants' **mailboxes** (Exchange);
Teams **files** live in **SharePoint/OneDrive**. Searching only SharePoint (or only Exchange) misses
half of Teams.
**Resolve:** Include both the custodian **mailbox** (for messages) and the relevant **SharePoint/
OneDrive** locations (for files). Confirm both workloads show hits in `MSEDISC-Report.ps1`.

### Some items are flagged unindexed / partially indexed
**Cause:** Items Microsoft could not fully index (unsupported/corrupt/encrypted content).
**Resolve:** In Premium collections, deliberately **include** unindexed items and record the count;
do not silently drop them. Investigate high unindexed counts (a bad file type, encryption) before
producing.

## Holds & preservation

### Hold shows an error or "not applied"
**Cause:** Invalid location (mailbox/site not resolvable), a custodian without an eligible license, or
propagation still in progress.
**Resolve:** Verify each location is valid and the custodian is licensed; check
`Get-CaseHoldPolicy`/`Get-CaseHoldRule` via `MSEDISC-Report.ps1`. Hold application can take time to
propagate — re-check after propagation.

### A held item was permanently deleted
**Cause:** The hold was placed **after** the deletion, or the hold scope missed that location.
**Resolve:** Preservation only protects content **from the moment the hold is effective** — place the
hold **before** collection/notification (Best Practices). Confirm the deleted item's location was in
`Hold Policy – Matter-A – Pilot`. This is why the pilot **Hold effective** gate (Testing Test 5)
tests deletion→recoverability before any live matter.

### Need to remove a hold
**Cause:** Matter closed or scope changed.
**Resolve:** Remove the **rule** then the **policy** (`Remove-CaseHoldRule` → `Remove-CaseHoldPolicy`;
or portal case → Holds → remove). **On a live matter, get legal approval first** — releasing a hold
can destroy preservation (Implementation rollback).

## Export

### Export fails, is partial, or counts don't reconcile
**Cause:** Interrupted job, throttling on a very large export, or a transient service error.
**Resolve:** Re-run the export; for large matters export in batches. Confirm final status
**Completed** and that item counts match the review-set/search estimate in `MSEDISC-Report.ps1`. Do
**not** treat a partial export as a defensible production (Testing Test 7).

### Export downloaded but no load file / report
**Cause:** Export options omitted the metadata load file or results report.
**Resolve:** Re-export selecting the **load file** and **report** options; keep both as the matter's
evidence (Best Practices — defensible export).

## Boundaries & scope

### A scoped operator can search outside their region/agency
**Cause:** Compliance security filter missing or its membership predicate is wrong.
**Resolve:** Review filters with `MSEDISC-Scope.ps1`; correct the `-RecipientFilter` predicate and
re-create (`New-ComplianceSecurityFilter`). Filter syntax is version-dependent — **verify in your
tenant**. Remember the boundary **policy** is a legal/HR decision; only its implementation is fixed
here.

## Audit / evidence

### No audit activity for the matter
**Cause:** Unified audit log disabled, or too little time has passed.
**Resolve:** Enable auditing (Requirement 2.3); allow events to populate; re-run `MSEDISC-Report.ps1`.
The audit trail is the defensibility evidence — a matter without it is not fully defensible.


---


# 7. Best Practices — Microsoft 365 Purview eDiscovery Administration

Durable practices for running eDiscovery defensibly and repeatably.

## Governance & scope
- **Legal decides, IT executes and evidences.** Scope, custodians, holds, and production are legal/
  records determinations. Keep a matter-intake record with the named legal owner and their sign-off;
  never place a live hold or export without it.
- **One case per matter, always.** Even for a "quick" request, run it inside a named case rather than
  a loose Content Search — the case gives you holds, membership, and a contained audit trail.
- **Name everything consistently.** `<Purpose> – <Scope> – <Stage>` (e.g. `eDiscovery Case –
  Matter-A – Pilot`, `Hold Policy – Matter-A – Prod`). Reuse the exact name across searches, holds,
  review sets, exports, tests, and scripts so the matter is traceable end to end.

## Least privilege
- **Grant eDiscovery via role groups, not Global Admin.** Operators → **eDiscovery Manager** (own
  cases); a small, named group → **eDiscovery Administrator**. Review membership periodically.
- **Use compliance boundaries where policy requires** separation (region/agency/business unit).
  Define the boundary once, before matters run; the boundary policy is a legal/HR decision.

## Query & collection
- **Start narrow, widen only if needed.** Prefer explicit conditions (date range, participants,
  `kind:`/`filetype:`, sensitive-info type) over broad free-text; an over-broad KQL query is
  expensive and undermines defensibility.
- **Always estimate and preview before you export.** Read the search statistics and preview a sample
  to confirm on-topic hits across **all** in-scope workloads — including Teams messages (collected
  via the mailbox) and Teams files (via SharePoint/OneDrive).
- **Watch for unindexed/partially-indexed items.** Include them deliberately in Premium collections
  and note them; do not silently drop content that could not be indexed.

## Preservation (holds)
- **Place the hold before you collect or notify** when preservation is required — deletion between
  request and hold is the classic spoliation risk.
- **Prefer custodian holds (Premium) for people-centric matters** so preservation, communications,
  and data sources track together; use case holds (Standard) for location-centric preservation.
- **Document hold scope and keep it current** as custodians join/leave; release holds only with
  legal approval and record the release.

## Review efficiency (Premium)
- **Run analytics before human review** — email threading, near-duplicate detection, and
  de-duplication routinely cut the volume reaching expensive review. Enable de-dup on every review
  set.
- **Tag and redact in the review set, not the source.** The review set is the static, defensible
  copy; never alter source content.

## Defensible export
- **Always keep the export/results report and load file** as the evidence that the production was
  complete; reconcile item counts against the review-set/search estimate before handing anything to
  outside counsel.
- **Produce redacted/native per legal's instruction**, not by operator default.

## Safety & automation
- **Read-only or dry-run by default.** The scripts here default to reporting/`-WhatIf`; require an
  explicit `-Apply` to create searches, holds, or filters. Pilot every high-impact action
  (broad hold, export) on `Matter-A` first.
- **Modern auth only, no secrets in code.** Connect with `Connect-IPPSSession` / `Connect-MgGraph`
  (MFA); never embed credentials, tokens, or app secrets in a script or in source control.
- **Cloud/version awareness.** Government clouds use different portal hosts (e.g. `*.office365.us`)
  and the eDiscovery UI was modernized (unified Standard/Premium) — confirm paths and Graph cmdlet
  parameters **in your tenant** rather than trusting older screenshots.

## Evidence & auditing
- **Keep audit on and export the audit trail per matter.** Case, search, hold, and export activity in
  the unified audit log is the proof of a defensible process — treat it as a deliverable of every
  matter.


---


# 8. Deliverables Summary — Microsoft 365 Purview eDiscovery Administration

## Documentation
- **01 – Solution Overview** — the eDiscovery model (Content Search vs Standard vs Premium), cases,
  holds/custodians, review sets, analytics, export, and how it differs from Purview DLP/labels/
  retention; the reference design and deployment model.
- **02 – Requirements Guide** — every prerequisite (licensing/tier, eDiscovery roles, audit,
  in-scope workloads, legal owner, modules, pilot matter, compliance boundary, change control) with
  Verify / Implement steps and a checklist.
- **03 – Implementation Guide** — the ordered **Assess → Design → Configure → Pilot → Validate →
  Expand** build: create the case, design the KQL/condition query, run and refine Content Searches,
  place holds, and (Premium) add custodians, collect a review set, run analytics/de-dup, and export —
  every artifact named, with pass/fail gates and rollback.
- **05 – Testing & Validation** — nine procedures with expected pass/fail (search scoped, hold
  effective, export complete + defensible, audit present) and a gate summary.
- **06 – Troubleshooting** — common failure modes and resolutions (no hits, missing Teams content,
  hold not preserving, Premium features absent, export errors, boundary issues).
- **07 – Best Practices** — durable practices for defensible, least-privilege, repeatable eDiscovery.
- **Executive Summary** — outcome, approach, and why the approach is low-risk.

## PowerShell scripts (5) — safe-by-default (read-only or `-WhatIf`; modern auth; no secrets)
1. **`MSEDISC-Discovery.ps1`** — **read-only** eDiscovery posture & readiness check. Reports
   eDiscovery role-group membership (Manager/Administrator), existing cases, Content Searches, and
   case holds, and whether the unified audit log is on — the "what exists / am I ready" assessment.
2. **`MSEDISC-Search.ps1`** — **Content Search builder/runner, dry-run by default.** Echoes the
   `New-ComplianceSearch`/`Start-ComplianceSearch` it would run for `Content Search –
   <Matter>-Keywords – <Stage>` with your KQL and locations; creates and starts only with `-Apply`.
3. **`MSEDISC-CaseHold.ps1`** — **case + hold configuration helper, dry-run by default.** Creates the
   case and a case-hold policy/rule (`New-ComplianceCase`, `New-CaseHoldPolicy`, `New-CaseHoldRule`)
   named to the matter; previews by default, commits with `-Apply`. Never removes holds silently.
4. **`MSEDISC-Report.ps1`** — **search / hold / export status report (read-only).** Summarizes
   Content Search statistics and actions, case-hold status, and (where the Graph Security module is
   present) Premium case/export status, plus eDiscovery audit activity — the evidence pack.
5. **`MSEDISC-Scope.ps1`** — **scope / config helper, dry-run by default.** Reports and (with
   `-Apply`) creates a **compliance security filter** (`New-ComplianceSecurityFilter`) to enforce an
   eDiscovery boundary, and validates that the matter's named objects exist. The boundary *policy* is
   a legal/HR determination; the script only implements it.

All scripts print clear, named output referencing the same artifact names used in the Implementation
and Testing guides, so the docs and automation stay in lockstep.
