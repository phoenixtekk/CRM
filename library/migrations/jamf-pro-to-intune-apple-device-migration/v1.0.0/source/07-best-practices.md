# Best Practices

## Decide the wipe scope before you touch anything
- Supervised/ADE devices **must be erased** to change MDM; BYOD/user-enrolled do not. Split the fleet
  on that line up front so users know what to expect and you can schedule wipe windows only where they
  are actually needed.

## Migrate in waves, never big-bang
- Move a small pilot across all three platforms, validate, then roll rings. Keep Jamf running for
  everything not yet migrated. A per-wave cutover keeps rollback cheap and blast radius small.

## Never assume configuration transfers
- Jamf profiles, smart groups, and policies do **not** move. Rebuild them from the mapping worksheet as
  Intune Settings Catalog policies, Entra groups, and compliance policies. Translate, then validate,
  then assign.

## Protect the Apple push certificate
- A lapsed Apple MDM push certificate unenrolls the **entire** Apple fleet — Jamf and Intune alike.
  Check its expiry before you start and renew it with the **same Apple ID** if it is close.

## Handle VPP licenses deliberately
- App licenses are bound to the assigning MDM. **Revoke in Jamf, re-assign in Intune**, one license per
  device per app. Do it as each wave migrates so you do not run out of licenses mid-migration.

## Re-escrow FileVault, don't assume it carried
- The Jamf-escrowed recovery key does not transfer. Deploy an Intune FileVault policy that **escrows
  the key to Intune**, and confirm the key is retrievable in Intune before you consider a Mac migrated.

## Validate before you sign off a wave — because supervised rollback is a wipe
- Rollback for supervised devices means another erase. Validate enrollment, compliance, apps, SSO, and
  FileVault on each wave before starting the next, so you rarely need to roll back at all.

## Keep the evidence
- Retain the Jamf inventory export, the ABM assignment reports, and the per-wave validation/tracker
  CSVs as the migration record and the decommission sign-off.

## Sovereign clouds
- ABM + Intune is supported in GCC High / DoD and the mechanics are identical — only the portal host
  differs (`intune.microsoft.us`). Confirm VPP/ABM token and account-driven-enrollment availability for
  your tenant, then proceed the same way.
