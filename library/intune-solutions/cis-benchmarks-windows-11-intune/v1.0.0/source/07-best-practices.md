# 7. Best Practices — CIS Benchmarks for Windows 11 (Microsoft Intune)

- **Pilot before you harden the fleet.** A small `CIS Win11 – Pilot Devices` group soaked against real apps catches breakage before it reaches production — the single most important practice, because hardening can break business apps.
- **Start at Level 1, add Level 2 deliberately.** Deploy L1 broadly; apply L2 only to the high-security subset that needs it and only after extra testing. Never enable L2 fleet-wide on day one.
- **Work from the official benchmark, not memory.** The authoritative control list, levels, and values live in the current CIS Windows 11 Benchmark and Build Kit. Always configure from the version you obtained.
- **Use the settings catalog first, ADMX only when needed.** Most controls live in the settings catalog; reserve imported ADMX for the minority of controls that have no catalog equivalent.
- **Name and tag everything consistently.** Use the `<Purpose> – <Scope> – <Stage>` convention (`CIS Win11 – L1 – Pilot`, etc.) and put the benchmark version tag `CIS-Win11-vX.Y.Z` in every policy description so the live version is always visible and auditable.
- **Document every break-glass exception.** A healthy baseline has documented exceptions, not silent gaps — record the control, reason, compensating control, owner, and review date.
- **Treat each new benchmark version as a change, not a footnote.** Run the full Obtain → Diff → Assess/Approve → Update → Re-validate → Record lifecycle. Diff with `CIS11-Compare-BenchmarkVersion.ps1` so you never miss an added or changed control.
- **Detect drift on a cadence.** Run `CIS11-Report.ps1` regularly and reapply with `CIS11-Remediation.ps1` (default `-WhatIf`) so devices don't quietly fall out of compliance between versions.
- **Resolve policy conflicts at the source.** If a device repeatedly drifts, find the conflicting Intune policy setting the same control differently — don't just keep remediating the symptom.
- **Keep a rollback ready.** Removing a policy assignment (or setting a control to *Not configured*) is the fastest safe rollback when hardening breaks an app; record what you rolled back as an exception.
- **Prove compliance with evidence.** Use Intune per-setting/device status plus the report script as your audit evidence that each device received the CIS values.
