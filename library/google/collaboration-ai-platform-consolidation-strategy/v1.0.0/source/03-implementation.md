# 3. Implementation Guide — Collaboration & AI Platform Consolidation Strategy & Roadmap

This is the **program runbook**. It produces the four strategy artifacts, defines the operating model
and cost model, then executes the consolidation roadmap wave by wave — retiring legacy Microsoft
systems only when their coexistence-exit criteria pass. The program follows the standard model at two
levels: the **roadmap** is a sequence of waves, and **each wave** internally runs
**Assess → Configure → Pilot → Validate → Expand** with a **decommission gate** that must pass before
any legacy system is retired.

> **Naming convention (mandatory, reused verbatim):** every artifact, wave, role, and group is named
> `<Purpose> – <Scope> – <Stage>`. Stage is `Design` (a strategy artifact), `Program` (a roadmap/
> cross-cutting item), `Pilot` / `Broad` (a rollout scope), or `Run` (an operating-model/cost item).
> The canonical names introduced here are reused in Testing (§05) and Troubleshooting (§06).

> **Vendor note (read first):** the exact **Google Admin console** and **Microsoft/Entra** screens are
> named at current detail from the vendors' public documentation; **Gemini Enterprise** capabilities in
> preview/rolling out are **cited or flagged "verify in your tenant"**, never invented. The
> **click-by-click of each underlying migration** (mail, Drive, Chat/Meet, identity) is a **separate
> engagement** this roadmap *sequences and gates* — this guide defines *when a legacy system may be
> retired*, not how each migration is performed. Estate discovery uses **Microsoft Graph PowerShell**
> (the supplied scripts), which is real and current.

---

## Part A — Strategy artifacts (Configure-phase deliverables)

Before any legacy system is touched for retirement, author the four artifacts. They are the things the
whole program executes against (requirement R5).

### A1 — Consolidation strategy: `Consolidation Strategy – Platform – Design`

State the thesis on one page plus detail:

1. **Target platform.** Google Workspace + Gemini is the target collaboration-and-AI platform (R1).
2. **What retires.** The legacy Microsoft collaboration and AI systems on the decommission path
   (Exchange Online, Teams, SharePoint/OneDrive, Microsoft 365 Copilot/AI) and the duplicate identity/
   licensing/management surfaces that exist only to run them.
3. **Why.** The three recurring drivers — **sustainability, security, cost efficiency** — that justify
   every decommission decision.
4. **The end of coexistence.** State explicitly: *each legacy system retires deliberately, on a
   schedule, when its coexistence-exit criteria pass — coexistence is not a permanent state.*

**Output:** an approved `Consolidation Strategy – Platform – Design` (narrative + target-state diagram).

### A2 — Current-vs-target estate map: `Consolidation Estate Map – Platform – Design`

Map the current collaboration + AI estate to the target and surface redundancy (R4):

1. **Inventory** the estate — Microsoft (mail, Teams, SharePoint/OneDrive, Copilot), Google target
   capabilities, third-party collaboration/AI apps, and the identity/licence/contract surfaces. Run
   `GWCONSOL-Discovery.ps1` (read-only) for the discoverable Microsoft side; capture third-party and
   contract context manually.
2. **Map each system to the target** — *replaced by* a target capability, *retired outright*, or
   *retained* (a genuine keep, recorded as an exception with a reason).
3. **Flag redundancy** — where a legacy system and a target capability do the same job, mark it a
   **decommission candidate** and record the duplicate cost it carries (feeds A4).

**Output:** an approved `Consolidation Estate Map – Platform – Design` — the authoritative list of what
retires, what it maps to, and what it costs to keep running.

### A3 — Consolidation roadmap: `Consolidation Roadmap – Platform – Program`

Sequence the waves (Part C), each with: entry criteria, the scope groups it uses (R7), its pilot scope,
the legacy systems it retires, each system's **coexistence-exit criteria** (R6) and **dependency order**
(R8), its **decommission gate** (§05), and its rollback (R11). Record it as
`Consolidation Roadmap – Platform – Program`.

### A4 — Sustainability & cost model: `Consolidation Cost Model – Platform – Run`

Model the business case so savings are realized, not assumed (R9):

1. **Run-rate baseline** — the current cost of running *both* ecosystems (duplicate licences,
   contracts, operations, support).
2. **Projected savings** — the run-rate that falls away as each legacy system retires, tied to the
   roadmap waves so savings land on a schedule.
3. **Sustainability posture** — operational load, patch/audit scope, and skill footprint that shrink as
   the estate converges.

**Output:** an approved `Consolidation Cost Model – Platform – Run`; `GWCONSOL-Report.ps1` maintains the
live view against it.

---

## Part B — Target operating model: `Consolidation Operating Model – Platform – Run`

A consolidated platform must be *run* and the decommissions *governed*. Define the operating model
before the first decommission (requirement R12).

### B1 — Roles (RACI)

| Role (named) | Responsibility |
|---|---|
| `Consolidation Sponsor – Program – Run` | Executive accountability, budget, cross-team mandate, **decommission-gate sign-off**. |
| `Consolidation Owner – Platform – Run` | Owns the strategy, roadmap, and cost model; sequences the waves; final say on exit criteria and retention exceptions. |
| `Consolidation Estate Analyst – Platform – Run` | Maintains the estate map and dependency map; runs discovery/report; keeps the decommission-candidate list current. |
| `Consolidation Migration Coordinator – Platform – Run` | Coordinates the underlying migrations that each wave sequences; confirms data-migrated exit criteria. |
| `Consolidation Governance Liaison – Platform – Run` | Owns the retention/eDiscovery clearance (R10) and change/rollback per decommission; bridges legal/security and the program. |

### B2 — KPIs (the run dashboard)

| KPI | What it measures | Target posture |
|---|---|---|
| Coexistence footprint | Count of legacy systems still running | Trends to zero across the roadmap |
| Decommission progress | % of decommission candidates retired (gate PASSED) | Increases each wave |
| Realized savings | Baseline run-rate removed as systems retire | Tracks the cost-model projection |
| Licence reduction | Duplicate M365 licences reclaimed | Falls as legacy retires |
| Target-state conformance | % of users/data fully on the target platform | Trends to ~100% |
| Open exit-criteria blockers | Exit criteria not yet met per candidate | Falls to zero before each gate |

### B3 — Cadence

- **Estate review** (regular): estate map + dependency map re-confirmed as migrations complete.
- **Decommission-gate review** (per candidate): the coexistence-exit criteria (§05) before retirement.
- **Cost/savings review** (regular): realized savings against `Consolidation Cost Model – Platform –
  Run`.
- **Wave-gate review** (per wave): the pilot acceptance gate (§05) before expansion.

---

## Part C — Consolidation roadmap (execution)

Each wave below runs the standard model. **The decommission gate is mandatory: no legacy system is
retired until its coexistence-exit criteria PASS (§05), in dependency order (R8), with governance
clearance (R10).** All waves target the Entra groups built by `GWCONSOL-Set-ScopeTargeting.ps1`
(requirement R7).

> **Per-wave preflight (every wave):** run `GWCONSOL-Validation.ps1` (target-state conformance) and
> `GWCONSOL-Report.ps1` (cost/savings + decommission-readiness) before Configure; confirm change
> control, rollback, and comms (R11). Use `GWCONSOL-Remediation.ps1` (default `-WhatIf`) to preview
> fixes for any readiness gaps.

### Wave 0 — Baseline & Strategy

**Goal:** author the strategy, map the estate, set the cost/sustainability baseline, and stand up the
operating model. **Nothing is retired yet.**

1. **Assess.** Run `GWCONSOL-Discovery.ps1` (read-only) for the current-state estate baseline (R4).
   Confirm gating requirements R1–R2 are met.
2. **Configure.** Author the four artifacts (Part A) and the operating model (Part B). Build the Wave
   scope groups `Consolidation Wave Scope – <Wave> – Pilot` / `– Broad` (R7). Capture the cost baseline
   (R9) and the KPI baseline (R12).
3. **Pilot.** Validate the estate map and dependency map against a representative slice; confirm the
   decommission-candidate list and its exit criteria (R6) are complete.
4. **Validate.** Run the Wave 0 tests (§05). **Wave-gate.**
5. **Expand.** Publish the approved roadmap; the program is now sequenced and gated.

### Wave 1 — Collaboration Consolidation

**Goal:** sequence the collaboration migrations (mail, files, chat/meetings) and **retire each legacy
collaboration system as its coexistence-exit criteria pass.**

1. **Assess.** Confirm the dependency order (R8) for Exchange, SharePoint/OneDrive, and Teams; confirm
   each system's exit criteria (R6) and governance clearance (R10).
2. **Configure.** Coordinate the underlying migrations (separate engagements this wave *sequences*);
   target the `Consolidation Wave Scope – Collab – Pilot` group. Do **not** decommission anything yet.
3. **Pilot.** Migrate the pilot cohort to the target; run in coexistence; confirm the pilot's data is
   migrated and verified and no dependency remains on the legacy system.
4. **Validate.** Run the Collaboration tests (§05), including the **decommission gate** per legacy
   collaboration system (exit criteria PASS).
5. **Expand.** Promote to `Consolidation Wave Scope – Collab – Broad`; as each legacy collaboration
   system's exit criteria pass across the fleet, **retire it** (decommission-progress KPI rises; keep it
   warm per R11 until the criterion is provably met).

### Wave 2 — AI Platform Consolidation

**Goal:** converge the AI stack on the target (Gemini) and **retire the legacy Microsoft AI/Copilot
surface as its exit criteria pass.**

1. **Assess.** Inventory AI usage on both platforms; map Copilot-embedded workflows and their
   dependencies (R8). *Gemini Enterprise capabilities in preview/rolling out are flagged "verify in your
   tenant" — do not assume parity that is not confirmed.*
2. **Configure.** Enable the target AI capabilities (Gemini) for the `Consolidation Wave Scope – AI –
   Pilot` group per current Google guidance; leave the legacy AI surface in place during coexistence.
3. **Pilot.** Validate the target AI capability in production for the pilot; confirm no workflow still
   depends on the legacy Copilot surface.
4. **Validate.** Run the AI-consolidation tests (§05), including the **decommission gate** for the
   legacy AI/Copilot licences/surface.
5. **Expand.** Promote to `Consolidation Wave Scope – AI – Broad`; retire/reharvest the legacy AI
   licences as exit criteria pass (realized-savings KPI rises).

### Wave 3 — Identity & Management Consolidation

**Goal:** retire the **duplicate identity, licensing, and management surfaces** that exist only to keep
the legacy platform running.

1. **Assess.** Identify the identity/provisioning/management surfaces duplicated across ecosystems and
   their dependencies (service accounts, sync connectors, management policies) (R8).
2. **Configure.** Consolidate onto the target identity/management model for the
   `Consolidation Wave Scope – Identity – Pilot` group; confirm the source-of-truth and provisioning
   direction (global requirement 4).
3. **Pilot.** Confirm users/groups/licensing flow correctly from the consolidated model with no
   dependency left on the duplicate legacy surface.
4. **Validate.** Run the Identity/Management tests (§05), including the **decommission gate** for each
   duplicate surface.
5. **Expand.** Promote to `Consolidation Wave Scope – Identity – Broad`; retire the duplicate identity/
   management surfaces as exit criteria pass (licence-reduction KPI rises).

### Wave 4 — Decommission & Sustain

**Goal:** complete the remaining decommissions, realize the modeled savings, and hand the consolidated
estate to the operating model.

1. **Assess.** Review the decommission-candidate list; confirm every remaining candidate's exit
   criteria (R6) and governance clearance (R10) are met — `GWCONSOL-Report.ps1` shows decommission
   readiness with no open blockers.
2. **Configure.** Execute the final decommissions in dependency order (R8), each behind change control
   and rollback (R11).
3. **Pilot/Validate.** Confirm each retirement caused no production impact; run the final tests (§05).
   **Decommission gate** per remaining candidate.
4. **Expand/Sustain.** Reconcile realized savings against `Consolidation Cost Model – Platform – Run`;
   confirm the coexistence footprint is zero (or the retained exceptions are the only remainder); hand
   the estate to the operating model (Part B).

---

## Part D — Transition to run

Once the roadmap waves pass:

1. Confirm all wave gates and decommission gates PASS (`GWCONSOL-Report.ps1` shows decommission
   readiness/progress with no open blockers and realized savings on track).
2. Hand the consolidated estate to the operating model (Part B): roles assigned, KPI dashboard live,
   review cadence scheduled.
3. Keep the four strategy artifacts version-controlled; any change (a new system entering the estate, a
   retained exception being revisited) goes through the estate/cost review and updates
   `Consolidation Estate Map – Platform – Design` / `Consolidation Cost Model – Platform – Run`.

---

### Order of operations

`Strategy artifacts (A) → Operating & cost model (B) → Wave 0 Baseline → Wave 1 Collaboration →
Wave 2 AI → Wave 3 Identity & Management → Wave 4 Decommission & Sustain → Run (D)` — each wave gated by
its pilot, each legacy system retired only when its coexistence-exit criteria pass.
