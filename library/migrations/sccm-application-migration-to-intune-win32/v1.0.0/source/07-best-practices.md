# 7. Best Practices — SCCM Application Migration to Intune Win32

- **Inventory before you touch anything.** Export every app's deployment types, detection methods,
  requirements, dependencies, and supersedence from SCCM first — the estate encodes years of
  decisions you must not lose.
- **Migrate in waves, simple first.** Start with clean MSI apps that have shallow dependencies; defer
  App-V, script-heavy, and user-context deployment types to a packaging-decision wave.
- **One authoritative deployment type per app.** When an SCCM app has several deployment types, pick
  the one that represents the estate and repackage that; note the rest for later.
- **Detection parity is the whole game.** Carry over the exact MSI product code / file / registry /
  script detection SCCM used — Intune reports `Installed` only when the rule matches.
- **Use coexistence deliberately.** Leave the SCCM deployment live until the Intune app is validated
  on the same devices; only then retire the SCCM deployment for that ring. Nobody loses software.
- **Pilot ring is the gate.** Validate install + detection parity on a small ring before broad
  cutover — a bad repackage never reaches the fleet.
- **Recreate dependencies and supersedence, don't skip them.** Package dependency apps first and set
  auto-install; mirror supersedence so version replacement behaves as it did in SCCM.
- **Name everything with `<Purpose> – <Scope> – <Stage>`.** Reuse the same names for apps, detection
  rules, requirements, and ring groups so the migration is searchable and auditable.
- **Prove coverage with a report.** Track repackage coverage and deployment success with
  `SCCMAPP-Report.ps1` and chase `Failed` devices before decommissioning SCCM.
- **Retire SCCM last, ring by ring.** Remove the SCCM deployment only after the matching Intune ring
  is validated — never both authorities enforcing the same app in conflict.
- **Document the mapping.** Record each SCCM app → Intune Win32 app, its detection rule, and its ring
  for audit and repeatability.
