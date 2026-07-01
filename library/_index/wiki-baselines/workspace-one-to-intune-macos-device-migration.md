# Workspace ONE to Intune — macOS Device Migration

> **Version 1.0.0** · Category: Migrations · Solution code: WS1MAC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Workspace ONE to Intune: macOS Device Migration

Moving a Mac fleet off Workspace ONE and onto Microsoft Intune is not a switch you flip — it is a
device handoff. Each Mac must be re-assigned in Apple Business Manager from the old MDM server to
Intune, re-enrolled, and then rebuilt to the same posture it had before: settings-catalog policies,
custom `.mobileconfig` profiles, and shell scripts, all at parity. Done ad hoc, it produces
half-managed Macs, dropped profiles, and unhappy users. Done the repeatable way, it is a controlled,
ringed cutover you can prove on a pilot before you scale.

This is a complete, deploy-it-today package for migrating macOS devices from Workspace ONE to
Microsoft Intune, written for an administrator with no prior migration experience. It treats
Workspace ONE internals as the vendor's domain (deferred to VMware documentation) and gives exact,
named steps for the Microsoft Intune and Apple Business Manager surfaces you control.

## What you get
- A plain-language Solution Overview of the macOS migration model — Apple Business Manager
  re-assignment, ADE / Account-driven re-enrollment, and rebuilding configuration for parity.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps: connect ABM to Intune, build enrollment
  profiles, reassign Macs in ABM, re-enroll by ring, rebuild profile and shell parity, validate, expand.
- Five PowerShell scripts for migration-readiness discovery, per-device enrollment and parity
  validation, a migration status and parity report, safe remediation of stuck enrollments, and a
  migration-ring group builder.
- Testing and Troubleshooting guides with explicit pass/fail gates.

## What this delivers
A repeatable Workspace ONE to Intune macOS migration: each Mac re-assigned in Apple Business Manager,
re-enrolled into Intune via Automated Device Enrollment or Account-driven enrollment, and rebuilt to
full configuration parity, rolled out in migration rings with a pilot gate and a documented rollback.

## The standard deployment model
Assess to Configure to Pilot to Validate to Expand.

## Outcome
Macs moved from Workspace ONE to Intune — re-assigned in Apple Business Manager, re-enrolled, and
rebuilt to full macOS profile and shell-script parity — proven on a pilot ring before you scale.


---


# 1. Solution Overview — Workspace ONE to Intune: macOS Device Migration

## What this migration is
Migrating macOS devices from VMware Workspace ONE UEM to Microsoft Intune means changing which MDM
authority manages each Mac. For Apple devices that authority is decided in Apple Business Manager
(ABM): an enrolled Mac is tied, through ABM, to one MDM server. Moving to Intune therefore requires
three things to happen for each device — re-assign the Mac in ABM from the Workspace ONE MDM server
to the Intune MDM server, re-enroll the Mac into Intune, and rebuild its configuration in Intune so
the device ends up with the same posture it had under Workspace ONE.

Unlike a Windows migration, a Mac cannot simply switch authority in place. Apple's model ties the
management profile to the device record in ABM, so re-enrollment is the mechanism — either Automated
Device Enrollment (ADE, formerly DEP) for corporate-owned Macs, or Account-driven enrollment for
user-initiated scenarios. The configuration is then rebuilt across the three macOS Intune surfaces:
the settings catalog, custom `.mobileconfig` profiles, and shell scripts.

## Why this is done this way (the rationale)
- A Mac obeys exactly one MDM server at a time. ABM is the system of record that decides which one,
  so re-assignment in ABM is the unavoidable hinge of any Mac MDM migration.
- Apple does not provide an in-place authority swap for macOS; re-enrollment is how the device picks
  up the new management profile. ADE makes that re-enrollment hands-off for corporate Macs.
- Configuration is not portable between MDMs. Workspace ONE profiles, baselines, and scripts do not
  transfer to Intune; the posture must be rebuilt natively as settings-catalog policies, custom
  `.mobileconfig` profiles, and shell scripts so it is supportable in the target.
- Macs are live, in-use production devices. A ringed cutover — pilot first, then expand — catches a
  parity gap or a re-enrollment failure on a few devices before it reaches the fleet.

## How it works (end to end)
1. Connect ABM to Intune: add Intune as an MDM server in ABM and stand up the Automated Device
   Enrollment connection (ADE token) and the Apple MDM Push (APNs) certificate in Intune.
2. Build the macOS enrollment profile in Intune so re-enrolled Macs receive the right setup,
   management mode, and user experience.
3. Establish the parity target: inventory the current Workspace ONE macOS posture (profiles,
   restrictions, scripts) and map each item to its Intune surface — settings catalog, custom
   `.mobileconfig`, or shell script.
4. Build the parity objects in Intune (settings-catalog policies, custom profiles, shell scripts)
   assigned to the migration groups, so configuration is waiting when a Mac arrives.
5. Reassign Macs in ABM, ring by ring, from the Workspace ONE MDM server to the Intune MDM server.
6. Re-enroll the Macs into Intune (ADE for corporate Macs; Account-driven for user-initiated),
   removing Workspace ONE management as part of the cutover.
7. Validate parity on the pilot ring — enrollment succeeded, profiles and scripts applied, posture
   matches — then expand ring by ring to the rest of the fleet.

## The three macOS configuration surfaces (parity targets)
- Settings catalog — most modern macOS controls (Software Update, restrictions, login window,
  security and privacy) rebuilt as settings-catalog policies.
- Custom `.mobileconfig` profiles — any control with no settings-catalog payload, delivered as an
  uploaded Apple configuration profile.
- Shell scripts — controls enforceable only by a command, delivered as Intune macOS shell scripts
  on a re-enforcement schedule.

## What you control in the target (Intune + ABM)
- The ABM-to-Intune connection (MDM server assignment, ADE token, APNs certificate).
- The macOS enrollment profile (setup steps, management mode, user experience).
- The rebuilt configuration parity (settings catalog, custom profiles, shell scripts).
- The migration rings (which Macs move in which wave) and the pilot gate.

## What stays with the vendor (deferred)
- Workspace ONE UEM internals — how to release, unenroll, or de-assign a Mac on the Workspace ONE
  side, and the exact Workspace ONE console paths — are deferred to VMware Workspace ONE
  documentation. This solution drives the Intune and Apple Business Manager surfaces you own.

## Limitations (be honest with buyers)
- Configuration does not migrate; it is rebuilt. Plan the parity mapping work explicitly.
- Re-enrollment is user-visible on Macs not enrolled via ADE; communications matter.
- ABM re-assignment and the Workspace ONE-side release are coordinated, not instantaneous — expect a
  brief coexistence window per device.
- FileVault recovery keys and certificate-based items may need re-issue under the new authority;
  treat them as explicit parity items, not assumptions.

## The standard deployment model
> Connect ABM to Intune, build the enrollment profile, rebuild parity objects, then per ring:
> reassign in ABM, re-enroll, validate parity, expand. Model: Assess to Configure to Pilot to
> Validate to Expand, with a pilot-ring gate and a documented rollback.


---


# 2. Requirements Guide — Workspace ONE to Intune: macOS Device Migration

Verify every requirement before configuring. Each entry: Description, Why, Verify, and
Implement-if-missing. Category-wide prerequisites are in `global-requirements-migrations.md` (target
Entra ID tenant, target Intune licensing/admin, source platform access, source inventory, enrollment
prerequisites, pilot/wave structure, and change control/coexistence/rollback). The items below are
the macOS-specific prerequisites for this migration.

## 2.1 Apple Business Manager access and the Intune MDM server
Description: An Apple Business Manager organization where you can manage MDM servers and device
assignments, with Intune added as an MDM server.
Why: ABM is the system of record that decides which MDM manages each Mac; you reassign devices here.
Verify: Sign in to `https://business.apple.com` as an ABM Administrator or Device Enrollment Manager;
under MDM servers, confirm an Intune MDM server entry exists.
Implement: In ABM add a new MDM server and link it to Intune (see Implementation Step 1); ensure you
hold a role that can reassign devices.

## 2.2 Apple MDM Push (APNs) certificate in Intune
Description: A valid, unexpired Apple MDM Push certificate connecting Intune to Apple's push service.
Why: No Apple device — including macOS — can be managed by Intune without an active APNs certificate.
Verify: Intune to Devices to Enrollment to Apple to Apple MDM Push certificate shows present and not
near expiry. Run `WS1MAC-Discovery.ps1`.
Implement: Devices to Enrollment to Apple to Apple MDM Push certificate; create/renew with the same
Apple ID you will keep long term (never let it lapse — management stops if it does).

## 2.3 Automated Device Enrollment (ADE) token / enrollment program token
Description: An ADE (DEP) token in Intune that syncs the corporate Macs assigned to the Intune MDM
server in ABM.
Why: ADE is how corporate-owned Macs re-enroll hands-off after you reassign them in ABM.
Verify: Intune to Devices to Enrollment to Apple to Enrollment program tokens shows a token with
synced macOS devices. Run `WS1MAC-Discovery.ps1`.
Implement: In ABM download the server token for the Intune MDM server; in Intune to Devices to
Enrollment to Apple to Enrollment program tokens to Add, upload it and sync.

## 2.4 Source access: Workspace ONE UEM admin
Description: Administrative access to the Workspace ONE UEM console for the in-scope Macs.
Why: You must inventory the current macOS posture and release/unenroll devices on the source side
during cutover.
Verify: You can sign in to the Workspace ONE UEM console and export the macOS device list, profiles,
and scripts for the migration scope.
Implement: Obtain the Workspace ONE admin role from the platform owner. (Workspace ONE console paths
and unenroll mechanics are deferred to VMware Workspace ONE documentation.)

## 2.5 The macOS parity target (current posture inventory)
Description: A documented inventory of every Workspace ONE macOS profile, restriction, payload, and
script that must be reproduced in Intune, each mapped to its Intune surface.
Why: Parity is the goal of the migration; you cannot rebuild what you have not inventoried and mapped.
Verify: You have a mapping table — each Workspace ONE item to settings catalog, custom
`.mobileconfig`, or shell script.
Implement: Export the macOS configuration from Workspace ONE; sort each item into one of the three
Intune surfaces (see Implementation Step 4). Record the parity tag `WS1MAC-Parity-vX`.

## 2.6 Custom `.mobileconfig` source files (where needed)
Description: The Apple configuration profile files for any control with no settings-catalog payload.
Why: Some payloads exist only as custom profiles; without the file you cannot reach parity.
Verify: For each control mapped to "custom profile", you have the `.mobileconfig` file ready to upload.
Implement: Obtain or author the `.mobileconfig` (Apple Configurator, a profile tool, or export from
the source) for each such control.

## 2.7 Migration ring groups
Description: Microsoft Entra security groups defining the migration rings — at minimum a pilot ring
and one or more expansion rings.
Why: The cutover is ringed; the pilot ring is the gate before fleet migration.
Verify: Entra to Groups shows the migration ring groups. Run `WS1MAC-Set-MigrationRingTargeting.ps1`
to build/populate them.
Implement: Entra to Groups to New group to Security; create the rings named per Step 3, or run
`WS1MAC-Set-MigrationRingTargeting.ps1`.

## 2.8 User communications plan
Description: A user-facing notice covering what will happen on the Mac, when, and any user action
(for non-ADE re-enrollment) plus support contact.
Why: macOS re-enrollment can be user-visible; clear comms cut tickets and failed enrollments.
Verify: A comms message and schedule exist per ring.
Implement: Draft a short per-ring notice (timing, what to expect, who to contact) before cutover.

---
## Checklist
- [ ] Apple Business Manager access + Intune added as an MDM server
- [ ] Apple MDM Push (APNs) certificate active — `WS1MAC-Discovery.ps1`
- [ ] ADE / enrollment program token synced — `WS1MAC-Discovery.ps1`
- [ ] Workspace ONE UEM admin access (source)
- [ ] macOS parity target inventoried and mapped to Intune surfaces
- [ ] Custom `.mobileconfig` source files ready where needed
- [ ] Migration ring groups created — `WS1MAC-Set-MigrationRingTargeting.ps1`
- [ ] User communications plan per ring


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


# 3. Implementation Guide — Workspace ONE to Intune: macOS Device Migration

Follow these steps in order. Intune steps are in the Microsoft Intune admin center
(`https://intune.microsoft.com`); Apple Business Manager steps are at `https://business.apple.com`.
Workspace ONE console steps (releasing/unenrolling a Mac on the source side) are deferred to VMware
Workspace ONE documentation and flagged where they occur.

> Model: Assess to Configure to Pilot to Validate to Expand. Connect ABM to Intune and rebuild the
> macOS posture once; then per ring reassign in ABM, re-enroll, validate parity, and expand. The
> pilot ring is a gate — do not expand until it passes (Step 9) and keep the rollback (Step 8.6) ready.

> Naming: every artifact is named `<Purpose> - <Scope> - <Stage>` and reused verbatim across the
> docs and scripts. Migration rings: `WS1MAC Migration - Pilot Ring` and
> `WS1MAC Migration - Production Ring`. Parity objects carry the parity tag `WS1MAC-Parity-vX` in
> their description.

## Step 1 — Connect Apple Business Manager to Intune (Assess to Configure)
1. Confirm the Apple MDM Push (APNs) certificate: Intune to Devices to Enrollment to Apple to
   Apple MDM Push certificate; present and not near expiry (Requirement 2.2). Run
   `WS1MAC-Discovery.ps1`.
2. In Apple Business Manager to your account to Preferences (or Settings) to MDM servers, add a new
   MDM server named `WS1MAC Intune - macOS MDM Server`. Download its public key from Intune first if
   prompted: Intune to Devices to Enrollment to Apple to Enrollment program tokens to Add, which
   provides the public key to upload in ABM, then download the ABM server token.
3. In Intune to Devices to Enrollment to Apple to Enrollment program tokens to Add, upload the ABM
   server token and complete the connection. Confirm the token appears and that synced macOS device
   count is non-zero once Macs are assigned (Requirement 2.3). Run `WS1MAC-Discovery.ps1`.

## Step 2 — Build the macOS enrollment profile (Configure)
1. Intune to Devices to Enrollment to Apple to Enrollment program tokens to (open the token
   `WS1MAC Intune - macOS MDM Server`) to Profiles to Create profile to macOS.
2. Name: `WS1MAC Enrollment - macOS - ADE`. Description: include the parity tag `WS1MAC-Parity-vX`.
   Next.
3. Configure the enrollment experience: management mode (supervised for corporate Macs), Setup
   Assistant screens to skip/show, locked enrollment per policy, and the user experience. Next.
4. Review and Create. This profile is what re-enrolled corporate Macs receive after ABM reassignment.
5. (User-initiated Macs) For Macs that will use Account-driven enrollment instead of ADE, confirm the
   Account-driven enrollment path is enabled per your tenant; name that flow
   `WS1MAC Enrollment - macOS - AccountDriven` in your runbook. Account-driven enrollment specifics
   are configured per the current Intune Apple enrollment options.

## Step 3 — Create the migration ring groups (Configure)
1. Entra to Groups to New group to Security to name `WS1MAC Migration - Pilot Ring` to add a few
   representative Macs. Create.
2. Create `WS1MAC Migration - Production Ring` for the rest of the in-scope fleet. Create.
3. Or run `WS1MAC-Set-MigrationRingTargeting.ps1` to create and populate these groups from a device
   list.

## Step 4 — Establish the parity target and map each item (Assess to Configure)
1. From Workspace ONE, export the current macOS posture: profiles, restrictions, payloads, and
   scripts for the in-scope Macs (Requirement 2.5). (Workspace ONE export mechanics are deferred to
   VMware Workspace ONE documentation.)
2. Sort each item into one of the three Intune surfaces:
   - settings catalog — most controls (Software Update, restrictions, login window, security and
     privacy), built in Step 5.
   - custom `.mobileconfig` — controls with no settings-catalog payload, built in Step 6.
   - shell script — controls enforceable only by a command, built in Step 7.
3. Record the mapping table and the parity tag `WS1MAC-Parity-vX`; this tag goes in every parity
   object's description so the set is traceable.

## Step 5 — Build the settings-catalog parity policy (Configure)
1. Intune to Devices to macOS to Configuration to Create to New Policy.
2. Platform: macOS. Profile type: Settings catalog. Create.
3. Name: `WS1MAC Parity - macOS Settings - Pilot`. Description: parity tag `WS1MAC-Parity-vX`. Next.
4. Click Add settings. For each mapped control from Step 4, search the settings picker, add it, and
   set the value to match the Workspace ONE posture (the source values are the parity reference).
5. Next to Assignments to Add groups to `WS1MAC Migration - Pilot Ring`. Next to Create.

## Step 6 — Build the custom `.mobileconfig` parity profiles (Configure, only if needed)
1. For each control with no settings-catalog payload (from Step 4), have the `.mobileconfig` file
   ready (Requirement 2.6).
2. Intune to Devices to macOS to Configuration to Create to New Policy to Platform: macOS to Profile
   type: Templates to Custom to Create.
3. Name: `WS1MAC Parity - macOS Custom - Pilot`. Description: parity tag. Provide a deployment channel
   and upload the `.mobileconfig` configuration profile file.
4. Assignments to Add groups to `WS1MAC Migration - Pilot Ring`. Create.

## Step 7 — Build the shell-script parity (Configure, only for script-only controls)
1. For each control enforceable only by a command (from Step 4): Intune to Devices to macOS to Shell
   scripts to Add.
2. Name: `WS1MAC Parity - macOS Shell - Pilot`. Description: parity tag. Upload the shell script that
   implements the control.
3. Script settings: run as root = Yes where required; set a run frequency so the control re-enforces
   on a schedule (re-applying corrects drift). Next.
4. Assignments to Add groups to `WS1MAC Migration - Pilot Ring`. Add to Next to Add.

## Step 8 — Migrate the pilot ring: reassign in ABM, re-enroll, with rollback ready (Pilot)
1. Confirm the parity objects (Steps 5 to 7) are assigned to `WS1MAC Migration - Pilot Ring` and the
   enrollment profile `WS1MAC Enrollment - macOS - ADE` is assigned to the token. Run
   `WS1MAC-Validation.ps1` against a pilot Mac to confirm targeting.
2. In Apple Business Manager, select the pilot Macs and reassign their MDM server from the Workspace
   ONE MDM server to `WS1MAC Intune - macOS MDM Server`. In Intune, sync the enrollment program token
   (Enrollment program tokens to the token to Sync) and confirm the pilot Macs now appear as assigned
   to Intune.
3. Release the pilot Macs from Workspace ONE management on the source side so they can re-enroll
   cleanly. (The exact Workspace ONE unenroll/release steps are deferred to VMware Workspace ONE
   documentation.)
4. Re-enroll the pilot Macs into Intune:
   - Corporate (ADE) Macs: erase/reset or trigger re-enrollment so the Mac runs Setup Assistant and
     picks up `WS1MAC Enrollment - macOS - ADE` automatically.
   - User-initiated Macs: have the user complete Account-driven enrollment per the comms (Step 2.5,
     Requirement 2.8).
5. Confirm enrollment: Intune to Devices to macOS to macOS devices shows each pilot Mac enrolled and
   managed by Intune. Run `WS1MAC-Validation.ps1` per device.
6. Rollback (if a pilot Mac fails to enroll or a parity gap blocks use): reassign that Mac's MDM
   server in ABM back to the Workspace ONE MDM server and re-enroll it to the source, or remove the
   Intune assignment of the offending parity object and sync. Record the failure and resolve before
   retrying. ABM reassignment back to the source is the fastest safe rollback for an individual Mac.

## Step 9 — Validate parity on the pilot, then gate (Validate)
1. Run `WS1MAC-Validation.ps1` per pilot Mac: enrollment succeeded, settings-catalog policy, custom
   profiles, and shell scripts all applied.
2. Run `WS1MAC-Report.ps1` for the pilot ring: migration status and per-object parity (succeeded vs
   drift) across the pilot Macs.
3. Soak the pilot: have pilot users run their real apps and workflows for several business days; watch
   for parity gaps (missing restriction, login window, FileVault, certificate, app config) and
   re-enrollment issues. Complete the Testing Guide (document 5).
4. Gate: do not expand until the pilot passes the Testing Guide gate AND no unresolved enrollment or
   parity gap remains.

## Step 10 — Expand to production (Expand)
1. Duplicate each piloted parity object (Intune to policy to Duplicate where available) and rename the
   copies `WS1MAC Parity - macOS Settings - Production`, `WS1MAC Parity - macOS Custom - Production`,
   and `WS1MAC Parity - macOS Shell - Production`, keeping the parity tag. (For shell scripts,
   re-create with the production name.) Assign them to `WS1MAC Migration - Production Ring`.
2. Migrate the production ring in waves: reassign each wave's Macs in ABM to
   `WS1MAC Intune - macOS MDM Server`, release them from Workspace ONE (deferred to VMware docs),
   sync the token, and re-enroll (Step 8.2 to 8.5).
3. Re-run `WS1MAC-Report.ps1` after each wave to confirm enrollment and parity and to catch drift;
   use `WS1MAC-Remediation.ps1` (default preview) for stuck enrollments.
4. Decommission: once a Mac is confirmed enrolled in Intune at parity, remove it from Workspace ONE
   per your change record.

---
### Order of operations
`Connect ABM to Intune to Enrollment profile to Ring groups to Map parity to Settings-catalog parity to Custom .mobileconfig parity to Shell parity to Pilot (reassign in ABM, re-enroll, rollback ready) to Validate parity + gate to Expand in waves`


---


# 5. Testing Guide — Workspace ONE to Intune: macOS Device Migration

Run after the pilot ring migrates (Implementation Step 8) and again per production wave (Step 10).
Tests use the named artifacts from the Implementation Guide.

## Test 1 — ABM reassignment took effect
Do: In Apple Business Manager, confirm the pilot Macs show MDM server
`WS1MAC Intune - macOS MDM Server`; in Intune to Devices to Enrollment to Apple to Enrollment program
tokens, sync the token and confirm the Macs are assigned to Intune.
Expected: Each pilot Mac is assigned to the Intune MDM server in ABM and appears under the Intune
enrollment token.

## Test 2 — Re-enrolled into Intune
Do: Intune to Devices to macOS to macOS devices; or run `WS1MAC-Validation.ps1` per device.
Expected: Each pilot Mac is enrolled and managed by Intune (no longer managed by Workspace ONE).

## Test 3 — Settings-catalog parity applied
Do: Intune to Devices to macOS to Configuration to `WS1MAC Parity - macOS Settings - Pilot` to Device
status / Per-setting status; or `WS1MAC-Validation.ps1`.
Expected: Pilot Macs show Succeeded; the settings match the Workspace ONE parity reference.

## Test 4 — Custom profiles and shell scripts applied
Do: Check `WS1MAC Parity - macOS Custom - Pilot` (Configuration to Device status) and
`WS1MAC Parity - macOS Shell - Pilot` (Devices to macOS to Shell scripts to the script to Device
status); or `WS1MAC-Validation.ps1`.
Expected: Custom profiles show Succeeded and shell scripts show their last run as success.

## Test 5 — Posture parity (real use)
Do: On a pilot Mac, confirm the migrated posture matches the prior Workspace ONE state — restrictions,
login window, Software Update, FileVault, certificates, and any app config — by using the device for
real work.
Expected: No regression versus the Workspace ONE posture; users can do their normal work.

## Test 6 — Fleet migration + parity report
Do: Run `WS1MAC-Report.ps1` for the ring.
Expected: A clear per-device migration status and per-object parity breakdown (succeeded vs drift)
for the ring.

## Test 7 — Rollback rehearsed (pilot only)
Do: On one pilot Mac, rehearse the rollback (Implementation Step 8.6): reassign in ABM back to the
Workspace ONE MDM server, or remove an Intune parity assignment and sync.
Expected: The rollback path works and is documented before any production wave.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 6 pass on the pilot ring; rollback (Test 7) is rehearsed; no unresolved enrollment or parity gap |
| Wave pass | Tests 1 to 4 and 6 pass for each production wave before the next wave migrates |


---


# 6. Troubleshooting Guide — Workspace ONE to Intune: macOS Device Migration

Use `WS1MAC-Discovery.ps1` for tenant/enrollment readiness, `WS1MAC-Validation.ps1` for per-device
enrollment and parity, `WS1MAC-Report.ps1` for fleet/ring status, and `WS1MAC-Remediation.ps1` for
safe sync-based fixes (preview first). Workspace ONE-side issues (release/unenroll) are deferred to
VMware Workspace ONE documentation.

## A. Mac will not re-enroll into Intune
| Symptom | Cause | Remediation |
|---|---|---|
| ADE Mac does not pick up the enrollment profile | Profile not assigned to the token, or token not synced after ABM reassignment | Confirm `WS1MAC Enrollment - macOS - ADE` is assigned to the token; sync the token; run `WS1MAC-Discovery.ps1` |
| Mac still managed by Workspace ONE | Source management not released before re-enrollment | Release the Mac from Workspace ONE (deferred to VMware docs), then re-enroll |
| Enrollment fails with push errors | APNs certificate expired or wrong Apple ID | Renew the APNs certificate with the long-term Apple ID; never let it lapse |

## B. ABM reassignment not reflecting in Intune
| Symptom | Cause | Remediation |
|---|---|---|
| Reassigned Macs do not appear under the Intune token | Token not synced, or wrong MDM server selected in ABM | In ABM confirm the Mac's MDM server is `WS1MAC Intune - macOS MDM Server`; in Intune sync the enrollment program token |
| Devices show under the old token | They were assigned to the prior MDM server | Reassign in ABM, then sync; the device moves on the next sync |

## C. Configuration parity gaps after enrollment
| Symptom | Cause | Remediation |
|---|---|---|
| A setting/restriction is missing | Control not mapped, or in the wrong Intune surface | Re-check the Step 4 mapping; add it to `WS1MAC Parity - macOS Settings - Pilot`, a custom profile, or a shell script as appropriate |
| Custom profile not applied | Wrong deployment channel or malformed `.mobileconfig` | Re-upload a valid `.mobileconfig` to `WS1MAC Parity - macOS Custom - Pilot`; confirm the channel |
| Shell-script control drifts back | No re-enforcement schedule | Set a run frequency on `WS1MAC Parity - macOS Shell - Pilot`; run `WS1MAC-Remediation.ps1` to re-sync |

## D. Object shows Error / not applied
- Confirm the Mac is enrolled and in the assigned ring group; run `WS1MAC-Validation.ps1`.
- Run `WS1MAC-Remediation.ps1` (preview, then `-WhatIf:$false`) to issue a device sync so the parity
  objects re-evaluate.
- Resolve any conflicting policy that targets the same payload.

## E. FileVault / certificate continuity
- FileVault recovery keys and certificate-based items do not carry over with the device; treat each as
  an explicit parity item and re-issue under Intune. If FileVault escrow is missing post-migration,
  confirm the FileVault policy is assigned and the Mac has re-escrowed its key.

## F. Coexistence confusion (two authorities)
- A Mac briefly managed by both during cutover should be released from Workspace ONE promptly. If a
  Mac is stuck dual-managed, release the source first, then re-sync Intune.

## G. When to escalate
If a Mac is assigned to `WS1MAC Intune - macOS MDM Server` in ABM, released from Workspace ONE, the
token is synced, and the device still will not enroll or apply parity after a sync, collect the device
enrollment state from `WS1MAC-Validation.ps1` and open a Microsoft support case (or, for the source
release behavior, a VMware Workspace ONE support case).


---


# 7. Best Practices — Workspace ONE to Intune: macOS Device Migration

- Migrate in rings, always. A small `WS1MAC Migration - Pilot Ring` proves ABM reassignment,
  re-enrollment, and parity before the `WS1MAC Migration - Production Ring` fleet moves — the single
  most important practice.
- Build parity before you reassign. Have the settings-catalog policy, custom `.mobileconfig` profiles,
  and shell scripts assigned to the ring so configuration is waiting the moment a Mac re-enrolls — not
  scrambled together after.
- Inventory and map the source posture first. Export the Workspace ONE macOS configuration and map
  every item to its Intune surface (settings catalog, custom profile, shell script) with the parity
  tag `WS1MAC-Parity-vX`; you cannot rebuild what you have not catalogued.
- Reassign in ABM and release from the source as one coordinated move. ABM reassignment plus the
  Workspace ONE-side release is what lets the Mac re-enroll cleanly; doing one without the other
  leaves a device half-managed.
- Prefer ADE for corporate Macs. Automated Device Enrollment makes re-enrollment hands-off and
  consistent; reserve Account-driven enrollment for genuinely user-initiated cases.
- Keep the APNs certificate and ADE token healthy. An expired APNs certificate stops all Apple
  management; a stale token will not sync reassigned Macs. Check both with `WS1MAC-Discovery.ps1`
  before each wave.
- Treat FileVault keys and certificates as explicit parity items. They do not carry over with the
  device; plan their re-issue under the new authority rather than assuming continuity.
- Communicate per ring. Tell users what re-enrollment looks like, when it happens, and who to contact;
  clear comms cut tickets and failed enrollments, especially for non-ADE Macs.
- Keep the rollback ready. The fastest safe rollback for a single Mac is to reassign it in ABM back to
  the Workspace ONE MDM server; rehearse it on the pilot before any production wave.
- Validate parity, do not assume it. Run `WS1MAC-Validation.ps1` per device and `WS1MAC-Report.ps1`
  per ring after every wave, and chase any drift with `WS1MAC-Remediation.ps1` (preview first).
- Decommission only after parity is confirmed. Remove a Mac from Workspace ONE only once it is
  enrolled in Intune at full parity, so you always have a coexistence fallback.


---


# 8. Deliverables Summary — Workspace ONE to Intune: macOS Device Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The macOS migration model, why ABM reassignment + re-enrollment + parity rebuild, the three config surfaces, limitations |
| 2. Requirements Guide | Every macOS-specific prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: connect ABM to Intune, enrollment profile, ring groups, parity rebuild, reassign + re-enroll, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WS1MAC-Discovery.ps1` | Migration-readiness: APNs certificate, ADE/enrollment token + synced Macs, enrolled macOS count/version spread, existing macOS config policies (read-only, Graph) |
| `WS1MAC-Validation.ps1` | Per-device enrollment + parity check: managed by Intune, settings-catalog/custom/shell objects applied (read-only, Graph) |
| `WS1MAC-Report.ps1` | Fleet/ring migration status + per-object parity (succeeded vs drift) with optional CSV (read-only, Graph) |
| `WS1MAC-Remediation.ps1` | Safe remediation of stuck enrollments/drift — issues a device sync so parity objects re-apply (defaults to -WhatIf) |
| `WS1MAC-Set-MigrationRingTargeting.ps1` | Builds/populates the migration ring groups (`WS1MAC Migration - Pilot Ring` / `... - Production Ring`) from a device list (defaults to -WhatIf) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess to Configure to Pilot to Validate to Expand.

## Outcome
Macs moved from Workspace ONE to Intune — re-assigned in Apple Business Manager, re-enrolled, and
rebuilt to full macOS profile and shell-script parity — proven on a pilot ring before you scale.
