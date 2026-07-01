# Solution Overview — Cisco Secure Client (AnyConnect) VPN Deployment via Microsoft Intune

## What this solution is

This solution packages and deploys the **Cisco Secure Client** (the product formerly branded
**AnyConnect**) and its **VPN configuration profile** to every enrolled device in your fleet using
**Microsoft Intune** — across **Windows, macOS, iOS/iPadOS, and Android**. The goal is a
consistent, tested, hands-off remote-access client: the right app and the right VPN settings land on
each device automatically, are validated on a small pilot first, and are then expanded fleet-wide
with a documented rollback path.

The work is authored at click-by-click detail on the **Intune and Entra ID** side. The **Cisco
Secure Client console, the VPN Profile Editor / XML profile internals, and the VPN head-end (ASA,
Firepower/FTD, or ISE) configuration are deferred to Cisco's official documentation** — this
solution tells you *what* Cisco artifacts you need and *where* they plug into Intune, not how to
click through Cisco's own consoles.

## The app-plus-profile model

Deploying a working VPN through Intune is always **two artifacts working together**:

1. **The app (the client binary).** The Cisco Secure Client software that must be installed on the
   device. How it is delivered depends on the platform (see below).
2. **The VPN profile (the configuration).** The settings that tell the installed client *which
   gateway to connect to, how to authenticate, and how to behave* (split vs. full tunnel, on-demand
   rules, allowed apps, trusted networks). This is delivered as an **Intune VPN
   device-configuration profile** and/or a Cisco **VPN client profile (XML)** packaged with the app.

Neither artifact is useful alone: the app with no profile gives the user a blank client with no
connection defined; the profile with no app has nothing to configure. This solution always deploys
**both**, assigned to the **same** target group, so a device is either fully ready or clearly not —
never half-configured.

## How Secure Client is delivered per platform

Each platform has a different packaging and profile mechanism. The names below are the exact object
names you will create and reuse throughout this solution.

### Windows (Win32 / line-of-business app)
- **App delivery:** The Cisco Secure Client Windows installer is a set of MSI modules (Core VPN,
  plus optional modules). It is wrapped as a **Win32 app** (`.intunewin`) — this is the robust,
  recommended path because it supports multiple modules, a transform/answer file, install-order
  control, and rich detection rules. (A single-MSI **line-of-business app** is possible for the
  core-only case but is less flexible.)
- **Profile delivery:** Two options, used together or separately:
  - Ship the Cisco **VPN client profile XML** *inside* the Win32 package (dropped to the Secure
    Client profile directory during install), and/or
  - Push an **Intune VPN device-configuration profile** (Devices → Configuration) that references
    the Cisco Secure Client as the connection type.
- **App name:** `Cisco Secure Client – VPN – Win32`
- **Profile name:** `Cisco Secure Client – VPN – Profile – Windows`

### macOS (PKG app)
- **App delivery:** Cisco ships a signed **`.pkg`** installer. Intune deploys macOS PKG apps via
  **Apps → macOS → macOS app (PKG)**. The package must be signed and its **bundle IDs / version**
  supplied for install detection.
- **Profile delivery:** An **Intune VPN device-configuration profile** for macOS (connection type
  = Cisco Secure Client / a Custom VPN payload) and/or the Cisco VPN client profile bundled in the
  PKG.
- **App name:** `Cisco Secure Client – VPN – macOS PKG`
- **Profile name:** `Cisco Secure Client – VPN – Profile – macOS`

### iOS / iPadOS (store app + VPN profile)
- **App delivery:** The **Cisco Secure Client** app from the **Apple App Store**, added in Intune as
  a **store app** and deployed to supervised/enrolled devices.
- **Profile delivery:** An **Intune VPN device-configuration profile** for iOS/iPadOS with
  connection type **Cisco AnyConnect / Cisco Secure Client**, specifying the gateway, authentication,
  and (optionally) **Per-App VPN** and **On-Demand** rules. iOS VPN config is delivered *only* via
  the MDM profile — there is no bundled XML.
- **App name:** `Cisco Secure Client – VPN – iOS`
- **Profile name:** `Cisco Secure Client – VPN – Profile – iOS`

### Android (store app + VPN profile)
- **App delivery:** The **Cisco Secure Client** app from **Managed Google Play**, added in Intune and
  deployed to Android Enterprise (work profile / fully managed) devices.
- **Profile delivery:** An **Intune VPN device-configuration profile** (App configuration policy +
  VPN profile) for Android Enterprise with connection type **Cisco AnyConnect / Cisco Secure
  Client**, specifying gateway, authentication, and Per-App VPN where used.
- **App name:** `Cisco Secure Client – VPN – Android`
- **Profile name:** `Cisco Secure Client – VPN – Profile – Android`

## Authentication options (Intune-side view)

The VPN profile references *how* users authenticate to the head-end. This solution supports the
common patterns; the actual identity/certificate acceptance is configured on the Cisco head-end
(deferred to Cisco docs), but the Intune-side plumbing is authored here:

- **Certificate-based (recommended for machine/always-on and modern posture).** Intune issues a
  device or user certificate via a **SCEP** or **PKCS** certificate profile (from your PKI /
  Cloud PKI / NDES connector). The VPN profile references that certificate. This is the cleanest
  option for silent connect and is the pattern we assume by default.
- **SAML / Entra ID SSO.** The head-end redirects VPN authentication to Entra ID (SAML). No secret
  is stored on the device; users sign in with their Entra credentials + MFA. Intune's role is only
  to deliver the client and the profile that points at the SAML-enabled tunnel group.
- **Username / password (+ RADIUS/MFA).** The client prompts; least preferred for a hands-off
  fleet but supported. No credential is provisioned by Intune.

Certificate profiles referenced in this solution use the name
`Cisco Secure Client – VPN – Device Cert (SCEP)` so the dependency is traceable.

## Benefits

- **One client, every platform, from the cloud.** No per-device touch, no imaging, no manual profile
  import.
- **Consistency.** Every device gets the *same* gateway, tunnel mode, and auth — configuration drift
  disappears.
- **Pilot-first and rollback-ready.** The app+profile are assigned to a named pilot group, validated
  against explicit gates, and only then expanded. Uninstall/exclude is a one-click reversal.
- **Traceable.** Every object is named to a convention, so discovery, reporting, and troubleshooting
  scripts can find and check them deterministically.
- **Reportable.** The included scripts produce fleet-wide coverage so you always know who has the
  client and profile and who does not.

## Limitations and boundaries

- **Cisco head-end and client internals are out of scope.** The VPN gateway (ASA / Firepower FTD)
  or ISE, the tunnel-group/connection-profile config, and the Cisco **VPN Profile Editor** XML
  authoring are done per **Cisco's official documentation**. This solution consumes those artifacts
  (the installer and the XML/gateway values) and deploys them via Intune.
- **Platform enrollment is a prerequisite, not a deliverable.** Devices must already be enrolled in
  Intune (and for iOS, **Apple Push Notification service (APNs)** configured; for Android,
  **Managed Google Play** connected). See the Requirements guide.
- **Certificate infrastructure is assumed where cert-auth is used.** SCEP/PKCS delivery depends on a
  working PKI (on-prem NDES, Intune Cloud PKI, or a third-party CA connector).
- **No inline traffic decision is made here.** This deploys and configures the *client*; the
  security policy the tunnel enforces lives on the Cisco head-end.

## The standard deployment model

This solution follows the category-standard model, with explicit pass/fail gates at each step:

**Assess → Configure → Pilot → Validate → Expand**

1. **Assess.** Confirm prerequisites (Requirements guide), gather the Cisco artifacts (installers,
   XML profile, gateway FQDN, tunnel-group, auth method), and inventory target platforms.
2. **Configure.** Package the client per platform, build the VPN device-configuration profiles and
   any certificate profile, name every object to convention.
3. **Pilot.** Assign the app+profile to the named pilot group `PILOT – Cisco VPN Users` and let it
   deploy.
4. **Validate.** Run the validation script and the manual test matrix; every pilot device installs
   the client, receives the profile, and connects — pass/fail gates in the Testing guide.
5. **Expand.** Widen assignment to the production group(s), monitor the coverage report, and keep the
   rollback (exclude/uninstall) ready.

Proceed to the **Requirements guide** (`02-requirements.md`) to confirm you are ready to build.
