# 7. Best Practices — Windows Firewall GPO to Intune Migration

- **Inventory before you translate.** Capture the GPO firewall profile defaults and every rule with
  `FWMIG-Discovery.ps1` / `FWMIG-Report.ps1` first; that export is your parity source of truth and your
  GPO-retirement checklist.
- **One authority per device, always.** The single most important practice: never let GPO and Intune
  enforce the same firewall settings on the same device at once. Move a device out of GPO firewall
  scope at the same step it enters the Intune ring.
- **Control rule merging explicitly.** Set the merge controls in the Intune `Firewall Policy` so local
  and GPO leftovers cannot silently re-merge — uncontrolled merging is how merge conditions and loops
  start.
- **Ring it; never big-bang the firewall.** `Migration Ring – Pilot` → `Wave 1` → `Broad`, with a
  parity gate between each. The firewall affects connectivity, so a small ring catches a bad
  translation before the fleet feels it.
- **Gate on parity, not on "it deployed."** Advance only when the effective Intune rule set equals the
  captured GPO inventory and connectivity is confirmed — not just when the policy shows Succeeded.
- **Translate faithfully, then improve later.** Migrate rules as-is for parity; defer firewall
  redesign/cleanup to a separate change after the migration is complete, so a connectivity break is
  unambiguously a translation error.
- **Keep a connectivity-aware rollback ready.** For each ring, pre-write how to re-scope the device to
  GPO firewall / unassign the Intune policy, because a wrong rule can block management or LOB traffic.
- **Watch for oscillation.** Re-validate after two check-ins / a `gpupdate /force`; a flipping
  effective state means two authorities are still fighting — fix coexistence before expanding.
- **Retire GPO last.** Disable/unlink the GPO firewall section only after every ring has passed parity
  and `FWMIG-Report.ps1` shows no device depends on it.
- **Name everything consistently.** Use `<Purpose> – <Scope> – <Stage>` for every policy, rules
  profile, ring, and group so the migration state is self-documenting and auditable.
