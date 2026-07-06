# 1. Solution Overview — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

## What this solution is
Your people want to reach company email, files, and apps from their **own** Macs. You need that
data protected without seizing control of a device you don't own. This solution builds a
**macOS BYOD (Bring-Your-Own-Device) strategy** in **Microsoft Intune** and **Microsoft Entra ID**
that does three things, in the right order:

1. **Enroll personal Macs with the lightest footprint that still gives you control** — Apple's
   **account-driven user enrollment**, which manages a *managed Apple Account* and corporate apps/data
   on the Mac while leaving the user's personal apps, data, and identity untouched.
2. **Gate access on device state** — a named **Conditional Access** policy that only lets a Mac reach
   Microsoft 365 when it is **compliant** (and enrolled), so an unmanaged or unhealthy Mac is turned away.
3. **Tell the honest truth about "app protection" on macOS** — because the biggest mistake buyers make
   here is assuming macOS works like iOS/Android. It does not (see the honest note below).

The result: company data is protected on non-corporate Macs, using the right enrollment model and a
compliance gate — deployed pilot-first and rollback-ready — **without over-managing the user's device**.

## The honest macOS app-protection note (read this first)
On **iOS and Android**, Intune **App Protection Policies (APP / "MAM")** can protect corporate data
*inside* individual apps (Outlook, Teams, Edge) — encryption, copy/paste limits, a PIN, and selective
wipe of company data — **without enrolling the device at all**. It is tempting to assume the same is
available for BYOD Macs. **It is not.**

- **Intune App Protection Policies do NOT cover macOS apps the way they do iOS/Android.** There is no
  equivalent per-app "MAM without enrollment" containerization for arbitrary Mac apps. The APP policy
  types you see for iOS/Android are not the macOS story.
- On **macOS**, corporate-data protection comes from a **different place**: the device being **enrolled
  and in scope for MDM** (so you can push configuration, encryption, and compliance signals) **plus
  Conditional Access** (so only a compliant/enrolled Mac is allowed to reach the data in the first place).
- In practical terms: **the protection boundary on a BYOD Mac is the enrollment + compliance +
  Conditional Access combination, not an iOS-style in-app container.** If you need data protected on a
  Mac, the Mac must be **enrolled** and **compliant**, and access must be **gated**.

Everywhere this guide says "protect company data on a personal Mac," that is what it means. We will not
overclaim macOS MAM, and neither should your internal messaging to users.

## The three BYOD models for Macs (choose deliberately)
There is no single "BYOD" setting — there are three postures, each with a different management
footprint and a different protection story. Pick per your risk appetite; this solution **standardizes
on account-driven user enrollment** as the default, with the other two documented so you choose with
eyes open.

### Model A — Account-driven **user enrollment** (this solution's default)
- **What it is:** The user opens **Settings → (their name area) → Sign in to Work or School account**
  and signs in with their **Entra ID**. macOS creates a **managed Apple Account** and a **separate,
  cryptographically isolated APFS volume** for managed data; corporate apps and data live there,
  personal data stays personal.
- **Footprint:** **Light.** No supervision, no device serial required, no wipe of the whole Mac —
  only the **managed** data can be removed. Users keep their personal Apple ID and privacy.
- **What you get:** MDM management of the *corporate* scope, a compliance signal, and Entra device
  registration — enough to drive **Conditional Access**.
- **Best for:** Personal Macs where you want data protected and access gated, but must respect that
  the device is the user's own.

### Model B — **Device enrollment** (BYOD, but fuller management)
- **What it is:** The user enrolls the whole Mac via the **Company Portal** app (Intune's standard
  macOS device enrollment). The **entire device** comes under MDM.
- **Footprint:** **Heavier.** You manage the whole Mac (not just a corporate volume). It is *not*
  supervised (that requires company ownership / ADE), but you can push broader configuration and, if
  needed, wipe the device.
- **Best for:** Personal Macs where the user accepts fuller management in exchange for full access —
  or where user enrollment's constraints don't fit. More footprint than most BYOD users will accept.

### Model C — **Unmanaged + Conditional Access only** (no enrollment)
- **What it is:** The Mac is **not enrolled** at all. You lean on **Conditional Access** (e.g. require
  MFA, or restrict to browser-only sessions with app-enforced restrictions) to limit what an unmanaged
  Mac can do.
- **Footprint:** **None on the device** — but also **no device-health signal**, so you cannot require
  *compliance* (there's nothing reporting it). Protection is limited to identity-layer controls.
- **Best for:** Low-risk access, contractors, or a stopgap. **Cannot** satisfy a "require compliant
  device" policy, because an unmanaged Mac has no compliance state.

> **This solution builds Model A** (account-driven user enrollment) and gates it with Conditional
> Access requiring **compliant** (and enrolled) Macs. Model C is covered so you understand what you
> give up by *not* enrolling; Model B is the fallback when user enrollment doesn't fit.

## How account-driven user enrollment works (Model A, step by step)
1. **Tenant readiness.** macOS enrollment is allowed, and account-driven **user** enrollment is enabled
   as the platform's enrollment type (Implementation §Phase 1). You do **not** need Apple Business
   Manager for this model — it is identity-driven, not device-serial-driven.
2. **User initiates from the Mac.** In **System Settings**, the user adds their **Work or School
   account** (their Entra ID). This is user-initiated by design — you are not seizing the device.
3. **Managed Apple Account + isolated volume.** macOS provisions a **managed Apple Account** and a
   **separate managed APFS volume**. Corporate apps/data are placed there; personal data is not touched.
4. **MDM applies the corporate scope.** Intune pushes the configuration and compliance policy scoped to
   BYOD, and the Mac reports a **compliance state**. The Mac registers with **Entra ID** as a device.
5. **Conditional Access gates access.** Your named CA policy checks: is this Mac **compliant** (and
   enrolled)? If yes, access to Microsoft 365 is allowed; if no, it is blocked or challenged.
6. **Un-enrollment = selective removal.** When the user removes the work account (or you retire it),
   only the **managed** volume/data is removed — the personal Mac stays intact.

## Benefits
- **Least footprint that still protects data** — manage the corporate scope, not the user's whole Mac.
- **Access gated on device health** — Conditional Access allows only compliant, enrolled Macs.
- **Privacy-respecting** — personal apps, data, and Apple ID stay the user's; only managed data is
  ever removed.
- **No Apple Business Manager required** for the user-enrollment model — identity-driven onboarding.
- **Honest, defensible model** — you protect data the way macOS actually supports it, not with an
  iOS-style promise you can't keep.
- **Pilot-first and rollback-ready** — every step is scoped to a pilot group and reversible.

## Limitations (be honest with buyers)
- **No iOS-style app protection on macOS.** As above — protection is enrollment + compliance +
  Conditional Access, **not** per-app MAM containers for arbitrary Mac apps.
- **Account-driven user enrollment requires a recent macOS.** Account-driven **user** enrollment is a
  modern macOS capability; older Macs may only support device enrollment (Model B). Confirm your OS
  floor in Requirements (R-OS) and flag anything below it rather than assuming.
- **User-initiated by design.** You cannot silently push user enrollment onto a personal Mac — the
  user adds the work account. Your rollout must include user communication.
- **Unmanaged Macs can't be "compliant."** If you choose Model C, a require-compliance CA policy will
  block those Macs — that is expected, not a bug.
- **Conditional Access can lock people out if misconfigured.** Always deploy CA in **report-only**
  first, with break-glass accounts excluded (Best Practices).

## The standard deployment model
This solution uses **one** primary model so the process is repeatable across our catalog:

> **Personal (BYOD) Macs onboarded with account-driven user enrollment into Microsoft Intune, scoped
> to a BYOD compliance policy, and gated by a named Conditional Access policy that requires a compliant
> (enrolled) Mac — piloted, validated, then expanded.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
