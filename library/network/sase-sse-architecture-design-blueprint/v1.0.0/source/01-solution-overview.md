# 1. Solution Overview — SASE / SSE Architecture & Design Blueprint

## What this solution is

This is a **reference architecture and design blueprint** for a SASE/SSE estate — not a single
product configuration and not a one-button wizard. It is a repeatable design that ties the edge
security services together into one coherent model, with a **phased adoption roadmap** and a **target
operating model**, so an organization can roll out every edge service against the same blueprint
rather than buying and operating them in silos.

Concretely, the blueprint delivers three durable artifacts that the rest of this package builds and
operates:

1. A named **reference architecture** — `SASE Reference Architecture – Edge – Design` — that shows how
   the capability services fit together and how traffic and identity flow through them.
2. A named **policy model** — `SASE Policy Model – Edge – Design` — a layered way of writing policy
   (identity-first, then destination/app, then content) that is consistent across every service.
3. A named **adoption roadmap** — `SASE Adoption Roadmap – Edge – Program` — a sequence of phases that
   moves the estate from piecemeal to unified, each with an entry and a gate.

It also defines a **target operating model** — `SASE Operating Model – Edge – Run` — with roles, RACI,
and KPIs so the design is *run*, not just *built*.

## Why piecemeal edge security fails (the *why*)

Edge controls bought separately almost always end up:

- **Overlapping** — two products inspect the same traffic, or two access paths exist to the same app,
  doubling cost and confusion.
- **Inconsistent** — SSL inspection is on in one path and off in another; policy is identity-aware in
  one console and IP-based in the next; the same user gets different treatment depending on which tool
  is in front.
- **Un-auditable** — no single place answers "which control decided, and why," because the decision is
  spread across consoles with different data models.
- **Hard to operate** — every product has its own admin model, its own identity wiring, its own
  reporting, and its own upgrade cadence.

A SASE/SSE architecture fixes this by making the edge **one logical service** with **identity as the
control plane**: who the user is and what device they are on is evaluated *once* and drives policy
*everywhere* — SWG, ZTNA, CASB, and inspection. That single shift — from network-location trust to
identity-and-device trust, evaluated consistently at the edge — is the whole point of SASE/SSE.

## The capability services and how they fit

The blueprint composes five capability areas. Each is a layer of the same edge, not a separate
island. Exact Netskope console screens for configuring each are **deferred to the official Netskope
documentation and your tenant** (see the vendor note in `global-requirements-network.md`); this
section is about *what each does and where it sits in the architecture*.

| Capability | What it does | Where it sits in the architecture |
|---|---|---|
| **Secure Web Gateway (SWG)** | Inline inspection and policy for web/SaaS traffic (URL/category filtering, threat protection, acceptable-use). | The inline path for internet/SaaS-bound traffic; consumes identity from the control plane. |
| **Zero Trust Network Access (ZTNA)** | Identity- and device-aware access to *private* applications; replaces broad VPN network access with per-app, least-privilege access. | The private-app path; brokers connections by identity, not network location. |
| **Cloud Access Security Broker (CASB)** | Visibility into and control over sanctioned/unsanctioned cloud apps; inline controls and (where supported) API-based posture. | Rides the inline path (and API connectors) to govern cloud-app usage and shadow IT. |
| **SSL/TLS inspection** | Decrypts inspectable traffic so SWG/CASB/threat controls can actually see content, with a governed exception list. | The decryption foundation under the inline path; everything inline depends on it. |
| **Data-protection-adjacent (DLP-adjacent)** | Content-aware policy hooks (where to apply data classification/blocking) positioned in the design. | Designed into the inline and CASB layers; the deep DLP build is a separate program. |

> **Scope honesty:** this blueprint *designs in* the DLP-adjacent control points (where data-aware
> policy will attach) but does not build a full data-classification/DLP program — that is a separate
> engagement. Naming the hooks now means the later DLP work drops into the architecture cleanly
> instead of bolting on.

## Identity as the control plane

In this design, **Microsoft Entra ID is the control plane**. The edge does not decide policy from IP
addresses or network segments; it decides from **identity and device posture**:

- **SSO and identity** — users authenticate via Entra ID; the edge trusts that assertion.
- **Groups drive steering and policy** — phase scope, ring membership, and policy targeting all key off
  named Entra security groups (built by the supplied `SASE-Set-PhaseScopeTargeting.ps1`).
- **Device posture** — managed/compliant device signals (from Intune) feed access decisions (especially
  ZTNA).
- **One decision, applied everywhere** — the same identity context drives SWG, ZTNA, and CASB policy,
  which is what makes the estate *coherent* rather than five separate trust models.

## The phased adoption roadmap

The blueprint is adopted in **named phases** (`SASE Adoption Roadmap – Edge – Program`), each a
deliberate step from piecemeal to unified. The phases are summarized here and detailed in the
Implementation Guide:

- **Phase 0 — Baseline & Steering** — establish identity wiring, deploy the client/steering to a small
  scope, turn on visibility (monitor-only).
- **Phase 1 — Secure Web Gateway** — bring web/SaaS traffic under one SWG policy with SSL inspection
  and a governed exception model.
- **Phase 2 — CASB & Cloud-App Control** — add sanctioned/unsanctioned cloud-app visibility and inline
  control; tame shadow IT.
- **Phase 3 — ZTNA for Private Apps** — publish private apps via identity-aware access and begin VPN
  displacement.
- **Phase 4 — Data-Protection-Adjacent & Optimization** — activate the designed-in content-aware hooks
  and tune the estate.

Each phase runs the standard model **Assess → Configure → Pilot → Validate → Expand**, and **no phase
expands until its pilot passes the gate**.

## The target operating model

A design nobody runs decays. The blueprint ships a **target operating model**
(`SASE Operating Model – Edge – Run`) so the estate has named owners and measurable health:

- **Roles** — `SASE Architecture Owner – Edge – Run`, `SASE Policy Administrator – Edge – Run`,
  `SASE Operations Engineer – Edge – Run`, `SASE Identity Liaison – Edge – Run`, and an executive
  `SASE Sponsor – Program – Run` (detailed in the Implementation Guide).
- **KPIs** — steering coverage, SSL-inspection coverage (with a tracked exception rate), policy
  consistency, ZTNA/VPN displacement, mean time to policy change, and user-impact/ticket rate.
- **Cadence** — a regular policy-review and exception-review rhythm, plus a phase-gate review.

## Benefits

- **One coherent edge** — SWG, ZTNA, CASB, and inspection operated as a single, identity-driven service.
- **Lower cost and overlap** — designing first surfaces duplicate tools and paths before more are bought.
- **Auditable decisions** — a single policy model means you can explain why any decision was made.
- **De-risked rollout** — phased adoption with a pilot gate per phase; live traffic is never changed
  blindly.
- **A run model, not just a build** — named roles and KPIs keep the architecture healthy over time.

## Honest limitations

- **This is a design + adoption blueprint, not a turnkey tenant build.** It names the architecture,
  policy model, roadmap, and operating model and walks the rollout; the **exact Netskope console
  configuration is deferred to Netskope's official documentation and your tenant**.
- **It requires real prerequisites** — a licensed Netskope tenant and modules, Entra ID identity,
  endpoint management to deliver the client/certificates, network/egress inputs, and executive
  sponsorship (see Requirements).
- **Deep DLP is out of scope** — the architecture *designs in* the content-aware hooks; building a full
  data-classification/DLP program is a separate engagement.
- **SSL inspection has a governed exception model** — some destinations (e.g. regulated, pinned, or
  privacy-sensitive categories) are inspected by exception; coverage is a tracked KPI, not 100%.
- **It is phased, not same-day** — a piecemeal-to-unified move is deliberately staged, wave by wave,
  behind change control.

## The standard deployment model

This solution follows the **standard deployment model** at two levels: the **program** is delivered in
roadmap phases, and **each phase** internally follows the same lifecycle —

**Assess → Configure → Pilot → Validate → Expand**, with a **pilot-phase gate** that must pass before
any phase expands to broader scope.
