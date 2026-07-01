# 7. Best Practices — CIS Benchmarks for macOS (Microsoft Intune)

- **Pilot before you harden the fleet.** A small `CIS macOS – Pilot Devices` group soaked against real apps catches breakage before it reaches production — the single most important practice, because hardening can break apps and even login.
- **Start at Level 1, add Level 2 deliberately.** Deploy L1 broadly; apply L2 only to the high-security subset that needs it and only after extra testing. Never enable L2 fleet-wide on day one.
- **Work from the official benchmark, not memory.** The authoritative control list, levels, payload keys, and values live in the current CIS macOS Benchmark for your macOS version. Always configure from the version you obtained.
- **Use the right macOS surface for each control.** Prefer the **settings catalog** first; use a **custom `.mobileconfig`** only for controls the catalog cannot reach; use a **shell script** only for controls enforceable solely by command — and set its run frequency so it re-enforces against user drift.
- **Keep the APNs certificate alive.** Apple management stops the moment the Apple MDM Push certificate expires. Track its renewal date and renew with the same Apple ID before expiry.
- **Name and tag everything consistently.** Use the `<Purpose> – <Scope> – <Stage>` convention (`CIS macOS – L1 – Pilot`, etc.) and put the benchmark version tag `CIS-macOS-vX.Y.Z` in every policy/profile/script description so the live version is always visible and auditable.
- **Document every break-glass exception.** A healthy baseline has documented exceptions, not silent gaps — record the control, reason, compensating control, owner, and review date.
- **Treat each new benchmark version (and each new macOS major) as a change, not a footnote.** Run the full Obtain → Diff → Assess/Approve → Update → Re-validate → Record lifecycle. Diff with `CISMAC-Compare-BenchmarkVersion.ps1` so you never miss an added or changed control.
- **Detect drift on a cadence.** Run `CISMAC-Report.ps1` regularly and reapply with `CISMAC-Remediation.ps1` (default `-WhatIf`) so Macs don't quietly fall out of compliance between versions.
- **Resolve policy conflicts at the source.** If a Mac repeatedly drifts, find the conflicting Intune profile setting the same payload differently — don't just keep remediating the symptom.
- **Keep a rollback ready.** Removing a profile/script assignment (or setting a control to *Not configured*) is the fastest safe rollback when hardening breaks an app or login; record what you rolled back as an exception.
- **Prove compliance with evidence.** Use Intune per-setting/device status plus the report script as your audit evidence that each Mac received the CIS values.
