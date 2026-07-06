# 7. Best Practices — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

Field-proven recommendations for defensible eDiscovery across both ecosystems.

- **Assume nothing syncs — hold in parallel.** A hold in Vault does not reach Purview and vice versa.
  For every custodian, issue the hold on **both** platforms for every workload they touch. One
  playbook, two systems, the same named custodians on each side.
- **Name the matter once, identically on both.** Use the same `<Purpose> – <Scope> – <Stage>` name for
  the Vault matter and the Purview case so the two holds are unmistakably the same legal matter and
  coverage is auditable.
- **Map what's governed where before you hold anything.** Know which custodians and record classes live
  in Vault, in Purview, or (during migration) in both — the both-sides overlap is exactly where
  coexistence gaps hide.
- **Retain to the longer of the two.** Where a record class exists on both platforms, set each side's
  retention to the **longer** schedule so the stricter obligation is satisfied by default and nothing
  is purged out from under a hold.
- **Let the hold, not retention, preserve an active matter.** In Vault a hold takes precedence over
  retention and preserves indefinitely; in Purview most-restrictive-preservation-wins. Retention
  governs the ongoing schedule — the hold governs the matter.
- **Preserve the whole Microsoft footprint.** On the Purview side, holding a Team means holding the
  Team's group mailbox **and** SharePoint site; 1:1/group chat and OneDrive files live in individual
  mailboxes/accounts — add those custodians explicitly. Group membership on a hold is a point-in-time
  snapshot, so re-add groups when membership changes.
- **Mind the timing and licensing on Purview.** eDiscovery holds can take up to 24 hours to take
  effect, and require an eligible license on **every held user** (frontline F1/F3 cannot be a hold
  target). Confirm licensing before you place the hold, not after.
- **Discover across both and reconcile.** Run the matched search on each platform, export from both,
  and reconcile into a single de-duplicated production under counsel's direction — so no
  coexistence-overlap item is missed or double-counted, and the collection is defensible.
- **Always pilot the whole loop.** Prove parallel-hold-effective, retention-applied, and
  discovery-returns on a small custodian scope before extending to the full population — the pilot gate
  is "held and discoverable on both," not "a hold exists somewhere."
- **Keep legal/records counsel in the driver's seat.** Retention periods, hold triggers, and
  discovery scope are legal determinations. This is the technical mapping; counsel owns the legal call
  and signs off at each gate.
- **Watch the migration boundary.** As custodians move from M365 to Workspace, data can exist on both
  sides mid-migration and then shift — re-run coverage checks so a migrating custodian never drops out
  of hold on one ecosystem.
- **Verify evolving surfaces in your tenant.** Vault's Gemini-app hold/retention support and the
  Purview eDiscovery experience change; confirm each path for your editions and defer volatile
  specifics to the vendors' documentation rather than assuming.
- **Test discovery on a cadence, not just at crisis.** Rehearse the cross-system search/export/
  reconcile regularly so your first real hold is not your first rehearsal, and document the cadence for
  audit and repeatability.
