# 7. Best Practices — Workspace ONE to Intune: Policy & Compliance Translation

- Inventory before you map. A complete, normalized source inventory is what parity is measured
  against; map nothing until the source list is verified complete with `WS1POL-Discovery.ps1`.
- Make every gap an explicit decision. The single most important practice: no source setting is
  dropped silently. Every setting with no clean equivalent gets a row in `Policy Translation - All
  Platforms - Gap Register` with a decision and an owner.
- Translate effective values, not just setting names. A setting that maps by name but with a
  different effective value silently changes posture. Confirm the value, not only the control.
- Work platform by platform. Intune policy is per platform; a profile that spanned platforms in
  Workspace ONE becomes one Intune object per platform. Handle Windows, iOS/iPadOS, Android, and
  macOS each on their own pass.
- Prefer the settings catalog, fall back to templates. Map most configuration in the settings
  catalog for granularity; use template profiles only where the catalog does not cover the setting
  (Wi-Fi, VPN, certificates, email).
- Pin compliance to Conditional Access. A translated compliance policy only protects anything when
  Conditional Access requires a compliant device; confirm the gate exists before cutover.
- Name everything `<Purpose> - <Scope> - <Stage>`. Reuse the names verbatim so every object is
  self-describing and the Pilot-to-Production promotion is mechanical.
- Gate on parity, not on schedule. No platform expands to production until it clears the parity gate
  on the pilot; the gate, not the calendar, decides cutover.
- Keep coexistence and rollback ready. Until a platform clears parity, the Workspace ONE policy
  remains authoritative; the rollback is to revert the Intune assignment (global requirement G7).
- Re-validate after every wave. Run `WS1POL-Validation.ps1` and `WS1POL-Report.ps1` after each
  expansion wave so parity is proven to hold, not assumed.
- Resolve conflicts deliberately. Use `WS1POL-Remediation.ps1` with `-WhatIf` first; never blind-fix
  a conflicting assignment.
