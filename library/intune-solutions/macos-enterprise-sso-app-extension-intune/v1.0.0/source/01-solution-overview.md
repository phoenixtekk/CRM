# 1. Solution Overview — macOS Enterprise SSO App Extension (Extensible SSO for Apps & Browsers)

## What this solution is
This solution deploys the **Microsoft Enterprise SSO plug-in** as an Apple **Extensible Single
Sign-On (SSO) app extension** on managed Macs, via a **Microsoft Intune** configuration profile. Once
in place, apps and browsers that authenticate against **Microsoft Entra ID** get **silent, shared
single sign-on** — the user signs in once and the device broker satisfies subsequent Entra sign-ins
across cooperating apps and Safari, without repeated password prompts.

Apple's **Extensible SSO** framework lets a third-party identity provider register a system-wide
authentication extension. Microsoft ships two kinds of extension through the same **Company Portal**
bundle:

- an **app SSO extension** (a **redirect**-type extension) that brokers Entra tokens for **apps and
  browsers** — **this is the subject of this solution**; and
- **Platform SSO** (a **credential**-type extension) that extends Entra sign-in to the **macOS login
  window / device account** — that is a **separate** capability, covered by a different product.

> **Scope, stated plainly.** This solution delivers the **app/browser SSO extension** only. It does
> **not** configure macOS **Platform SSO device login** (Secure Enclave / password-sync / smart-card
> login-window registration). If you want corporate identity **at the Mac login window**, use the
> companion solution *macOS Automated Device Enrollment with SSO* instead of, or in addition to, this
> one. The two are complementary but distinct: this one silences prompts *inside apps and browsers*;
> Platform SSO changes *how the user logs in to the Mac*.

## How Apple Extensible SSO works (the two types)
An Extensible SSO configuration profile carries a **type**:

- **Redirect** — for identity providers that use **OpenID Connect / OAuth 2 redirect** flows
  (Microsoft Entra ID is a redirect IdP). The extension intercepts authentication requests to a
  defined set of **URLs** and completes them silently using the broker. **This solution uses the
  redirect type.**
- **Credential** — for **challenge/response (Kerberos-style)** providers, and the mechanism Apple's
  **Platform SSO** builds on to register the *device/login* identity. **Out of scope here.**

For the Microsoft Enterprise SSO **app** extension we therefore create a **redirect** profile that
names the Microsoft **Entra login URLs**, the extension's **bundle identifier**, and the Apple
**Team ID** — and, optionally, the **app bundle IDs** allowed to use it.

## How it works, step by step
1. **Company Portal delivers the extension binary.** The Microsoft Enterprise SSO extension ships
   inside the **Intune Company Portal** app for macOS. Company Portal must be installed on the device.
2. **Intune deploys the redirect profile.** A **configuration profile** (Settings catalog →
   *Single Sign-On Extension* / SSO app extension) activates the extension, sets its **Extension
   Identifier** `com.microsoft.CompanyPortalMac.ssoextension`, **Team Identifier** `UBF8T346G9`,
   **Type = Redirect**, and the **Entra URLs** the extension should intercept.
3. **First sign-in primes the broker.** The user signs in once to a Microsoft app or web property
   (for example Outlook on the web) with their Entra credentials, optionally completing MFA. The
   extension caches a **Primary Refresh Token (PRT)**–backed session on the device.
4. **Silent SSO afterward.** Subsequent Entra sign-ins from **cooperating apps and Safari** are
   satisfied **silently** by the extension — no password re-entry — until the session expires.
5. **Scoping (optional).** You can restrict which **app bundle IDs** participate, and add extra
   **URLs** or a `AppPrefixAllowList`, so the extension covers exactly the apps/browsers you intend.

## What silent SSO covers (and what it needs)
- **Safari and WebKit-based flows** and **native apps built on the Microsoft Authentication Library
  (MSAL)** or the macOS broker get silent SSO automatically once the extension is active.
- **Non-Microsoft browsers** (Chrome, Edge on macOS, Firefox) get broker SSO **only** when the
  browser supports the macOS SSO extension or ships the Microsoft **SSO browser support** hooks;
  otherwise they fall back to normal interactive sign-in. Best-effort by design — call this out to
  users.
- The device should have the **Microsoft Authenticator** or **Company Portal** identity present so
  the broker can register and issue the PRT.

## Benefits
- **Fewer prompts** — one sign-in, then silent Entra SSO across apps and Safari on the Mac.
- **No login-window change** — deploys a system extension only; it does **not** alter how users log
  in to macOS, so there is no re-imaging or account migration.
- **Fast to pilot** — a single configuration profile plus Company Portal; reversible by unassigning
  the profile.
- **Conditional Access friendly** — the broker session supports device-based Entra policies for the
  apps that use it.
- **Precise scoping** — target exactly the apps/URLs you want via bundle-ID and URL lists.

## Limitations (be honest with buyers)
- **Not device login.** This does not provide macOS login-window SSO — that is **Platform SSO**
  (separate product). Do not expect the Mac account password to sync with Entra here.
- Requires the **Company Portal** app (the extension lives inside it) and a supported macOS release
  (**macOS 10.15+** for the app SSO extension; a current macOS is recommended).
- **Browser coverage varies.** Only browsers with SSO-extension support get silent SSO; others sign
  in normally.
- Apps must use the **Microsoft broker/MSAL** or Safari/WebKit to benefit; legacy apps with embedded
  webviews may not.
- Requires **Microsoft Entra ID** as the IdP and outbound access to the Entra login endpoints.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Managed (Intune-enrolled) Macs receive the Microsoft Enterprise SSO plug-in as a redirect-type
> Extensible SSO app extension, scoped to Entra login URLs (and optionally specific app bundle IDs),
> deployed pilot-first and reversible.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
