# 7. Best Practices — Forcepoint Neo to Netskope Migration (Legacy Web Filtering)

- One enforcing agent at a time. Never run Forcepoint Neo and Netskope both enforcing the same traffic — deploy Netskope passive, then swap. Dual SSL inspection is the fastest way to break access fleet-wide.
- Translate from an export, not from memory. Use the exported Forcepoint policy as the parity baseline; map every category, rule, and exception, and flag any mapping that is not one-to-one for a parity test.
- Migrate in rings. A small `Migration Ring - Pilot - Cutover` catches a bad translation or steering issue before the `Migration Ring - Broad - Cutover` fleet — the single most important practice.
- Gate decommission on parity, not on schedule. Remove the Forcepoint Neo agent from a ring only after that ring passes the parity test set; decommission the platform only after `Legacy Estate - Forcepoint Neo - Inventory` is empty.
- Keep groups non-overlapping. A device is in either `Coexistence Group - Netskope - Passive` or `Steering Group - Netskope - Enforce`, never both — overlap causes the dual-enforcement collision.
- Preview before you remove. `NSMIG-Remediation.ps1` defaults to `-WhatIf`; review the planned removals before re-running with `-Confirm`.
- Test allowed and blocked, not just blocked. Over-blocking breaks the business as surely as under-blocking exposes it — the parity set must include known-good URLs.
- Keep a rollback ready per ring. Until the legacy agent is removed, rollback is cheap: return the ring to passive and revert steering to Forcepoint. Plan it before each cutover.
- Reuse the named artifacts verbatim. The same `<Purpose> - <Scope> - <Stage>` names in the docs, scripts, and consoles keep the migration auditable and repeatable.
- Defer console specifics to the vendors. Netskope and Forcepoint screens change; operate on agent state and policy export at the architectural level and confirm the exact control in each vendor's current docs.
- Document the cadence. Record which ring cut over when, its parity result, and when its legacy agent was removed — for audit and for the decommission gate.
