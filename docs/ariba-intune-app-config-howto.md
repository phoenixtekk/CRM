# How-To: Auto-Configure the SAP Ariba Procurement App with Intune (Tenant + Employee + Entra/CA Sign-In)

**Goal:** when a managed user opens the Ariba Procurement mobile app, it should already know the
**tenant/realm**, be set to the **employee** option, and send the user straight to the
**Entra ID / Conditional Access** sign-in — no manual setup.

This is done with an **Intune App Configuration Policy** (managed app config) plus the identity side
(Entra SSO + a Conditional Access policy targeting the app). Two moving parts:

1. **App Configuration Policy** — pushes key/value settings *into the app* so it self-configures on launch.
2. **Identity routing** — the app trusts Entra ID, and a Conditional Access policy governs the sign-in.

> ⚠️ **The one thing you must get from SAP, not from me:** the *exact app-configuration key names* for
> the Ariba Procurement app (the keys that set tenant/realm, environment, and user type). I won't guess
> those. The steps below tell you exactly **where to get them** so you use the real ones.
>
> 📌 **Platform reality (verified against SAP):** SAP documents the Ariba Procurement mobile app for
> **iOS generic MDM** and does **not** list it as MDM-certified on **Android**. So build this **iOS-first**
> — the Android section below is the general Intune pattern, and you must **confirm with SAP whether the
> Android app honors managed configuration at all** before relying on it. Authoritative source for the
> keys: **SAP Ariba Procurement Mobile App Guide → "Configuring the app in a Mobile Device Management
> Tool"** (help.sap.com/docs/buying-invoicing/sap-ariba-procurement-mobile-app-guide).

---

## Step 0 — Prerequisites (5-minute check)
- The **Ariba Procurement app is deployed through Intune** as a managed app (iOS: added from the App
  Store as a managed app / VPP; Android: approved in **Managed Google Play** and assigned). App config
  only applies to an app Intune manages.
- Devices are **enrolled** (for device-level app config) *or* you're using **App Protection / MAM**
  for unmanaged devices (app config for managed apps). Decide which — the policy type differs.
- **SAP Ariba is set up for SSO with your Entra ID tenant** (the Ariba/SAP enterprise app exists in
  Entra ID with SAML/OIDC SSO). If it isn't, that's a separate prerequisite — do it first, or the
  "route to Entra sign-in" behavior has nothing to route to.

---

## Step 1 — Get the real Ariba app-config keys

You need the keys that correspond to **tenant/realm**, **environment**, and **employee/user type**.

- **iOS/iPadOS (the supported path):** the keys come from **SAP's documentation** for the Ariba app's
  managed app configuration — the **SAP Ariba Procurement Mobile App Guide → "Configuring … in a Mobile
  Device Management Tool"** page. Get the documented key names from SAP before building the iOS policy.
- **Android (verify first):** SAP does **not** list Ariba as MDM-certified on Android, so the Android
  Enterprise config designer may **not** surface Ariba keys from Managed Google Play. Treat Step 3 as
  the *general* pattern and confirm with SAP whether the Android build supports managed configuration
  at all. If it doesn't, deliver the config on iOS only.
- **Realm tip (verified):** the Ariba **realm** is your buyer subdomain — you can read it from the
  `realm=` value in your Ariba **SSO / ACS URL**.

Write down the three mappings you need (fill the middle column from the source above — **do not assume
the names**):

| What you want to set | Ariba key (get the real name from Android designer / SAP docs) | Example value |
|---|---|---|
| Tenant / realm / company | `‹ariba-tenant-key›` | your Ariba realm / tenant ID |
| Environment | `‹ariba-environment-key›` | e.g. Production |
| Employee / user type | `‹ariba-usertype-key›` | Employee |
| (If present) SSO / discovery endpoint | `‹ariba-sso-key›` | your Entra SSO / IdP URL |

---

## Step 2 — Create the iOS App Configuration Policy
1. **Intune admin center** → **Apps** → **App configuration policies** → **Add** → **Managed devices**.
2. Name it **`Ariba – iOS – App Config – Pilot`**. Platform **iOS/iPadOS**. Under **Targeted app**,
   select your managed **Ariba Procurement** app. **Next**.
3. **Configuration settings format:**
   - If you have just a few keys → **Use configuration designer**, add each key/value from your Step 1 table.
   - If SAP gives you an XML blob → **Enter XML data**. ⚠️ **It must be a valid Apple *plist*** — a
     lowercase `<dict>` root containing `<key>`/`<string>` (etc.) pairs. **Not** a capitalized `<Dict>`,
     and **not** a namespaced vendor XML document (strip any `xmlns`/`xsi` headers), or it will reject it.

   Minimal plist shape (replace keys/values with the real ones):
   ```xml
   <dict>
     <key>‹ariba-tenant-key›</key><string>your-realm</string>
     <key>‹ariba-usertype-key›</key><string>Employee</string>
     <key>‹ariba-environment-key›</key><string>Production</string>
   </dict>
   ```
   ⚠️ **Any host/server field is a HOSTNAME, not a URL** — no `https://` and no trailing path/slash, or
   the app's lookup fails.
4. **Next** → assign to your pilot group (Step 5) → **Create**.

## Step 3 — Create the Android App Configuration Policy (only if SAP confirms Android support)
> ⚠️ SAP does not list Ariba as MDM-certified on Android. Confirm the Android app honors managed
> configuration before doing this; if it doesn't, ship iOS-only and skip this step.
1. **Apps** → **App configuration policies** → **Add** → **Managed devices**. Name it
   **`Ariba – Android – App Config – Pilot`**. Platform **Android Enterprise**, profile type
   **All Profile Types**. Select the managed **Ariba Procurement** app. **Next**.
2. **Configuration settings** → **Use configuration designer** → **Add**. If the app supports managed
   config, Intune lists **Ariba's own supported keys** (from its Managed Google Play schema) — tick the
   tenant, environment, and user-type keys and set their values (Employee, your realm, Production). If
   no keys appear, the app doesn't support Android managed config — stop and use iOS. **Next** →
   assign → **Create**.

## Step 4 — Wire the Entra / Conditional Access sign-in routing
The app "sends them to the Entra/Conditional Access login" because it trusts your tenant's SSO and a CA
policy governs it:
1. Confirm the **SAP Ariba enterprise app** exists in **Entra ID → Enterprise applications** with SSO
   configured. The tenant/environment value you set in Step 1–3 is what points the app at *your* SSO.
2. Create/confirm a **Conditional Access policy** targeting that Ariba enterprise app (require managed
   device / MFA / compliant device as your standard requires). *(Deep CA design is its own topic — see
   our Conditional Access Integration guide; here you just need the app in scope.)*
3. Result: on launch the app reads its config → knows the tenant → initiates sign-in against Entra →
   the CA policy applies.

## Step 5 — Assign & test (prove it works)
1. Assign both policies to a small **`Ariba – App Config – Pilot`** Entra group first.
2. On a pilot device: remove/reinstall the Ariba app so it picks up fresh config, open it, and confirm:
   - it does **not** prompt for tenant/realm (pre-filled ✓)
   - the **employee** option is preset ✓
   - it goes straight to the **Entra ID sign-in**, and your **CA policy** applies ✓
3. Once the pilot passes, expand assignment to production.

---

## Fast troubleshooting
- **Config not applying (iOS):** almost always the plist — capitalized `<Dict>`, leftover `xmlns`/`xsi`,
  or it's a vendor profile rather than key/value pairs. Rebuild as a clean lowercase `<dict>` of
  `<key>`/`<string>` pairs.
- **App can't reach the tenant / "cannot contact server":** a host field has a URL/path in it. Use the
  bare hostname only.
- **Keys ignored:** wrong key name (case-sensitive) — re-check against the Android designer (Android)
  or SAP's documented keys (iOS). This is the #1 cause and why we don't guess the names.
- **Policy targets the app but nothing changes:** the app isn't actually Intune-*managed* on that
  device, or you built a "managed apps" (MAM) policy for an MDM-enrolled scenario (or vice-versa).
  Match the policy type to how the device/app is managed.
- **No sign-in redirect:** the Ariba enterprise app / SSO isn't set up in Entra yet, or the CA policy
  doesn't have the app in scope.

> **Bottom line:** the Intune mechanics above are exact. The only blank to fill is the Ariba key
> *names* — get tenant/environment/user-type from **SAP's Ariba Procurement Mobile App Guide** (the
> MDM configuration page) and build it **iOS-first**, since SAP doesn't certify the app for Android
> MDM. Your realm is the buyer subdomain in your Ariba SSO/ACS URL.
