# 1. Solution Overview — iOS iPhone Entra ID Shared Device Mode (Frontline SSO)

## What this solution is
This solution configures **Microsoft Entra ID Shared Device Mode (SDM)** on **pooled, shared
iPhones** managed by **Microsoft Intune**, so a frontline worker can walk up to any shift phone,
**sign in once**, use their Microsoft apps as themselves, and **sign out once** at end of shift —
which **clears their identity and app data from every supporting app on the device** for the next
person. It is the identity-session model for shared iPhones: **global sign-in** and **single (global)
sign-out** across apps that support SDM (notably **Microsoft Teams** and MSAL-based line-of-business
apps).

The devices are enrolled **without user affinity** (no single owner), registered into **shared
device mode** through the **Microsoft Authenticator** app, and handed between staff freely. Each
person gets their **own** Entra sign-in on the shared hardware — not a generic shared account.

> **This is not kiosk lockdown, and not a shared service account.** Restricting a phone to one app
> (kiosk/lockdown) or signing everyone in with one shared mailbox does **not** give each worker a
> private session — cached tokens and data from the previous user survive an app sign-out on a
> single-user device. Shared Device Mode exists precisely to solve that: it gives the device a
> **per-user identity session** that global sign-out tears down. (For single-purpose kiosk phones,
> see the separate *iOS iPhone Shared Device Mode (Lockdown) with WebEx* and *iOS Lock-Down Profile*
> solutions — those are a different job.)

## Why iPhones specifically need this
Apple's own multi-user technology — **Shared iPad** with Managed Apple IDs — **only runs on iPad
hardware; it is not available on iPhone.** So for **shared iPhones**, there is no OS-level Apple
multi-user mode to fall back on. **Entra ID Shared Device Mode is the primary way to give shared
iPhones a real per-user sign-in/sign-out experience** within the Microsoft identity stack. (If your
fleet is iPads and you want Apple's OS-level partitioning, use the *Shared iPad for Frontline Teams*
solution instead; if it's iPhones, this is the one.)

## How Shared Device Mode works (the moving pieces)
1. **No-affinity enrollment.** The iPhone is enrolled via **Apple Business Manager + Automated Device
   Enrollment (ADE)** with an enrollment profile set to **enroll without user affinity** — the device
   belongs to the organization, not a person.
2. **Shared-mode registration (the Authenticator step).** The device is registered into **shared
   device mode** through **Microsoft Authenticator**. The account that performs this registration must
   hold the Entra **Cloud Device Administrator** role. Registration is a one-time provisioning action
   at device setup; afterward the device advertises itself as *shared* to apps that support SDM.
3. **SDM-aware apps.** Apps built on the **Microsoft Authentication Library (MSAL)** that opt into SDM
   — first and foremost **Microsoft Teams** for iOS — detect shared mode and switch to the
   global-sign-in / global-sign-out model. A worker signs into Teams; other SDM apps recognize the
   signed-in user; signing out of one signs out of all and clears their data.
4. **Intune delivers everything.** Intune enrolls the device (no affinity), deploys **Microsoft
   Authenticator** and the SDM apps (Teams, your MSAL LOB apps), applies device configuration and
   compliance, and (optionally) a light restriction profile — all targeted at an **assigned device
   group** the shared iPhones land in at enrollment.

## Global sign-in / single sign-out — what actually happens
- **Sign-in:** the worker opens Teams (or another SDM app), signs in with their Entra credentials and
  MFA. That identity becomes the device's **current shared-mode user**; other SDM apps pick it up
  without a second sign-in.
- **Sign-out:** the worker taps sign-out once. SDM performs a **global sign-out** — every SDM app
  drops the session and **clears that user's cached data and tokens** from the device, returning the
  phone to a clean state for the next person.

## What SDM isolates (stated honestly)
- **It isolates the Entra identity session and the data inside SDM-aware apps.** Global sign-out
  clears tokens and app data for SDM apps (Teams and MSAL apps that implement SDM).
- **It does not partition the entire iOS operating system** the way Apple Shared iPad does. Apps that
  are **not** SDM-aware do not participate in global sign-out; treat them accordingly (don't put
  personal-data-caching non-SDM apps on a shared iPhone, or restrict them). Combine SDM with a
  sensible restriction profile so only appropriate apps are present.
- **App support is narrower on iOS than on Android.** On Android, Managed Home Screen and a broad set
  of apps support SDM; on iOS the anchor is **Teams**, plus MSAL LOB apps that explicitly implement
  SDM. **Verify SDM support for each app you intend to deploy** rather than assuming — confirm against
  current Microsoft documentation for your tenant.

## Benefits
- **A real per-user session on shared iPhones** — each worker signs in as themselves; single sign-out
  wipes their session and app data for the next person.
- **The Microsoft-native answer for shared *iPhones*** — where Apple Shared iPad (iPad-only) cannot
  help.
- **Frontline-fit** — fast hand-off, no personal enrollment, no per-device user assignment.
- **Central management** — enrollment, apps, compliance, and restrictions all driven from Intune
  against one assigned device group.
- **Conditional Access aware** — the signed-in user's session supports Entra device/compliance
  policies for the SDM apps.

## Limitations (be honest with buyers)
- **iPhone / no-affinity only.** Targets shared iPhones enrolled without user affinity; it is not for
  single-user corporate phones (see the *Enterprise SSO app extension* solution for those).
- **App coverage is the gating factor.** Only SDM-aware apps (Teams + MSAL apps that implement SDM)
  get global sign-in/out; verify each app.
- **Requires Microsoft Authenticator** for shared-mode registration and the **Cloud Device
  Administrator** role for the registering account.
- **Not full OS multi-user.** SDM is an identity/app-data model, not an Apple OS partition; pair it
  with restrictions.
- Requires **Microsoft Entra ID**, supported iOS, and outbound access to Entra login endpoints.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Shared iPhones are enrolled without user affinity via ABM/ADE into an assigned device group,
> registered into Entra Shared Device Mode through Microsoft Authenticator, and given the SDM apps
> (Teams + MSAL LOB) so frontline workers get global sign-in and single sign-out — deployed
> pilot-first and reversible.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
