# 7. Best Practices — Group Policy to Intune Settings Migration

- **Measure before you migrate.** Run Group Policy analytics first and let the **readiness %** drive
  the order — migrate high-readiness GPOs early; plan the heavy-unsupported ones carefully.
- **Translate, never guess.** Recreate settings from the analytics mapping and the source GPO value,
  not from memory; confirm each migrated value with `GPOM-Validation.ps1`.
- **Decide precedence up front.** Enable **MDMWinsOverGP** before you cut over so migrated Intune
  settings actually win on hybrid devices — otherwise GPO wins and the work looks broken.
- **One authority per setting.** As each area moves, scope the legacy GPO away from migrated
  devices; never leave the same setting owned by both GPO and Intune long-term.
- **Migrate by ring, gate on parity.** A small **Pilot Ring** proves parity before the **Broad
  Ring** — the single most important safety practice in a migration.
- **Handle the unsupported settings deliberately.** Re-implement (proactive remediation / platform
  script / endpoint security), replace with the modern equivalent, or retire — and record the
  decision in the gap report.
- **Keep your exports and source GPOs.** Retain the GPO XML exports and leave source GPOs
  present-but-unscoped (not deleted) until the broad ring passes — that is your rollback.
- **Name everything to the convention.** Use `<Purpose> – <Scope> – <Stage>` for every policy and
  group so the estate stays auditable and the next admin understands it instantly.
- **Re-run the gap report each wave.** `GPOM-Report.ps1` should trend toward full coverage; chase
  anything that lingers in the gap list.
- **Document the cutover.** Record readiness %, migrated areas, unsupported-setting decisions, and
  the precedence model for audits and repeatability.
