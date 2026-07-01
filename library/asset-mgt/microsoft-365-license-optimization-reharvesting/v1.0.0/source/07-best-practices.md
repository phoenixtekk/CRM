# 7. Best Practices — Microsoft 365 License Optimization & Reharvesting

- **Close the unassigned gap first.** Purchased-but-unassigned seats are pure waste and zero-risk to drop at renewal — start there before touching a single user.
- **Always dry-run before you reclaim.** Run `M365LIC-Remediation.ps1 -WhatIf` and read every line; `-WhatIf` is the default for a reason. Execution is a deliberate, separate step.
- **Protect shared and service accounts, always.** Keep `Reclaim Exclusions – Shared+Service – AllStages` current; shared mailboxes, room/resource accounts, and service accounts look inactive but must never be stripped.
- **Define "unused" objectively.** Use a documented inactivity window (no sign-in *and* no service activity across the full period), not a hunch — and pick a window inside the reports' available range.
- **Pilot a safe set first.** Reclaim obvious leavers in one department before any broad sweep; validate savings and zero user impact at the gate, then expand.
- **Right-size on evidence, with a re-grant path.** Downgrade a tier only when the high-tier-only features show no usage, communicate the change, and keep re-granting one click away in case a need appears later.
- **Mind data retention on the last license.** Removing a leaver's final license starts mailbox/OneDrive grace timers — confirm retention/offboarding before reclaiming.
- **Reclaim group-assigned seats via the group.** Where group-based licensing is used, remove the user from the licensing group; stripping the user license won't stick.
- **Make it recurring, not a one-off.** A single cleanup regresses within months. Schedule the read-only `Discovery → Report → Validation` chain monthly under `Savings Campaign – M365 – Recurring`.
- **Close the loop with finance.** Reflect freed seats in the entitlement record so they actually reduce the next true-up/renewal — reclaimed seats only become savings when the bill changes.
