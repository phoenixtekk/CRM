# 1. Solution Overview — Collaboration & AI Platform Consolidation Strategy & Roadmap

## What this solution is

This is a **long-term platform consolidation strategy and roadmap** — not a migration runbook and not
a single-product configuration. A collaboration-and-AI transformation that stalls in *permanent
coexistence* carries double the cost, double the tools, double the attack surface, and double the
operational burden — forever. This solution defines how an enterprise deliberately converges on **one
supportable platform** instead of running two ecosystems side by side indefinitely: the **target
state**, the **decommission path for the legacy Microsoft systems**, the **sequencing and
dependencies**, the **coexistence-exit criteria**, and the **sustainability/cost model** that proves
the consolidation pays for itself.

Concretely, the strategy produces four durable artifacts that the rest of this package builds and
operates:

1. A named **consolidation strategy** — `Consolidation Strategy – Platform – Design` — the thesis:
   the target platform, what is retired, and *why* (sustainability, security, cost efficiency).
2. A named **current-vs-target estate map** — `Consolidation Estate Map – Platform – Design` — the
   collaboration + AI estate (Microsoft, Google, third-party) mapped to the target, with redundancy
   and decommission candidates identified.
3. A named **consolidation roadmap** — `Consolidation Roadmap – Platform – Program` — a sequence of
   waves that moves the estate off legacy systems, each with dependencies, a decommission gate, and
   coexistence-exit criteria.
4. A named **sustainability & cost model** — `Consolidation Cost Model – Platform – Run` — the
   run-rate baseline, the projected savings as legacy systems retire, and the sustainability posture.

It also defines a **target operating model** — `Consolidation Operating Model – Platform – Run` — with
roles, RACI, and KPIs so the consolidated platform is *run and governed*, not just *reached*.

## Why permanent coexistence fails (the *why*)

A transformation that never finishes converging almost always ends up:

- **Doubly expensive** — two productivity suites, two AI stacks, two identity paths, two support
  contracts, two skill sets. The business pays for both ecosystems every month with no end date.
- **Doubly exposed** — every legacy system left running is attack surface, patch burden, and audit
  scope that the target platform was supposed to eliminate. Security posture is the weaker of the two.
- **Un-decommissionable by accident** — a legacy mailbox, a Teams tenant, a SharePoint site, or a
  Copilot licence quietly acquires "just one" dependency, and nobody can turn it off because the
  exit criteria were never written down.
- **Ungoverned** — no single place answers "are we done with the old platform yet, and if not, what
  is blocking retirement?" — because consolidation was treated as an outcome that would *happen*
  rather than a program that is *sequenced and gated*.

Consolidation fixes this by treating the move off legacy as a **first-class, gated program**: every
legacy system has a named **decommission gate** and explicit **coexistence-exit criteria**, and no
system is retired until its criteria pass. That single shift — from "we migrated, coexistence will
sort itself out" to "each legacy system retires deliberately, on a schedule, when its exit criteria
are met" — is the whole point of this solution.

## The target-state thesis (what consolidates, and why)

The consolidation thesis is stated once and reused everywhere: **Google Workspace + Gemini is the
target collaboration-and-AI platform; the legacy Microsoft collaboration and AI systems are retired on
a deliberate schedule.** The rationale is threefold and is the recurring justification for every
decommission decision:

| Driver | What consolidation delivers |
|---|---|
| **Sustainability** | One platform to run, patch, support, and skill for — not two. Operational load, licence sprawl, and cognitive overhead all fall as legacy retires. |
| **Security** | Every retired legacy system removes attack surface, patch burden, and audit scope. The security posture stops being "the weaker of two" and becomes one governed estate. |
| **Cost efficiency** | Duplicate licences, duplicate contracts, and duplicate operations are eliminated as systems retire — the savings are modeled, not assumed (`Consolidation Cost Model – Platform – Run`). |

The legacy Microsoft systems in scope for the decommission path typically include: **Exchange Online
mailboxes, Teams, SharePoint/OneDrive, and the Microsoft 365 Copilot / AI stack**, along with the
duplicate identity, licensing, and management surfaces that exist only to keep them running. Exactly
which systems retire, in which wave, is the output of the estate map — this section names the *model*,
not a fixed list.

> **Scope honesty:** this solution is the **strategy and roadmap** for consolidation. It *names* the
> target, maps the estate, sequences the waves, and defines the decommission gates and cost model. The
> **execution of any individual migration** (mail, Drive, Chat/Meet, identity) is a separate
> engagement with its own runbook; this roadmap sequences those migrations and defines *when a legacy
> system is allowed to be turned off*, not the click-by-click of each move.

## The estate-mapping method (current vs. target)

You cannot consolidate what you have not mapped. The solution defines a repeatable method to map the
**current** collaboration + AI estate against the **target** platform and surface what is redundant:

- **Inventory the collaboration + AI estate** across Microsoft, Google, and third-party systems (mail,
  files, chat/meetings, AI assistants, identity, and the licences/contracts behind them). The read-only
  `GWCONSOL-Discovery.ps1` inventories the discoverable Microsoft side via Graph; non-discoverable
  context (third-party apps, contracts) is captured manually.
- **Map each system to the target** — is it *replaced by* a target capability, *retired outright*, or
  *retained* (a genuine keep, recorded as an exception)?
- **Flag redundancy** — where a legacy system and a target capability both do the same job, that is a
  **decommission candidate**; the duplicate cost it carries feeds the cost model.

The output is `Consolidation Estate Map – Platform – Design`: the authoritative list of what retires,
what it maps to, and what it costs to keep running.

## The consolidation roadmap (sequencing, gates, exit criteria)

The estate is consolidated in **named waves** (`Consolidation Roadmap – Platform – Program`), each a
deliberate step off legacy. The waves are summarized here and detailed in the Implementation Guide:

- **Wave 0 — Baseline & Strategy** — author the strategy, map the estate, set the cost/sustainability
  baseline, and stand up the operating model. Nothing is retired yet.
- **Wave 1 — Collaboration Consolidation** — sequence the collaboration migrations (mail, files,
  chat/meetings) and retire each legacy collaboration system as its exit criteria pass.
- **Wave 2 — AI Platform Consolidation** — converge the AI stack on the target (Gemini), retiring the
  legacy Microsoft AI/Copilot surface as its exit criteria pass.
- **Wave 3 — Identity & Management Consolidation** — retire the duplicate identity, licensing, and
  management surfaces that existed only to keep the legacy platform running.
- **Wave 4 — Decommission & Sustain** — complete the decommissions, realize the modeled savings, and
  hand the consolidated estate to the operating model.

Each wave runs the standard model **Assess → Configure → Pilot → Validate → Expand**, and **no legacy
system is decommissioned until its decommission gate and coexistence-exit criteria pass** (§05).

## Coexistence-exit criteria and decommission gates

The heart of this solution is the discipline that ends coexistence. For **every** legacy system on the
decommission path, the roadmap records:

- **Coexistence-exit criteria** — the objective conditions that must be true before the legacy system
  is turned off (data fully migrated and verified, no remaining active users/dependencies, target
  capability validated in production, rollback window elapsed).
- **A decommission gate** — an explicit PASS/FAIL gate (§05) that confirms the exit criteria are met,
  with a named approver, before decommission proceeds.
- **A rollback position** — what to do if the gate fails or a dependency surfaces late (keep the
  legacy system warm until the criterion is genuinely met).

`GWCONSOL-Validation.ps1` reports target-state conformance and `GWCONSOL-Report.ps1` produces the
decommission-readiness view, so the gate is decided on evidence, not optimism.

## The sustainability & cost model

Consolidation is justified by what it *saves*, so the savings are modeled, not assumed
(`Consolidation Cost Model – Platform – Run`):

- **Run-rate baseline** — the current cost of running *both* ecosystems (duplicate licences, contracts,
  operations, support).
- **Projected savings** — the run-rate that falls away as each legacy system retires, tied to the
  roadmap waves so savings are realized on a schedule.
- **Sustainability posture** — the operational load, patch/audit scope, and skill footprint that
  shrink as the estate converges on one platform.

`GWCONSOL-Report.ps1` produces the cost-savings and decommission-readiness report so leadership can see
consolidation progress and realized savings against the model.

## Benefits

- **One supportable platform** — collaboration and AI operated as a single, governed estate instead of
  two ecosystems run forever.
- **Coexistence has an end date** — every legacy system has explicit exit criteria and a decommission
  gate, so the program *converges* instead of drifting.
- **Modeled, realized savings** — duplicate cost is quantified and eliminated on a schedule, not hoped
  for.
- **A stronger security posture** — retired legacy systems remove attack surface, patch burden, and
  audit scope.
- **A run model, not just a target** — named roles and KPIs keep the consolidated platform healthy and
  the decommissions honest.

## Honest limitations

- **This is a strategy + roadmap, not a migration execution kit.** It names the target, maps the
  estate, sequences the waves, sets the gates and the cost model — the **click-by-click of each
  migration** (mail/Drive/Chat/identity) is a separate engagement this roadmap *sequences*.
- **It requires real inputs** — a target Google Workspace/Gemini tenant, administrative access to the
  source Microsoft 365 / Entra environment, the estate and contract data, and executive sponsorship
  (see Requirements).
- **Some Gemini Enterprise capabilities are preview / rolling out** — where the target state depends on
  them, they are **cited or flagged "verify in your tenant"**, never invented (see the vendor note).
- **Third-party app internals are deferred** — enterprise apps that integrate with the estate are
  mapped at the pattern level; their console specifics defer to the vendor's own documentation.
- **Decommission is gated, not same-day** — legacy systems retire wave by wave as exit criteria pass,
  behind change control — deliberately, not in a big bang.

## The standard deployment model

This solution follows the **standard deployment model** at two levels: the **program** is delivered in
consolidation waves, and **each wave** internally follows the same lifecycle —

**Assess → Configure → Pilot → Validate → Expand**, with a **decommission gate** (coexistence-exit
criteria, §05) that must pass before any legacy system is retired.
