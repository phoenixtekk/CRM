# 2. Requirements

Confirm every requirement below **before** authoring any Wi-Fi profile. Category-wide prerequisites
(Entra tenant, Intune subscription, admin roles, enrollment, pilot group, network access) live in
`global-requirements-intune-solutions.md`; this file adds the requirements **specific to Wi-Fi profile
deployment across Windows, iOS/iPadOS, and Android Enterprise**. Each entry follows the house pattern:
**Description · Why required · How to verify · How to implement if missing.**

## R1. Known Wi-Fi network facts (SSID, security type, key/EAP)

**Description:** The exact broadcast **SSID**, the **security type** (Open, WPA2/WPA3-Personal with a
pre-shared key, or WPA2/WPA3-Enterprise/802.1X), and — for Personal — the pre-shared key, or — for
Enterprise — the EAP type and RADIUS server name.
**Why required:** The profile reproduces these values exactly; a wrong SSID or key means no device
ever connects. You can't target two profiles with the **same SSID** to the same device, so you must
know the canonical SSID.
**How to verify:** Confirm with the network/wireless team, or read the SSID from a working device
(Windows: `netsh wlan show profiles`).
**How to implement if missing:** Obtain the network design document or export a working profile from a
reference device before proceeding.

## R2. Proxy decision and values (per network)

**Description:** Whether the corporate Wi-Fi uses **no proxy**, a **manual proxy** (server
**address/host + port**), or an **automatic proxy** (a **PAC-file URL**).
**Why required:** Proxy is the most error-prone Wi-Fi field. The **manual** field is an address + a
separate port (never a URL/path); the **automatic** field is a PAC URL. Choosing the wrong field, or
pasting a URL into the manual address field, breaks connectivity.
**How to verify:** Confirm the proxy model with the network team; on a working Windows device check
**Settings > Network & Internet > Proxy**.
**How to implement if missing:** Get the proxy host + port, or the PAC URL, from the network team. If
no proxy is used, set proxy to **None** deliberately.

## R3. Wi-Fi profile authoring role (Policy and Profile Manager)

**Description:** An Intune account with the **Policy and Profile Manager** built-in role (or Intune
Administrator).
**Why required:** Creating and assigning Wi-Fi configuration profiles requires this role at minimum.
**How to verify:** Intune admin center → **Tenant administration > Roles**; confirm the operator holds
**Policy and Profile Manager** or **Intune Administrator**.
**How to implement if missing:** Assign the **Policy and Profile Manager** role to the operator.

## R4. Enrolled devices on each target platform

**Description:** The Windows, iOS/iPadOS, and/or Android Enterprise devices you intend to configure are
**enrolled in Intune**, in the management modes you plan to target.
**Why required:** Wi-Fi profiles only reach enrolled, managed devices; Android options differ between
**corporate-owned** (fully managed / dedicated / COPE) and **personally-owned work profile** (BYOD).
**How to verify:** Intune → **Devices > All devices**; confirm target devices appear and are compliant.
Note each Android device's ownership/management mode.
**How to implement if missing:** Complete enrollment for each platform (Windows Autopilot / automatic
enrollment; Apple ADE or user enrollment; Android Enterprise enrollment) before assigning Wi-Fi.

## R5. Apple MDM push certificate (iOS/iPadOS)

**Description:** A valid **Apple MDM Push certificate (APNs)** connected to the tenant.
**Why required:** No Apple device configuration profile — including Wi-Fi — deploys without a valid
APNs certificate; an expired APNs silently stops all iOS/iPadOS policy.
**How to verify:** Intune → **Devices > Enrollment > Apple > Apple MDM Push certificate**; confirm it
is present and **not expired**.
**How to implement if missing:** Renew/create the APNs certificate (Apple Business Manager account is
needed for ADE, but a push certificate alone suffices for user-enrolled devices).

## R6. Managed Google Play connection (Android Enterprise)

**Description:** The tenant is connected to **managed Google Play** (Android Enterprise binding).
**Why required:** Android Enterprise Wi-Fi profiles (fully managed, dedicated, COPE, or work profile)
require the Android Enterprise connection to exist.
**How to verify:** Intune → **Devices > Enrollment > Android > Managed Google Play**; confirm status is
connected.
**How to implement if missing:** Complete the managed Google Play binding (see the companion Android
Enterprise connection solution) before authoring Android Wi-Fi profiles.

## R7. Certificate + RADIUS trust chain (ONLY if using WPA-Enterprise / 802.1X)

**Description:** If the network security type is **Enterprise (WPA2/WPA3-Enterprise, EAP-TLS/PEAP)**,
the device must already have a **client certificate profile** (SCEP or PKCS), a **trusted-root
profile** for RADIUS-server validation, and a working **RADIUS authority** (e.g. Cisco ISE).
**Why required:** An enterprise Wi-Fi profile references — it does not create — these certificate
objects. Without them the profile deploys but authentication fails.
**How to verify:** Intune → **Devices > Configuration**; confirm a trusted-root and a SCEP/PKCS cert
profile exist and are assigned to the same devices; confirm RADIUS accepts EAP for the SSID.
**How to implement if missing:** Deploy the companion **Cisco ISE 802.1X Certificate Authentication
for Wi-Fi & Wired via Intune** solution to build the PKI, certificate profiles, and ISE policy first.
For **Personal (pre-shared key)** or **Open** networks, this requirement does **not** apply — skip it.

## R8. Pilot and production assignment groups

**Description:** Two Entra security groups: `WIFIMGT - Pilot Devices` and `WIFIMGT - Production
Devices` (device groups, since Wi-Fi config is typically device-targeted).
**Why required:** Every profile is piloted before fleet rollout, then expanded — separate groups make
that safe and reversible.
**How to verify:** Entra → **Groups**; confirm both groups exist.
**How to implement if missing:** Create them (Entra → **Groups > New group > Security**), then add a
few known test devices to `WIFIMGT - Pilot Devices`.

## R9. Government cloud awareness (GCC High / DoD tenants only)

**Description:** If you operate in a **US Government** tenant, use the sovereign-cloud portals and Graph
endpoints throughout.
**Why required:** Government tenants use different admin URLs and Graph endpoints; the steps otherwise
match Commercial for Wi-Fi profiles (see the note in the Implementation guide).
**How to verify:** You sign in at `https://intune.microsoft.us` (not `.com`).
**How to implement if missing:** Substitute `intune.microsoft.us` / `graph.microsoft.us` and connect
scripts with `Connect-MgGraph -Environment USGov` (or `USGovDoD`). No Wi-Fi-profile field differs
materially; **verify for GCC High** where your tenant's feature rollout lags Commercial.
