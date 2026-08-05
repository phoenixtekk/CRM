# Executive Summary — iOS/iPadOS Enterprise SSO App Extension (COD iPhones)

Users on corporate iPhones still hit repeated sign-in prompts — and repeated MFA — in apps and Safari
because the **Microsoft Enterprise SSO plug-in** isn't deployed as an **app extension**. This solution
deploys that plug-in as an Apple **Extensible Single Sign-On (SSO) app extension** — a
**redirect-type** extension hosted in **Microsoft Authenticator** — via **Microsoft Intune**, so apps
and browsers get **silent, shared single sign-on** to **Microsoft Entra ID**: the user signs in once
and the device broker satisfies subsequent Entra sign-ins across cooperating apps and Safari — no
repeated passwords, no repeat MFA.

**A deliberately scoped, distinct capability.** This is the **app/browser** SSO extension for
**corporate-owned, Intune-enrolled** iPhones/iPads. It is **not** device enrollment (ADE/ABM is a
prerequisite), **not** the two-phone personal+corporate model, and **not** shared-device identity —
each of those is a separate solution. It deploys a single configuration profile, silences prompts
*inside apps and Safari*, and is fully reversible by unassigning the profile — no re-enrollment, no
re-imaging.

The iOS story differs from the Mac in two ways this package makes explicit: the extension is hosted in
**Microsoft Authenticator** (not Company Portal), and iOS offers a one-key coverage lever —
**`Enable_SSO_On_All_ManagedApps`** — that extends SSO to every Intune-managed app at once.

This package delivers the complete, field-tested method to stand it up in Intune — written so a single
administrator can follow it end to end:

- **One profile, one purpose.** An iOS/iPadOS **SSO app extension (Microsoft Entra ID / Redirect)**
  configuration profile carrying the Microsoft Enterprise SSO identifiers, the Entra login URLs, and
  precise **managed-app / URL scoping** — deployed pilot-first.
- **Silent SSO where it counts.** Safari and MSAL/broker-aware apps get silent Entra sign-in after a
  single priming sign-in; browser coverage is set honestly (Safari reliable; others best-effort).
- **Precise, reversible scoping.** `Enable_SSO_On_All_ManagedApps`, `AppPrefixAllowList`, and URL
  lists target exactly the apps and browsers you intend — widen in waves after each gate.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate →
Expand** — with exact, click-by-click Intune steps, a requirements guide that tells you how to verify
*and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and
testing/troubleshooting guides with clear pass/fail gates.

**Outcome:** silent, shared sign-in to Entra apps and browsers across every corporate iPhone — the
Enterprise SSO app extension deployed and proven on a pilot before you scale, without a consulting
engagement, and without touching how the device is enrolled.
