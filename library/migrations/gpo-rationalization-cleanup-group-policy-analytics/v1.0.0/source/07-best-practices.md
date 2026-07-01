# 7. Best Practices — GPO Rationalization & Cleanup with Group Policy Analytics

- **Rationalize before you migrate, always.** Cleaning the estate first is the single most valuable
  step — it shrinks the migration, removes the conflicts, and means you migrate intent once instead of
  duplicating the mess in a new console.
- **Let analytics score, let a human decide.** Group Policy analytics gives you the readiness
  percentage and supported/unsupported breakdown; the keep / retire / consolidate / replace call is a
  business decision a named owner makes — never auto-retire on a score alone.
- **Retire by unlinking, not deleting.** Leave retired GPOs present-but-unlinked until the migration is
  complete; with the retained exports that is a clean, instant rollback.
- **Keep the export folder as your rollback source.** The `GPORAT-Discovery.ps1` export is both the
  analytics input and the backup — retain it for the whole program.
- **One authority per audit area.** Duplicated audit settings are the most common redundancy; pick one
  authoritative GPO per area and clear the rest, recording each in the conflict log.
- **Resolve conflicts by intent, not by link order.** Where values differ across GPOs, decide the
  value you *mean* and set it once — do not preserve a winner that only won by accident of link order.
- **Document intent for everything you keep.** A one-line "what this is for" per surviving GPO is the
  hand-off the settings-migration phase depends on.
- **Sequence by readiness.** Put high-readiness GPOs first in the backlog for early, low-risk wins;
  schedule low-readiness and replace items deliberately.
- **Name every artifact consistently.** Use `<Purpose> – <Scope> – <Stage>` for every register, log,
  backlog, import set, and scope group, and reuse the names verbatim so the migration team can follow.
- **Prove it on a pilot scope first.** Validate the register, conflict log, and backlog against the
  pilot scope group before expanding to the broad fleet.
