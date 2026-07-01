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
