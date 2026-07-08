# 1. Solution Overview — Legal-Hold & Custodian Management Program (Microsoft Purview)

## What this solution is
When a matter (litigation, investigation, regulatory inquiry) arises, the organization has a duty to
**preserve** the potentially relevant content of the people involved — and to be able to **prove** it
did. In Microsoft Purview that duty is met with **eDiscovery legal holds** and, for larger matters,
**custodian management**: the people of interest are identified as **custodians**, their data sources
(mailbox, OneDrive, the Teams and SharePoint content they touch) are placed on **hold** so nothing is
purged or edited away, each custodian is issued a **legal-hold notice** they must **acknowledge**, and
the whole thing is **tracked** — who is on hold, who has acknowledged, who has been reminded or
escalated, and when a hold is released. This solution is a repeatable, pilot-first method to stand up
that **legal-hold and custodian-management program** in Microsoft Purview eDiscovery — holds,
custodian data sources, hold notifications, acknowledgment tracking, and a defensible hold register —
so preservation is done consistently, evidenced, and defensible instead of ad hoc.

It delivers the **operational program**: the case + hold objects, the custodian and communication
workflow, the tracking and reporting, and the pilot → validate → expand discipline. It is the
program you run every time a matter starts.

## What this is NOT — the deferred boundary and the MSEDISC boundary
- **Legal determinations are deferred to legal.** *Whether* a duty to preserve has attached, *who* is a
  custodian, *what* the scope of a hold is, *when* a hold may be released, and the legal sufficiency of
  a hold notice are **legal/eDiscovery-counsel determinations**. This solution provides the **technical
  method and the evidence** — it configures the holds legal scopes, issues the notices legal drafts,
  and produces the tracking — it does **not** make the preservation decision or judge defensibility.
- **This is not the eDiscovery *readiness assessment* (MSEDISC).** The readiness-assessment product
  assesses whether the tenant is *ready* to run eDiscovery — licensing, roles, data-source coverage,
  search/export posture, the maturity gaps. **This** product is the running **hold + custodian program**
  that operates once you are ready. Where this solution needs the readiness picture (is Premium
  licensed? are roles assigned? are all workloads discoverable?), it **references** MSEDISC rather than
  re-performing the assessment.
- **Collection, review, analytics, and export are not in scope here.** Building review sets, running
  searches over held content, applying analytics/predictive coding, and producing/exporting are the
  *downstream* eDiscovery phases. This program stops at **defensible preservation** (hold + notice +
  tracking); it hands validated, preserved custodians to whatever review/production process legal runs.
- **Retention/records lifecycle is a different program.** Retention policies and records labels (keep
  and dispose on a *schedule*) are the province of the data-lifecycle/records product. Legal hold is
  **matter-driven preservation** that *overrides* deletion for the duration of the matter — it is
  referenced against, not rebuilt.

## The core distinction — hold types in Microsoft Purview
The single most important design decision is **which preservation mechanism** a matter uses, because
they differ in scope, evidence, and licensing:

- An **eDiscovery case hold** (a **CaseHoldPolicy** + **CaseHoldRule** created inside an eDiscovery
  case) preserves the **specific locations** named on it — chosen mailboxes, OneDrive accounts,
  SharePoint sites, and Microsoft 365 Group/Teams locations — and can be **query-based** (preserve only
  content matching keywords/date range) or **preserve-everything**. It is **matter-scoped**, auditable,
  and the natural unit of a legal hold. This is the primary mechanism this program uses.
- **Custodian-based holds** are an **eDiscovery (Premium)** capability: you add a **custodian** (a
  person of interest), Purview **maps their data sources** (primary mailbox and OneDrive, plus
  associated Teams/Groups and any additional mailboxes/sites you attach), and placing the custodian on
  hold creates the underlying case holds automatically — *and* unlocks the **communications**
  (hold-notice) workflow with acknowledgment tracking, reminders, and escalations. This is what turns a
  hold into a *managed custodian program*.
- **Litigation Hold** (`Set-Mailbox -LitigationHoldEnabled`) is a **mailbox-level** hold in Exchange
  Online (Plan 2). It preserves a single mailbox (and its archive) for a duration, independent of any
  case. It is a useful **belt-and-suspenders** hold for a small matter or a departing custodian, but it
  is **not matter-scoped, has no notice/acknowledgment workflow, and only covers the mailbox** — so it
  complements, but does not replace, case/custodian holds.
- **Retention policies with preservation** also keep content, but they are *schedule*-driven, not
  matter-driven, and carry no custodian/notice workflow — referenced, not used as a legal hold here.

The reference design uses **eDiscovery case holds** as the preservation floor and, where Premium is
licensed, **custodian management + communications** as the managed layer, with **Litigation Hold** as
an optional mailbox-level reinforcement.

## Why this matters
- **A preservation duty that lives in an email is not preservation.** A case hold in Microsoft Purview
  is enforcement the platform applies — held content cannot be permanently purged even if a user
  deletes it or a retention policy would otherwise delete it — with an audit trail the platform keeps.
- **Defensibility is about *proof*, not just the hold.** Courts and regulators expect evidence that a
  hold was issued, to whom, that custodians *acknowledged* it, that non-responders were *reminded and
  escalated*, and that holds were *released* deliberately. The custodian-communications workflow and
  the hold register this program produces are that proof.
- **Spoliation is expensive and often irreversible.** If a custodian mailbox is purged, a leaver's
  data is deleted, or a hold is missed, the content is gone — and the sanction lands on the
  organization. A consistent, tracked program is the control that prevents it.
- **Ad-hoc holds do not scale.** One matter with five custodians can be run by hand; a portfolio of
  matters with overlapping custodians cannot. Named, standardized case/hold/notice objects, a tracked
  register, and scripts make it repeatable and auditable.
- **Doing it pilot-first** — proving the hold, the notice, and the tracking on a bounded pilot matter
  before it is the live practice — avoids the failure mode of a mis-scoped or non-distributing hold on
  a real matter, where the cost of getting it wrong is legal, not just technical.

## How it works (the program)
1. **Create the matter case.** In Microsoft Purview → **eDiscovery**, an eDiscovery case is created for
   the matter (`New-ComplianceCase`, or the portal). The case is the container for all holds,
   custodians, and communications for that matter.
2. **Add custodians and map their data sources** *(Premium)*. Each person of interest is added as a
   **custodian**; Purview resolves their **primary mailbox and OneDrive** and lets you attach
   **associated** Teams/Groups and **additional** mailboxes/sites. In the newer unified experience
   these appear under **Data sources**; verify the exact tab name in your tenant.
3. **Place the hold.** Placing custodians on hold (Premium) or creating a **case hold policy + rule**
   (Standard) preserves the mapped locations. The rule can be **query-based** (a KQL condition and/or
   date range — preserve only matter-relevant content) or **preserve-everything**. Optionally enable
   **Litigation Hold** on the custodian mailboxes as reinforcement.
4. **Issue the hold notice** *(Premium communications)*. A **hold notification** legal drafts is issued
   to the custodians as a **communication**; it carries the preservation instructions and an
   **acknowledgment** link. Purview supports **issuance**, **re-issuance/reminder**, **escalation** (to
   non-responders), and **release** notices, on a schedule you set.
5. **Track acknowledgment.** Each custodians **acknowledgment status** (acknowledged / not yet /
   reminded / escalated) is tracked in the case; non-responders are reminded and escalated per the
   configured cadence. This is the evidence that the notice reached the custodian.
6. **Validate the hold is effective.** Confirm the case hold policys **distribution status is Success**
   across all locations, every custodian is covered, and (where used) Litigation Hold shows enabled —
   with explicit pass/fail gates before the program is trusted.
7. **Maintain the register.** A **custodian hold register** — custodians, their data sources, hold
   status, notice/acknowledgment status, dates — is exported and kept current as the defensible record
   of the matter.
8. **Release deliberately.** When legal authorizes release, the custodian is released (hold removed), a
   **release notice** is sent, and the release is recorded in the register. Release is a legal
   decision — the program executes and evidences it, it does not decide it.
9. The whole thing runs through the house model — **Assess → Design → Configure → Pilot → Validate →
   Expand** — proving the mechanics on a **pilot matter** before it becomes the live practice.

## The reference design
- **Inputs (from legal/eDiscovery counsel):** the matter, the custodian list, the preservation scope
  (all content vs a query/date range), the hold-notice text and cadence (reminder/escalation
  intervals), and the release authority. This solution **implements** these; it does not author them.
- **Case (the container):** one eDiscovery case per matter — `Legal Hold Case – <Matter> – Pilot`.
- **Holds (the floor):** a case hold policy + rule per matter — `Hold Policy – <Matter> – Pilot` /
  `Hold Rule – <Matter> – Pilot` — query-based where legal scopes it, preserve-everything where they do
  not.
- **Custodians (the managed layer, Premium):** custodians added to the case with mapped data sources,
  grouped conceptually as `Custodians – <Matter> – Pilot`.
- **Communications (Premium):** `Hold Notice – <Matter> – Issuance`, `– Reminder`, `– Escalation`,
  `– Release`, with a defined acknowledgment cadence.
- **Reinforcement (optional):** Litigation Hold enabled on custodian mailboxes for the matter duration.
- **Tracking:** `Custodian Hold Register – <Matter> – Report`, exported and kept current.
- **Scope/stage:** a **pilot matter** (`Scope – Hold-Pilot`) validated before the program is adopted as
  the live practice for real matters.

## What you can control
- Which **mechanism** each matter uses — case hold (Standard) vs custodian management + communications
  (Premium), with or without Litigation Hold reinforcement.
- Whether a hold is **query-based** (preserve only content matching a KQL/date scope legal defines) or
  **preserve-everything**.
- Which **data sources** each custodian contributes — primary mailbox/OneDrive plus associated
  Teams/Groups and additional mailboxes/sites.
- The **notice cadence** — issuance, reminder interval, escalation to non-responders, and release.
- The **pilot scope**, the pass/fail gates, and the rollback — before the program is the live practice.

## Limitations (be honest with buyers)
- **Custodian management and communications are Premium (E5-class).** Adding custodians, mapping their
  data sources, and the **hold-notice/acknowledgment/reminder/escalation** workflow require
  **eDiscovery (Premium)** — generally **Microsoft 365 E5**, the **E5 Compliance** add-on, or the **E5
  eDiscovery & Audit** add-on. **eDiscovery (Standard)** case holds are available at **E3**, but
  *without* custodians or communications. **Verify what your tenant is licensed for** before designing
  the program.
- **The eDiscovery portal is actively changing.** Microsoft is consolidating the classic **eDiscovery
  (Standard)** and **(Premium)** experiences into a **new unified eDiscovery** experience in the Purview
  portal, and some tab names/paths (e.g. *Custodians* → *Data sources*) differ between them. This
  solution names the objects and the cmdlets, and **flags "verify the exact path in your tenant"**
  rather than asserting a single UI that may have moved.
- **Holds are not instant.** Placing a hold and distributing it across locations runs on service
  timers; **distribution status** can take time (often minutes to hours, and longer for many
  locations) to reach **Success** — do not judge a hold in its first minutes; validate distribution.
- **A hold does not stop a user editing or deleting *from their view*** — it stops the content from
  being **permanently purged**. Deleted held items are recoverable (they move to a preservation
  location); the hold preserves, it does not lock the item read-only the way a record label does.
- **Notice acknowledgment is a portal-tracked workflow.** Issuance, acknowledgment, reminders, and
  escalation are managed in the Purview eDiscovery **Communications** area; the provided scripts
  **inventory and report** holds, custodians, and (where the API exposes it) status, but the notice
  workflow itself is operated in the portal — the scripts do not send notices.
- **Not everything is exposed to PowerShell/Graph equally.** Case holds are well-covered by Security &
  Compliance PowerShell (`*-CaseHoldPolicy/Rule`); custodians and holds are readable via the
  **Microsoft Graph eDiscovery** APIs (some in **beta**); the **communications/acknowledgment** detail
  is primarily a portal surface. The scripts use only documented cmdlets/endpoints and **flag** where a
  step is portal-only — no invented cmdlets.
- **Commercial vs Government cloud paths differ.** Portal URLs, endpoints, and some feature availability
  differ in **GCC / GCC High / DoD** (e.g. `*.office365.us`, `Connect-IPPSSession -ConnectionUri`,
  Graph national-cloud endpoints) — **verify the path and feature in your cloud.**

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Matter/Scope> – <Stage>` and reused
verbatim across the docs, scripts, and the Purview admin surfaces (`Contoso-Matter-001` is used as the
placeholder matter throughout):

| Artifact | Name |
|---|---|
| eDiscovery case (the matter) | `Legal Hold Case – Contoso-Matter-001 – Pilot` |
| Case hold policy | `Hold Policy – Contoso-Matter-001 – Pilot` |
| Case hold rule | `Hold Rule – Contoso-Matter-001 – Pilot` |
| Custodian set (conceptual grouping) | `Custodians – Contoso-Matter-001 – Pilot` |
| Hold notice — issuance | `Hold Notice – Contoso-Matter-001 – Issuance` |
| Hold notice — reminder | `Hold Notice – Contoso-Matter-001 – Reminder` |
| Hold notice — escalation | `Hold Notice – Contoso-Matter-001 – Escalation` |
| Hold notice — release | `Hold Notice – Contoso-Matter-001 – Release` |
| Pilot scope | `Scope – Hold-Pilot` |
| Hold register (tracking export) | `Custodian Hold Register – Contoso-Matter-001 – Report` |
| Preservation posture (discovery export) | `Hold Posture – Tenant – Discovery` |

When the pilot passes and the program goes live on real matters, mint the production equivalents by
swapping the `– Pilot` stage for the real matter name/number (e.g.
`Hold Policy – <RealMatter> – Live`) — never edit a validated pilot artifact in place, and never reuse
a pilot case for a real matter.

## The standard deployment model
> **Assess** the tenants preservation posture and eDiscovery readiness (reference MSEDISC), and ingest
> the matter/custodian/scope inputs from legal → **Design** the case/hold/custodian/notice map →
> **Configure** the case, case hold policy + rule, custodians and data sources, and the notice cadence
> → **Pilot** on `Scope – Hold-Pilot` (a pilot matter with test custodians; holds created with
> `-WhatIf` reviewed first, then committed) → **Validate** distribution status, custodian coverage, and
> notice/acknowledgment against explicit pass/fail gates → **Expand** into the live matter practice with
> the production naming and change control.

Preservation is **high-stakes** — a missed custodian, a non-distributing hold, or a released hold that
should have stayed is a legal exposure, not just a technical one. Every real-matter action goes through
change control with the register updated, and nothing becomes the live practice until the gates in
Section 5 pass on the pilot. **Legal owns the determination; this program owns the execution and the
evidence.**
