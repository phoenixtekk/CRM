# Workspace ONE to Intune — iOS/iPadOS Device Migration

> **Version 1.0.0** · Category: Migrations · Solution code: WS1IOS

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Workspace ONE to Intune iOS/iPadOS Device Migration

Apple devices are the trickiest part of any Workspace ONE exit. Supervised, ADE-enrolled iPhones and iPads are
bound in Apple Business Manager to whatever MDM server they were set up with, and that binding only changes when an
administrator re-assigns the device in Apple Business Manager and the device re-enrolls through Setup Assistant —
which, for a supervised device, almost always means a wipe-and-re-enroll. Done ad hoc, that is how a migration
turns into a fleet of bricked, half-managed devices and a flood of tickets.

This is the repeatable way to migrate iPhones and iPads from Workspace ONE to Microsoft Intune: connect Apple
Business Manager to Intune, build Intune enrollment profiles and app/profile parity, re-assign devices in Apple
Business Manager from the Workspace ONE MDM server to Intune, re-enroll supervised by ring, and cut over with clear
user communications and a rollback path — proven on a pilot before the fleet.

It is written for an administrator with no prior Apple migration experience, and it is deliberately white-label:
Workspace ONE internals are deferred to the source vendor's documentation, while the Intune and Apple Business
Manager side is covered with exact navigation.

## What you get
- A plain-language Solution Overview of the Apple migration model and why supervised devices must be re-assigned and re-enrolled.
- A Requirements Guide with verify / implement-if-missing for every prerequisite (APNs, ABM/ADE, VPP, parity, rings, rollback).
- An Implementation Guide of precise, ordered steps in Intune and Apple Business Manager, with every artifact named.
- Five PowerShell scripts for readiness discovery, per-device validation, migration reporting, safe remediation, and ring-group targeting.
- Testing and Troubleshooting guides for confident rollout.

## What this delivers
A ringed iOS/iPadOS migration — Apple Business Manager MDM-server re-assignment, supervised ADE re-enrollment,
rebuilt app and configuration parity, and a pilot-gated cutover with user comms and a rollback to the source.

## The deployment model
**Assess to Configure to Pilot to Validate to Expand.**

## Outcome
iPhones and iPads moved cleanly from Workspace ONE to Intune — re-assigned in Apple Business Manager, re-enrolled
supervised with app and profile parity, cut over by ring with clear comms, and validated on a pilot before you scale.


---


# 1. Solution Overview — Workspace ONE to Intune iOS/iPadOS Device Migration

## What this migration is
This is the repeatable way to move supervised, ADE-enrolled iPhones and iPads off **VMware Workspace ONE UEM**
and onto **Microsoft Intune**, without losing supervision, app delivery, or device configuration. Apple devices
are the hardest part of any Workspace ONE exit because the path to a new MDM is gated by **Apple Business Manager
(ABM)**: a supervised, Automated Device Enrollment (ADE) device is bound to whatever **MDM server** ABM points it
at, and that binding only changes when an administrator **re-assigns the device in ABM** and the device
**re-enrolls** — which for an already-supervised device almost always means **wipe and re-enroll**.

## Why Apple is different (the why lives here)
On Windows you can often migrate management authority in place. On iOS/iPadOS you cannot: supervision and the ADE
enrollment profile are applied during Setup Assistant and are enforced by Apple, not by the MDM. A device that was
supervised under Workspace ONE will not silently become supervised under Intune. To change its managing MDM you
must (1) re-assign the device from the Workspace ONE MDM server to the Intune MDM server **in Apple Business
Manager**, and (2) put the device through Setup Assistant again so it picks up the Intune ADE enrollment profile.
Step 2 requires an erase. That single reality — re-assign in ABM, then wipe-and-re-enroll — shapes the entire
program: it must be ringed, communicated to users, and validated on a pilot before it touches the fleet, because
every migrated device is briefly unmanaged and its on-device data is reset.

## How it works
1. Connect **Apple Business Manager to Intune**: an **Apple MDM Push (APNs) certificate** and an **ADE token**
   (an MDM server in ABM whose public key comes from Intune) make Intune a valid MDM server for your Apple devices.
2. Build **Intune ADE enrollment profiles** that re-create the supervision and Setup Assistant experience the
   devices had under Workspace ONE.
3. Rebuild **app and configuration parity** in Intune — the store/VPP apps, Wi-Fi, VPN, email, restrictions, and
   compliance the devices had under Workspace ONE — so a re-enrolled device lands fully configured.
4. **Re-assign devices in Apple Business Manager** from the Workspace ONE MDM server to the Intune MDM server.
5. **Re-enroll** each device by ring — for supervised ADE devices this is a wipe-and-re-enroll through Setup
   Assistant — so it picks up the Intune ADE profile and the parity policies.
6. Cut over in **rings** (pilot first), with **user communications** and a **rollback** path, then expand.

## What you migrate
- **Enrollment and supervision** — supervised ADE re-enrollment under Intune (the Workspace ONE binding is replaced).
- **Apps** — store and Volume Purchase (VPP/ABM) apps re-published in Intune with the same assignments.
- **Configuration** — Wi-Fi, VPN, email, certificates, and device restrictions re-created as Intune profiles.
- **Compliance** — an iOS/iPadOS compliance policy matching (or improving on) the Workspace ONE baseline.

## Limitations (be honest with buyers)
- Supervised ADE devices generally require **wipe-and-re-enroll**; on-device data is erased, so back up or accept loss.
- **Workspace ONE internals** (its console layout, its API, its profile export) are the source vendor's domain —
  this solution defers those specifics to VMware documentation and focuses on the **Intune + Apple Business
  Manager** side, which it covers exactly.
- ABM device **re-assignment** and ADE **sync** are rate-limited by Apple; allow time between assignment and re-enroll.
- A device that is still **checked in to Workspace ONE** when you re-assign it will not move until it is erased and
  runs Setup Assistant again — coexistence is expected during the transition.

## The standard deployment model
> **Connect ABM to Intune → build enrollment profiles and parity policies → re-assign in ABM → re-enroll by ring →
> validate on the pilot → expand.** The repeatable model: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Workspace ONE to Intune iOS/iPadOS Device Migration

Verify every requirement before configuring. Each entry: Description · Why · Verify · Implement-if-missing.
Category-wide prerequisites are in `global-requirements-migrations.md`; the items below are the iOS/iPadOS specifics.

## 2.1 Intune licensing and admin role
Description: An Intune-bearing plan and the rights to build Apple enrollment, apps, and policies.
Why: You rebuild enrollment, parity apps, and profiles in Intune; this needs licensing and admin rights.
Verify: `https://intune.microsoft.com` loads; Tenant administration > Tenant status active; you hold Intune Administrator.
Implement: Assign M365 E3/E5, Business Premium, or standalone Intune Plan 1; grant the Intune Administrator role.

## 2.2 Apple MDM Push (APNs) certificate — Active in Intune
Description: An Apple MDM Push certificate so Intune can manage Apple devices.
Why: No Apple device can enroll in Intune until the APNs certificate is Active.
Verify: Intune > Devices > Enrollment > Apple > Apple MDM Push certificate shows Active with a future expiry. Run `WS1IOS-Discovery.ps1`.
Implement: Intune > Devices > Enrollment > Apple > Apple MDM Push certificate; download the CSR, create the certificate at `https://identity.apple.com` with a company Apple ID (record it — reuse it every renewal), upload the `.pem`.

## 2.3 Apple Business Manager access and the Intune MDM server (ADE token)
Description: Administrator access to Apple Business Manager and an ADE token connecting ABM to Intune.
Why: Supervised ADE devices are bound to an ABM MDM server; migrating them means re-assigning them to an Intune MDM server, which must exist first.
Verify: You can sign in to `https://business.apple.com` as an administrator; Intune > Devices > Enrollment > Apple > Enrollment program tokens shows at least one token. Run `WS1IOS-Discovery.ps1`.
Implement: In Intune add an enrollment program token (download the Intune public key); in ABM > Preferences > MDM Servers > Add, name it `Intune MDM Server – Apple – Migration`, upload the Intune public key, save, download the token (`.p7m`); upload the `.p7m` back in Intune.

## 2.4 Workspace ONE / ABM source access (re-assignment rights)
Description: Administrative access to Workspace ONE UEM and to the ABM MDM-server assignments the source devices currently use.
Why: Migration inventories the source and then re-assigns devices away from the Workspace ONE MDM server in ABM.
Verify: You can sign in to the Workspace ONE console and identify which ABM MDM server the in-scope devices map to.
Implement: Obtain the Workspace ONE admin role and ABM administrator rights from the platform owner. Workspace ONE console specifics are deferred to VMware documentation.

## 2.5 Device inventory and supervision state
Description: An accurate list of in-scope iPhones/iPads with serial numbers and their supervision/ADE state.
Why: Wave planning and the wipe-and-re-enroll decision depend on knowing which devices are supervised ADE.
Verify: You can export the in-scope serial numbers from ABM (and Workspace ONE) and confirm supervision. Run `WS1IOS-Report.ps1` once devices appear in Intune.
Implement: Build the inventory from ABM Devices and the Workspace ONE console before scoping rings.

## 2.6 App and profile parity target
Description: A documented list of the apps, Wi-Fi/VPN/email/certificate profiles, restrictions, and compliance rules the devices have under Workspace ONE.
Why: A re-enrolled device must land fully configured; parity is what makes the migration invisible to users.
Verify: A parity matrix (source policy to Intune object) exists and is approved. Name the Intune objects per Section 3.
Implement: Export the source configuration (VMware docs) and map each item to an Intune app or profile in the parity matrix.

## 2.7 VPP / Apple Business Manager app licensing
Description: A VPP (Apps and Books) token in Intune and the app licenses the devices need.
Why: Most managed iOS apps are delivered via VPP; without the token Intune cannot assign them by device.
Verify: Intune > Tenant administration > Connectors and tokens > Apple VPP tokens shows an Active token.
Implement: In ABM > Payments and Billing > download the Apps and Books token; upload it in Intune.

## 2.8 Migration ring groups and user communications
Description: Microsoft Entra groups for each migration ring (pilot first) and a user-facing comms plan for the erase/re-enroll.
Why: Cutover is ringed and disruptive (a wipe); users must know what to expect and when.
Verify: Entra > Groups shows the ring groups; a comms template per ring is approved. Run `WS1IOS-Set-MigrationRingTargeting.ps1` to build them.
Implement: Create the ring groups (Section 3) and draft the user notice (backup reminder, downtime window, re-sign-in steps).

## 2.9 Rollback and coexistence plan
Description: A written rollback (re-assign the device back to the Workspace ONE MDM server and re-enroll) and a coexistence approach for the transition.
Why: Cutover touches live production devices; it must be reversible and coordinated.
Verify: A rollback procedure and coexistence plan are written and approved before any device is re-assigned.
Implement: Document the per-device rollback, the order of operations, and the comms for coexistence to cutover to decommission.

---
## Checklist
- [ ] Intune licensing + Intune Administrator role
- [ ] Apple MDM Push (APNs) certificate Active — `WS1IOS-Discovery.ps1`
- [ ] ABM access and Intune MDM server (ADE token) present — `WS1IOS-Discovery.ps1`
- [ ] Workspace ONE / ABM source re-assignment rights
- [ ] Device inventory with supervision state — `WS1IOS-Report.ps1`
- [ ] App and profile parity matrix approved
- [ ] VPP (Apps and Books) token Active
- [ ] Migration ring groups created — `WS1IOS-Set-MigrationRingTargeting.ps1`
- [ ] User comms drafted per ring
- [ ] Rollback and coexistence plan approved


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


# 3. Implementation — Workspace ONE to Intune iOS/iPadOS Device Migration

Follow these steps in order. The why lives in the Solution Overview; the steps below are short and exact so you can
click to implement. The model is **Assess to Configure to Pilot to Validate to Expand**, with a pilot-ring gate
before any fleet cutover.

Consoles used:
- Microsoft Intune admin center — `https://intune.microsoft.com`
- Microsoft Entra admin center — `https://entra.microsoft.com`
- Apple Business Manager (ABM) — `https://business.apple.com`
- Workspace ONE UEM console — source platform; its internals are deferred to VMware documentation.

> Scope note: these are managed, supervised iPhones/iPads currently bound to a Workspace ONE MDM server in Apple
> Business Manager. Moving them to Intune means re-assigning the device in ABM and re-enrolling through Setup
> Assistant — for supervised ADE devices this is a wipe-and-re-enroll. Treat every device as briefly unmanaged and
> erased during cutover.

Artifacts created in this guide (name each exactly; reuse the names verbatim everywhere):
- ABM MDM server: `Intune MDM Server – Apple – Migration`
- Enrollment profile (pilot): `iOS Migration – Corporate Supervised – Pilot`
- Enrollment profile (broad): `iOS Migration – Corporate Supervised – Broad`
- Parity Wi-Fi profile: `iOS Parity – Corporate Wi-Fi – Cutover`
- Parity restrictions profile: `iOS Parity – Device Restrictions – Cutover`
- Parity compliance policy: `iOS Parity – Compliance Baseline – Cutover`
- Ring group (pilot): `iOS Migration – Pilot Ring – Pilot`
- Ring group (broad): `iOS Migration – Broad Ring – Expand`

---

## Phase 1 (Assess) — inventory and parity baseline

### Step 1. Inventory the in-scope Apple devices
1. Export the in-scope iPhone/iPad serial numbers from Apple Business Manager (ABM > Devices) and from the
   Workspace ONE console. Record which ABM MDM server each device currently maps to (it will be the Workspace ONE
   server).
2. Confirm supervision/ADE state per device. Supervised ADE devices follow the wipe-and-re-enroll path.
   *(Workspace ONE export specifics are deferred to VMware documentation.)*

### Step 2. Build the app/profile parity matrix
1. List every Workspace ONE app and profile in scope (store/VPP apps, Wi-Fi, VPN, email, certificates,
   restrictions, compliance) and map each to the Intune object you will build in Phase 2.
2. Approve the matrix with the device/app owners — this is the definition of a successful re-enroll.

---

## Phase 2 (Configure) — connect ABM to Intune and build target objects

### Step 3. Confirm the Apple MDM Push (APNs) certificate is Active
1. In Intune, go to Devices > Enrollment > Apple > Apple MDM Push certificate.
2. If not present: check I agree, Download the CSR, click Create your MDM push certificate to open
   `https://identity.apple.com`, sign in with a company Apple ID (record it — reuse it every renewal), create a
   certificate, upload the CSR, Download the `.pem`, then back in Intune enter the Apple ID, Browse to the `.pem`,
   Upload.
3. Confirm status Active with an expiration about one year out.

### Step 4. Connect Apple Business Manager to Intune (the Intune MDM server / ADE token)
1. In Intune, go to Devices > Enrollment > Apple > Enrollment program tokens > Add, check I agree, and Download the
   Intune public key (`.pem`).
2. In ABM, go to Preferences (or Settings in the newer ABM) > MDM Servers > Add MDM Server; name it
   `Intune MDM Server – Apple – Migration`; Upload the Intune public key; Save; then Download Token (`.p7m`).
3. Back in Intune, on the Add token blade enter the Apple ID used for ABM, Browse to the `.p7m`, and Upload.
4. Confirm the token appears under Enrollment program tokens. Run `WS1IOS-Discovery.ps1` to verify the APNs cert
   and ADE token are present.

### Step 5. Set the default ADE MDM server for new device sync (optional but recommended)
1. In ABM > Preferences > MDM Servers, you can set `Intune MDM Server – Apple – Migration` as the default server
   for new device types so newly purchased devices land in Intune automatically. Existing devices are still
   re-assigned per ring in Step 9 — do not bulk-reassign here.

### Step 6. Create the Intune ADE enrollment profile (supervised)
1. In Intune, go to Devices > Enrollment > Apple > Enrollment program tokens, open the token from Step 4, then
   open the Profiles tab > Create profile > iOS/iPadOS.
2. Enter the name `iOS Migration – Corporate Supervised – Pilot` and a description.
3. User affinity: choose Enroll with user affinity (so each device has its primary user) unless these are shared
   appliances; supervised corporate devices typically use user affinity.
4. Management options: enable Supervised; set Locked enrollment = Yes (matches a corporate Workspace ONE posture).
5. Setup Assistant: hide the panes you do not want (Apple ID, Restore, Privacy, etc.) for a clean first-run that
   matches the prior experience.
6. Review + Create. Repeat to create `iOS Migration – Corporate Supervised – Broad` for the broad ring (identical
   settings; the separate name keeps ring assignment auditable).

### Step 7. Build the parity apps (store and VPP)
1. Apps > iOS/iPadOS > Add. For each app in the parity matrix, add it as an iOS store app or, for licensed apps, a
   Volume Purchase Program (VPP) app, identifying it by its exact store publisher name and bundle ID to avoid
   selecting a similarly-named app.
2. Assignments: assign Required to the ring groups (Step 8) so a re-enrolled device installs them automatically.

### Step 8. Create the migration ring groups
1. Entra > Groups > New group > Security; name it `iOS Migration – Pilot Ring – Pilot`; add the pilot device
   serials/users.
2. Repeat to create `iOS Migration – Broad Ring – Expand` for the rest of the fleet.
3. Prefer automation? Run `WS1IOS-Set-MigrationRingTargeting.ps1` to create the ring groups (default `-WhatIf`).

### Step 9. Build parity configuration and compliance
1. Devices > Configuration > Create > New policy > iOS/iPadOS. Re-create each in-scope profile from the parity
   matrix; name the corporate Wi-Fi `iOS Parity – Corporate Wi-Fi – Cutover` and the restrictions
   `iOS Parity – Device Restrictions – Cutover`. Add VPN, email, and certificate profiles as the matrix requires.
2. Devices > Compliance > Create policy > iOS/iPadOS; name it `iOS Parity – Compliance Baseline – Cutover` and set
   rules matching (or improving on) the Workspace ONE baseline (min OS, jailbreak detection, passcode).
3. Assignments: assign every parity profile, the compliance policy, and the parity apps to
   `iOS Migration – Pilot Ring – Pilot` first.

---

## Phase 3 (Pilot) — re-assign and re-enroll the pilot ring

### Step 10. Communicate to pilot users
1. Send the approved pilot notice: back up personal data, expected downtime, and the steps to sign back in after
   re-enroll. The device will be erased — this must be explicit.

### Step 11. Re-assign the pilot devices in Apple Business Manager
1. In ABM > Devices, select the pilot iPhone/iPad serial numbers.
2. Choose Edit MDM Server (Edit Device Management in the newer ABM) and select
   `Intune MDM Server – Apple – Migration`; Confirm.
   *(This moves the devices away from the Workspace ONE MDM server. Do not unenroll them in Workspace ONE yet —
   the device keeps responding to Workspace ONE until it is erased.)*
3. In Intune, on the token > Devices, click Sync (Apple rate-limits — allow a few minutes), then select the pilot
   serials > Assign profile > `iOS Migration – Corporate Supervised – Pilot`.

### Step 12. Re-enroll each pilot device (wipe-and-re-enroll for supervised ADE)
1. On (or for) each pilot device, erase it: Settings > General > Transfer or Reset > Erase All Content and
   Settings (or push a remote wipe). For a supervised ADE device this is required so it returns to Setup Assistant.
2. Power on, choose language/region, connect to network.
3. Setup Assistant shows Remote Management naming your organization (now Intune) > continue. The device enrolls
   supervised under Intune, joins its ring group, installs the parity apps, and applies the parity profiles.
4. Sign in (user affinity) and confirm the home screen, apps, and connectivity match the prior experience.

---

## Phase 4 (Validate) — pilot gate

### Step 13. Validate the pilot
1. Run `WS1IOS-Discovery.ps1` (tenant readiness) and `WS1IOS-Validation.ps1` (per pilot device), then
   `WS1IOS-Report.ps1` for migration status and app parity.
2. Pass criteria: each pilot device is enrolled supervised under Intune, no longer managed by Workspace ONE, a
   member of `iOS Migration – Pilot Ring – Pilot`, has the parity Wi-Fi/restrictions/compliance applied, and the
   parity apps installed.
3. On the device, confirm Wi-Fi/email/VPN work and a managed app opens.

> **Pilot-ring gate:** do not proceed to the broad ring until the pilot pass criteria are met for every pilot
> device. **Rollback note:** to revert a device, re-assign it in ABM back to the Workspace ONE MDM server, erase,
> and re-enroll through Setup Assistant — restoring source management. Keep the Workspace ONE server live until the
> ring is signed off.

---

## Phase 5 (Expand) — broad rings

### Step 14. Expand by ring
1. Assign the parity profiles, compliance policy, and parity apps to `iOS Migration – Broad Ring – Expand`.
2. For each broad wave, repeat Steps 10 to 13: communicate, re-assign in ABM, sync and assign
   `iOS Migration – Corporate Supervised – Broad`, erase and re-enroll, then validate with the scripts before
   widening to the next wave.

### Step 15. Decommission the source
1. Once a ring is validated and stable, unenroll those devices from Workspace ONE and retire the Workspace ONE ABM
   MDM server only after the entire fleet has migrated and been signed off. Keep rollback available until then.


---


# 5. Testing Guide — Workspace ONE to Intune iOS/iPadOS Device Migration

Run after the pilot ring re-enrolls (Implementation Step 12) and after each broad wave.

## Test 1 — ABM re-assignment took effect
Do: In Apple Business Manager > Devices, open a migrated device and confirm its MDM server is
`Intune MDM Server – Apple – Migration`.
Expected: The device shows the Intune MDM server, not the Workspace ONE server.

## Test 2 — Device enrolled supervised in Intune
Do: On a pilot device run `WS1IOS-Validation.ps1`, or check Intune > Devices > iOS/iPadOS.
Expected: The device is present, Supervised = Yes, enrolled via Automated Device Enrollment, and in its ring group.

## Test 3 — No longer managed by Workspace ONE
Do: Confirm the device no longer responds to Workspace ONE (the management profile is the Intune one after erase).
Expected: The device shows only the Intune management profile; Workspace ONE no longer controls it.

## Test 4 — Enrollment profile applied
Do: In Intune, on the ADE token > Devices, confirm the assigned profile.
Expected: Pilot devices show `iOS Migration – Corporate Supervised – Pilot` (broad shows the Broad profile).

## Test 5 — Configuration parity
Do: Run `WS1IOS-Validation.ps1`; on the device check Wi-Fi, email, VPN, and restrictions.
Expected: `iOS Parity – Corporate Wi-Fi – Cutover` and `iOS Parity – Device Restrictions – Cutover` are applied and connectivity works.

## Test 6 — App parity
Do: Run `WS1IOS-Report.ps1` (app parity section) and check the device home screen.
Expected: The parity apps from the matrix are installed and assignments report Installed.

## Test 7 — Compliance
Do: Intune > Devices > Compliance, or `WS1IOS-Validation.ps1`.
Expected: `iOS Parity – Compliance Baseline – Cutover` evaluates the device as Compliant.

## Test 8 — Fleet migration report
Do: Run `WS1IOS-Report.ps1`.
Expected: A clear per-device view of supervision, enrollment profile, ring group, and app-parity status.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 7 pass for every pilot device; users confirm normal use |
| Broad pass | Tests 1 to 5 and 8 pass for the wave before the next wave begins |


---


# 6. Troubleshooting Guide — Workspace ONE to Intune iOS/iPadOS Device Migration

Use `WS1IOS-Validation.ps1` / `WS1IOS-Discovery.ps1` for state, `WS1IOS-Report.ps1` for fleet status, and
`WS1IOS-Remediation.ps1` for safe fixes (default `-WhatIf`).

## A. Device will not move to Intune
| Symptom | Cause | Remediation |
|---|---|---|
| Device still managed by Workspace ONE after ABM re-assignment | Not yet erased — re-assignment only takes effect on the next Setup Assistant | Erase the device (Erase All Content and Settings or remote wipe) so it re-enrolls under Intune |
| Re-assigned device does not show in Intune | ADE not synced, or profile not assigned | In Intune on the token > Devices click Sync (allow for Apple rate limits), then Assign profile |
| Setup Assistant shows the old organization | ABM still points to the Workspace ONE MDM server | Re-confirm Edit MDM Server in ABM is `Intune MDM Server – Apple – Migration` before erasing |

## B. Enrollment / supervision problems
| Symptom | Cause | Remediation |
|---|---|---|
| Device enrolls but is not supervised | Manual enrollment instead of ADE, or supervision off in the profile | Use ADE (Setup Assistant) with the enrollment profile; confirm Supervised is enabled in the profile |
| Remote Management screen skipped | Device not in ABM under the Intune server | Verify the serial is assigned to the Intune MDM server and synced into Intune |
| Enrollment fails after erase | APNs cert expired or ADE token stale | Run `WS1IOS-Discovery.ps1`; renew the APNs cert / re-download the ADE token if flagged |

## C. App or profile parity gaps
| Symptom | Cause | Remediation |
|---|---|---|
| Apps not installing after re-enroll | App not assigned to the ring group, or no VPP licenses | Confirm Required assignment to the ring group; check the VPP token and available licenses |
| Wi-Fi / VPN / email missing | Parity profile not assigned to the ring group | Assign `iOS Parity – Corporate Wi-Fi – Cutover` and the other parity profiles to the ring group |
| Device shows Not compliant | Compliance policy not assigned, or rule not met | Assign `iOS Parity – Compliance Baseline – Cutover`; check OS version / passcode / jailbreak rules |

## D. Ring and group issues
- Device not picking up policy: confirm it is a member of `iOS Migration – Pilot Ring – Pilot` (or the broad ring)
  and that profiles/apps are assigned to that exact group.

## E. Rollback
- To revert a device: in ABM re-assign it back to the Workspace ONE MDM server, erase, and re-enroll through Setup
  Assistant so source management is restored. Keep the Workspace ONE MDM server live until the ring is signed off.

## F. Source-platform issues (Workspace ONE)
- Workspace ONE console behavior, its profile export, and its unenrollment steps are the source vendor's domain and
  are deferred to VMware documentation. This guide covers the Intune and Apple Business Manager side.

## G. When to escalate
If a device is correctly assigned to the Intune MDM server in ABM, synced, erased, and still will not enroll after
an APNs/ADE check passes, capture the device console logs and open an Apple Business Manager and/or Microsoft
support case.


---


# 7. Best Practices — Workspace ONE to Intune iOS/iPadOS Device Migration

- **Ring everything.** A small pilot ring catches a broken parity profile or a missed app before it touches the
  fleet — the single most important practice in an erase-and-re-enroll migration.
- **Treat re-enroll as a wipe.** For supervised ADE devices, plan for data loss: tell users to back up, confirm
  iCloud/Managed Apple ID backups where used, and schedule the erase in a known window.
- **Build parity before you re-assign.** Re-create every app and profile in Intune and assign them to the ring
  group first, so a device lands fully configured the moment Setup Assistant finishes. Use the parity matrix as the
  acceptance test.
- **Name objects consistently.** Use the `<Purpose> – <Scope> – <Stage>` convention (for example
  `iOS Parity – Corporate Wi-Fi – Cutover`) so every enrollment profile, parity policy, and ring group is
  auditable and reusable across waves.
- **Re-assign in ABM, do not unenroll in Workspace ONE first.** The device keeps working under Workspace ONE until
  it is erased; leaving the source live preserves rollback until the ring is signed off.
- **Respect Apple rate limits.** Allow time between ABM re-assignment, Intune sync, and profile assignment; do not
  bulk-reassign the whole fleet at once.
- **Communicate per ring.** A clear notice — backup reminder, downtime window, re-sign-in steps — dramatically
  reduces tickets during an erase-based migration.
- **Keep a rollback ready.** Document re-assigning the device back to the Workspace ONE MDM server and re-enrolling;
  do not retire the source MDM server until the whole fleet is migrated and stable.
- **Validate before widening.** Run the scripts and meet the pilot gate before the broad ring; repeat the gate per
  wave.
- **Document the cutover.** Record the parity matrix, ring membership, and dates for audit and repeatability.


---


# 8. Deliverables Summary — Workspace ONE to Intune iOS/iPadOS Device Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The Apple migration model, ABM re-assignment, wipe-and-re-enroll reality, parity, ringed cutover |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: connect ABM to Intune, build enrollment profiles, re-assign in ABM, re-enroll by ring, parity, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WS1IOS-Discovery.ps1` | Tenant readiness: APNs cert, ADE token, VPP token, parity profiles/compliance, ring groups (read-only) |
| `WS1IOS-Validation.ps1` | Per-device check: supervised, ADE-enrolled, ring membership, compliance, profiles applied (read-only) |
| `WS1IOS-Report.ps1` | Fleet migration status and app-parity report via Microsoft Graph (read-only) |
| `WS1IOS-Remediation.ps1` | Safe remediation for stuck enrollments (sync managed devices); default `-WhatIf` |
| `WS1IOS-Set-MigrationRingTargeting.ps1` | Builds the pilot/broad migration ring groups; default `-WhatIf` |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: **Assess to Configure to Pilot to Validate to Expand.**

## Outcome
iPhones and iPads moved from Workspace ONE to Intune — re-assigned in Apple Business Manager, re-enrolled supervised
with app and profile parity, and cut over by ring with clear user comms — proven on a pilot before the fleet.
