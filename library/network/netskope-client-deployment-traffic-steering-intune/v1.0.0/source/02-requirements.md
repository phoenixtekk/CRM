# 2. Requirements Guide — Netskope Client Deployment & Traffic Steering at Scale (Intune)

Verify every requirement before configuring. Each entry: Description, Why, Verify,
Implement-if-missing. Category-wide prerequisites (Netskope tenant, Entra ID, Intune, admin roles,
network/identity fundamentals, pilot group, change control) are in `global-requirements-network.md` —
confirm those first; the items below are specific to this client-deployment-and-steering solution.

## 2.1 Netskope client installer and tenant-enrollment method
Description: The current Netskope client installer plus the tenant-enrollment method your tenant uses
(for example an enrollment token or identity/SSO-based enrollment).
Why: The Intune app must install the client silently and enroll it to the correct Netskope tenant, or
devices install an unconfigured client that steers nothing.
Verify: You have the installer and the documented silent-install and enrollment parameters from your
Netskope tenant; a manual install on one test device installs and enrolls to your tenant.
Implement: Obtain the installer and enrollment method from your Netskope tenant/account team; confirm
the exact silent-install switches in the official Netskope documentation (deferred to Netskope docs).

## 2.2 Steering configuration authored in the Netskope tenant
Description: A steering profile (`Steering Profile – Corporate – Production`) defined in the Netskope
tenant that specifies which traffic the client steers.
Why: The client steers according to tenant-side configuration; without it, deployment installs an
agent with no defined steering behavior.
Verify: In your Netskope tenant, the steering profile exists and is assigned to your users/devices
(exact console path deferred to Netskope docs).
Implement: Author the steering profile in the Netskope console per the official Netskope documentation.

## 2.3 Exception list for business applications
Description: A defined set of bypass/steering exceptions (`Steering Exceptions – Business Apps –
Production`) for applications that must not be inline-steered or SSL-inspected.
Why: Inline steering and decryption can break apps that pin certificates or dislike proxies; a named,
auditable exception list keeps business apps working without disabling protection broadly.
Verify: The exception entries for your known sensitive apps exist in the tenant configuration; a test
device with the client active can still use those apps.
Implement: Build the exception list in the Netskope console (objects/format deferred to Netskope docs);
record each entry and the app it protects so it is auditable.

## 2.4 SSL/decryption certificate delivery (if SSL inspection is used)
Description: If the steering config inspects SSL, the Netskope root/decryption certificate delivered
to the device trust store via Intune.
Why: Without the trusted certificate, inspected HTTPS traffic throws certificate errors fleet-wide.
Verify: On a test device the certificate is present in the trusted root store and inspected sites load
without certificate warnings.
Implement: Deploy the certificate with an Intune trusted-certificate profile to the same device groups
as the client (certificate source/details deferred to Netskope docs).

## 2.5 Devices enrolled and compliant in Intune
Description: The in-scope Windows devices enrolled in Intune and (where used) compliant.
Why: Intune app and certificate assignments apply only to enrolled devices.
Verify: Intune -> Devices -> All devices shows the target devices; run `NSCLIENT-Discovery.ps1`.
Implement: Enable automatic enrollment and enroll the target devices (global G3).

## 2.6 Rollout-ring groups (pilot first, then larger waves)
Description: Entra security groups for each ring — `Device Group – Pilot – Stage1`,
`Device Group – Early – Stage2`, `Device Group – Broad – Stage3`.
Why: A ringed rollout requires the membership boundaries each wave is assigned to; the pilot ring is
the gate before any expansion.
Verify: Entra -> Groups shows the ring groups; run `NSCLIENT-Set-RolloutRingTargeting.ps1 -WhatIf` to
preview membership.
Implement: Create the groups in Entra (or build them with `NSCLIENT-Set-RolloutRingTargeting.ps1`);
keep the pilot small and representative.

## 2.7 Change window and rollback path
Description: An approved change window and a written rollback (disable steering, remove the client app
assignment, or revert the exception list) before enabling steering on real traffic.
Why: Steering and decryption sit in the live traffic path and must be reversible (global G7).
Verify: A rollback procedure is documented and approved before the pilot ring goes inline.
Implement: Define and approve the rollback and a user-comms plan (global G7).

---
## Checklist
- [ ] Netskope client installer + tenant-enrollment method (Netskope docs)
- [ ] Steering Profile – Corporate – Production authored in the tenant
- [ ] Steering Exceptions – Business Apps – Production defined
- [ ] SSL/decryption certificate delivery configured (if inspecting SSL)
- [ ] Target devices enrolled/compliant in Intune — `NSCLIENT-Discovery.ps1`
- [ ] Ring groups created — `NSCLIENT-Set-RolloutRingTargeting.ps1 -WhatIf`
- [ ] Change window + rollback path approved
