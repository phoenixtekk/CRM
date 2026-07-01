# 3. Implementation Guide — Workspace ONE to Intune: Android Enterprise Device Migration

Follow these steps in order, in the Microsoft Intune admin center (`https://intune.microsoft.com`).
Workspace ONE-side actions (export, un-enrollment) are flagged and deferred to VMware
documentation; the Intune target is specified exactly here.

> Model: Connect managed Google Play, build enrollment profiles per mode, rebuild app and profile
> parity, re-enroll by ring (factory reset for fully managed and dedicated), validate on the pilot,
> then expand. Assess to Configure to Pilot to Validate to Expand.

## Step 1 — Connect managed Google Play (gate zero)
1. Go to Devices > Android > Enrollment.
2. Open Connectors and tokens > Managed Google Play.
3. Choose to connect, then sign in with a corporate Google account (not a personal Gmail; this
   account becomes the enterprise binding owner). Accept the agreement.
4. Confirm the blade shows the linked Google account and an active status.
5. Verify with `WS1DROID-Discovery.ps1` (reports the Android enterprise binding state). This is
   gate zero — do not proceed until it is active, because no app deploys without it.

## Step 2 — Build the enrollment profiles per management mode
Create only the profiles for modes in your scope (from requirement 2.2). Use these exact names so
every later artifact and the scripts line up.

1. Work profile (BYOD): Devices > Android > Enrollment > Personally-owned devices with work profile.
   Confirm enrollment is enabled for personal work profile. The reusable artifact name is
   `Android Enrollment Profile – Work Profile BYOD – Migration`. (BYOD re-enrolls without a wipe.)
2. Fully managed: Devices > Android > Enrollment > Corporate-owned, fully managed user devices >
   set to Yes (allow). Note the enrollment method (token / QR / NFC / zero-touch) you will use.
   Artifact name: `Android Enrollment Profile – Fully Managed – Migration`.
3. Dedicated: Devices > Android > Enrollment > Corporate-owned dedicated devices > Create profile.
   Enter a name `Android Enrollment Profile – Dedicated – Migration`, choose the token type, and
   create the enrollment token / QR. (Dedicated and fully managed both require a factory reset to
   enroll.)
4. Verify with `WS1DROID-Validation.ps1` (confirms the in-scope profiles exist).

## Step 3 — Rebuild app parity in managed Google Play
1. Go to Apps > Android > Add.
2. For each in-scope app, choose Managed Google Play app, search the store, and select it by its
   exact publisher name and package id (disambiguate from similarly named apps — the package id is
   what guarantees the right app). Approve it.
3. For internally distributed source apps, publish them as managed Google Play private apps, then
   add them the same way.
4. Set any required app configuration policy (managed configurations) to match the source behavior.
5. Assign the apps to the migration ring groups (Step 6). The reusable artifact name for this set is
   `App Parity – Android Estate – Migration`.
6. Verify the parity gap with `WS1DROID-Report.ps1` (source list vs Intune-assigned apps).

## Step 4 — Rebuild configuration profile parity
1. Go to Devices > Android > Configuration profiles > Create profile.
2. Choose the platform/profile type matching the target mode (work profile vs fully managed /
   dedicated have distinct profile types).
3. Recreate each source profile's intent — Wi-Fi, email, VPN, certificate (SCEP/PKCS), device
   restrictions — as Intune configuration profiles. (Source profile internals are deferred to VMware
   docs; rebuild the intended setting in Intune, do not translate XML.)
4. Name the set `Config Parity – Android Estate – Migration` and assign to the migration ring groups.

## Step 5 — Set compliance and retarget Conditional Access
1. Go to Devices > Compliance policies > Create policy > Android.
2. Build `Compliance Baseline – Android Estate – Migration` (minimum OS, encryption, threat level,
   rooted-device block as appropriate) and assign to the migration ring groups.
3. In Entra > Conditional Access, confirm the access policies that gate corporate resources reference
   the migration ring groups, so migrated devices keep (and only keep) the intended access.

## Step 6 — Build the migration ring groups
1. Create Entra security groups `Migration Ring – Pilot – Android`,
   `Migration Ring – Wave 1 – Android`, `Migration Ring – Wave 2 – Android` (extend as needed).
2. Seed the pilot with a few representative devices covering each in-scope mode.
3. Confirm Steps 3 to 5 artifacts are assigned to these ring groups.
4. Run `WS1DROID-Set-MigrationRingTargeting.ps1` to create/populate the groups from your mapping
   (run with `-WhatIf` first to preview).

## Step 7 — Pilot cutover (re-enroll the pilot ring)
1. Communicate to the pilot users (what is changing, when, what to back up, expected downtime).
2. Un-enroll the pilot devices from Workspace ONE (source action — see VMware docs for the
   un-enrollment / enterprise wipe procedure).
3. Re-enroll into Intune by mode:
   - Work profile (BYOD): enroll via the Company Portal app; the work profile re-provisions without
     a factory reset.
   - Fully managed / dedicated: factory reset the device, then enroll during out-of-box setup using
     the enrollment token / QR from Step 2.
4. Confirm each pilot device lands in the correct mode with apps and configuration applied.

## Step 8 — Validate the pilot (gate)
1. Run `WS1DROID-Validation.ps1` (per-device mode + enrollment correctness).
2. Run `WS1DROID-Report.ps1` (migration status + app-parity gaps for the pilot ring).
3. For any failed enrollments, run `WS1DROID-Remediation.ps1` (preview with `-WhatIf`).
4. Complete the Testing Guide. Pilot-ring gate: do not expand until the pilot passes the gate in
   Section 5. Rollback note: if the pilot fails, re-enroll affected devices back into Workspace ONE
   (source action, VMware docs) and revert their migration-group membership.

## Step 9 — Expand by wave
1. Move to `Migration Ring – Wave 1 – Android`: communicate, un-enroll from source, re-enroll into
   Intune (reset where required), validate.
2. Repeat for subsequent waves. Re-validate each wave with `WS1DROID-Report.ps1` before starting the
   next.
3. After the final wave validates, decommission the Workspace ONE Android estate per change control.

---
### Order of operations
`Managed Google Play -> Enrollment profiles per mode -> App parity -> Config parity -> Compliance/CA -> Ring groups -> Pilot cutover -> Validate (gate) -> Expand by wave`
