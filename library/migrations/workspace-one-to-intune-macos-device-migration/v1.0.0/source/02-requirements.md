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
