# Requirements

Before you can diagnose a pre-logon VPN failure — Cisco Start Before Logon (SBL/PLAP) or a Windows
Always On VPN device tunnel — you need read access to each place that holds evidence, and access to a
device that exhibits the problem. This section lists what to have ready. Each item follows
**Description / Why / Verify / Implement if missing**.

Gather these *before* an incident where possible — assembling access mid-incident wastes the outage.
Everything here is **read-only**; you never need write/remediation rights to run this toolkit.

> Naming convention used throughout this toolkit (reuse these names verbatim):
> - Device-tunnel VPN profile (VPNv2 CSP / ProfileXML): **`Pre-Logon VPN – Device Tunnel – Profile`**
> - SBL module app: **`Pre-Logon VPN – SBL Module – Win32`**; SBL-enabling VPN profile:
>   **`Pre-Logon VPN – SBL – Profile`**
> - Trusted-root certificate profile: **`Pre-Logon VPN – Trusted Root`**; machine-certificate profile:
>   **`Pre-Logon VPN – Device Cert (SCEP)`**
> - Pilot / test **device** group in Entra: **`PILOT – Pre-Logon VPN Devices`**

> **Government / sovereign-cloud note:** if the tenant is **GCC High / DoD**, the admin portals differ
> (`https://endpoint.microsoft.us`, `https://entra.microsoft.us`, sign-in via
> `https://login.microsoftonline.us`) and feature/endpoint parity can lag Commercial. The device-side
> checks are identical, but **verify the portal steps and object availability for GCC High** in your
> sovereign cloud before acting on the Intune-side checks.

---

## R1. Access to a device that exhibits the problem

**Description:** Local (or remote-management) access to the enrolled **Windows** device where
pre-logon VPN fails — enough to run the device-side scripts and read its certificate store, registry,
services, and VPN configuration.

**Why:** Most pre-logon preconditions have a **device-side truth** the cloud cannot see: whether the
`vpnplap64.dll` PLAP provider is actually registered, whether the machine certificate is present with a
private key and the Client Authentication EKU, and whether a device tunnel actually exists. The
scripts `PLAPDX-Collect-Diagnostics.ps1`, `PLAPDX-Check-PlapSbl.ps1`,
`PLAPDX-Check-DeviceTunnel.ps1`, and `PLAPDX-Check-Certificate.ps1` run **on this device**.

**Verify:** You can open a PowerShell session on the device and run
`Get-ChildItem Cert:\LocalMachine\My` and `Get-VpnConnection -AllUserConnection` and see output.

**Implement if missing:** Arrange local admin access (needed to read `LocalMachine\My` and the
Credential Providers registry key), a remote session (RDP / remote PowerShell), or have the end user
run the read-only collector and return the report. No changes are made to the device.

---

## R2. Local administrator rights on the failing device

**Description:** Local administrator (or SYSTEM) rights on the device, to read the machine certificate
store `Cert:\LocalMachine\My`, the all-user VPN connections, and the Credential Providers registry key.

**Why:** The device-tunnel machine certificate lives in `LocalMachine\My`, the device tunnel is an
all-user connection, and the PLAP credential-provider registration is under `HKLM`. A standard user
can't read these reliably, so a check would report false negatives.

**Verify:** In an elevated PowerShell session, `Get-ChildItem Cert:\LocalMachine\My` returns the
machine certs and `Get-Item 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers'`
succeeds.

**Implement if missing:** Run the device-side scripts **elevated** (Run as administrator) or as SYSTEM
via your management tooling. The scripts read only; elevation is for visibility, not change.

---

## R3. Microsoft Intune admin center read access

**Description:** Sign-in to the Microsoft Intune admin center (`https://intune.microsoft.com`; GCC
High: `https://endpoint.microsoft.us`) with at least a read-only role that can view apps, device
configuration profiles, certificate profiles, and their **assignments**.

**Why:** Whether the SBL module app, the device-tunnel profile, the SBL-enabling VPN profile, the
trusted-root profile, and the SCEP/PKCS certificate profile are **present, assigned, and scoped to the
right context** is only visible here. A device-tunnel profile assigned to a *user* group instead of a
*device* group is a classic silent failure.

**Verify:** Browse to the Intune admin center → **Apps** and **Devices > Configuration** and confirm
you can read each object's **Properties** and **Assignments**.

**Implement if missing:** In Entra (`https://entra.microsoft.com`) → **Roles & admins**, assign the
operator the **Global Reader** role (tenant-wide read, no change rights) or the built-in **Intune
Administrator** role. Prefer read-only.

---

## R4. Microsoft Graph read access (for the Intune check script)

**Description:** The ability to run `PLAPDX-Check-Intune.ps1` against Microsoft Graph with the
read-only scopes `DeviceManagementApps.Read.All`, `DeviceManagementConfiguration.Read.All`,
`Group.Read.All`, and `Directory.Read.All`.

**Why:** The script reads the same app/profile/assignment state you would click through in the portal —
so it can confirm each expected object exists, is assigned to `PILOT – Pre-Logon VPN Devices`, and (the
key check) that the **device-tunnel profile is assigned to a device group, not a user group**.

**Verify:** Run `Connect-MgGraph -Scopes "DeviceManagementApps.Read.All","DeviceManagementConfiguration.Read.All","Group.Read.All","Directory.Read.All"`
and confirm consent succeeds; `Get-MgContext` shows the scopes granted.

**Implement if missing:** Install the Microsoft Graph PowerShell SDK
(`Install-Module Microsoft.Graph -Scope CurrentUser`). Consent to the delegated **read** scopes above
at first connect — no write consent is required or requested.

---

## R5. Knowledge of the intended mechanism and gateway

**Description:** A recorded statement of **which** pre-logon mechanism this device is supposed to use
(Cisco SBL/PLAP or an AOVPN device tunnel), the **gateway/head-end address**, the **expected issuing
CA** for the machine/VPN certificate, and — for SBL — the expected Cisco Secure Client version.

**Why:** Diagnosis is comparison. Knowing the intended mechanism stops you from "fixing" a device
tunnel on a machine that was only ever meant to use SBL (and vice-versa), and the expected issuing CA
turns "is this certificate right?" into a one-line match.

**Verify:** You can state, for this device: mechanism (SBL vs device tunnel), gateway FQDN, expected
issuing-CA name, and the expected profile name from the naming table above.

**Implement if missing:** Obtain the design decision from whoever owns the pre-logon VPN deployment
(the matching **deployment** product records these). If nobody can say which mechanism is intended,
that ambiguity is itself a finding — pick one design and standardize.

---

## R6. A known-good reference device (baseline)

**Description:** At least one Windows device on which pre-logon VPN **currently works** for the same
mechanism, plus its expected values (issuer/template of the machine cert, profile name, gateway).

**Why:** A working reference turns "is this profile correct?" into a diff and "is the certificate
right?" into "does it match the working one's issuer and template?" It also proves the *service* (CA,
gateway) is up, isolating the fault to the failing device.

**Verify:** Confirm one device brings up the pre-logon tunnel / shows the Network sign-in tile right
now; record its cert issuer/template, profile name, and gateway.

**Implement if missing:** Use a device from `PILOT – Pre-Logon VPN Devices` as the known-good
reference. If **nothing** currently works, the fault is likely a shared/service break (issuing CA,
gateway, or a fleet-wide assignment error) rather than a single device — note that and start from the
Intune check (`PLAPDX-Check-Intune.ps1`).

---

## R7. VPN head-end / gateway vantage point (evidence-only)

**Description:** Read access to, or a hand-off with, whoever administers the **VPN gateway** (Cisco
ASA/FTD for SBL, or the RRAS / third-party IKEv2 gateway for the device tunnel), to read whether the
device's authentication attempt **reached** the gateway and why it was accepted or rejected.

**Why:** Whether the gateway **trusts the issuing CA**, whether it received the connection attempt, and
the exact rejection reason are only visible at the head-end. Without this, a "cert looks perfect
device-side but the gateway rejects it" case is guesswork.

**Verify:** You (or the gateway admin on the call) can locate the failing device's connection attempt
in the gateway logs by time/identity.

**Implement if missing:** Arrange gateway read access or an agreed hand-off where the gateway admin
pulls the log for a timestamp you provide. **Exact gateway console navigation and trust-store
configuration are deferred to the vendor's official documentation** — this toolkit names the evidence
to read (did it arrive, what was the rejection reason); the vendor doc covers where it lives.
