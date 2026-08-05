# 3. Implementation

This section builds App Configuration Policies **click-by-click** for **iOS/iPadOS** and **Android
Enterprise**, using **SAP Ariba Procurement** as the worked example, and wires the app's sign-in to
route to Microsoft Entra ID / Conditional Access. Every object you create is named; reuse the exact
names in Testing and Troubleshooting.

> **Portal note (US Government):** all navigation below uses the commercial admin center
> `https://intune.microsoft.com`. On GCC/GCC High use **`https://intune.microsoft.us`** — the blades
> and steps are identical.

> **Vendor-key note (read before you build the Ariba example):** the Ariba configuration **key names**
> shown here are **placeholders**. SAP defines the authoritative keys in the *SAP Ariba Procurement
> Mobile App Guide* → **"Configuring SAP Ariba Procurement mobile app in Mobile Device Management
> Tool."** Confirm every key there before production use — flagged **"verify against SAP Ariba
> documentation."** The *mechanics* below (how to build, assign, and validate a policy) are correct
> regardless of the exact keys.

---

## Phase A — Assess and choose the channel

### Step 1 — Decide managed-device vs managed-app, per app
For each app you will configure, choose one channel (see Overview §"The two delivery channels"):
- **Managed devices (MDM):** device is **enrolled**; you want the app configured on the device.
  iOS = plist payload; Android = managed configurations.
- **Managed apps (MAM):** device may be **unenrolled** (BYOD); the app integrates the Intune App SDK;
  configuration is tied to the **user**.

For the Ariba worked example we use the **managed-device (MDM)** channel on **iOS/iPadOS** (SAP
supports generic MDM on iOS; Ariba is **not MDM-certified on Android** per current SAP docs — **verify
against SAP Ariba documentation**). The Android steps (Phase D) show the general managed-configuration
method with a placeholder Ariba schema so the pattern is complete.

### Step 2 — Confirm the app object and gather the keys
1. In **Apps → iOS/iPadOS**, confirm **SAP Ariba Procurement** is present — publisher **SAP SE**,
   bundle ID **`com.sap.ariba.procurement`** (*verify the exact bundle ID in the App Store listing /
   SAP docs*). If missing, add it (Requirements §2.5).
2. Open the *SAP Ariba Procurement Mobile App Guide* MDM section and record the **exact key names**
   for: site/server **hostname**, **realm**, **environment**, **user role**, and any **SSO/sign-in**
   key. Enter them in the key table (Step 5). **verify against SAP Ariba documentation.**

### Step 3 — Create the pilot group
1. **Entra admin center → Groups → New group.**
2. Group type **Security**; **Name** = `APPCFG - Ariba - Pilot`; add the pilot **devices** (managed-
   device channel) or pilot **users** (managed-app channel).
3. **Create.**

---

## Phase B — Build the iOS/iPadOS App Configuration Policy (Ariba, managed devices)

### Step 4 — Create the policy and bind it to the app
1. **Intune admin center (`https://intune.microsoft.com`) → Apps → App configuration policies →
   Create → Managed devices.**
2. **Basics:**
   - **Name:** `APPCFG - Ariba - iOS - Pilot`
   - **Description:** `Pre-configures SAP Ariba Procurement (site/realm/environment/role) and routes sign-in to Entra ID. Pilot.`
   - **Platform:** **iOS/iPadOS**
   - **Targeted app:** click **Select app**, choose **SAP Ariba Procurement** (publisher **SAP SE**,
     bundle ID `com.sap.ariba.procurement`). Click **Select**, then **Next**.

### Step 5 — Author the settings (Configuration designer — preferred)
1. On the **Settings** tab, set **Configuration settings format = Use configuration designer**.
2. Add one row per vendor key. **Use hostnames, not URLs, in any "server/host" field** — no `https://`
   and no trailing path/slash (a path is sent to DNS as one string and fails to resolve).

   | Configuration key (PLACEHOLDER — verify against SAP Ariba documentation) | Value type | Example value | Notes |
   |---|---|---|---|
   | `aribaSiteHost` | String | `s1.ariba.com` | **Hostname only** — no `https://`, no path. Region-specific (e.g. `s1-eu.ariba.com`); confirm your site host. |
   | `aribaRealm` | String | `yourcompany` | The buyer **realm/subdomain** (the `realm=` value from your Ariba SSO/ACS URL). |
   | `aribaEnvironment` | String | `production` | e.g. `production` / `test` — confirm the exact accepted values. |
   | `userRole` | String | `requester` | The employee/role option pre-selected on launch — confirm accepted values. |
   | `authMode` | String | `SSO` | Route sign-in to the federated/Entra ID flow rather than local sign-in — confirm the exact key/value. |
   | `tenantId` | String | `{{tenantid}}` | Optional — Entra tenant GUID; the `{{tenantid}}` token is expanded by Intune at delivery. |

   > Intune supports **token variables** in values — e.g. `{{userprincipalname}}`, `{{mail}}`,
   > `{{tenantid}}`, `{{deviceid}}` — expanded per user/device at delivery. Use `{{mail}}` or
   > `{{userprincipalname}}` to pre-fill a username field so the user only enters credentials.

3. Click **Next**.

### Step 5-ALT — Author the settings (Enter XML data — plist)
If SAP's documentation supplies the configuration as a property list, choose **Configuration settings
format = Enter XML data** and paste a **valid Apple plist**. It **must** be a lowercase `<dict>` root
of `<key>`/`<string>` pairs with **no** `xmlns`/`xsi` attributes and **no** vendor XML profile header
(a capitalized `<Dict>` or a namespaced document is rejected):

```xml
<dict>
    <key>aribaSiteHost</key>
    <string>s1.ariba.com</string>
    <key>aribaRealm</key>
    <string>yourcompany</string>
    <key>aribaEnvironment</key>
    <string>production</string>
    <key>userRole</key>
    <string>requester</string>
    <key>authMode</key>
    <string>SSO</string>
    <key>tenantId</key>
    <string>{{tenantid}}</string>
</dict>
```

> The `<?xml … ?>` line and the `<!DOCTYPE plist …>`/`<plist>` wrapper are added by the platform —
> if you paste them and the portal complains ("Remove XML headers from property list"), delete them
> and paste only from the `<dict>` to the closing `</dict>`. Keys/values remain **placeholders —
> verify against SAP Ariba documentation.** A full vendor *profile* document, if the app supports one,
> goes in as a **string value under a key** (CDATA), never as the plist's structure.

### Step 6 — Assign to the pilot group
1. On the **Assignments** tab → **Included groups → Add groups** → select **`APPCFG - Ariba -
   Pilot`** → **Select**.
2. **Next → Review + create → Create.** The policy now applies to enrolled iOS devices in the pilot
   group the next time they sync and the app is present.

---

## Phase C — Wire sign-in to Entra ID / Conditional Access

### Step 7 — Ensure the Entra SSO plumbing is on the device
1. **Deploy Microsoft Authenticator** (Apps → iOS/iPadOS → Add → iOS store app → **Microsoft
   Authenticator**, publisher **Microsoft Corporation**, bundle ID `com.azure.authenticator`),
   assigned to the pilot group as **Required**.
2. **Create the iOS Enterprise SSO extension profile** (if not already present):
   - **Devices → Configuration → Create → New policy → iOS/iPadOS → Templates → Device features.**
   - **Name:** `APPCFG - iOS - Enterprise SSO`.
   - Under **Single sign-on app extension**, set **SSO app extension type = Microsoft Entra ID**.
   - **Save**, then **Assign** to `APPCFG - Ariba - Pilot`. This delivers the Microsoft Enterprise
     SSO plug-in so the app's MSAL sign-in lands on Entra ID silently.

### Step 8 — Confirm the app routes to Entra (config side)
The `authMode`/SSO key from Step 5 tells Ariba to use federated sign-in. Combined with the Enterprise
SSO extension and the pre-filled `aribaRealm`, the app opens straight to the **Entra ID** sign-in for
your tenant. (Whether an app can be *forced* to SSO via a key is app-dependent — **verify against SAP
Ariba documentation**; some apps route to the IdP only after the user's work email/realm is detected,
which the pre-filled realm satisfies.)

### Step 9 — Reference the Conditional Access policy (do not build it here)
1. **Entra admin center → Protection → Conditional Access → Policies.** Confirm a policy targets the
   Ariba enterprise application (or the appropriate cloud app) with your controls (require MFA /
   require compliant device / require app protection policy).
2. If none exists, **build it with the dedicated Conditional Access Integration solution** — create
   break-glass accounts, pilot in **Report-only**, then enable. This solution intentionally stops at
   *routing* sign-in to Entra; the CA solution *enforces* it.

> **Boundary reminder:** naming here — reference a CA policy such as `CA - Ariba - Require Compliant +
> MFA` if your CA solution created one, but do **not** author CA logic in this guide.

---

## Phase D — Build the Android Enterprise managed configuration (general pattern)

> SAP states the Ariba Procurement app is **not certified with MDM on Android** as of current docs
> (**verify against SAP Ariba documentation**). The steps below are the **general** Android
> managed-configuration method — correct for any Android Enterprise app that publishes a
> managed-configuration schema (Outlook, Chrome, and most enterprise apps). The Ariba keys are shown
> as **placeholders** to illustrate the pattern.

### Step 10 — Create the Android managed-configuration policy
1. **Apps → App configuration policies → Create → Managed devices.**
2. **Basics:**
   - **Name:** `APPCFG - Ariba - Android - Pilot`
   - **Platform:** **Android Enterprise**
   - **Profile type:** **All Profile Types** (or the specific work-profile/fully-managed type you
     target).
   - **Targeted app:** **Select app** → choose the managed Google Play app (for a real deployment,
     the vendor's Android app — publisher and package ID confirmed). **Next.**

### Step 11 — Set the keys from the app's schema
1. On **Settings**, set **Configuration settings format = Use configuration designer**. Intune reads
   the app's **managed-configuration schema** from managed Google Play and lists its keys — **you do
   not type key names on Android; you fill in the schema's values.**
2. Set the values (placeholders shown; the real key names come from the app's schema):

   | Schema key (from managed Google Play — example/placeholder) | Value | Notes |
   |---|---|---|
   | `server_host` | `s1.ariba.com` | **Hostname only.** |
   | `realm` | `yourcompany` | Buyer realm/subdomain. |
   | `environment` | `production` | Confirm accepted values. |
   | `user_role` | `requester` | Confirm accepted values. |
   | `auth_mode` | `sso` | Route to federated/Entra ID sign-in. |

   > If the schema exposes a key as an enum/bool/bundle, the designer shows the correct control — use
   > it rather than free text. The **JSON** channel (below) is only for the rare case you must supply a
   > raw managed-configuration document.
3. **Next.**

### Step 11-ALT — Android via raw JSON (only if required)
If you must supply the configuration as raw JSON (e.g. an OEMConfig-style bundle), the values map to
the schema's keys exactly:

```json
{
  "kind": "androidenterprise#managedConfiguration",
  "managedProperty": [
    { "key": "server_host", "valueString": "s1.ariba.com" },
    { "key": "realm", "valueString": "yourcompany" },
    { "key": "environment", "valueString": "production" },
    { "key": "user_role", "valueString": "requester" },
    { "key": "auth_mode", "valueString": "sso" }
  ]
}
```
Keys remain **placeholders — verify against the app's managed-configuration schema.**

### Step 12 — Assign the Android policy
1. **Assignments → Included groups → Add groups →** `APPCFG - Ariba - Pilot` → **Select**.
2. **Review + create → Create.**

---

## Phase E — Managed-app (MAM) channel — when the device is unenrolled

If you need to configure a MAM app (Intune App SDK) on an **unenrolled/BYOD** device (e.g. Outlook on
a personal phone), use the **managed apps** channel instead of managed devices:

### Step 13 — Create a managed-app configuration policy
1. **Apps → App configuration policies → Create → Managed apps.**
2. **Basics: Name** = `APPCFG - Outlook - MAM - Pilot`. Under **Public apps → Select public apps**,
   choose the App SDK-enabled app(s) (e.g. **Microsoft Outlook**). **Next.**
3. **Settings:** add the app's supported managed-app keys (from vendor docs). **Next.**
4. **Assignments:** assign to a **user** group (MAM policies target users, not devices) —
   `APPCFG - Ariba - Pilot` if it holds users. **Create.**

> Managed-app policies apply on enrolled **and** unenrolled devices because they ride the App SDK, not
> the OS MDM payload. This is the channel to use when there is no enrollment to carry an OS plist.

---

## Phase F — Pilot → Validate → Expand

### Step 14 — Validate on a pilot device
Run the Testing procedures (§5): on a pilot device, install/open the app and confirm it is
**pre-configured** (host/realm/environment/role filled) and lands on the **Entra ID / Conditional
Access** sign-in. Use `APPCFG-Validate-Assignment.ps1` to confirm the device/user received the policy.

### Step 15 — Expand to production
1. Create production groups (e.g. `APPCFG - Ariba - Prod` for devices/users) and a production policy
   copy named `APPCFG - Ariba - iOS - Prod` (and `…- Android - Prod`).
2. Add the production group to the production policy's **Assignments**; expand in waves.
3. Keep the pilot policy for future changes; test key changes in pilot before promoting.

### Step 16 — Document and hand off
Record every object name (`APPCFG - Ariba - iOS - Pilot`, `APPCFG - Ariba - Android - Pilot`,
`APPCFG - iOS - Enterprise SSO`, `APPCFG - Ariba - Pilot` group, production copies) and the confirmed
vendor keys, so the configuration is auditable and reproducible.
