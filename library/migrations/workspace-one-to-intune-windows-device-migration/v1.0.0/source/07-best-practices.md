# 7. Best Practices — Workspace ONE to Intune (Windows Device Migration)

- **Build the target before you move a device.** Have `Parity Configuration – Windows – Migration`,
  `Compliance Policy – Windows – Migration`, and `Conditional Access Continuity – Windows – Migration`
  in place and assigned to both rings *first*, so every device lands configured, compliant, and able to
  sign in the moment it enrolls.
- **Never dual-manage.** A Windows device has one MDM authority — unenroll from Workspace ONE (per
  VMware documentation) before, or as part of, Intune enrollment. Run `WS1WIN-Discovery.ps1` to catch
  any device still held by the source.
- **Make access depend on Entra + Intune, not Workspace ONE.** Tying Conditional Access to a compliant,
  Entra-joined device means removing the old MDM never breaks sign-in.
- **Always pilot, always ring.** Move `Migration Ring – Pilot – Windows` first and hold the gate; only
  expand to `Migration Ring – Broad – Windows` after every pilot device passes. This catches a parity
  or compliance gap on a handful of devices instead of the fleet.
- **Hold the pilot-ring gate honestly.** Single-MDM, parity applied, compliant, access working — all
  four, every pilot device. A partial pass is a fail.
- **Keep a written rollback.** Re-enroll to Workspace ONE (VMware) and revert Conditional Access to
  report-only is the documented fallback; confirm it before cutover (global G7).
- **Validate per device, not per ring.** Run `WS1WIN-Validation.ps1` on each migrated device; a ring
  is only as migrated as its worst device.
- **Track what is left.** Keep `Group – Workspace ONE Managed – Windows` accurate; the migration is
  done when it is empty. Use `WS1WIN-Report.ps1` each wave to chase laggards.
- **Recreate, don't expect to import.** Workspace ONE profiles do not convert to Intune — map each
  source setting to its Intune equivalent in the parity target and verify with
  `WS1WIN-Validation.ps1`.
- **Communicate cutover to users.** A short note about the sign-in/restart and what "managed by your
  organization" means dramatically reduces tickets.
- **Reuse the names verbatim.** The same artifact names across config, compliance, Conditional Access,
  groups, and scripts make the process auditable and repeatable for the next wave and the next estate.
