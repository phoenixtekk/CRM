# Solution Overview — Pre-Logon VPN Connectivity with Cisco Secure Client Start Before Logon (SBL/PLAP) via Microsoft Intune

## What this solution is

This solution deploys the **Cisco Secure Client** (the product formerly branded **AnyConnect**) with
its **Start Before Logon (SBL)** capability to your **Windows** fleet using **Microsoft Intune**, so
the VPN tunnel comes up **at the Windows logon screen — before the user signs in to Windows.** The
goal is a consistent, tested, hands-off pre-logon remote-access build: the right modules, the right
SBL-enabled VPN profile, and a **device certificate** for silent pre-logon authentication all land on
each device automatically, are validated on a small pilot first, and are then expanded fleet-wide with
a documented rollback path.

The work is authored at click-by-click detail on the **Intune, Entra ID, and Windows** side. The
**Cisco Secure Client console, the VPN Profile Editor / XML profile internals, and the VPN head-end
(ASA, Firepower/FTD, or ISE) configuration are deferred to Cisco's official documentation** — this
solution tells you *what* Cisco artifacts you need and *where* they plug into Intune, not how to click
through Cisco's own consoles.

## Why pre-logon (the business case in one paragraph)

An after-logon VPN can only tunnel *after* a user has already authenticated to Windows — which is
exactly the problem when there is nothing on the device to authenticate against yet. **Start Before
Logon** brings the tunnel up first, at the logon screen, so the device can reach a domain controller
and internal services **before** the Windows sign-in happens. That enables:

- **First-time remote logon** of a user who has never signed in to this device (no cached credentials).
- **Off-network password changes / resets** that must reach a domain controller to succeed.
- **GPO and logon-script processing** at logon for domain-joined / Entra hybrid-joined devices.
- **Domain-controller reachability** for hybrid-join and Group Policy on remote machines.

## How Start Before Logon actually works (the two artifacts)

SBL is **Windows-only** and is implemented as the **Pre-Login Access Provider (PLAP)** — a
*connectable credential provider* that adds a **"Network sign-in"** option to the Windows logon
screen. On 64-bit Windows the component is **`vpnplap64.dll`** (on 32-bit Windows, `vpnplap.dll`).

For that "Network sign-in" option to appear, **both** of the following must be true on the device:

1. **The Start Before Logon module is installed.** Cisco ships SBL as a **separate module** on top of
   the Core VPN module. The **Core VPN module must be installed first, then the Start Before Logon
   module** — install order matters.
2. **The VPN client profile (XML) enables SBL.** The Cisco VPN client profile must contain
   **`<UseStartBeforeLogon>true</UseStartBeforeLogon>`**. Without this flag set to `true`, the PLAP
   credential provider stays dormant and the logon-screen option never shows — even with the module
   installed.

Neither artifact is useful alone: the module with a `false` (or missing) `UseStartBeforeLogon` gives
you a normal after-logon client; the flag with no module has no PLAP DLL to activate. This solution
always deploys **both together**, plus the device certificate, so a device is either fully pre-logon
ready or clearly not — never half-configured.

## How it is delivered through Intune (Windows Win32 app + profiles)

Everything is delivered from the cloud to enrolled Windows devices:

- **The client (Win32 app).** A single **Win32 app** (`.intunewin`) installs the **Core VPN module
  first, then the Start Before Logon module** (correct order), and **drops the SBL-enabled VPN client
  profile XML** (the one with `<UseStartBeforeLogon>true</UseStartBeforeLogon>`) into the Secure
  Client profile directory during install.
  - **App name:** `Cisco Secure Client – Pre-Logon (SBL) – Win32`
- **The VPN connection settings (optional Intune profile).** In addition to (or instead of) the
  bundled XML, an **Intune VPN device-configuration profile** can carry the connection settings.
  - **Profile name:** `Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows`
- **The device certificate (for silent pre-logon auth).** A **Trusted Root CA** profile and a **SCEP
  (or PKCS) certificate profile** issuing a **Device (machine) certificate** so the tunnel can
  authenticate with no user context present.
  - **Trusted root profile:** `Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows`
  - **Certificate profile:** `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows`

## Authentication for pre-logon — why a device certificate

At the Windows logon screen **no user is signed in yet**, so there is no user context, no user
certificate store, and (for a brand-new device) no cached credentials. The clean way for the tunnel to
authenticate at that moment is a **device / machine certificate** delivered by Intune to the
**LocalMachine** store, which the head-end trusts. That is why this solution folds in a full
**certificate-lifecycle** section: pre-logon connectivity only stays working as long as a valid device
certificate is present and renewed before expiry.

- **Device certificate (recommended, default here).** Intune issues a machine certificate via the
  SCEP/PKCS profile `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows`; the VPN profile
  references it; the tunnel comes up silently at the logon screen. This is the pattern this solution
  assumes.
- **Interactive pre-logon (SAML/RADIUS at the PLAP screen).** Some head-ends allow the user to type
  credentials into the PLAP "Network sign-in" window before Windows logon. Supported, but it is not
  silent and does not help true first-logon with no credentials. The head-end's acceptance of any auth
  method is configured on the Cisco side (deferred to Cisco docs).

## Certificate lifecycle (why it is in scope)

Pre-logon depends on the device certificate being present, valid, and trusted **at the logon screen**.
This solution therefore deploys the **trusted root/intermediate first**, then the **device SCEP
certificate**, sets a **renewal threshold** comfortably before expiry, and includes reporting so an
expiring certificate is caught before it silently breaks pre-logon connectivity. The **issuing CA must
be trusted by the Cisco head-end** — that head-end trust configuration is **Cisco-side and deferred to
Cisco docs**; Intune's job is to get the correct device certificate onto the machine.

## Benefits

- **The tunnel is up before Windows logon.** First remote logon, off-network password resets, GPO/logon
  scripts, and DC reachability all work from anywhere.
- **Silent and hands-off.** A device certificate authenticates the pre-logon tunnel with no user
  interaction; the whole build is delivered from Intune with no per-device touch.
- **Consistency.** Every device gets the *same* modules, the *same* SBL-enabled profile, and the *same*
  certificate policy — configuration drift disappears.
- **Pilot-first and rollback-ready.** The app, profile, and certificate profiles are assigned to a
  named pilot group, validated against explicit gates, and only then expanded. Uninstall/exclude is a
  one-click reversal.
- **Traceable and reportable.** Every object is named to a convention, so the discovery, validation,
  reporting, and remediation scripts find and check them deterministically — including whether
  **PLAP/SBL is actually present** and `UseStartBeforeLogon` is `true`.

## Limitations and boundaries

- **Windows only.** Start Before Logon is a Windows credential-provider (PLAP) feature. macOS, iOS, and
  Android have no equivalent pre-logon flow and are out of scope for this solution.
- **Cisco head-end and client internals are out of scope.** The VPN gateway (ASA / Firepower FTD) or
  ISE, the tunnel-group/connection-profile config, head-end CA trust, and the Cisco **VPN Profile
  Editor** XML authoring are done per **Cisco's official documentation**. This solution consumes those
  artifacts (the installer modules, the SBL-enabled XML, gateway FQDN, tunnel-group, auth method) and
  deploys them via Intune.
- **Enrollment is a prerequisite, not a deliverable.** Devices must already be enrolled in Intune. See
  the Requirements guide.
- **A working PKI is assumed.** The device certificate depends on a SCEP/PKCS path (on-prem NDES,
  Intune Cloud PKI, or a supported third-party CA connector).

## The standard deployment model

This solution follows the category-standard model, with explicit pass/fail gates at each step:

**Assess → Configure → Pilot → Validate → Expand**

1. **Assess.** Confirm prerequisites (Requirements guide), gather the Cisco artifacts (Core + SBL
   modules, the **SBL-enabled** VPN profile XML, gateway FQDN, tunnel-group, auth method), and confirm
   the PKI path for a device certificate. **Gate A.**
2. **Configure.** Deploy the trusted root and the device SCEP certificate, package the Win32 app that
   installs **Core then SBL** and drops the SBL-enabled XML, build the Windows VPN profile, and name
   every object to convention. **Gate B.**
3. **Pilot.** Assign the certificate profiles, app, and VPN profile to the named pilot group
   `PILOT – Pre-Logon VPN (SBL) Users` and let it deploy. **Gate C.**
4. **Validate.** Run the validation script (client installed, **PLAP/SBL present**, `UseStartBeforeLogon`
   true, device cert present) and the manual pre-logon test — connect at the logon screen, then log on
   with the tunnel already up. **Gate D.**
5. **Expand.** Widen assignment to `PROD – Pre-Logon VPN (SBL) Users`, monitor the coverage report, and
   keep the rollback ready. **Gate E.**

Proceed to the **Requirements guide** (`02-requirements.md`) to confirm you are ready to build.
