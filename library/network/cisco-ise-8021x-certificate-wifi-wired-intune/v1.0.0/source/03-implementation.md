# Implementation

Follow these steps **in order**. The order matters: the **trusted root** must exist before the SCEP
profile references it, the **SCEP certificate** must exist before the Wi-Fi/wired profiles reference
it, and everything is assigned to **`PILOT – 802.1X Devices`** first — never the whole fleet.

All Intune steps use the **Microsoft Intune admin center** at `https://intune.microsoft.com`. Object
names are exact and are **reused verbatim** in *Testing* and *Troubleshooting*.

> **Vendor boundary:** Steps 6–7 (ISE and switch/WLC) are stated at the architectural level and
> **deferred to Cisco documentation**. Do not expect ISE/IOS menu paths here.

---

## Step 0 — Pre-flight

1. Confirm all *Requirements* are green (CA/Cloud PKI, Certificate Connector or Cloud PKI, ISE
   RADIUS readiness, Entra pilot group).
2. Confirm the Entra group **`PILOT – 802.1X Devices`** exists and holds a few representative test
   devices. If not, create it (Entra → **Groups → New group → Security**) or run
   `ISE8021X-Set-ScopeTargeting.ps1`.
3. Have on hand: the **root `.cer`** for ISE's server chain (R3), the agreed **SAN/CN format**
   (R4), the **SSID string** (R5), and your **SCEP URL** (or Cloud PKI issuing CA).

**Gate:** Do not continue until every item above is confirmed.

---

## Step 1 — Create the trusted-root profile `Cisco 802.1X – Trusted Root`

1. Go to **Devices → Manage devices → Configuration → Create → New policy**.
2. **Platform:** choose your target (e.g. **Windows 10 and later**). **Profile type:** **Templates →
   Trusted certificate**. Click **Create**.
3. **Name:** `Cisco 802.1X – Trusted Root`. **Description:** "Root CA for Cisco ISE EAP server
   certificate — 802.1X EAP-TLS." Click **Next**.
4. **Configuration settings:** upload the **root `.cer`** file that signed ISE's server certificate
   (from R3). For Windows, set **Destination store = Computer certificate store – Root**. Click
   **Next**.
5. **Assignments:** **Add groups → `PILOT – 802.1X Devices`**. Click **Next**.
6. **Review + create → Create.**

> If ISE's chain has intermediates, repeat Step 1 for each intermediate as a separate Trusted
> certificate profile (name them `Cisco 802.1X – Trusted Root (Intermediate)`), destination store
> **Intermediate**.

**Gate:** Profile shows **Assigned**; on a pilot device the ISE root appears under the machine's
**Trusted Root Certification Authorities** store.

---

## Step 2 — Create the SCEP certificate profile `Cisco 802.1X – SCEP Cert`

*(If you use PKCS instead of SCEP, choose **PKCS certificate** as the profile type and reference your
CA/template instead of a SCEP URL; the identity settings below are the same.)*

1. **Devices → Configuration → Create → New policy.**
2. **Platform:** same target. **Profile type:** **Templates → SCEP certificate**. Click **Create**.
3. **Name:** `Cisco 802.1X – SCEP Cert`. **Description:** "Device client certificate for 802.1X
   EAP-TLS to Cisco ISE." **Next**.
4. **Configuration settings:**
   - **Certificate type:** **Device** (machine certificate for device/machine authentication).
   - **Subject name format:** e.g. `CN={{DeviceName}}` (match what ISE expects).
   - **Subject alternative name:** add the type ISE reads (per R4), e.g. **DNS =
     `{{DeviceName}}`** or **UPN**.
   - **Certificate validity period:** e.g. **1 year**.
   - **Key storage provider (KSP):** **Enroll to TPM if present, otherwise software**.
   - **Key usage:** **Digital signature** and **Key encipherment**.
   - **Extended key usage:** ensure **Client Authentication (1.3.6.1.5.5.7.3.2)** is present.
   - **Root certificate:** select the trusted-root profile **`Cisco 802.1X – Trusted Root`**.
   - **SCEP server URLs:** enter your SCEP/NDES URL, **or** select your **Cloud PKI** issuing CA's
     SCEP endpoint.
   Click **Next**.
5. **Assignments:** **Add groups → `PILOT – 802.1X Devices`**. **Next**.
6. **Review + create → Create.**

**Gate:** Profile shows **Assigned**; on a pilot device a certificate with **Client Authentication**
EKU and the expected Subject/SAN appears in the **machine personal (My)** store, chaining to the ISE
root.

---

## Step 3 — Create the Wi-Fi 802.1X profile `Corp Wi-Fi – EAP-TLS`

1. **Devices → Configuration → Create → New policy.**
2. **Platform:** target. **Profile type:** **Templates → Wi-Fi**. Click **Create**.
3. **Name:** `Corp Wi-Fi – EAP-TLS`. **Description:** "Corporate Wi-Fi, WPA2/WPA3-Enterprise,
   EAP-TLS to Cisco ISE." **Next**.
4. **Configuration settings:**
   - **Wi-Fi type:** **Enterprise**.
   - **SSID:** the exact corporate **SSID** (case-sensitive, from R5).
   - **Connect automatically** = Yes; **Connect to this network even when not broadcasting** as
     appropriate.
   - **Security type:** **WPA2-Enterprise** (or **WPA3-Enterprise** if supported end-to-end).
   - **EAP type:** **EAP-TLS**.
   - **Client certificate for on-client authentication (identity certificate):** select
     **`Cisco 802.1X – SCEP Cert`**.
   - **Certificate server names / Root certificate for server validation:** select
     **`Cisco 802.1X – Trusted Root`**; where available, add ISE's **server name(s)** for
     server-name matching.
   Click **Next**.
5. **Assignments:** **Add groups → `PILOT – 802.1X Devices`**. **Next**.
6. **Review + create → Create.**

**Gate:** Profile shows **Assigned**; a pilot device sees the corporate SSID provisioned and, if in
range, associates using the device certificate.

---

## Step 4 — Create the wired 802.1X profile `Wired 802.1X – EAP-TLS`

1. **Devices → Configuration → Create → New policy.**
2. **Platform:** **Windows 10 and later**. **Profile type:** **Templates → Wired network**. Click
   **Create**. *(If "Wired network" is not present as a template, use the Settings Catalog "Wired
   Network" category; the fields map one-to-one.)*
3. **Name:** `Wired 802.1X – EAP-TLS`. **Description:** "Wired 802.1X, EAP-TLS to Cisco ISE." **Next**.
4. **Configuration settings:**
   - **Authentication mode:** e.g. **Machine** (device certificate) — match your ISE policy.
   - **EAP type:** **EAP-TLS**.
   - **Client certificate (identity):** select **`Cisco 802.1X – SCEP Cert`**.
   - **Trusted server / root certificate:** select **`Cisco 802.1X – Trusted Root`**; add ISE
     server-name matching where available.
   - Enable **remember/cache** and **single sign-on** settings per your standard; ensure the
     profile **starts the Wired AutoConfig (dot3svc) service**.
   Click **Next**.
5. **Assignments:** **Add groups → `PILOT – 802.1X Devices`**. **Next**.
6. **Review + create → Create.**

**Gate:** Profile shows **Assigned**; on a pilot device the **Wired AutoConfig** service is running
and the wired NIC is set to authenticate with EAP-TLS.

---

## Step 5 — Sync a pilot device and confirm delivery

1. On a pilot device: **Settings → Accounts → Access work or school → Info → Sync** (or run
   `ISE8021X-Validation.ps1` locally).
2. Confirm all four objects landed: trusted root present, client cert present (Client
   Authentication EKU), Wi-Fi profile present, wired profile present + dot3svc running.
3. In Intune, **Devices → Configuration**, open each profile → **Device status** shows the pilot
   device **Succeeded**.

**Gate (Intune side):** cert present ✔ and all profiles **Succeeded** on the pilot device.

---

## Step 6 — Confirm the Cisco ISE + network side *(vendor side — deferred to Cisco docs)*

Before an authentication can succeed, the ISE/network side (R7) must be true. Confirm with the ISE/
network administrator, per **Cisco ISE / WLC / IOS documentation**:

- ISE **trusts the CA** that issued the device certificate (device CA chain in ISE's trusted store).
- An ISE **policy set** permits **EAP-TLS**, with a **certificate authentication profile** reading
  the certificate field your SCEP profile populated (R4), and an **authorization result**
  (permit/VLAN) for authenticated devices.
- The **WLC/AP** and target **switches** are defined in ISE as network access devices with the
  shared RADIUS secret, and **802.1X is enabled** on the SSID and the target switch ports.

Do **not** fabricate these ISE/switch steps — follow Cisco documentation and confirm each control in
the Cisco console.

**Gate (Cisco side):** ISE is reachable as RADIUS, trusts the device CA, and the network devices
point at ISE.

---

## Step 7 — Validate end-to-end authentication (pilot)

1. **Wi-Fi:** connect a pilot device to the corporate SSID; confirm it associates **without** a
   password prompt (certificate is used).
2. **Wired:** plug a pilot device into an 802.1X-enabled port; confirm the port authorizes.
3. In **ISE → Operations → RADIUS → Live Logs** (Cisco side), confirm an **Access-Accept** with
   **EAP-TLS** for the pilot device. A **reject** here points back to the trust chain or ISE policy
   (see *Troubleshooting*).

**Gate (the three gates together):** cert present ✔, profile applied ✔, **ISE 802.1X auth success**
✔. Do not expand until all three pass on multiple pilot devices.

---

## Step 8 — Expand to the fleet

1. Once the pilot passes on Wi-Fi **and** wired across representative device types, add the broader
   production group (e.g. `Corp – 802.1X Devices`) to the **Assignments** of all four profiles.
2. Expand in **waves** (add device batches to the production group), watching Intune profile status
   and ISE Live Logs after each wave.
3. Keep `PILOT – 802.1X Devices` assigned for ongoing testing of changes.

**Rollback at any point:** remove the profile **assignment** from the affected group (and, if
necessary, keep a fail-open/MAB fallback on switch ports during rollout) — see *Best Practices* and
`global-requirements-network.md` (G7).
