# 7. Best Practices — Workspace ONE to Intune: Android Enterprise Device Migration

- Connect managed Google Play first, always. It is gate zero — verify it active before touching
  anything else, because no app deploys on Android Enterprise without it.
- Map every device to a mode before you start. Management mode is fixed at enrollment; getting the
  mapping right up front prevents re-doing the migration for whole device classes.
- Plan the factory reset honestly. Fully managed and dedicated devices must be wiped to re-enroll —
  pair every corporate-mode ring with a backup step, a reset window, and clear user comms. Only
  work profile (BYOD) re-enrolls without a wipe.
- Build parity once, reuse everywhere. Define `App Parity – Android Estate – Migration` and
  `Config Parity – Android Estate – Migration` once and assign them to every ring, so each wave is a
  re-run, not a rebuild.
- Use exact app identity. Add managed Google Play apps by their exact publisher name and package id
  so you deploy the right app, not a similarly named imposter; re-publish internal apps as private
  managed Google Play apps.
- Ring it, gate it. A small `Migration Ring – Pilot – Android` across all in-scope modes catches
  mode/parity mistakes before the fleet; do not expand until the pilot gate passes.
- Retarget access before cutover. Move compliance and Conditional Access to the migration groups so
  migrated devices keep the intended access and security is never weaker mid-cutover.
- Keep a rollback path. Until a device validates in Intune, re-enrolling it back to Workspace ONE
  must remain possible; document it per ring before you cut over.
- Communicate per ring. A short, specific note (what changes, when, what to back up, downtime)
  before each ring dramatically reduces tickets and data-loss incidents.
- Decommission deliberately. Only retire the Workspace ONE Android estate after the final wave
  validates, per change control — not device-by-device on a hunch.
