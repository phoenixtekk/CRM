# Collaboration & AI Platform Consolidation Strategy & Roadmap

> **Version 1.0.0** · Category: Google · Solution code: GWCONSOL

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Collaboration & AI Platform Consolidation Strategy & Roadmap

## The situation

Most organizations that set out to transform their collaboration and AI platform do not finish the
job — they stall in **permanent coexistence**. The migration to the new platform "succeeds," but the
old one is never turned off. A legacy mailbox stays "just in case," a Teams tenant keeps a handful of
channels, a SharePoint site backs one integration nobody wants to touch, and the old AI/Copilot
licences renew on autopilot. The result is a business paying for **two ecosystems forever**: double the
licences, double the contracts, double the identity and management surfaces, double the attack surface,
and double the operational load — with no end date and no owner empowered to end it. Nobody can answer
the simple question: *are we done with the old platform yet, and if not, what is blocking retirement?*

The remedy is not another migration. It is a **consolidation strategy and roadmap** that treats the
move off legacy as a first-class, gated program — with a ratified **target platform**, a
**current-vs-target estate map**, a **sequenced roadmap**, explicit **coexistence-exit criteria** and
**decommission gates** for every legacy system, and a **sustainability/cost model** that proves the
consolidation pays for itself.

## The solution

This strategy delivers exactly that — a repeatable, vendor-aligned plan to converge a two-ecosystem
collaboration-and-AI estate onto **one supportable platform (Google Workspace + Gemini)** and retire
the legacy Microsoft systems deliberately:

- **A consolidation strategy** — the target platform, what retires, and *why* (sustainability,
  security, cost efficiency).
- **A current-vs-target estate map** — the collaboration + AI estate (Microsoft, Google, third-party)
  mapped to the target, with redundancy and decommission candidates surfaced.
- **A consolidation roadmap** — waves that move the estate off legacy in dependency order, each with a
  decommission gate and coexistence-exit criteria so coexistence *ends* on a schedule.
- **A sustainability & cost model** — the run-rate baseline of running both ecosystems and the savings
  realized as each legacy system retires.

These are bound together by a **target operating model** that names who runs the consolidated platform,
who signs each decommission, and how progress and savings are measured — delivered through waves proven
on a **pilot** before any expansion, and gated so **no legacy system is retired until its exit criteria
pass.**

## What you get

- A plain-language **Solution Overview** of the consolidation model and *why* it beats permanent
  coexistence.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (target-platform
  decision and tenant, source Microsoft 365 / Entra access, estate and contract data, executive
  decommission authority).
- An **Implementation Guide** that names the **strategy**, the **estate map**, the **roadmap waves**,
  the **cost model**, and the **operating-model roles**, then walks Assess → Configure → Pilot →
  Validate → Expand with a decommission gate per legacy system.
- Five **PowerShell scripts** for estate/redundancy discovery, target-state conformance validation, a
  consolidation/cost-savings and decommission-readiness report, safe remediation of readiness gaps, and
  a wave-scope group builder.
- **Testing** and **Troubleshooting** guides with pass/fail gates, plus field-proven **Best Practices**
  for cost efficiency and long-term platform sustainability.

## The standard deployment model

**Assess → Configure → Pilot → Validate → Expand** — with a hard **decommission gate** (coexistence-exit
criteria) before any legacy system is retired.

## The outcome

One consolidated collaboration + AI platform — legacy Microsoft systems retired on a deliberate schedule
against written coexistence-exit criteria — delivering sustainability, security, and cost efficiency,
with a named operating model, a measurable cost model, and a coexistence footprint that trends to zero
instead of running two platforms forever.


---


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


---


# 2. Requirements Guide — Collaboration & AI Platform Consolidation Strategy & Roadmap

Verify **every** requirement before mapping the estate or committing a wave. Each entry is structured
as **Description · Why · Verify · Implement-if-missing.** **Never assume a prerequisite exists.**
Category-wide prerequisites (Google Workspace/Cloud Identity tenant, source Microsoft 365 / Entra
environment, DNS control, identity source of truth, pilot scope, security/governance stakeholders) are
in `global-requirements-google.md`; this guide adds the requirements specific to a *consolidation
strategy* engagement and numbers them R1–R12.

> **Naming convention (mandatory, reused verbatim throughout):** every artifact, wave, role, and group
> is named `<Purpose> – <Scope> – <Stage>`, e.g. `Consolidation Roadmap – Platform – Program`. Stage is
> `Design` (a strategy artifact), `Program` (a roadmap/cross-cutting item), `Pilot` / `Broad` (a
> rollout scope), or `Run` (an operating-model/cost item). The canonical names introduced here are
> reused in the Implementation, Testing, and Troubleshooting guides.

> **Vendor note:** the **Google Admin console** and the **Microsoft / Entra** sides are named at
> current detail from the vendors' public documentation. **Gemini Enterprise** capabilities in preview
> or rolling out are **cited or flagged "verify in your tenant"** — never invented. **Third-party
> enterprise-app internals** are deferred to their own vendor docs.

> **Gating prerequisites:** R1 (target platform decided + tenant) and R2 (executive sponsorship for
> decommission authority) are **hard gates** — no legacy system is decommissioned, and no wave commits
> to retirement, until both are satisfied.

---

## R1. A decided target platform and a provisioned target tenant  *(GATING)*

- **Description:** An executive-ratified decision that **Google Workspace + Gemini is the target
  collaboration-and-AI platform**, and a provisioned target Google Workspace / Cloud Identity tenant
  with the editions/licensing the target state assumes.
- **Why:** Consolidation is meaningless without a single, agreed target; every decommission decision
  justifies itself against the target platform. Ambiguity here is what produces permanent coexistence.
- **Verify:** Confirm a documented target-platform decision (`Consolidation Strategy – Platform –
  Design`) and sign in to **admin.google.com** as a super-admin to confirm the target tenant and
  editions (global requirement 1).
- **Implement-if-missing:** Ratify the target-platform decision at the executive level and provision
  the target tenant/licences before committing any wave to retirement.

## R2. Executive sponsorship with decommission authority  *(GATING)*

- **Description:** An executive sponsor (`Consolidation Sponsor – Program – Run`) and a named program
  owner (`Consolidation Owner – Platform – Run`) with the authority to **approve legacy-system
  decommissions** and to end coexistence on a schedule.
- **Why:** Retiring a legacy mail/chat/files/AI system is a business decision with organizational blast
  radius. Without an owner empowered to sign the decommission gates, coexistence never ends — systems
  stay "just in case." This is a program/operating-model requirement, not a technical one.
- **Verify:** Confirm a documented sponsor and program owner with decommission-approval authority and a
  budget/decision mandate over the roadmap.
- **Implement-if-missing:** Secure executive sponsorship and assign the program owner before any wave;
  record both in the operating model (§03).

## R3. Administrative access to the source Microsoft 365 / Entra environment

- **Description:** Administrative (read at minimum; the least-privilege roles each migration names for
  execution) access to the source **Microsoft 365** tenant and **Microsoft Entra ID**.
- **Why:** The estate map and every decommission-readiness check read from the Microsoft side; the
  decommissions themselves change it. Consolidation cannot be sequenced or gated without visibility
  into what is running there (global requirement 2).
- **Verify:** Confirm access to the M365 admin center and the Entra admin center with the required
  role. Run `GWCONSOL-Discovery.ps1` (read-only) to confirm Graph read access to the estate.
- **Implement-if-missing:** Obtain the role from the M365/Entra tenant owner; for discovery, a
  global-reader / read-only admin is sufficient.

## R4. A current-state estate inventory (the consolidation baseline)

- **Description:** An inventory of the **collaboration + AI estate** the strategy must account for:
  Microsoft mail/Teams/SharePoint-OneDrive/Copilot, the Google target capabilities, third-party
  collaboration/AI apps, and the identity/licensing/contract surfaces behind them.
- **Why:** You cannot map current-to-target, identify redundancy, or sequence decommissions without a
  baseline; it drives the estate map, the cost model, and the roadmap sequencing.
- **Verify:** Confirm a baseline exists (output of `GWCONSOL-Discovery.ps1` — a read-only inventory of
  the discoverable Microsoft estate) plus manually captured third-party/contract context, reviewed by
  the program owner.
- **Implement-if-missing:** Run `GWCONSOL-Discovery.ps1` (read-only) and capture non-discoverable
  context (third-party apps, contract terms/renewals) manually into the baseline.

## R5. The named strategy artifacts exist (design deliverables)

- **Description:** The four core artifacts are authored and version-controlled: the consolidation
  strategy, the estate map, the consolidation roadmap, and the sustainability/cost model.
- **Why:** These are the deliverables the entire program executes against; without them, consolidation
  degrades back into an undocumented hope that coexistence will end on its own.
- **Verify:** Confirm `Consolidation Strategy – Platform – Design`, `Consolidation Estate Map –
  Platform – Design`, `Consolidation Roadmap – Platform – Program`, and `Consolidation Cost Model –
  Platform – Run` exist and are approved.
- **Implement-if-missing:** Produce them in the Configure phase (§03) following the templates and the
  naming convention; have the program owner and sponsor approve them.

## R6. Coexistence-exit criteria defined per legacy system

- **Description:** For **every** legacy system on the decommission path, a documented set of
  **coexistence-exit criteria** — the objective conditions (data migrated + verified, no active
  users/dependencies remaining, target capability validated, rollback window elapsed) that must be
  true before it is turned off.
- **Why:** A decommission gate with no written criteria is a guess. Exit criteria are what turn "we
  think we're done with the old system" into a defensible, evidence-based retirement.
- **Verify:** Confirm each decommission candidate in the estate map has recorded exit criteria in the
  roadmap (`Consolidation Roadmap – Platform – Program`). `GWCONSOL-Validation.ps1` reports the
  discoverable conformance signals behind them.
- **Implement-if-missing:** Author the exit criteria per system as part of the roadmap before any
  decommission gate is scheduled.

## R7. Consolidation-wave scope groups (Entra security groups)

- **Description:** Named Entra security groups that scope each consolidation wave and its pilot, e.g.
  `Consolidation Wave Scope – Collab – Pilot`, `Consolidation Wave Scope – Collab – Broad`, and
  equivalents per wave.
- **Why:** Waved consolidation and the pilot gate depend on being able to target exactly the right
  users per wave; identity-driven sequencing and coexistence tracking need these groups to exist
  (global requirement 5).
- **Verify:** Entra → **Groups**; confirm the per-wave pilot/broad groups exist (or run
  `GWCONSOL-Validation.ps1`).
- **Implement-if-missing:** Build the groups with `GWCONSOL-Set-ScopeTargeting.ps1` (defaults to
  `-WhatIf`; re-run with `-Apply` to create), named per the convention.

## R8. Dependency map for the legacy systems (sequencing input)

- **Description:** A map of the **dependencies** each legacy system carries — who/what still relies on
  it (integrations, service accounts, shared mailboxes, SharePoint-backed apps, Copilot-embedded
  workflows) — so retirement order respects real coupling.
- **Why:** Decommissioning a system that something still depends on breaks production. Sequencing must
  retire systems in dependency order; the exit criteria depend on knowing there are no live
  dependencies left.
- **Verify:** Confirm a dependency map exists per decommission candidate, feeding the roadmap
  sequencing. `GWCONSOL-Report.ps1` surfaces the discoverable dependency/usage signals.
- **Implement-if-missing:** Build the dependency map during Assess; record blocking dependencies as
  exit-criteria items so a system is not gated for retirement while a dependency is live.

## R9. The sustainability & cost baseline

- **Description:** A documented **run-rate baseline** of the current cost of operating *both*
  ecosystems — duplicate licences, contracts, operations, and support — plus the sustainability inputs
  (operational load, patch/audit scope) the model tracks.
- **Why:** The consolidation business case is the savings; without a baseline there is nothing to
  measure realized savings against, and the sponsor cannot see the program paying for itself.
- **Verify:** Confirm a baseline cost/sustainability sheet exists as `Consolidation Cost Model –
  Platform – Run`. `GWCONSOL-Report.ps1` merges the operator-maintained cost inputs with live
  licence/usage signals.
- **Implement-if-missing:** Assemble the baseline from licensing, contract, and operations data during
  Wave 0; tie each line to the legacy system whose retirement removes it.

## R10. Data-governance, eDiscovery & compliance sign-off for decommission

- **Description:** Engagement with the **legal/eDiscovery, records-retention, and data-governance**
  stakeholders whose policies gate turning a legacy system off (retention holds, eDiscovery obligations,
  regulatory data-residency).
- **Why:** A legacy system cannot be decommissioned if it still holds data under legal hold or a
  retention obligation. Governance sign-off is a mandatory exit-criterion, not an afterthought (global
  requirement 6).
- **Verify:** Confirm the applicable retention/eDiscovery obligations and named approvers per
  decommission candidate; confirm no active hold blocks retirement.
- **Implement-if-missing:** Identify the owners and obtain the retention/eDiscovery clearance as an
  explicit exit-criterion before any decommission gate.

## R11. Change control, rollback, and a comms plan (per wave / per decommission)

- **Description:** An approved change window, a documented rollback (keep the legacy system warm /
  restore access / reverse the cutover), and a user-comms plan — for **each** wave cutover and **each**
  decommission.
- **Why:** Every decommission is irreversible-by-intent and changes how users work. Operational safety
  requires approved windows and a tested back-out until the exit criteria are provably met.
- **Verify:** Confirm an approved change record and a written rollback per planned wave/decommission,
  plus a comms template.
- **Implement-if-missing:** Establish the change/comms process; author per-decommission rollback
  runbooks (covered in Best Practices §07).

## R12. KPI baseline + operating-model owners (for the run phase)

- **Description:** A baseline of the operating-model KPIs (coexistence footprint, decommission
  progress, realized savings, target-state conformance, licence reduction) and the named
  operating-model roles assigned.
- **Why:** A consolidated platform that nobody measures or owns drifts back toward sprawl; the
  operating model (`Consolidation Operating Model – Platform – Run`) needs a starting baseline and
  named owners to keep coexistence retiring and savings realized.
- **Verify:** Confirm baseline KPI values (from `GWCONSOL-Report.ps1` plus manual inputs) and that the
  operating-model roles (§03) are assigned.
- **Implement-if-missing:** Capture the KPI baseline early (during Wave 0) and assign the
  operating-model roles before the first decommission.

---
## Checklist

- [ ] **(GATING)** Target platform decided + target tenant provisioned — `GWCONSOL-Discovery.ps1`
- [ ] **(GATING)** Executive sponsor + program owner with decommission authority
- [ ] Source Microsoft 365 / Entra access confirmed — `GWCONSOL-Discovery.ps1`
- [ ] Current-state collaboration + AI estate baseline captured
- [ ] Strategy, estate map, roadmap, and cost model authored & approved
- [ ] Coexistence-exit criteria defined per legacy system
- [ ] Per-wave pilot/broad scope groups — `GWCONSOL-Set-ScopeTargeting.ps1`
- [ ] Dependency map per decommission candidate — `GWCONSOL-Report.ps1`
- [ ] Sustainability & cost baseline captured — `GWCONSOL-Report.ps1`
- [ ] Data-governance / eDiscovery decommission sign-off obtained
- [ ] Per-wave / per-decommission change control, rollback, comms plan
- [ ] KPI baseline captured + operating-model roles assigned — `GWCONSOL-Report.ps1`


---


# Global Requirements — Google Workspace & Gemini Solutions

These requirements apply to **every** solution in the **Google** category. They are the common
foundation each Google Workspace / Gemini solution assumes is already in place (or stands up as part
of its own Requirements section). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every Google solution).** The **Google Admin console**
> (admin.google.com), **Google Cloud / Cloud Identity**, and the **Microsoft / Entra** sides are
> authored at exact, current click-by-click detail from the vendors' public documentation. **Gemini
> Enterprise** capabilities that are in preview or rolling out are **cited or flagged "verify in your
> tenant"** — never invented. **Third-party migration tools** (e.g. for mail/Drive/Chat data movement)
> and **third-party enterprise apps** (ServiceNow, SAP, Databricks, etc.) are integrated at the
> pattern/architectural level; their internal console steps are deferred to the vendor's own docs.

## 1. Google Workspace / Cloud Identity tenant
- **Description:** A provisioned Google Workspace (or Cloud Identity) tenant with a **super-admin**
  account for configuration, and the appropriate Workspace edition/licensing for the capability in
  scope (e.g. Enterprise Plus for Vault/CAA/DLP, Gemini/AI add-on where required).
- **Why required:** All configuration, policy, and API work is performed against this tenant.
- **How to verify:** Sign in to **admin.google.com** as a super-admin; confirm edition and license
  counts under **Billing / Subscriptions**.
- **How to implement if missing:** Provision the tenant and licenses through Google or an authorized
  reseller before starting.

## 2. Source Microsoft 365 / Entra environment (for migration & coexistence)
- **Description:** For migration/coexistence/identity solutions, administrative access to the source
  **Microsoft 365** tenant and **Microsoft Entra ID** (Global Administrator or the least-privilege
  roles the solution names).
- **Why required:** Migration, directory sync, SSO federation, and coexistence read from and change
  the Microsoft side.
- **How to verify:** Confirm access to the M365 admin center and the Entra admin center with the
  required role.
- **How to implement if missing:** Obtain the role from the M365/Entra tenant owner.

## 3. DNS control for the routed domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF, DKIM, DMARC, TXT, CNAME) for the
  domains being migrated, coexisting, or verified.
- **Why required:** Domain verification, mail routing/coexistence, and authentication all depend on
  DNS changes.
- **How to verify:** Confirm access to the authoritative DNS zone for each domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow changes are high-impact).

## 4. Identity & provisioning source of truth
- **Description:** A defined **identity source of truth** (on-prem AD, Entra ID, or an HR/IGA system)
  and the sync mechanism (e.g. **Google Cloud Directory Sync (GCDS)** or SCIM-based provisioning).
- **Why required:** Consistent users/groups across ecosystems underpin SSO, licensing, and access.
- **How to verify:** Confirm which directory is authoritative and how objects flow into Google.
- **How to implement if missing:** Define the source of truth and provisioning model before configuring
  SSO or migrating.

## 5. A pilot scope (OU / group) and change control
- **Description:** A **pilot organizational unit or group** to validate on before fleet-wide rollout,
  and a **change-control** process for production changes (especially mail flow, DNS, identity, and DLP).
- **Why required:** Every solution follows an **Assess → Configure → Pilot → Validate → Expand** model;
  the pilot proves the design and change control protects production.
- **How to verify:** Confirm a named pilot OU/group exists and a change window/approval path is available.
- **How to implement if missing:** Create a pilot OU/group and agree the change-control process with the
  owners before making production changes.

## 6. Security, compliance & governance stakeholders
- **Description:** Engagement with the **security (CISO), legal/eDiscovery, and data-governance**
  stakeholders whose policies the configuration must satisfy (DLP, retention, Vault/Purview, and any
  regulatory regime such as ITAR/DFARS/Assured Controls where applicable).
- **Why required:** Data governance, eDiscovery, DLP, and regulated-workload settings must align to
  enterprise policy and legal requirements, not just technical defaults.
- **How to verify:** Confirm the applicable policies and named stakeholders/approvers.
- **How to implement if missing:** Identify the owners and obtain the policy/compliance requirements
  before configuring governance controls.

*The deployment model across every Google solution is the same: **Assess → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback for production changes.*


---


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


---


# 5. Testing & Acceptance — Collaboration & AI Platform Consolidation Strategy & Roadmap

Testing is organized by wave, each test with an explicit **PASS/FAIL gate**. Every wave has a **pilot
acceptance gate** (before it expands from pilot to broad scope) and, crucially, a **decommission gate**
per legacy system — the combined **coexistence-exit criteria** that must PASS before any legacy system
is retired (Implementation §03, Part C). **No wave expands until its pilot gate is PASS; no legacy
system is decommissioned until its decommission gate is PASS.**

> Run `GWCONSOL-Validation.ps1` for the scripted target-state conformance checks and
> `GWCONSOL-Report.ps1` for the cost/savings + decommission-readiness report; the manual gates below are
> operator-verified with the estate map, dependency map, and governance clearance. Record results
> against the wave/system, e.g. `Decommission Results – Exchange – Collab`.

---

## Group 0 — Strategy & operating-model readiness (run once, before Wave 0 expands)

**T0.1 — Strategy artifacts exist.** `Consolidation Strategy – Platform – Design`, `Consolidation
Estate Map – Platform – Design`, `Consolidation Roadmap – Platform – Program`, and `Consolidation Cost
Model – Platform – Run` are authored and approved (R5).
- PASS: all four approved. FAIL: any missing/unapproved.

**T0.2 — Operating model + cost baseline defined.** Roles in `Consolidation Operating Model – Platform –
Run` are assigned and the KPI + cost baseline is captured (R2, R9, R12); `GWCONSOL-Report.ps1` produces
a baseline.
- PASS: roles assigned + baseline captured. FAIL: no owner or no baseline.

**T0.3 — Scope groups present.** Per-wave pilot/broad groups exist (R7); `GWCONSOL-Validation.ps1`
confirms.
- PASS: groups present and correctly named. FAIL: missing/misnamed.

**T0.4 — Exit criteria defined per candidate.** Every decommission candidate in the estate map has
recorded coexistence-exit criteria and a dependency order (R6, R8).
- PASS: all candidates have exit criteria + dependency order. FAIL: any candidate without.

**Readiness gate:** T0.1–T0.4 PASS before Wave 0 expands.

---

## Group 1 — Wave 1: Collaboration Consolidation

**T1.1 — Pilot migrated & verified.** The `Consolidation Wave Scope – Collab – Pilot` cohort's mail/
files/chat data is migrated to the target and verified.
- PASS: pilot data on target and verified. FAIL: data missing/unverified.

**T1.2 — Target capability validated.** The pilot works entirely on the target collaboration platform.
- PASS: pilot productive on target. FAIL: pilot still dependent on legacy for normal work.

**T1.3 — No residual dependency (per legacy system).** For each legacy collaboration system, no active
users, integrations, or service dependencies remain (R8) for the retired scope.
- PASS: dependency map clear for the scope. FAIL: a live dependency remains.

**T1.4 — Governance clearance.** Retention/eDiscovery obligations are cleared for the system being
retired; no active legal hold blocks decommission (R10).
- PASS: governance sign-off recorded. FAIL: hold/obligation outstanding.

**Collaboration pilot gate:** T1.1–T1.2 PASS before broad expansion.
**Collaboration decommission gate (per system):** T1.1–T1.4 PASS + rollback available (R11) before the
legacy collaboration system is retired.

---

## Group 2 — Wave 2: AI Platform Consolidation

**T2.1 — Target AI validated.** The target AI capability (Gemini) is validated in production for the
`Consolidation Wave Scope – AI – Pilot` cohort. *Preview/rolling-out capabilities are confirmed in-tenant,
not assumed.*
- PASS: target AI works for the pilot's use cases. FAIL: capability unconfirmed/absent.

**T2.2 — No Copilot-embedded dependency.** No workflow in the retired scope still depends on the legacy
Microsoft AI/Copilot surface (R8).
- PASS: no residual Copilot dependency. FAIL: a workflow still depends on it.

**T2.3 — Licence reclaim identified.** The legacy AI/Copilot licences freed by retirement are identified
for reharvest (feeds realized-savings).
- PASS: reclaimable licences identified. FAIL: not quantified.

**AI decommission gate:** T2.1–T2.3 PASS + rollback available (R11) before the legacy AI/Copilot surface
is retired.

---

## Group 3 — Wave 3: Identity & Management Consolidation

**T3.1 — Consolidated model authoritative.** Users/groups/licensing flow correctly from the consolidated
identity/management model for the `Consolidation Wave Scope – Identity – Pilot` cohort.
- PASS: consolidated model authoritative for the pilot. FAIL: still dual-sourced.

**T3.2 — No duplicate-surface dependency.** No service account, sync connector, or management policy in
the retired scope still depends on the duplicate legacy surface (R8).
- PASS: duplicate surface has no live dependency. FAIL: a dependency remains.

**T3.3 — Provisioning integrity.** Joiner/mover/leaver flows work end-to-end on the consolidated model.
- PASS: JML verified on target. FAIL: provisioning breaks.

**Identity/Management decommission gate:** T3.1–T3.3 PASS + rollback available (R11) before a duplicate
identity/management surface is retired.

---

## Group 4 — Wave 4: Decommission & Sustain

**T4.1 — All exit criteria met.** Every remaining decommission candidate's coexistence-exit criteria
(R6) and governance clearance (R10) are PASS; `GWCONSOL-Report.ps1` shows no open blockers.
- PASS: no open exit-criteria blockers. FAIL: any candidate blocked.

**T4.2 — Decommission caused no impact.** Each executed retirement produced no production impact for the
scope.
- PASS: zero post-decommission incidents. FAIL: user-visible breakage.

**T4.3 — Coexistence footprint retired.** The legacy platform footprint is zero, or the only remainder
is the recorded, approved retained-exception set.
- PASS: footprint zero or exceptions-only. FAIL: unretired systems without exception.

**Sustain gate:** T4.1–T4.3 PASS for the program to be declared consolidated.

---

## Group 5 — Cost & operating-model health (ongoing)

**T5.1 — Realized savings tracked.** `GWCONSOL-Report.ps1` shows realized savings against the cost model
as systems retire.
- PASS: savings reported and tracking the projection. FAIL: no measurement / off-model.

**T5.2 — Estate/dependency map current.** The estate map and dependency map are re-confirmed as
migrations complete; no undocumented legacy system remains.
- PASS: maps current. FAIL: stale/undocumented estate.

**Run gate:** T5.1–T5.2 PASS before the program is declared in steady-state run.

---

## Program-level exit (per wave / per decommission)

A wave is **complete** only when its pilot acceptance gate is PASS; a legacy system is **retired** only
when its decommission gate (coexistence-exit criteria) is PASS. Capture results against the wave/system
name (`Decommission Results – <System> – <Wave>`). **No legacy system is decommissioned until its
coexistence-exit criteria pass**, in dependency order (R8), with governance clearance (R10) and change
control + rollback confirmed (R11).


---


# 6. Troubleshooting Guide — Collaboration & AI Platform Consolidation Strategy & Roadmap

Failure modes and fixes, grouped by area. Most consolidation programs stall for a few root causes: **the
target platform was never truly decided**, **a legacy system has no written exit criteria**, **a
decommission was attempted with a live dependency still attached**, or **coexistence was never gated so
it simply never ends**.

> Use `GWCONSOL-Discovery.ps1` / `GWCONSOL-Validation.ps1` (read-only) for current-state and target-state
> conformance, and `GWCONSOL-Report.ps1` for cost/savings + decommission readiness. Use
> `GWCONSOL-Remediation.ps1` (default `-WhatIf`) to preview fixes. **Google Admin / Microsoft-Entra
> console specifics are named from the vendors' public docs; Gemini preview capabilities are verified
> in-tenant** — these fixes name *what* to correct.

---

## A. Target / strategy ambiguity

| Symptom | Cause | Remediation |
|---|---|---|
| Program keeps adding "keep it for now" exceptions | Target platform never executive-ratified; teams hedge | Ratify the target-platform decision at the sponsor level (`Consolidation Strategy – Platform – Design`, R1); every exception must be a recorded retained-exception with a driver, not a default |
| Two teams disagree on what is "target" vs "legacy" | Strategy thesis not stated once and reused | Publish the single thesis (target + what retires + why) and reference it in every wave and gate |
| A decommission decision gets reversed under pushback | No owner with decommission authority | Assign `Consolidation Sponsor – Program – Run` with decommission-approval authority (R2); the gate, not the loudest objector, decides |

## B. Estate mapping / redundancy

| Symptom | Cause | Remediation |
|---|---|---|
| A legacy system surfaces late that nobody had mapped | Estate inventory incomplete | Re-run `GWCONSOL-Discovery.ps1` for the discoverable Microsoft side; capture third-party/contract context manually into `Consolidation Estate Map – Platform – Design` (R4) |
| Redundant systems not being retired | Decommission candidates not flagged in the map | For every system where a target capability does the same job, mark it a decommission candidate and record its duplicate cost (§03 A2) |
| "Retained" systems accumulating with no reason | Retained exceptions not justified/reviewed | Require a driver + review date per retained exception; revisit on the operating-model cadence (Best Practices §07) |

## C. Sequencing / dependencies

| Symptom | Cause | Remediation |
|---|---|---|
| Decommissioning a system broke a production workflow | Retired out of dependency order / a live dependency missed | Build/refresh the dependency map (R8); retire in dependency order; make each blocking dependency an explicit exit-criterion (T1.3/T2.2/T3.2) |
| Wave scope keeps slipping | Cohorts split across waves, extending coexistence | Scope waves to groups who work together (`Consolidation Wave Scope – <Wave> – Pilot/Broad`); keep cohorts intact |
| Underlying migration not ready when the wave needs it | Roadmap sequences a migration engagement that isn't scheduled | Confirm the underlying migration (separate engagement) is scheduled before the wave's Configure; this roadmap *sequences* it, it does not perform it |

## D. Decommission gates / exit criteria

| Symptom | Cause | Remediation |
|---|---|---|
| Nobody is sure whether a system is safe to turn off | No written coexistence-exit criteria | Author exit criteria per candidate (R6): data migrated + verified, no active users/dependencies, target validated, rollback window elapsed, governance cleared |
| A gate "passed" but the system still had active users | Gate decided on optimism, not evidence | Decide the gate on `GWCONSOL-Report.ps1` decommission-readiness output; a gate is PASS only when every exit-criterion is objectively met (§05) |
| Coexistence never ends | No decommission gate wired into the program | Attach a decommission gate to every candidate; the coexistence-footprint KPI must trend to zero, wave by wave |

## E. Cost / savings not materializing

| Symptom | Cause | Remediation |
|---|---|---|
| Consolidation isn't showing savings | System technically retired but licence/contract still billing | Reharvest freed licences promptly (licence-reduction KPI); align decommission with renewal/true-up windows so the contract saving lands (§07) |
| Savings can't be measured | No cost baseline of running both ecosystems | Capture the run-rate baseline (R9) in `Consolidation Cost Model – Platform – Run`; tie each cost line to the system whose retirement removes it |
| Reported savings drift from reality | Realized savings not tracked against the model | Run `GWCONSOL-Report.ps1` on the cadence; reconcile realized vs projected (T5.1) |

## F. Governance / compliance blocking retirement

| Symptom | Cause | Remediation |
|---|---|---|
| Legal blocks a decommission at the last minute | Retention hold / eDiscovery obligation not cleared up front | Make governance clearance an exit-criterion (R10); obtain it *before* the gate is scheduled, not at cutover (T1.4) |
| Uncertainty over where regulated data lives post-retirement | Data-residency not mapped for the target | Confirm target-platform data-residency with the governance stakeholders before retiring the legacy store |

## G. Program / operating-model issues

| Symptom | Cause | Remediation |
|---|---|---|
| Program drifting back toward two-platform sprawl | No owner / artifacts not maintained | Assign `Consolidation Owner – Platform – Run` (R2); keep the four strategy artifacts current as living documents (§07) |
| Progress unclear to leadership | KPIs not measured | Capture the baseline (R12) and keep `GWCONSOL-Report.ps1` live — report coexistence footprint, decommission progress, and realized savings (T5.1) |
| Retained exceptions never revisited | No review cadence | Institute the estate/exception review in the operating model (§03 Part B3); re-justify or retire each exception |

## H. Tooling / script issues

| Symptom | Cause | Remediation |
|---|---|---|
| A script fails to connect to Graph | Microsoft Graph PowerShell module not installed or not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; sign in with the required read scopes when prompted |
| Remediation made no change | `-WhatIf` is the default (by design) | Re-run with `-Apply` once the preview is correct |
| Report shows licence/cost as 'n/a' | No operator-maintained cost/status CSV, or Graph sizing unavailable | Provide the status/cost CSV template `GWCONSOL-Report.ps1` writes; confirm Graph read access for live licence/group sizing |
| Gemini capability assumed but absent | A preview/rolling-out capability was treated as GA | Verify the capability in your tenant (vendor note); if absent, record it as a risk/assumption and do not gate a decommission on it (T2.1) |

---

## When to escalate

If the target platform is ratified, the estate and dependency maps are current, a candidate's
coexistence-exit criteria are written and objectively met, governance is cleared, and a decommission
still cannot proceed safely — collect the `GWCONSOL-Discovery.ps1` and `GWCONSOL-Validation.ps1` output
and the relevant `Decommission Results – <System> – <Wave>`, and escalate to the
`Consolidation Sponsor – Program – Run` with the specific blocking exit-criterion. For underlying
migration mechanics, refer to that migration engagement's own runbook; for Google/Microsoft product
behavior, reference the vendor's official documentation.


---


# 7. Best Practices — Collaboration & AI Platform Consolidation Strategy & Roadmap

Program-grade practices for consolidating a two-ecosystem collaboration-and-AI estate onto one
platform. These reduce risk, prevent the slide into permanent coexistence, and keep the consolidation
paying for itself.

## Strategy discipline

- **Decide the target once, ratify it high.** Executive-ratify that Google Workspace + Gemini is the
  target platform (`Consolidation Strategy – Platform – Design`, R1) before mapping or committing a
  wave. Ambiguity about the target is the single biggest cause of permanent coexistence.
- **Map the estate before you sequence.** Author `Consolidation Estate Map – Platform – Design` first —
  it is what surfaces the redundant systems and the decommission candidates. You cannot retire what you
  have not mapped.
- **Name everything with the convention.** `<Purpose> – <Scope> – <Stage>`, reused verbatim across
  artifacts, waves, roles, groups, and scripts, so discovery, validation, reporting, and the estate map
  cross-reference cleanly.
- **Justify every decommission against the three drivers.** Sustainability, security, cost efficiency —
  state which one(s) each retirement serves. A system with no driver for retiring is a retained
  exception, recorded as such.

## Ending coexistence (the whole point)

- **Coexistence is a phase, not a destination.** Write it into the strategy: every legacy system retires
  on a schedule when its exit criteria pass. A transformation that never decommissions has failed even
  if every migration "succeeded."
- **Every legacy system gets written exit criteria (R6).** Data migrated + verified, no active
  users/dependencies, target capability validated in production, governance cleared, rollback window
  elapsed. A decommission gate with no written criteria is a guess.
- **Gate the retirement, don't just hope.** No legacy system is turned off until its decommission gate
  (§05) is PASS. `GWCONSOL-Report.ps1` produces the decommission-readiness view so the gate is decided
  on evidence.
- **Retire in dependency order (R8).** Map what still depends on each system; retire in the order that
  respects real coupling. Decommissioning something a live workflow needs is how consolidation breaks
  production.

## Sequencing & the wave gate

- **Consolidate in waves, never big-bang.** Wave 0 baseline → Collaboration → AI → Identity &
  Management → Decommission & Sustain. Each wave moves a bounded slice off legacy.
- **The pilot gate is non-negotiable.** No wave expands to broad scope until its pilot acceptance gate
  (§05) is PASS. A bounded pilot catches breakage before the fleet feels it.
- **Keep cohorts intact in a wave scope.** Scope a wave to groups of users who work together so the
  coexistence window between platforms is short for any given team.
- **Run the per-wave preflight.** `GWCONSOL-Validation.ps1` (target-state conformance) and
  `GWCONSOL-Report.ps1` (cost/savings + decommission readiness) before every Configure; preview fixes
  with `GWCONSOL-Remediation.ps1` (default `-WhatIf`).

## Cost efficiency

- **Baseline the cost of running both (R9).** Duplicate licences, contracts, operations, support — the
  full run-rate of coexistence. Without the baseline you cannot show the program paying for itself.
- **Tie every saving to a retirement.** Each cost line in `Consolidation Cost Model – Platform – Run`
  maps to the legacy system whose decommission removes it, so savings land on the roadmap schedule, not
  in a vague "eventually."
- **Reharvest licences as systems retire.** Duplicate M365/Copilot licences freed by decommission are
  reclaimed promptly (licence-reduction KPI) — a licence left assigned to a retired system is pure waste.
- **Mind the contracts, not just the consoles.** A system can be technically retired while its contract
  keeps billing; align decommission timing with renewal/true-up windows to capture the saving.

## Sustainability & long-term platform health

- **Fewer systems is the sustainability win.** Every retired legacy system removes operational load,
  patch burden, audit scope, and a skill set to maintain. Track the shrinking footprint, not just the
  dollar savings.
- **One governed estate beats two weak ones.** Consolidation removes the "weaker of two" security
  posture; the target platform is the single governed surface once legacy retires.
- **Keep the artifacts current as living documents.** The strategy, estate map, roadmap, and cost model
  are updated with every completed migration and every retained-exception decision — not at the end.
- **Revisit retained exceptions on a cadence.** A system kept "for now" is a future decommission
  candidate; re-justify or retire each retained exception on the operating-model cadence so coexistence
  keeps shrinking.

## Change control & rollback

- **Approved window + tested back-out per decommission (R11).** Every retirement is
  irreversible-by-intent; keep the legacy system warm and the rollback ready until the exit criteria are
  provably met.
- **Governance clears before the gate (R10).** Retention holds and eDiscovery obligations are an
  exit-criterion, not an afterthought. A system under legal hold cannot be retired, full stop.
- **Communicate each cutover.** A short note per wave/decommission — what changes, the new experience,
  who to contact — sharply reduces tickets and resistance.

## Operating model

- **Assign the roles before you retire anything.** `Consolidation Sponsor` (with decommission
  authority), `Consolidation Owner`, `Estate Analyst`, `Migration Coordinator`, `Governance Liaison` —
  a consolidation with no empowered owner never ends coexistence.
- **Measure what matters.** Keep the KPI dashboard (`GWCONSOL-Report.ps1`) live: coexistence footprint,
  decommission progress, realized savings, licence reduction, target-state conformance, open
  exit-criteria blockers.
- **Report progress as convergence.** Leadership should see the coexistence footprint trending to zero
  and realized savings tracking the model — that is what proves the consolidation is working.


---


# 8. Deliverables Summary — Collaboration & AI Platform Consolidation Strategy & Roadmap

This package is a flagship, enterprise-grade strategy kit for consolidating a two-ecosystem
collaboration-and-AI estate onto one supportable platform. It contains the documentation blueprint,
five PowerShell tools, and a hero image. It delivers a consolidation strategy, a current-vs-target
estate map, a phased consolidation roadmap with decommission gates and coexistence-exit criteria, a
sustainability/cost model, and a target operating model — plus the read-only tooling to discover,
validate, report, remediate, and scope the consolidation.

## Documentation

| File | What it covers |
|---|---|
| `executive-summary.md` | One-page business case and outcomes for sponsors/leadership. |
| `01-solution-overview.md` | What the strategy is, *why* permanent coexistence fails, the target-state thesis (what retires and why — sustainability/security/cost), the estate-mapping method, the consolidation roadmap, coexistence-exit criteria and decommission gates, the sustainability/cost model, benefits, and honest limitations. |
| `02-requirements.md` | R1–R12 prerequisites (Description / Why / Verify / Implement-if-missing), including the GATING target-platform-decision and executive-decommission-authority requirements, plus a checklist. |
| `global-requirements-google.md` | Category-wide Google prerequisites (Workspace/Cloud Identity tenant, source M365/Entra, DNS control, identity source of truth, pilot scope, security/governance stakeholders), published once. |
| `03-implementation.md` | The program runbook: strategy artifacts (strategy, estate map, roadmap, cost model), the target operating model (roles/RACI, KPIs, cadence), and the consolidation roadmap (Wave 0 Baseline → Collaboration → AI → Identity & Management → Decommission & Sustain) with a decommission gate per legacy system. |
| `05-testing.md` | Per-wave numbered tests with PASS/FAIL gates, a pilot acceptance gate per wave, and a **decommission gate** (coexistence-exit criteria) per legacy system, plus strategy-readiness and cost/operating-model-health gates. |
| `06-troubleshooting.md` | Field failure modes and fixes across strategy/target ambiguity, estate mapping, sequencing/dependencies, decommission gates & exit criteria, cost/savings, governance, and tooling. |
| `07-best-practices.md` | Field-proven practices: strategy discipline, ending coexistence, sequencing & the wave gate, cost efficiency, sustainability & platform health, change control, and the operating model. |

> **Vendor scope:** the exact **Google Admin console** and **Microsoft/Entra** configuration is named
> at current detail from the vendors' public documentation; **Gemini Enterprise** preview/rolling-out
> capabilities are **cited or flagged "verify in your tenant"**. The **click-by-click of each underlying
> migration** (mail/Drive/Chat/identity) is a separate engagement this roadmap *sequences and gates* —
> this kit defines *when a legacy system may be retired*, not how each migration is performed.

## PowerShell scripts

All scripts carry a header with **PURPOSE / HOW TO RUN / EXPECTED RESULTS** and a neutral, white-label
note. Current-state estate discovery uses **Microsoft Graph PowerShell**; Discovery, Validation, and
Report are strictly **read-only**; Remediation and Set-ScopeTargeting default to `-WhatIf`.

| Script | What it does |
|---|---|
| `scripts\GWCONSOL-Discovery.ps1` | **Read-only estate/redundancy inventory.** Uses Microsoft Graph to capture the consolidation baseline (R4): tenant identity, the wave-scope targeting groups, mail/SharePoint-OneDrive/Teams and Copilot/AI licence footprint, managed devices, and notes for non-discoverable third-party collaboration/AI apps and contracts. The design baseline for the estate map. |
| `scripts\GWCONSOL-Validation.ps1` | **Target-state conformance validation (read-only).** Checks the consolidation readiness signals per wave — target-platform decision recorded, per-wave scope groups present and correctly named (R7), residual legacy-licence footprint, and coexistence signals — and emits PASS/FAIL per check for the readiness and decommission gates. |
| `scripts\GWCONSOL-Report.ps1` | **Consolidation/cost-savings + decommission-readiness report (read-only).** Produces the operating-model KPI view (coexistence footprint, decommission progress, realized savings, licence reduction) and a decommission-readiness matrix per candidate, merging an operator-maintained cost/status CSV with live Graph licence/group signals, as a CSV plus a console summary — the run dashboard. |
| `scripts\GWCONSOL-Remediation.ps1` | **Safe remediation of readiness gaps.** Fixes the identity-side gaps validation/report surface (create missing wave-scope groups, add pilot members). Runs `-WhatIf` by default; requires `-Apply` to change anything. |
| `scripts\GWCONSOL-Set-ScopeTargeting.ps1` | **Wave-scope group builder.** Creates/maintains the named Entra security groups that scope each consolidation wave and its pilot (`Consolidation Wave Scope – <Wave> – Pilot` / `– Broad`), per the naming convention. Defaults to `-WhatIf`. |

## Hero image

| File | Purpose |
|---|---|
| `GWCONSOL-hero.png` | Listing/marketing hero image for the solution. |

## The Consolidation-Roadmap document template (outline)

The primary deliverable an architect produces from this kit is the **Consolidation Roadmap** document
(`Consolidation Roadmap – Platform – Program`). Author it to this outline:

1. **Executive summary** — the consolidation thesis and the target-state decision (R1); the headline
   savings and end-of-coexistence commitment.
2. **Target-state definition** — the target platform (Google Workspace + Gemini), what retires, and the
   three drivers (sustainability, security, cost efficiency) per decision.
3. **Current-vs-target estate map** — the inventory mapped to the target; each system marked *replaced /
   retired / retained*; the decommission-candidate list with duplicate cost.
4. **Dependency map & sequencing** — what depends on each legacy system; the dependency-ordered
   retirement sequence.
5. **Consolidation waves** — Wave 0 → Collaboration → AI → Identity & Management → Decommission & Sustain,
   each with entry criteria, scope groups, pilot scope, and the legacy systems it retires.
6. **Coexistence-exit criteria & decommission gates** — per legacy system: the objective exit criteria,
   the gate (§05), the named approver, the governance clearance (R10), and the rollback (R11).
7. **Sustainability & cost model** — the run-rate baseline, the projected savings tied to each wave, and
   the shrinking operational/patch/audit footprint.
8. **Operating model** — roles/RACI, KPIs, and the estate/decommission/cost review cadence.
9. **Risks, retained exceptions & assumptions** — including any Gemini capability flagged "verify in
   your tenant" the target state depends on.

## What the buyer receives

- This strategy as a branded **Word** document and **PDF** (`GWCONSOL-Solution.pdf`).
- All five **PowerShell scripts** in a single ZIP (`GWCONSOL-Scripts.zip`).
- A repeatable consolidation process following the standard model:
  **Assess → Configure → Pilot → Validate → Expand**, gated per wave, with a decommission gate per
  legacy system.

> **Naming convention reminder:** artifacts, waves, roles, groups, and script outputs share the standard
> `<Purpose> – <Scope> – <Stage>` (e.g. `Consolidation Wave Scope – Collab – Pilot`) so everything
> cross-references cleanly across discovery, validation, reporting, and the estate map.

## Outcome

One consolidated collaboration + AI platform — legacy Microsoft systems retired on a deliberate schedule
against written coexistence-exit criteria — delivering sustainability, security, and cost efficiency,
with a named operating model, a measurable cost model, and a coexistence footprint that trends to zero.
