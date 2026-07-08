# 1. Solution Overview — Microsoft Purview Center of Excellence

## What this solution is
Microsoft Purview is broad — sensitivity and retention labels, data loss prevention (DLP), data
lifecycle and records management, insider risk, communication compliance, audit, eDiscovery, data
security posture management (DSPM), and data governance. Once a tenant has the *foundation* in place,
the next failure mode is **governance drift**: labels, DLP policies, and retention rules get created
ad hoc by whoever had the role that day, nobody owns them, none of them share a naming or lifecycle
standard, high-impact policies get flipped to *enforce* without ever running in **simulation/test**,
and six months later nobody can say which policy does what, who approved it, or when it was last
reviewed. That is a compliance gap and a data-risk exposure.

This solution institutionalizes Purview governance by standing up a **Purview Center of Excellence
(CoE)** — the operating model that governs every Purview capability from one place:

- A **governance board** — a named body with a charter, a RACI, and least-privilege membership mapped
  to built-in Purview role groups (compliance, information protection, records, insider risk,
  communication compliance, eDiscovery, audit) with **separation of duties** enforced.
- **Standards** — the house rules every Purview artifact must follow: a **naming convention**, a
  mandatory **owner + review cadence**, a **simulation/test-first** rule for every high-impact policy,
  a **change-control** rule (every change via intake, versioned, reversible), and a
  **separation-of-duties** rule for HR/legal-sensitive capabilities.
- **Intake** — a single request-to-production workflow (Request → Triage → Design → Pilot in
  simulation/test → Validate → Board approval → Enforce → Register) so nothing lands in the tenant
  without an owner, a standard-conformant name, recorded simulation evidence, and board sign-off.
- **Lifecycle** — a periodic review cadence, **drift detection** (current configuration compared to
  the registered standards baseline), versioning, and a decommission path for orphaned or unowned
  artifacts — so the estate stays understood and defensible over time.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com), the **Microsoft 365
admin center**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), Exchange Online
PowerShell (for audit config), and **Microsoft Graph** — no third-party tooling. The five PowerShell
scripts inventory every governed artifact, apply the CoE role model and standards tags (`-WhatIf`
first), validate governance gates, and produce the governance register/scorecard.

> **This is the governance operating model, not the capability build-outs.** The CoE governs the
> *labels, DLP policies, retention/records rules, insider-risk and communication-compliance policies,
> eDiscovery cases, and DSPM* that other Purview solutions configure. It does not author those
> policies' contents or make the regulatory/records/legal determinations behind them — those are
> deferred to the organization's compliance, records, privacy, and legal functions. The CoE supplies
> the board, the standards, the intake gate, the lifecycle cadence, and the evidence.

## Why this matters
- **Ungoverned Purview drifts into risk.** Every unowned DLP or retention policy is a change nobody
  can explain and nobody dares touch. A CoE gives every artifact an owner, a standard-conformant name,
  and a review date — so the estate stays auditable.
- **Simulation-first is the single most valuable house rule.** DLP, auto-labeling, retention, and
  insider-risk policies can block mail, encrypt files, delete content, and flag employees. Making
  **simulation/test mode a mandatory intake gate** — with recorded evidence before any policy is
  enforced — prevents the most damaging Purview incidents.
- **Separation of duties is compliance-critical.** Insider risk, communication compliance, and
  eDiscovery expose sensitive employee content. The CoE keeps those role groups separate, membership
  minimal and named, and the *determination* of who may hold them deferred to HR, privacy, and legal.
- **A register turns Purview into a defensible program.** When an auditor asks "what governs your
  sensitive data, who owns it, and when was it last reviewed?", the governance register answers in one
  export instead of a scramble.

## How it works
1. **Assess.** Read the tenant's compliance licensing (which capabilities the CoE can actually
   govern), the existing role-group posture, and a full inventory of Purview artifacts — labels, label
   policies, DLP policies, retention policies/labels, auto-labeling, and (where licensed and readable)
   communication-compliance and audit-retention policies. Read-only, no changes.
2. **Design.** Author the **CoE charter and board RACI**, the **standards** (naming, ownership, review
   cadence, simulation-first, change-control, separation of duties), and the **intake workflow**. Map
   board functions to least-privilege built-in role groups.
3. **Configure.** Create/populate the CoE governance role groups (least-privilege, from a matrix),
   register the standards baseline, and optionally stamp each artifact with an ownership/standard tag —
   role and tag changes applied with a **`-WhatIf` preview first**.
4. **Pilot.** Run the intake workflow end-to-end on a **pilot artifact** in **simulation/test mode**
   (for example, one DLP or auto-labeling policy taken Request → simulate → validate → board approval)
   to prove the gate works before governing the whole estate.
5. **Validate.** Confirm every governance gate: naming conformance, every artifact has an owner and a
   review date, no high-impact policy is enforced without recorded simulation evidence, separation of
   duties intact, and the register reconciles to the live tenant.
6. **Expand.** Bring the full artifact estate under the register and the review cadence; run the CoE as
   a standing operating rhythm (intake for new requests, periodic lifecycle reviews, drift detection).

## The CoE governance board (least-privilege, separated)
Map each board function to the **built-in Purview/compliance role group** — add named members; create
custom scoped role groups only where tighter scoping is required.

| Board function | Built-in role group | Separation |
|---|---|---|
| Chair / compliance administration | **Compliance Administrator** | Governs; does not hold investigative roles |
| Information protection (labels/DLP standards owner) | **Information Protection Admin** | — |
| Classification data | **Compliance Data Administrator** | — |
| Records & retention standards owner | **Records Management** | Determinations deferred to records/legal |
| Insider risk representative | **Insider Risk Management** | **Separated** — HR/security; minimal, named |
| Communication compliance representative | **Communication Compliance** | **Separated** — HR/compliance; minimal, named |
| eDiscovery / legal representative | **eDiscovery Manager** | **Separated** — legal/investigations |
| Audit representative | **Audit Manager** / **Audit Reader** | Read-only where sufficient |

> **Separation of duties is a standard, not a nicety.** The chair governs the operating model but does
> not hold insider-risk, communication-compliance, or eDiscovery roles. Those seats are separate,
> minimal, named, and — for insider risk and communication compliance — privacy-by-design
> (pseudonymization where the capability supports it) is applied in that capability's own solution. The
> CoE governs *how* these capabilities are stood up and reviewed; **who may hold the roles, and every
> regulatory/records/legal determination, is deferred to HR, privacy, records, and legal.**

## The CoE standards (the house rules)
| Standard | Rule |
|---|---|
| **Naming** | Every governed artifact follows `<Purpose> – <Capability> – <State>` (e.g. `Financial Data – DLP – Simulation`). Names carry purpose and state at a glance. |
| **Ownership** | Every artifact has a **named owner** and a **review cadence** (default quarterly), recorded in the register (and, where the object supports it, stamped in its `Comment`). |
| **Simulation-first** | No DLP, auto-labeling, retention, or insider-risk policy is enforced without first running in **simulation/test/disabled** mode with recorded pass evidence. |
| **Change control** | Every change enters via **intake**, is **versioned**, and has a documented **rollback**. No out-of-band edits. |
| **Separation of duties** | Insider-risk, communication-compliance, and eDiscovery roles are separate from governance administration; membership minimal and named. |
| **Evidence** | Every enforced policy has an evidence record (simulation results, board approval, register entry) — the audit answer. |

## The intake workflow (request to production)
`Request → Triage (board) → Design (standard-conformant name + owner) → Pilot in simulation/test →
Validate (pass/fail gates) → Board approval → Enforce → Register (owner + review date)`. Every stage
has an artifact (`Purview CoE Intake – Request`, simulation evidence, `Purview CoE Register –
Governed`); nothing reaches *enforce* without passing simulation and board sign-off.

## The lifecycle cadence
A standing rhythm: **periodic review** (default quarterly) of every registered artifact against the
standards; **drift detection** (compare current tenant configuration to the registered standards
baseline and flag new/changed/orphaned artifacts); **versioning** of every change; and a
**decommission** path for orphaned or unowned policies (identified → owner-confirmed → disabled →
removed under change control).

## What you can control
- The CoE board membership (least-privilege, named, separated) and the role-group mapping.
- The standards themselves (naming pattern, review cadence, which capabilities are in remit — bounded
  by licensing).
- The intake workflow gates and who approves.
- The lifecycle cadence (review frequency, drift-detection schedule, decommission policy).
- The pilot artifact used to prove the intake gate before governing the full estate.

## Limitations (be honest with buyers)
- **The CoE governs; it does not determine.** Retention schedules, records file plans, legal holds,
  insider-risk and communication-compliance case actions, and regulatory applicability are **deferred**
  to compliance, records, privacy, and legal. The CoE provides the method, the gate, and the evidence.
- **Purview is heavily licensing-gated.** Advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, and DSPM require **Microsoft 365 E5** or the **E5 Compliance** add-on;
  some capabilities are in preview. The CoE governs what your plan unlocks — **verify availability
  against your own tenant and plan.**
- **The portal is evolving, and some capabilities have limited PowerShell.** Microsoft is actively
  changing the Purview portal and moving parts of role management to a unified Purview RBAC model.
  Insider Risk (and some communication-compliance) management is primarily **portal-managed** with
  limited/evolving PowerShell surface. Portal paths and cmdlets are cited as of authoring and flagged
  **"verify in your tenant"**; the scripts guard for cmdlet availability and never invent cmdlets.
- **The CoE does not author policy contents.** It governs naming, ownership, lifecycle, and the
  simulation-first gate — the *contents* of each label, DLP rule, and retention schedule are the
  subject of the capability-specific Purview solutions and the stakeholders' determinations.

## Naming convention (used in every doc and script)
Governance artifacts this solution creates or captures follow `<Purpose> – CoE – <Stage>`; governed
Purview artifacts follow the CoE **naming standard** `<Purpose> – <Capability> – <State>`.

| Artifact | Name |
|---|---|
| CoE charter + board RACI matrix | `Purview CoE Charter – Board` |
| Standards baseline (the house rules, captured) | `Purview CoE Standards – Baseline` |
| Governed-artifact inventory / register | `Purview CoE Register – Governed` |
| Intake request record | `Purview CoE Intake – Request` |
| Lifecycle / drift review log | `Purview CoE Lifecycle – Review` |
| Governance scorecard | `Purview CoE Scorecard – Report` |
| CoE pilot artifact (simulation) | `Purview CoE Pilot – Stage1` |

## The standard deployment model
> Assess the estate → design the board, standards, and intake → configure the role model and standards
> (pilot-first) → pilot the intake gate in simulation → validate every governance gate → expand to the
> full estate and run the lifecycle cadence. Pattern: **Assess → Design → Configure → Pilot → Validate
> → Expand.**
