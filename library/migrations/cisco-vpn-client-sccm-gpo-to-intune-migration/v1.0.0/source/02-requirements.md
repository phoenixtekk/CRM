# 2. Requirements Guide — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

Verify **every** requirement before you rebuild anything in Intune. Each entry:
**Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (target Entra
tenant, Intune licensing, source access, inventory, enrollment, pilot/waves, change control) are in
`global-requirements-migrations.md` and are assumed here.

> **Vendor boundary:** the Cisco Secure Client installer, its VPN profile XML schema, the VPN head-end
> (ASA/Firepower/Secure Firewall), and ISE posture are configured per **Cisco's documentation**. This
> guide covers what you need on the **Intune / Entra / SCCM / GPO / certificate** side.

## 2.1 Intune enrollment and admin rights (target)
Description: Devices enrolled in Intune, an Intune-bearing license plan, and the roles to create apps,
VPN profiles, and certificate profiles.
Why: You cannot deliver the client, profile, or certificate from Intune to unenrolled devices, or build
those objects without rights.
Verify: `https://intune.microsoft.com` loads; **Devices** shows the in-scope devices as enrolled; you
hold **Intune Administrator**; **Apps → Windows** and **Devices → Configuration** are reachable.
Implement: Assign M365 E3/E5, Business Premium, or Intune Plan 1; enable Windows automatic enrolment
(global requirement G5); grant least-privilege admin roles.

## 2.2 The Cisco Secure Client installer (from Cisco)
Description: The Cisco-provided Secure Client (AnyConnect) installer media and its **silent install
command line**, at the version you are standardizing on.
Why: Intune wraps this exact installer into a Win32 app; without clean Cisco media and known switches
you cannot rebuild the install.
Verify: `CVPNMIG-Discovery.ps1` reports the installed client version on sample devices; you have the
matching installer and a documented silent command from Cisco.
Implement: Obtain the installer and command line from Cisco's official download/documentation; confirm
it installs silently on a clean test device. (Installer internals and switches are per Cisco docs.)

## 2.3 The current VPN profile XML (source of truth)
Description: The AnyConnect / Secure Client **VPN profile XML** delivered today (server/head-end list,
protocol, split-tunnel, and connection settings).
Why: Intune must deliver a profile with parity so the tunnel behaves identically after the move.
Verify: `CVPNMIG-Discovery.ps1` locates the profile XML in the client profile directory on a sample
device; you can open it and read the head-end list.
Implement: Recover the authoritative profile XML from the SCCM package/source share, the GPO that
drops it, or the Cisco profile editor; treat one copy as the single source of truth for the migration.

## 2.4 The current SCCM/GPO deployment details (source)
Description: Exactly how the client and profile arrive today — the SCCM **package/application +
deployment + target collection**, and/or the **GPO(s)** that install the client, drop the profile XML,
and their linked OUs / security-group filters.
Why: You must know each legacy delivery mechanism to rebuild it in Intune *and* to remove it cleanly at
cutover so the two paths never conflict.
Verify: In the Configuration Manager console, `Software Library → Application Management` shows the app/
package and its deployment; in **Group Policy Management** you can identify the GPO(s), their links,
and scope; `CVPNMIG-Discovery.ps1` flags SCCM- and GPO-delivered artifacts on a device.
Implement: Obtain Configuration Manager **read** access and **Group Policy Management** read access
(global requirement G3); document each mechanism and its scope before migrating.

## 2.5 Certificate delivery for the VPN
Description: How the VPN **client certificate** and its **trusted root / issuing CA** reach devices
today (typically AD CS auto-enrolment via GPO and a certificate template), and the target Intune
**SCEP** (or **PKCS**) delivery.
Why: If the VPN authenticates with a certificate, the Intune-issued certificate must be one the head-end
accepts — same template intent (subject/SAN, EKUs, key usage).
Verify: On a sample device, `CVPNMIG-Discovery.ps1` reports the VPN client certificate (issuer,
template, EKUs) in the user/computer store; in Intune, a **Certificate connector** (for SCEP/PKCS) shows
**Active** under **Tenant administration → Connectors and tokens**.
Implement: Stand up the Intune Certificate connector and an SCEP/PKCS **certificate profile** plus a
**Trusted certificate** profile for the root, mapped to the same template intent as the legacy AD CS
template. (NDES/SCEP setup follows Microsoft documentation.)

## 2.6 Entra wave groups and a pilot group
Description: Microsoft Entra security groups for the migration **pilot wave** and subsequent **waves**,
used to assign the Intune client + profile + cert.
Why: Every wave is piloted and validated before the next; assignment is by group so cutover is
controlled and reversible.
Verify: Entra → **Groups** shows the pilot/wave groups; `CVPNMIG-Set-ScopeTargeting.ps1` can create/
populate them.
Implement: Create the groups (or run `CVPNMIG-Set-ScopeTargeting.ps1`); name the first
`PILOT – VPN Migration Wave 1` (see Implementation for the full naming set).

## 2.7 Coexistence and rollback plan
Description: A written plan for running SCCM/GPO and Intune side by side **per fleet** while keeping any
single device on **one** path, plus a documented rollback (re-add the wave to the SCCM collection and
GPO scope).
Why: Migrations touch live production VPN; cutover must be reversible and must never double-manage a
device (global requirement G7).
Verify: The coexistence rule ("a device leaves the legacy scope in the same change it joins the Intune
wave") and the rollback steps are written and approved before any cutover.
Implement: Document the per-wave order of operations (add to Intune wave → remove from SCCM collection →
move out of GPO scope) and the reverse for rollback.

---
## Checklist
- [ ] Intune enrolment + Intune Administrator — Apps/Configuration reachable
- [ ] Cisco Secure Client installer + silent command (from Cisco)
- [ ] Current VPN profile XML recovered (single source of truth)
- [ ] SCCM package/deployment + GPO(s) and their scope documented
- [ ] Certificate delivery mapped; Intune Certificate connector Active; SCEP/PKCS + Trusted-root planned
- [ ] Entra pilot/wave groups exist (`PILOT – VPN Migration Wave 1`)
- [ ] Coexistence + rollback plan written (one authority per device)
