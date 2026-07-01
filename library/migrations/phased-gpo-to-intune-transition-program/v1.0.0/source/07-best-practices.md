# 7. Best Practices — Phased GPO-to-Intune Transition Program

- **Core OS first, security later — always.** The foundation must be migrated and stable before any
  security control (firewall, application control) is touched. This single sequencing rule prevents
  most transition failures.
- **Hold the stabilization gate against pressure.** The most common way a transition breaks is
  internal pressure to migrate security too quickly. Treat the Phase-2 go/no-go gate as
  non-negotiable: security phases do not start until the broad core-OS scope shows zero
  conflicts/loops.
- **Set precedence before you migrate settings.** Deploy `Coexistence Policy – MDM Wins Over GP – All
  Migrated` *first*, so the very first migrated settings already have a defined winner — never migrate
  settings into an undefined-precedence state.
- **Rationalize before you migrate.** Retire dead, duplicate, and obsolete GPOs first; migrate intent,
  not accumulated cruft. Less surface means fewer conflicts.
- **One setting area, one phase.** Assign every setting area to exactly one phase; never let two phases
  touch the same area, and never leave both authorities driving the same area indefinitely.
- **Scope the legacy GPO away as each area migrates.** Coexistence is transitional. The end-state is
  one authority per setting — security-filter / unlink the legacy GPO for each migrated area (keep it
  present-but-unlinked for rollback).
- **Watch for loops, not just conflicts.** A setting that flips between a GPO value and an Intune value
  across policy cycles is the loop signature; the validation script flags it — resolve precedence
  before advancing.
- **Pilot, soak, then expand — every phase.** Each phase gets its own pilot, a stabilization soak
  across at least one full policy cycle, and a re-validate before broad expansion.
- **Pilot application control in audit/learn mode.** App control has the highest block-out risk; learn
  first, review events, then enforce.
- **Gate, sign, and record.** Every phase boundary is a named `Phase Gate Checklist – <Scope> –
  Program`, signed by the program lead with stakeholders — the audit trail and the pressure valve.
- **Name everything to the convention.** `<Purpose> – <Scope> – <Stage>`, reused verbatim, so status,
  assignments, and rollback are unambiguous.
- **Keep rollback available through a grace period.** Leave legacy GPOs present-but-unlinked until each
  phase is confirmed; decommission only after the grace period.
- **Track the KPIs.** Phase completion, precedence coverage, open conflicts/loops, GPO rationalization,
  and coexistence cleanup — a downward conflict count and rising one-authority-per-setting % mean the
  transition is healthy.
