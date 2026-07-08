# 7. Best Practices — Azure RMS / AIP → Built-in Unified Labeling Migration

- **Migrate for parity, not just for cutover.** The deliverable is that users see the same labels,
  encryption, and behaviour after the move. Build the parity map first and make every label, add-in
  feature, and RMS template map to a target — a silently dropped feature is unprotected data, not a
  cosmetic change.
- **Cut over a pilot ring in a change window before anyone else.** Flipping the labeling client changes
  how every document and email is classified and protected. Prove parity on `AIP Migration Pilot Ring –
  Stage1` first; it is cheap to fix on a ring and expensive to fix tenant-wide.
- **Confirm Azure RMS is activated and super-users exist before you touch protection.** Activation is the
  prerequisite for label encryption and departmental-template protection; super-users are the recovery
  net if a mapping is wrong. Both must be in place before the first cutover.
- **Always dry-run label-policy changes.** Run `IPRMSMIG-Set-LabelPolicy.ps1 -WhatIf` and read every line
  before `-Commit`; the script prints the prior value for each advanced setting so rollback is trivial.
  Never guess an advanced-setting key name — verify it against current documentation.
- **Treat departmental RMS templates as manual conversions.** There is no supported cmdlet that turns a
  protection template into a sensitivity label. Recreate each as a label with matching encryption and
  validate it opens old content — don't assume the template "just carries over."
- **Verify Office builds before cutting a ring over.** Built-in labeling and several parity features need
  minimum Office versions; a user on too old a build loses a feature at cutover. Update the ring first and
  let `IPRMSMIG-Test-Parity.ps1` flag features that need a newer build.
- **Verify the AIP add-in's retirement state and the client-policy setting names against current docs.**
  Retirement timing, the Office ADMX / Cloud Policy setting names, and any registry values evolve — cite
  as of authoring and confirm in your tenant rather than trusting a value from last quarter.
- **Run `Execute-AzureADLabelSync` after label/protection changes.** Protection picks up label changes on
  a sync; running it removes "the label works in the portal but not for the user" surprises during
  validation.
- **Keep the AIP add-in until parity is proven, then decommission deliberately.** Disable the add-in for a
  population only after that population is validated on built-in labeling — and record the decommission in
  the validation report so the estate's state is auditable.
- **This is a migration, not a taxonomy build.** Do not redesign labels, add auto-labeling, or stand up
  the Information Protection scanner here — hand off to those dedicated Purview solutions once the estate
  is safely on built-in labeling. Which legacy templates still apply is a records/compliance
  determination, not a technical default.
