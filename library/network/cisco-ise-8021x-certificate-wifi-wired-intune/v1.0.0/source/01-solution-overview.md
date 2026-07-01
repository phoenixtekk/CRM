# Solution Overview

## What this solution delivers

This solution makes **every managed device prove its identity with a certificate** before it is
allowed onto your Wi-Fi or a wired switch port. It does that by using **Microsoft Intune** to issue
the device certificate and to push the **Wi-Fi and wired 802.1X network profiles**, and by using
**Cisco Identity Services Engine (ISE)** as the **RADIUS authentication authority** that checks the
certificate and admits (or denies) the device. The authentication method is **EAP-TLS** — the
mutual-certificate flavor of 802.1X — which is the strongest, most phishing-resistant network
authentication method in common use.

In plain terms: pre-shared Wi-Fi keys and open switch ports are replaced by **certificate-based
network access control (NAC)**. A device that lacks a valid certificate simply cannot get on the
network.

## How 802.1X / EAP-TLS works (the moving parts)

802.1X is a three-party conversation:

1. **Supplicant** — the software on the endpoint (Windows/macOS/iOS/Android native 802.1X client)
   that presents the certificate. Intune configures the supplicant through the Wi-Fi and wired
   network profiles.
2. **Authenticator** — the network device that controls the port: a **wireless LAN controller (WLC)
   or access point** for Wi-Fi, or an **Ethernet switch** for wired. It does not decide who gets in;
   it relays credentials to the RADIUS server and enforces the verdict (open the port / VLAN, or
   keep it closed).
3. **Authentication server** — **Cisco ISE**, acting as the **RADIUS** server. ISE validates the
   presented certificate against a trusted certificate authority (CA), applies its policy, and
   returns **Access-Accept** or **Access-Reject** to the authenticator.

With **EAP-TLS**, authentication is *mutual and certificate-based*:

- The **device presents a client certificate** (issued by your CA via Intune).
- **ISE presents its own server certificate**, which the device trusts because Intune also delivered
  the **trusted root** for ISE's certificate chain.
- Both sides validate each other's certificate chain. No passwords cross the wire. There is no
  pre-shared key to steal, phish, or leak.

The same EAP-TLS mechanism secures **both** transports:

- **Wi-Fi** — the endpoint associates to a corporate SSID configured for **WPA2/WPA3-Enterprise**;
  the WLC/AP brokers the EAP-TLS exchange to ISE.
- **Wired** — the endpoint plugs into an 802.1X-enabled switch port; the switch brokers the same
  EAP-TLS exchange to ISE.

Because the credential is a certificate on the device (not a user password), this works for
**user-attended laptops and unattended/headless devices** alike.

## The certificate + network-profile model (what Intune delivers)

Intune's job is to put four things on every in-scope device, all named consistently and reused
verbatim throughout this solution:

| Object (named) | What it is | Role |
| --- | --- | --- |
| `Cisco 802.1X – Trusted Root` | Trusted-certificate profile | Installs the root/intermediate CA that signed **ISE's server certificate**, so the device trusts ISE. |
| `Cisco 802.1X – SCEP Cert` | SCEP (or PKCS) certificate profile | Enrolls the **device client certificate** used as the 802.1X (EAP-TLS) identity. |
| `Corp Wi-Fi – EAP-TLS` | Wi-Fi device-configuration profile | Configures the corporate SSID for WPA2/WPA3-Enterprise + EAP-TLS and points the supplicant at the SCEP-issued client cert. |
| `Wired 802.1X – EAP-TLS` | Wired (Ethernet) device-configuration profile | Configures the wired 802.1X supplicant for EAP-TLS using the same client cert. |

The certificate profiles and the network profiles are **linked**: the Wi-Fi and wired profiles are
told *which* certificate to present (the one from `Cisco 802.1X – SCEP Cert`) and *which* root to
trust for the server (`Cisco 802.1X – Trusted Root`). Get the linkage wrong and the supplicant has
nothing to present — the number-one cause of "profile applied but auth fails."

> **SCEP vs PKCS:** Both deliver a device client certificate. **SCEP** uses the Intune Certificate
> Connector plus a **NDES/SCEP** endpoint (or **Microsoft Cloud PKI**, which provides a managed CA +
> SCEP service with no on-prem NDES). **PKCS** uses the connector against an on-prem enterprise CA.
> This solution is written for **SCEP** (the common path, and the one Cloud PKI uses) and notes the
> PKCS equivalent where it differs. Pick one per certificate profile.

## Where Intune delivery meets Cisco switching / wireless

There is a clean division of responsibility, and this solution respects it deliberately:

- **Intune / Entra / certificate side (authored here in exact click-by-click detail):** issuing the
  client certificate, delivering the trusted root, and building + assigning the Wi-Fi and wired
  802.1X profiles to a pilot group, then expanding.
- **Cisco ISE + network-infrastructure side (architectural level + vendor-doc pointers only):**
  configuring ISE as the RADIUS authority (policy sets, certificate authentication profile,
  authorization results), and configuring the **WLC/AP** and **switches** to point at ISE as their
  RADIUS server and to enable 802.1X on the SSID / ports.

> **Vendor boundary (important):** The exact ISE console screens (policy sets, authorization
> profiles, certificate authentication profile), and the switch/WLC RADIUS and `dot1x`
> configuration, **change across versions and are deferred to Cisco's official documentation**. This
> guide tells you *what* must be true on the Cisco side and *how to verify it from the Intune/device
> side*; it does **not** fabricate ISE or IOS/AireOS menu paths. Follow Cisco's documentation for the
> named ISE/switch/WLC step and confirm the precise control in your console.

## The trust chain, end to end

For a device to authenticate successfully, this full chain must line up:

```
Your CA (on-prem AD CS or Microsoft Cloud PKI)
    │  issues
    ├── ISE server certificate  ──────────────► trusted by device via  Cisco 802.1X – Trusted Root
    └── device client certificate  ───────────► delivered by  Cisco 802.1X – SCEP Cert
                                                        │ presented over EAP-TLS by
                                        Corp Wi-Fi – EAP-TLS   /   Wired 802.1X – EAP-TLS
                                                        │ brokered by
                                              WLC / AP   or   802.1X switch  (RADIUS client)
                                                        │ validated by
                                                    Cisco ISE  (RADIUS authority)
                                                        │
                                             Access-Accept → device on the network
```

Every downstream document — requirements, implementation, testing, troubleshooting — walks this
chain in order and gates each link with a pass/fail check.

## Deployment model

This solution follows the standard staged model, with an explicit gate at each step:

**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — confirm the CA/PKI, Intune certificate connector, ISE RADIUS readiness, and Entra
  groups (see *Requirements*).
- **Configure** — build the four named Intune objects (trusted root, SCEP cert, Wi-Fi, wired).
- **Pilot** — assign only to `PILOT – 802.1X Devices` and prove the full chain on a handful of
  devices.
- **Validate** — cert present ✔, profile applied ✔, ISE 802.1X auth success ✔ (the three gates).
- **Expand** — widen assignment to the broader fleet once the pilot passes, keeping a documented
  rollback.
