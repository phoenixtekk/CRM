# 8. Deliverables Summary — SASE / SSE Architecture & Design Blueprint

This package is a flagship, enterprise-grade design kit for building a unified SASE/SSE edge. It
contains the documentation blueprint, five PowerShell tools, and a hero image. It delivers a reference
architecture, a policy model, a phased adoption roadmap, and a target operating model — and the
read-only tooling to discover, validate, report, remediate, and scope the rollout.

## Documentation

| File | What it covers |
|---|---|
| `executive-summary.md` | One-page business case and outcomes for sponsors/leadership. |
| `01-solution-overview.md` | What the blueprint is, *why* piecemeal edge security fails, the capability services (SWG, ZTNA, CASB, SSL inspection, DLP-adjacent), identity as the control plane, the phased roadmap, the operating model, benefits, and honest limitations. |
| `02-requirements.md` | R1–R12 prerequisites (Description / Why / Verify / Implement-if-missing), including the GATING Netskope-tenant/modules and executive-sponsorship requirements, plus a checklist. |
| `global-requirements-network.md` | Category-wide Network prerequisites (Netskope tenant, Entra ID, Intune, admin roles, network/identity fundamentals, pilot group, change control), published once. |
| `03-implementation.md` | The program runbook: design artifacts (reference architecture, policy model, roadmap), the target operating model (roles/RACI, KPIs, cadence), and the phased adoption roadmap (Phase 0 Baseline → SWG → CASB → ZTNA → Data-hook/Optimize) with a pilot-phase gate per phase. |
| `05-testing.md` | Per-phase numbered tests with PASS/FAIL gates and a pilot acceptance gate per phase, plus design-readiness and operating-model-health gates. |
| `06-troubleshooting.md` | Field failure modes and fixes across steering/client, SSL inspection/certificates, identity/policy, CASB, ZTNA/VPN displacement, design/operating-model, and tooling. |
| `07-best-practices.md` | Field-proven practices: design discipline, phasing & the pilot gate, SSL inspection, ZTNA/VPN displacement, CASB, DLP-adjacent scope, change control, and the operating model. |

> **Vendor scope:** the exact **Netskope console** configuration is **deferred to the official Netskope
> documentation and your tenant**. This kit is authored at the architectural and procedural level —
> what to design, in what order, with which named artifacts and gates.

## PowerShell scripts

All scripts carry a header with **PURPOSE / HOW TO RUN / EXPECTED RESULTS** and a neutral, white-label
note. Current-state edge/identity discovery uses **Microsoft Graph PowerShell**; Netskope-module
specifics are flagged and deferred to Netskope's documentation. Discovery, Validation, and Report are
strictly **read-only**; Remediation defaults to `-WhatIf`.

| Script | What it does |
|---|---|
| `scripts\SASE-Discovery.ps1` | **Read-only current-state inventory.** Uses Microsoft Graph to capture the edge/identity baseline (R6): tenant identity, targeting groups, enrolled/compliant devices, conditional-access signals, and notes for non-discoverable third-party SWG/VPN/CASB. The design baseline. |
| `scripts\SASE-Validation.ps1` | **Architecture-readiness validation (read-only).** Checks SSO/identity readiness, the presence and naming of the per-phase targeting groups, device/certificate-trust readiness signals, and emits PASS/FAIL per check for the readiness and per-phase gates. |
| `scripts\SASE-Report.ps1` | **Capability-coverage + gap report (read-only).** Produces the operating-model KPI view and a coverage/gap matrix across the capability services and roadmap phases, as a CSV plus a console summary — the run dashboard. |
| `scripts\SASE-Remediation.ps1` | **Safe remediation of configuration gaps.** Fixes readiness gaps the validation/report surface (e.g. create missing targeting groups, add members, tag device groups). Runs `-WhatIf` by default; requires `-Apply` to change anything. |
| `scripts\SASE-Set-PhaseScopeTargeting.ps1` | **Phase-scope group builder.** Creates/maintains the named Entra security groups that scope each roadmap phase and its pilot (`SASE Phase Scope – <Phase> – Pilot` / `– Broad`), per the naming convention. Defaults to `-WhatIf`. |

## Hero image

| File | Purpose |
|---|---|
| `SASE-hero.png` | Listing/marketing hero image for the solution. |

## What the buyer receives

- This blueprint as a branded **Word** document and **PDF** (`SASE-Solution.pdf`).
- All five **PowerShell scripts** in a single ZIP (`SASE-Scripts.zip`).
- A repeatable design + adoption process following the standard model:
  **Assess → Configure → Pilot → Validate → Expand**, gated per phase.

> **Naming convention reminder:** artifacts, phases, roles, groups, and script outputs share the
> standard `<Purpose> – <Scope> – <Stage>` (e.g. `SASE Phase Scope – SWG – Pilot`) so everything
> cross-references cleanly across discovery, validation, reporting, and policy.

## Outcome

One coherent SASE/SSE architecture — SWG, ZTNA, CASB, SSL inspection, and identity-based policy
designed as a single operating model with a phased roadmap — replacing piecemeal edge security, with a
named operating model and measurable KPIs, proven on a pilot phase before you scale.
