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
