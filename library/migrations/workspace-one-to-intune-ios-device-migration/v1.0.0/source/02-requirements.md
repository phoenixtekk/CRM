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
