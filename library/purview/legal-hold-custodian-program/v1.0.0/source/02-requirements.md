# 2. Requirements — Legal-Hold & Custodian Management Program (Microsoft Purview)

These are the **solution-specific** prerequisites for standing up a legal-hold and custodian-management
program in **Microsoft Purview eDiscovery** — cases, case holds, custodians, hold notifications, and
tracking. They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles,
S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and
a pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to implement
if missing**.

---

## 2.1 Licensing sufficient for the eDiscovery tier you will use — Standard vs Premium

- **Description:** The program uses two eDiscovery tiers, and they are licensed differently.
  **eDiscovery (Standard)** — cases and **case holds** (`CaseHoldPolicy` + `CaseHoldRule`) — is broadly
  available at **Microsoft 365 E3** (Exchange Online Plan 2 / SharePoint Online Plan 2). **eDiscovery
  (Premium)** — **custodian management**, **custodian data-source mapping**, and the **hold-notice
  (communications) / acknowledgment / reminder / escalation** workflow — requires **Microsoft 365 E5**, the
  **E5 Compliance** add-on, or the **E5 eDiscovery & Audit** add-on. Per-custodian Premium licensing applies
  to each user placed under custodian management. This extends GR-#1 with the eDiscovery-specific plan detail.
- **Why required:** The custodian program's defining features — mapped data sources and the tracked hold
  notice — are **Premium-only**. On an E3-only tenant you can still run **case holds** (the preservation
  floor), but not custodians or communications; designing for a feature the tenant is not licensed for is the
  most common early failure.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons (E3 / E5 / E5
  Compliance / E5 eDiscovery & Audit). In the **Purview portal → eDiscovery**, confirm whether the
  **Premium** experience (Custodians / Data sources, Communications) is present, not just **Standard**.
  **Flag "verify your licensing/tenant"** — tiers and the unified-eDiscovery rollout evolve.
- **How to implement if missing:** Acquire/assign the Premium licensing (and per-custodian licenses) before
  building the custodian/communications layer; on E3, scope the program to **case holds** and operate the
  notice workflow manually until Premium is licensed.

## 2.2 eDiscovery least-privilege role-group membership

- **Description:** eDiscovery in Purview is gated by **role groups**, not general compliance roles.
  **eDiscovery Manager** — create and manage **your own** cases, holds, and (Premium) custodians/
  communications; **eDiscovery Administrator** — a member of the eDiscovery Manager group who can additionally
  **see and manage all cases** in the tenant (the program owner); **Reviewer** and **Compliance Data
  Administrator** for narrower read/analysis roles. The underlying roles (Case Management, Hold, Custodian,
  Communication, Review, Search And Purge, Export) are assigned **through** these groups. Global Administrator
  only where genuinely required. Extends GR-#2.
- **Why required:** A user without eDiscovery role-group membership cannot see the eDiscovery node at all; a
  plain eDiscovery Manager sees only cases they are a member of. Running a tenant-wide **program** (many
  matters, oversight, reporting) needs at least one **eDiscovery Administrator**, with least-privilege
  Managers per matter — and separation keeps the blast radius small on a preservation-critical control.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions (Microsoft Purview
  roles)** → confirm **eDiscovery Manager / eDiscovery Administrator** membership; or
  `Get-eDiscoveryCaseAdmin` / `Get-RoleGroupMember 'eDiscovery Manager'` in S&C PowerShell.
- **How to implement if missing:** Assign the least-privilege eDiscovery role group under change control —
  one or more **eDiscovery Administrators** as program owners, **eDiscovery Managers** scoped per matter;
  separate the person who *places* holds from the person who *authorizes release* where possible.

## 2.3 In-scope custodians, data sources, and workloads identified (by legal, implemented here)

- **Description:** A per-matter list of the **custodians** (people of interest) and the **data sources** to
  preserve — primary **mailbox** and **OneDrive**, plus **associated** Teams/Microsoft 365 Groups and any
  **additional** mailboxes/SharePoint sites — and **non-custodial** locations (shared mailboxes, departmental
  sites, records repositories) that must be held but belong to no single person. Extends GR-#4.
- **Why required:** A case hold and a custodian mapping key off *specific* locations; a missed custodian or an
  un-mapped associated site is content that is **not preserved** — a spoliation exposure, not a cosmetic gap.
  Non-custodial data (a team SharePoint site, a shared mailbox) is invisible to custodian mapping and must be
  held explicitly.
- **How to verify:** Confirm the custodian list and each custodian's mailbox/OneDrive resolve
  (`Get-Recipient`); confirm associated Teams/Groups and additional sites with the custodian and IT; confirm
  the non-custodial locations with the data owners. **The *who* and *what-scope* are legal's determination**
  — this solution implements and evidences them.
- **How to implement if missing:** Capture the custodian/data-source/non-custodial map from legal before
  configuring; the Discovery and Set-Scope scripts inventory what a hold currently covers so gaps are visible.

## 2.4 Preservation scope and hold-notice content defined by legal (drafted by legal, configured here)

- **Description:** For each matter, legal defines: the **preservation scope** — **preserve everything** vs a
  **query-based** hold (a KQL condition and/or date range that preserves only matter-relevant content); the
  **hold-notice text** (Premium communications) — issuance, reminder, escalation, and release wording; and the
  **acknowledgment cadence** (reminder interval, escalation trigger for non-responders). Extends GR-#5.
- **Why required:** The hold rule's `ContentMatchQuery`/date range and the notice's legal sufficiency are
  **legal determinations**. A query-based hold that is too narrow silently fails to preserve responsive
  content; a notice that is legally insufficient undermines defensibility. The program **configures** these
  values — it does not author them.
- **How to verify:** Confirm the preservation scope (everything vs query/date), the four notice texts, and the
  cadence with eDiscovery counsel; confirm any query with a small **statistics** run before it becomes a hold.
- **How to implement if missing:** Have legal supply the scope and notice content; default to
  **preserve-everything** (the safest floor) where a query has not been authorized, never the reverse.

## 2.5 A named release authority and change-control path (holds are preservation-critical)

- **Description:** A named **release authority** (the legal/eDiscovery role empowered to authorize lifting a
  hold) and a **change-control record** for every hold placement, scope change, and release. Because releasing
  a hold **deletes the preservation** and cannot be undone for content purged afterward, release must be a
  deliberate, signed-off, two-party action — **never** scripted automatically. Extends GR-#6.
- **Why required:** The single highest-risk action in this program is **releasing a hold that should have
  stayed**. A named authority, a written authorization, and a change record are what make placement and
  release defensible — and what this solution's tooling deliberately **will not** automate (no script in this
  pack releases a hold).
- **How to verify:** Confirm who may authorize release, the written-authorization format, and that the release
  step is outside the automation (portal + sign-off only).
- **How to implement if missing:** Name the release authority and stand up the change log before any hold is
  placed; wire the sign-off into the operating procedure, not the scripts.

## 2.6 Audit logging enabled and a pilot matter defined

- **Description:** Tenant **unified audit logging** enabled (so hold placement, notice, and access events are
  recorded and reportable), and a **pilot matter** — a bounded case with **fabricated test custodians** — on
  which the mechanics are proven before the program runs on a real matter (`Scope – Hold-Pilot`, the case
  `Legal Hold Case – Contoso-Matter-001 – Pilot`). Extends GR-#6.
- **Why required:** Defensibility rests on **evidence**, and the evidence lives in the audit log and the case
  history — if auditing is off, the tracking report has nothing to read. The pilot proves the hold
  distributes, the notice issues, and acknowledgment tracks **before** a real matter's preservation depends
  on it — the house model's *pilot-first* discipline applied to a control where getting it wrong is a legal,
  not a technical, cost.
- **How to verify:** `Get-AdminAuditLogConfig`/audit-log search confirms auditing is on; confirm the pilot
  case name, the fabricated test custodians, and the change window to expand to real matters.
- **How to implement if missing:** Enable unified audit logging; define the pilot matter and test custodians
  (never real people) before validating.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | eDiscovery licensing — Standard (E3) vs Premium (E5/E5 Compliance/E5 eDiscovery & Audit); verify | Custodians + communications available (Premium) |
| 2.2 | eDiscovery role-group membership (Manager / Administrator) | Case, hold, custodian, communication access |
| 2.3 | In-scope custodians, data sources, non-custodial locations | Nothing responsive left un-held |
| 2.4 | Preservation scope + hold-notice content (from legal) | Hold rule + notice configured to legal's intent |
| 2.5 | Named release authority + change control | Release is deliberate, signed, never scripted |
| 2.6 | Audit logging on + pilot matter with test custodians | Evidence captured; mechanics proven pilot-first |

> **Deferred to legal / eDiscovery counsel / records:** whether a duty to preserve has attached, *who* is a
> custodian, the *scope* of preservation, the legal sufficiency of a notice, and *when* a hold may be
> released. This solution provides the technical configuration and the evidence, not the determination —
> and it never releases a hold automatically.
