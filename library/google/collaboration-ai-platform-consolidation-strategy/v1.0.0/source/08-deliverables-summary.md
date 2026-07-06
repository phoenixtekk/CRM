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
