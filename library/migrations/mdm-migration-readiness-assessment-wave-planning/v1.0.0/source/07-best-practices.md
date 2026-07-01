# 7. Best Practices — MDM Migration Readiness Assessment & Wave Planning

- **Inventory before you opinion.** Build the `Estate Inventory – MDM Migration – Assess` first and
  reconcile it to the source console totals. Every later decision (readiness, risk, waves) is only as
  good as this inventory — a migration planned on a guess fails on a guess.
- **Score against the target, not in a vacuum.** Readiness is relative: a device on an OS the *target*
  no longer supports is a readiness gap. Capture the target's supported-OS matrix before scoring the
  `Readiness Scorecard – MDM Migration – Assess`.
- **Make business criticality an input, not an afterthought.** No inventory export knows which devices
  are executive, shared, or mission-critical. Feed stakeholder criticality into the
  `Risk Register – MDM Migration – Assess` so the risky devices land in later waves.
- **Sequence low-risk/high-readiness first.** Always migrate the safest, most-ready devices early so
  the approach is proven before complex or critical devices move. The
  `Pilot Wave – MDM Migration – Pilot` must be low-risk, high-readiness, and representative.
- **Respect dependencies — move what must move together.** Use the
  `Dependency Map – MDM Migration – Assess` to keep certificate/VPN/app/conditional-access and
  shared-device groupings in the same wave; a split dependency is an outage waiting for a change
  window.
- **Write entry and exit criteria for every wave.** A wave without an
  `Entry/Exit Criteria – Per Wave – Pilot` block has no gate, so it never truly "finishes" and risk
  piles into the next wave. Define both before the wave starts.
- **Validate the plan against the pilot before you scale.** Re-run the report over the post-pilot
  estate and reconcile predicted vs. actual; tune the scoring weights if the pilot surprised you. Do
  not expand on an unvalidated plan — this is the one gate you never skip.
- **Keep it vendor-neutral and repeatable.** Drive everything from the CSV input schema (or Graph
  when Intune-adjacent) so the same assessment runs against any source MDM and the next migration
  reuses the artifacts and names verbatim.
- **Re-run discovery as the estate drains.** After each wave, re-run `MDMRDY-Discovery.ps1` and
  `MDMRDY-Report.ps1` so the inventory, scores, and cohorts stay current as devices leave the source.
- **Preview before you change anything.** Run `MDMRDY-Remediation.ps1` in its default `-WhatIf` mode
  and review the proposed inventory fills before `-Apply`; never let an automated fill silently rewrite
  the source of truth.
- **Name everything once and reuse it.** Use the exact artifact names
  (`<Purpose> – <Scope> – <Stage>`) across the inventory, scorecard, risk register, dependency map,
  wave plan, cohorts, and groups so the plan reads the same in every document and tool.
