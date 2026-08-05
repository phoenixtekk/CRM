# 1. Solution Overview — iOS/iPadOS Enterprise SSO App Extension for Corporate-Owned iPhones

## What this solution is
This solution deploys the **Microsoft Enterprise SSO plug-in** as an Apple **Extensible Single
Sign-On (SSO) app extension** on **corporate-owned (COD) iPhones and iPads** managed by **Microsoft
Intune**. Once in place, apps and browsers that authenticate against **Microsoft Entra ID** get
**silent, shared single sign-on** — the user signs in once and the on-device broker satisfies
subsequent Entra sign-ins across cooperating apps and Safari, without repeated password prompts or
per-app MFA.

Apple's **Extensible SSO** framework lets an identity provider register a system-wide authentication
extension. On iOS/iPadOS, Microsoft ships the Enterprise SSO plug-in **inside the Microsoft
Authenticator app** — this is the first important difference from the Mac, where the same extension
ships inside Company Portal:

- **iOS/iPadOS broker host = Microsoft Authenticator.** The extension binary lives in the
  **Microsoft Authenticator** app; without Authenticator installed, the extension identifier the
  profile references does not exist on the device.
- **macOS broker host = Company Portal.** (Covered by the separate *macOS Enterprise SSO App
  Extension* solution — do not confuse the two; the identifiers differ.)

> **Scope, stated plainly.** This solution delivers the **app/browser SSO extension** for
> **corporate-owned, Intune-enrolled** iPhones/iPads. It is the identity-experience layer — it
> silences sign-in prompts *inside apps and Safari*. It is **not** device enrollment (ADE/ABM is a
> prerequisite, covered by the enrollment solutions), it is **not** the two-phone
> personal+corporate scenario (see *Dual-Device iPhone Management with SSO*), and it is **not**
> shared-device identity (see *iOS iPhone Shared Device Mode — Frontline SSO*). It assumes each COD
> iPhone is assigned to **one** user.

## How Apple Extensible SSO works (the two types)
An Extensible SSO configuration profile carries a **type**:

- **Redirect** — for identity providers that use **OpenID Connect / OAuth 2 redirect** flows.
  **Microsoft Entra ID is a redirect IdP**, so the Enterprise SSO plug-in is a **redirect-type**
  extension. It intercepts authentication requests to a defined set of **Entra URLs** and completes
  them silently using the broker. **This solution uses the redirect type.**
- **Credential** — for **challenge/response (Kerberos-style)** providers. **Out of scope here.**

On iOS/iPadOS, Intune's **Device features** template exposes a convenient **SSO app extension type =
Microsoft Entra ID** option that pre-populates the Microsoft extension identifiers for you; the
underlying type is still Redirect. This solution uses that path (with the raw Redirect values given
as well, so you can verify or script them).

## How it works, step by step
1. **Microsoft Authenticator delivers the extension binary.** The Enterprise SSO plug-in ships inside
   the **Microsoft Authenticator** app for iOS/iPadOS. Authenticator must be installed (deployed
   **Required** from Intune) on the COD device.
2. **Intune deploys the redirect profile.** A **configuration profile** (Device features → *Single
   sign-on app extension*, type **Microsoft Entra ID**) activates the extension, setting the
   **Extension Identifier** `com.microsoft.azureauthenticator.ssoextension`, **Team Identifier**
   `UBF8T346G9`, **Type = Redirect**, and the **Entra URLs** to intercept.
3. **First sign-in primes the broker.** The user signs in once to a Microsoft app or web property
   (for example Outlook, or `https://outlook.office.com` in Safari) with their Entra credentials,
   completing MFA. The extension registers a **Primary Refresh Token (PRT)**–backed session on the
   device.
4. **Silent SSO afterward.** Subsequent Entra sign-ins from **cooperating apps and Safari** are
   satisfied **silently** — no password re-entry, no repeat MFA — until the session expires.
5. **Scoping (optional but recommended).** Extension-configuration keys tune coverage: turn on SSO
   for **all managed apps**, allow-list app bundle-ID prefixes, and enable browser interaction.

## What silent SSO covers (and what it needs)
- **Safari and native apps built on the Microsoft Authentication Library (MSAL)** or the iOS broker
  get silent SSO automatically once the extension is active and the broker is primed.
- **Managed apps** (deployed and managed by Intune) can all be brought into SSO with the
  iOS-specific key **`Enable_SSO_On_All_ManagedApps = 1`** — a coverage lever the Mac does not have.
- **Non-Safari browsers** (Chrome, Edge, Firefox on iOS) get broker SSO **only** when they support
  the iOS SSO extension; otherwise they fall back to normal interactive sign-in. Best-effort by
  design — set that expectation with users.
- The device must have **Microsoft Authenticator** present so the broker can register and issue the
  PRT.

## Benefits
- **Fewer prompts, less MFA fatigue** — one sign-in, then silent Entra SSO across apps and Safari on
  the corporate iPhone.
- **Managed-app-wide SSO** — one key (`Enable_SSO_On_All_ManagedApps`) extends SSO to every
  Intune-managed app on the device.
- **No enrollment change** — deploys a configuration profile only; it does **not** re-enroll or
  re-image the device and is reversible by unassigning the profile.
- **Conditional Access friendly** — the broker PRT session supports device-based Entra policies for
  the apps that use it.
- **Precise scoping** — target exactly the apps/URLs you want via bundle-ID prefixes and URL lists.

## Limitations (be honest with buyers)
- **Corporate-owned, enrolled devices.** This targets Intune-enrolled COD iPhones/iPads. It is not a
  BYOD/MAM-only capability (personal-device SSO for unenrolled phones is a different model).
- Requires the **Microsoft Authenticator** app (the extension lives inside it) and a supported
  iOS/iPadOS release (**iOS/iPadOS 13+**; a current release recommended).
- **Browser coverage varies.** Only browsers with iOS SSO-extension support get silent SSO; others
  sign in normally.
- Apps must use the **Microsoft broker/MSAL** or Safari to benefit; legacy apps with embedded
  webviews may not.
- Requires **Microsoft Entra ID** as the IdP and outbound access to the Entra login endpoints.
- **Identifiers can change.** The extension identifier and template options above reflect current
  Microsoft documentation — **verify them in your tenant** before fleet rollout rather than assuming.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Corporate-owned, Intune-enrolled iPhones/iPads receive the Microsoft Enterprise SSO plug-in
> (hosted in Microsoft Authenticator) as a redirect-type Extensible SSO app extension, scoped to
> Entra login URLs and managed apps, deployed pilot-first and reversible.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
