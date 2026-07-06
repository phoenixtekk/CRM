# Executive Summary — macOS Enterprise SSO App Extension (Apps & Browsers)

Users on managed Macs still hit repeated sign-in prompts in apps and Safari because the **Microsoft
Enterprise SSO plug-in** isn't deployed as an **app extension**. This solution deploys that plug-in as
an Apple **Extensible Single Sign-On (SSO) app extension** — a **redirect-type** extension — via
**Microsoft Intune**, so apps and browsers get **silent, shared single sign-on** to **Microsoft Entra
ID**: the user signs in once and the device broker satisfies subsequent Entra sign-ins across
cooperating apps and Safari — no repeated passwords.

**A deliberately scoped, distinct capability.** This is the **app/browser** SSO extension. It is
**not** macOS **Platform SSO device login** (that changes how users sign in to the Mac itself and is a
separate solution). This one deploys a single system-extension profile, silences prompts *inside apps
and browsers*, and is fully reversible by unassigning the profile — no re-imaging, no account
migration, no login-window change.

This package delivers the complete, field-tested method to stand it up in Intune — written so a single
administrator can follow it end to end:

- **One profile, one purpose.** A macOS **SSO app extension (Redirect)** configuration profile
  carrying the Microsoft Enterprise SSO identifiers, the Entra login URLs, and precise **app-bundle /
  URL scoping** — deployed pilot-first.
- **Silent SSO where it counts.** Safari and MSAL/broker-aware apps get silent Entra sign-in after a
  single priming sign-in; browser coverage is set honestly (Safari reliable; others best-effort).
- **Precise, reversible scoping.** `AppPrefixAllowList`, URL lists, and block lists target exactly the
  apps and browsers you intend — widen in waves after each gate.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate →
Expand** — with exact, click-by-click Intune steps, a requirements guide that tells you how to verify
*and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and
testing/troubleshooting guides with clear pass/fail gates.

**Outcome:** silent, shared sign-in to Entra apps and browsers across every managed Mac — the
Enterprise SSO app extension deployed and proven on a pilot before you scale, without a consulting
engagement, and without touching how users log in to the Mac.
