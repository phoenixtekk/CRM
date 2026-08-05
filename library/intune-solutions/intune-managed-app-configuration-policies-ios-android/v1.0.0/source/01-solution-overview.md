# 1. Solution Overview — Intune Managed App Configuration Policies (iOS & Android)

## What App Configuration Policies are
An **App Configuration Policy** in Microsoft Intune pushes an app's own settings — the values the app
would otherwise ask a user to type on first launch — directly to the app, so it arrives
**pre-configured**. Instead of a user entering a server hostname, a tenant/realm, an environment, or
an account, Intune delivers those key/value pairs and the app reads them the moment it opens.

This is deliberately different from other Intune app features:
- **App Configuration** = *settings inside the app* (server hostname, realm, environment, feature
  flags, sign-in routing). This solution.
- **App Protection (MAM / APP)** = *data-protection controls* (encryption, copy/paste and save-as
  restrictions, app PIN). A different, complementary feature — covered by the dedicated App
  Protection solution.
- **App deployment/assignment** = *getting the app onto the device* (required/available install).

App configuration answers one question: **"When this app opens, how is it already set up, and where
does it send the user to sign in?"**

## The two delivery channels — and when each applies
App Configuration Policies are delivered through one of two channels. Choosing the right one is the
single most important design decision, because a policy sent on the wrong channel silently never
applies.

1. **Managed devices (the MDM channel)** — for devices **enrolled** in Intune.
   - **iOS/iPadOS:** the settings are delivered as an Apple **Managed App Configuration** payload —
     an Apple **property list (plist)** of key/value pairs the app declares support for. Intune
     targets the enrolled device, and the OS hands the plist to the app.
   - **Android Enterprise:** the settings are delivered as **managed configurations** — the app
     publishes a configuration **schema** to managed Google Play, and Intune renders that schema so
     you set each key. Applies to Android Enterprise (work profile, fully managed, dedicated).
   - Use this channel when devices are **enrolled** and you want the app configured at the device
     level for every user of that device.

2. **Managed apps (the MAM channel)** — for **MAM-managed apps**, enrolled **or** unenrolled (BYOD).
   - Settings flow through the **Intune App SDK / App Protection** channel to apps that integrate it
     (the Microsoft 365 apps and other SDK-enabled apps). The policy is scoped to a **user**, and the
     app reads the configuration when the user signs in with their work account.
   - Use this channel when the device is **not enrolled** (personal/BYOD) but you still need to hand
     the app settings — or when you want configuration tied to the *user's identity* rather than the
     device.

> **The enrolled vs MAM distinction in one line:** *managed-device* app config targets the **device**
> (enrolled/MDM) and can configure any app that supports the OS payload; *managed-app* app config
> targets the **user** (MAM) and only works with apps that integrate the Intune App SDK. If you send a
> managed-device iOS plist to an unenrolled phone, nothing happens — the OS payload channel does not
> exist there.

## Authoring the key/value pairs
The values you push are always **key/value pairs**, but the format depends on the platform and the
authoring surface you choose.

- **iOS/iPadOS — "Configuration designer" vs "Enter XML data".** Intune offers two ways to author an
  iOS managed-device policy:
  - **Configuration designer** — you type the **key** and **value** into a table; Intune builds the
    payload for you. Use this whenever you can; it is the least error-prone.
  - **Enter XML data** — you paste an Apple **property list (plist)** directly. This is **not** a
    place for a vendor's XML *profile* schema. The content must be a valid plist: a lowercase
    `<dict>` root containing only `<key>`/`<string>` (and `<integer>`/`<true/>`/etc.) pairs, with
    **no** XML namespace attributes (`xmlns`, `xsi`) and **no** vendor profile headers. A capitalized
    `<Dict>` root or a namespaced document is rejected by the portal. If an app genuinely needs a
    whole configuration document as one setting, it goes in as a **string value under a key** (e.g. a
    CDATA string), never as the plist's structure.
- **Android Enterprise — the managed configurations schema.** You do not invent keys. The app
  publishes its supported keys to managed Google Play; Intune reads that **schema** and renders the
  **configuration designer** so you fill in each key's value. There is no free-typed XML on
  Android — the schema is authoritative, and keys the app did not publish cannot be set.
- **Where the keys come from — always the vendor.** For any third-party app, the exact key **names**
  are defined by the app vendor and published in the app's documentation (and, on Android, in the
  managed-configuration schema). Never guess a key name; a typo'd key is simply ignored by the app.

## Identity and SSO routing (high level)
A well-built App Configuration Policy does more than pre-fill a hostname — it **routes the user's
sign-in to Microsoft Entra ID** so Conditional Access can enforce access. Two pieces cooperate:

1. **The app trusts Entra single sign-on.** Modern apps authenticate through **MSAL** (the Microsoft
   Authentication Library) and honor platform SSO — on iOS the **Microsoft Enterprise SSO plug-in**
   (delivered by the Microsoft Authenticator / Company Portal SSO extension), on Android the broker
   in Authenticator/Company Portal. App configuration keys point the app at your **tenant** and, where
   the app supports it, tell it to use federated/SSO sign-in rather than a local username/password.
2. **A Conditional Access policy scoped to the app enforces the access rules.** Once the app routes
   sign-in to Entra ID, a CA policy targeting that cloud app applies your controls (require MFA,
   require a compliant device, require an app protection policy, block legacy auth).

> **Scope boundary — read this.** This solution **wires the app to route to Entra ID / Conditional
> Access**; it does **not** build the Conditional Access policies themselves. The full CA build
> (break-glass accounts, report-only piloting, baseline policies) is delivered by the dedicated
> **Conditional Access Integration** solution. Here you create the app config that sends sign-in to
> Entra, then reference an existing CA policy (or the CA solution) to enforce it.

## The worked example — SAP Ariba Procurement
The guide implements one end-to-end example: the **SAP Ariba Procurement** mobile app. The goal — a
user installs Ariba, opens it, and lands **pre-pointed at your Ariba site/realm/environment with the
correct role option, on the Entra ID sign-in screen**, with no manual entry. The Implementation
section builds this policy click-by-click in Intune for **iOS/iPadOS** (as a plist) and shows the
Android managed-configuration equivalent, with every object named (e.g. `APPCFG - Ariba - iOS -
Pilot`). Because the exact Ariba configuration **key names** are vendor-defined and must be taken
from SAP's documentation, the guide presents them in a clearly-labeled table and flags them **"verify
against SAP Ariba documentation"** rather than asserting invented keys.

## How app config interacts with App Protection and supersedence
- **App config + App Protection are independent and complementary.** One configures the app; the
  other protects its data. A managed app can carry **both** at once — e.g. Ariba/Outlook receives its
  settings from an App Configuration Policy and its copy/paste/PIN controls from an App Protection
  Policy. They are assigned separately and do not conflict.
- **Supersedence is an *app-deployment* concept, not an app-config one.** When you replace one app
  package with a newer/different one via app supersedence, the **assignments carry to the superseding
  app but app configuration does not automatically follow** — confirm the App Configuration Policy
  still targets the current app after any supersedence, or the new app installs unconfigured.

## Benefits
- **Zero-touch first launch** — apps configure themselves; no user data entry, fewer help-desk tickets.
- **Consistent, auditable settings** — every device/user gets the same hostname, realm, and routing.
- **Sign-in routed to your IdP** — apps land on Entra ID, so Conditional Access can enforce access.
- **Cross-platform, one method** — the same design pattern for iOS/iPadOS and Android Enterprise.
- **Repeatable** — assign the policy to a group; new users/devices inherit configuration automatically.

## Limitations (be honest with buyers)
- **The app must support managed configuration.** App config only works for apps that declare
  supported keys (iOS Managed App Configuration, Android managed configurations, or the Intune App
  SDK). An app with no supported keys cannot be configured this way.
- **Vendor keys are authoritative and can drift.** Key names come from the app vendor; a wrong or
  outdated key is silently ignored. Always verify against current vendor documentation.
- **Channel must match posture.** A managed-device policy needs an **enrolled** device; a managed-app
  policy needs a **MAM/App-SDK** app. Sending the wrong channel means the config never applies.
- **Not every app is MDM-certified on every platform.** Some vendors support iOS managed configuration
  but not Android (SAP states the Ariba Procurement app is not certified with MDM on Android as of
  current documentation — **verify against SAP Ariba documentation**). Confirm platform support before
  designing.
- **SSO routing depends on the app.** Whether an app can be *forced* to federated/SSO sign-in via a
  key depends on the app's own capabilities; some apps only route to your IdP once the user enters a
  work email/domain.
- **Conditional Access enforcement requires Entra ID P1** and the CA policy itself (this solution
  routes to it; the CA solution builds it).

## The standard deployment model
> Choose the channel (managed devices vs managed apps) → author the key/value pairs (iOS plist /
> Android schema) → create the App Configuration Policy and assign to a **pilot** group → validate on
> a device that the app opens pre-configured and routes to Entra ID / Conditional Access → expand in
> waves. Pattern: **Assess → Configure → Pilot → Validate → Expand.**
