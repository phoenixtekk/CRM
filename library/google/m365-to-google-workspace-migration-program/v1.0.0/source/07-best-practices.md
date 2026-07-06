# 7. Best Practices — Microsoft 365 → Google Workspace Migration Program & Wave Plan

Field-proven practices for executing 150k users of migration wave by wave **without rework**.

- **Treat it as a program, not a project.** Baseline, design, coexistence, waves, cutover, and
  hypercare are stages with owners and gates — run them as one governed operating model, not a series
  of ad-hoc moves.
- **Design once, execute many.** Freeze `GWMIGPROG Design - Target & Tooling - Program` and the
  coexistence design before Wave 0. Deciding target structure or tooling per wave is the single
  biggest source of rework at scale.
- **Prove the whole runbook on a pilot wave.** Wave 0 (core IT + early adopters) exercises readiness →
  mail-flow/DNS → data move → validation → rollback end to end. It is cheaper to find a defect in 100
  users than in a business unit of 10,000.
- **Fix the runbook, not just the wave.** Every issue found in a wave is a defect in the runbook,
  coexistence design, or tooling pattern — fix it there so all later waves inherit the fix. This is
  what stops each wave re-learning the same lesson.
- **Identity before data, always.** Provision each wave's users/groups into Google (GCDS/SCIM) before
  any data moves or any routing addresses them; a data move to a non-existent account fails loudly at
  scale.
- **Stand up coexistence before the first wave, and time-box it.** Mail routing and calendar interop
  must be live before anyone cuts over so migrated and not-yet-migrated users still interoperate — and
  coexistence is transitional, decommissioned as waves complete, never left running indefinitely
  ([Google — dual delivery](https://support.google.com/a/answer/9228551),
  [Google — split delivery](https://support.google.com/a/answer/12971016)).
- **Keep the routing rule following users.** As each wave completes, update coexistence routing so
  every user's mail always reaches their current platform; a stale rule silently mis-delivers.
- **Spread data-heavy users across waves.** Distribute the largest mailboxes/Drives so no wave exceeds
  migration throughput; pre-stage Drive content ahead of cutover and finalize at cutover
  ([Google — plan your phases](https://support.google.com/workspacemigrate/answer/9275515)).
- **One user, one wave, fixed.** Assign every user to exactly one wave and never move a user between
  waves once confirmed — moving users mid-flight risks duplicate data.
- **Gate every cutover.** No wave starts until the previous wave passes
  `GWMIGPROG Gate - Go/No-Go - Per Wave`; a wave declared done before its validation completes is an
  incident waiting to surface.
- **Always have a rollback.** Every wave's routing/DNS change is applied under change control with a
  documented, tested back-out; a high-impact mail-flow change without a rollback is not ready to run.
- **Change management runs in tandem with the technical plan.** Comms and role-based training are part
  of each wave's readiness, set up alongside the migration plan from the start — not bolted on at
  cutover ([Google — enterprise migration & change management](https://workspace.google.com/solutions/migration/enterprise-migration/)).
- **Defer tool internals to the per-service solutions.** This program governs *which pattern and when*;
  the mail, Drive, and chat migration mechanics live in their own solutions and vendor docs — keep the
  program tool-agnostic so a tooling change touches the per-service layer, not the program.
- **Report progress cumulatively.** Track waves complete, users migrated vs total, and coexistence
  scope every cadence with `GWMIGPROG-Report.ps1`; a stalled coverage trend is an early warning.
