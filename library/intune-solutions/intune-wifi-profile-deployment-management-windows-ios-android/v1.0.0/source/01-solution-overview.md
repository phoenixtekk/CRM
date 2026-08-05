# 1. Solution Overview — Intune Wi-Fi Profile Deployment & Management (Windows, iOS & Android)

## What this solution delivers

This solution deploys and manages **Wi-Fi configuration profiles** from **Microsoft Intune** to
**Windows, iOS/iPadOS, and Android Enterprise** devices, so that every managed device connects to
your corporate wireless network **automatically, correctly, and without the user typing an SSID, a
password, or a proxy address**. You author the profile once per platform, assign it to a pilot group,
prove that devices connect, then expand to the fleet.

In plain terms: instead of walking users through "join this SSID, here's the Wi-Fi password, now set
the proxy," Intune pushes a policy that carries the network name, the security/authentication method,
and the proxy configuration to the device silently. The Wi-Fi network appears pre-configured and the
device joins it on its own.

## What a Wi-Fi profile carries

A Wi-Fi configuration profile is a small policy object. Across all three platforms it always carries
the same three decisions, and this solution deploys each one correctly per platform:

1. **The network (SSID).** The real broadcast name of the wireless network the device joins, plus a
   friendly **connection name** the user sees, and behavioral options — **connect automatically when
   in range** and whether the network is **hidden** (SSID not broadcast).
2. **The security / authentication type.** How the device proves it is allowed onto the network:
   - **Open** — no authentication (guest/unsecured networks only).
   - **Pre-shared key (WPA2/WPA3-Personal)** — one shared password/network key delivered by the
     profile. Simple; the same key goes to every targeted device.
   - **Enterprise (WPA2/WPA3-Enterprise, 802.1X/EAP)** — the device authenticates with a certificate
     or credentials against a RADIUS server. This is the strongest option.
3. **The proxy.** Whether traffic on that network goes through a web proxy: **None**, **Manual** (a
   proxy server **address/host + port**), or **Automatic** (a **PAC-file URL**).

## Where the enterprise / 802.1X-certificate path is handled

This product owns **Wi-Fi profile deployment and management at the operational level** — building,
assigning, updating, and validating Wi-Fi profiles across the three platforms. It covers the
**enterprise/802.1X security type at the deployment level**: selecting WPA2/WPA3-Enterprise, choosing
an EAP type (EAP-TLS, PEAP, EAP-TTLS), and pointing the profile at an existing client-certificate and
trusted-root profile.

It deliberately does **not** reproduce the deep certificate build. **Issuing the device
client certificate (SCEP/PKCS), delivering the trusted root, and configuring the RADIUS authority
(e.g. Cisco ISE) for EAP-TLS is a full solution of its own** — see the companion
*Cisco ISE 802.1X Certificate Authentication for Wi-Fi & Wired via Intune* product. When your network
is certificate-authenticated, deploy that solution to stand up the PKI + ISE + certificate profiles,
then use **this** solution's method to author, assign, update, and validate the Wi-Fi profiles that
reference those certificates at scale across Windows, iOS, and Android.

> **Boundary in one line:** this product = *deploy and manage the Wi-Fi profiles across all
> platforms*. The ISE product = *build the certificate + RADIUS trust chain that a WPA-Enterprise
> profile authenticates against*.

## How Intune delivers the profile per platform

All three platforms use the same Intune template family (**Templates > Wi-Fi**), but the fields and
options differ. This solution authors each platform correctly:

| Platform | Profile family | Notable specifics |
| --- | --- | --- |
| **Windows 10/11** | Templates > Wi-Fi (Basic or Enterprise) | Fields `Wi-Fi name (SSID)` + `Connection name`; `Connect automatically when in range`; `Company proxy settings`. |
| **iOS/iPadOS** | Templates > Wi-Fi (Basic or Enterprise) | Fields `Network name` + `SSID`; `Connect automatically`; `Hidden network`; proxy `Manual`/`Automatic`. |
| **Android Enterprise** | Templates > Wi-Fi (Basic or Enterprise) | Separate settings for **corporate-owned** vs **personally-owned work profile**; the work profile omits `Connect automatically` and manual proxy. |

## The proxy field — get it right (common failure)

The proxy configuration is where Wi-Fi profiles most often go wrong:

- **Manual proxy takes an address/host + a separate port number — it is NOT a URL.** You enter the
  proxy server's host or IP address in one field and the port in another. Putting a scheme or a path
  (for example `http://proxy.contoso.com/proxy.pac`) into the manual **address** field breaks it — the
  whole string is treated as a hostname and fails to resolve.
- **Automatic proxy takes a PAC-file URL** (for example `http://proxy.contoso.com/proxy.pac`). The URL
  belongs *only* in the automatic/PAC field, never in the manual address field.

This solution states, per platform, exactly which field is an address+port and which is a URL, so the
proxy applies on the first try.

## Naming model (named once, reused everywhere)

Every object this solution creates is named to a consistent convention — `WIFIMGT - <Purpose> -
<Platform> - <Stage>` — and reused verbatim in every later step, in testing, and in the scripts:

| Object (named) | What it is |
| --- | --- |
| `WIFIMGT - Pilot Devices` | Entra security group — the pilot assignment target. |
| `WIFIMGT - Production Devices` | Entra security group — the production assignment target. |
| `WIFIMGT - Corp WiFi - Windows - Pilot` | Windows Wi-Fi configuration profile. |
| `WIFIMGT - Corp WiFi - iOS - Pilot` | iOS/iPadOS Wi-Fi configuration profile. |
| `WIFIMGT - Corp WiFi - Android - Pilot` | Android Enterprise Wi-Fi configuration profile. |

## Benefits

- **Zero-touch connectivity** — devices join corporate Wi-Fi with no user setup.
- **Consistent, correct config** — the same SSID, security, and proxy settings on every device.
- **Cross-platform parity** — one repeatable method for Windows, iOS/iPadOS, and Android.
- **Safe change management** — a pilot-first, rollback-ready model for updating profiles later.

## Limitations (be honest with buyers)

- **You can't target two Wi-Fi profiles with the same SSID to the same device** — a documented Intune
  constraint; new profiles for the same network must use a distinct SSID or supersede the old one.
- **Changing the trusted root on an existing profile needs a backup internet path** on the device so
  the updated profile can be delivered (Android in particular).
- **Certificate (WPA-Enterprise/EAP-TLS) networks require the certificate + RADIUS chain first** —
  deploy the companion ISE product before the enterprise Wi-Fi profile will authenticate.
- **Profile changes take effect on the next device check-in**, not instantly — see the companion
  *"Wi-Fi changes not applying"* troubleshooting product for deep remediation.

## The standard deployment model

> **Assess → Configure → Pilot → Validate → Expand.**
>
> Confirm prerequisites and network facts → build the Wi-Fi profile on each platform → assign only to
> `WIFIMGT - Pilot Devices` → prove devices connect with the right proxy → expand to
> `WIFIMGT - Production Devices` with a documented rollback.
