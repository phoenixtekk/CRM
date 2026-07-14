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
