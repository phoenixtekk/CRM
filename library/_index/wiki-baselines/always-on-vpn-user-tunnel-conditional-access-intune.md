# Windows Always On VPN — User Tunnel with Conditional Access (IKEv2/SSTP) via Intune

> **Version 1.0.0** · Category: Network · Solution code: AOVUT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Windows Always On VPN: User Tunnel with Conditional Access (IKEv2/SSTP) via Microsoft Intune

## The business problem
Remote workers need a VPN that just works — always on, no manual reconnecting — and access to corporate
resources over that VPN must be limited to trusted, healthy devices. Done by hand, teams end up with users
clicking "connect" every session, inconsistent tunnel settings across the fleet, split-tunnel drift, and
an always-on tunnel that is effectively always-open because nothing checks the device. The result is
help-desk load, configuration drift, and a remote-access surface that identity alone doesn't secure.

## The solution
This is a complete, self-guided package that **deploys the Windows Always On VPN user tunnel to every
enrolled Windows device through Microsoft Intune** and **gates access over it with Microsoft Entra
Conditional Access**. The tunnel auto-connects when the user signs in (IKEv2 with SSTP fallback,
authenticated by a user certificate), and Conditional Access requires a **compliant or Entra
hybrid-joined device plus MFA** before the user reaches corporate resources. It uses a disciplined
**profile-plus-certificate-plus-policy** model and a proven rollout method:
**Assess → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates and an instant rollback
(unassign / Conditional Access report-only).

## What you get
- **Step-by-step implementation** at click-by-click detail on the Intune/Entra side — the trusted root,
  the user SCEP certificate (built leanly), the VPN template profile, and the Conditional Access policy.
- **Five PowerShell scripts** — readiness discovery, on-device validation, fleet coverage reporting, safe
  remediation (preview-by-default), and pilot-group creation.
- **Requirements, testing, troubleshooting, and best-practice guides** so a competent Intune admin can
  implement it end to end and know it worked.

## Business outcomes
- **Sign in, auto-connect, stay compliant** — the tunnel comes up automatically and only compliant,
  trusted devices reach corporate resources through it.
- **Consistent remote access on every device** — the same gateway, tunnel type, trusted-network rules, and
  authentication everywhere; configuration drift eliminated.
- **Lower risk** — piloted before fleet-wide rollout, Conditional Access proven in report-only first, and
  reversible at any point, so a change never strands users.
- **Continuous assurance** — coverage reporting shows exactly who has a working tunnel and user certificate
  and who does not.

## Scope and boundary
The solution is authored at full detail on the **Microsoft Intune and Entra** side (the **user tunnel**
plus Conditional Access). The **VPN gateway / head-end (RRAS or Azure VPN Gateway)** follows **Microsoft's
official documentation**, and the **device tunnel** plus the **full certificate lifecycle** are the
**companion device-tunnel product** — this package configures the user certificate leanly and consumes the
head-end and PKI values as inputs.

## Bottom line
An always-on, compliance-gated VPN user tunnel on **every managed Windows device** — delivered from
Intune, consistent across the fleet, enforced by Conditional Access, proven on a pilot before you scale,
and a fraction of the cost and time of a hands-on consulting engagement.


---


# Solution Overview — Windows Always On VPN: User Tunnel with Conditional Access (IKEv2/SSTP) via Microsoft Intune

## What this solution is

This solution deploys the **Windows Always On VPN (AOVPN) user tunnel** — the per-user, always-on
remote-access connection that carries a signed-in user's traffic to your corporate network — to every
enrolled Windows device using **Microsoft Intune**, and **gates access over that tunnel with Microsoft
Entra Conditional Access** so corporate resources are reachable only from a compliant, trusted device.
The goal is a consistent, tested, hands-off remote-access tunnel: the right VPN profile and the right
user certificate land on each device automatically, the tunnel auto-connects when the user signs in,
and access is enforced by device compliance and identity — validated on a small pilot first, then
expanded fleet-wide with a documented rollback path.

The work is authored at click-by-click detail on the **Intune and Entra** side. The **VPN gateway /
head-end (Windows Server Routing and Remote Access Service — RRAS — or an Azure VPN Gateway) and its
IKEv2/SSTP configuration are deferred to Microsoft's official documentation** — this solution tells you
*what* the tunnel needs from the head-end and *where* those values plug into the Intune VPN profile, not
how to click through the RRAS console or the Azure VPN Gateway blades.

## User tunnel vs. device tunnel — and where this solution sits

Windows Always On VPN comes in **two tunnel types**, and they solve different problems:

- **Device tunnel** — a **machine-authenticated** tunnel that connects **before** any user signs in
  (using a **device certificate**), so domain controllers, management, and log-on traffic are reachable
  at the lock screen. It is machine-scoped and assigned to **devices**.
- **User tunnel** — a **user-authenticated** tunnel that connects **after** the user signs in (using a
  **user certificate**), carrying that user's application traffic to corporate resources. It is
  user-scoped and assigned to **users**. This is the tunnel most remote workers actually use day to day.

**This solution covers the user tunnel** — deploying it via the Intune VPN template and integrating it
with Entra **Conditional Access**. The **device tunnel**, together with the **full user/device
certificate lifecycle** (PKI design, SCEP/NDES or Cloud PKI stand-up, root/issuing-CA trust, renewal
and revocation), is the scope of the **companion device-tunnel product** — here the user certificate is
configured **leanly** and **cross-referenced** to that companion product, not re-taught from scratch.
The two tunnels are designed to coexist: many fleets run both, the device tunnel for pre-logon
reachability and the user tunnel for user traffic.

## The profile-plus-certificate-plus-policy model

A working, compliance-gated user tunnel is always **three artifacts working together**:

1. **The VPN profile (the configuration).** An **Intune VPN device-configuration profile** built from
   the **Windows 10 and later → Templates → VPN** template that tells Windows *which gateway to connect
   to, how to authenticate, and how to behave* (Always On, connection type IKEv2 with SSTP fallback,
   trusted-network detection, split-tunnel routes, DNS). Assigned to the **user** group.
2. **The user certificate (the authentication).** A **user** certificate delivered by Intune via a
   **SCEP** certificate profile into the user's personal store (`CurrentUser\My`), plus the **trusted
   root CA** the device must trust to validate the chain. The VPN profile references this certificate to
   authenticate the tunnel silently.
3. **The Conditional Access policy (the gate).** An Entra **Conditional Access** policy that requires a
   **compliant or Entra hybrid-joined device** (and MFA) before the signed-in user can reach the
   corporate cloud apps the tunnel fronts — so an always-on tunnel does not become always-open access.

None of the three is sufficient alone: the profile with no certificate cannot authenticate; the
certificate with no profile has nothing to connect; and the tunnel with no Conditional Access enforces
identity but not device trust. This solution deploys **all three**, assigned to the **same user
audience**, so a user is either fully provisioned and gated or clearly not — never half-configured.

## How the user tunnel is delivered (Intune-side view)

The exact object names below are what you will create and reuse verbatim throughout this solution.

### The VPN profile (built-in VPN template — primary path)
- **Delivery:** Intune → **Devices > Configuration > Create > New Policy > Windows 10 and later >
  Templates > VPN**. **Connection type** *Automatic* (IKEv2 with SSTP fallback) or *IKEv2*, **Always
  On = Enable**, **Authentication = user certificate (EAP)**, plus **Trusted Network Detection**,
  split-tunnel routes, and DNS. Assigned to the **user** group.
- **Profile name:** `AOVPN – User Tunnel – Profile – Windows`
- **Connection name shown to the user:** `AOVPN User Tunnel`
- **Note:** the same tunnel can also be delivered by a **ProfileXML** (custom OMA-URI) payload, but the
  **built-in VPN template is the primary, novice-friendly path** authored here.

### The user certificate and its trust
- **User SCEP certificate profile:** `AOVPN – User Tunnel – User Cert (SCEP) – Windows` — issues a
  **user** certificate into `CurrentUser\My`.
- **Trusted Root CA profile:** `AOVPN – User Tunnel – Trusted Root CA – Windows` — deploys the root/
  issuing CA so the device trusts the chain the tunnel presents. (Full PKI lifecycle is the companion
  device-tunnel product; here it is configured leanly and cross-referenced.)

### The Conditional Access gate
- **Conditional Access policy:** `CA – AOVPN User Tunnel Access` — targets the corporate cloud apps
  reached over the tunnel and requires a compliant/hybrid-joined device plus MFA.

## Supported devices and modes

- **IKEv2 and SSTP.** The user tunnel uses **IKEv2** with **SSTP as fallback** (SSTP is TCP 443, useful
  where UDP 500/4500 is blocked).
- **Join states.** Works on **domain-joined**, **Entra hybrid-joined**, and **Entra-joined** Windows 10
  and Windows 11 **Enterprise/Education** devices.
- **Authentication.** **User certificate** (SCEP/PKCS user cert in `CurrentUser\My`), commonly paired
  with Entra Conditional Access for the device-trust and MFA gate.

## Benefits

- **Sign in, auto-connect, stay compliant.** The tunnel comes up automatically for the signed-in user;
  Conditional Access ensures only compliant, trusted devices reach corporate resources through it.
- **Consistency.** Every user gets the *same* gateway, tunnel type, trusted-network rules, and auth —
  configuration drift disappears.
- **Pilot-first and rollback-ready.** The profile, certificate, and policy are assigned to a named pilot
  user group, validated against explicit gates, and only then expanded. Unassign/exclude is a one-click
  reversal (and the Conditional Access policy can be flipped to **report-only** instantly).
- **Traceable.** Every object is named to a convention, so discovery, reporting, and troubleshooting
  scripts can find and check them deterministically.
- **Reportable.** The included scripts produce fleet-wide coverage so you always know who has the VPN
  profile and user certificate and who does not.

## Limitations and boundaries

- **The VPN gateway / head-end is out of scope.** The RRAS server (or Azure VPN Gateway), its IKEv2/
  SSTP listener, certificate/EAP acceptance, IP pools, and routing are configured per **Microsoft's
  official documentation**. This solution consumes the head-end values (gateway FQDN, accepted auth,
  routes) and deploys the client side via Intune.
- **The device tunnel and full certificate lifecycle are the companion product.** Pre-logon device-tunnel
  deployment and end-to-end PKI (SCEP/NDES or Cloud PKI stand-up, issuing-CA trust, renewal/revocation)
  are covered in depth there; here the user certificate is configured leanly and cross-referenced.
- **Enrollment and PKI are prerequisites, not deliverables.** Devices must already be enrolled in Intune,
  and a working certificate path (SCEP/PKCS via NDES or Intune Cloud PKI) must exist. See the Requirements
  guide.
- **This is a single-tunnel scope.** One user tunnel, one Windows platform. Multi-platform VPN client
  deployment and the device tunnel are separate solutions.

## The standard deployment model

This solution follows the category-standard model, with explicit pass/fail gates at each step:

**Assess → Configure → Pilot → Validate → Expand**

1. **Assess.** Confirm prerequisites (Requirements guide), gather the head-end values (gateway FQDN,
   accepted auth, routes) and the PKI inputs (SCEP URL, issuing/root CA), and confirm a device
   compliance policy exists.
2. **Configure.** Build the trusted root CA profile, the user SCEP certificate profile, the VPN template
   profile, and the Conditional Access policy — naming every object to convention.
3. **Pilot.** Assign the profiles to `PILOT – AOVPN User Tunnel Users` and scope the Conditional Access
   policy to the same pilot users (start it **report-only**).
4. **Validate.** Run the validation script and the manual test matrix; a pilot user signs in, the tunnel
   auto-connects, the Conditional Access challenge behaves, and an internal resource is reachable only
   from a compliant device — pass/fail gates in the Testing guide.
5. **Expand.** Widen assignment to `PROD – AOVPN User Tunnel Users`, turn the Conditional Access policy
   **On**, monitor the coverage report, and keep the rollback (unassign / report-only) ready.

Proceed to the **Requirements guide** (`02-requirements.md`) to confirm you are ready to build.


---


# Requirements — Windows Always On VPN: User Tunnel with Conditional Access via Microsoft Intune

Confirm **every** requirement below before you build. Each entry follows the same shape:
**Description / Why required / How to verify / How to implement if missing.** The category-level
prerequisites (Entra tenant, Intune, admin roles, pilot group, change control) are in
`global-requirements-network.md`; the items here are specific to deploying the Always On VPN **user
tunnel** and its Conditional Access gate.

> **Vendor boundary:** the **VPN gateway / head-end (Windows Server RRAS or an Azure VPN Gateway) and its
> IKEv2/SSTP + EAP configuration are deferred to Microsoft's official documentation.** Below, "obtain
> from the head-end" means *get the value from your network/VPN admin or Microsoft docs* — this guide
> does not fabricate RRAS/Azure gateway menu paths.

> **Companion product boundary:** the **device tunnel** and the **full certificate lifecycle** (PKI
> design, SCEP/NDES or Cloud PKI stand-up, issuing-CA trust, renewal/revocation) are covered in depth by
> the **companion device-tunnel product**. Here the **user** certificate is configured **leanly** (R4/R5)
> and cross-referenced to that product for the full lifecycle.

---

## R1. Microsoft Intune licensing and enrolled Windows devices
**Description:** An Intune-bearing license plan (e.g. Microsoft 365 E3/E5, EMS, or Intune standalone) and
the target **Windows 10/11 Enterprise or Education** devices already enrolled and shown in Intune.
**Why required:** Intune is the delivery plane for the VPN profile and the user certificate. Nothing
deploys to a device that is not enrolled and licensed.
**How to verify:** In the **Microsoft Intune admin center** (`https://intune.microsoft.com`), go to
**Devices > All devices** and confirm the target devices are present and *Compliant/Managed*. Under
**Tenant administration > Licenses**, confirm Intune licenses are assigned to the pilot users.
**How to implement if missing:** Assign an Intune-bearing license to the pilot users (Microsoft 365
admin center → **Users** → assign licenses). Enroll devices via Autopilot / Company Portal / Entra join.

## R2. Entra ID USER security groups (pilot and production)
**Description:** A pilot **user** group `PILOT – AOVPN User Tunnel Users` and a production **user** group
`PROD – AOVPN User Tunnel Users`, containing the **users** who receive the user tunnel.
**Why required:** The **user** tunnel and the user certificate are **user-assigned**, and the Conditional
Access policy is scoped to users. The pilot-first model needs a small, named pilot user group distinct
from the eventual production audience.
**How to verify:** In the **Microsoft Entra admin center** (`https://entra.microsoft.com`), go to
**Groups > All groups** and confirm `PILOT – AOVPN User Tunnel Users` exists with the intended user
members.
**How to implement if missing:** Entra → **Groups > New group > Security**; name it exactly
`PILOT – AOVPN User Tunnel Users`; add 3–10 representative pilot **users**. The included
`AOVUT-Set-ScopeTargeting.ps1` script creates and populates these user groups for you.

## R3. A VPN gateway / head-end for the user tunnel (RRAS or Azure VPN Gateway)
**Description:** A reachable Always On VPN termination point — a Windows Server **RRAS** VPN server or an
**Azure VPN Gateway** — configured to accept the **user tunnel** over **IKEv2 (with SSTP fallback)** using
**certificate/EAP** authentication.
**Why required:** The deployed profile needs something to connect *to*. The gateway FQDN, the accepted
authentication (user cert/EAP), the IKEv2/SSTP listener, and the routes/IP pool are inputs to the Intune
VPN profile.
**How to verify:** Obtain from your network/VPN team: the **gateway public FQDN** (e.g.
`vpn.your-company.com`), confirmation that **IKEv2 and SSTP** are listening, and the **EAP/certificate**
method accepted. Confirm a test user can already connect manually to that gateway with a user cert.
**How to implement if missing:** Stand up / configure the RRAS server or Azure VPN Gateway for the user
tunnel **per Microsoft's official documentation** — this is head-end work outside this solution's scope.
Record the FQDN, auth method, and routes for R6/Implementation.

## R4. User certificate path (SCEP/PKCS) — configured leanly here
**Description:** A working certificate path for Intune to deliver a **user** certificate — an on-prem
**NDES/SCEP** connector, **Intune Cloud PKI**, or a supported third-party CA connector — and a **SCEP
(or PKCS) user certificate profile** in Intune.
**Why required:** The user tunnel authenticates with a **user** certificate in `CurrentUser\My`; Intune
must be able to issue it to each pilot user's device.
**How to verify:** Intune → **Devices > Configuration**; a user SCEP certificate profile named
`AOVPN – User Tunnel – User Cert (SCEP) – Windows` deploys successfully to a test user, and the issued
cert chains to a CA the VPN gateway trusts.
**How to implement if missing:** Stand up the SCEP/PKCS path (NDES + Intune Certificate Connector, or
enable Intune Cloud PKI). **The full certificate lifecycle — PKI design, issuing-CA trust, renewal and
revocation — is covered in depth by the companion device-tunnel product;** provision at least a basic
working SCEP path here so R5 and the VPN profile can reference a user cert.

## R5. Trusted root / issuing CA available to Intune
**Description:** The **root (and issuing) CA certificate(s)** exported so Intune can deploy them as a
**Trusted certificate** profile, and the chain the VPN gateway trusts.
**Why required:** A Windows device must **trust the CA chain** before the SCEP user certificate succeeds
and before the tunnel can validate the gateway/EAP. The trusted-root profile establishes that trust.
**How to verify:** Intune → **Devices > Configuration**; a **Trusted certificate** profile named
`AOVPN – User Tunnel – Trusted Root CA – Windows` deploys *Succeeded* to a test device, and the SCEP cert
in R4 then chains cleanly.
**How to implement if missing:** Export the root/issuing CA (`.cer`) from your PKI and create the Trusted
certificate profile (Implementation §2.1). Ensure the **VPN gateway trusts the same issuing CA** (head-end
trust config is deferred to Microsoft docs). Full PKI trust design is the companion device-tunnel product.

## R6. VPN connection parameters recorded
**Description:** A recorded set of connection values: **gateway FQDN**, **connection type** (Automatic —
IKEv2 with SSTP fallback), **authentication** (user certificate/EAP), **split-tunnel routes**, **DNS
suffix/servers**, and the **Trusted Network Detection** DNS suffix that suppresses the tunnel on the
corporate LAN.
**Why required:** These are the exact fields you type into the Intune VPN template profile. Consistency
here is what makes every user's tunnel identical.
**How to verify:** You have a single sheet listing each value; a manual client connect using those values
succeeds against the head-end.
**How to implement if missing:** Collect the values from R3/R5 and your network design. Decide split-tunnel
routes and the trusted-network DNS suffix with the network owner before building the profile.

## R7. Microsoft Entra Conditional Access available
**Description:** Conditional Access is available in the tenant (Entra ID **P1** or higher) and you can
create policies under **Entra > Protection > Conditional Access**.
**Why required:** The tunnel is gated by a Conditional Access policy (`CA – AOVPN User Tunnel Access`)
that requires a compliant/hybrid-joined device and MFA before the user reaches corporate resources.
**How to verify:** Entra admin center → **Protection > Conditional Access > Policies** loads and you can
select **New policy**.
**How to implement if missing:** Ensure Entra ID P1+ licensing is assigned to the pilot users (Conditional
Access requires it), then confirm access to the Conditional Access blade.

## R8. A device compliance policy for Windows
**Description:** An Intune **compliance policy** for Windows assigned to the pilot users/devices, so
"device is compliant" is a meaningful signal Conditional Access can require.
**Why required:** The Conditional Access grant "**Require device to be marked as compliant**" only works if
a compliance policy defines and evaluates compliance for those devices.
**How to verify:** Intune → **Devices > Compliance** shows a Windows compliance policy assigned to the
pilot audience, and pilot devices report *Compliant*.
**How to implement if missing:** Create a Windows compliance policy (Intune → **Devices > Compliance >
Create policy > Windows 10 and later**), set your baseline rules, and assign it to
`PILOT – AOVPN User Tunnel Users`.

## R9. Administrative roles for building the deployment
**Description:** Intune admin rights to create configuration/certificate profiles, Entra rights to create
Conditional Access policies (**Conditional Access Administrator** or **Security Administrator**), and
rights to create/populate groups (**Groups Administrator** or better).
**Why required:** Building VPN/cert profiles, creating the Conditional Access policy, and assigning groups
all require elevated roles.
**How to verify:** In Intune you can reach **Devices > Configuration > Create**; in Entra you can reach
**Protection > Conditional Access > New policy** and create groups.
**How to implement if missing:** Have a Global Administrator assign **Intune Administrator**,
**Conditional Access Administrator**, and **Groups Administrator** (least-privilege) to the operator.

## R10. Microsoft Graph PowerShell SDK (to run the included scripts)
**Description:** The **Microsoft.Graph** PowerShell SDK installed on the operator workstation, used by the
five discovery/validation/report/remediation/targeting scripts.
**Why required:** The scripts call Microsoft Graph (Intune/Entra) to inventory profiles, the Conditional
Access policy, assignments, and group membership.
**How to verify:** In PowerShell, `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**How to implement if missing:** Run `Install-Module Microsoft.Graph -Scope CurrentUser`. The scripts call
`Connect-MgGraph` with the specific delegated scopes each one documents in its header (the discovery script
additionally needs `Policy.Read.All` to read the Conditional Access policy).

## R11. Change control and rollback (category requirement, restated)
**Description:** An approved change window and a written rollback (unassign the profiles / set the
Conditional Access policy to **report-only**).
**Why required:** Pushing an always-on tunnel and a Conditional Access gate touches remote-access and
sign-in for real users; changes must be reversible.
**How to verify:** A rollback procedure exists and is approved; you know how to exclude
`PILOT – AOVPN User Tunnel Users` from the profiles and how to flip `CA – AOVPN User Tunnel Access` to
**Report-only**.
**How to implement if missing:** Document the rollback (profile unassignment, Conditional Access
report-only) and the comms plan before you assign anything.

> **Government (GCC / GCC High / DoD) note:** in US Government tenants the admin portals are on different
> hosts — Intune at **`https://endpoint.microsoft.us`**, Entra at **`https://entra.microsoft.us`**, and
> sign-in/Graph at **`login.microsoftonline.us`** (Graph at `graph.microsoft.us`). Substitute these
> endpoints throughout, and **verify feature parity and endpoint availability for GCC High** before you
> build — Conditional Access, certificate connectors, and VPN template options can differ or roll out
> later than in Commercial.

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


# Implementation — Windows Always On VPN: User Tunnel with Conditional Access via Microsoft Intune

This is the ordered, click-by-click build. Follow the phases in order:
**Assess → Configure → Pilot → Validate → Expand.** Do **not** skip the pilot. Use the **exact object
names** shown — later steps, tests, troubleshooting, and scripts reference them verbatim.

> **Vendor boundary:** the VPN gateway / head-end (Windows Server **RRAS** or an **Azure VPN Gateway**),
> its IKEv2/SSTP listener, and EAP/certificate acceptance are **deferred to Microsoft's official
> documentation**. This guide covers the Intune and Entra side at full detail and *consumes* the
> head-end values (gateway FQDN, accepted auth, routes) and the PKI inputs (SCEP URL, issuing/root CA)
> as inputs.

> **Companion boundary:** the **device tunnel** and the **full certificate lifecycle** are the companion
> device-tunnel product. Here the **user** certificate (§2.2) and its trusted root (§2.1) are built
> **leanly** and cross-referenced — enough to authenticate the user tunnel, not a PKI course.

## Object naming convention (use verbatim)

| Object | Name |
|---|---|
| Pilot user group | `PILOT – AOVPN User Tunnel Users` |
| Production user group | `PROD – AOVPN User Tunnel Users` |
| Trusted Root CA profile | `AOVPN – User Tunnel – Trusted Root CA – Windows` |
| User SCEP certificate profile | `AOVPN – User Tunnel – User Cert (SCEP) – Windows` |
| VPN template profile | `AOVPN – User Tunnel – Profile – Windows` |
| Connection name shown to the user | `AOVPN User Tunnel` |
| Conditional Access policy | `CA – AOVPN User Tunnel Access` |
| Assignment filter (optional) | `Filter – AOVPN User Tunnel – Windows` |

---

# Phase 1 — Assess

1. Confirm every item in `02-requirements.md` passes.
2. Gather the head-end inputs (from your network/VPN team, per Microsoft docs):
   - **Gateway FQDN** (e.g. `vpn.your-company.com`)
   - **Connection type** — *Automatic* (IKEv2 with SSTP fallback), or *IKEv2*
   - **Authentication method** — **user certificate (EAP)**
   - **Split-tunnel routes**, **DNS suffix/servers**, and the **Trusted Network Detection** DNS suffix
   - The **SCEP server URL(s)** and the **root/issuing CA** for the user certificate
3. Decide the pilot audience (3–10 users on Windows 10/11 Enterprise/Education).
4. Run the discovery script to baseline readiness:
   `powershell -ExecutionPolicy Bypass -File .\scripts\AOVUT-Discovery.ps1`
   Review its readiness table before building anything.

**Gate A (Assess):** All requirements pass, all head-end and PKI inputs recorded, discovery shows the
tenant is ready (a Windows compliance policy exists; Conditional Access is available). If not, stop and
remediate.

---

# Phase 2 — Configure

## 2.0 Create the target user groups

Use the script (recommended) or the portal.

- **Script:** `powershell -ExecutionPolicy Bypass -File .\scripts\AOVUT-Set-ScopeTargeting.ps1`
  (creates `PILOT – AOVPN User Tunnel Users` and `PROD – AOVPN User Tunnel Users` and adds the **users**
  you supply by UPN).
- **Portal:** Entra admin center → **Groups > New group > Security** → name `PILOT – AOVPN User Tunnel
  Users` → add pilot **users** → **Create**. Repeat for `PROD – AOVPN User Tunnel Users`.

## 2.1 Deploy the trusted root CA (build leanly)

The device must trust the issuing CA chain before the user certificate and the tunnel validate.

1. Intune → **Devices > Configuration > Create > New Policy**.
2. **Platform:** *Windows 10 and later*; **Profile type:** *Templates* → **Trusted certificate**.
3. Name it exactly `AOVPN – User Tunnel – Trusted Root CA – Windows`.
4. Upload the exported **root (and issuing, if separate) CA** `.cer` (from R5); set the destination store
   to **Computer certificate store – Root** (use an Intermediate profile as well if your issuing CA is
   separate).
5. **Assign** to `PILOT – AOVPN User Tunnel Users`. **Review + create.**

> Full PKI trust design (root vs. issuing, cross-signing, revocation) is the companion device-tunnel
> product; this step just establishes the trust the user tunnel needs.

## 2.2 Create the user SCEP certificate profile (build leanly)

1. Intune → **Devices > Configuration > Create > New Policy** → **Windows 10 and later** → **Templates >
   SCEP certificate** (use **PKCS certificate** instead if that is your path).
2. Name it exactly `AOVPN – User Tunnel – User Cert (SCEP) – Windows`.
3. **Certificate type:** **User**.
4. **Subject name format** and **SAN** per your head-end's matching requirements (e.g. subject = CN of the
   user, SAN = UPN).
5. **Key usage** / key size / hash per your PKI; **Extended key usage:** include **Client Authentication**.
6. **Root Certificate:** select the `AOVPN – User Tunnel – Trusted Root CA – Windows` profile from §2.1.
7. **SCEP Server URLs:** the SCEP URL(s) from R4.
8. **Assign** to `PILOT – AOVPN User Tunnel Users`. **Review + create.** (The issuing CA must be trusted
   by the VPN gateway — head-end trust config is deferred to Microsoft docs.)

## 2.3 Build the user-tunnel VPN profile (built-in VPN template)

1. Intune → **Devices > Configuration > Create > New Policy** → **Windows 10 and later** → **Templates >
   VPN**.
2. Name it exactly `AOVPN – User Tunnel – Profile – Windows`.
3. **Connection name:** `AOVPN User Tunnel` (this is what the user sees).
4. **Servers:** add the **gateway FQDN** from R6; mark it **Default**.
5. **Connection type:** *Automatic* (IKEv2 with SSTP fallback), or *IKEv2* if you require IKEv2 only.
6. **Always On:** **Enable** — this makes it a user tunnel that connects automatically when the user signs
   in. Leave *device tunnel* **off** (device tunnel is the companion product).
7. **Authentication method:** **EAP** → **user certificate**; select/point at the user certificate issued
   by `AOVPN – User Tunnel – User Cert (SCEP) – Windows` (the EAP XML references a client cert in
   `CurrentUser\My`).
8. **Trusted Network Detection:** add the corporate **DNS suffix** (from R6) so the tunnel suppresses on
   the corporate LAN.
9. **Split tunnel / routes:** add the corporate **routes** and **DNS** from R6 (enable split tunneling for
   the corporate ranges).
10. **Assign** to `PILOT – AOVPN User Tunnel Users`. Optionally attach `Filter – AOVPN User Tunnel –
    Windows` to scope by Windows edition/ownership. **Review + create.**

## 2.4 Create the Conditional Access policy (gate the tunnel)

Create the policy in **report-only** first so you can watch its impact before enforcing.

1. Entra admin center → **Protection > Conditional Access > Policies > New policy**.
2. Name it exactly `CA – AOVPN User Tunnel Access`.
3. **Users:** *Include* → **Select users and groups** → `PILOT – AOVPN User Tunnel Users`. Under
   *Exclude*, add your break-glass/emergency-access accounts.
4. **Target resources:** *Cloud apps* → **Select apps** → choose the corporate cloud app(s) reached over
   the tunnel (and, where you use it, the VPN server's Entra app). Do **not** target "All cloud apps"
   during the pilot.
5. **Conditions (optional):** scope **Device platforms** to **Windows** if you want this policy Windows-only.
6. **Grant:** **Grant access** → check **Require multifactor authentication** *and* **Require device to be
   marked as compliant** (add **Require Microsoft Entra hybrid joined device** with the **Require one of
   the selected controls** option if you support hybrid-joined). This ties access to a compliant/trusted
   device (R8).
7. **Enable policy:** **Report-only** for the pilot.
8. **Create.**

**Gate B (Configure):** The trusted-root profile, the user SCEP profile, the VPN profile (named to
convention and assigned to `PILOT – AOVPN User Tunnel Users`), and the Conditional Access policy
`CA – AOVPN User Tunnel Access` (report-only, scoped to the pilot users) all exist. Re-run
`AOVUT-Discovery.ps1` — every expected object should now be found.

---

# Phase 3 — Pilot

1. Ensure the pilot users are members of `PILOT – AOVPN User Tunnel Users`, signed in on enrolled,
   **compliant** Windows 10/11 Enterprise/Education devices.
2. Trigger a sync (Company Portal → **Sync**, or Intune → device → **Sync**) to pull the trusted root, the
   user certificate, and the VPN profile.
3. Allow time for the certificate to issue and the profile to apply (minutes). Have the pilot user **sign
   out and back in** so the user tunnel evaluates and auto-connects.
4. Confirm the connection `AOVPN User Tunnel` appears under **Settings > Network & internet > VPN** and
   shows **Connected** after sign-in.

**Gate C (Pilot):** Every pilot device shows the user SCEP cert *Succeeded*, the VPN profile *Succeeded*,
and the `AOVPN User Tunnel` connection auto-connects in Intune monitoring / on the device. If any fail, go
to `06-troubleshooting.md` before proceeding.

---

# Phase 4 — Validate

1. On a pilot device, signed in as the pilot user, run:
   `powershell -ExecutionPolicy Bypass -File .\scripts\AOVUT-Validation.ps1`
   It confirms the `AOVPN User Tunnel` VPN connection is present (Always On) and a valid **user**
   certificate is in `CurrentUser\My` on *this* device.
2. Perform the manual tests in `05-testing.md` — the tunnel auto-connects on sign-in, the Conditional
   Access challenge behaves, and an internal-only resource is reachable **only** from a compliant device.
3. Review the **Conditional Access > Insights and reporting (report-only)** workbook for
   `CA – AOVPN User Tunnel Access` to confirm it *would* grant compliant devices and block non-compliant
   ones — with no unexpected lockouts.
4. Run the fleet report to see pilot coverage:
   `powershell -ExecutionPolicy Bypass -File .\scripts\AOVUT-Report.ps1`

**Gate D (Validate):** On the pilot, the user certificate issues, the VPN profile applies, the tunnel
**auto-connects on sign-in**, an internal resource is reachable, and the report-only Conditional Access
policy shows the intended compliant-allow / non-compliant-block behavior with no false lockouts. All
Testing guide pass/fail gates are green. Only then proceed.

---

# Phase 5 — Expand

1. For the trusted-root, user SCEP, and VPN profiles, **add** `PROD – AOVPN User Tunnel Users` to the
   assignment. Keep `PILOT – AOVPN User Tunnel Users` assigned (pilot users stay covered).
2. Edit `CA – AOVPN User Tunnel Access`: add `PROD – AOVPN User Tunnel Users` to the included users, then
   switch **Enable policy** from **Report-only** to **On**. Keep the break-glass exclusion.
3. Expand in waves if the fleet is large (add production sub-groups over several days) and watch the
   report and the Conditional Access sign-in logs between waves.
4. Monitor with `AOVUT-Report.ps1` for coverage and with Intune **Devices > Configuration** for profile
   success and Entra **Sign-in logs** for Conditional Access results.
5. Remediate stragglers with `AOVUT-Remediation.ps1` (defaults to **-WhatIf** preview — review, then
   re-run with `-WhatIf:$false` to act).

**Rollback (any phase):** Remove/exclude the target group from the VPN, SCEP, and trusted-root profile
assignments; flip `CA – AOVPN User Tunnel Access` back to **Report-only** (or exclude the affected group)
to stop enforcement immediately. Unassigning the profiles removes the tunnel and user certificate.

**Gate E (Expand):** Fleet coverage meets your target (e.g. ≥ 95% of assigned users' devices with the VPN
profile *Succeeded* and a valid user cert), the Conditional Access policy is **On** with no unexpected
lockouts, and remaining failures are triaged. Deployment is complete.


---


# Testing & Validation — Windows Always On VPN: User Tunnel with Conditional Access via Intune

Run these tests on the **pilot** before expanding, and spot-check during expansion. Each test has an
explicit **pass/fail gate**. A phase is only "done" when its gate is **PASS**. Object names match the
Implementation guide verbatim.

> **Scope note:** these tests validate that Intune **delivered the user certificate and the VPN profile**,
> that the tunnel **auto-connects on sign-in**, and that **Conditional Access gates access** as intended.
> Deep head-end diagnostics (why the RRAS/Azure gateway rejects an EAP handshake) are Microsoft-side and
> deferred to Microsoft docs.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | Tenant readiness | Discovery script | Objects found; CA policy present |
| T2 | User certificate issued | Intune monitor + device | SCEP cert *Succeeded*, in `CurrentUser\My` |
| T3 | VPN profile applied | Intune monitor + device | Profile *Succeeded*; `AOVPN User Tunnel` present |
| T4 | Auto-connect on sign-in | Pilot device | Tunnel *Connected* after sign-in |
| T5 | Internal resource over tunnel | Pilot device | Internal-only resource reachable |
| T6 | Conditional Access behaves | Entra report-only / sign-in logs | Compliant allowed, non-compliant blocked |
| T7 | On-device validation script | Pilot device | Script reports PASS |
| T8 | Fleet coverage report | Report script | Coverage ≥ target |
| T9 | Rollback / report-only | Test device + CA policy | Profiles removed; CA reverts cleanly |

---

## T1 — Tenant and object readiness
**Steps:** Run `AOVUT-Discovery.ps1`. Review the readiness table: the trusted-root profile, the user SCEP
profile, the VPN profile, the Conditional Access policy `CA – AOVPN User Tunnel Access`, and the
pilot/prod user groups — each present and (profiles) assigned to `PILOT – AOVPN User Tunnel Users`.
**PASS:** Every expected object is present, profiles are assigned, and the Conditional Access policy is
found.
**FAIL:** Any expected object missing/unassigned → fix in Requirements/Implementation before piloting.

## T2 — User certificate issued
**Steps:** Intune → **Devices > Configuration >** `AOVPN – User Tunnel – User Cert (SCEP) – Windows` **>
Device status**. On the device, open **certmgr.msc** (Current User) → **Personal > Certificates** and
confirm a valid user certificate with **Client Authentication** EKU.
**PASS:** Profile status *Succeeded* and a non-expired user cert chains to the trusted root in
`CurrentUser\My`.
**FAIL:** *Error* / no cert / broken chain → see Troubleshooting §Certificate issues.

## T3 — VPN profile applied
**Steps:** Intune → **Devices > Configuration >** `AOVPN – User Tunnel – Profile – Windows` **> Device
status**. On the device, open **Settings > Network & internet > VPN** and confirm `AOVPN User Tunnel`
appears.
**PASS:** Profile status *Succeeded* and the `AOVPN User Tunnel` connection is present with the correct
gateway FQDN.
**FAIL:** *Error* / *Conflict* or no connection entry → see Troubleshooting §Profile not applying.

## T4 — Auto-connect on sign-in (the decisive delivery test)
**Steps:** Have the pilot user **sign out and back in** on the pilot device. Watch the `AOVPN User Tunnel`
connection under **Settings > Network & internet > VPN** (or run `Get-VpnConnection -AllUserConnection`).
**PASS:** The tunnel reaches **Connected** automatically shortly after sign-in, with no manual click
(Always On working).
**FAIL:** Stays *Disconnected* / requires manual connect → see Troubleshooting §Tunnel not auto-connecting.

## T5 — Internal resource over the tunnel
**Steps:** With the tunnel connected, reach an **internal-only** resource (internal URL, file share, or
ping an internal host) that is *not* reachable without the VPN.
**PASS:** The internal resource is reachable while connected; disconnecting (off the corporate LAN) makes
it unreachable again.
**FAIL:** Resource unreachable while connected → check split-tunnel routes/DNS in the profile (R6); if
routing is correct but traffic never arrives, confirm the head-end with your network admin.

## T6 — Conditional Access behaves
**Steps:** Review **Protection > Conditional Access > Insights and reporting** (report-only) for
`CA – AOVPN User Tunnel Access`. Sign in as the pilot user from a **compliant** device and from a
**non-compliant** device (or simulate) against the targeted cloud app.
**PASS:** Report-only shows the policy **would grant** access from a compliant/hybrid-joined device (with
MFA satisfied) and **would block** a non-compliant device — with **no unexpected lockouts** of legitimate
users.
**FAIL:** Legit compliant users would be blocked, or non-compliant devices would be allowed → adjust the
policy scope/grant (Implementation §2.4) before turning it **On**.

## T7 — On-device validation script
**Steps:** On a pilot device, signed in as the pilot user, run `AOVUT-Validation.ps1`.
**PASS:** Script reports the `AOVPN User Tunnel` VPN connection present **and** a valid user cert in
`CurrentUser\My` → overall **PASS**.
**FAIL:** Script reports a missing component → address per its message before counting the device.

## T8 — Fleet coverage report
**Steps:** Run `AOVUT-Report.ps1`; review VPN profile + user-cert profile apply coverage across the
assigned groups.
**PASS (pilot):** 100% of pilot devices with the VPN profile *Succeeded* and the user cert *Succeeded*.
**PASS (expand):** Coverage ≥ your target (e.g. ≥ 95%) with remaining failures triaged.
**FAIL:** Coverage below target → remediate (T2/T3 failures) before widening further.

## T9 — Rollback / report-only verification
**Steps:** On a disposable test device, exclude it from `PILOT – AOVPN User Tunnel Users` (removing the
profiles). Separately, flip `CA – AOVPN User Tunnel Access` to **Report-only**. Sync.
**PASS:** The VPN profile and user certificate are removed from the test device; the Conditional Access
policy stops enforcing immediately when set to report-only.
**FAIL:** Residual tunnel/cert or policy still enforcing → confirm the unassignment and the policy state
took effect.

---

## Overall exit criteria (before Expand)
All of T1–T7 **PASS** on the pilot, T8 shows 100% pilot coverage, and T9 confirms a clean rollback and a
working report-only toggle. Record results against each gate; only then proceed to Phase 5 (Expand) and
turn the Conditional Access policy **On**.


---


# Troubleshooting — Windows Always On VPN: User Tunnel with Conditional Access via Intune

Common failures and fixes, grouped by symptom. Object names match the Implementation guide. Work
top-down within a section — the first cause listed is the most common.

> **Vendor boundary:** problems on the **VPN gateway / head-end** (RRAS or Azure VPN Gateway rejects the
> EAP handshake, IP pool exhausted, routing/NAT) are **deferred to Microsoft's official documentation and
> your network admin**. This guide resolves the **Intune/Entra delivery + Conditional Access** side and
> tells you when a failure points at the head-end.

> **Companion boundary:** deep certificate-lifecycle problems (issuing-CA design, NDES/Cloud PKI health,
> revocation) are covered by the companion device-tunnel product; this section resolves the **user
> certificate delivery** needed for the tunnel.

---

## §Tunnel not auto-connecting — profile present but no automatic connection

**Symptom:** `AOVPN User Tunnel` appears under **Settings > Network & internet > VPN** but stays
*Disconnected* until the user clicks Connect (or never connects).

1. **Always On not enabled.** The most common cause. Confirm the VPN profile
   `AOVPN – User Tunnel – Profile – Windows` has **Always On = Enable**. Re-save and re-sync; have the
   user sign out and back in so the tunnel re-evaluates.
2. **Trusted Network Detection matches the current network.** If the **Trusted Network Detection** DNS
   suffix (R6) matches the network the device is on, Windows **intentionally suppresses** the tunnel
   (you're "already inside"). Test from an external network, or confirm the suffix is your *corporate*
   suffix, not the current one.
3. **User certificate missing / not selected.** Auto-connect needs a valid **user** cert in
   `CurrentUser\My`. Run `AOVUT-Validation.ps1`; if the cert is missing, resolve §Certificate issues.
4. **Signed in with the wrong user / cert not for this user.** The user tunnel is per-user; confirm the
   signed-in user is a member of `PILOT – AOVPN User Tunnel Users` and holds the user cert.
5. **EAP configuration mismatch.** If the profile's EAP/authentication doesn't match what the head-end
   expects, the tunnel starts and drops. Confirm the connection type (Automatic/IKEv2) and EAP-cert
   settings against R6; if the handshake reaches the gateway and fails there, it's a **head-end** issue
   (deferred to Microsoft docs).

## §Profile not applying — the VPN profile doesn't show up

**Symptom:** `AOVPN – User Tunnel – Profile – Windows` shows *Error*/*Conflict*, or the `AOVPN User
Tunnel` connection never appears on the device.

1. **Profile not assigned to the user group.** Confirm the profile is assigned to `PILOT – AOVPN User
   Tunnel Users`. `AOVUT-Discovery.ps1` flags UNASSIGNED profiles; `AOVUT-Remediation.ps1
   -FixMissingAssignments` adds the assignment.
2. **Assigned to a device group instead of a user group.** The **user** tunnel must be **user-assigned**.
   If you targeted a device group, the profile may not materialize for the user tunnel — reassign to the
   user group.
3. **Conflicting VPN profile.** Another VPN profile (or a leftover AOVPN config) on the device can
   conflict. Remove/scope the conflicting profile so only `AOVPN – User Tunnel – Profile – Windows`
   applies.
4. **Wrong platform / template.** Ensure the profile is **Windows 10 and later → Templates → VPN** and
   the device is Windows 10/11 Enterprise/Education.

## §Certificate issues — the user certificate won't issue or the tunnel rejects it

**Symptom:** `AOVPN – User Tunnel – User Cert (SCEP) – Windows` fails, or the tunnel rejects the cert.

1. **Trusted root not deployed first.** The device must trust the issuing CA before the SCEP profile
   succeeds. Confirm `AOVPN – User Tunnel – Trusted Root CA – Windows` shows *Succeeded*, then re-sync the
   SCEP profile.
2. **Certificate type not User.** The user tunnel needs a **User** certificate. Confirm the SCEP profile's
   **Certificate type = User** (not Device).
3. **SCEP infrastructure error.** Check the NDES/Intune Certificate Connector (or Cloud PKI) health and
   the SCEP server URL(s) in the profile. (Full PKI health is the companion device-tunnel product.)
4. **Subject/SAN mismatch.** If the head-end matches on subject/SAN, ensure the SCEP profile's
   subject-name format and SAN produce what the head-end expects (e.g. SAN = UPN).
5. **Missing Client Authentication EKU.** The cert must include the **Client Authentication** EKU for EAP;
   add it to the SCEP profile and re-issue.
6. **Head-end doesn't trust the issuing CA (Microsoft side).** If the cert is issued correctly but the
   tunnel still rejects it, the **VPN gateway must trust the issuing CA** — head-end trust config is
   **deferred to Microsoft docs**. Provide your network admin the issuing CA chain.

## §Conditional Access blocking legitimate users

**Symptom:** Pilot users on compliant devices are blocked from the corporate app the tunnel fronts, or see
repeated MFA/compliance prompts.

1. **Policy scope too broad.** Confirm `CA – AOVPN User Tunnel Access` targets the **specific** cloud
   app(s) — not "All cloud apps" — and only `PILOT – AOVPN User Tunnel Users` during the pilot.
2. **Device not actually compliant.** The grant **Require device to be marked as compliant** needs a
   compliance policy (R8) that the device passes. Check Intune → **Devices > Compliance**; a device that
   isn't evaluated compliant will be blocked. Fix compliance or add **hybrid joined** as an alternative
   grant.
3. **Grant requires controls the device can't meet.** If you require compliant **AND** hybrid-joined on an
   Entra-joined (not hybrid) device, it fails. Use **Require one of the selected controls** so either
   satisfies.
4. **Enforced before validation.** Always run the policy **Report-only** first (Implementation §2.4) and
   review the Insights workbook; only turn it **On** after T6 passes. To stop enforcement instantly, flip
   it back to **Report-only**.
5. **Break-glass excluded?** Confirm your emergency-access accounts are in the policy's **Exclude** list so
   a misconfiguration can never lock everyone out.

## §SSTP used instead of IKEv2

**Symptom:** The tunnel connects but over **SSTP** (TCP 443) rather than the preferred **IKEv2**.

1. **UDP 500/4500 blocked on the path.** IKEv2 needs **UDP 500 and 4500**; if a firewall/NAT on the
   client's network blocks them, Windows falls back to **SSTP** (this is by design when connection type is
   *Automatic*). Allow UDP 500/4500 end to end to prefer IKEv2, or accept SSTP fallback where that's not
   possible.
2. **Connection type is Automatic (expected fallback).** With *Automatic*, SSTP fallback is intended
   behavior. If you require IKEv2 only, set the profile's connection type to **IKEv2** — but then clients
   on UDP-blocked networks won't connect at all.
3. **Head-end SSTP/IKEv2 listener config.** Which protocols the gateway offers is a **head-end** setting
   (deferred to Microsoft docs); confirm both IKEv2 and SSTP are configured if you want fallback.

## §Reporting/script issues

1. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph -Scope
   CurrentUser`) and consent to the scopes each script lists in its header. Reading the Conditional Access
   policy needs `Policy.Read.All`; read-only inventory needs only `.Read.All` scopes.
2. **Objects show MISSING but exist in the portal.** The scripts match **by exact display name** — confirm
   the object is named to convention verbatim (including the en-dash `–` and spacing). Rename any drifted
   object to the convention.
3. **Remediation "made no changes."** By design — it defaults to **-WhatIf**. Re-run with `-WhatIf:$false`
   after reviewing the previewed actions.

---

If the tunnel still won't establish after the Intune/Entra side is confirmed healthy (validation PASS,
profile *Succeeded*, user cert issued and chaining) and the handshake reaches the gateway and fails there,
treat it as a **VPN gateway / head-end issue** and continue with **Microsoft's official documentation**
and your network admin.


---


# Best Practices — Windows Always On VPN: User Tunnel with Conditional Access via Intune

Field-proven practices for the assign-once, repeat-everywhere model. These make the user tunnel
predictable, reversible, and easy to operate at scale.

## Naming and structure
- **Name every object to the convention and reuse it verbatim.** The VPN profile, the user SCEP and
  trusted-root profiles, the Conditional Access policy, and the groups all follow
  `AOVPN – User Tunnel – …` / `PILOT – AOVPN User Tunnel Users` / `CA – AOVPN User Tunnel Access`. The
  discovery, validation, report, and remediation scripts find objects **by these names** — drift breaks
  automation and reporting.
- **One user tunnel, one profile.** Keep exactly one VPN profile for the user tunnel. Do not fork "test"
  copies in production; use assignment (pilot vs prod user group) to stage.
- **Keep pilot and production user groups separate and both assigned.** `PILOT – AOVPN User Tunnel Users`
  stays assigned after expansion so pilot members keep the tunnel and you retain a fast test cohort.

## User tunnel vs. device tunnel
- **Assign the user tunnel to USERS, not devices.** It is a per-user, post-sign-in tunnel authenticated by
  a **user** certificate — user-targeted assignment is what makes it behave correctly.
- **Run the device tunnel alongside it where you need pre-logon reachability** — that (and the full
  certificate lifecycle) is the **companion device-tunnel product**. The two coexist by design: device
  tunnel before sign-in, user tunnel after.

## Pilot-first, always
- **Never skip the pilot,** even for "simple" profile or policy changes. Every change to the VPN profile,
  the certificate profile, or the Conditional Access policy goes to `PILOT – AOVPN User Tunnel Users`
  first and passes the Testing gates before production.
- **Start Conditional Access in report-only.** Create `CA – AOVPN User Tunnel Access` **report-only**,
  review the Insights workbook, and only turn it **On** after T6 passes. Report-only is also your instant
  rollback.
- **Expand in waves.** For large fleets, add production sub-groups over several days and watch
  `AOVUT-Report.ps1` and the Entra sign-in logs between waves.

## Authentication and certificates (lean, cross-referenced)
- **Use a user certificate for silent auth.** Deliver it via `AOVPN – User Tunnel – User Cert (SCEP) –
  Windows` with the **Client Authentication** EKU, and ensure the **issuing CA is trusted by the VPN
  gateway** (head-end trust config per Microsoft docs).
- **Deploy the trusted root first,** then the user SCEP profile, then the VPN profile that references the
  cert — order matters so the cert exists and chains when the tunnel needs it.
- **Defer full PKI lifecycle to the companion device-tunnel product.** Issuing-CA design, NDES/Cloud PKI
  health, renewal thresholds, and revocation are handled there — here, keep the user-cert config minimal
  and correct.

## Trusted network detection and split tunnel
- **Set Trusted Network Detection to your corporate DNS suffix** so the tunnel suppresses on the corporate
  LAN and only comes up off-network — this avoids "tunnel inside the tunnel" and needless load.
- **Scope split-tunnel routes deliberately.** Route only the corporate ranges through the tunnel; full
  tunneling hurts performance and privacy unless a policy requires it.

## Conditional Access
- **Gate on device compliance, not just identity.** Pair **Require MFA** with **Require device to be
  marked as compliant** (or hybrid-joined) so an always-on tunnel is never always-open access.
- **Target specific cloud apps** the tunnel fronts — not "All cloud apps" — so the policy's blast radius
  is understood.
- **Always exclude break-glass accounts** from the policy so a misconfiguration can't lock everyone out.

## Change control and rollback
- **Keep a one-click rollback ready:** unassign the profiles from the group, and flip
  `CA – AOVPN User Tunnel Access` to **Report-only**. Test the rollback (Testing T9) before you ever need it.
- **Deploy inside a change window** and announce it — remote-access and sign-in changes affect real users.
- **Version your inputs.** Track which gateway FQDN, routes, SCEP settings, and CA grant a given rollout
  used, so you can reproduce or revert precisely.

## Operate and monitor
- **Run `AOVUT-Report.ps1` on a schedule** (e.g. weekly) to track coverage drift as users/devices come and
  go, and to catch profile *Error* states early.
- **Watch the Entra sign-in logs** for `CA – AOVPN User Tunnel Access` results after you enforce, to catch
  unexpected blocks quickly.
- **Remediate safely.** `AOVUT-Remediation.ps1` defaults to **-WhatIf** — always preview the planned
  actions, then re-run with `-WhatIf:$false`. Never let a remediation run act without a preview first.
- **Least-privilege admin.** Use Intune Administrator + Conditional Access Administrator + Groups
  Administrator for the operator; reserve Global Administrator for tenant-wide changes only.

## Security hygiene
- **Never store VPN credentials in the profile.** Use the user certificate for authentication — do not
  embed secrets.
- **Keep the compliance policy meaningful.** The Conditional Access device-compliance grant is only as
  strong as the compliance policy behind it (R8); keep its rules current.


---


# Deliverables Summary — Windows Always On VPN: User Tunnel with Conditional Access via Intune

This solution is a complete, self-guided package to deploy the Windows Always On VPN **user tunnel** to
enrolled Windows devices via Microsoft Intune and gate it with Entra **Conditional Access** —
pilot-first and rollback-ready. Below is everything included.

## Documentation set (source/)

| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | User tunnel vs. device tunnel, the profile-plus-certificate-plus-policy model, IKEv2/SSTP + Always On, where this fits vs. the companion device-tunnel product, and the Assess→Configure→Pilot→Validate→Expand model. |
| `02-requirements.md` | Every prerequisite with **Description / Why / Verify / Implement-if-missing** — Intune licensing + enrolled Windows devices, Entra user groups, a VPN head-end (RRAS/Azure VPN Gateway), a lean user-cert SCEP path + trusted root, Conditional Access availability, and a device compliance policy. |
| `03-implementation.md` | Exact ordered build: trusted root → user SCEP cert → the VPN template profile → the Conditional Access policy, assigned to the named pilot user group, then validate, pilot, expand — with pass/fail gates and a naming table. |
| `05-testing.md` | The validation test matrix (T1–T9) with explicit **PASS/FAIL** gates, including auto-connect-on-sign-in and the Conditional Access report-only check. |
| `06-troubleshooting.md` | Failure-by-symptom fixes: tunnel not auto-connecting, profile not applying, certificate issues, Conditional Access blocking legit users, SSTP-vs-IKEv2, and script/reporting issues. |
| `07-best-practices.md` | Field-proven practices for naming, user-vs-device tunnel, pilot-first, certificates (lean), trusted-network/split-tunnel, Conditional Access, change control, and safe operation. |
| `executive-summary.md` | One-page business-outcome summary for stakeholders. |
| `global-requirements-network.md` | Category-level Network prerequisites (shared across Network solutions). |

## PowerShell scripts (scripts/)

All five use the **Microsoft Graph PowerShell SDK** (validation runs locally, no Graph). Discovery/
validation/report are **read-only**; remediation and scope-targeting **default to `-WhatIf` (preview)**
and change nothing until you re-run with `-WhatIf:$false`. Each script's header documents its exact
purpose, run command, and required Graph scopes.

| Script | Purpose | Mode |
|---|---|---|
| `AOVUT-Discovery.ps1` | Deployment-readiness sweep across Entra + Intune — the trusted-root, user SCEP, and VPN profiles, the Conditional Access policy `CA – AOVPN User Tunnel Access`, and the pilot/prod user groups, with assignment state. | Read-only |
| `AOVUT-Validation.ps1` | Confirms **on this device** that the `AOVPN User Tunnel` VPN connection is present (Always On) and a valid **user** certificate is in `CurrentUser\My`. Prints an overall PASS/FAIL. | Read-only (local) |
| `AOVUT-Report.ps1` | Fleet coverage report — per-profile apply counts (succeeded/failed/pending) for the VPN and user-cert profiles, with coverage percentages and an overall figure; optional CSV export. | Read-only |
| `AOVUT-Remediation.ps1` | Safely fixes stragglers — retries errored devices via sync and adds missing Required assignments to the user target group. | Write, **default `-WhatIf`** |
| `AOVUT-Set-ScopeTargeting.ps1` | Creates/populates the pilot (and optional production) Entra **user** security groups used as assignment targets. | Write, **default `-WhatIf`** |

## The consistent object naming convention

Every artifact is named to a convention and reused verbatim across docs, tests, troubleshooting, and
scripts (so the scripts find objects deterministically):

- User groups: `PILOT – AOVPN User Tunnel Users`, `PROD – AOVPN User Tunnel Users`
- Trusted root profile: `AOVPN – User Tunnel – Trusted Root CA – Windows`
- User SCEP profile: `AOVPN – User Tunnel – User Cert (SCEP) – Windows`
- VPN template profile: `AOVPN – User Tunnel – Profile – Windows` (connection name: `AOVPN User Tunnel`)
- Conditional Access policy: `CA – AOVPN User Tunnel Access`

## Vendor and companion boundaries (what is deferred)

The **VPN gateway / head-end (Windows Server RRAS or an Azure VPN Gateway) and its IKEv2/SSTP + EAP
configuration are deferred to Microsoft's official documentation.** The **device tunnel** and the **full
certificate lifecycle** (PKI design, SCEP/NDES or Cloud PKI stand-up, issuing-CA trust, renewal/revocation)
are covered in depth by the **companion device-tunnel product**. This solution authors the **Intune and
Entra** user-tunnel + Conditional Access side at full click-by-click detail and consumes the head-end
values (gateway FQDN, accepted auth, routes) and PKI inputs (SCEP URL, issuing/root CA) as inputs.
