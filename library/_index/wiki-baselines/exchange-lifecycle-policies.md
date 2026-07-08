# Exchange Lifecycle Policies — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: DLCEXO

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Exchange Lifecycle Policies in Microsoft Purview

Mailboxes grow without limit unless something governs the lifecycle of the mail inside them. Left
unaddressed, that is two liabilities at once: a **compliance gap** — you cannot demonstrate that mail
is kept as long as your schedule requires, and only that long — and a **data-risk exposure** — years of
old messages, emptied Deleted Items, and junk accumulating in every mailbox as discoverable, breachable
content. This solution closes both by delivering **Exchange-focused lifecycle policies** in **Microsoft
Purview**, end to end.

It gives a competent M365/compliance administrator a repeatable way to stand up **two complementary
engines**: **Purview Data Lifecycle Management retention** (the compliance-grade "keep, then defensibly
delete" control that overrides user deletion for the required period) and **Exchange messaging records
management** (the housekeeping engine that ages out Deleted Items and Junk and tiers old mail to the
archive) — configured to your schedule, scoped to a pilot ring, validated with explicit pass/fail
gates, and only then expanded.

This is a complete, deploy-it-carefully package, written for the administrator implementing Exchange
retention and cleanup for the first time.

## What you get
- A plain-language Solution Overview of the two engines, how they interact (principles of retention/
  precedence), and why retention **delete is high-impact and has no simulation mode**.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — licensing, the two
  PowerShell connections, the records schedule, legal holds, cleanup/archive design, and the pilot ring.
- An Implementation Guide of precise, ordered steps that configures both engines **scoped to a pilot**,
  supports a **retain-first** deployment, names every policy/tag/scope, and includes rollback.
- Five PowerShell scripts: a lifecycle discovery inventory, a scope-manifest helper, a configuration
  helper (`-WhatIf`/retain-first by default), a coverage/health report, and a PASS/GAP readiness gate —
  read-only or `-WhatIf` by default, no credentials in code.
- Testing and Troubleshooting guides, including a **blast-radius** check that proves nothing outside
  scope is touched.

## What this delivers
Mail retained for exactly as long as the schedule requires and no longer; Deleted Items and Junk aged
out on a set cadence; old mail moved to the archive to keep primary mailboxes lean; and every
destructive behavior proven on a bounded pilot before it reaches production mailboxes.

## The deployment model
Assess → Design → Configure → Pilot (limited scope / retain-first) → Validate → Expand (enforce).

## Scope boundary
This solution provides the **technical method and evidence**. The **retention schedule** (how long mail
is kept, when it may be deleted), any **legal hold**, and the decision to apply an irreversible
**Preservation Lock** are **records, privacy, and legal determinations** deferred to those functions —
not technical defaults and not the administrator's call (see `global-requirements-purview.md` §5).
Because retention delete is largely irreversible and has no simulation mode, the pilot ring is the
safety mechanism.

## Outcome
Exchange mail governed on policy in Microsoft Purview — kept, cleaned, and tiered exactly as the
schedule directs, piloted and validated before enforcement — so the capability is in place, defensible,
and evidenced.


---


# Solution Overview — Exchange Lifecycle Policies in Microsoft Purview

## What this solution delivers

Mailboxes grow forever unless something tells mail when to **stay** and when to **go**. Left alone,
that is two problems at once: a **compliance gap** (you cannot show that mail is kept for as long as
the schedule requires — and only as long) and a **data-risk exposure** (years of old messages,
deleted items, and junk sitting in every mailbox as discoverable, breachable content). This solution
closes both by delivering **Exchange-focused lifecycle policies** in **Microsoft Purview**: a
**retention** side that keeps mail for the required period, and a **cleanup** side that removes or
archives mail once it is past its useful life — configured to your schedule, piloted on a bounded
scope, validated with pass/fail gates, and operable.

This solution walks a competent-but-novice administrator through a **complete, repeatable Exchange
lifecycle deployment** built from **two complementary engines**:

1. **Purview Data Lifecycle Management retention (the "keep" and "keep-then-delete" engine).** A
   **retention policy** scoped to **Exchange mailboxes** (and, where in scope, Exchange **public
   folders**) with a **retention rule** that says *retain for N, then delete* — or *retain only*, or
   *delete only* — applied per the schedule your records function sets. This is the compliance-grade
   control: retention overrides user deletion (content is preserved in the Recoverable Items folder
   even if the user empties it) for the duration of the retain period.
2. **Exchange (MRM) messaging records management (the "housekeeping / cleanup" engine).** A **retention
   policy** made of **retention tags** that quietly age mail out of noisy folders — permanently delete
   **Deleted Items** and **Junk Email** after a set age, and (optionally) **move older mail to the
   archive mailbox** with a default policy tag — run by the **Managed Folder Assistant**. This is the
   hygiene control that keeps primary mailboxes lean.

The two are designed to work **together**: Purview retention guarantees the floor (mail is kept long
enough and is defensibly removed at end-of-life), while MRM handles day-to-day cleanup and archive
tiering. This solution configures both, names every policy/tag/scope, pilots on a limited ring
**before** any destructive action reaches production mailboxes, validates, and only then expands.

## Read this first — retention deletion is high-impact and there is no "simulation" toggle

Unlike DLP or auto-labeling, **Purview retention policies do not have a simulation/test mode**. When a
retention rule includes a **delete** action, mail **past the retention age is permanently removed** —
this is real, and for most tenants **irreversible** once the Recoverable Items window passes. Two
principles therefore run through every step:

- **Pilot by SCOPE, not by simulation.** The safe pilot here is a **small, named pilot ring** (a
  handful of mailboxes / a pilot group) and, where you want extra safety, starting the retention rule
  as **retain-only** (no delete) or with a deliberately long test window, **validating**, and adding
  the delete action only after the gate passes. Never point a keep-**then**-delete rule at the whole
  tenant on day one.
- **The schedule is a records/legal determination, not a technical default.** *How long* mail must be
  kept, *when* it may be deleted, and *which* mail is subject to legal hold are decided by your
  **records-management, compliance, privacy, and legal** functions — not by this solution and not by
  the administrator. This solution provides the **technical method and the evidence**; the retention
  schedule and any hold come from the owners who set them (see `global-requirements-purview.md` §5).

> **Preservation Lock is irreversible.** If your regulatory obligations require an immutable,
> can-never-be-shortened retention policy, Purview offers **Preservation Lock** — but once locked, the
> policy **cannot be disabled, deleted, or made less restrictive by anyone, including a Global
> Administrator**. Treat locking as a separate, records-approved decision; this solution keeps policies
> **unlocked** unless your records function explicitly directs otherwise.

## How the pieces fit

- **Retention policy (Purview) → retention rule.** The **policy** defines *where* it applies
  (Exchange mailboxes, public folders) and *to whom* (all mailboxes, a static list, or an **adaptive
  scope**). The **rule** defines *the behavior*: `Retain` (keep), `Delete` (remove), or `KeepAndDelete`
  (retain N, then delete), with the duration measured from when content was created or last modified.
  Retention **wins over user deletion** while the retain period runs.
- **MRM retention policy → retention tags.** An MRM **policy** is a bundle of **tags**: a **Default
  Policy Tag (DPT)** applies to all untagged items (e.g. *move to archive after 2 years*), **Retention
  Policy Tags (RPTs)** apply to specific default folders (e.g. *Deleted Items → permanently delete
  after 30 days*), and optional **Personal Tags** users can apply themselves. Assigned to a mailbox
  and run by the **Managed Folder Assistant**, this is the cleanup/archive engine.
- **The archive mailbox (optional tier).** Enabling the **online archive** (and **auto-expanding
  archive** where licensed) gives MoveToArchive tags somewhere to move old mail to — shrinking the
  primary mailbox while keeping the content searchable and within retention.
- **Precedence, understood.** When multiple retention settings apply, Purview follows a defined
  **principles of retention** order (retain wins over delete; longest retention wins; explicit wins
  over default). This solution names each object so precedence is deliberate, not accidental.

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure → Pilot (limited scope / retain-first) → Validate → Expand (enforce).**

- **Assess** — confirm licensing (retention is available on **Exchange Online Plan 2 / M365 E3+**;
  adaptive scopes and auto-expanding archive have their own plan gates — **verify your licensing/
  tenant**), roles, the in-scope mailboxes, the **records schedule**, and legal-hold status.
- **Design** — with records/legal, decide the **retention schedule** (retain N, then delete? retain
  only?), the **cleanup** tags (Deleted Items / Junk age-out, archive DPT), the **pilot ring**, and
  **name every object**.
- **Configure** — create the Purview retention policy + rule scoped to the **pilot**, and the MRM
  policy + tags; assign the MRM policy to pilot mailboxes.
- **Pilot** — run on the pilot ring only; where extra safety is wanted, retain-only first. Confirm
  mail is being kept/moved/cleaned as intended and **nothing outside scope is touched**.
- **Validate** — run the pass/fail gates in `05-testing.md`.
- **Expand** — widen the Purview policy scope (to all mailboxes / an adaptive scope) and add/enable the
  delete action **only** after the gate passes.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing** (pass/fail
  gates), **Troubleshooting**, **Best Practices**, and a **Deliverables Summary** + **Executive
  Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Exchange Online PowerShell / Graph): a
  lifecycle **discovery** inventory, a **scope** manifest helper, a **configuration** helper
  (`-WhatIf`/retain-first by default, applies only with `-Commit`), a coverage/health **report**, and a
  PASS/GAP **readiness** gate — read-only or `-WhatIf` by default; **no credentials in code**.

> **Sources:** Microsoft Learn — *Learn about retention policies & retention labels*, *Create and
> configure retention policies*, *Principles of retention*, *Preservation Lock*, *Adaptive scopes*
> (Purview Data Lifecycle Management); *Retention tags and retention policies (MRM)*, *Set up an
> archive and retention policy*, *Enable auto-expanding archiving*, and *Managed Folder Assistant*
> (Exchange Online). Retention/lifecycle capability is **licensing-dependent** and the Purview portal
> is **evolving** — **verify capability availability and portal paths against your licensing/tenant**
> rather than assuming.


---


# Requirements — Exchange Lifecycle Policies in Microsoft Purview

Confirm every prerequisite below **before** you configure anything. Category-level prerequisites
(tenant, licensing model, least-privilege roles, S&C PowerShell / Graph toolchain, in-scope data
sources, compliance/records/privacy/legal stakeholders, pilot scope + change control) are in
`global-requirements-purview.md` — reference them; they are **not** repeated here. The items below are
the ones **specific to Exchange lifecycle policies** and their two engines: **Purview Data Lifecycle
Management retention** and **Exchange (MRM) messaging records management**.

Each requirement is written as **Description · Why · Verify · Implement if missing.**

> The retention **schedule** (how long mail is kept, when it may be deleted) and any **legal hold**
> are **records/legal determinations**, not technical defaults — see `global-requirements-purview.md`
> §5. Several requirements below are hard gates because retention **delete** is destructive and, past
> the recovery window, **irreversible**.

---

## R1. Licensing for Exchange retention + MRM + archive

**Description:** Microsoft 365 / Exchange Online plans that unlock the pieces you use: **Purview
retention policies** for Exchange (available with **Exchange Online Plan 2**, included in **Microsoft
365 E3/E5** and equivalents); the **online archive mailbox** (Plan 2 / E3+) and **auto-expanding
archiving** (E3/E5 or Exchange Online archiving add-on) if you use MoveToArchive cleanup; and
**adaptive scopes** (require **E5 / E5 Compliance**) if you scope the retention policy dynamically.
**Why:** Retention, archive, and adaptive scoping are plan-gated; the control will not be available
without the right plan, and in-scope mailboxes must be licensed.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; in the Purview portal, **Data
Lifecycle Management → Retention Policies** is present and **Exchange** is a selectable location;
archive availability shows per mailbox. Cross-check advanced features against the *Microsoft Purview
service description* — **verify against your licensing/tenant.**
**Implement if missing:** Acquire/assign the required SKUs/add-ons before configuring. If you lack E5,
use **static scoping** (a mailbox list / group) instead of adaptive scopes.

## R2. Least-privilege roles — retention (Purview) and MRM (Exchange)

**Description:** The least-privilege roles for each engine, mapped to **named** people:
- **Retention Management** or **Compliance Administrator / Compliance Data Administrator** in the
  Purview portal to author **retention policies and rules**.
- **Retention Management** role (Exchange Online RBAC) to create **MRM retention tags/policies** and
  assign them to mailboxes; **Recipient Management** where you also change mailbox settings/archive.
- **Global Administrator** only where genuinely required (e.g. first-time Purview role assignment).
**Why:** Purview retention and Exchange MRM use **separate** role models; configuring both requires the
matching least-privilege role on each surface, without over-granting.
**Verify:** Purview → **Roles & scopes / Permissions** (retention roles); Exchange admin center →
**Roles → Admin roles** (Retention/Recipient Management). `DLCEXO-Discovery.ps1` reports the role
signals it can read.
**Implement if missing:** Assign the least-privilege role on each surface under change control.

## R3. Exchange Online PowerShell + Security & Compliance PowerShell toolchain

**Description:** A workstation with the **ExchangeOnlineManagement** module, able to run both
**`Connect-IPPSSession`** (Security & Compliance — for Purview retention policies/rules) and
**`Connect-ExchangeOnline`** (Exchange Online — for MRM tags/policies, mailbox assignment, and the
Managed Folder Assistant), with a modern-auth / MFA-capable admin account.
**Why:** The two engines are configured through **two different connections** in the same module; the
provided scripts use both. Graph is used only for read-only mailbox/scope signals.
**Verify:** `Connect-IPPSSession` and `Connect-ExchangeOnline` both succeed; `Get-RetentionCompliancePolicy`
and `Get-RetentionPolicy` each return without error.
**Implement if missing:** `Install-Module ExchangeOnlineManagement`; confirm modern-auth sign-in for
both connections before running steps.

## R4. The retention schedule (records determination) — retain, delete, or keep-then-delete

**Description:** A **documented retention schedule for mail**, approved by records/legal: the
**retain period** (e.g. retain 7 years), whether mail is **deleted at end-of-life** (`KeepAndDelete`),
**retained only** (`Retain`), or **deleted by age** with no retain guarantee (`Delete`), and whether
the period runs from **created** or **last-modified** date.
**Why:** This determines exactly what the retention rule does to real mail; a delete action is
destructive. It is a **records/legal determination**, not a technical choice.
**Verify:** Confirm the approved schedule **in writing**, including the disposition action and duration,
before you author the rule.
**Implement if missing:** **Stop** and obtain it from records/legal. Do not enable a delete action on a
schedule you cannot cite. (See `global-requirements-purview.md` §5.)

## R5. Legal-hold / eDiscovery status of the in-scope mailboxes

**Description:** Knowledge of which in-scope mailboxes are under a **litigation hold**, **eDiscovery
hold**, or an existing **retention policy/label** that preserves content — and confirmation that the
new cleanup/delete behavior will not conflict with an active hold.
**Why:** A hold **overrides** delete (held content is preserved regardless), which is correct — but you
must know it, because it changes what "cleanup" actually removes and can mask a mis-scoped rule.
Removing or shortening retention on held data is a legal matter.
**Verify:** Purview → **Data Lifecycle Management / eDiscovery** and Exchange **litigation hold**
status per mailbox; `DLCEXO-Discovery.ps1` reports litigation-hold and existing-policy signals it can
read.
**Implement if missing:** Reconcile holds with records/legal **before** enabling delete/cleanup;
exclude or defer any mailbox whose hold status is unresolved.

## R6. Cleanup design — MRM tags and the archive tier

**Description:** The **MRM cleanup design**, agreed with the business: which default folders are aged
out (e.g. **Deleted Items** and **Junk Email** → permanently delete after 30 days), whether a **Default
Policy Tag** moves old mail to the **archive** (e.g. move to archive after 2 years), and whether users
get **Personal Tags**. Plus whether the **online archive** (and **auto-expanding archive**) is enabled
where MoveToArchive is used.
**Why:** MRM is the hygiene engine; its tags act on real folders and (for delete tags) permanently
remove mail. MoveToArchive needs an archive mailbox to move to.
**Verify:** Exchange → **Compliance management → Retention tags/policies**; archive enabled per mailbox
(`Get-Mailbox -Archive`); `DLCEXO-Discovery.ps1` reports existing MRM tags/policies and archive status.
**Implement if missing:** Define the tag set and (if used) enable archive mailboxes before assigning the
MRM policy.

## R7. Pilot scope and change control (limited ring / retain-first)

**Description:** A **named pilot ring** — a small mailbox list or mail-enabled group **`SG-DLCEXO-Pilot`**
— and agreement to deploy the Purview retention policy and MRM policy to that ring **first**, under
**change control**, before any tenant-wide or delete-enabled expansion. Because retention has **no
simulation mode**, the pilot is the safety mechanism; optionally start the retention rule **retain-only**
and add delete after validation.
**Why:** Retention delete and MRM delete are high-impact and largely irreversible; the pilot ring proves
the policies keep/move/clean the right mail **without** touching anyone else, and lets you tune before
enforcing broadly.
**Verify:** Confirm the pilot group exists and its membership, that a retain-first option was
considered, and a change window/approval path. `DLCEXO-Set-Scope.ps1` (read-only) records the pilot
scope manifest; `DLCEXO-Configure.ps1` defaults to `-WhatIf`.
**Implement if missing:** Create the pilot group, deploy to it first, and agree change control before
expanding scope or enabling delete.

## R8. Managed Folder Assistant / processing expectations

**Description:** Awareness that MRM tags are applied by the **Managed Folder Assistant (MFA)**, which
runs on its own **work cycle** (roughly once per day, best-effort) — cleanup/archive is **not
instantaneous** — and that you can trigger a processing pass for a pilot mailbox with
`Start-ManagedFolderAssistant`.
**Why:** Test expectations must match reality: if you assign a tag and check a minute later, nothing
will have changed. Validation must allow for the MFA cycle (or a manual trigger on the pilot mailbox).
**Verify:** `Start-ManagedFolderAssistant -Identity <pilotMailbox>` succeeds on a pilot mailbox;
`Get-MailboxFolderStatistics` / message age reflects processing after the pass.
**Implement if missing:** Plan validation around the MFA cycle; trigger it manually on pilot mailboxes
to observe results within a test window.


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


# Implementation — Exchange Lifecycle Policies in Microsoft Purview

Follow these steps in order. The model is **Assess → Design → Configure → Pilot (limited scope /
retain-first) → Validate → Expand (enforce)** with an explicit **pass/fail gate** before you widen
scope or enable any delete action. Every object is named so precedence and scope are deliberate.

> **Before you start:** retention **delete is destructive and largely irreversible**, and Purview
> retention has **no simulation mode**. The pilot ring is your safety net. Do not point a
> keep-**then**-delete rule at all mailboxes on day one. The retention **schedule** and any **hold**
> come from records/legal (`02-requirements.md` R4/R5), not from this guide.

Named objects used throughout (rename to your convention, keep them consistent):

| Object | Name | Engine |
|---|---|---|
| Pilot ring (mail-enabled security group) | `SG-DLCEXO-Pilot` | scope |
| Purview retention policy (Exchange) | `DLCEXO-Retention-Exchange-Pilot` | Purview DLM |
| Purview retention rule | `DLCEXO-Rule-Exchange-Keep7yrThenDelete` | Purview DLM |
| MRM (cleanup) retention policy | `DLCEXO-MRM-Cleanup-Standard` | Exchange MRM |
| RPT — Deleted Items age-out | `DLCEXO-Tag-DeletedItems-30d` | Exchange MRM |
| RPT — Junk Email age-out | `DLCEXO-Tag-JunkEmail-30d` | Exchange MRM |
| DPT — move old mail to archive | `DLCEXO-Tag-Default-MoveToArchive-2yr` | Exchange MRM |

*(Durations shown — 7 years / 30 days / 2 years — are placeholders. Use the values your records
schedule specifies.)*

---

## Phase 1 — Assess

1. **Confirm licensing and roles** (`02-requirements.md` R1/R2). In the Purview portal confirm **Data
   Lifecycle Management → Retention Policies** is available and **Exchange** is a selectable location;
   confirm you hold **Retention Management / Compliance Administrator**. Confirm **Retention Management**
   in Exchange for MRM.
2. **Run the discovery inventory.** From a workstation with `Connect-IPPSSession` **and**
   `Connect-ExchangeOnline`:
   ```powershell
   .\DLCEXO-Discovery.ps1 -IncludeMailboxSample
   ```
   Review existing Purview retention policies scoped to Exchange, existing MRM tags/policies, the
   **org default MRM policy**, archive status, and any **litigation-hold** mailboxes. Pre-existing
   retention or holds change what your new policy will (and won't) remove — reconcile them now.
   **Gate:** you have a clear picture of what already governs these mailboxes. Unresolved holds → stop
   and reconcile with legal (R5).

## Phase 2 — Design (with records/legal)

3. **Fix the retention schedule** (R4). Record, in writing: retain period, disposition
   (`Retain` / `Delete` / `KeepAndDelete`), and whether the clock runs from **created** or
   **modified** date. Example working schedule: *retain 7 years from creation, then delete.*
4. **Fix the cleanup design** (R6). Decide the MRM tags: Deleted Items → permanently delete after
   30 days; Junk Email → permanently delete after 30 days; DPT → move to archive after 2 years (only
   if archive mailboxes are/will be enabled). Decide whether users get Personal Tags.
5. **Fix the pilot ring** (R7). Confirm `SG-DLCEXO-Pilot` exists with a small, representative
   membership. Record the scope manifest:
   ```powershell
   .\DLCEXO-Set-Scope.ps1 -PilotGroup "SG-DLCEXO-Pilot" -RetainDays 2555 -Disposition KeepAndDelete
   ```
   (2555 ≈ 7 years.) This writes a read-only manifest to configure against; it changes nothing.
   **Gate:** schedule, cleanup design, and pilot ring are all approved and named.

## Phase 3 — Configure (scoped to the pilot)

### 3a. Purview retention policy + rule (the keep / keep-then-delete engine)

6. **Create the retention policy scoped to the pilot**, Exchange location only. Prefer the helper in
   `-WhatIf` first, then `-Commit`:
   ```powershell
   # Preview (default): prints the plan, changes nothing
   .\DLCEXO-Configure.ps1 -PolicyName "DLCEXO-Retention-Exchange-Pilot" `
       -RuleName "DLCEXO-Rule-Exchange-Keep7yrThenDelete" `
       -PilotGroup "SG-DLCEXO-Pilot" -RetainDays 2555 -Disposition KeepAndDelete -WhatIf

   # Apply
   .\DLCEXO-Configure.ps1 -PolicyName "DLCEXO-Retention-Exchange-Pilot" `
       -RuleName "DLCEXO-Rule-Exchange-Keep7yrThenDelete" `
       -PilotGroup "SG-DLCEXO-Pilot" -RetainDays 2555 -Disposition KeepAndDelete -Commit
   ```
   Under the covers this is `New-RetentionCompliancePolicy -ExchangeLocation <pilot members>` then
   `New-RetentionComplianceRule -Policy <policy> -RetentionDuration 2555 -RetentionComplianceAction
   KeepAndDelete -ExpirationDateOption CreationAgeInDays`. **Retain-first option:** pass
   `-Disposition Retain` to deploy keep-only, validate, then re-run with `KeepAndDelete` to add delete.
   > Scoping to a group targets **its current members' mailboxes**; membership changes do not auto-
   > re-scope a static policy. For dynamic membership use an **adaptive scope** (E5) at expand time.
7. **Do NOT enable Preservation Lock** at pilot. Locking is a separate, records-approved, irreversible
   decision (`01-solution-overview.md`).

### 3b. Exchange MRM policy + tags (the cleanup / archive engine)

8. **Create the retention tags**, then bundle them into the MRM policy, then assign to pilot mailboxes.
   The `-Commit` path of the helper performs these; the equivalent Exchange cmdlets are:
   ```powershell
   New-RetentionPolicyTag "DLCEXO-Tag-DeletedItems-30d" -Type DeletedItems `
       -RetentionEnabled $true -AgeLimitForRetention 30 -RetentionAction PermanentlyDelete
   New-RetentionPolicyTag "DLCEXO-Tag-JunkEmail-30d" -Type JunkEmail `
       -RetentionEnabled $true -AgeLimitForRetention 30 -RetentionAction PermanentlyDelete
   New-RetentionPolicyTag "DLCEXO-Tag-Default-MoveToArchive-2yr" -Type All `
       -RetentionEnabled $true -AgeLimitForRetention 730 -RetentionAction MoveToArchive
   New-RetentionPolicy "DLCEXO-MRM-Cleanup-Standard" -RetentionPolicyTagLinks `
       "DLCEXO-Tag-DeletedItems-30d","DLCEXO-Tag-JunkEmail-30d","DLCEXO-Tag-Default-MoveToArchive-2yr"
   ```
   Include the DPT (`-Type All … MoveToArchive`) **only if** archive mailboxes are enabled for the
   pilot users (`Enable-Mailbox -Archive`). Assign to each pilot mailbox:
   `Set-Mailbox -Identity <pilotMailbox> -RetentionPolicy "DLCEXO-MRM-Cleanup-Standard"`.
9. **Trigger a processing pass** on a pilot mailbox so you can observe results within the test window:
   ```powershell
   Start-ManagedFolderAssistant -Identity <pilotMailbox>
   ```
   **Gate (Configure):** both policies exist, are scoped to the pilot only, and the MFA has run at
   least once on a pilot mailbox. `DLCEXO-Report.ps1` should show the pilot mailboxes as covered.

## Phase 4 — Pilot & Validate

10. **Validate on the pilot ring** using `05-testing.md`. Confirm: retention is **preserving** mail
    against user deletion (Recoverable Items holds it) for in-scope pilot mailboxes; MRM is
    **cleaning** Deleted Items / Junk on schedule; MoveToArchive is **moving** old mail to the archive;
    and **no mailbox outside `SG-DLCEXO-Pilot` is affected**.
11. **Run the readiness gate:**
    ```powershell
    .\DLCEXO-Test-Readiness.ps1
    ```
    All checks **PASS** (or every **GAP** is understood and accepted by records/legal) → proceed.
    Any unexplained GAP, or any out-of-scope mailbox touched → **stop, fix, re-pilot.**

## Phase 5 — Expand (enforce)

12. **Widen the Purview retention scope** only after the gate passes: re-scope
    `DLCEXO-Retention-Exchange-Pilot` from the pilot group to **all mailboxes** or an **adaptive scope**
    (E5), and — if you piloted retain-only — **add the delete action** now
    (`Set-RetentionComplianceRule -RetentionComplianceAction KeepAndDelete`). Rename the policy to drop
    `-Pilot` if you wish, keeping the name consistent in your records.
13. **Assign the MRM policy more broadly** (or set it as the mailbox default for new mailboxes) under
    change control, staging in rings.
14. **Record the evidence.** Export the final `DLCEXO-Report.ps1` and `DLCEXO-Test-Readiness.ps1`
    output as the deployment evidence (policy names, scope, durations, coverage), and hand the
    retention-schedule mapping back to records.

## Rollback

- **Purview retention (keep-only or not yet deleted):** `Set-RetentionCompliancePolicy -Enabled $false`
  (unless **Preservation Locked** — locked policies cannot be disabled by anyone). Removing a policy
  before its delete action has run leaves mail intact.
- **Purview retention after deletion has run:** deleted mail past the Recoverable Items window is
  **not** recoverable — this is why you pilot and retain-first. There is no rollback for already-
  deleted content.
- **MRM cleanup:** unassign with `Set-Mailbox -RetentionPolicy $null` (or a benign policy) and the MFA
  stops applying the tags going forward; **already-deleted** items past recovery are not restorable.
  **MoveToArchive** is reversible in effect (content moved to the archive is still the user's and
  searchable), but re-homing it to the primary is a manual/eDiscovery operation.
- Always capture the current state with `DLCEXO-Discovery.ps1` **before** changes so rollback targets a
  known-good baseline.


---


# Testing & Validation — Exchange Lifecycle Policies in Microsoft Purview

Run these gates on the **pilot ring** (`SG-DLCEXO-Pilot`) before expanding scope or enabling any delete
action. Each test has an explicit **PASS / FAIL** signal. A FAIL means **stop, fix, and re-pilot** — do
not widen scope or add a delete action on a failing gate. Because retention **delete is destructive and
has no simulation mode**, the most important gate is **G5: nothing outside scope is touched.**

> Allow for the **Managed Folder Assistant** cycle (roughly daily, best-effort). For MRM tests, trigger
> a pass first: `Start-ManagedFolderAssistant -Identity <pilotMailbox>`. Purview retention can also take
> time to fully apply after a policy is created.

---

## G1. Scope is correct — only pilot mailboxes are in the policy

- **How:** `Get-RetentionCompliancePolicy "DLCEXO-Retention-Exchange-Pilot" | Select ExchangeLocation`
  and confirm it lists **only** the pilot members. `Get-Mailbox <pilotMailbox> | Select RetentionPolicy`
  shows `DLCEXO-MRM-Cleanup-Standard`. Run `DLCEXO-Report.ps1`.
- **PASS:** the Purview policy's ExchangeLocation resolves to pilot members only, and pilot mailboxes
  carry the MRM policy.
- **FAIL:** any non-pilot mailbox appears in scope, or a pilot mailbox is missing the MRM policy.

## G2. Retention rule is configured as designed

- **How:** `Get-RetentionComplianceRule -Policy "DLCEXO-Retention-Exchange-Pilot" | Select Name,
  RetentionDuration, RetentionComplianceAction, ExpirationDateOption`.
- **PASS:** duration, action (`Retain` / `KeepAndDelete` per your approved schedule), and date basis
  match `02-requirements.md` R4 exactly.
- **FAIL:** any value differs from the approved schedule (especially a **delete** action that records/
  legal did not approve).

## G3. Retention preserves mail against user deletion (the "keep" guarantee)

- **How:** In a pilot mailbox, delete a test message and empty Deleted Items (and empty Recoverable
  Items "Deletions" from the client where possible). Confirm via **eDiscovery content search** or
  `Get-MailboxFolderStatistics <pilotMailbox> -FolderScope RecoverableItems` that the item is still
  **preserved** (in Recoverable Items) within the retain period.
- **PASS:** the "deleted" item is still recoverable/preserved — retention overrode the user deletion.
- **FAIL:** the item is gone with an active retain rule → policy not applied yet (allow more time) or
  mis-scoped.

## G4. MRM cleanup ages out the right folders

- **How:** Trigger `Start-ManagedFolderAssistant -Identity <pilotMailbox>`. On a pilot mailbox with a
  message older than the tag age in **Deleted Items** / **Junk Email**, confirm the item is removed
  after the pass; confirm the **MoveToArchive** DPT moved older primary-folder mail into the **archive**
  mailbox (`Get-MailboxFolderStatistics <pilotMailbox> -Archive`).
- **PASS:** aged Deleted Items/Junk are permanently removed; older mail appears in the archive; newer
  mail and other folders are untouched.
- **FAIL:** nothing changed after an MFA pass (check tag age/enabled, archive enabled for MoveToArchive),
  or a folder outside the tag design was affected.

## G5. Blast-radius check — NO mailbox outside the pilot is affected

- **How:** Pick 2–3 **non-pilot** mailboxes. Confirm `Get-Mailbox <nonPilot> | Select RetentionPolicy`
  is **not** `DLCEXO-MRM-Cleanup-Standard`, and that they are **not** in the Purview policy's
  ExchangeLocation. Confirm no cleanup/deletion occurred in them. Run `DLCEXO-Test-Readiness.ps1`.
- **PASS:** non-pilot mailboxes are untouched by both engines.
- **FAIL:** any non-pilot mailbox carries the policy or shows cleanup → **immediately** roll back scope
  (`03-implementation.md`) before continuing.

## G6. Holds are honored (no held mail deleted)

- **How:** For any pilot mailbox on litigation/eDiscovery hold (from `DLCEXO-Discovery.ps1`), confirm
  that mail which would otherwise be deleted by MRM/retention is **still preserved** (holds override
  delete).
- **PASS:** held content is preserved despite delete tags/rules.
- **FAIL:** held content was removed → **stop**, treat as a legal incident, and escalate to legal.

## G7. Readiness gate is green

- **How:** `.\DLCEXO-Test-Readiness.ps1`.
- **PASS:** every check returns **PASS**, or each **GAP** is documented and accepted by records/legal.
- **FAIL:** any unexplained GAP.

---

### Exit criteria (before Expand)
All of **G1–G7 PASS** (or GAPs accepted in writing), evidence exported from `DLCEXO-Report.ps1` and
`DLCEXO-Test-Readiness.ps1`, and records/legal sign-off on record. Only then widen the Purview scope /
add the delete action / broaden the MRM assignment per `03-implementation.md` Phase 5.


---


# Troubleshooting — Exchange Lifecycle Policies in Microsoft Purview

Field issues and how to resolve them, grouped by engine. Start every investigation with a read-only
baseline: `.\DLCEXO-Discovery.ps1 -IncludeMailboxSample` and `.\DLCEXO-Report.ps1`. Remember the two
timing realities: **Purview retention** can take time to fully provision after a policy is created, and
**MRM cleanup** runs on the **Managed Folder Assistant** cycle (roughly daily, best-effort).

---

## Connection & permissions

**`Get-RetentionCompliancePolicy` / `New-RetentionCompliancePolicy` not recognized or access denied.**
- You are not connected to **Security & Compliance PowerShell**, or lack the role. Run
  `Connect-IPPSSession` with a **Retention Management / Compliance Administrator** account
  (`02-requirements.md` R2/R3). These cmdlets do **not** exist in a plain `Connect-ExchangeOnline`
  session.

**`New-RetentionPolicyTag` / `Set-Mailbox -RetentionPolicy` fails.**
- Those are **Exchange Online** cmdlets — run `Connect-ExchangeOnline` (separate from IPPS) with the
  **Retention Management** role. The scripts expect **both** connections open.

**"You don't have sufficient permissions" on `Set-Mailbox`.**
- MRM assignment needs **Recipient Management** (or Retention Management with recipient write). Assign
  the least-privilege role rather than escalating to Global Admin.

## Purview retention (keep / keep-then-delete)

**Policy created but mail isn't being preserved yet.**
- Retention policies take time to **provision and apply** after creation (can be hours). Re-check with
  `Get-RetentionCompliancePolicy -Identity <name> -DistributionDetail | Select DistributionStatus`.
  Wait for distribution to complete before concluding the "keep" gate (G3) failed.

**A "deleted" test message really disappeared under an active retain rule.**
- Either the policy hasn't finished distributing (above), or the mailbox isn't actually in scope. Run
  `DLCEXO-Test-Readiness.ps1` — the **scope = pilot only** check shows whether the mailbox is in
  `ExchangeLocation`. Retention preserves to **Recoverable Items**; verify there / via eDiscovery, not
  just the visible folders.

**I need to remove a policy but `Set-RetentionCompliancePolicy -Enabled $false` is refused.**
- The policy is under **Preservation Lock** — by design it **cannot be disabled, deleted, or shortened
  by anyone**, including a Global Admin. This is why this solution keeps policies **unlocked** unless
  records explicitly directs locking. There is no self-service unlock.

**Delete action removed mail I did not expect.**
- Check `ExpirationDateOption` (**CreationAgeInDays** vs **ModificationAgeInDays**) — the wrong basis
  ages mail differently than intended — and the `RetentionDuration`. Because deletion past the recovery
  window is **irreversible**, treat this as an incident: freeze expansion, confirm scope, and escalate
  to records/legal if held or in-scope-but-not-approved mail was affected.

**Group-scoped policy isn't covering new members.**
- A **static** group scope targets the mailboxes that were members **when scoped**; it does not
  auto-re-scope. Either re-run configuration to refresh scope or move to an **adaptive scope** (E5) at
  expand time (`03-implementation.md` Phase 5; `07-best-practices.md`).

## Exchange MRM cleanup (Deleted Items / Junk / archive)

**Assigned the MRM policy but nothing has been cleaned.**
- The **Managed Folder Assistant** hasn't run yet. Trigger it on the pilot mailbox:
  `Start-ManagedFolderAssistant -Identity <pilotMailbox>`, then re-check. Also confirm the tags are
  **RetentionEnabled = $true** and the item is genuinely **older** than `AgeLimitForRetention`.

**MoveToArchive tag isn't moving anything.**
- The mailbox has **no archive**. `Get-Mailbox <mbx> | Select ArchiveStatus,ArchiveState` — if there is
  no archive, `Enable-Mailbox -Identity <mbx> -Archive` first (licensing permitting), then re-run the
  MFA. MoveToArchive has nowhere to move mail without an archive.

**Cleanup is deleting mail that should be kept.**
- A **hold** (litigation/eDiscovery) or a **Purview retain** rule should override an MRM delete
  (retain wins over delete — `07-best-practices.md`). If held mail was removed, treat it as a **legal
  incident** and escalate. Otherwise confirm the tag ages/types match the design (`03-implementation.md`
  Phase 3b) and that you didn't attach an unintended DPT.

**Age limits look right but items persist past the age.**
- MFA is **best-effort** and throttled by mailbox size and work-cycle; large mailboxes converge over
  multiple cycles. Confirm the tag is linked to the assigned policy (`Get-RetentionPolicy <name> |
  Select RetentionPolicyTagLinks`) and that the item's folder matches the tag **Type**.

## Scope & blast radius

**A non-pilot mailbox was affected.**
- **Stop and roll back scope immediately** (`03-implementation.md` Rollback): unassign the MRM policy
  (`Set-Mailbox -RetentionPolicy $null`) and remove the mailbox from the Purview policy's
  `ExchangeLocation`. Then re-run `DLCEXO-Test-Readiness.ps1` (the C5 blast-radius check) until it PASSes
  before continuing. Investigate how the mailbox entered scope (group membership? "All"? adaptive-scope
  query?).

**Readiness gate shows GAP on "scope = pilot only".**
- The policy is scoped to **All** or lists mailboxes outside the pilot group. Re-scope to the pilot
  before doing anything else — this is the guardrail that keeps a destructive rule off production
  mailboxes.

## Reporting & evidence

**`DLCEXO-Report.ps1` shows no per-mailbox rows.**
- The policy is likely scoped to **All** or an **adaptive scope**, so there are no explicit addresses to
  enumerate. Pass `-PilotGroup` to report per-mailbox, or accept that estate-wide scope reports at the
  policy level.

**I need audit evidence of what changed.**
- Export `DLCEXO-Report.ps1` and `DLCEXO-Test-Readiness.ps1` output at each phase and keep the
  policy/rule/tag names, scope, and durations. For end-to-end change history, use the **unified audit
  log** (retention config changes are audited) and the Purview policy's own change record.

> If a symptom isn't covered here, capture a fresh `DLCEXO-Discovery.ps1` baseline and re-run
> `DLCEXO-Test-Readiness.ps1` — most issues resolve to (a) not connected to both endpoints, (b) timing
> (distribution / MFA cycle), (c) scope drift, or (d) a hold correctly overriding a delete. Regulatory,
> records, and legal questions go to those owners, not the administrator.


---


# Best Practices — Exchange Lifecycle Policies in Microsoft Purview

Field-proven recommendations for running Exchange retention + cleanup safely. They reinforce the
model: **Assess → Design → Configure → Pilot → Validate → Expand**, with records/legal owning the
schedule.

## Treat delete as one-way — pilot and retain-first
- Retention **delete has no simulation mode and is largely irreversible** past the recovery window.
  Deploy **keep-only first** on the pilot, validate the "keep" behavior, and add the delete action only
  after the gate passes. This is the single most important habit in this solution.
- Never point a keep-**then**-delete rule at all mailboxes on day one. Widen scope in **rings**.

## Keep the schedule with records, not in the tool
- The retain period, disposition, and legal holds are **records/legal determinations**. Store the
  approved schedule in your records system and map policy names to it; the Purview policy is the
  *implementation*, not the *decision*. Re-confirm the schedule at each expansion.

## Name and document precedence deliberately
- Use consistent, self-describing names (`DLCEXO-Retention-Exchange-*`, `DLCEXO-Tag-*`,
  `DLCEXO-MRM-Cleanup-*`) so anyone reading the tenant can see scope and intent.
- Understand **principles of retention**: **retain wins over delete**, **longest retention wins**,
  **explicit wins over default**. When Purview retention and MRM both apply, expect Purview's
  preservation to win over an MRM delete — design so this is intentional, not a surprise.

## Prefer adaptive scopes for dynamic populations (where licensed)
- A **static** group scope targets *current* members and does not auto-re-scope as membership changes.
  For "all mailboxes in Legal" or "all leavers," an **adaptive scope** (E5) keeps membership current
  automatically. Confirm licensing before relying on it.

## Use the archive tier to shrink mailboxes without losing content
- **MoveToArchive** DPTs plus the **online / auto-expanding archive** keep primary mailboxes lean while
  content stays searchable and within retention. Enable the archive **before** assigning MoveToArchive
  tags, or the tag has nowhere to move mail to.

## Respect the Managed Folder Assistant cadence
- MRM is **best-effort, ~daily**, not instant. Don't judge cleanup on a stopwatch; trigger
  `Start-ManagedFolderAssistant` on pilot mailboxes for testing, but expect production to converge over
  a work cycle.

## Reconcile with holds every time
- A litigation/eDiscovery hold **overrides** delete (correctly). Always run discovery first so you know
  which mailboxes are held; never assume "cleanup removed it" for held content, and treat any held-mail
  deletion as a legal incident.

## Preservation Lock is a separate, deliberate decision
- Lock **only** when regulation requires immutability and records has approved it — a locked policy
  **cannot be shortened, disabled, or deleted by anyone**, including a Global Admin. Default to
  **unlocked**.

## Automate read-only, gate the writes
- Run `DLCEXO-Discovery.ps1` / `DLCEXO-Report.ps1` / `DLCEXO-Test-Readiness.ps1` on a schedule for
  ongoing assurance (coverage, drift, out-of-scope mailboxes). Keep all write operations behind
  `-WhatIf` → `-Commit` and change control. **No credentials in scripts** — use interactive modern-auth
  or a managed identity.

## Keep evidence
- Export policy names, scope, durations, and coverage at each phase. "Retention is configured and
  validated" is only defensible if you can **show** the scope, the schedule it implements, and the
  pass/fail gates — that evidence is the deliverable records and auditors actually want.


---


# 8. Deliverables Summary — Exchange Lifecycle Policies: Microsoft Purview

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The two engines (Purview retention + Exchange MRM cleanup), why deletion is high-impact, precedence, and the Assess→Design→Configure→Pilot→Validate→Expand model (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (licensing, roles, both toolchain connections, the records schedule, holds, cleanup design, pilot ring, MFA cadence) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: assess, design with records/legal, configure retention + MRM scoped to the pilot, pilot (retain-first), validate, expand — each policy/tag/scope named, with rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates — including the blast-radius check that nothing outside scope is touched |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Pilot ring (mail-enabled security group) | `SG-DLCEXO-Pilot` |
| Purview retention policy (Exchange) | `DLCEXO-Retention-Exchange-Pilot` |
| Purview retention rule | `DLCEXO-Rule-Exchange-Keep7yrThenDelete` |
| MRM cleanup retention policy | `DLCEXO-MRM-Cleanup-Standard` |
| RPT — Deleted Items age-out | `DLCEXO-Tag-DeletedItems-30d` |
| RPT — Junk Email age-out | `DLCEXO-Tag-JunkEmail-30d` |
| DPT — move old mail to archive | `DLCEXO-Tag-Default-MoveToArchive-2yr` |

*(Durations are placeholders — use the values from your records schedule.)*

## PowerShell scripts
| Script | What it does |
|---|---|
| `DLCEXO-Discovery.ps1` | Read-only inventory of what already governs the mailboxes: Purview retention policies/rules scoped to Exchange, MRM retention tags/policies, the org default MRM policy, per-mailbox archive + litigation-hold status (Connect-IPPSSession + Connect-ExchangeOnline) |
| `DLCEXO-Set-Scope.ps1` | Records the pilot/expansion scope — pilot group, target retain duration, disposition, cleanup tags — as a read-only scope manifest to configure against; changes nothing |
| `DLCEXO-Configure.ps1` | Creates/updates the Purview retention policy + rule (Exchange) and the MRM cleanup policy + tags, scoped to the pilot; **defaults to `-WhatIf`**, applies only with `-Commit`; supports `-Disposition Retain` for retain-first; no secrets in code |
| `DLCEXO-Report.ps1` | Coverage/health report: which mailboxes are in the Purview policy scope, MRM policy assignment coverage, archive enablement, and mailbox-size signal (read-only) |
| `DLCEXO-Test-Readiness.ps1` | Consolidated PASS/GAP pilot gate: licensing/role signal, policy scope = pilot only, rule matches the approved schedule, MRM assigned to pilot, holds honored, and the blast-radius (no out-of-scope mailbox) check (read-only) |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
Mail governed on policy in Microsoft Purview — retained for as long as the schedule requires and no
longer, with Deleted Items/Junk aged out and old mail tiered to the archive — proven on a bounded pilot
before any destructive action reaches production, with the retention schedule, holds, and disposition
determinations left to the records, privacy, and legal owners who make them.
