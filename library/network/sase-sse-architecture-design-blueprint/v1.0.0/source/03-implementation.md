# 3. Implementation Guide — SASE / SSE Architecture & Design Blueprint

This is the **program runbook**. It produces the three design artifacts, defines the operating model,
and then executes the phased adoption roadmap. The program follows the standard model at two levels:
the **roadmap** is a sequence of phases, and **each phase** internally runs
**Assess → Configure → Pilot → Validate → Expand** with a **pilot-phase gate** that must pass before
the phase expands.

> **Naming convention (mandatory, reused verbatim):** every artifact, phase, role, and group is named
> `<Purpose> – <Scope> – <Stage>`. Stage is `Design` (an architecture artifact), `Program` (a roadmap/
> cross-cutting item), `Pilot` / `Broad` (a rollout scope), or `Run` (an operating-model item). The
> canonical names introduced here are reused in Testing (§05) and Troubleshooting (§06).

> **Vendor note (read first):** the **exact Netskope console** screens, menu paths, and tenant options
> are **deferred to the official Netskope documentation and your tenant**. Steps below say *what* to
> configure and *in what order*; confirm the precise control in your console. Identity/edge
> current-state discovery uses **Microsoft Graph PowerShell** (the supplied scripts), which is real and
> current.

---

## Part A — Design artifacts (Configure-phase deliverables)

Before any traffic is touched, author the three artifacts. They are the things the whole program
executes against (requirement R7).

### A1 — Reference architecture: `SASE Reference Architecture – Edge – Design`

Define, on one page plus detail, how the capability services compose into one edge:

1. **Identity control plane.** Entra ID is the source of truth; SSO to the edge; group membership and
   device posture (from Intune) feed every policy decision. State explicitly: *policy is decided from
   identity + device, not network location.*
2. **Inline path.** The steered traffic flow: endpoint → steering (client-based or network-based, per
   R5) → SSL inspection (with the governed exception list, R9) → SWG policy → CASB inline controls →
   internet/SaaS.
3. **Private-app path.** ZTNA brokers identity-aware, per-app access to private applications (R10),
   displacing broad VPN network access.
4. **DLP-adjacent hooks.** Mark *where* content-aware policy will attach (inline and CASB layers) so the
   later DLP program drops in — do not build DLP here.
5. **Exception model.** The SSL-inspection exception list and the steering-bypass list, both governed
   and recorded here.
6. **Trust boundaries.** Note what is decrypted, what is bypassed, and where regulated/privacy-sensitive
   traffic is handled.

**Output:** an approved `SASE Reference Architecture – Edge – Design` document (diagram + narrative).

### A2 — Policy model: `SASE Policy Model – Edge – Design`

Define **one** way to write policy, applied consistently across SWG, ZTNA, and CASB. The model is
layered, evaluated in this order:

1. **Identity layer (first).** Who is the user / which Entra group, and what is the device posture?
   Everything keys off this.
2. **Destination / application layer.** Web category/URL, SaaS app instance, or named private app.
3. **Content layer (DLP-adjacent hook).** Where content-aware rules will attach (designed in now).
4. **Action.** Allow / inspect / restrict / block, plus user-coaching where the capability supports it.

State the conventions: least-privilege default, identity-first targeting, named policy objects using
the convention (e.g. `SASE Policy – SWG Acceptable Use – Broad`), and a change/exception process.

**Output:** an approved `SASE Policy Model – Edge – Design`.

### A3 — Adoption roadmap: `SASE Adoption Roadmap – Edge – Program`

Sequence the phases (Part C), each with: entry criteria, the targeting groups it uses, its pilot scope,
its acceptance gate (§05), and its rollback (R11). Record it as `SASE Adoption Roadmap – Edge – Program`.

---

## Part B — Target operating model: `SASE Operating Model – Edge – Run`

A design must be *run*. Define the operating model before the first phase expands (requirement R12).

### B1 — Roles (RACI)

| Role (named) | Responsibility |
|---|---|
| `SASE Sponsor – Program – Run` | Executive accountability, budget, cross-team mandate, phase-gate sign-off. |
| `SASE Architecture Owner – Edge – Run` | Owns the reference architecture and policy model; approves changes; final say on exceptions. |
| `SASE Policy Administrator – Edge – Run` | Authors/maintains policy per the policy model; runs the exception process. |
| `SASE Operations Engineer – Edge – Run` | Day-to-day edge operations, steering/client health, incident response, validation runs. |
| `SASE Identity Liaison – Edge – Run` | Owns the Entra group/targeting wiring and device-posture signals; bridges identity + edge teams. |

### B2 — KPIs (the run dashboard)

| KPI | What it measures | Target posture |
|---|---|---|
| Steering coverage | % of in-scope endpoints actively steered | Trend to ~100% of the active phase scope |
| SSL-inspection coverage | % of inspectable traffic decrypted | High, with the **exception rate tracked** (not chased to 100%) |
| Policy consistency | % of traffic governed by the unified policy model (vs. legacy point tools) | Increases each phase as silos retire |
| ZTNA / VPN displacement | % of private-app access via ZTNA vs. legacy VPN | Increases through the ZTNA phase |
| Mean time to policy change | Time from request to safely-applied policy | Decreases as the model matures |
| User-impact / ticket rate | Edge-related tickets per active user | Low and stable; spikes trigger a review |

### B3 — Cadence

- **Policy review** (regular): new/changed policy against the policy model.
- **Exception review** (regular): SSL-inspection and steering-bypass exceptions — re-justify or retire.
- **Phase-gate review** (per phase): the pilot acceptance gate (§05) before expansion.

---

## Part C — Phased adoption roadmap (execution)

Each phase below runs the standard model. **The pilot-phase gate is mandatory: a phase does not expand
until its pilot passes its acceptance gate in §05.** All phases target the Entra groups built by
`SASE-Set-PhaseScopeTargeting.ps1` (requirement R8).

> **Per-phase preflight (every phase):** run `SASE-Validation.ps1` (readiness) and `SASE-Report.ps1`
> (capability-coverage + gap report) before Configure; confirm change control, rollback, and comms
> (R11). Use `SASE-Remediation.ps1` (default `-WhatIf`) to preview fixes for any readiness gaps.

### Phase 0 — Baseline & Steering

**Goal:** wire identity, deploy steering to a small scope, turn on **monitor-only** visibility.

1. **Assess.** Run `SASE-Discovery.ps1` (read-only) for the current-state edge/identity baseline (R6).
   Confirm gating requirements R1–R2 are met.
2. **Configure.** Confirm Entra SSO (R3); deploy the edge client + steering config and the decryption
   **root certificate** via endpoint management (R4) — but keep inspection/enforcement in monitor-only.
   Build the Phase 0 groups `SASE Phase Scope – Baseline – Pilot` / `– Broad`.
3. **Pilot.** Steer `SASE Phase Scope – Baseline – Pilot`; confirm traffic appears in the edge with
   correct identity attribution and no user impact (monitor-only).
4. **Validate.** Run the Phase 0 tests (§05). **Pilot-phase gate.**
5. **Expand.** Steer `SASE Phase Scope – Baseline – Broad`. Capture the KPI baseline (R12) now.

### Phase 1 — Secure Web Gateway (SWG)

**Goal:** bring web/SaaS traffic under one SWG policy, with **SSL inspection** and the governed
exception model.

1. **Assess.** Confirm certificate trust on the steered scope (R9); finalize the SSL-inspection
   exception list in the reference architecture.
2. **Configure.** Enable SSL inspection (honoring the exception list) and author SWG policy per the
   policy model — named objects, e.g. `SASE Policy – SWG Acceptable Use – Pilot`. (Exact console steps
   deferred to Netskope docs.)
3. **Pilot.** Apply to `SASE Phase Scope – SWG – Pilot`; verify inspection works (no TLS errors),
   policy decides as designed, exceptions are honored.
4. **Validate.** Run the SWG tests (§05). **Pilot-phase gate** — including zero broken pinned/regulated
   apps.
5. **Expand.** Promote policy to `SASE Phase Scope – SWG – Broad`; begin retiring the legacy SWG/proxy
   (policy-consistency KPI rises).

### Phase 2 — CASB & Cloud-App Control

**Goal:** add sanctioned/unsanctioned cloud-app visibility and inline control; tame shadow IT.

1. **Assess.** Review cloud-app discovery from Phase 1 visibility; classify apps sanctioned/tolerated/
   unsanctioned.
2. **Configure.** Author CASB inline policy per the policy model (identity-first), e.g.
   `SASE Policy – CASB Cloud Control – Pilot`; connect any supported API-based posture for sanctioned
   apps. (Console specifics deferred to Netskope docs.)
3. **Pilot.** Apply to `SASE Phase Scope – CASB – Pilot`; verify shadow-IT visibility and that control
   actions behave as designed.
4. **Validate.** Run the CASB tests (§05). **Pilot-phase gate.**
5. **Expand.** Promote to `SASE Phase Scope – CASB – Broad`.

### Phase 3 — ZTNA for Private Apps

**Goal:** publish private apps via identity-aware, per-app access; begin VPN displacement.

1. **Assess.** Confirm the private-app catalog mapped to Entra groups (R10).
2. **Configure.** Publish private apps via ZTNA, mapping each to its access group per the policy model,
   e.g. `SASE Policy – ZTNA Private App – Pilot`. (Connector placement / console steps deferred to
   Netskope docs.)
3. **Pilot.** Apply to `SASE Phase Scope – ZTNA – Pilot`; verify users reach exactly their entitled apps
   and nothing else; confirm the VPN path can be displaced for these users.
4. **Validate.** Run the ZTNA tests (§05). **Pilot-phase gate.**
5. **Expand.** Promote to `SASE Phase Scope – ZTNA – Broad`; retire broad VPN access as displacement
   proves out (ZTNA/VPN-displacement KPI rises). Keep the VPN path warm per the rollback plan (R11)
   until displacement is validated.

### Phase 4 — Data-Protection-Adjacent & Optimization

**Goal:** activate the designed-in content-aware hooks and tune the estate.

1. **Assess.** Review the DLP-adjacent hooks named in the reference architecture; confirm scope (this
   blueprint *attaches* hooks; the deep DLP build is a separate program).
2. **Configure.** Activate the content-aware policy hooks where designed, e.g.
   `SASE Policy – Data Hook – Pilot`; tune inspection exceptions, SWG/CASB policy, and performance.
3. **Pilot.** Apply to `SASE Phase Scope – DataHook – Pilot`; verify hooks fire as designed with no
   undue user impact.
4. **Validate.** Run the optimization tests (§05). **Pilot-phase gate.**
5. **Expand.** Promote to `SASE Phase Scope – DataHook – Broad`; finalize the operating-model cadence
   (Part B).

---

## Part D — Transition to run

Once the roadmap phases pass:

1. Confirm all phase gates PASS (`SASE-Report.ps1` shows capability coverage with no critical gaps).
2. Hand the estate to the operating model (Part B): roles assigned, KPI dashboard live, review cadence
   scheduled.
3. Keep the three design artifacts version-controlled; any change goes through the policy/exception
   review and updates `SASE Reference Architecture – Edge – Design` / `SASE Policy Model – Edge – Design`.

---

### Order of operations

`Design artifacts (A) → Operating model (B) → Phase 0 Baseline → Phase 1 SWG → Phase 2 CASB →
Phase 3 ZTNA → Phase 4 Data-hook & Optimize → Run (D)` — each phase gated by its pilot.
