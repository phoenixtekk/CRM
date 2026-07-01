# 7. Best Practices — Workspace ONE to Intune iOS/iPadOS Device Migration

- **Ring everything.** A small pilot ring catches a broken parity profile or a missed app before it touches the
  fleet — the single most important practice in an erase-and-re-enroll migration.
- **Treat re-enroll as a wipe.** For supervised ADE devices, plan for data loss: tell users to back up, confirm
  iCloud/Managed Apple ID backups where used, and schedule the erase in a known window.
- **Build parity before you re-assign.** Re-create every app and profile in Intune and assign them to the ring
  group first, so a device lands fully configured the moment Setup Assistant finishes. Use the parity matrix as the
  acceptance test.
- **Name objects consistently.** Use the `<Purpose> – <Scope> – <Stage>` convention (for example
  `iOS Parity – Corporate Wi-Fi – Cutover`) so every enrollment profile, parity policy, and ring group is
  auditable and reusable across waves.
- **Re-assign in ABM, do not unenroll in Workspace ONE first.** The device keeps working under Workspace ONE until
  it is erased; leaving the source live preserves rollback until the ring is signed off.
- **Respect Apple rate limits.** Allow time between ABM re-assignment, Intune sync, and profile assignment; do not
  bulk-reassign the whole fleet at once.
- **Communicate per ring.** A clear notice — backup reminder, downtime window, re-sign-in steps — dramatically
  reduces tickets during an erase-based migration.
- **Keep a rollback ready.** Document re-assigning the device back to the Workspace ONE MDM server and re-enrolling;
  do not retire the source MDM server until the whole fleet is migrated and stable.
- **Validate before widening.** Run the scripts and meet the pilot gate before the broad ring; repeat the gate per
  wave.
- **Document the cutover.** Record the parity matrix, ring membership, and dates for audit and repeatability.
