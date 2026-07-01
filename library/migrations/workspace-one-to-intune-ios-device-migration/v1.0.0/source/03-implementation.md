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
