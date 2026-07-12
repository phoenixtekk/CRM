# 1. Solution Overview — Microsoft Entra: Secure Cloud Identity Reference Architecture

## What a reference architecture is (and what it is not)
A reference architecture is a **documented design**: a set of deliberate decisions about how your
identity foundation is structured, why each decision was made, and in what order it should be built.
It is the drawing, not the building. This solution produces three artifacts — an **Architecture Design
Document**, a **Decision Record** (a numbered log of the choices and their rationale), and a **phased
Roadmap** — and hands the actual construction to the implementation solutions it cross-references.

That separation is the point. Building Conditional Access, PIM, governance, and hybrid sync without a
design first is how tenants accrue permanent Global Admins, RBAC sprawl, orphaned guests, and rework.
Designing first — deciding topology, identity model, access model, and governance on purpose, and
recording the decisions — makes the build predictable and the result defensible.

## Why identity is the control plane
In a Microsoft cloud estate, identity is where trust is established and access is enforced. Every
sign-in, every admin action, every app connection, and every automated workload authenticates through
Microsoft Entra. Get the identity architecture right and the rest of Zero Trust (devices, data,
network, apps) has a solid anchor; get it wrong and every downstream control inherits the weakness.
That is why a secure cloud identity foundation is worth designing deliberately, once.

## The six design domains
The architecture is organized into six domains. Each domain produces decisions in the Decision Record
and maps to the implementation solution that builds it:

1. **Tenant topology & environment model** — single vs. multi-tenant, production/test separation,
   directory boundaries, and the source of authority for identity (cloud-only vs. hybrid).
2. **Identity model (human / workload / external)** — the three identity types and how each is
   represented, named, provisioned, and retired: member users (humans), service principals / managed
   identities (workloads), and B2B guests / cross-tenant access (external).
3. **Zero Trust access design** — the Conditional Access persona baseline and the Identity Protection
   risk posture (the "who, on what, how risky" access rules). *Builds:* the Zero Trust Conditional
   Access Baseline and Identity Protection solutions.
4. **Privileged access model** — admin tiering, PIM eligibility and activation, break-glass, and
   privileged access workstations (PAW). *Builds:* the PIM and PAW solutions.
5. **Identity governance model** — joiner/mover/leaver lifecycle, entitlement management (access
   packages), and access reviews. *Build:* the Identity Governance solution.
6. **Hybrid / coexistence & connectivity** — on-prem AD coexistence (Entra Connect / cloud sync),
   application identity and migration, and secure network access to resources (Global Secure Access).
   *Builds:* the Hybrid Identity, Application Migration, and Global Secure Access solutions.

## How the blueprint relates to the builds (this is a design product)
This solution deliberately does **not** re-document how to configure Conditional Access, PIM, access
reviews, or Entra Connect — those are delivered, click-by-click, by the adjacent catalog solutions.
This blueprint's job is upstream of them: decide the target state, record the decisions, and sequence
the builds. Each domain in the Design Guide ends with a "build cross-reference" naming the
implementation solution that executes it, so the buyer's roadmap is a concrete, ordered list of the
solutions to deploy — not a vague aspiration.

| Design domain | Implementation solution it points to (the build) |
|---|---|
| Zero Trust access — Conditional Access baseline | Zero Trust Conditional Access Baseline (`ENTZTCA`) |
| Zero Trust access — risk-based (P2) | Identity Protection & Advanced Conditional Access (`ENTIDP`) |
| Privileged access — just-in-time elevation | Privileged Identity Management / PIM (`ENTPIM`) |
| Privileged access — admin workstations | Privileged Access Workstation / PAW (`ENTPAW`) |
| Identity governance — reviews, entitlement, lifecycle | Identity Governance: Access Reviews & Entitlement (`ENTIGA`) |
| Connectivity — secure access to resources | Global Secure Access (`ENTGSA`) |
| Applications — identity & migration | Migrate & Protect Applications with Entra (`ENTAPPMIG`) |
| Hybrid coexistence — AD ↔ Entra sync | Hybrid Identity: AD + Entra Connect (`HYBID`) |

## The design method — Assess, Configure, Pilot, Validate, Expand
The same repeatable model the catalog uses, adapted for a design deliverable:

- **Assess** — inventory the current identity posture with the read-only scripts (humans, workloads,
  external identities, privileged access, Conditional Access, licensing). This is the evidence base.
- **Configure** — draft the target-state design across the six domains and capture each choice in the
  Decision Record as a numbered `ADR-0nn` with context, decision, rationale, and consequences.
- **Pilot** — run a structured design review with the decision owners (security, ops, compliance);
  test each decision against the architecture principles and the current-state evidence.
- **Validate** — check the design against explicit pass/fail gates and against the tenant with the
  validation script; confirm nothing conflicts with an existing control or license reality.
- **Expand** — finalize the Architecture Design Document, freeze the Decision Record, publish the
  phased Roadmap, and hand each phase to its build solution.

## Naming and standards the design defines
So the design is legible and the builds inherit a consistent convention, the blueprint mandates the
same object-naming pattern the implementation solutions already use — `<Purpose> - <Scope> - <Stage>`
for groups and objects — plus a decision-record convention `ADR-0nn <Decision> - <Domain>` and a
roadmap-phase convention `Phase n - <Theme>`. These names are defined once here and reused by every
build.

## Authentication and connections used
- Microsoft Entra admin center (`https://entra.microsoft.com`) and the Azure portal for read-only
  review of the current posture during Assess.
- Microsoft Graph PowerShell SDK and the Az module for the read-only discovery, inventory, posture
  reporting, privileged-access review, and validation scripts (each script's header names its scopes;
  all are read-only).
- KQL against Entra sign-in / audit logs (Log Analytics or the sign-in logs blade) for the posture
  evidence in the assessment report — read-only queries you paste and run.

## What you can control
- The target-state design across all six domains.
- The Decision Record — every `ADR-0nn`, its rationale, and its license/preview caveats.
- The naming and admin-tiering standard the builds will adopt.
- The roadmap sequence and phase gates.

## Benefits
- **Deliberate** — an identity foundation designed on purpose, with the rationale recorded, instead of
  accreted project by project.
- **Defensible** — a decision record you can show an auditor, a board, or a new architect: what was
  decided, why, and what it depends on.
- **Sequenced** — a phased roadmap that turns "secure our identity" into an ordered list of concrete
  builds, each cross-referenced to the solution that delivers it.
- **Repeatable** — the same Assess -> Configure -> Pilot -> Validate -> Expand shape as every build, so
  the design and the builds feel like one system.

## Limitations (be honest with buyers)
- This is a **design deliverable**. It produces an architecture, a decision record, and a roadmap — it
  does **not** configure Conditional Access, PIM, governance, or sync. Those are the cross-referenced
  build solutions; budget and schedule them as separate phases.
- Several target-state controls depend on licensing — **Entra ID P1/P2**, **Entra ID Governance**,
  **Global Secure Access**, **Verified ID** — and some capabilities are **in preview**. The design
  flags each dependency; *verify current availability in your tenant* before committing a decision to
  it.
- Regulatory / records / legal retention, data classification, acceptable-identity-use, and
  production change-approval determinations are **the customer's** to make (compliance / security /
  legal / ops). The architecture provides the technical controls and the decision framework, not those
  determinations.

## The standard deployment model
> Assess the current identity posture (read-only scripts + KQL) -> Configure the target-state design
> and Decision Record across the six domains -> Pilot the design in a review with decision owners ->
> Validate against pass/fail gates and the tenant -> Expand into the finalized Design Document,
> Decision Record, and phased Roadmap handed to the build solutions. Repeatable pattern: Assess ->
> Configure -> Pilot -> Validate -> Expand.
