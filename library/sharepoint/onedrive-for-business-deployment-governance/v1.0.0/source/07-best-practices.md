# 7. Best Practices — OneDrive for Business Deployment & Governance

Durable practices that keep OneDrive deployed, governed, and low-risk after the initial rollout.

## Deployment & client
- **Silent sign-in + KFM together, always.** Silent sign-in without KFM leaves Desktop/Documents/
  Pictures on the device — the very data-loss gap you deployed to close. Pair `SilentAccountConfig`
  with `KFMSilentOptIn` in the same profile so protection is complete the moment the client signs in.
- **Block the opt-out.** Set `KFMBlockOptOut = 1` so users can't move known folders back to the PC and
  silently re-open the data-loss gap. Use the notification variant so users understand the change.
- **Keep the client current, don't repackage it.** OneDrive updates itself on its release ring; prefer
  the built-in current ring over pinning an old standalone build. Only use per-machine standalone
  install where your device model genuinely requires it (e.g. non-persistent VDI).
- **Enable Files On-Demand.** `FilesOnDemandEnabled = 1` avoids filling local disks on first sync of a
  large OneDrive — essential for KFM at scale.

## Sync governance
- **Restrict sync to managed devices.** Always enable the domain-join allow-list
  (`Sync Restriction – DomainJoined – Prod`) so corporate data only syncs to devices you manage, and
  block personal accounts (`DisablePersonalSync`) so corporate and personal data never mix on a device.
- **Block risky file types at the tenant.** Exclude extensions that should never sync (e.g. `pst`) via
  `Set-SPOTenantSyncClientRestriction -ExcludedFileExtensions`.
- **Use web-only access for unmanaged sessions** (`ConditionalAccessPolicy = AllowLimitedAccess`) so
  browser access from unmanaged devices can't download, print, or sync — verify the licensing first.
- **Prefer ADMX/Intune over hand-edited registry.** Deploy client policies through the OneDrive ADMX in
  Intune/GPO, not by pushing raw registry values — the ADMX carries the correct, build-matched value names.

## Storage, retention & sharing
- **Set a deliberate default quota, override by exception.** A governed default
  (`OneDrive Storage Quota – Default – Prod`) with per-role overrides beats an unbounded max that hides
  cost and hoards stale data. Review near-quota accounts from the governance report.
- **Set the orphaned-retention window with records, not by default.** It is the **hard deletion timer**
  for a departed user's OneDrive — agree it with compliance/records and document it.
- **Keep OneDrive sharing aligned to (≤) org sharing.** Re-check `OneDriveSharingCapability` against org
  `SharingCapability` after any sharing change so OneDrive never drifts more permissive than policy.

## Offboarding & lifecycle
- **Grant, retrieve, then revoke.** Grant the manager site-collection admin only for the handoff window
  and remove it (`IsSiteCollectionAdmin $false`) once files are retrieved — don't leave standing access.
- **Confirm holds before deletion.** Never delete a departed user's account until compliance confirms no
  legal/records hold applies — the retention window is a timer, not a hold, and not a backup.
- **Automate the manager-access grant** on deletion (SharePoint admin center Retention/Notifications) so
  offboarding is consistent, not ad-hoc.

## Operate & assure
- **Report on a cadence.** Run `ODFBGOV-Report.ps1` regularly and act on NearQuota (≥90%) and Stale
  accounts; a downward stale trend means governance is working.
- **Pilot every high-impact change.** Sync, sharing, retention, and KFM changes are tenant-wide — always
  validate on `OneDrive Pilot Ring – Users – Stage1` with the go/no-go gate before broad rollout, and
  keep the documented rollback ready.
- **Preview before you commit.** Run `ODFBGOV-Configure.ps1` and `ODFBGOV-Set-OffboardingAccess.ps1`
  without `-Commit` (or with `-WhatIf`) first; commit only after the change table is reviewed.
- **Verify plan- and cloud-dependent behavior in your tenant.** Storage maxima, some sharing controls,
  and admin URLs differ by plan and between Commercial and Government clouds — confirm, don't assume.
