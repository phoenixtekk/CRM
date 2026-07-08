# Solution Overview

## What this toolkit is

This is a **diagnostics toolkit**, not a deployment guide. It assumes you already run — or are
supposed to run — **pre-logon VPN** on Windows: a tunnel that comes up **before** (or without) an
interactive user sign-in, so the device can reach a domain controller, apply Group Policy, and let a
first-time user log on over the corporate network. Something in that flow has stopped working — the
network sign-in option never appears, the tunnel never comes up, or authentication is rejected — and
the fault is hiding somewhere across several cooperating preconditions. This toolkit collects the
device and Intune state, checks each precondition, and points you at the fix.

The core idea: **a pre-logon VPN failure is almost never "the VPN is broken."** It is one specific
missing precondition — a module not installed, a flag not set, a certificate with the wrong usage, a
profile assigned to the wrong context — cascading into a symptom that looks like a total failure. If
you can name the missing precondition, you can name the fix. The whole toolkit exists to help you name
it fast.

## The two mechanisms it diagnoses

Windows offers **two different ways** to bring a VPN up before logon, and they fail for different
reasons. This toolkit diagnoses **both** and tells you which one you are (or should be) using.

### Mechanism 1 — Cisco Start Before Logon (SBL / PLAP)

Cisco Secure Client's **Start Before Logon (SBL)** shows a **Network sign-in** option on the Windows
logon screen (the PLAP — *Pre-Logon Access Provider* — credential provider), so a user connects the
VPN *before* signing in. The "Network sign-in" tile appears **only if both** of these are true:

- The Cisco Secure Client **VPN profile** carries `<UseStartBeforeLogon>true</UseStartBeforeLogon>`, **and**
- The **Start Before Logon module** MSI is installed (Core VPN must be installed **first**).

The component that renders the tile is the 64-bit PLAP DLL **`vpnplap64.dll`**, registered as a
Windows **credential provider** under
`HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers`. If either
precondition is missing — module absent, flag not set, or the provider not registered — the tile never
shows, and users on a fresh machine can't log on off-network.

### Mechanism 2 — Windows Always On VPN (AOVPN) device tunnel

The **device tunnel** is a machine-context VPN that connects automatically at boot using a **machine
certificate** — no user needed. It is the native Windows way to get pre-logon connectivity. It has
strict preconditions:

- **Only one** device tunnel is allowed **per device**.
- The device must be **domain-joined or hybrid-joined** and running **Windows Enterprise or Education**.
- The connection must be **IKEv2** (device tunnels do not support other tunnel types).
- A **machine certificate** must be in `LocalMachine\My` with the **Client Authentication** EKU, and
  the issuing CA must be trusted by the VPN gateway.
- The profile (delivered via the **VPNv2 CSP** as **ProfileXML**) must carry **`DeviceTunnel=true`**
  and **`AlwaysOn=true`**, and the tunnel must be visible via `Get-VpnConnection -AllUserConnection`.

If any precondition is off — wrong SKU/join type, a user-context profile instead of device-context,
the wrong certificate EKU, or more than one device tunnel — the tunnel silently never establishes.

## The named objects this toolkit looks for

Diagnosis is comparison, so the toolkit reuses the **exact object names** a matching deployment uses.
Reuse these verbatim (they appear in the scripts and the troubleshooting matrix):

| Object | Name |
|---|---|
| Device-tunnel VPN profile (VPNv2 CSP / ProfileXML) | `Pre-Logon VPN – Device Tunnel – Profile` |
| SBL module app (Start Before Logon) | `Pre-Logon VPN – SBL Module – Win32` |
| SBL-enabling VPN profile (UseStartBeforeLogon) | `Pre-Logon VPN – SBL – Profile` |
| Trusted-root certificate profile | `Pre-Logon VPN – Trusted Root` |
| Machine-certificate profile (SCEP/PKCS) | `Pre-Logon VPN – Device Cert (SCEP)` |
| Pilot / test **device** group | `PILOT – Pre-Logon VPN Devices` |

## The five diagnostic tools

All five are **read-only**. They observe; they never remediate.

- **`PLAPDX-Collect-Diagnostics.ps1`** — the entry point. A single on-device master collector that
  snapshots every precondition for **both** mechanisms (OS SKU/build, join type, Secure Client
  version, `vpnplap64.dll` + PLAP provider registration, the `UseStartBeforeLogon` value, the AOVPN
  device tunnel, the machine certificate) and writes one report.
- **`PLAPDX-Check-PlapSbl.ps1`** — focused **SBL/PLAP** checks with PASS/FAIL per precondition and the
  exact remedy for each FAIL.
- **`PLAPDX-Check-DeviceTunnel.ps1`** — focused **device-tunnel** checks (SKU/join eligibility, exactly
  one device tunnel, IKEv2, machine cert, AlwaysOn) with PASS/FAIL + remedy.
- **`PLAPDX-Check-Certificate.ps1`** — a certificate deep-check (present, not expired, Client
  Authentication EKU, chains to a trusted root, private key present), with optional expected-issuing-CA
  confirmation.
- **`PLAPDX-Check-Intune.ps1`** — a read-only Microsoft Graph check that confirms the expected Intune
  objects exist, are assigned, and are **scoped to the right context** (a device-tunnel profile
  assigned to a **device** group, not a user group).

## Where the vendor boundary sits

This toolkit authors the **Windows, Intune, Entra, and certificate side** at exact, click-by-click
detail — that is where your read-only scripts and portal checks live. The **VPN head-end / gateway
internals are deferred to the vendor's official documentation**: the Cisco Secure Client profile
editor and head-end (ASA / Firepower FTD) config, and the RRAS / third-party IKEv2 gateway
configuration. The toolkit tells you *what* the device and Intune must present (the certificate, the
profile flags, the module); *how* the gateway is configured to accept it is the vendor's domain and
your gateway admin's.

## How to use the rest of this toolkit

- **`02-requirements.md`** — the read access and vantage points you need before you can diagnose.
  Confirm these first; assembling access mid-incident wastes the outage.
- **`03-implementation.md` (Diagnostic Workflow)** — the ordered **Collect → Analyze → Remediate →
  Verify** workflow and the **symptom → tool** map. Start here during an incident.
- **`05-testing.md`** — pass/fail gates to confirm the toolkit runs correctly and that a fix actually
  cleared the failing precondition.
- **`06-troubleshooting.md`** — the comprehensive **symptom → likely cause → fix** matrix for
  pre-logon VPN across **both** mechanisms. This is the heart of the product.
- **`07-best-practices.md`** — repeatable triage habits, evidence collection, and clean escalation.

**Standing constraint for the whole toolkit:** every script and check here is **read-only**.
Diagnostics observe; they never change the device, the tenant, or the gateway. You decide the fix; the
toolkit only tells you where it is. The workflow adapts the category-standard
**Assess → Configure → Pilot → Validate → Expand** model to a diagnostic shape:
**Collect → Analyze → Remediate → Verify.**
