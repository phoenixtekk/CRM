# Cisco Secure Client (AnyConnect) VPN Deployment via Microsoft Intune

> **Version 1.0.0** · Category: Network · Solution code: CSCVPN

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Cisco Secure Client (AnyConnect) VPN Deployment via Microsoft Intune

## The business problem
Getting a reliable remote-access VPN onto an entire device fleet is where remote-work projects
stall. Teams end up hand-installing the **Cisco Secure Client (AnyConnect)** device by device,
importing the wrong profile, or leaving Windows, macOS, iOS, and Android in different states. The
result is inconsistent connectivity, help-desk load, security gaps, and a rollout that never quite
finishes.

## The solution
This is a complete, self-guided package that **packages and deploys the Cisco Secure Client and its
VPN configuration profiles to every enrolled device through Microsoft Intune** — Windows, macOS,
iOS, and Android — from the cloud, with no hands-on device touch. It uses a disciplined
**app-plus-profile** model (the client software *and* its VPN settings, always deployed together to
the same target group) and a proven rollout method: **Assess → Configure → Pilot → Validate →
Expand**, with explicit pass/fail gates and a one-click rollback.

## What you get
- **Step-by-step implementation** at click-by-click detail on the Intune/Entra side — packaging the
  client for each platform, building the VPN profiles, and assigning them to a named pilot group.
- **Five PowerShell scripts** — readiness discovery, on-device validation, fleet coverage reporting,
  safe remediation (preview-by-default), and pilot-group creation.
- **Requirements, testing, troubleshooting, and best-practice guides** so a competent Intune admin
  can implement it end to end and know it worked.

## Business outcomes
- **Consistent remote access on every device** — the same gateway, tunnel mode, and authentication
  everywhere; configuration drift eliminated.
- **Faster, cheaper rollout** — hands-off cloud delivery replaces per-device installs, freeing the
  help desk and shrinking project time.
- **Lower risk** — piloted before fleet-wide rollout, validated against explicit gates, and reversible
  at any point, so a change never strands users.
- **Continuous assurance** — coverage reporting shows exactly who has a working client and profile
  and who does not.

## Scope and boundary
The solution is authored at full detail on the **Microsoft Intune and Entra ID** side. The **Cisco
Secure Client console, VPN profile-editor internals, and the VPN head-end (ASA / Firepower / ISE)**
are the customer's existing Cisco environment and follow **Cisco's official documentation** — this
package consumes those artifacts (installers, VPN profile, gateway details, authentication method)
and delivers them reliably to every device.

## Bottom line
The Cisco VPN client and its profile on **every managed device** — delivered from Intune, consistent
across platforms, proven on a pilot before you scale, and a fraction of the cost and time of a
hands-on consulting engagement.


---


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


---


# Requirements — Cisco Secure Client (AnyConnect) VPN Deployment via Microsoft Intune

Confirm **every** requirement below before you build. Each entry follows the same shape:
**Description / Why required / How to verify / How to implement if missing.** The category-level
prerequisites (Entra tenant, Intune, admin roles, pilot group, change control) are in
`global-requirements-network.md`; the items here are specific to deploying the Cisco Secure Client
and its VPN profiles.

> **Vendor boundary:** the **Cisco Secure Client console, the VPN Profile Editor / XML internals, and
> the VPN head-end (ASA / Firepower FTD / ISE) configuration are deferred to Cisco's official
> documentation.** Below, "obtain from Cisco" means *get the artifact/value from your Cisco admin or
> Cisco docs* — this guide does not fabricate Cisco menu paths.

---

## R1. Microsoft Intune licensing and enrolled devices
**Description:** An Intune-bearing license plan (e.g. Microsoft 365 E3/E5, EMS, or Intune standalone)
and the target Windows/macOS/iOS/Android devices already enrolled and shown in Intune.
**Why required:** Intune is the delivery plane for both the app and the VPN profile. Nothing deploys
to a device that is not enrolled and licensed.
**How to verify:** In the **Microsoft Intune admin center** (`https://intune.microsoft.com`), go to
**Devices > All devices** and confirm the target devices are present and *Compliant/Managed*. Under
**Tenant administration > Licenses**, confirm Intune licenses are assigned to the pilot users.
**How to implement if missing:** Assign an Intune-bearing license to the pilot users (Microsoft 365
admin center → **Users** → assign licenses). Enroll devices: Windows via Autopilot / Company Portal;
macOS via Company Portal / Automated Device Enrollment; iOS via Company Portal or ADE; Android via
the work-profile / fully-managed enrollment flow.

## R2. Entra ID security groups (pilot and production)
**Description:** A pilot group `PILOT – Cisco VPN Users` and one or more production target groups
(e.g. `PROD – Cisco VPN Users`), containing users or devices to receive the client.
**Why required:** Intune assignments target Entra groups. The pilot-first model requires a small,
named pilot group distinct from the eventual production audience.
**How to verify:** In the **Microsoft Entra admin center** (`https://entra.microsoft.com`), go to
**Groups > All groups** and confirm `PILOT – Cisco VPN Users` exists with the intended members.
**How to implement if missing:** Entra → **Groups > New group > Security**; name it exactly
`PILOT – Cisco VPN Users`; add 3–10 representative pilot members (ideally covering each platform).
The included `CSCVPN-Set-ScopeTargeting.ps1` script creates and populates these groups for you.

## R3. A Cisco VPN head-end (ASA / Firepower FTD) — with ISE where used
**Description:** A reachable Cisco VPN termination point (ASA or Firepower Threat Defense) with a
configured **tunnel group / connection profile**, plus **Cisco ISE** if you use posture or
identity-based authorization.
**Why required:** The deployed client needs something to connect *to*. The gateway FQDN,
tunnel-group/connection-profile name, and accepted authentication method are inputs to the Intune
VPN profile.
**How to verify:** Obtain from your Cisco/network team: the **gateway FQDN** (e.g.
`vpn.your-company.com`), the **tunnel-group / connection-profile name**, and the **auth method**
(certificate, SAML/Entra, or RADIUS). Confirm a test user can already connect manually with a
Cisco-supplied client to that gateway.
**How to implement if missing:** Stand up / configure the ASA or FTD head-end and (optionally) ISE
**per Cisco's official documentation** — this is Cisco-side work outside this solution's scope.
Record the FQDN, connection-profile name, and auth method for use in R6/Implementation.

## R4. Cisco Secure Client installers (per platform)
**Description:** The official Cisco Secure Client installers for each platform you are deploying:
Windows (MSI predeploy package / modules), macOS (signed `.pkg`), and the App Store / Managed Google
Play listings for iOS and Android.
**Why required:** These are the exact binaries Intune will package and deploy. Version and module set
must match what your head-end supports.
**How to verify:** Download the installers from your **Cisco Software Download** entitlement and
confirm the version against what your head-end/Cisco admin specifies. Confirm the macOS PKG is
**signed** (needed for Intune detection and macOS Gatekeeper).
**How to implement if missing:** Obtain the correct entitled version from Cisco (Software Download,
per your support contract). Do not repackage or re-sign Cisco binaries; use the vendor-provided ones.

## R5. Cisco VPN client profile (XML) — where used
**Description:** The Cisco **VPN client profile** (an XML file authored in Cisco's **VPN Profile
Editor** or delivered from the head-end) that encodes gateway lists, connect behavior, and client
options for Windows/macOS.
**Why required:** For Windows/macOS, bundling this XML with the app package gives the client its
connection defaults immediately on install (for iOS/Android the equivalent lives in the Intune VPN
profile).
**How to verify:** Obtain the `.xml` profile from your Cisco admin and confirm it references the
correct gateway FQDN and connect settings. (iOS/Android do **not** consume this XML — they use the
Intune VPN profile.)
**How to implement if missing:** Have your Cisco admin author/export the VPN client profile XML
**per Cisco's VPN Profile Editor documentation** (deferred to Cisco). Store it with your Win32/PKG
packaging inputs.

## R6. VPN connection parameters recorded
**Description:** A recorded set of connection values: **gateway FQDN**, **tunnel-group / connection
profile**, **authentication method**, tunnel mode (**split** vs **full**), any **Per-App VPN** app
list, and **On-Demand / trusted-network** rules.
**Why required:** These are the exact fields you type into the Intune VPN device-configuration
profiles for each platform. Consistency here is what makes every device identical.
**How to verify:** You have a single sheet listing each value; a manual client connect using those
values succeeds against the head-end.
**How to implement if missing:** Collect the values from R3/R5 and your security requirements. Decide
split vs full tunnel and Per-App scope with the network/security owner before building profiles.

## R7. Certificate infrastructure (if using certificate authentication)
**Description:** A working PKI path for Intune to deliver client/device certificates — an on-prem
**NDES/SCEP** connector, **Intune Cloud PKI**, or a supported third-party CA connector — and a
**SCEP or PKCS certificate profile** in Intune.
**Why required:** Certificate-based VPN auth (the recommended silent-connect pattern) requires each
device to receive a certificate the head-end trusts, delivered by Intune.
**How to verify:** Intune → **Devices > Configuration**; a certificate profile named
`Cisco Secure Client – VPN – Device Cert (SCEP)` deploys successfully to a test device, and the
issued cert chains to a CA the Cisco head-end trusts.
**How to implement if missing:** Stand up the SCEP/PKCS path (NDES + Intune Certificate Connector,
or enable Intune Cloud PKI), publish the trusted root/intermediate CA profile, then create the SCEP
certificate profile. Ensure the **issuing CA is trusted by the Cisco head-end** (Cisco-side trust
config is deferred to Cisco docs). Skip R7 only if you authenticate by SAML/Entra SSO or
username/password.

## R8. iOS enrollment prerequisite — Apple Push Notification service (APNs)
**Description:** A valid **Apple MDM Push certificate (APNs)** configured in Intune, enabling iOS/
iPadOS management.
**Why required:** No iOS device can be managed (and thus receive the store app or VPN profile)
without a current APNs certificate.
**How to verify:** Intune → **Tenant administration > Connectors and tokens > Apple MDM Push
certificate**; status is *Active* and not expired.
**How to implement if missing:** Create/renew the APNs certificate: download the CSR from Intune,
upload it at `https://identity.apple.com` (Apple Push Certificates Portal) with a **corporate** Apple
ID, and upload the resulting certificate back into Intune. **Renew annually with the same Apple ID.**

## R9. Android enrollment prerequisite — Managed Google Play
**Description:** Intune connected to **Managed Google Play** (Android Enterprise) so the Cisco Secure
Client app can be approved and pushed.
**Why required:** Android Enterprise app deployment (work profile / fully managed) flows through the
Managed Google Play connection.
**How to verify:** Intune → **Devices > Android > Android enrollment > Managed Google Play**; the
connection shows as configured/connected.
**How to implement if missing:** Complete the Managed Google Play bind in Intune (**Android
enrollment > Managed Google Play**) using a corporate Google account, then approve the Cisco Secure
Client app.

## R10. macOS PKG signing / app detection readiness
**Description:** The macOS Cisco Secure Client **`.pkg` is signed**, and you know its **primary bundle
ID and version** for Intune's install-detection.
**Why required:** Intune's macOS PKG deployment relies on the package being signed and on bundle-ID/
version metadata to detect a successful install; unsigned packages fail Gatekeeper.
**How to verify:** Inspect the vendor PKG (e.g. it is a Developer ID–signed installer) and record the
bundle identifier/version Cisco documents for the release.
**How to implement if missing:** Use Cisco's official signed PKG (do not re-sign). If your workflow
needs the bundle-ID list, obtain it from Cisco's release notes / documentation.

## R11. Administrative roles for building the deployment
**Description:** Intune admin rights to create apps and configuration profiles, and Entra rights to
create/populate groups (Groups Administrator or better).
**Why required:** Packaging apps, creating VPN/cert profiles, and assigning groups all require
elevated roles.
**How to verify:** In Intune, you can reach **Apps > Add** and **Devices > Configuration > Create**;
in Entra you can create groups.
**How to implement if missing:** Have a Global Administrator assign **Intune Administrator** and
**Groups Administrator** (least-privilege) to the operator.

## R12. Microsoft Graph PowerShell SDK (to run the included scripts)
**Description:** The **Microsoft.Graph** PowerShell SDK installed on the operator workstation, used by
the five discovery/validation/report/remediation/targeting scripts.
**Why required:** The scripts call Microsoft Graph (Intune/Entra) to inventory apps, profiles,
assignments, and group membership.
**How to verify:** In PowerShell, `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**How to implement if missing:** Run `Install-Module Microsoft.Graph -Scope CurrentUser`. The scripts
call `Connect-MgGraph` with the specific delegated scopes each one documents in its header.

## R13. Change control and rollback (category requirement, restated)
**Description:** An approved change window and a written rollback (exclude the group / uninstall the
app / remove the profile).
**Why required:** Pushing a VPN client and profile touches remote-access for real users; changes must
be reversible.
**How to verify:** A rollback procedure exists and is approved; you know how to exclude
`PILOT – Cisco VPN Users` and how to flip the Win32 app to **Uninstall** if needed.
**How to implement if missing:** Document the rollback (Intune assignment exclusion, app Uninstall
intent, profile removal) and the comms plan before you assign anything.

---

When all requirements pass, proceed to `03-implementation.md`.


---


# Global Requirements — Network (category-level)

These requirements apply to **every** solution in the **Network** category (SASE/SSE, secure web
gateway, Zero Trust network access, and related network-security work — Netskope-centric). They are
published once at the category level so individual listings stay small. Confirm these before deploying
*any* Network solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

> **Vendor note:** these solutions are authored at the correct architectural and procedural level.
> Exact, current **Netskope console** screens, menu paths, and tenant-specific options change over
> time and are **deferred to the official Netskope documentation and your Netskope tenant** — follow
> the named step and confirm the precise control in your console.

## G1. A Netskope tenant
**Description:** An active, licensed Netskope tenant with admin access.
**Why:** It is the control plane for SWG, ZTNA, SSL inspection, and policy.
**Verify:** Sign in to your Netskope tenant admin console as an administrator.
**Implement:** Engage your Netskope account team / reseller to provision a tenant and the required modules.

## G2. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** Identity is the backbone for SSO, identity-based policy, and user/group steering.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G3. Endpoint management (Intune)
**Description:** Microsoft Intune (or an equivalent) able to deploy the client and certificates to endpoints.
**Why:** The Netskope client, root/decryption certificates, and steering config are delivered to managed devices.
**Verify:** `https://intune.microsoft.com` loads and target devices are enrolled and compliant.
**Implement:** Assign an Intune-bearing license plan and enroll the target devices.

## G4. Administrative roles
**Description:** Appropriate admin roles in Netskope, Entra ID, and Intune for the operator.
**Why:** Creating policies, app definitions, and deployments requires elevated rights in each plane.
**Verify:** Confirm an admin role in each console (Netskope admin; Entra/Intune admin).
**Implement:** Assign least-privilege admin roles; reserve Global Administrator for tenant-wide changes.

## G5. Network and identity fundamentals in place
**Description:** Working DNS, routing/egress, and an identity source (Entra ID / Active Directory) for users and groups.
**Why:** Traffic steering, SSL inspection, and identity-based policy depend on resolvable, routable, identified traffic.
**Verify:** Endpoints resolve DNS and reach the internet; users/groups are present in Entra ID.
**Implement:** Remediate DNS/egress; sync Active Directory to Entra ID if hybrid.

## G6. A pilot group
**Description:** A Microsoft Entra security group of pilot users/devices for staged rollout.
**Why:** Every solution is piloted before fleet rollout to validate steering, policy, and performance.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group → Security** → add members.

## G7. Change control and a rollback path
**Description:** A change window and a documented rollback (disable steering / remove client / revert policy).
**Why:** Inline proxy, decryption, and ZTNA changes affect live traffic and must be reversible.
**Verify:** A rollback procedure is written and approved before enabling inline enforcement.
**Implement:** Define the rollback (e.g. steering exception, client uninstall, policy disable) and a comms plan.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# Implementation — Cisco Secure Client (AnyConnect) VPN Deployment via Microsoft Intune

This is the ordered, click-by-click build. Follow the phases in order:
**Assess → Configure → Pilot → Validate → Expand.** Do **not** skip the pilot. Use the **exact object
names** shown — later steps, tests, troubleshooting, and scripts reference them verbatim.

> **Vendor boundary:** the Cisco head-end (ASA / FTD / ISE), the Cisco Secure Client console, and the
> **VPN Profile Editor** XML authoring are **deferred to Cisco's official documentation**. This guide
> covers the Intune and Entra side at full detail and *consumes* the Cisco-supplied installers, XML
> profile, gateway FQDN, tunnel-group, and auth method as inputs.

## Object naming convention (use verbatim)

| Object | Name |
|---|---|
| Pilot group | `PILOT – Cisco VPN Users` |
| Production group | `PROD – Cisco VPN Users` |
| Windows app | `Cisco Secure Client – VPN – Win32` |
| macOS app | `Cisco Secure Client – VPN – macOS PKG` |
| iOS app | `Cisco Secure Client – VPN – iOS` |
| Android app | `Cisco Secure Client – VPN – Android` |
| Windows VPN profile | `Cisco Secure Client – VPN – Profile – Windows` |
| macOS VPN profile | `Cisco Secure Client – VPN – Profile – macOS` |
| iOS VPN profile | `Cisco Secure Client – VPN – Profile – iOS` |
| Android VPN profile | `Cisco Secure Client – VPN – Profile – Android` |
| Certificate profile (if cert auth) | `Cisco Secure Client – VPN – Device Cert (SCEP)` |
| Assignment filter (optional) | `Filter – Cisco VPN – platform-name` |

---

# Phase 1 — Assess

1. Confirm every item in `02-requirements.md` passes.
2. Gather the Cisco inputs (from your Cisco/network team, per Cisco docs):
   - **Gateway FQDN** (e.g. `vpn.your-company.com`)
   - **Tunnel-group / connection-profile name**
   - **Authentication method** (certificate / SAML-Entra / RADIUS)
   - **Tunnel mode** (split vs full) and any **Per-App VPN** app list
   - **VPN client profile XML** for Windows/macOS (if used)
   - The **Windows MSI module set**, the **signed macOS `.pkg`**, and the store listings for iOS/Android
3. Decide the pilot audience (3–10 users, ideally one device per platform).
4. Run the discovery script to baseline readiness:
   `powershell -ExecutionPolicy Bypass -File .\scripts\CSCVPN-Discovery.ps1`
   Review its readiness table before building anything.

**Gate A (Assess):** All requirements pass, all Cisco inputs recorded, discovery shows the tenant is
ready (enrollment/APNs/Managed Google Play connectors green). If not, stop and remediate.

---

# Phase 2 — Configure

## 2.0 Create the target groups

Use the script (recommended) or the portal.

- **Script:** `powershell -ExecutionPolicy Bypass -File .\scripts\CSCVPN-Set-ScopeTargeting.ps1`
  (creates `PILOT – Cisco VPN Users` and `PROD – Cisco VPN Users` and adds the members you supply).
- **Portal:** Entra admin center → **Groups > New group > Security** → name `PILOT – Cisco VPN Users`
  → add pilot members → **Create**. Repeat for `PROD – Cisco VPN Users`.

## 2.1 (If cert auth) Create the certificate profile

Only if R7 applies (certificate authentication).

1. First ensure the **trusted root CA** profile is deployed (Intune → **Devices > Configuration >
   Create > Windows/macOS/iOS/Android > Trusted certificate**), so the device trusts your issuing CA.
2. Intune → **Devices > Configuration > Create > New Policy** → pick the platform → **Templates >
   SCEP certificate** (or **PKCS certificate**).
3. Name it exactly `Cisco Secure Client – VPN – Device Cert (SCEP)`.
4. Set **Certificate type** (Device or User to match your head-end), **Subject name format**,
   **SAN**, **Key usage**, the **SCEP server URL(s)**, and the **root CA** you deployed in step 1.
5. **Assign** to `PILOT – Cisco VPN Users`. (The issuing CA must be trusted by the Cisco head-end —
   Cisco-side trust config is deferred to Cisco docs.)

## 2.2 Package and deploy the Windows client (Win32)

1. **Prepare the package.** Place the Cisco Secure Client MSI module(s) and the **VPN client profile
   XML** (from R5) into a source folder. Author an install script (or transform) that installs the
   **Core VPN** module and drops the XML into the Secure Client profile directory. Wrap the folder
   into an `.intunewin` with the **Microsoft Win32 Content Prep Tool**:
   `IntuneWinAppUtil.exe -c your-source-folder -s your-setup-file -o your-output-folder`
2. **Add to Intune.** Intune admin center → **Apps > Windows > Add** → App type **Windows app
   (Win32)** → upload the `.intunewin`.
3. **App information.** Name it exactly `Cisco Secure Client – VPN – Win32`; set publisher = Cisco,
   version, and a description.
4. **Program.** Install command (your MSI/script install line, silent); Uninstall command (MSI
   product-code uninstall); Install behavior **System**; Device restart behavior as Cisco specifies.
5. **Requirements.** OS architecture x64; minimum OS version per Cisco support matrix.
6. **Detection rules.** Detect the installed client (MSI product code, or file/version of the Secure
   Client core binary). This is what marks a device *Installed*.
7. **Assignments.** Under **Required**, add `PILOT – Cisco VPN Users`. Leave production for Phase 5.
   Optionally attach `Filter – Cisco VPN – Windows`.
8. **Review + create.**

## 2.3 Build the Windows VPN device-configuration profile

Use this if you deliver VPN settings via Intune (in addition to, or instead of, the bundled XML).

1. Intune → **Devices > Configuration > Create > New Policy** → **Windows 10 and later** →
   **Templates > VPN**.
2. Name it exactly `Cisco Secure Client – VPN – Profile – Windows`.
3. **Connection type:** *Cisco AnyConnect / Cisco Secure Client*.
4. **Connection name** (what the user sees), **Servers** (the gateway FQDN from R6, mark default).
5. **Authentication:** reference the certificate `Cisco Secure Client – VPN – Device Cert (SCEP)`
   for cert auth, or select the appropriate method (SAML/EAP) per R6.
6. **Split tunnel / routes**, **Per-App VPN**, and **trusted network** rules per R6.
7. **Assign** to `PILOT – Cisco VPN Users`. **Review + create.**

## 2.4 Package and deploy the macOS client (PKG)

1. Intune admin center → **Apps > macOS > Add** → App type **macOS app (PKG)** → upload the **signed**
   Cisco Secure Client `.pkg` (R4/R10).
2. Name it exactly `Cisco Secure Client – VPN – macOS PKG`; publisher = Cisco; version.
3. **Detection / app bundle IDs:** supply the bundle ID(s) and versions Cisco documents so Intune can
   confirm install; add any required **pre-install/post-install scripts** if your workflow drops the
   VPN client profile XML.
4. **Assignments:** **Required** → `PILOT – Cisco VPN Users`. **Review + create.**

## 2.5 Build the macOS VPN device-configuration profile

1. Intune → **Devices > Configuration > Create > New Policy** → **macOS** → **Templates > VPN**.
2. Name it exactly `Cisco Secure Client – VPN – Profile – macOS`.
3. **Connection type:** *Cisco AnyConnect / Cisco Secure Client* (or a Custom VPN payload if
   directed by Cisco docs).
4. Set **connection name**, **server** (gateway FQDN from R6), **authentication** (reference the SCEP
   cert or chosen method), split/full tunnel, and Per-App VPN per R6.
5. **Assign** to `PILOT – Cisco VPN Users`. **Review + create.**

## 2.6 Deploy the iOS client (store app) and VPN profile

1. **Store app.** Intune → **Apps > iOS/iPadOS > Add** → App type **iOS store app** → search
   **Cisco Secure Client** → select it → name it exactly `Cisco Secure Client – VPN – iOS` →
   **Assignments: Required** → `PILOT – Cisco VPN Users` → **Review + create**. (Requires APNs, R8.)
2. **VPN profile.** Intune → **Devices > Configuration > Create > New Policy** → **iOS/iPadOS** →
   **Templates > VPN**.
   - Name it exactly `Cisco Secure Client – VPN – Profile – iOS`.
   - **Connection type:** *Cisco AnyConnect / Cisco Secure Client*.
   - **Server** (gateway FQDN, R6), **authentication** (SCEP cert or chosen method), and — where
     used — **Per-App VPN** (associate the apps that should tunnel) and **On-Demand** rules.
   - **Assign** to `PILOT – Cisco VPN Users`. **Review + create.**

## 2.7 Deploy the Android client (Managed Google Play) and VPN profile

1. **Store app.** Intune → **Apps > Android > Add** → App type **Managed Google Play app** →
   search/approve **Cisco Secure Client** → **Sync** → the app appears; name reference
   `Cisco Secure Client – VPN – Android` → **Assignments: Required** → `PILOT – Cisco VPN Users`.
   (Requires Managed Google Play, R9.)
2. **VPN profile.** Intune → **Devices > Configuration > Create > New Policy** → **Android
   Enterprise** → the appropriate profile type (**Device restrictions/VPN** or an **App configuration
   policy** for Secure Client).
   - Name it exactly `Cisco Secure Client – VPN – Profile – Android`.
   - **Connection type:** *Cisco AnyConnect / Cisco Secure Client*; set **server** (R6),
     **authentication**, and Per-App VPN where used.
   - **Assign** to `PILOT – Cisco VPN Users`. **Review + create.**

**Gate B (Configure):** For each platform in scope, the app **and** the matching VPN profile (and
the cert profile if used) exist, are named to convention, and are assigned to
`PILOT – Cisco VPN Users`. Re-run `CSCVPN-Discovery.ps1` — every expected object should now be found.

---

# Phase 3 — Pilot

1. Ensure the pilot devices (one per platform, ideally) are enrolled, compliant, and members of
   `PILOT – Cisco VPN Users`.
2. Trigger a sync (Company Portal → **Sync**, or Intune → device → **Sync**) to pull the app + profile.
3. Allow time for install and profile application (minutes on Windows/macOS; may require the user to
   open the app / accept the VPN config prompt on iOS/Android).
4. On iOS/Android, confirm the user **allows** the VPN configuration when prompted (MDM-delivered VPN
   payloads are silent, but first launch of the client may prompt for the VPN permission).

**Gate C (Pilot):** Every pilot device shows the app *Installed* and the profile *Succeeded* in
Intune monitoring. If any fail, go to `06-troubleshooting.md` before proceeding.

---

# Phase 4 — Validate

1. On a pilot device, run:
   `powershell -ExecutionPolicy Bypass -File .\scripts\CSCVPN-Validation.ps1`
   It confirms the client is installed and the VPN profile is present on *this* device.
2. Perform the manual connection test in `05-testing.md` (open Cisco Secure Client → connect to the
   gateway → authenticate → confirm tunnel up and internal resource reachable).
3. Run the fleet report to see pilot coverage:
   `powershell -ExecutionPolicy Bypass -File .\scripts\CSCVPN-Report.ps1`

**Gate D (Validate):** On every pilot platform, the client installs, the profile applies, and a
**successful VPN connection** to the gateway is established with the intended auth method. All Testing
guide pass/fail gates are green. Only then proceed.

---

# Phase 5 — Expand

1. For each app and each VPN profile (and the cert profile), **add** `PROD – Cisco VPN Users` to the
   **Required** assignment. Keep `PILOT – Cisco VPN Users` assigned (pilot users stay covered).
2. Expand in waves if the fleet is large (e.g. add production sub-groups over several days) and watch
   the report between waves.
3. Monitor with `CSCVPN-Report.ps1` for coverage and with Intune **Apps > Monitor** / **Devices >
   Configuration** for install/profile success.
4. Remediate stragglers with `CSCVPN-Remediation.ps1` (defaults to **-WhatIf** preview — review, then
   re-run with `-WhatIf:$false` to act).

**Rollback (any phase):** Remove/exclude the target group from the app and profile assignments; to
remove the installed Windows client, flip the Win32 app assignment to **Uninstall** for the group.
On iOS/Android, unassigning the store app and profile removes the managed app and VPN config.

**Gate E (Expand):** Fleet coverage meets your target (e.g. ≥ 95% of assigned devices *Installed* +
profile *Succeeded*); remaining failures are triaged. Deployment is complete.

---

## Selecting the correct ASA tunnel group on iOS/iPadOS (important)

A common failure on mobile is getting devices onto a **specific ASA tunnel group** (e.g. a `Mobile`
group) when the connection URL is not just the plain hostname. On a **Windows** client the local
AnyConnect *client profile* (`<ServerList><HostEntry><UserGroup>…`) drives group selection — but on
**iOS/iPadOS under Intune that mechanism is not available**, so use one of the two supported approaches
below. Do **not** try to add a URL path to the FQDN or paste the AnyConnect client profile into an App
Configuration policy (see Troubleshooting — both fail).

### Recommended: select the tunnel group on the ASA by client certificate
Because these devices already authenticate with a client certificate (SCEP/PKCS), let the **ASA** choose
the group from the certificate — the client never needs to know the group:

1. **On the ASA**, map the mobile client certificate to the target tunnel group — build a certificate map
   that matches a field unique to the mobile cert template (e.g. an OU or issuer), and bind it with a
   tunnel-group map so matching sessions land on the `Mobile` group. *(The concept is
   `crypto ca certificate map` → `tunnel-group-map`; confirm exact syntax against current Cisco ASA
   documentation and with your Cisco/network admin.)*
2. **In the Intune VPN profile** (this solution's Step for the Base VPN), set **VPN server address** to the
   **plain FQDN** — e.g. `vpn.contoso.com`, with **no path and no slash** — Connection type **Cisco
   AnyConnect**, Authentication **Certificates** with the SCEP/PKCS cert.
3. Do **not** create a `UserGroup` App Configuration policy — it is unnecessary in this model.

Result: the device connects to the clean FQDN and the ASA routes it to the correct tunnel group from the
certificate. This is the most robust pattern for MDM-deployed, cert-auth AnyConnect at scale — nothing on
the client to drift or break, and it sidesteps the iOS FQDN/app-config limitations entirely.

### Alternative: ASA group-url (only if certificate mapping is not acceptable)
1. **On the ASA**, enable a **group-url** on the target tunnel group so the group is reachable at a URL
   path (e.g. `…/Mobile`). *(Concept: `group-url … enable` under the tunnel-group webvpn attributes —
   verify against current Cisco guidance.)*
2. On iOS the group can only be conveyed through **Cisco's documented Secure Client iOS MDM app-config
   keys** — not by putting a path in the Intune FQDN field and not by pasting the AnyConnect profile XML.
   If Cisco's iOS app supports carrying the connection this way, the profile is delivered as a **string
   value under a plist key** (see Troubleshooting), never as top-level XML. Confirm the exact supported
   key and format in Cisco's "Deploy Cisco Secure Client on Apple iOS/iPadOS with MDM" documentation.

Prefer the certificate-map approach unless a documented constraint requires the group-url path.


---


# Testing & Validation — Cisco Secure Client (AnyConnect) VPN via Intune

Run these tests on the **pilot** before expanding, and spot-check during expansion. Each test has an
explicit **pass/fail gate**. A phase is only "done" when its gate is **PASS**. Object names match the
Implementation guide verbatim.

> **Scope note:** these tests validate that Intune **delivered the client and profile** and that a
> device **can establish the VPN**. Deep head-end diagnostics (why a specific tunnel-group rejects a
> cert, ISE posture results) are Cisco-side and deferred to Cisco docs.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | Tenant/connector readiness | Discovery script | Connectors green; objects found |
| T2 | App install per platform | Intune monitor + device | App *Installed* |
| T3 | VPN profile applied per platform | Intune monitor + device | Profile *Succeeded* |
| T4 | Certificate present (if cert auth) | Device | Cert issued & chains to trusted CA |
| T5 | Manual VPN connect | Pilot device | Tunnel up, internal resource reachable |
| T6 | On-device validation script | Pilot device | Script reports PASS |
| T7 | Fleet coverage report | Report script | Coverage ≥ target |
| T8 | Rollback / uninstall | Test device | App/profile removed cleanly |

---

## T1 — Tenant and connector readiness
**Steps:** Run `CSCVPN-Discovery.ps1`. Review the readiness table: APNs (iOS), Managed Google Play
(Android), the four apps, the four VPN profiles, and the cert profile (if used), each assigned to
`PILOT – Cisco VPN Users`.
**PASS:** All required connectors are active and every expected object is present and assigned.
**FAIL:** Any connector inactive or any expected object missing/unassigned → fix in Requirements/
Implementation before piloting.

## T2 — App install per platform
**Steps:** For each platform, Intune → **Apps > Monitor > App install status** for
`Cisco Secure Client – VPN – (platform)`. On the device, confirm the client binary/app exists
(Windows: Secure Client present in Programs; macOS: app in /Applications; iOS/Android: app icon).
**PASS:** Status *Installed* for the pilot device and the app is visibly present.
**FAIL:** *Failed*/*Pending* beyond the expected window → see Troubleshooting §Install failures.

## T3 — VPN profile applied per platform
**Steps:** Intune → **Devices > Configuration >** `Cisco Secure Client – VPN – Profile – (platform)`
**> Device status**. On device, confirm the VPN connection entry appears (Windows: Secure Client
shows the configured gateway; macOS/iOS: VPN entry in Settings; Android: VPN present).
**PASS:** Profile status *Succeeded* and the connection entry with the correct gateway FQDN is present.
**FAIL:** *Error*/*Conflict* or no connection entry → see Troubleshooting §Profile not applying.

## T4 — Certificate present (cert-auth deployments only)
**Steps:** Confirm `Cisco Secure Client – VPN – Device Cert (SCEP)` shows *Succeeded* in Intune and
the certificate is in the device store (Windows: certlm/certmgr; macOS: Keychain; iOS/Android: the
managed profile shows the cert).
**PASS:** Certificate issued, not expired, and chains to a CA the head-end trusts.
**FAIL:** No cert / wrong chain → see Troubleshooting §Certificate issues.

## T5 — Manual VPN connect (the decisive test)
**Steps:** On the pilot device, open **Cisco Secure Client**, select the configured connection
(gateway FQDN from R6), connect, and authenticate with the intended method (certificate / SAML-Entra
/ RADIUS). Once connected, reach an **internal-only** resource (internal URL, file share, or ping an
internal host) that is *not* reachable without the VPN.
**PASS:** Tunnel establishes; the internal resource is reachable; disconnect returns to normal.
Repeat on **every** piloted platform.
**FAIL:** Auth rejected, no tunnel, or resource unreachable → capture the Secure Client message and
see Troubleshooting §VPN won't connect (and confirm the head-end/tunnel-group with Cisco).

## T6 — On-device validation script
**Steps:** On a pilot device run `CSCVPN-Validation.ps1`.
**PASS:** Script reports the client installed **and** the VPN profile present → overall **PASS**.
**FAIL:** Script reports a missing component → address per its message before counting the device.

## T7 — Fleet coverage report
**Steps:** Run `CSCVPN-Report.ps1`; review install + profile coverage across the assigned groups.
**PASS (pilot):** 100% of pilot devices *Installed* + profile *Succeeded*.
**PASS (expand):** Coverage ≥ your target (e.g. ≥ 95%) with remaining failures triaged.
**FAIL:** Coverage below target → remediate (T2/T3 failures) before widening further.

## T8 — Rollback / uninstall verification
**Steps:** On a disposable test device, exclude it from the target group (or flip the Windows Win32
app to **Uninstall**). Sync.
**PASS:** The managed app and VPN profile are removed; the device returns to its pre-deployment state.
**FAIL:** Residual app/profile → confirm the Uninstall command (Windows) or unassignment took effect.

---

## Overall exit criteria (before Expand)
All of T1–T6 **PASS** on every piloted platform, T7 shows 100% pilot coverage, and T8 confirms a
clean rollback. Record results against each gate; only then proceed to Phase 5 (Expand).


---


# Troubleshooting — Cisco Secure Client (AnyConnect) VPN via Intune

Common failures and fixes, grouped by symptom. Object names match the Implementation guide. Work
top-down within a section — the first cause listed is the most common.

> **Vendor boundary:** problems on the **Cisco head-end** (tunnel-group rejects the cert, ISE posture
> denies access, gateway config) are **deferred to Cisco's official documentation and your Cisco
> admin**. This guide resolves the **Intune/Entra delivery** side and tells you when a failure points
> at the Cisco side.

---

## §Install failures — the app won't install

**Symptom:** Intune shows `Cisco Secure Client – VPN – (platform)` as *Failed* or stuck *Pending*.

1. **Device not synced / not in the group.** Confirm the device's user (or device) is a member of
   `PILOT – Cisco VPN Users` and the assignment intent is **Required**. Force a sync (Company Portal
   → **Sync**, or `CSCVPN-Remediation.ps1 -RetryFailedInstalls`).
2. **(Windows) Detection rule wrong.** If detection doesn't match what the installer actually writes,
   Intune reports *Failed* even when the client installed. Fix the detection rule (MSI product code
   or the Secure Client core binary path/version) on `Cisco Secure Client – VPN – Win32`.
3. **(Windows) Install command / silent switches wrong.** Verify the install command line installs
   the intended modules silently and returns success (exit 0/3010). Check the Intune Management
   Extension log (`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`).
4. **(Windows) Missing module dependency or order.** If you deploy multiple Secure Client modules,
   confirm Core VPN installs first and prerequisites are met.
5. **(macOS) PKG not signed / Gatekeeper.** The PKG must be Cisco-signed (R10). An unsigned/altered
   PKG fails. Re-upload the official signed `.pkg` to `Cisco Secure Client – VPN – macOS PKG`.
6. **(macOS) Bundle-ID/version mismatch for detection.** Supply the exact bundle ID(s)/version Cisco
   documents so Intune detects the install.
7. **(iOS) APNs expired.** If the store app never installs on iOS, check **Tenant administration >
   Connectors and tokens > Apple MDM Push certificate** — renew if expired (R8).
8. **(Android) Managed Google Play not connected / app not approved.** Confirm the connector is
   bound and the Cisco Secure Client app is approved and synced (R9); re-**Sync** apps.

## §Profile not applying — the VPN profile doesn't show up

**Symptom:** `Cisco Secure Client – VPN – Profile – (platform)` shows *Error*/*Conflict*, or the VPN
connection entry never appears on the device.

1. **Profile not assigned to the group.** Confirm the profile is assigned to `PILOT – Cisco VPN
   Users`. `CSCVPN-Discovery.ps1` flags UNASSIGNED profiles; `CSCVPN-Remediation.ps1
   -FixMissingAssignments` adds the assignment.
2. **App not installed yet.** The VPN profile configures the *client*; if the app isn't installed,
   the connection entry may not materialize. Resolve §Install failures first, then re-sync.
3. **Conflicting VPN profile.** Another VPN profile (or a leftover Cisco config) targeting the same
   device can conflict. Remove/scope the conflicting profile so only
   `Cisco Secure Client – VPN – Profile – (platform)` applies.
4. **Wrong connection type / platform.** Ensure the profile's connection type is *Cisco AnyConnect /
   Cisco Secure Client* and the profile platform matches the device OS.
5. **(Windows) Bundled XML vs Intune profile disagree.** If you ship the VPN client profile XML in
   the Win32 package *and* push an Intune VPN profile, keep them consistent (same gateway/behavior);
   contradictions produce confusing client state. Validate with `CSCVPN-Validation.ps1`.
6. **(iOS/Android) VPN permission not granted.** The MDM VPN payload is delivered silently, but the
   user may need to open the client once and allow the VPN configuration. Have the pilot user launch
   the app and accept the prompt.

## §Certificate issues (cert-auth deployments)

**Symptom:** `Cisco Secure Client – VPN – Device Cert (SCEP)` fails, or the VPN rejects the cert.

1. **Trusted root not deployed first.** The device must trust the issuing CA before the SCEP profile
   succeeds. Deploy the **Trusted certificate** profile, then the SCEP profile.
2. **SCEP infrastructure error.** Check the NDES/Intune Certificate Connector health and the SCEP
   server URL(s) in the profile. Re-sync after fixing.
3. **Subject/SAN mismatch.** If the head-end matches on subject/SAN, ensure the SCEP profile's
   subject-name format and SAN produce what the head-end expects (coordinate the required format with
   your Cisco admin).
4. **Head-end doesn't trust the issuing CA (Cisco side).** If the cert is issued correctly but the
   VPN still rejects it, the **Cisco head-end must trust the issuing CA** — this trust config is
   **Cisco-side, deferred to Cisco docs**. Provide your Cisco admin the issuing CA chain.

## §VPN won't connect — client installed, profile present, but no tunnel

**Symptom:** The user opens Cisco Secure Client, tries to connect, and it fails or times out.

1. **Confirm the delivery side is green first.** Run `CSCVPN-Validation.ps1` on the device: client
   installed + profile present must both PASS. If not, resolve the sections above — this is a
   delivery problem, not a connection problem.
2. **Wrong gateway FQDN / unreachable.** Verify the profile's server matches the gateway from R6 and
   the device can resolve/reach it (DNS + network path). A typo or unreachable gateway is common.
3. **Authentication rejected (Cisco side).** If the tunnel starts but auth fails (cert/SAML/RADIUS
   rejected), the decision is on the **head-end / ISE** — **deferred to Cisco docs**. Capture the
   exact Secure Client error message and the tunnel-group name, and work it with your Cisco admin.
   Common cert cause is head-end CA trust (see §Certificate issues #4).
4. **SAML/Entra SSO loop or failure.** For SAML auth, confirm the head-end's SAML app in Entra is
   configured and the user has access; the Intune side only delivers client+profile.
5. **Split/full tunnel or Per-App scope surprises.** If the tunnel is up but an internal resource is
   unreachable, check the tunnel mode and Per-App VPN scope in the profile (R6) — the app/resource
   may not be routed through the tunnel.
6. **Client/head-end version mismatch.** If the head-end requires a newer/older client than deployed,
   align the packaged version (R4) with what the head-end supports and re-pilot.

## §Reporting/script issues

1. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph
   -Scope CurrentUser`) and consent to the scopes each script lists in its header. Read-only scripts
   need only `.Read.All` scopes.
2. **Objects show MISSING but exist in the portal.** The scripts match **by exact display name** —
   confirm the object is named to convention verbatim (including the en-dash `–` and spacing).
   Rename any drifted object to the convention.
3. **Remediation "made no changes."** By design — it defaults to **-WhatIf**. Re-run with
   `-WhatIf:$false` after reviewing the previewed actions.

---

## iOS/iPadOS — selecting a specific ASA tunnel group (three failures that look different but share one cause)

These three attempts all try to steer iOS devices to a non-default ASA tunnel group and all fail — the
supported fix is in Implementation ("Selecting the correct ASA tunnel group on iOS/iPadOS"): map the
group on the ASA by client certificate.

- **Symptom:** VPN "Unable to contact" / "Connection attempt timed out" right after adding the group.
  - **Cause:** a **URL path was added to the FQDN** (e.g. `vpn.contoso.com/Mobile`). The Intune VPN
    **Server address is a hostname field** — the whole string is sent to DNS, which resolves *hostnames
    only*. `vpn.contoso.com/Mobile` is not a hostname → NXDOMAIN → timeout.
  - **Fix:** Server address must be the **plain FQDN**, no slash/path. Select the group on the ASA (cert
    map) instead — see Implementation.

- **Symptom:** an App Configuration policy with a bare **`UserGroup = Mobile`** key is assigned but the
  device still lands on the default group.
  - **Cause:** on **Windows** the AnyConnect *client profile* (`<HostEntry><UserGroup>`) drives group
    selection; **iOS under Intune does not consume that profile**, and a lone `UserGroup` key, detached
    from its parent `<HostEntry>` server-list structure, is not interpreted as a group selector — it is
    ignored.
  - **Fix:** remove it; select the group on the ASA (cert map). Do not rely on a bare app-config key.

- **Symptom:** pasting the AnyConnect profile into an App Configuration policy (**"Enter XML data"**)
  errors with **"Property list must begin and end with 'dict' tag. Remove XML headers from property
  list."**
  - **Cause:** that field is an **Apple property list (plist)**, not a free-form XML document. A plist
    must (1) have a **lowercase `<dict>`** root — `<Dict>` (capitalized) is not recognized — and (2)
    contain only `<key>`/value pairs. A pasted `<AnyConnectProfile xmlns="…" xmlns:xsi="…" …>` carries
    **XML namespace declarations** (the "XML headers") that a plist `<dict>` cannot hold. Managed App
    Configuration is not a transport for the AnyConnect profile schema, so this cannot work regardless of
    formatting.
  - **Fix:** don't paste the profile here. Use the ASA certificate-map approach (Implementation). If a
    valid plist is needed at all, it must be lowercase `<dict>` with `<key>`/`<string>` pairs, e.g.
    `<dict><key>UserGroup</key><string>Mobile</string></dict>` — and if Cisco's iOS app documents carrying
    the connection this way, the profile goes in as a **CDATA string value under a key**, never as
    top-level elements. Confirm the exact supported key with Cisco's iOS MDM app-config documentation.

---

If a failure persists after the Intune/Entra side is confirmed healthy (validation PASS, profile
*Succeeded*, cert issued) and the tunnel still won't establish or authenticate, treat it as a
**Cisco head-end issue** and continue with **Cisco's official documentation** and your Cisco admin.


---


# Best Practices — Cisco Secure Client (AnyConnect) VPN via Intune

Field-proven practices for the assign-once, repeat-everywhere model. These make the deployment
predictable, reversible, and easy to operate at scale.

## Naming and structure
- **Name every object to the convention and reuse it verbatim.** Apps, VPN profiles, the cert
  profile, groups, and filters all follow `Cisco Secure Client – VPN – …` / `PILOT – Cisco VPN
  Users`. The discovery, validation, report, and remediation scripts find objects **by these names**
  — drift breaks automation and reporting.
- **One app + one profile per platform.** Keep exactly one app object and one VPN profile per
  platform. Do not fork "test" copies in production; use assignment (pilot vs prod group) to stage.
- **Keep pilot and production groups separate and both assigned.** `PILOT – Cisco VPN Users` stays
  assigned after expansion so pilot members keep the client and you retain a fast test cohort.

## Pilot-first, always
- **Never skip the pilot,** even for "simple" profile changes. Every change to the app package or the
  VPN profile goes to `PILOT – Cisco VPN Users` first and passes the Testing gates before production.
- **Cover every platform in the pilot.** Include at least one Windows, macOS, iOS, and Android device
  so a platform-specific packaging or profile issue is caught before fleet rollout.
- **Expand in waves.** For large fleets, add production sub-groups over several days and watch
  `CSCVPN-Report.ps1` between waves rather than assigning everyone at once.

## The app-plus-profile discipline
- **Always deploy the app and the matching profile to the same group.** A device should be either
  fully ready or clearly not — never an installed client with no connection defined, or a profile
  with no client.
- **Use assignment filters** (e.g. `Filter – Cisco VPN – Windows`) to scope by OS/ownership when a
  single group spans platforms, so each platform's app/profile only targets the right devices.

## Authentication and certificates
- **Prefer certificate authentication** for silent, always-available connect on managed devices.
  Deliver the device/user cert via `Cisco Secure Client – VPN – Device Cert (SCEP)` and ensure the
  **issuing CA is trusted by the Cisco head-end** (Cisco-side trust config per Cisco docs).
- **Deploy the trusted root/intermediate first,** then the SCEP profile, then the VPN profile that
  references the cert — order matters so the cert exists when the VPN needs it.
- **Watch certificate lifetime and renewal.** SCEP renewal thresholds should comfortably precede
  expiry so devices never lose connectivity; monitor cert profile status in the report.
- **For SAML/Entra SSO**, keep the client and profile deployment Intune-side and let the head-end own
  the SAML trust — no secrets are provisioned to the device.

## Packaging (Windows/macOS)
- **Use the vendor's signed binaries.** Do not re-sign or repackage Cisco installers; use the exact
  entitled version your head-end supports (macOS PKG must stay Cisco-signed for Gatekeeper/detection).
- **Bundle the VPN client profile XML in the Win32/PKG package** for immediate connection defaults on
  Windows/macOS, and keep it in sync with any Intune VPN profile so the two never contradict.
- **Write precise detection rules** (MSI product code / binary version) so Intune reports install
  truth — vague detection produces false "installed"/"failed" noise.
- **Set install behavior to System** and match Cisco's supported OS/architecture in Requirements.

## Change control and rollback
- **Keep a one-click rollback ready:** exclude the group, or flip the Windows Win32 app to
  **Uninstall**. Test the rollback (Testing T8) before you ever need it.
- **Deploy inside a change window** and announce it — remote-access changes affect real users.
- **Version your inputs.** Track which installer version, XML profile, and gateway values a given
  rollout used, so you can reproduce or revert precisely.

## Operate and monitor
- **Run `CSCVPN-Report.ps1` on a schedule** (e.g. weekly) to track coverage drift as devices enroll
  and leave, and to catch profile *Error* states early.
- **Remediate safely.** `CSCVPN-Remediation.ps1` defaults to **-WhatIf** — always preview the planned
  actions, then re-run with `-WhatIf:$false`. Never let a remediation run act without a preview first.
- **Least-privilege admin.** Use Intune Administrator + Groups Administrator for the operator; reserve
  Global Administrator for tenant-wide changes only.

## Security hygiene
- **Never store VPN credentials in Intune profiles.** Use certificate or SAML auth; where
  username/password is unavoidable, let the client prompt — do not embed secrets.
- **Scope Per-App VPN deliberately.** Only tunnel the apps that need internal access; over-broad
  tunneling hurts performance and privacy.
- **Keep the client patched.** Update the app package when Cisco releases fixes; pilot the new version
  before fleet-wide expansion, same as any change.


---


# Deliverables Summary — Cisco Secure Client (AnyConnect) VPN via Intune

This solution is a complete, self-guided package to deploy the Cisco Secure Client and its VPN
profiles across Windows, macOS, iOS, and Android using Microsoft Intune — pilot-first and
rollback-ready. Below is everything included.

## Documentation set (source/)

| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | The app-plus-profile model, per-platform delivery (Win32 / macOS PKG / iOS & Android store app + profile), auth options, benefits, limits, and the Assess→Configure→Pilot→Validate→Expand model. |
| `02-requirements.md` | Every prerequisite with **Description / Why / Verify / Implement-if-missing** — Intune licensing + enrollment, Entra groups, the Cisco head-end/ISE, installers + XML profile, APNs, Managed Google Play, macOS PKG signing, certificate infrastructure. |
| `03-implementation.md` | Exact ordered build: package the client per platform, build the VPN device-configuration profiles, assign to the named pilot group, validate, pilot, expand — with pass/fail gates and a naming table. |
| `05-testing.md` | The validation test matrix (T1–T8) with explicit **PASS/FAIL** gates, including the decisive manual VPN-connect test. |
| `06-troubleshooting.md` | Failure-by-symptom fixes: install failures, profile not applying, certificate issues, VPN won't connect, and script/reporting issues. |
| `07-best-practices.md` | Field-proven practices for naming, pilot-first, packaging, certificates, change control, and safe operation. |
| `executive-summary.md` | One-page business-outcome summary for stakeholders. |
| `global-requirements-network.md` | Category-level Network prerequisites (shared across Network solutions). |

## PowerShell scripts (scripts/)

All five use the **Microsoft Graph PowerShell SDK**. Discovery/validation/report are **read-only**;
remediation and scope-targeting **default to `-WhatIf` (preview)** and change nothing until you
re-run with `-WhatIf:$false`. Each script's header documents its exact purpose, run command, and
required Graph scopes.

| Script | Purpose | Mode |
|---|---|---|
| `CSCVPN-Discovery.ps1` | Deployment-readiness sweep across Entra + Intune — enrollment connectors (APNs, Managed Google Play), the four Secure Client apps, the four VPN profiles, the optional SCEP cert profile, and the pilot/prod groups, with assignment state. | Read-only |
| `CSCVPN-Validation.ps1` | Confirms **on this device** that the Secure Client is installed and its VPN profile (and, optionally, a device certificate) is present. Prints an overall PASS/FAIL. | Read-only (local) |
| `CSCVPN-Report.ps1` | Fleet coverage report — per-app install and per-profile apply counts (installed/failed/pending) with coverage percentages and an overall figure; optional CSV export. | Read-only |
| `CSCVPN-Remediation.ps1` | Safely fixes stragglers — retries failed installs via device sync and adds missing Required assignments to the target group. | Write, **default `-WhatIf`** |
| `CSCVPN-Set-ScopeTargeting.ps1` | Creates/populates the pilot (and optional production) Entra security groups used as assignment targets. | Write, **default `-WhatIf`** |

## The consistent object naming convention

Every artifact is named to a convention and reused verbatim across docs, tests, troubleshooting, and
scripts (so the scripts find objects deterministically):

- Groups: `PILOT – Cisco VPN Users`, `PROD – Cisco VPN Users`
- Apps: `Cisco Secure Client – VPN – Win32` / `– macOS PKG` / `– iOS` / `– Android`
- VPN profiles: `Cisco Secure Client – VPN – Profile – Windows` / `– macOS` / `– iOS` / `– Android`
- Certificate profile: `Cisco Secure Client – VPN – Device Cert (SCEP)`

## Vendor boundary (what is deferred)

The **Cisco Secure Client console, the VPN Profile Editor / XML internals, and the VPN head-end
(ASA / Firepower FTD / ISE) configuration are deferred to Cisco's official documentation.** This
solution authors the **Intune and Entra** side at full click-by-click detail and consumes the
Cisco-supplied installers, VPN profile XML, gateway FQDN, tunnel-group, and auth method as inputs.
