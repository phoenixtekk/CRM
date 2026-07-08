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
