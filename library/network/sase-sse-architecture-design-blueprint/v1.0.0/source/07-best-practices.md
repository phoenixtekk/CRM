# 7. Best Practices — SASE / SSE Architecture & Design Blueprint

Program-grade practices for designing and adopting a unified SASE/SSE edge. These reduce risk, prevent
the slide back into piecemeal tooling, and keep the estate operable over time.

## Design discipline

- **Design before you buy.** Author the reference architecture, policy model, and roadmap *first*
  (`SASE Reference Architecture – Edge – Design` and friends). Designing first is what exposes
  duplicate tools and overlapping paths before more spend is committed.
- **Make identity the control plane, everywhere.** Decide policy from identity + device posture, not
  network location — and wire it the *same* way into SWG, ZTNA, and CASB. One trust model is the whole
  point of SASE/SSE.
- **One policy model, applied consistently.** Write every policy in the layered order — identity →
  destination/app → content hook → action. Inconsistent policy logic across consoles is how the old
  mess returns.
- **Name everything with the convention.** `<Purpose> – <Scope> – <Stage>`, reused verbatim across
  artifacts, groups, phases, and scripts, so discovery, validation, reporting, and policy cross-
  reference cleanly.

## Phasing & the pilot gate

- **Adopt in phases, never big-bang.** Phase 0 baseline → SWG → CASB → ZTNA → data-hook/optimize. Each
  phase changes a bounded slice of live traffic.
- **The pilot gate is non-negotiable.** No phase expands to broad scope until its pilot acceptance gate
  (§05) is PASS. A bounded pilot catches breakage before the fleet feels it.
- **Keep cohorts intact in a phase scope.** Scope a phase to groups of users who work together so
  coexistence between unified and legacy paths is short.
- **Run the per-phase preflight.** `SASE-Validation.ps1` (readiness) and `SASE-Report.ps1` (coverage +
  gaps) before every Configure; preview fixes with `SASE-Remediation.ps1` (default `-WhatIf`).

## SSL inspection

- **Trust the certificate first.** Deploy and confirm the decryption root on the steered scope *before*
  enabling inline inspection — otherwise users get TLS errors everywhere.
- **Govern the exception list; don't chase 100%.** Inspect by default, but maintain a documented,
  reviewed exception list for pinned-cert, regulated, and privacy-sensitive traffic. Inspection
  coverage is a tracked KPI with an exception rate, not a number to force to 100%.
- **Review exceptions on a cadence.** Every exception is re-justified or retired; stale bypasses are how
  blind spots accumulate.

## ZTNA & VPN displacement

- **Least privilege, per app.** Publish private apps mapped to the entitled Entra group — not broad
  network ranges. Verify non-entitled apps are unreachable (T4.2).
- **Displace VPN, don't yank it.** Prove ZTNA works for the pilot's apps, then retire broad VPN as
  displacement validates — and keep the VPN path warm for rollback (R11) until it does.

## CASB & shadow IT

- **Classify before you control.** Use Phase 1 visibility to label apps sanctioned/tolerated/
  unsanctioned, then write inline policy — control without classification breaks legitimate work.
- **Keep CASB policy identity-first** like everything else, so the same app can be handled differently
  per group.

## Data-protection-adjacent scope

- **Design the hooks, defer the DLP build.** Mark where content-aware policy attaches now; building a
  full data-classification/DLP program is a separate engagement. Naming the hooks keeps that later work
  a drop-in, not a rebuild.

## Change control & rollback

- **Approved window + tested back-out per phase (R11).** Every phase changes live traffic; have a
  documented rollback (disable steering / remove client / revert policy / re-enable VPN) and a comms
  plan before each cutover.
- **Communicate the change.** A short note per phase — what changes, the new sign-in/access experience,
  and who to contact — sharply reduces tickets.

## Operating model

- **Assign the roles before you expand.** `SASE Architecture Owner`, `Policy Administrator`,
  `Operations Engineer`, `Identity Liaison`, and the executive `Sponsor` — a design with no owner
  decays.
- **Measure what matters.** Keep the KPI dashboard (`SASE-Report.ps1`) live: steering coverage,
  inspection coverage/exception rate, policy consistency, ZTNA/VPN displacement, mean time to policy
  change, user-impact rate.
- **Keep the artifacts current as you go.** The reference architecture, policy model, and roadmap are
  living documents; update them with every approved change, not at the end.
