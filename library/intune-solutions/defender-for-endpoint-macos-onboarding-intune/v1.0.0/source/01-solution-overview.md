# 1. Solution Overview — Microsoft Defender for Endpoint for macOS: Deployment & Onboarding via Intune

## What this solution does
Microsoft Defender for Endpoint (MDE) protects macOS with anti-malware, endpoint detection and
response (EDR), network protection, and vulnerability management. But on a Mac, MDE is **not** a
simple app push. macOS deliberately blocks security software from loading kernel/system extensions,
reading the full disk, or filtering network traffic until an administrator has explicitly approved
each of those capabilities. If you push the MDE installer and the onboarding package **before** those
approvals are in place, the agent installs but sits **silently degraded** — extensions not running,
real-time protection off, no EDR sensor — and it will *look* onboarded in the portal while protecting
nothing. This solution delivers the required Apple approval profiles **first**, then the onboarding
configuration, then validates that the agent is genuinely healthy — deployed pilot-first and
rollback-ready through **Microsoft Intune**.

## The macOS deployment model (why order matters)
macOS enforces user/administrator consent for exactly the capabilities MDE needs. When those consent
gates are pre-approved by an MDM (Intune) configuration profile, the user sees no prompts and the
agent works immediately. When they are missing, the user is either prompted (and usually clicks the
wrong thing) or silently blocked. The rule for this entire solution is therefore: **profiles first,
onboarding second, validation third.** The five capability profiles are:

1. **System extensions** — MDE for macOS runs as *system extensions* (the modern replacement for
   kernel extensions). A **System Extensions** configuration profile pre-approves the Microsoft
   Defender team identifier and the specific extension bundle identifiers so they load without a user
   prompt. Without this, the endpoint-security and network extensions never activate.
2. **Full Disk Access (Privacy Preferences Policy Control / PPPC / TCC)** — macOS's Transparency,
   Consent and Control (TCC) framework blocks apps from reading protected files unless granted Full
   Disk Access. MDE needs Full Disk Access to scan the whole file system and to run its endpoint
   security extension. A **PPPC** profile (also called a *Privacy Preferences Policy Control* payload)
   grants it at the MDM level so no user prompt is required.
3. **Network filter (content filter)** — MDE's network protection and web content filtering run as a
   *network extension* that inspects traffic. A **Web content filter** configuration profile
   pre-approves that network extension so traffic filtering can attach. Without it, network protection
   is inert.
4. **Background service management (login items / managed background tasks)** — recent macOS versions
   let users disable an app's background items, which would stop the MDE daemons. A **Managed login
   items / background service management** profile keeps the Microsoft Defender background services
   from being turned off by the user.
5. **Notifications** — so the user actually sees MDE alerts (threat found, action needed) instead of
   silent notifications, a **Notifications** configuration profile pre-approves Microsoft Defender to
   post notifications.

Only **after** those are assigned and applying do you deliver the **onboarding package** — the
tenant-specific blob (`WindowsDefenderATPOnboarding.plist`, delivered inside a `.mobileconfig` /
custom profile) that tells the installed agent which Microsoft Defender tenant to report to — and the
**MDE app** itself (via the Microsoft Defender app in Intune, or a packaged installer).

## The three Intune delivery surfaces on macOS
macOS is configured by Apple **configuration profiles** (`.mobileconfig` payloads) and by apps — not
by Windows constructs. This solution uses three Intune surfaces:
1. **Templates → configuration profiles** — the System Extensions, PPPC/Full Disk Access, Web content
   filter, Notifications, and Managed login items payloads are delivered as Intune macOS configuration
   profiles (Settings catalog where the payload is exposed, or Templates → Custom with a
   `.mobileconfig` where it is not).
2. **Custom `.mobileconfig` (onboarding)** — the MDE onboarding package is delivered as a **custom**
   macOS configuration profile carrying the onboarding payload.
3. **App deployment** — the **Microsoft Defender** app is deployed via Intune (Apps → macOS →
   Microsoft Defender, or a packaged `.pkg`/DMG app).

## Onboard-then-verify: the health model
Getting a green "onboarded" tick in the Microsoft Defender portal is not the same as being protected.
This solution treats **health** as the real finish line: after onboarding you confirm the system and
network extensions are **running**, real-time protection is **on**, the device appears in the
Microsoft Defender portal (`https://security.microsoft.com`) as **onboarded and active**, and the
built-in health check (`mdatp health`) reports healthy. The included scripts read the Intune side of
this (profile apply state, app install state, device enrollment) so you can prove the management-plane
prerequisites are in place, and the guides show the on-device `mdatp` commands that prove the agent
itself is healthy.

## Benefits
- **Onboarded correctly, not just installed** — the required Apple approvals land *before* onboarding,
  so the agent is genuinely protecting the Mac rather than silently degraded.
- **No end-user prompts** — every consent gate (extensions, Full Disk Access, network filter,
  background items, notifications) is pre-approved by MDM, so users aren't asked to make security
  decisions.
- **Provable health** — validation confirms extensions running, real-time protection on, and the
  device active in the Microsoft Defender portal.
- **Safe rollout** — piloted on a small group and validated before fleet-wide, with a documented
  rollback because a bad onboarding or a missing approval is easy to correct when caught early.

## Limitations (be honest with buyers)
- The exact Microsoft Defender **team identifier**, **extension bundle identifiers**, **code
  requirement strings**, and the **onboarding package** are Microsoft-published values — this solution
  gives the correct procedure and object names; where a specific identifier is required it is clearly
  marked as *obtain from the current Microsoft documentation / your onboarding download*, not invented.
- MDE licensing and a working macOS enrollment are prerequisites, not part of this solution.
- Some macOS versions surface these payloads differently (Settings catalog vs custom `.mobileconfig`);
  the implementation flags where a custom profile may be required.

## The deployment model
> Deliver the System Extensions, Full Disk Access (PPPC/TCC), Network filter, Background services, and
> Notifications profiles **first**; then deploy the MDE app and the onboarding package; then validate
> the agent is healthy — on a pilot, before you expand. The repeatable way:
> **Assess → Configure → Pilot → Validate → Expand.**
