# Pre-Logon VPN Connectivity with Cisco Secure Client Start Before Logon (SBL/PLAP) via Microsoft Intune

> **Version 1.0.0** · Category: Network · Solution code: SBLVPN

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Pre-Logon VPN Connectivity with Cisco Secure Client Start Before Logon (SBL/PLAP) via Microsoft Intune

## The business problem
A normal VPN can only connect *after* a user has already signed in to Windows — which is exactly the
wrong order for remote workers. A user who has **never logged on to a device** has no cached
credentials to sign in with off-network; an **off-network password change or reset** can't reach a
domain controller; **Group Policy and logon scripts** don't process; and hybrid-joined machines can't
see a domain controller at logon. The help desk ends up couriering laptops, running users through
manual VPN dances, or relying on cached passwords that drift out of date.

## The solution
This is a complete, self-guided package that deploys the **Cisco Secure Client (AnyConnect)** with its
**Start Before Logon (SBL)** capability to **Windows** devices through **Microsoft Intune**, so the VPN
tunnel comes up **at the logon screen, before Windows sign-in.** Start Before Logon is delivered as the
**Pre-Login Access Provider (PLAP)** — a "Network sign-in" option on the logon screen — and it only
works when three things are true, all of which this solution automates from the cloud: the **Start
Before Logon module** is installed (after the Core module), the VPN profile has
**`UseStartBeforeLogon` set to true**, and a **device certificate** is present so the tunnel can
authenticate with no user signed in. It uses a proven rollout method:
**Assess → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates and a one-click
rollback.

## What you get
- **Step-by-step implementation** at click-by-click detail on the Intune/Entra/Windows side —
  deploying the trusted root and **device** certificate, packaging the Win32 app that installs **Core
  then SBL** and drops the SBL-enabled profile, building the Windows VPN profile, and assigning to a
  named pilot group.
- **A folded-in certificate-lifecycle section** — why pre-logon needs a machine certificate, how to
  issue it via SCEP/PKCS, and how to keep it renewed so pre-logon never silently breaks.
- **Five PowerShell scripts** — readiness discovery, on-device validation (checks the client, the
  **PLAP/SBL** component, `UseStartBeforeLogon`, and the device cert), fleet coverage reporting, safe
  remediation (preview-by-default), and pilot-group creation.
- **Requirements, testing, troubleshooting, and best-practice guides** so a competent Intune admin can
  implement it end to end — including the decisive test: connect at the logon screen, then log on with
  the tunnel already up.

## Business outcomes
- **First remote logon just works** — a brand-new user on a brand-new device signs in from anywhere,
  no cached credentials required.
- **Off-network password resets and GPO/logon scripts succeed** — the domain controller is reachable
  before Windows logon.
- **Silent and hands-off** — a device certificate authenticates the pre-logon tunnel with no user
  interaction; the whole build is delivered from Intune with no per-device touch.
- **Lower risk** — piloted before fleet-wide rollout, validated against explicit gates, and reversible
  at any point, so a change never strands users at the logon screen.

## Scope and boundary
The solution is authored at full detail on the **Microsoft Intune, Entra ID, and Windows** side and is
**Windows-only** (Start Before Logon is a Windows credential-provider feature). The **Cisco Secure
Client console, the VPN Profile Editor XML internals, head-end CA trust, and the VPN head-end (ASA /
Firepower / ISE)** are the customer's existing Cisco environment and follow **Cisco's official
documentation** — this package consumes those artifacts (Core + SBL modules, the SBL-enabled VPN
profile, gateway details, auth method) and delivers them reliably to every device.

## Bottom line
The VPN tunnel up **before** Windows logon, on every managed Windows device — first remote logon,
off-network password resets, and GPO all working from anywhere, delivered from Intune, proven on a
pilot before you scale, and a fraction of the cost and time of a hands-on consulting engagement.


---


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


---


# Requirements — Pre-Logon VPN Connectivity with Cisco Secure Client Start Before Logon (SBL/PLAP) via Microsoft Intune

Confirm **every** requirement below before you build. Each entry follows the same shape:
**Description / Why required / How to verify / How to implement if missing.** The category-level
prerequisites (Entra tenant, Intune, admin roles, pilot group, change control) are in
`global-requirements-network.md`; the items here are specific to deploying Cisco Secure Client with
**Start Before Logon (SBL/PLAP)** and the device certificate that makes silent pre-logon possible.

> **Vendor boundary:** the **Cisco Secure Client console, the VPN Profile Editor / XML internals, and
> the VPN head-end (ASA / Firepower FTD / ISE) configuration are deferred to Cisco's official
> documentation.** Below, "obtain from Cisco" means *get the artifact/value from your Cisco admin or
> Cisco docs* — this guide does not fabricate Cisco menu paths.

> **Government note (GCC High / DoD):** the steps below name the commercial portals
> (`https://intune.microsoft.com`, `https://entra.microsoft.com`, `https://login.microsoftonline.com`).
> In a US-Gov (GCC High / DoD) tenant use the sovereign portals instead —
> `https://intune.microsoft.us`, `https://entra.microsoft.us`, and
> `https://login.microsoftonline.us` — and **verify each step for GCC High**, as feature availability
> and rollout can differ. This guide does not invent GCC-specific menus.

---

## R1. Windows-only scope confirmed
**Description:** The target devices for pre-logon VPN are **Windows** (Windows 10/11) devices; Start
Before Logon is a Windows-only feature.
**Why required:** SBL is implemented as a Windows credential provider (PLAP). macOS/iOS/Android have no
equivalent and cannot receive this build.
**How to verify:** Your in-scope device list is Windows only.
**How to implement if missing:** Scope the pilot and production groups to Windows devices/users. If you
also need after-logon VPN on macOS/iOS/Android, deploy that with the separate multi-platform Secure
Client VPN solution — it is out of scope here.

## R2. Microsoft Intune licensing and enrolled Windows devices
**Description:** An Intune-bearing license plan (e.g. Microsoft 365 E3/E5, EMS, or Intune standalone)
and the target Windows devices already enrolled and shown in Intune.
**Why required:** Intune is the delivery plane for the app, the VPN profile, and the certificate
profiles. Nothing deploys to a device that is not enrolled and licensed.
**How to verify:** In the **Microsoft Intune admin center** (`https://intune.microsoft.com`), go to
**Devices > All devices** and confirm the target Windows devices are present and *Compliant/Managed*.
Under **Tenant administration > Licenses**, confirm Intune licenses are assigned to the pilot users.
**How to implement if missing:** Assign an Intune-bearing license to the pilot users (Microsoft 365
admin center → **Users** → assign licenses). Enroll Windows devices via Autopilot / Company Portal.

## R3. Entra ID security groups (pilot and production)
**Description:** A pilot group `PILOT – Pre-Logon VPN (SBL) Users` and a production target group
`PROD – Pre-Logon VPN (SBL) Users`, containing the users to receive the pre-logon build.
**Why required:** Intune assignments target Entra groups. The pilot-first model requires a small, named
pilot group distinct from the eventual production audience.
**How to verify:** In the **Microsoft Entra admin center** (`https://entra.microsoft.com`), go to
**Groups > All groups** and confirm `PILOT – Pre-Logon VPN (SBL) Users` exists with the intended members.
**How to implement if missing:** Entra → **Groups > New group > Security**; name it exactly
`PILOT – Pre-Logon VPN (SBL) Users`; add 3–10 representative pilot members. The included
`SBLVPN-Set-ScopeTargeting.ps1` script creates and populates these groups for you.

## R4. A Cisco VPN head-end (ASA / Firepower FTD) — with ISE where used
**Description:** A reachable Cisco VPN termination point (ASA or Firepower Threat Defense) with a
configured **tunnel group / connection profile** that accepts a **certificate**-authenticated
connection, plus **Cisco ISE** if you use posture or identity-based authorization.
**Why required:** The pre-logon client needs something to connect *to*, and the head-end must accept the
device certificate at the logon screen (no user context). The gateway FQDN, tunnel-group name, and
accepted auth method are inputs to the Intune VPN profile and the SBL-enabled XML.
**How to verify:** Obtain from your Cisco/network team: the **gateway FQDN** (e.g.
`vpn.your-company.com`), the **tunnel-group / connection-profile name**, and confirmation that the
tunnel-group accepts **certificate** auth for machine/pre-logon connections.
**How to implement if missing:** Stand up / configure the ASA or FTD head-end (and optionally ISE) with
a certificate-accepting tunnel-group **per Cisco's official documentation** — Cisco-side work outside
this solution's scope. Record the FQDN, connection-profile name, and auth method for R7/Implementation.

## R5. Cisco Secure Client installers — Core VPN **and** Start Before Logon modules
**Description:** The official Cisco Secure Client Windows installers, including **both** the **Core VPN**
module and the **Start Before Logon** module (the SBL module that registers the PLAP credential
provider, `vpnplap64.dll`).
**Why required:** SBL is a separate module layered on Core VPN. Without the Start Before Logon module
the PLAP DLL is never installed and the logon-screen "Network sign-in" option cannot appear.
**How to verify:** Download the installers from your **Cisco Software Download** entitlement and confirm
the package set includes the **Start Before Logon** module for the version your head-end supports.
**How to implement if missing:** Obtain the correct entitled version (Core VPN + Start Before Logon
modules) from Cisco. Do not repackage or re-sign Cisco binaries; use the vendor-provided modules.

## R6. Cisco VPN client profile (XML) with SBL enabled
**Description:** The Cisco **VPN client profile** (an XML file authored in Cisco's **VPN Profile
Editor** or delivered from the head-end) that contains
**`<UseStartBeforeLogon>true</UseStartBeforeLogon>`** and references the correct gateway.
**Why required:** The Start Before Logon module only activates the PLAP credential provider when the
deployed profile sets `UseStartBeforeLogon` to `true`. This XML is bundled into the Win32 package and
dropped into the Secure Client profile directory on install.
**How to verify:** Open the `.xml` and confirm it contains
`<UseStartBeforeLogon>true</UseStartBeforeLogon>` (inside the preferences block) and the correct
gateway FQDN from R4.
**How to implement if missing:** Have your Cisco admin author/export the VPN client profile with Start
Before Logon enabled **per Cisco's VPN Profile Editor documentation** (deferred to Cisco). Store the XML
with your Win32 packaging inputs.

## R7. VPN connection parameters recorded
**Description:** A recorded set of connection values: **gateway FQDN**, **tunnel-group / connection
profile**, **authentication method** (device certificate for silent pre-logon), tunnel mode
(**split** vs **full**), and any **trusted-network / connect-on-logon** behavior.
**Why required:** These are the exact fields that go into the SBL-enabled XML and the Intune VPN
profile. Consistency here is what makes every device identical.
**How to verify:** You have a single sheet listing each value; a manual client connect using those
values succeeds against the head-end with certificate auth.
**How to implement if missing:** Collect the values from R4/R6 and your security requirements. Decide
split vs full tunnel with the network/security owner before building the profile.

## R8. Device-certificate decision — device (machine) cert, not user cert
**Description:** A decision, recorded, to authenticate pre-logon with a **Device (machine)
certificate** issued to the **LocalMachine** store — not a user certificate.
**Why required:** At the logon screen there is **no user context**, so a *user* certificate is not
available to the pre-logon tunnel. Only a **machine** certificate present in `LocalMachine\My` can
authenticate before Windows sign-in.
**How to verify:** Your design specifies **Certificate type = Device** for the SCEP/PKCS profile.
**How to implement if missing:** Choose **Device** for the certificate profile (Implementation §2.2).
Only use a user certificate if you have deliberately chosen interactive post-logon connect, which does
not satisfy true first-logon pre-logon connectivity.

## R9. Certificate infrastructure (PKI / NDES-SCEP or Intune Cloud PKI)
**Description:** A working PKI path for Intune to deliver a **device** certificate — an on-prem
**NDES/SCEP** connector, **Intune Cloud PKI**, or a supported third-party CA connector — plus the
**trusted root/intermediate CA** you will publish to devices.
**Why required:** Silent pre-logon depends on each device receiving a machine certificate the head-end
trusts, delivered by Intune, chaining to a root the device also trusts.
**How to verify:** Intune → **Devices > Configuration**; a SCEP (or PKCS) certificate profile can be
created and the SCEP/connector infrastructure is healthy; you have the root/intermediate CA cert file
to publish.
**How to implement if missing:** Stand up the SCEP/PKCS path (NDES + Intune Certificate Connector, or
enable Intune Cloud PKI), and obtain the trusted root/intermediate CA certificate. Ensure the **issuing
CA is trusted by the Cisco head-end** (Cisco-side trust config is deferred to Cisco docs).

## R10. Certificate renewal policy defined
**Description:** A defined **certificate validity period** and **renewal threshold** (percentage of
lifetime remaining, or days) for the device certificate profile so certificates renew *before* expiry.
**Why required:** Pre-logon silently breaks the moment the device certificate expires. A renewal
threshold comfortably ahead of expiry keeps the tunnel authenticating at every logon.
**How to verify:** Your SCEP/PKCS profile design records a validity period and a renewal threshold
(e.g. renew at 20% remaining lifetime).
**How to implement if missing:** Set a renewal threshold in the certificate profile (Implementation
§2.2) and include the certificate in the coverage report so expiries are caught early.

## R11. Administrative roles for building the deployment
**Description:** Intune admin rights to create Win32 apps, VPN configuration profiles, and certificate
profiles, and Entra rights to create/populate groups (Groups Administrator or better).
**Why required:** Packaging apps, creating VPN/cert profiles, and assigning groups all require elevated
roles.
**How to verify:** In Intune, you can reach **Apps > Add** and **Devices > Configuration > Create**; in
Entra you can create groups.
**How to implement if missing:** Have a Global Administrator assign **Intune Administrator** and
**Groups Administrator** (least-privilege) to the operator.

## R12. Microsoft Win32 Content Prep Tool
**Description:** The **Microsoft Win32 Content Prep Tool** (`IntuneWinAppUtil.exe`) on the packaging
workstation, used to wrap the Core + SBL modules and the SBL-enabled XML into an `.intunewin`.
**Why required:** Multi-module install with an enforced order (Core then Start Before Logon) plus the
profile-XML drop is best delivered as a Win32 app, which requires the `.intunewin` package.
**How to verify:** `IntuneWinAppUtil.exe` runs and reports its version.
**How to implement if missing:** Download the Win32 Content Prep Tool from Microsoft's official
`microsoft-Win32-Content-Prep-Tool` release and place it on the packaging workstation.

## R13. Microsoft Graph PowerShell SDK (to run the included scripts)
**Description:** The **Microsoft.Graph** PowerShell SDK installed on the operator workstation, used by
the discovery/report/remediation/targeting scripts (the on-device validation script runs locally and
needs no Graph).
**Why required:** The scripts call Microsoft Graph (Intune/Entra) to inventory the app, profiles,
certificate profiles, assignments, and group membership.
**How to verify:** In PowerShell, `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**How to implement if missing:** Run `Install-Module Microsoft.Graph -Scope CurrentUser`. The scripts
call `Connect-MgGraph` with the specific delegated scopes each one documents in its header.

## R14. Change control and rollback (category requirement, restated)
**Description:** An approved change window and a written rollback (exclude the group / uninstall the app
/ remove the profiles).
**Why required:** Pushing a pre-logon VPN client, an SBL credential provider, and a machine certificate
touches the logon experience for real users; changes must be reversible.
**How to verify:** A rollback procedure exists and is approved; you know how to exclude
`PILOT – Pre-Logon VPN (SBL) Users` and how to flip the Win32 app to **Uninstall** if needed.
**How to implement if missing:** Document the rollback (Intune assignment exclusion, app Uninstall
intent, profile/cert removal) and the comms plan before you assign anything.

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


# Implementation — Pre-Logon VPN Connectivity with Cisco Secure Client Start Before Logon (SBL/PLAP) via Microsoft Intune

This is the ordered, click-by-click build. Follow the phases in order:
**Assess → Configure → Pilot → Validate → Expand.** Do **not** skip the pilot. Use the **exact object
names** shown — later steps, tests, troubleshooting, and scripts reference them verbatim.

> **Vendor boundary:** the Cisco head-end (ASA / FTD / ISE), the Cisco Secure Client console, and the
> **VPN Profile Editor** XML authoring (including where `<UseStartBeforeLogon>true</UseStartBeforeLogon>`
> is set) are **deferred to Cisco's official documentation**. This guide covers the Intune, Entra, and
> Windows side at full detail and *consumes* the Cisco-supplied installer modules, SBL-enabled XML
> profile, gateway FQDN, tunnel-group, and auth method as inputs.

> **Government (GCC High / DoD):** substitute the sovereign portals — `https://intune.microsoft.us`,
> `https://entra.microsoft.us`, `https://login.microsoftonline.us` — and **verify each step for GCC
> High**. Menu names below are the commercial names.

## Object naming convention (use verbatim)

| Object | Name |
|---|---|
| Pilot group (users) | `PILOT – Pre-Logon VPN (SBL) Users` |
| Production group (users) | `PROD – Pre-Logon VPN (SBL) Users` |
| Win32 app (Core + SBL modules) | `Cisco Secure Client – Pre-Logon (SBL) – Win32` |
| Windows VPN profile | `Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows` |
| Trusted root CA profile | `Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows` |
| SCEP device certificate profile | `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows` |
| Assignment filter (optional) | `Filter – Pre-Logon VPN – Windows` |

---

# Phase 1 — Assess

1. Confirm every item in `02-requirements.md` passes.
2. Gather the Cisco inputs (from your Cisco/network team, per Cisco docs):
   - **Gateway FQDN** (e.g. `vpn.your-company.com`)
   - **Tunnel-group / connection-profile name** (must accept **certificate** auth)
   - **Authentication method** — **device certificate** for silent pre-logon
   - **Tunnel mode** (split vs full)
   - The **Windows Core VPN module** and the **Start Before Logon module** installers
   - The **SBL-enabled VPN client profile XML** (contains `<UseStartBeforeLogon>true</UseStartBeforeLogon>`)
3. Confirm the **PKI path** for a **device** certificate (R8–R10): SCEP/PKCS infrastructure healthy,
   the trusted root/intermediate CA cert in hand, and the issuing CA trusted by the Cisco head-end.
4. Decide the pilot audience (3–10 Windows users).
5. Run the discovery script to baseline readiness:
   `powershell -ExecutionPolicy Bypass -File .\scripts\SBLVPN-Discovery.ps1`
   Review its readiness table before building anything.

**Gate A (Assess):** All requirements pass, all Cisco inputs recorded (including the **SBL-enabled**
XML), the PKI path for a **device** certificate is confirmed, and discovery shows the tenant is ready.
If not, stop and remediate.

---

# Phase 2 — Configure

## 2.0 Create the target groups

Use the script (recommended) or the portal.

- **Script:** `powershell -ExecutionPolicy Bypass -File .\scripts\SBLVPN-Set-ScopeTargeting.ps1`
  (creates `PILOT – Pre-Logon VPN (SBL) Users` and `PROD – Pre-Logon VPN (SBL) Users` and adds the
  members you supply).
- **Portal:** Entra admin center → **Groups > New group > Security** → name
  `PILOT – Pre-Logon VPN (SBL) Users` → add pilot members → **Create**. Repeat for
  `PROD – Pre-Logon VPN (SBL) Users`.

## 2.1 (Optional) Create the assignment filter

If a single group spans device types, create a Windows filter to keep this build on Windows only.

1. Intune → **Tenant administration > Filters > Create**.
2. Name it exactly `Filter – Pre-Logon VPN – Windows`; **Platform: Windows 10 and later**.
3. Set a rule (e.g. `(device.operatingSystem -eq "Windows")`); **Review + create**. Attach it to the
   app/profile assignments in the steps below where you want to scope by OS.

## 2.2 Certificate lifecycle for pre-logon VPN (device certificate via SCEP/PKCS)

**Do this before packaging the client.** Pre-logon authenticates with a **Device (machine)
certificate** because at the logon screen there is **no user context** — a user certificate is not
available. Deploy the trust chain first, then the device certificate, so the certificate exists in
`LocalMachine\My` by the time the VPN needs it.

### 2.2a Deploy the Trusted Root CA profile (trust the issuing CA first)

1. Intune → **Devices > Configuration > Create > New Policy**.
2. **Platform:** *Windows 10 and later*. **Profile type:** *Templates* → **Trusted certificate**.
3. Name it exactly `Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows`.
4. Upload your **root (and intermediate, if separate) CA** `.cer` file; set the **Destination store**
   to **Computer certificate store – Root** (root) / **Intermediate** (intermediate) as appropriate.
5. **Assignments: Required** → `PILOT – Pre-Logon VPN (SBL) Users` (optionally with
   `Filter – Pre-Logon VPN – Windows`). **Review + create.**

### 2.2b Deploy the SCEP device-certificate profile

1. Intune → **Devices > Configuration > Create > New Policy**.
2. **Platform:** *Windows 10 and later*. **Profile type:** *Templates* → **SCEP certificate** (use
   **PKCS certificate** instead if your PKI uses PKCS — the field intent is the same).
3. Name it exactly `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows`.
4. Set the fields:
   - **Certificate type: Device** (this is mandatory for pre-logon — see R8).
   - **Subject name format:** e.g. `CN={{DeviceName}}` (or the format your head-end matches on).
   - **Subject alternative name:** add a SAN (e.g. DNS = `{{DeviceName}}`) if the head-end matches on SAN.
   - **Certificate validity period:** per R10 (e.g. 1 year).
   - **Key storage provider (KSP):** TPM if available, else software.
   - **Key usage:** *Digital signature* and *Key encipherment*.
   - **Extended key usage:** *Client Authentication* (`1.3.6.1.5.5.7.3.2`).
   - **Renewal threshold (%):** per R10 (e.g. 20) so certs renew before expiry.
   - **SCEP server URLs:** your NDES/SCEP (or Cloud PKI) URL(s).
   - **Root CA certificate:** reference the trusted-root profile from 2.2a.
5. **Assignments: Required** → `PILOT – Pre-Logon VPN (SBL) Users`. **Review + create.**
   (The issuing CA must be trusted by the Cisco head-end — Cisco-side trust config is deferred to
   Cisco docs.)

**Certificate best-practice note:** the renewal threshold must comfortably precede expiry so devices
never lose the pre-logon tunnel; keep the certificate profile in the coverage report (Phase 5) so an
expiring or failed certificate is caught before it silently breaks pre-logon at the logon screen.

## 2.3 Package and deploy the Windows client (Win32) — Core then SBL, with the SBL-enabled XML

1. **Prepare the package.** Place into a source folder:
   - the **Core VPN module** installer,
   - the **Start Before Logon module** installer,
   - the **SBL-enabled VPN client profile XML** (from R6, containing
     `<UseStartBeforeLogon>true</UseStartBeforeLogon>`).
   Author an install script (`install.cmd` / PowerShell) that:
   1. installs the **Core VPN module first**,
   2. then installs the **Start Before Logon module** (order matters — Core before SBL), and
   3. copies the **SBL-enabled XML** into the Secure Client profile directory
      (`%ProgramData%\Cisco\Cisco Secure Client\VPN\Profile`).
   Wrap the folder into an `.intunewin` with the **Microsoft Win32 Content Prep Tool**:
   `IntuneWinAppUtil.exe -c your-source-folder -s install.cmd -o your-output-folder`
2. **Add to Intune.** Intune admin center → **Apps > Windows > Add** → App type **Windows app
   (Win32)** → upload the `.intunewin`.
3. **App information.** Name it exactly `Cisco Secure Client – Pre-Logon (SBL) – Win32`; set publisher
   = Cisco, version, and a description noting Core + Start Before Logon modules.
4. **Program.**
   - **Install command:** your `install.cmd` line that runs the Core install, then the SBL install,
     then drops the XML (silent).
   - **Uninstall command:** MSI product-code uninstall for the modules.
   - **Install behavior: System.** Device restart behavior as Cisco specifies (SBL registration may
     require a reboot to surface the PLAP option).
5. **Requirements.** OS architecture **x64**; minimum OS version per Cisco support matrix.
6. **Detection rules.** Detect that **both** the client **and the Start Before Logon component** are
   present — for example, a file-exists rule on the PLAP DLL
   `%ProgramFiles(x86)%\Cisco\Cisco Secure Client\vpnplap64.dll` (or the Cisco-documented path for your
   version), in addition to the Core client MSI product code / core binary. Detecting only Core will
   mark a device *Installed* even when SBL is missing.
7. **Assignments.** Under **Required**, add `PILOT – Pre-Logon VPN (SBL) Users` (optionally with
   `Filter – Pre-Logon VPN – Windows`). Leave production for Phase 5.
8. **Review + create.**

## 2.4 Build the Windows VPN device-configuration profile (optional, connection settings)

Use this if you deliver VPN connection settings via Intune in addition to (or instead of) the bundled
XML. Keep it consistent with the bundled SBL-enabled XML so the two never contradict.

1. Intune → **Devices > Configuration > Create > New Policy** → **Windows 10 and later** →
   **Templates > VPN**.
2. Name it exactly `Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows`.
3. **Connection type:** *Cisco AnyConnect / Cisco Secure Client*.
4. **Connection name** (what the user sees), **Servers** (the gateway FQDN from R7, mark default).
5. **Authentication:** reference the device certificate issued by
   `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows`.
6. **Split tunnel / routes** per R7.
7. **Assign** to `PILOT – Pre-Logon VPN (SBL) Users`. **Review + create.**

**Gate B (Configure):** The trusted-root profile, the **device** SCEP certificate profile, the Win32
app (installing **Core then SBL** and dropping the **SBL-enabled** XML), and the Windows VPN profile
all exist, are named to convention, and are assigned to `PILOT – Pre-Logon VPN (SBL) Users`. Re-run
`SBLVPN-Discovery.ps1` — every expected object should now be found.

---

# Phase 3 — Pilot

1. Ensure the pilot Windows devices are enrolled, compliant, and their users are members of
   `PILOT – Pre-Logon VPN (SBL) Users`.
2. Trigger a sync (Company Portal → **Sync**, or Intune → device → **Sync**) to pull the certificate
   profiles, the app, and the VPN profile.
3. Allow time for the trusted root + device certificate to land, then the Win32 app to install the
   Core and Start Before Logon modules and drop the XML. **Reboot** the device if SBL registration
   requires it so the PLAP "Network sign-in" option surfaces at the logon screen.

**Gate C (Pilot):** Every pilot device shows the certificate profiles *Succeeded*, the app *Installed*
(with the SBL detection rule satisfied), and the VPN profile *Succeeded* in Intune monitoring. If any
fail, go to `06-troubleshooting.md` before proceeding.

---

# Phase 4 — Validate

1. On a pilot device, run:
   `powershell -ExecutionPolicy Bypass -File .\scripts\SBLVPN-Validation.ps1`
   It confirms the client is installed, **Start Before Logon / PLAP is present**, the VPN profile XML
   contains `<UseStartBeforeLogon>true`, and a device certificate is present in `LocalMachine\My`.
2. Perform the decisive manual pre-logon test in `05-testing.md`: **lock or sign out**, click the
   **"Network sign-in"** (PLAP) option on the Windows logon screen, connect the Cisco Secure Client
   tunnel with the device certificate, then **log on to Windows with the tunnel already up**.
3. Run the fleet report to see pilot coverage:
   `powershell -ExecutionPolicy Bypass -File .\scripts\SBLVPN-Report.ps1`

**Gate D (Validate):** On every pilot device the client installs, SBL/PLAP is present,
`UseStartBeforeLogon` is `true`, the device certificate is issued, and the **pre-logon tunnel
establishes at the logon screen** with a successful Windows logon over it. All Testing guide pass/fail
gates are green. Only then proceed.

---

# Phase 5 — Expand

1. For the certificate profiles, the app, and the VPN profile, **add**
   `PROD – Pre-Logon VPN (SBL) Users` to the **Required** assignment. Keep
   `PILOT – Pre-Logon VPN (SBL) Users` assigned (pilot users stay covered).
2. Expand in waves if the fleet is large (e.g. add production sub-groups over several days) and watch
   the report between waves.
3. Monitor with `SBLVPN-Report.ps1` for coverage (app + profiles + certificate) and with Intune
   **Apps > Monitor** / **Devices > Configuration** for install/profile success.
4. Remediate stragglers with `SBLVPN-Remediation.ps1` (defaults to **-WhatIf** preview — review, then
   re-run with `-WhatIf:$false` to act).

**Rollback (any phase):** Remove/exclude the target group from the app, VPN profile, and certificate
assignments; to remove the installed client and the SBL/PLAP component, flip the Win32 app assignment
to **Uninstall** for the group.

**Gate E (Expand):** Fleet coverage meets your target (e.g. ≥ 95% of assigned devices with the app
*Installed* + SBL present, VPN profile *Succeeded*, and a valid device certificate); remaining failures
are triaged. Deployment is complete.


---


# Testing & Validation — Pre-Logon VPN with Cisco Secure Client Start Before Logon (SBL/PLAP) via Intune

Run these tests on the **pilot** before expanding, and spot-check during expansion. Each test has an
explicit **pass/fail gate**. A phase is only "done" when its gate is **PASS**. Object names match the
Implementation guide verbatim.

> **Scope note:** these tests validate that Intune **delivered the modules, the SBL-enabled profile,
> and the device certificate** and that a device **can bring the tunnel up at the logon screen and log
> on over it**. Deep head-end diagnostics (why a specific tunnel-group rejects a cert, ISE posture
> results) are Cisco-side and deferred to Cisco docs.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | Tenant/object readiness | Discovery script | Objects found and assigned |
| T2 | Trusted root + device cert applied | Intune monitor + device | Cert *Succeeded*, cert in `LocalMachine\My` |
| T3 | Win32 app installed — Core **and** SBL | Intune monitor + device | App *Installed*, `vpnplap64.dll` present |
| T4 | VPN profile applied / XML has SBL | Device | Profile *Succeeded*, `UseStartBeforeLogon=true` |
| T5 | PLAP option shows at logon screen | Pilot device | "Network sign-in" option visible |
| T6 | Pre-logon connect + logon over tunnel | Pilot device | Tunnel up before logon; Windows logon succeeds |
| T7 | On-device validation script | Pilot device | Script reports PASS |
| T8 | Fleet coverage report | Report script | Coverage ≥ target |
| T9 | Rollback / uninstall | Test device | App/SBL/profile/cert removed cleanly |

---

## T1 — Tenant and object readiness
**Steps:** Run `SBLVPN-Discovery.ps1`. Review the readiness table: the app
`Cisco Secure Client – Pre-Logon (SBL) – Win32`, the VPN profile
`Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows`, the trusted-root profile
`Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows`, the SCEP profile
`Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows`, and the groups, each assigned to
`PILOT – Pre-Logon VPN (SBL) Users`.
**PASS:** Every expected object is present and assigned.
**FAIL:** Any object missing/unassigned → fix in Requirements/Implementation before piloting.

## T2 — Trusted root + device certificate applied
**Steps:** Intune → **Devices > Configuration >** the two certificate profiles **> Device status**.
On the device, confirm the device certificate is in the **LocalMachine\My** store (`certlm.msc`) and
chains to the root delivered by `Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows`.
**PASS:** Both profiles *Succeeded*; a valid, unexpired **machine** certificate is present and chains
to the trusted root.
**FAIL:** *Error*/no cert / wrong store (user not machine) → see Troubleshooting §Certificate issues.

## T3 — Win32 app installed (Core **and** Start Before Logon)
**Steps:** Intune → **Apps > Monitor > App install status** for
`Cisco Secure Client – Pre-Logon (SBL) – Win32`. On the device, confirm the Secure Client is present
**and** the PLAP DLL exists (e.g. `%ProgramFiles(x86)%\Cisco\Cisco Secure Client\vpnplap64.dll`).
**PASS:** Status *Installed* and the SBL component (`vpnplap64.dll`) is present.
**FAIL:** *Failed*/*Pending*, or the client is present but `vpnplap64.dll` is missing → see
Troubleshooting §Install failures and §PLAP option not showing.

## T4 — VPN profile applied and SBL enabled in the XML
**Steps:** Confirm the VPN client profile XML is present in
`%ProgramData%\Cisco\Cisco Secure Client\VPN\Profile` and contains
`<UseStartBeforeLogon>true</UseStartBeforeLogon>`. If you also push
`Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows`, confirm it shows *Succeeded* in Intune.
**PASS:** The profile XML is present with `UseStartBeforeLogon` set to `true` (and the Intune profile,
if used, *Succeeded*).
**FAIL:** No XML, or `UseStartBeforeLogon` missing/`false` → see Troubleshooting §PLAP option not
showing.

## T5 — PLAP "Network sign-in" option shows at the logon screen
**Steps:** **Lock** the device (or sign out) to reach the Windows logon screen. Look for the
**"Network sign-in"** (PLAP) option (typically a button/link at the logon screen that launches the
Cisco Secure Client pre-logon window). A reboot after install may be required for it to appear.
**PASS:** The "Network sign-in" / PLAP option is visible at the logon screen.
**FAIL:** No option → see Troubleshooting §PLAP option not showing (module missing, wrong install
order, or `UseStartBeforeLogon` not `true`).

## T6 — Pre-logon connect + Windows logon over the tunnel (the decisive test)
**Steps:** From the logon screen, click **"Network sign-in"**, select the configured connection
(gateway FQDN from R7), and connect — the **device certificate** authenticates the tunnel with no user
signed in. With the tunnel up, **log on to Windows**. To exercise the real use case, test with a user
who has **never** signed in to this device (no cached credentials) and/or perform an **off-network
password change** that must reach a domain controller.
**PASS:** The tunnel establishes **before** logon; the Windows logon completes over the tunnel; a
first-time/no-cached-credential logon and/or off-network password change succeeds.
**FAIL:** Tunnel won't establish, or logon fails with the tunnel up → see Troubleshooting §Tunnel up
but logon fails and §Pre-logon tunnel won't connect (confirm the head-end/tunnel-group with Cisco).

## T7 — On-device validation script
**Steps:** On a pilot device run `SBLVPN-Validation.ps1`.
**PASS:** Script reports the client installed **and** SBL/PLAP present **and**
`UseStartBeforeLogon=true` → overall **PASS** (device cert also PASS if `-RequireCertificate`).
**FAIL:** Script reports a missing component → address per its message before counting the device.

## T8 — Fleet coverage report
**Steps:** Run `SBLVPN-Report.ps1`; review app install + VPN/cert profile coverage across the assigned
groups.
**PASS (pilot):** 100% of pilot devices *Installed* + profiles *Succeeded* + certificate present.
**PASS (expand):** Coverage ≥ your target (e.g. ≥ 95%) with remaining failures triaged.
**FAIL:** Coverage below target → remediate (T2/T3/T4 failures) before widening further.

## T9 — Rollback / uninstall verification
**Steps:** On a disposable test device, exclude it from the target group (or flip the Windows Win32 app
to **Uninstall**). Sync and reboot.
**PASS:** The client, the SBL/PLAP component (the "Network sign-in" option disappears), the VPN
profile, and the device certificate are removed; the device returns to its pre-deployment state.
**FAIL:** Residual client/PLAP option/profile/cert → confirm the Uninstall command and unassignment
took effect.

---

## Overall exit criteria (before Expand)
All of T1–T7 **PASS** on every pilot device (including the decisive pre-logon connect + logon test T6),
T8 shows 100% pilot coverage, and T9 confirms a clean rollback. Record results against each gate; only
then proceed to Phase 5 (Expand).


---


# Troubleshooting — Pre-Logon VPN with Cisco Secure Client Start Before Logon (SBL/PLAP) via Intune

Common failures and fixes, grouped by symptom. Object names match the Implementation guide. Work
top-down within a section — the first cause listed is the most common.

> **Vendor boundary:** problems on the **Cisco head-end** (tunnel-group rejects the cert, ISE posture
> denies access, gateway config, head-end CA trust) are **deferred to Cisco's official documentation
> and your Cisco admin**. This guide resolves the **Intune/Entra/Windows delivery** side and tells you
> when a failure points at the Cisco side.

---

## §PLAP option not showing — no "Network sign-in" at the logon screen

**Symptom:** You lock or sign out and the **"Network sign-in"** (PLAP) option never appears at the
Windows logon screen, so there is no way to bring the tunnel up before logon.

1. **`UseStartBeforeLogon` is not `true` in the deployed profile.** This is the most common cause. The
   PLAP credential provider stays dormant unless the VPN client profile XML in
   `%ProgramData%\Cisco\Cisco Secure Client\VPN\Profile` contains
   `<UseStartBeforeLogon>true</UseStartBeforeLogon>`. Confirm with `SBLVPN-Validation.ps1`; if it's
   missing or `false`, redeploy the **SBL-enabled** XML (R6) via the Win32 package.
2. **The Start Before Logon module is not installed.** The SBL module registers the PLAP DLL
   (`vpnplap64.dll`). If the client is present but `vpnplap64.dll` is missing (check
   `%ProgramFiles(x86)%\Cisco\Cisco Secure Client\vpnplap64.dll`), the Win32 package installed Core
   only. Fix the install script to install the **Start Before Logon** module and update the detection
   rule to check for the PLAP DLL on `Cisco Secure Client – Pre-Logon (SBL) – Win32`.
3. **Wrong install order (SBL before Core).** The Start Before Logon module must install **after** the
   Core VPN module. If the order was reversed, correct the `install.cmd` (Core first, then SBL) and
   redeploy.
4. **No reboot after install.** SBL/PLAP registration may require a reboot to surface at the logon
   screen. Reboot the device and re-check.
5. **PLAP credential provider not registered.** Confirm a Cisco PLAP entry exists under
   `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers`. If the module
   installed but no provider is registered, reinstall the SBL module (the client is present but the
   provider registration failed).

## §Tunnel up but logon fails — pre-logon connects yet Windows sign-in doesn't work

**Symptom:** The pre-logon tunnel establishes at the logon screen, but the subsequent Windows logon
fails (e.g. "no logon servers available", first-time logon rejected, password change won't complete).

1. **Domain controller not reachable over the tunnel.** The tunnel is up but the DC isn't routed. Check
   the profile's **tunnel mode / split-tunnel routes** (R7) — the domain controller subnets must be
   inside the tunnel. Confirm with your network team that DC subnets are reachable from the VPN pool.
2. **DNS not resolving internal names pre-logon.** The pre-logon tunnel must hand the client internal
   DNS so the DC's name resolves. Verify DNS settings pushed by the head-end (Cisco-side) and that the
   client uses them before logon.
3. **The device certificate authenticated the tunnel, but the head-end doesn't grant DC access.** ISE
   posture/authorization or the tunnel-group ACL may allow the tunnel but restrict traffic — a
   **Cisco-side** decision, deferred to Cisco docs. Capture the tunnel-group name and work it with your
   Cisco admin.
4. **Cached-credential test masks the issue.** If you tested with a user who has logged on before,
   Windows may be using cached credentials rather than the tunnel. Re-test with a **first-time / no
   cached credential** logon to truly exercise pre-logon.

## §Certificate issues — device certificate missing, wrong, or rejected

**Symptom:** `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows` fails, the pre-logon
tunnel can't authenticate, or no certificate is present at the logon screen.

1. **SCEP profile not applied / not yet delivered.** Confirm the profile shows *Succeeded* in Intune
   and the device has synced. `SBLVPN-Discovery.ps1` shows whether the profile is assigned to
   `PILOT – Pre-Logon VPN (SBL) Users`; `SBLVPN-Remediation.ps1 -FixMissingAssignments` adds a missing
   assignment.
2. **Certificate issued to the user store, not the machine store.** Pre-logon needs a **Device
   (machine)** certificate in `LocalMachine\My`. If **Certificate type** was set to *User*, the cert
   isn't available at the logon screen. Set **Certificate type = Device** on the SCEP profile (R8) and
   redeploy.
3. **Trusted root not deployed first.** The device must trust the issuing CA before the SCEP profile
   succeeds. Confirm `Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows` is *Succeeded*, then
   the SCEP profile.
4. **SCEP infrastructure error.** Check NDES / Intune Certificate Connector health and the SCEP server
   URL(s) in the profile. Re-sync after fixing.
5. **Head-end doesn't trust the issuing CA (Cisco side).** If the cert is issued correctly but the
   tunnel still rejects it, the **Cisco head-end must trust the issuing CA** — this trust config is
   **Cisco-side, deferred to Cisco docs**. Provide your Cisco admin the issuing CA chain.
6. **Certificate expired (pre-logon suddenly stopped working).** A previously working device lost
   pre-logon when its device cert expired. Confirm the **renewal threshold** (R10) precedes expiry;
   re-issue and watch cert status in `SBLVPN-Report.ps1`.

## §Install failures — the Win32 app won't install

**Symptom:** Intune shows `Cisco Secure Client – Pre-Logon (SBL) – Win32` as *Failed* or stuck
*Pending*.

1. **Device not synced / not in the group.** Confirm the device's user is a member of
   `PILOT – Pre-Logon VPN (SBL) Users` and the assignment intent is **Required**. Force a sync (Company
   Portal → **Sync**, or `SBLVPN-Remediation.ps1 -RetryFailedInstalls`).
2. **Detection rule wrong.** If detection doesn't match what the installer writes, Intune reports
   *Failed* even when the client installed — or reports *Installed* when only Core (not SBL) is present.
   Fix the detection rules (Core MSI product code **and** the PLAP DLL `vpnplap64.dll`) on the app.
3. **Install command / order / silent switches wrong.** Verify `install.cmd` installs **Core first,
   then the Start Before Logon module** silently and returns success (exit 0/3010), then drops the XML.
   Check the Intune Management Extension log
   (`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`).
4. **XML not landing in the profile directory.** If the client installs but there is no VPN profile,
   confirm the install step copies the SBL-enabled XML into
   `%ProgramData%\Cisco\Cisco Secure Client\VPN\Profile`.
5. **Architecture / OS requirement mismatch.** Confirm the app **Requirements** are x64 and the minimum
   OS matches Cisco's support matrix.

## §Profile not applying — the Intune VPN profile doesn't take

**Symptom:** `Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows` shows *Error*/*Conflict*, or
the connection entry never appears.

1. **Profile not assigned to the group.** Confirm it's assigned to `PILOT – Pre-Logon VPN (SBL) Users`.
   `SBLVPN-Discovery.ps1` flags UNASSIGNED profiles; `SBLVPN-Remediation.ps1 -FixMissingAssignments`
   adds the assignment.
2. **App not installed yet.** The profile configures the *client*; if the app isn't installed, resolve
   §Install failures first, then re-sync.
3. **Conflicting VPN profile / leftover config.** Another VPN profile (or a leftover Cisco config)
   targeting the same device can conflict. Remove/scope it so only the pre-logon profile applies.
4. **Bundled XML vs Intune profile disagree.** If you ship the SBL-enabled XML in the Win32 package
   *and* push the Intune VPN profile, keep them consistent (same gateway/behavior). Validate with
   `SBLVPN-Validation.ps1`.

## §Reporting/script issues

1. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph
   -Scope CurrentUser`) and consent to the scopes each script lists in its header. Read-only scripts
   need only `.Read.All` scopes.
2. **Objects show MISSING but exist in the portal.** The scripts match **by exact display name** —
   confirm the object is named to convention verbatim (including the en-dash `–` and spacing). Rename
   any drifted object to the convention.
3. **Validation says SBL missing but the option shows.** The script checks for `vpnplap64.dll` and the
   PLAP registration; confirm the Cisco program path for your version and, if Cisco changed it, note the
   actual path (per Cisco docs) — the logon-screen option is the ground truth.
4. **Remediation "made no changes."** By design — it defaults to **-WhatIf**. Re-run with
   `-WhatIf:$false` after reviewing the previewed actions.

---

If a failure persists after the Intune/Entra/Windows side is confirmed healthy (validation PASS,
profiles *Succeeded*, device cert issued, PLAP option showing) and the pre-logon tunnel still won't
establish or authenticate, treat it as a **Cisco head-end issue** and continue with **Cisco's official
documentation** and your Cisco admin.


---


# Best Practices — Pre-Logon VPN with Cisco Secure Client Start Before Logon (SBL/PLAP) via Intune

Field-proven practices for the assign-once, repeat-everywhere model. These make the pre-logon
deployment predictable, reversible, and easy to operate at scale.

## Naming and structure
- **Name every object to the convention and reuse it verbatim.** The app, the VPN profile, the two
  certificate profiles, the groups, and the filter all follow `Cisco Secure Client – Pre-Logon … ` /
  `PILOT – Pre-Logon VPN (SBL) Users`. The discovery, validation, report, and remediation scripts find
  objects **by these names** — drift breaks automation and reporting.
- **One app + one VPN profile + one cert chain for pre-logon.** Keep exactly one Win32 app, one VPN
  profile, one trusted-root profile, and one device-cert profile. Do not fork "test" copies in
  production; use assignment (pilot vs prod group) to stage.
- **Keep pilot and production groups separate and both assigned.** `PILOT – Pre-Logon VPN (SBL) Users`
  stays assigned after expansion so pilot members keep the build and you retain a fast test cohort.

## Get Start Before Logon actually working (the three non-negotiables)
- **Install Core first, then the Start Before Logon module.** Order matters — the SBL module layers on
  Core. Enforce the order in the Win32 install script.
- **Ship a profile with `<UseStartBeforeLogon>true</UseStartBeforeLogon>`.** The PLAP credential
  provider stays dormant unless the deployed VPN profile sets this to `true`. Bundle the SBL-enabled XML
  in the Win32 package and drop it into the Secure Client profile directory on install.
- **Detect the SBL component, not just the client.** Add a detection rule on the PLAP DLL
  (`vpnplap64.dll`) so a device missing the Start Before Logon module is reported *not installed* rather
  than a false *Installed*.
- **Reboot to surface the PLAP option** if SBL registration requires it, so testers actually see
  "Network sign-in" at the logon screen.

## Pilot-first, always
- **Never skip the pilot,** even for "simple" profile changes. Every change to the app package, the SBL
  XML, or the certificate profile goes to `PILOT – Pre-Logon VPN (SBL) Users` first and passes the
  Testing gates (including the decisive pre-logon connect + logon test) before production.
- **Test the real scenarios in the pilot.** Include a **first-time / no-cached-credential** logon and an
  **off-network password change** — the situations pre-logon exists for — not just a normal re-logon.
- **Expand in waves.** For large fleets, add production sub-groups over several days and watch
  `SBLVPN-Report.ps1` between waves rather than assigning everyone at once.

## Certificates and pre-logon authentication
- **Use a Device (machine) certificate — never a user certificate — for pre-logon.** There is no user
  context at the logon screen; only a machine cert in `LocalMachine\My` can authenticate the pre-logon
  tunnel. Deliver it via `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows`.
- **Deploy the trusted root/intermediate first,** then the device SCEP certificate, then the VPN
  profile that references the cert — order matters so the cert exists when the tunnel needs it.
- **Set a renewal threshold comfortably before expiry** (e.g. renew at 20% remaining lifetime).
  Pre-logon breaks silently the moment the cert expires — treat certificate lifecycle as a first-class,
  monitored concern, not a set-and-forget.
- **Ensure the issuing CA is trusted by the Cisco head-end** (Cisco-side trust config per Cisco docs);
  a correctly issued cert still fails if the head-end doesn't trust its chain.

## Packaging (Windows)
- **Use the vendor's signed binaries.** Do not re-sign or repackage Cisco installers; use the exact
  entitled version (Core VPN + Start Before Logon modules) your head-end supports.
- **Keep the bundled XML and any Intune VPN profile in sync.** If you ship the SBL-enabled XML in the
  Win32 package *and* push `Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows`, keep gateway and
  behavior identical so the two never contradict.
- **Set install behavior to System** and match Cisco's supported OS/architecture (x64) in Requirements.

## Change control and rollback
- **Keep a one-click rollback ready:** exclude the group, or flip the Windows Win32 app to
  **Uninstall** (which removes the SBL/PLAP component and the "Network sign-in" option). Test the
  rollback (Testing T9) before you ever need it.
- **Deploy inside a change window** and announce it — changes to the *logon experience* affect real
  users the moment they lock or reboot.
- **Version your inputs.** Track which Core/SBL module version, SBL-enabled XML, and gateway values a
  given rollout used, so you can reproduce or revert precisely.

## Operate and monitor
- **Run `SBLVPN-Report.ps1` on a schedule** (e.g. weekly) to track coverage drift and to catch an
  expiring or failed device certificate early — before it silently breaks pre-logon.
- **Remediate safely.** `SBLVPN-Remediation.ps1` defaults to **-WhatIf** — always preview the planned
  actions, then re-run with `-WhatIf:$false`. Never let a remediation run act without a preview first.
- **Least-privilege admin.** Use Intune Administrator + Groups Administrator for the operator; reserve
  Global Administrator for tenant-wide changes only.

## Security hygiene
- **Never store VPN credentials in Intune profiles.** Pre-logon uses the device certificate; where
  interactive auth is unavoidable, let the PLAP window prompt — do not embed secrets.
- **Protect the machine key.** Prefer a TPM-backed key storage provider for the device certificate so
  the private key is hardware-protected.
- **Keep the client patched.** Update the Core/SBL module package when Cisco releases fixes; pilot the
  new version (re-verify the PLAP option still appears) before fleet-wide expansion.


---


# Deliverables Summary — Pre-Logon VPN with Cisco Secure Client Start Before Logon (SBL/PLAP) via Intune

This solution is a complete, self-guided package to deploy Cisco Secure Client with **Start Before
Logon (SBL/PLAP)** to Windows devices using Microsoft Intune — so the VPN tunnel comes up **before**
Windows logon — pilot-first and rollback-ready, with the device-certificate lifecycle folded in. Below
is everything included.

## Documentation set (source/)

| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | Why pre-logon matters (first remote logon, off-network password resets, GPO/DC reachability), how SBL works (PLAP / `vpnplap64.dll`, the two required artifacts, Core-then-SBL order, `UseStartBeforeLogon=true`), how it's delivered via Intune, why a device certificate, and the Assess→Configure→Pilot→Validate→Expand model. |
| `02-requirements.md` | Every prerequisite with **Description / Why / Verify / Implement-if-missing** — Windows-only scope, Intune licensing + enrollment, Entra groups, the Cisco head-end/ISE, the **Core + Start Before Logon** installers, the **SBL-enabled** XML, the **device-cert** decision, PKI/SCEP infrastructure, and certificate renewal policy. |
| `03-implementation.md` | Exact ordered build: create groups, **deploy the trusted root then the device SCEP certificate**, package the Win32 app that installs **Core then SBL** and drops the SBL-enabled XML, build the Windows VPN profile, assign to the pilot group, validate, pilot, expand — with pass/fail **Gates A–E** and a naming table. |
| `05-testing.md` | The validation test matrix (T1–T9) with explicit **PASS/FAIL** gates, including the decisive manual test — lock/sign out, click the **"Network sign-in"** (PLAP) option, connect, then log on with the tunnel up. |
| `06-troubleshooting.md` | Failure-by-symptom fixes: PLAP option not showing, tunnel up but logon fails, certificate missing/wrong, install failures, and script/reporting issues. |
| `07-best-practices.md` | Field-proven practices for naming, the three SBL non-negotiables, pilot-first, device-certificate lifecycle, packaging, change control, and safe operation. |
| `executive-summary.md` | One-page business-outcome summary for stakeholders. |
| `global-requirements-network.md` | Category-level Network prerequisites (shared across Network solutions). |

## PowerShell scripts (scripts/)

Four of the five use the **Microsoft Graph PowerShell SDK**; the on-device validation script runs
locally with no Graph. Discovery/report are **read-only**; on-device validation is **read-only local**;
remediation and scope-targeting **default to `-WhatIf` (preview)** and change nothing until you re-run
with `-WhatIf:$false`. Each script's header documents its exact purpose, run command, and required
Graph scopes.

| Script | Purpose | Mode |
|---|---|---|
| `SBLVPN-Discovery.ps1` | Deployment-readiness sweep across Entra + Intune — the Win32 app, the Windows VPN profile, the trusted-root and SCEP device-cert profiles, and the pilot/prod groups, with assignment state. | Read-only |
| `SBLVPN-Validation.ps1` | Confirms **on this device** that the Secure Client is installed, **Start Before Logon / PLAP is present** (`vpnplap64.dll` and/or the PLAP credential-provider registration), the VPN profile XML has `<UseStartBeforeLogon>true`, and (optionally) a device certificate is in `LocalMachine\My`. Prints an overall PASS/FAIL. | Read-only (local) |
| `SBLVPN-Report.ps1` | Fleet coverage report — Win32 app install counts and VPN/cert profile apply counts (installed/failed/pending) with coverage percentages and an overall figure; optional CSV export. | Read-only |
| `SBLVPN-Remediation.ps1` | Safely fixes stragglers — retries failed installs via device sync and adds missing Required assignments to the target group. | Write, **default `-WhatIf`** |
| `SBLVPN-Set-ScopeTargeting.ps1` | Creates/populates the pilot (and optional production) Entra security groups used as assignment targets (mailNickname prefix `sblvpn-`). | Write, **default `-WhatIf`** |

## The consistent object naming convention

Every artifact is named to a convention and reused verbatim across docs, tests, troubleshooting, and
scripts (so the scripts find objects deterministically):

- Groups: `PILOT – Pre-Logon VPN (SBL) Users`, `PROD – Pre-Logon VPN (SBL) Users`
- Win32 app: `Cisco Secure Client – Pre-Logon (SBL) – Win32`
- VPN profile: `Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows`
- Trusted root CA profile: `Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows`
- SCEP device certificate profile: `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows`
- Assignment filter (optional): `Filter – Pre-Logon VPN – Windows`

## Vendor boundary (what is deferred)

The **Cisco Secure Client console, the VPN Profile Editor / XML internals (including where
`UseStartBeforeLogon` is set), head-end CA trust, and the VPN head-end (ASA / Firepower FTD / ISE)
configuration are deferred to Cisco's official documentation.** This solution authors the **Intune,
Entra, and Windows** side at full click-by-click detail and consumes the Cisco-supplied Core + Start
Before Logon modules, the SBL-enabled VPN profile XML, gateway FQDN, tunnel-group, and auth method as
inputs.
