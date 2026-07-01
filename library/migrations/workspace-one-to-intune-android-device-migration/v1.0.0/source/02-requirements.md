# 2. Requirements Guide — Workspace ONE to Intune: Android Enterprise Device Migration

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-migrations.md`
(target Entra tenant, Intune licensing, source access, inventory, enrollment prerequisites, a
pilot group and waves, and change control/rollback) — confirm those first; the items below are
the Android-specific additions.

## 2.1 Managed Google Play connection (the Android app channel)
Description: A live managed Google Play connection between Intune and a Google enterprise binding.
Why: On Android Enterprise, all apps deploy through managed Google Play; with no connection, no
app reaches any migrated device — this is gate zero.
Verify: In Intune at `https://intune.microsoft.com` go to Devices > Android > Enrollment, then
Connectors and tokens > Managed Google Play; the binding shows a linked Google account and status
active. Run `WS1DROID-Discovery.ps1` (reports the connection state via Graph).
Implement: In the same blade choose to connect, sign in with a corporate Google account that is
not tied to a personal Gmail, and accept the binding. See Implementation Step 1.

## 2.2 Source management-mode mapping (per device)
Description: A mapping of each in-scope Workspace ONE Android device to its current management mode
(work profile / fully managed / dedicated) and therefore its target Intune mode.
Why: Mode is fixed at enrollment; the right Intune enrollment profile and whether a factory reset
is needed both depend on this mapping.
Verify: Produce the device-to-mode export from the Workspace ONE console (Workspace ONE internals
deferred to VMware docs). Confirm each row has a target mode.
Implement: Build the mapping from the source inventory before scoping rings; record it alongside
the wave plan.

## 2.3 Enrollment profiles per management mode (target design)
Description: A named Intune enrollment profile for each in-scope mode:
`Android Enrollment Profile – Work Profile BYOD – Migration`,
`Android Enrollment Profile – Fully Managed – Migration`,
`Android Enrollment Profile – Dedicated – Migration`.
Why: Devices re-enroll into a specific mode; a missing profile means that class of device cannot be
migrated.
Verify: Intune > Devices > Android > Enrollment; the relevant profiles exist (corporate modes show
an enrollment token / QR). Run `WS1DROID-Validation.ps1`.
Implement: Create only the profiles for modes you actually have in scope. See Implementation Step 2.

## 2.4 App parity target (managed Google Play)
Description: The set of apps each migrated device must have, sourced from managed Google Play, named
as the parity policy `App Parity – Android Estate – Migration`.
Why: A device that re-enrolls without its apps is a failed migration from the user's view; parity is
what makes the new platform invisible to the user.
Verify: Intune > Apps > Android; the in-scope apps are added and assigned. Cross-check against the
source app list. Run `WS1DROID-Report.ps1` for the parity gap.
Implement: Add each app from managed Google Play by its exact publisher and package id; re-publish
internal apps as managed Google Play private apps. See Implementation Step 3.

## 2.5 Configuration profile parity target
Description: The configuration each migrated device must have — Wi-Fi, email, VPN, certificates,
device restrictions — named `Config Parity – Android Estate – Migration`.
Why: Connectivity and security settings must survive the move or the device is non-functional after
re-enrollment.
Verify: Intune > Devices > Android > Configuration profiles; the parity profiles exist and target
the migration groups.
Implement: Recreate the source profiles as Intune configuration profiles for the matching Android
Enterprise profile type. See Implementation Step 4.

## 2.6 Compliance and Conditional Access target
Description: An Android compliance policy and the Conditional Access posture for the migrated estate,
named `Compliance Baseline – Android Estate – Migration`.
Why: Access control must follow the device to Intune so security is not weaker (or stricter and
blocking) during cutover.
Verify: Intune > Devices > Compliance policies (Android); Entra > Conditional Access references the
right groups.
Implement: Create the Android compliance policy and confirm Conditional Access targets the migration
groups, not the Workspace ONE groups. See Implementation Step 5.

## 2.7 Migration ring groups
Description: Microsoft Entra security groups for staged cutover:
`Migration Ring – Pilot – Android`, `Migration Ring – Wave 1 – Android`,
`Migration Ring – Wave 2 – Android` (extend as needed).
Why: Re-enrollment touches live, sometimes wiped devices; ringing contains blast radius and gates
expansion on a healthy pilot.
Verify: Entra > Groups; the ring groups exist. Run `WS1DROID-Set-MigrationRingTargeting.ps1`
(builds/populates them).
Implement: Create the groups and seed the pilot with a few representative devices per in-scope mode.
See Implementation Step 6.

## 2.8 User communications and reset readiness
Description: A user comms plan and, for fully managed / dedicated devices, confirmed data backup and
a reset window.
Why: Factory reset is destructive; users need warning, a backup path, and a known downtime, or the
migration generates tickets and data loss.
Verify: The comms template and per-ring schedule are written; corporate-mode devices have a backup
confirmation step.
Implement: Draft the comms per ring (what, when, what to back up, how long); pair each corporate-mode
ring with a reset window.

---
## Checklist
- [ ] Managed Google Play connection active — `WS1DROID-Discovery.ps1`
- [ ] Source device-to-mode mapping produced (from Workspace ONE / VMware docs)
- [ ] Enrollment profiles per in-scope mode created — `WS1DROID-Validation.ps1`
- [ ] App parity target built in managed Google Play — `WS1DROID-Report.ps1`
- [ ] Configuration profile parity rebuilt
- [ ] Compliance + Conditional Access retargeted to migration groups
- [ ] Migration ring groups created — `WS1DROID-Set-MigrationRingTargeting.ps1`
- [ ] User comms + reset windows planned for corporate modes
