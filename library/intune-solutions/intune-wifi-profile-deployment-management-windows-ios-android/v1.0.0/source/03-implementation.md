# 3. Implementation

Follow these steps in order. You will create two assignment groups, then author one Wi-Fi profile per
platform (Windows, then iOS/iPadOS, then Android Enterprise), assign each to the pilot group, and later
expand to production. Every object is named exactly as shown and the name is reused verbatim later.

All navigation is for the **Microsoft Intune admin center** (`https://intune.microsoft.com`).
**US Government tenants:** use `https://intune.microsoft.us` instead — every menu path below is
identical; only the host differs (see Step 0 note).

> **Step 0 — Government cloud note.** In a GCC High / DoD tenant, sign in at `intune.microsoft.us`;
> the scripts connect with `Connect-MgGraph -Environment USGov` (or `USGovDoD`). No Wi-Fi-profile field
> below changes for Government. Where your tenant's feature rollout lags Commercial, **verify for GCC
> High**.

---

## Phase 1 — Create the assignment groups

### Step 1. Create the pilot group

1. Go to `https://entra.microsoft.com` and sign in as an administrator.
2. Select **Groups** > **All groups** > **New group**.
3. Set **Group type** = **Security**.
4. **Group name**: enter `WIFIMGT - Pilot Devices`.
5. **Membership type**: **Assigned**.
6. Select **No members selected** > add 3–5 known test devices (one Windows, one iOS/iPadOS, one
   Android where possible) > **Select**.
7. Select **Create**.

### Step 2. Create the production group

1. Still in **Groups** > **All groups** > **New group**.
2. **Group type** = **Security**; **Group name** = `WIFIMGT - Production Devices`;
   **Membership type** = **Assigned** (or Dynamic, per your fleet convention).
3. Select **Create**. Leave it empty for now — you populate it at expansion (Phase 5).

---

## Phase 2 — Author the Windows Wi-Fi profile

### Step 3. Start the Windows profile

1. In the Intune admin center, select **Devices** > **Manage devices** > **Configuration** >
   **Create** > **New policy**.
2. **Platform**: select **Windows 10 and later**.
3. **Profile type**: select **Templates**, then choose **Wi-Fi** > **Create**.

### Step 4. Name the Windows profile

1. On the **Basics** tab, **Name**: enter `WIFIMGT - Corp WiFi - Windows - Pilot`.
2. **Description**: enter `Corporate Wi-Fi for Windows devices — pilot ring.`
3. Select **Next**.

### Step 5. Configure the Windows Wi-Fi settings

On the **Configuration settings** tab:

1. **Wi-Fi type**:
   - For a pre-shared-key network, select **Basic**.
   - For a certificate/802.1X network, select **Enterprise** (see Step 6).
2. **Wi-Fi name (SSID)**: enter the real broadcast SSID exactly, e.g. `Contoso-Corp`.
3. **Connection name**: enter the friendly name users see, e.g. `Contoso Corp Wi-Fi`.
4. **Connect automatically when in range**: **Yes**.
   - **Connect to more preferred network if available**: **No** (keep devices on the corporate SSID).
   - **Connect to this network, even when it is not broadcasting its SSID**: set **Yes** only if the
     SSID is hidden; otherwise **No**.
5. **Wireless Security Type** (Basic):
   - **Open (no authentication)** — guest/unsecured networks only, or
   - **WPA/WPA2-Personal** — then enter the **Pre-shared key** (an 8–63 character ASCII string or 64
     hex characters). The PSK is identical on every targeted device — keep it secure.
6. **Company proxy settings** — choose one and enter values in the correct field:
   - **None** — no proxy.
   - **Manually configure** — enter the **Proxy server IP address** (host/IP only, no scheme, no path)
     and its **Port number** (e.g. address `10.0.0.22`, port `8080`).
   - **Automatically configure** — enter the **PAC-file URL**, e.g. `http://proxy.contoso.com/proxy.pac`.
     (This is the only proxy field that takes a URL.)
7. Select **Next**.

### Step 6. (Enterprise/802.1X networks only) Windows Enterprise settings

If you chose **Enterprise** in Step 5, also configure:

1. **Authentication mode**: **User or machine** (typical), or **Machine** for unattended devices.
2. **EAP type**: select **EAP-TLS** for certificate authentication (recommended). PEAP and EAP-TTLS
   are also available for credential-based auth.
3. For **EAP-TLS**:
   - **Certificate server names**: enter the RADIUS server certificate common name(s).
   - **Root certificates for server validation**: select the existing **trusted-root** profile.
   - **Authentication method**: select **SCEP certificate** (or **PKCS certificate**) and choose the
     existing client-certificate profile.
   > These certificate objects are **not** created here — they come from the companion Cisco ISE
   > 802.1X solution (see Requirement R7). This profile only *references* them.
4. **Force Wi-Fi profile to be compliant with FIPS**: set **Yes** only if your agency requires FIPS
   140-2 validation; otherwise **No**.

### Step 7. Scope tags, assign, and create (Windows)

1. On **Scope tags** (optional): add a scope tag if your org uses them > **Next**.
2. On **Assignments**: under **Included groups**, select **Add groups**, choose
   `WIFIMGT - Pilot Devices`, then **Next**.
3. On **Review + create**, confirm the SSID, security type, and proxy are correct > **Create**.

---

## Phase 3 — Author the iOS/iPadOS Wi-Fi profile

### Step 8. Start the iOS/iPadOS profile

1. Select **Devices** > **Manage devices** > **Configuration** > **Create** > **New policy**.
2. **Platform**: select **iOS/iPadOS**.
3. **Profile type**: select **Templates**, then choose **Wi-Fi** > **Create**.

### Step 9. Name the iOS/iPadOS profile

1. **Basics** > **Name**: enter `WIFIMGT - Corp WiFi - iOS - Pilot`.
2. **Description**: enter `Corporate Wi-Fi for iOS/iPadOS devices — pilot ring.`
3. Select **Next**.

### Step 10. Configure the iOS/iPadOS Wi-Fi settings

On **Configuration settings**:

1. **Wi-Fi type**: **Basic** (pre-shared key) or **Enterprise** (802.1X — see Step 11).
2. **Network name**: enter the friendly connection name, e.g. `Contoso Corp Wi-Fi`.
3. **SSID**: enter the real broadcast SSID exactly, e.g. `Contoso-Corp`.
4. **Connect automatically**: **Enable**.
5. **Hidden network**: **Enable** only if the SSID is not broadcast; otherwise **Disable**.
6. **Security type** (Basic):
   - **Open (no authentication)**, or
   - **WPA2/WPA3 - Personal** (recommended) / **WPA/WPA2 - Personal** — then enter the **Pre-shared
     key**.
7. **Proxy settings**:
   - **None** — no proxy.
   - **Manual** — enter the **Proxy server address** (IP address, no scheme/path) and its **Port
     number**.
   - **Automatic** — enter the **Proxy server URL** that points to the PAC file, e.g.
     `http://proxy.contoso.com/proxy.pac`.
8. **Disable MAC address randomization**: leave **Not configured** unless NAC requires the hardware
   MAC (setting applies to iOS/iPadOS 14.0+).
9. Select **Next**.

### Step 11. (Enterprise/802.1X networks only) iOS/iPadOS Enterprise settings

If you chose **Enterprise** in Step 10:

1. **Security type**: **WPA/WPA2 - Enterprise** (or **WPA - Enterprise**).
2. **EAP type**: select **EAP-TLS** (recommended). EAP-TTLS, PEAP, EAP-FAST, EAP-SIM, and LEAP are
   also offered.
3. For **EAP-TLS**:
   - **Certificate server names**: **Add** the RADIUS server certificate common name(s), e.g.
     `radius.contoso.com` or a wildcard `*.contoso.com`.
   - **Root certificate for server validation**: select the existing trusted-root profile.
   - **Authentication method** > **Certificates**: select the existing SCEP or PKCS client-certificate
     profile.
   > As with Windows, these certificate objects come from the companion Cisco ISE 802.1X solution;
   > this profile only references them.

### Step 12. Scope tags, assign, and create (iOS/iPadOS)

1. **Scope tags** (optional) > **Next**.
2. **Assignments** > **Add groups** > `WIFIMGT - Pilot Devices` > **Next**.
3. **Review + create** > confirm SSID/security/proxy > **Create**.

---

## Phase 4 — Author the Android Enterprise Wi-Fi profile

> Android options differ by ownership. Steps 13–16 cover **corporate-owned** (fully managed,
> dedicated, COPE). For **personally-owned work profile (BYOD)**, see Step 17 for the differences.

### Step 13. Start the Android Enterprise profile

1. Select **Devices** > **Manage devices** > **Configuration** > **Create** > **New policy**.
2. **Platform**: select **Android Enterprise**.
3. Under **Templates**, select the profile type matching your devices:
   - **Fully Managed, Dedicated, and Corporate-Owned Work Profile** > **Wi-Fi**, or
   - **Personally-Owned Work Profile** > **Wi-Fi**.
4. Select **Create**.

### Step 14. Name the Android profile

1. **Basics** > **Name**: enter `WIFIMGT - Corp WiFi - Android - Pilot`.
2. **Description**: enter `Corporate Wi-Fi for Android Enterprise devices — pilot ring.`
3. Select **Next**.

### Step 15. Configure the Android (corporate-owned) Wi-Fi settings

On **Configuration settings**:

1. **Wi-Fi type**: **Basic** (pre-shared key) or **Enterprise** (802.1X — see Step 16).
2. **Network name**: enter the friendly name, e.g. `Contoso Corp Wi-Fi`.
3. **SSID**: enter the real broadcast SSID exactly, e.g. `Contoso-Corp`.
   > Reminder: you can't target two profiles with the **same SSID** to one device.
4. **Connect automatically**: **Enable**.
5. **Hidden network**: **Enable** only if the SSID is not broadcast; otherwise **Disable**.
6. **Security type** (Basic):
   - **Open (no authentication)**, or
   - **WPA-Pre-shared key** (recommended; WEP is deprecated on Android 12+) — then enter the
     **Pre-shared key**.
7. **Proxy settings**:
   - **None** — no proxy.
   - **Manual** — enter the **Proxy server address** (IP address), the **Port number**, and an
     optional **Exclusion list** (one host/IP per line; `*` wildcard allowed).
   - **Automatic** — enter the **Proxy server URL** pointing to the PAC file, e.g.
     `http://proxy.contoso.com/proxy.pac`.
8. **MAC address randomization** (Android 13+): leave **Use device default** unless NAC needs the
   hardware MAC (then **Use device MAC**).
9. Select **Next**.

### Step 16. (Enterprise/802.1X networks only) Android Enterprise settings

If you chose **Enterprise** in Step 15:

1. **EAP type**: select **EAP-TLS** (recommended); EAP-TTLS and PEAP are also available.
2. For **EAP-TLS**:
   - **Radius server name**: enter the DNS name in the RADIUS server certificate (e.g. `contoso.com`).
     On Android 11+ this is often required or the device won't connect; on Android 14+ keep the total
     under 256 characters (use the suffix only).
   - **Root certificate for server validation**: select the existing trusted-root profile.
   - **Authentication method** > **Certificates**: select the existing SCEP or PKCS client-certificate
     profile.
   - **Identity privacy (outer identity)**: optionally enter `anonymous`.
   > For **personally-owned work profile** EAP, the client certificate's **Subject Alternative Name
   > (SAN) must include the UPN**, or the Wi-Fi profile deployment fails.

### Step 17. Personally-owned work profile (BYOD) differences

If you selected **Personally-Owned Work Profile > Wi-Fi** in Step 13, note these differences from the
corporate-owned steps:

- There is **no Connect automatically** setting (the work profile manages that).
- **Proxy settings** offer only **None** or **Automatic** (a **Proxy server URL**) — **Manual proxy is
  not available**. If your BYOD network needs a proxy, you must use a PAC URL.
- Otherwise SSID, Hidden network, security type / EAP, and certificate references match Step 15/16.

### Step 18. Scope tags, assign, and create (Android)

1. **Scope tags** (optional) > **Next**.
2. **Assignments** > **Add groups** > `WIFIMGT - Pilot Devices` > **Next**.
3. **Review + create** > confirm SSID/security/proxy > **Create**.

---

## Phase 5 — Validate the pilot, then expand

### Step 19. Validate on pilot devices

Run the tests in **Testing & Validation** (`05-testing.md`) on at least one device per platform:
the profile shows **Succeeded** in Intune, the device joins the SSID automatically, and (if a proxy is
configured) traffic honors the proxy. Do not expand until all pilot gates pass.

### Step 20. Expand to production

1. Add the fleet devices to `WIFIMGT - Production Devices` (or point its dynamic rule at them).
2. For each of the three profiles (`WIFIMGT - Corp WiFi - Windows - Pilot`,
   `... - iOS - Pilot`, `... - Android - Pilot`), open the profile > **Properties** > **Assignments**
   > **Edit**, and **add** `WIFIMGT - Production Devices` to **Included groups**. Keep the pilot group
   assigned so pilot devices remain covered. Select **Review + save**.
   > Optional: rename the profiles from `- Pilot` to `- Prod` once the pilot ring is retired, and
   > update the scripts' `-ProfileNames` accordingly.

### Step 21. Rollback (if needed)

To reverse an expansion, open the affected profile > **Assignments** > **Edit**, **remove**
`WIFIMGT - Production Devices`, and **Review + save**. Devices drop the pushed Wi-Fi profile on their
next check-in. For a full stop, set the profile's assignment to **Excluded** for the affected group.
