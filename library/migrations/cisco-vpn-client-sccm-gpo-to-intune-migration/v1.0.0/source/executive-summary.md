# Executive Summary — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

**Workplace Marketplace · Migrations**

Many organizations still push the **Cisco Secure Client (AnyConnect)** and its VPN profile through
**Configuration Manager (SCCM) packages** and **Group Policy** — on-prem plumbing that assumes a
domain-joined device on the corporate network and breaks for remote and cloud-managed endpoints. Moving
that delivery to **Microsoft Intune** means every piece — the client install, the VPN connection
profile, and the certificate the VPN authenticates with — has to be rebuilt in Intune and validated so
nobody loses their VPN mid-migration. Done by hand it is slow and risky: the classic failure is a
**double-deployment conflict** where SCCM/GPO and Intune fight over the same client, causing reinstall
loops or a profile that flip-flops.

This is a complete, deploy-it-today package for migrating the Cisco VPN client deployment from SCCM/GPO
to Intune, written for an administrator carrying out the move without prior migration experience.

## What you get
- A plain-language Solution Overview of how the SCCM/GPO delivery maps to Intune, the rebuild-and-
  validate model, coexistence, ringed wave cutover, and — critically — how to keep exactly one delivery
  authority per device so the two paths never conflict.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps: inventory the SCCM package and GPO(s), rebuild the
  client as a Win32 app, deliver the VPN profile and the SCEP/PKCS certificate, pilot, validate the
  tunnel, cut over wave by wave, and retire the SCCM package and GPOs.
- Five PowerShell scripts for current-state discovery, per-device migration validation, a fleet
  legacy-vs-Intune progress report, safe legacy cleanup, and the wave-group builder.
- Testing and Troubleshooting guides with explicit parity, no-conflict, and legacy-gone gates.

## What this delivers
A repeatable inventory → rebuild → validate loop: the Cisco client, VPN profile, and certificate become
Intune-delivered with parity; SCCM/GPO keep working during coexistence; each device moves to Intune only
as its legacy delivery is removed; and the SCCM package and GPOs are retired ring by ring only after
Intune is proven.

## Vendor boundary
The Cisco Secure Client installer, the VPN profile XML schema, the head-end (ASA/Firepower), and ISE
posture are configured per **Cisco's official documentation**. This solution rebuilds *delivery* in
Intune at exact click-by-click detail and defers the Cisco product's own internals to the vendor.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand → Retire legacy.**

## Outcome
Your Cisco VPN client, profile, and certificate delivered from Intune instead of SCCM/GPO — migrated
wave by wave, validated for parity, and proven on a pilot before you retire the legacy path — with the
VPN never going dark and no device ever double-managed.
