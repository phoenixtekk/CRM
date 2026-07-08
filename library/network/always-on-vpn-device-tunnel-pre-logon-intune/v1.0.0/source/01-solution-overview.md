# Solution Overview — Windows Always On VPN — Device Tunnel Before User Logon (IKEv2, Machine-Certificate Auth) via Intune

## What this solution is

This solution deploys the **Windows Always On VPN *device tunnel*** to your managed Windows fleet using
**Microsoft Intune** — a Microsoft-native way to connect the **machine** to the corporate network at
**boot, before any user signs in**. It is the built-in Windows alternative to third-party
"Start Before Logon" (SBL) add-ons: the device authenticates with its own **machine certificate**
over **IKEv2**, so the corporate network is reachable at the Windows logon screen — enabling
first-time logon of users with **no cached credentials**, off-network **password changes**, group
policy / logon-script processing, and **domain-controller reachability** before a user is present.

The work is authored at click-by-click detail on the **Intune, Entra ID, and Windows/PKI** side. The
**VPN gateway head-end** (Windows Server **Routing and Remote Access (RRAS)** or **Azure VPN
Gateway**) is configured **per Microsoft's official documentation** — this solution tells you *what*
head-end outputs you need (gateway address/FQDN, IKEv2 settings, the root CA it trusts, the server
certificate it presents) and *where* they plug into Intune, not how to click through the head-end's
own console.

## Why a device tunnel (and what makes it different)

A normal Always On VPN **user tunnel** connects only *after* a user has signed in — which is useless
for the very problems the device tunnel solves. The **device tunnel** is a separate, machine-context
connection with a distinct, non-negotiable shape:

- **It connects at boot, before logon.** The machine is on the corporate network at the Windows logon
  screen, so a brand-new user with no cached credential can authenticate against a domain controller,
  and an off-network user can change an expired password.
- **IKEv2 is the ONLY supported protocol.** Unlike the user tunnel, the device tunnel has **no SSTP
  fallback** — if IKEv2 cannot establish, the device tunnel does not connect.
- **Authentication is a machine (computer) certificate** in the device's **Local Machine** store.
  There is no user at boot, so there is no user credential and no user certificate — the device
  proves *itself* with a certificate the head-end trusts.
- **It is configured through the VPNv2 CSP's ProfileXML**, with `<DeviceTunnel>true</DeviceTunnel>`
  and `<AlwaysOn>true</AlwaysOn>`. **Only ONE device-tunnel profile is allowed per device.**

## How the device tunnel is delivered through Intune

There is **no app to install** — the Always On VPN device tunnel is a **native Windows VPN profile**,
not a client binary. It is delivered as an **Intune *Custom* device configuration profile** that
pushes the **ProfileXML** into the VPNv2 CSP in **device (SYSTEM) context**:

1. **The machine certificate (the identity).** A **SCEP** (or PKCS) certificate profile issues a
   **device** certificate with **Client Authentication** EKU into `LocalMachine\My`, plus the
   **Trusted Root CA** profile so the device trusts the issuing CA. This is delivered first — the
   tunnel cannot authenticate without it.
2. **The ProfileXML (the configuration).** A **Custom** profile sets the OMA-URI
   `./Device/Vendor/MSFT/VPNv2/AOVPN Device Tunnel/ProfileXML` to the ProfileXML string. Because it
   is the **`./Device/`** path, the profile runs in device/SYSTEM context and **must be assigned to a
   DEVICE group**, never a user group.

The two artifacts work together: the certificate with no ProfileXML gives the device an identity but
no tunnel; the ProfileXML with no certificate gives a tunnel definition that can never authenticate.
This solution always deploys **both**, assigned to the **same DEVICE group**, so a device is either
fully ready or clearly not.

### The two ways to set the profile (this solution uses the first)

- **Custom OMA-URI ProfileXML (primary, recommended).** The full device-tunnel shape —
  `<DeviceTunnel>true</DeviceTunnel>`, `<AlwaysOn>true</AlwaysOn>`, routes, traffic filters, trusted
  network detection, and DNS (NRPT) — lives in the ProfileXML and is pushed via the Custom profile.
  This is the only way to set the **device-tunnel flag itself**, so it is the authoritative path.
- **Intune's built-in VPN template (supporting).** The **Windows 10 and later > Templates > VPN**
  profile can set **Connection type = IKEv2**, **Always On = Enable**, and **Authentication method =
  Machine certificates** — but the template does **not** expose the `DeviceTunnel` flag. Use the
  template only to understand the equivalent fields; deploy the device tunnel through the Custom
  OMA-URI ProfileXML.

## Certificate lifecycle (why it is part of this solution)

Because the device tunnel *requires* a valid machine certificate in `LocalMachine\My`, the **health
of that certificate is the health of the tunnel**. This solution folds in a dedicated **certificate
lifecycle** phase — issue the device certificate via SCEP/PKCS with the right EKU and subject/SAN,
have the head-end trust the issuing CA, present a correct server certificate on the gateway, and set
a **renewal threshold** that comfortably precedes expiry so the tunnel keeps authenticating over
time. A pre-logon tunnel that silently stops when a certificate lapses is worse than no tunnel; the
lifecycle work is what keeps it dependable.

## Object naming (used verbatim everywhere)

The names below are the exact object names you will create and reuse throughout this solution — in
the steps, the tests, the troubleshooting, and the scripts.

| Object | Name |
|---|---|
| Pilot DEVICE group | `PILOT – AOVPN Device Tunnel – Devices` |
| Production DEVICE group | `PROD – AOVPN Device Tunnel – Devices` |
| Custom OMA-URI ProfileXML profile | `AOVPN – Device Tunnel – ProfileXML – Windows` |
| VPN profile name inside the XML / OMA-URI path | `AOVPN Device Tunnel` |
| Trusted Root CA profile | `AOVPN – Device Tunnel – Trusted Root CA – Windows` |
| SCEP machine certificate profile | `AOVPN – Device Tunnel – Machine Cert (SCEP) – Windows` |
| Assignment filter (optional) | `Filter – AOVPN Device Tunnel – Windows` |

## Benefits

- **Corporate network at the logon screen.** New users with no cached credential can log on off-net;
  off-network password changes and GPO/logon-script processing work because a domain controller is
  reachable before sign-in.
- **Microsoft-native, no third-party add-on.** No SBL bolt-on — the device tunnel is built into
  Windows and delivered from the cloud through Intune.
- **Consistent and hands-off.** Every targeted device gets the *same* ProfileXML and the *same*
  machine-certificate policy — configuration drift disappears.
- **Pilot-first and rollback-ready.** The certificate profiles and the ProfileXML are assigned to a
  named pilot **device** group, validated against explicit gates, and only then expanded. Removing the
  assignment (or pushing a remove profile) is the reversal.
- **Traceable and reportable.** Every object is named to a convention, so the included scripts can
  find and check them deterministically and report fleet coverage.

## Limitations and boundaries

- **Windows-only, and only on supported SKUs/join types.** The device tunnel is supported on devices
  that are **domain-joined (or Entra hybrid-joined)** running **Windows 10/11 Enterprise or Education
  (version 1709 or later)**. (Support for pure Entra-joined device tunnels is emerging/edge —
  **verify for your build** before relying on it; do not assume it.)
- **IKEv2 only, machine-cert only, one profile.** No SSTP fallback, no user credential at boot, and
  **only one device-tunnel profile per device** — a second device tunnel is not allowed.
- **VPN gateway head-end is out of scope.** The **RRAS** or **Azure VPN Gateway** configuration —
  IKEv2 parameters, the address pool/routes it advertises, the root CA it trusts, and the server
  certificate it presents — is done **per Microsoft's official documentation**. This solution consumes
  those outputs (gateway address/FQDN, IKEv2 settings, CA trust) as inputs.
- **PKI is assumed.** Machine-certificate delivery depends on a working SCEP/PKCS path — on-prem
  **NDES + Intune Certificate Connector** or **Intune Cloud PKI** — issuing certificates the head-end
  trusts.

## The standard deployment model

This solution follows the category-standard model, with explicit pass/fail gates at each step:

**Assess → Configure → Pilot → Validate → Expand**

1. **Assess.** Confirm prerequisites (Requirements guide), gather the head-end outputs (gateway
   address/FQDN, IKEv2 settings, the CA it trusts), and confirm target devices are Enterprise/Education
   and domain-joined or hybrid-joined.
2. **Configure.** Deploy the Trusted Root CA and SCEP machine-certificate profiles, author the
   ProfileXML, build the Custom OMA-URI profile, and name every object to convention.
3. **Pilot.** Assign the certificate profiles and the ProfileXML to the named pilot device group
   `PILOT – AOVPN Device Tunnel – Devices` and let it deploy.
4. **Validate.** Reboot a pilot device and confirm — **at the logon screen, before any user signs
   in** — the device tunnel is connected and a domain controller is reachable. Pass/fail gates in the
   Testing guide.
5. **Expand.** Widen assignment to `PROD – AOVPN Device Tunnel – Devices`, monitor the coverage
   report, and keep the rollback (remove the assignment / push a remove profile) ready.

Proceed to the **Requirements guide** (`02-requirements.md`) to confirm you are ready to build.
