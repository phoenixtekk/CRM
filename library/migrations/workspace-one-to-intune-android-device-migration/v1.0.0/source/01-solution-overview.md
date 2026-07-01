# 1. Solution Overview — Workspace ONE to Intune: Android Enterprise Device Migration

## What this migration is
This is a platform migration of Android devices from Workspace ONE UEM to Microsoft Intune. On
Android, both platforms manage devices through Google's `Android Enterprise` framework, so the
migration is fundamentally an Android Enterprise re-enrollment: the device leaves Workspace ONE's
management, and re-enrolls into Intune under the correct management mode, with apps delivered by
managed Google Play and configuration rebuilt to match what the device had before.

Because Android management binds to the enterprise enrollment that was set on the device, you
cannot silently swap MDM authorities the way you might re-point a single agent. The device must
be released from the old authority and enrolled into the new one — which, for corporate-owned
modes, means a factory reset.

## The why — why this is harder than it looks
Three realities drive the whole plan, and they are the reason a structured migration beats an
ad-hoc one:

1. Management mode is a property set at enrollment and cannot be changed in place. A device
   enrolled as a personal work profile cannot become fully managed without re-enrolling, and
   vice versa. Choosing the wrong mode in Intune means re-doing the migration.
2. Apps only deploy on Android Enterprise through managed Google Play. If that connection is not
   live in Intune, no app reaches the device — so connecting it is gate zero, not a later step.
3. Re-enrollment for corporate modes requires a factory reset. Fully managed and dedicated
   devices must be wiped and re-provisioned to land in the right mode; only the personal work
   profile (BYOD) can re-enroll without a wipe. This is the single biggest source of user
   disruption and the reason cutover is ringed and communicated.

The repeatable way contains that risk: connect Google Play once, design the profiles per mode
once, rebuild parity once, then re-use those artifacts across every ring.

## The Android Enterprise management modes
- Personal work profile (BYOD): a managed container on a user-owned device. Personal apps and
  data stay private; work apps and policy live in the work profile. Re-enrolls without a factory
  reset.
- Fully managed (corporate-owned, COBO): the whole device is corporate-managed. Requires a
  factory reset to enroll.
- Dedicated (corporate-owned single/kiosk use, COSU): a locked-down corporate device for a task
  (scanner, kiosk, signage). Requires a factory reset and is typically enrolled without a user
  identity. (A corporate-owned work profile / COPE variant exists on supported OS versions; map
  it during Assess if in scope, and treat its re-enrollment like fully managed.)

The source-side mapping of which Workspace ONE device sits in which mode is read from the
Workspace ONE console. Workspace ONE internals are deferred to VMware documentation; this guide
defines the Intune target and the parity you rebuild there.

## How the migration works
1. Connect managed Google Play to Intune so apps can deploy at all.
2. Inventory the source: which devices, which management modes, which apps and configuration
   profiles each device has (read from Workspace ONE — see VMware docs for source export).
3. Build a named enrollment profile in Intune for each in-scope management mode.
4. Rebuild app and profile parity in Intune: the same apps (from managed Google Play) and the
   same configuration (Wi-Fi, email, VPN, certificates, restrictions, compliance) targeted to the
   migration groups.
5. Re-enroll devices by ring: un-enroll from Workspace ONE, then enroll into Intune (factory reset
   for fully managed and dedicated; container re-enroll for work profile).
6. Validate each device landed in the right mode with parity, then expand to the next ring.

## What you control in the target (Intune)
- Managed Google Play connection (the Android app channel).
- Enrollment profiles per management mode, including enrollment tokens for corporate modes.
- App parity from managed Google Play (work apps, store apps, managed configurations).
- Configuration profile parity (Wi-Fi, email, VPN, certificates, device restrictions).
- Compliance policy and Conditional Access for the migrated estate.
- Migration ring groups and staged assignment.

## Limitations (be honest with buyers)
- Fully managed and dedicated devices require a factory reset to re-enroll — there is no in-place
  mode conversion. Plan for data backup and user downtime on those devices.
- App parity is limited to what managed Google Play offers in your region; internally distributed
  apps must be re-published as managed Google Play private apps.
- Workspace ONE-specific configuration (its profile internals, its enrollment flows) is owned by
  VMware; this solution maps the intent to the Intune equivalent rather than translating XML.
- Conditional Access and compliance changes affect access during cutover; coordinate the change
  window.

## The deployment model
> Connect managed Google Play, build enrollment profiles per mode, rebuild app/profile parity,
> re-enroll by ring (reset where required), validate on the pilot, then expand.
> Model: Assess to Configure to Pilot to Validate to Expand.
