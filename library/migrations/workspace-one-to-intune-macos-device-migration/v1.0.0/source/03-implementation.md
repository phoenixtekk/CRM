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
