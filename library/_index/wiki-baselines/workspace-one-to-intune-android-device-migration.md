# Workspace ONE to Intune — Android Enterprise Device Migration

> **Version 1.0.0** · Category: Migrations · Solution code: WS1DROID

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Workspace ONE to Intune: Android Enterprise Device Migration

Moving Android devices off Workspace ONE and into Microsoft Intune is not a copy-paste of
settings — it is an Android Enterprise re-enrollment program. The outcome depends on three
things done correctly: picking the right management mode for each device (work profile for BYOD,
fully managed or dedicated for corporate), connecting managed Google Play so apps deploy at all,
and accepting the re-enrollment reality (a factory reset for fully managed and dedicated devices).
This solution is the repeatable way to run that migration: connect managed Google Play, build the
right enrollment profiles per mode, rebuild app and profile parity, and cut over by ring with
clear user communication.

This is a complete, deploy-it-today package, written for an administrator with no prior
Workspace ONE to Intune migration experience.

## What you get
- A plain-language Solution Overview of the Android Enterprise migration model, the management
  modes, managed Google Play app parity, the re-enrollment reality, and the ringed cutover.
- A Requirements Guide with verify and implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered Intune steps in the required sequence.
- Five PowerShell scripts for migration-readiness discovery, per-device validation, a migration
  and app-parity report, safe remediation of failed enrollments, and a migration-ring group builder.
- Testing and Troubleshooting guides for a confident, reversible rollout.

## What this delivers
A working Android Enterprise estate in Intune: managed Google Play connected, named enrollment
profiles for each in-scope management mode, app and profile parity rebuilt from the source, and a
ringed re-enrollment plan with a pilot gate and a documented rollback — proven on a pilot before
you scale.

## The deployment model
Assess to Configure to Pilot to Validate to Expand.

## Outcome
Android devices moved from Workspace ONE to Intune the Android Enterprise way — correct management
mode, real managed Google Play app parity, and ringed re-enrollment — validated on a pilot ring
before fleet cutover, with a rollback path the whole way.


---


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


---


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


---


# Global Requirements — Migrations (category-level)

These requirements apply to **every** solution in the **Migrations** category (platform-to-platform
migration programs — e.g. Workspace ONE → Microsoft Intune, Configuration Manager → Intune, Group
Policy → Intune, Exchange/Microsoft 365 tenant moves). They are published once at the category level
so individual listings stay small. Confirm these before running *any* Migrations solution. Each entry:
**Description · Why · Verify · Implement-if-missing.**

## G1. Target Microsoft Entra ID tenant
**Description:** An active, correctly-configured Microsoft Entra ID (Azure AD) tenant — the migration target's identity backbone.
**Why:** Every modern endpoint/identity workload binds to Entra ID; users and devices must resolve there before migration.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create/confirm the Microsoft 365 / Azure subscription that provisions the tenant.

## G2. Target platform licensing & admin access (Intune)
**Description:** An Intune-bearing license plan and the admin roles to build/assign policies and apps in the target.
**Why:** You can't rebuild apps, profiles, or enrollment in the target without licensing and rights.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** active; you hold **Intune Administrator**.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1; grant least-privilege admin roles.

## G3. Access to the SOURCE platform
**Description:** Administrative read (and, for cutover, change) access to the platform you are migrating *from* (e.g. Workspace ONE UEM, Configuration Manager, Active Directory, the source tenant).
**Why:** Migration begins by inventorying and exporting the source's apps, profiles, policies, and device assignments.
**Verify:** You can sign in to the source console and export/inventory its configuration for a sample.
**Implement:** Obtain the source admin role / API credentials from the platform owner.

## G4. A current inventory / source of truth
**Description:** An accurate inventory of in-scope devices, users, apps, and policies on the source platform.
**Why:** Wave planning, parity validation, and decommission all depend on knowing exactly what is in scope.
**Verify:** You can produce a device/app/policy export from the source for the migration scope.
**Implement:** Build the inventory from the source console / discovery before scoping waves.

## G5. Enrollment prerequisites for the target
**Description:** The enrollment plumbing for each in-scope platform — e.g. Apple MDM Push (APNs) certificate and Apple Business Manager for iOS/iPadOS/macOS, managed Google Play for Android, automatic enrollment for Windows.
**Why:** Devices cannot move to the target MDM until its enrollment channels are live.
**Verify:** In Intune, the relevant connector/cert/token shows **Active** for each platform in scope.
**Implement:** Configure the APNs certificate, ABM/ADE token, managed Google Play, and Windows automatic enrollment as needed.

## G6. A pilot group and wave structure
**Description:** A Microsoft Entra security group for the pilot, and a planned set of migration waves/rings.
**Why:** Every migration is piloted and ringed before fleet cutover to contain risk.
**Verify:** Entra → **Groups**; the pilot group exists and the wave plan is documented.
**Implement:** Entra → **Groups → New group → Security**; define waves by department/region/device type.

## G7. Change control, coexistence, and a rollback path
**Description:** A change window, a defined coexistence approach (both platforms managed during transition), and a documented rollback (re-enroll to source / revert assignment).
**Why:** Migrations touch live, enrolled production devices; cutover must be reversible and coordinated.
**Verify:** A rollback procedure and coexistence plan are written and approved before any cutover.
**Implement:** Define rollback per platform, a comms plan, and the order of operations for coexistence → cutover → decommission.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# 5. Testing Guide — Workspace ONE to Intune: Android Enterprise Device Migration

Run after the pilot ring re-enrolls (Implementation Step 8) and again for each wave before
expanding. Each test states Do and Expected.

## Test 1 — Managed Google Play connection active
Do: Intune > Devices > Android > Enrollment > Connectors and tokens > Managed Google Play; or run
`WS1DROID-Discovery.ps1`.
Expected: The binding shows a linked Google account and active status. (No connection = no apps;
this gates everything.)

## Test 2 — Enrollment profiles exist per in-scope mode
Do: Intune > Devices > Android > Enrollment; or run `WS1DROID-Validation.ps1`.
Expected: Each in-scope profile is present
(`Android Enrollment Profile – Work Profile BYOD – Migration`,
`Android Enrollment Profile – Fully Managed – Migration`,
`Android Enrollment Profile – Dedicated – Migration`); corporate modes have a valid token / QR.

## Test 3 — Device landed in the correct mode
Do: For a re-enrolled pilot device, Intune > Devices > All devices > (device) > check Ownership and
the management/enrollment type; or run `WS1DROID-Validation.ps1`.
Expected: The device shows the intended Android Enterprise mode (work profile vs fully managed vs
dedicated) — not the wrong mode.

## Test 4 — App parity present
Do: Run `WS1DROID-Report.ps1` (source app list vs Intune-assigned), and on the device confirm the
work apps are installed.
Expected: Every in-scope app from `App Parity – Android Estate – Migration` is installed/available;
the parity gap is zero for the device.

## Test 5 — Configuration parity applied
Do: On the device, confirm Wi-Fi/email/VPN/certificate and restrictions behave as before; in Intune
the device shows `Config Parity – Android Estate – Migration` profiles as succeeded.
Expected: Connectivity and security settings match the pre-migration state; no failed profiles.

## Test 6 — Compliance and access
Do: Intune > Devices > Compliance; confirm the device is compliant. Attempt access to a
Conditional-Access-gated resource.
Expected: The device is compliant under `Compliance Baseline – Android Estate – Migration` and
access works (or is blocked) exactly as intended.

## Test 7 — Migration status report
Do: Run `WS1DROID-Report.ps1` for the ring.
Expected: A clear per-device migration status (mode, enrollment, app-parity gap) for the ring with
no unexpected failures.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 6 pass for every pilot device across all in-scope modes; Test 7 shows zero unresolved failures |
| Wave pass | Tests 3 to 7 pass for the wave before the next wave begins |

If the pilot gate fails, do not expand: remediate (`WS1DROID-Remediation.ps1`) or roll the affected
devices back to Workspace ONE per Implementation Step 8.


---


# 6. Troubleshooting Guide — Workspace ONE to Intune: Android Enterprise Device Migration

Use `WS1DROID-Discovery.ps1` and `WS1DROID-Validation.ps1` for connection and per-device state,
`WS1DROID-Report.ps1` for migration/parity status, and `WS1DROID-Remediation.ps1` (defaults to
`-WhatIf`) for safe fixes.

## A. No apps deploy to migrated devices
| Symptom | Cause | Remediation |
|---|---|---|
| Device enrolls but no work apps install | Managed Google Play not connected, or binding broken | Run `WS1DROID-Discovery.ps1`; reconnect at Devices > Android > Enrollment > Connectors and tokens > Managed Google Play |
| Some apps missing | App not approved / not assigned, or wrong package id | Run `WS1DROID-Report.ps1` for the parity gap; approve and assign the correct managed Google Play app by exact package id |
| Internal app unavailable | Not published as a managed Google Play private app | Publish it as a private app, then add/assign it |

## B. Device landed in the wrong management mode
| Symptom | Cause | Remediation |
|---|---|---|
| Corporate device shows as work profile (or vice versa) | Enrolled with the wrong method; mode is fixed at enrollment | Factory reset and re-enroll using the correct profile's token / QR (`Android Enrollment Profile – Fully Managed – Migration` or `– Dedicated – Migration`); confirm with `WS1DROID-Validation.ps1` |
| Wanted fully managed, got nothing on reset | Corporate fully-managed enrollment not allowed in Intune | Devices > Android > Enrollment > Corporate-owned, fully managed user devices > set to Yes; re-run enrollment |

## C. Enrollment fails or hangs
| Symptom | Cause | Remediation |
|---|---|---|
| Token / QR rejected | Expired or wrong-mode token | Regenerate the enrollment token for the correct dedicated/fully-managed profile |
| Still managed by old authority | Device not un-enrolled from Workspace ONE | Complete the source un-enrollment / enterprise wipe (VMware docs) before enrolling into Intune |
| Enrollment loops | Account / Google Play services issue on device | Run `WS1DROID-Remediation.ps1` (preview with `-WhatIf`); for corporate modes, factory reset and re-enroll |

## D. Configuration / connectivity broken after migration
- A device with no Wi-Fi/email/VPN after re-enrollment is missing
  `Config Parity – Android Estate – Migration` — confirm the profiles target the device's ring group
  and the correct Android Enterprise profile type for its mode; check certificate (SCEP/PKCS)
  delivery first, since Wi-Fi and VPN often depend on it.

## E. Compliance or access problems
- Device blocked from resources after migration: confirm it is compliant under
  `Compliance Baseline – Android Estate – Migration` and that Conditional Access now targets the
  migration ring groups, not the old Workspace ONE groups.

## F. Rollback (pilot or wave fails)
- Re-enroll the affected devices back into Workspace ONE (source action — VMware docs) and revert
  their migration-group membership so the parity/compliance artifacts no longer target them. Do not
  expand to the next ring until the gate in Section 5 passes.

## G. When to escalate
If managed Google Play is connected, the device un-enrolled cleanly from the source, the correct
enrollment profile/token was used, and the device still will not enroll or stay in the right mode
after a factory reset, capture the device enrollment details and open a Microsoft support case;
for source-side un-enrollment issues, engage VMware support.


---


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


---


# 8. Deliverables Summary — Workspace ONE to Intune: Android Enterprise Device Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The Android Enterprise migration model, management modes, managed Google Play parity, the re-enrollment reality, ringed cutover, and the why |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps (Google Play, profiles per mode, parity, rings, cutover) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WS1DROID-Discovery.ps1` | Read-only: reports the managed Google Play / Android enterprise binding state, enrollment profiles, and Android device inventory by ownership (Microsoft Graph) |
| `WS1DROID-Validation.ps1` | Read-only: confirms per-device management mode and enrollment correctness, and that the in-scope enrollment profiles exist (Microsoft Graph) |
| `WS1DROID-Report.ps1` | Read-only: migration status and app-parity gap (assigned apps vs an expected list) across the migrated estate (Microsoft Graph) |
| `WS1DROID-Remediation.ps1` | Safe remediation of failed enrollments (sync / retire-and-re-enroll prompts); defaults to `-WhatIf` preview (Microsoft Graph) |
| `WS1DROID-Set-MigrationRingTargeting.ps1` | Builds/populates the migration ring Entra groups from a device-to-ring mapping (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess to Configure to Pilot to Validate to Expand.

## Outcome
Android devices moved from Workspace ONE to Intune the Android Enterprise way — correct management
mode, managed Google Play app parity, and ringed re-enrollment — validated on a pilot before fleet
cutover, with a documented rollback.
