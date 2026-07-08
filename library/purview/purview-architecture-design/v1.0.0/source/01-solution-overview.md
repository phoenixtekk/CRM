# 1. Solution Overview — Microsoft Purview Architecture & Design

## What this solution is
Microsoft Purview is not one product — it is a **suite** of compliance and data-governance capabilities
(sensitivity & retention labels, DLP, data lifecycle & records, insider risk, communication compliance,
audit, data security posture management, and data governance) that all share the same **tenant, roles,
scopes, and naming**. Turn them on ad hoc — a label here, a DLP policy there — and you get **sprawl**:
overlapping policies, over-privileged administrators, inconsistent names, no scoping discipline, and no
way to say what is deployed or why. That is a compliance gap and a data-risk exposure at the same time.

This solution delivers the **architecture and design that comes *before* you scale Purview**: a
**capability map** (which Purview capabilities are in scope, mapped to the licensing that gates them and
the phase they belong to), an **RBAC model** (least-privilege role groups with separation of duties),
a **scoping strategy** (adaptive scopes, administrative units, pilot rings, and the workloads/data
sources in scope), a **naming standard** every future policy/label/object follows, and a **phased
roadmap** that sequences the capabilities so each phase builds on the last. It is delivered with the
house model — **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand** — using only
the **Microsoft Purview portal**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), and
**Microsoft Graph**. No third-party tooling.

> **This is the design layer, not the individual capability build.** This solution produces the
> **reference architecture** — the capability map, RBAC model, scoping plan, naming standard, and phase
> roadmap — and stands up the **foundation guardrails** (least-privilege roles, scopes, naming, a pilot
> ring). Building out each capability (a specific DLP policy, a label taxonomy, a retention schedule, an
> insider-risk policy) is done in that capability's own solution, **against this design**. Every
> high-impact policy that design instantiates is **piloted in simulation/test first** under its own
> change control — this solution defines that as the standing pattern.

## Why this matters
- **Design once, or refactor forever.** Role groups, scopes, and naming set early are cheap; changing
  them after fifty policies reference them is expensive and risky. A reference architecture makes the
  expensive decisions **once, deliberately**, so every later capability slots in cleanly.
- **Least privilege has to be architected, not bolted on.** Purview's power is fine-grained role
  groups; that only protects you if administrators are **separated by function** (information protection
  ≠ insider risk ≠ eDiscovery ≠ records) from day one. Retrofitting separation of duties after everyone
  is a Compliance Administrator is painful and audit-visible.
- **Scoping is what keeps a pilot a pilot.** Adaptive scopes, administrative units, and a named pilot
  ring are what let you validate a high-impact policy on **a defined population** before it touches the
  tenant. Without a scoping design, "pilot" means "hope."
- **Licensing gates the map.** Most Purview capabilities require **E5 / E5 Compliance** (some are in
  preview). A capability map that ties each capability to the plan that enables it prevents designing a
  phase around a feature you cannot license — the most common Purview planning failure.
- **The determinations are not technical.** *Which* regulations apply, *what* the retention schedule is,
  *whether* insider-risk monitoring is lawful, *what* the records file plan contains — these are
  **compliance / records / privacy / legal** determinations. This solution designs the technical
  architecture that will carry them; it does not make them.

## How it works
1. **Baseline the tenant (Assess).** Inventory what already exists — licensing/SKUs and which
   capabilities they gate, current role groups and their membership, existing labels/DLP/retention
   policies and scopes, and the audit state — as the `PA Design Baseline – Tenant – Assess` starting
   point (`PURVARCH-Discovery.ps1`, read-only).
2. **Map the capabilities to licensing and phases (Assess → Design).** With stakeholders, decide which
   Purview capabilities are **in scope**, confirm each is **licensable** on your plan, and assign each
   to a **phase** — the `PA Capability Map – Tenant – Design` and `PA Phase Roadmap – Program – Design`.
3. **Design the RBAC model (Design).** Define the least-privilege **role groups** per capability with
   **separation of duties** (who administers vs analyzes vs investigates vs reads), the `PA RBAC Model –
   Tenant – Design`, and identify conflicts (`PA RBAC SoD – Conflicts`).
4. **Design the scoping strategy (Design).** Decide **adaptive scopes** vs static scopes, whether
   **administrative units** are used, the in-scope **workloads/data sources**, and the named **pilot
   ring** — the `PA Scoping Plan – Tenant – Design`, with the pilot group `SG-PA-Pilot` and example
   adaptive scope `AS-PA-Pilot`.
5. **Set the naming standard (Design).** Adopt the `<Purpose> – <Scope> – <Stage>` convention every
   future label/policy/scope/object follows — the `PA Naming Standard – Tenant – Design` — so the estate
   stays legible as it grows.
6. **Stand up the foundation guardrails (Configure — guardrails).** Apply the designed **role-group
   membership** (least privilege, separated) and scaffold the **pilot ring / adaptive scope** — the only
   things this solution *configures*; every capability policy is built later, against the design, in
   simulation first (`PURVARCH-Configuration.ps1`, `PURVARCH-Set-Scope.ps1`, `-WhatIf` default).
7. **Validate and hand off (Validate → Expand).** Confirm the design is conformant — capabilities
   licensable, roles separated, scopes in place, naming applied — with `PURVARCH-Validation.ps1` and the
   `PA Design Posture – Report` (`PURVARCH-Report.ps1`), then execute the roadmap phase by phase, each
   capability piloted in simulation/test against this architecture.

## The five design artifacts (what this solution produces)
- **Capability map** — every in-scope Purview capability, the **licensing** that gates it (E3 / E5 / E5
  Compliance / preview / add-on), its **phase**, its **owner**, and its status (in scope / deferred —
  not licensed / out of scope). It is the single answer to "what are we deploying, and can we?"
- **RBAC model** — the **role groups** per capability, mapped to a **least-privilege, separated** set of
  administrator / analyst / investigator / reader duties, plus the separation-of-duties rules and any
  conflicts. This is the auditable access design.
- **Scoping plan** — **adaptive vs static** scopes, **administrative unit** use, the in-scope
  **workloads and data sources**, and the **pilot ring** — the mechanism that keeps every high-impact
  policy contained until it is validated.
- **Naming standard** — the `<Purpose> – <Scope> – <Stage>` convention (e.g. `DLP-PII-Sim`,
  `Label-Confidential-Prod`, `AS-Finance-Prod`) so the estate is legible and searchable as it scales.
- **Phase roadmap** — the sequence (Foundation → Know → Protect → Prevent loss → Govern → Advanced),
  what each phase delivers, its entry/exit gates, and its dependency on the phase before it.

## The phase model (the reference architecture arc)
| Phase | Theme | Representative capabilities (all built later, in simulation first) |
|---|---|---|
| **0 — Foundation & Governance** | Roles, scopes, naming, audit | Purview RBAC role groups, adaptive scopes / administrative units, unified audit log, naming standard |
| **1 — Know your data** | Classification | Sensitive information types (SITs), trainable classifiers, Content/Activity explorer, data classification |
| **2 — Protect your data** | Labeling | Sensitivity labels + label policies, encryption, container/site labeling, auto-labeling |
| **3 — Prevent data loss** | DLP | DLP across Exchange/SharePoint/OneDrive/Teams and **endpoint** — **simulation-first** |
| **4 — Govern & retain** | Lifecycle & records | Retention labels/policies, records management, data lifecycle, disposition |
| **5 — Manage risk (advanced)** | Insider & AI | Insider Risk Management, Communication Compliance, Adaptive Protection, DSPM, Copilot/AI data governance |
> Phases are **sequenced, not simultaneous** — each depends on the guardrails and classification the
> earlier phases establish. Capability availability per phase is **licensing-gated and evolving**;
> the capability map confirms each is licensable **before** the phase is planned around it. **Verify
> availability and paths against your own licensing and tenant.**

## The role-separation model (least privilege, by function)
| Capability domain | Administer | Analyze / investigate | Read-only |
|---|---|---|---|
| **Information Protection** (labels/DLP) | Information Protection Admins | Information Protection Analysts / Investigators | Information Protection Readers |
| **Data Lifecycle & Records** | Records Management | — | Global Reader / read role |
| **Insider Risk Management** | Insider Risk Management Admins | Analysts / Investigators | Insider Risk Management Auditors |
| **Communication Compliance** | Communication Compliance Admins | Analysts / Investigators | Communication Compliance Viewers |
| **eDiscovery** | eDiscovery Administrator | eDiscovery Manager | reviewer (case-scoped) |
| **Audit / posture** | — | Audit roles | Global Reader |
> Global Administrator and Compliance Administrator subsume many of these — reserve them and prefer the
> **narrow, function-specific** role group. **Verify the exact role-group names and rights in your
> tenant** — Purview role naming (and the transition to unified Purview RBAC "roles & scopes") is
> **evolving**; do not assume. Separation of duties is the point: information protection ≠ insider risk
> ≠ eDiscovery ≠ records, and readers/auditors stay read-only.

## What you can control
- The **capability map** — which capabilities are in scope, and their phase, owner, and status.
- The **RBAC model** — the role groups, the least-privilege separation, and the SoD rules.
- The **scoping strategy** — adaptive vs static scopes, administrative-unit use, the in-scope workloads,
  and the pilot ring.
- The **naming standard** applied to every future object.
- The **phase roadmap** — sequence, gates, and dependencies — and the **pilot ring** validated first.

## Limitations (be honest with buyers)
- **It designs; it does not build every capability.** This solution produces the architecture and stands
  up the **foundation guardrails** (roles, scopes, naming, pilot ring). Each capability's policies
  (labels, DLP, retention, insider risk, etc.) are built in **that capability's own solution**, against
  this design, and **piloted in simulation/test first**.
- **Licensing gates the map.** Advanced capabilities require **E5 / E5 Compliance** (or add-ons); some
  are in **preview**. A capability you design a phase around may not be licensable — the map flags it as
  **deferred (not licensed)**. **Verify entitlement — do not assume.**
- **Portal-driven and evolving.** Role groups, adaptive scopes, administrative units, and the unified
  Purview RBAC surface are managed in the **portals** and are **actively changing**. The scripts assess,
  scaffold, validate, and report; they do not replace the portal, and they flag where a surface is
  portal-only. **Verify paths against your tenant.**
- **Determinations are deferred.** Regulatory applicability, retention schedules, records file plans,
  and the lawful basis for insider-risk monitoring are **compliance / records / privacy / legal**
  determinations. The architecture carries them; it does not make them.
- **No secrets in automation.** The provided scripts use interactive modern-auth sign-in; they never
  embed credentials, and default to read-only or `-WhatIf`.

## Naming convention (used in every doc and script)
Every design artifact and every object this architecture governs is named `<Purpose> – <Scope> –
<Stage>` and reused verbatim across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Tenant baseline snapshot | `PA Design Baseline – Tenant – Assess` |
| Capability map | `PA Capability Map – Tenant – Design` |
| RBAC model | `PA RBAC Model – Tenant – Design` |
| RBAC separation-of-duties conflicts | `PA RBAC SoD – Conflicts` |
| Scoping plan | `PA Scoping Plan – Tenant – Design` |
| Naming standard | `PA Naming Standard – Tenant – Design` |
| Phase roadmap | `PA Phase Roadmap – Program – Design` |
| Design posture report | `PA Design Posture – Report` |
| Pilot ring group | `SG-PA-Pilot` |
| Example adaptive scope (pilot) | `AS-PA-Pilot` |
> Future capability objects follow the same pattern, e.g. `DLP-PII-Sim`, `Label-Confidential-Prod`,
> `Retention-Finance-Prod`, `AS-Finance-Prod` — `<Purpose> – <Scope> – <Stage>`, with **`Sim`** for
> simulation/test and **`Prod`** for enforced.

## The standard deployment model
> Baseline the tenant → map capabilities to licensing and phases → design the RBAC model, scoping
> strategy, and naming standard → stand up the foundation guardrails (least-privilege roles, pilot
> ring/adaptive scope, naming) → validate the design and report the posture → execute the roadmap phase
> by phase, each capability piloted in simulation/test against this architecture.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand** —
> regulatory, records, and legal determinations deferred to compliance/records/privacy/legal at every step.
