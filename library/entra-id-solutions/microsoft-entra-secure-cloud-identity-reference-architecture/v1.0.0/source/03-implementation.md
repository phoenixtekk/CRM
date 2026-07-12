# 3. Design & Decision Guide — Microsoft Entra: Secure Cloud Identity Reference Architecture

This is a **design deliverable**, so this guide is a **method for producing a documented architecture**,
not a click-by-click deployment. Follow the stages in order. The output is three named artifacts: the
**Architecture Design Document**, the **Decision Record** (a numbered log of `ADR-0nn` decisions), and
the **phased Roadmap**. The actual configuration of each control is performed later by the
cross-referenced build solution, not here.

> Method: Assess the current identity posture with the read-only scripts and KQL -> Configure the
> target-state design across the six domains, recording each choice as an `ADR-0nn` -> Pilot the design
> in a structured review with the decision owners -> Validate against pass/fail gates and the tenant ->
> Expand into the finalized Design Document, frozen Decision Record, and published Roadmap. No decision
> is finalized before it is reviewed and validated, and every domain ends with a build cross-reference.

**Artifact & object naming convention (used everywhere below and in the scripts):**

| Artifact / object | Name |
|---|---|
| Master design document | `Identity Architecture - Enterprise - Design` |
| Decision log | `Decision Record - Identity Architecture - Design` |
| Individual decision | `ADR-0nn <Decision> - <Domain>` |
| Roadmap | `Roadmap - Identity Foundation - Phased` |
| Roadmap phase | `Phase n - <Theme>` |
| Groups/objects the design mandates (for the builds) | `<Purpose> - <Scope> - <Stage>` |
| Admin tiers the design defines | `Tier 0 / Tier 1 / Tier 2` |

Create these once and reuse the exact names in the Testing Guide, Troubleshooting Guide, and scripts.

---

## Stage 1 (Assess) — inventory the current identity posture
1. Run `ENTARCH-Discovery.ps1`. It reports, read-only: verified domains and topology signals, the
   identity source of authority (cloud-only vs. synced), licensing (P1/P2, Governance, GSA, Verified ID
   — flagged *verify*), existing Conditional Access policies and states, named locations, and
   external-collaboration settings.
2. Run `ENTARCH-IdentityInventory.ps1`. It counts and profiles the three identity types: **human**
   (member users, stale accounts, MFA registration), **workload** (service principals, managed
   identities, app credentials nearing expiry), and **external** (B2B guests, guest age, cross-tenant
   settings).
3. Run `ENTARCH-PrivilegedAccessReview.ps1`. It enumerates privileged role assignments — permanent vs.
   PIM-eligible, the Global Administrator count, highly-privileged service principals, and whether
   break-glass accounts exist.
4. Run `ENTARCH-Report.ps1` and run the embedded **KQL** queries (against `Monitoring -> Sign-in logs`
   or a Log Analytics workspace) to quantify posture: MFA coverage, legacy-auth sign-ins, risky
   sign-ins, and privileged sign-in patterns.
5. Save all output as the **Assess appendix** of `Identity Architecture - Enterprise - Design`. This is
   the evidence base — every decision that follows cites it. For each existing control, tag it
   **adopt**, **adjust**, or **replace** (this keeps the design gap-only — you do not redesign what is
   already sound).

## Stage 2 (Configure) — design the six domains and record the decisions
Work through the six domains in order. For each, frame the options against the architecture principles
(below), pick a target state with the named decision owner, and write an `ADR-0nn` capturing **Context
/ Decision / Rationale / Consequences / License-or-preview caveat / Build cross-reference**.

**Architecture principles (the design is tested against these):** least privilege by default; assume
breach (Zero Trust); no permanent standing admin; break-glass is sacrosanct; phishing-resistant auth
for privileged access; govern the full identity lifecycle; prefer cloud-native over hybrid where
feasible; every exception is documented, owned, and time-boxed.

### Domain 1 — Tenant topology & environment model
- Decide single vs. multi-tenant, production/test separation, and directory boundaries.
- Decide the **source of authority**: cloud-only, or hybrid with on-prem AD as master (drives Domain 6).
- Decisions: `ADR-001 Tenant Topology - Foundation`, `ADR-002 Identity Source of Authority - Foundation`.

### Domain 2 — Identity model (human / workload / external)
- **Human:** UPN/naming standard (routable domain, no `.local`), account types (member / cloud-only
  admin), and joiner/mover/leaver ownership. Object standard example: `<Purpose> - <Scope> - <Stage>`
  security groups (for example `CA Persona - Admins - Steady`, reused by the Zero Trust build).
- **Workload:** how service principals and managed identities are named, owned, credential-managed, and
  governed (prefer managed identities and short-lived credentials; app-credential expiry monitoring).
- **External:** the B2B collaboration and cross-tenant access posture — who can invite, which external
  tenants are trusted, and guest lifecycle (access reviews + expiry).
- Decisions: `ADR-003 Human Identity & Naming Standard - Identity Model`,
  `ADR-004 Workload Identity Strategy - Identity Model`,
  `ADR-005 External Identity & B2B Posture - Identity Model`.
- Build cross-reference: External Identities / B2B Cross-Tenant and Enterprise App & Service Principal
  Governance solutions execute the workload and external decisions.

### Domain 3 — Zero Trust access design
- Design the **Conditional Access persona baseline**: personas (`Admins`, `Internals`,
  `Externals-Guests`, `Service-Accounts`) mapped to `<Purpose> - <Scope> - <Stage>` groups, the
  control per persona (MFA, phishing-resistant for admins, compliant/hybrid device, block legacy auth,
  session controls), and the report-only-first rollout discipline. This design is the input the build
  consumes; it does not create the policies here.
- Design the **Identity Protection risk posture** (sign-in risk / user risk policies) — **requires
  Entra ID P2**; *verify availability*. If P1-only, design the non-risk compensating controls and note
  the gap.
- Decisions: `ADR-006 Authentication Methods & Phishing-Resistant Strategy - Zero Trust`,
  `ADR-007 Conditional Access Persona Baseline - Zero Trust`,
  `ADR-008 Identity Protection Risk Posture (P2) - Zero Trust`.
- **Build cross-reference:** the **Zero Trust Conditional Access Baseline (`ENTZTCA`)** builds the CA
  baseline; **Identity Protection & Advanced Conditional Access (`ENTIDP`)** builds the risk posture.

### Domain 4 — Privileged access model
- Design **admin tiering** (`Tier 0` = identity/control-plane admins; `Tier 1` = server/workload
  admins; `Tier 2` = workstation/helpdesk), with role separation and no cross-tier credential reuse.
- Design the **PIM model**: which roles are eligible (not permanent), activation requirements
  (approval, MFA, justification, max duration) — **requires Entra ID P2**; *verify availability*.
- Design the **break-glass standard** (two cloud-only accounts, excluded from CA, monitored) and the
  **PAW model** (privileged access workstations for Tier 0/1 admin work).
- Decisions: `ADR-009 Admin Tiering Model - Privileged Access`,
  `ADR-010 PIM Eligibility & Activation Model - Privileged Access`,
  `ADR-011 Break-Glass Standard - Privileged Access`,
  `ADR-012 Privileged Access Workstation Model - Privileged Access`.
- **Build cross-reference:** **Privileged Identity Management (`ENTPIM`)** builds PIM;
  **Privileged Access Workstation (`ENTPAW`)** builds the PAW. Break-glass exclusions are implemented
  by the Zero Trust build (`ENTZTCA`).

### Domain 5 — Identity governance model
- Design the **joiner/mover/leaver (JML) lifecycle** (automated provisioning/deprovisioning triggers),
  **entitlement management** (access packages with policies, approvals, and expiry), and **access
  reviews** (cadence and scope for privileged roles, guests, and high-value groups). **Requires Entra
  ID Governance**; *verify availability*.
- Decisions: `ADR-013 Access Lifecycle (JML) - Governance`,
  `ADR-014 Entitlement Management & Access Packages - Governance`,
  `ADR-015 Access Reviews Cadence - Governance`.
- **Build cross-reference:** **Identity Governance: Access Reviews & Entitlement (`ENTIGA`)** builds the
  governance model.

### Domain 6 — Hybrid / coexistence & connectivity
- Design **hybrid coexistence** if the source of authority is on-prem AD (Entra Connect vs. cloud sync,
  source anchor, password hash sync vs. pass-through vs. federation) — see the category global
  requirements (healthy AD, Connect host, UPN hygiene).
- Design **application identity & migration** (moving apps to Entra SSO, retiring legacy auth) and
  **secure network access to resources** (Global Secure Access) — **GSA is separately licensed / partly
  in preview**; *verify availability*.
- Decisions: `ADR-016 Hybrid Coexistence & Sync Model - Hybrid`,
  `ADR-017 Application Identity & Migration Approach - Apps`,
  `ADR-018 Secure Network Access (Global Secure Access) - Connectivity`.
- **Build cross-reference:** **Hybrid Identity: AD + Entra Connect (`HYBID`)**,
  **Migrate & Protect Applications with Entra (`ENTAPPMIG`)**, and **Global Secure Access (`ENTGSA`)**.

## Stage 3 (Pilot) — design review with the decision owners
1. Convene the named decision owners (security, ops, compliance). Walk the Decision Record `ADR` by
   `ADR`.
2. For each decision confirm: it is consistent with the architecture principles; it does not conflict
   with an existing **adopt** control from Assess; its license/preview caveat is acknowledged and owned;
   and an accountable owner is attributed.
3. Record objections and open decisions **as** `ADR` entries in `Proposed` status — never invent an
   answer where an owner has not decided. The design captures the open question.

## Stage 4 (Validate) — check the design against gates and the tenant
1. Run `ENTARCH-Validate.ps1`. It checks the tenant against the target-state blueprint: are break-glass
   accounts present; do the mandated `<Purpose> - <Scope> - <Stage>` design groups exist yet (or are
   they roadmap items); is the licensing the design assumes actually present; are there All-users CA
   policies with no exclusions that the design must reconcile.
2. Complete the Testing Guide (`05-testing.md`) — every `ADR` has context+rationale, every domain has a
   build cross-reference, every license/preview dependency is flagged *verify*, and the roadmap phases
   are gated.
3. Reconcile any gap the validation surfaces: either adjust the decision, or record it as an explicit
   roadmap prerequisite (for example "acquire Entra ID P2 before Phase 2").

## Stage 5 (Expand) — finalize and roadmap
1. Freeze the **Decision Record** — move every reviewed `ADR` from `Proposed` to `Accepted` (or record
   why it was `Rejected` / `Superseded`). The frozen record is the defensible artifact.
2. Publish the **phased Roadmap** `Roadmap - Identity Foundation - Phased`, sequencing the builds:

| Phase | Theme | Builds (cross-referenced solutions) | Gate to enter |
|---|---|---|---|
| `Phase 0 - Foundation` | Break-glass, tenant/topology, licensing true-up | Break-glass standard; license acquisition where needed | Assess complete; owners named |
| `Phase 1 - Hybrid & Identity Model` | Source of authority, sync, human/workload/external model | `HYBID`; External Identities / App governance | `ADR-001..005`, `016` accepted |
| `Phase 2 - Zero Trust Access` | CA persona baseline, then risk posture | `ENTZTCA`, then `ENTIDP` (P2) | `ADR-006..008` accepted; P1/P2 confirmed |
| `Phase 3 - Privileged Access` | Admin tiering, PIM, PAW | `ENTPIM`, `ENTPAW` | `ADR-009..012` accepted; P2 confirmed |
| `Phase 4 - Governance` | JML lifecycle, entitlement, access reviews | `ENTIGA` | `ADR-013..015` accepted; Governance license confirmed |
| `Phase 5 - Apps & Connectivity` | App migration, Global Secure Access | `ENTAPPMIG`, `ENTGSA` | `ADR-017..018` accepted; GSA availability verified |

3. Hand each phase to its build solution. Keep the Decision Record living — every future build that
   deviates adds a superseding `ADR` rather than silently drifting.

---
### Order of operations
`Assess (posture scripts + KQL) -> Configure (six domains -> Decision Record ADRs) -> Pilot (owner
review) -> Validate (gates + ENTARCH-Validate.ps1 against the tenant) -> Expand (freeze Decision
Record + publish phased Roadmap -> hand to build solutions)`

### Rollback / reversibility (a design product)
- Because this deliverable **makes no tenant changes**, there is nothing to roll back. The scripts are
  read-only; the output is documentation.
- A **decision** is reversed by adding a superseding `ADR` (status `Superseded`) — the Decision Record
  keeps the history, so the architecture never drifts silently.
- The **builds** it hands off to each carry their own report-only / `-WhatIf` / break-glass rollback
  discipline (see each build solution); the roadmap's phase gates ensure no build enforces before its
  design decision is accepted and validated.
