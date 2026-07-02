# 1. Solution Overview — iOS Lock-Down Profile for Shared iPhones (and Corporate iPhones)

## The two-device reality
Most organizations hand out iPhones in **two distinct ways**, and they need to be managed
differently:

- **Shared devices** — a phone that anyone on shift picks up, uses, and hands back. No single
  person owns it. It must stay **clean, consistent, and limited to what the job needs**, and it must
  not get tied to whoever happened to set it up.
- **Corporate devices** — a phone **assigned to one person**. It needs management and security, but a
  **lighter, user-owned** experience where the user signs in with their own identity and installs
  approved apps.

This solution delivers a repeatable **iOS lock-down profile for shared iPhones in Microsoft Intune**,
*and* the full provisioning and login model for **both** shared and corporate devices — so staff know
exactly how to pick up, sign in to, and use each kind of phone.

## What an iOS lock-down profile is
A "lock-down profile" is not a single Intune object — it is a small, named set of policies applied to
the shared phones:

1. A **Device restrictions** configuration profile (supervised restrictions) that **strips iOS down**
   to what the job needs: block the App Store, Safari, app install/remove, account modification, and
   "Erase all content and settings"; keep Wi-Fi, cellular/calling, and the apps the role requires.
2. An **optional Kiosk** profile — **single-app** (the phone runs exactly one app full-screen) or
   **multi-app** (a curated home screen of a few approved apps) — for the most locked-down use cases.
3. A **compliance** policy and (optionally) a **Conditional Access** policy so only a healthy, managed
   phone is trusted.

Corporate phones get a **lighter** version: a baseline device-restrictions profile, compliance, and
(optionally) app-protection — security without turning a personal-use device into an appliance.

## The two provisioning models (this is the key decision)
Both kinds of phone are supervised and enrolled through **Apple Business Manager (ABM)** with
**Automated Device Enrollment (ADE)**. The difference is **user affinity**, set on the ADE enrollment
profile:

| | Shared device | Corporate device |
|---|---|---|
| ADE enrollment profile | `iOS Shared – ADE – Pilot` | `iOS Corporate – ADE – Pilot` |
| User affinity | **Enroll without user affinity** (no primary user) | **Enroll with user affinity** (user signs in) |
| Supervised | Yes | Yes |
| Locked enrollment | Yes (can't remove management) | Yes |
| Identity | A **shared/managed account** signed into the apps | The **user's own Entra ID** |
| Lock-down | Restrictions + optional Kiosk | Lighter baseline restrictions |

## A note on "shared" on iPhone (be accurate)
iPhones do **not** support Apple **Shared iPad** (the multi-user, per-user-partition feature is
iPad-only). On iPhone, "shared" means: the device has **no user affinity** (no primary user), it is
**locked down** with restrictions and optionally a kiosk, and staff **sign into the apps** with a
**shared/managed account** rather than logging into the device itself. This solution implements that
model correctly and does not pretend iPhones have Shared iPad.

## How an end user experiences each device
- **Shared phone:** pick it up, it is already on the locked-down home screen (or kiosk app), do the
  job, hand it back. Where an app needs identity, staff sign in with the **shared/managed account**.
  At hand-back the next person finds the phone in the same clean state.
- **Corporate phone:** the user runs Setup Assistant once, **signs in with their own Entra ID**, the
  phone enrolls assigned to them, the baseline profile and approved apps arrive, and they use it as
  their day-to-day work phone.

(The full step-by-step for both is in the **Use & Login Guide**, Section 4.)

## Benefits
- **Shared phones stay clean** — restrictions/kiosk keep them limited to the job and free of drift.
- **Not tied to one setter** — no-user-affinity enrollment means no phone is "owned" by whoever set it up.
- **Corporate stays light** — assigned phones get security without an appliance lock-down.
- **Clear for staff** — everyone knows how to provision, sign in to, and use each device type.
- **Fleet-scale and reportable** — one group + one policy set per model; per-device and fleet posture
  reporting.

## Limitations (be honest with buyers)
- True kiosk single/multi-app lock-down requires **supervised** devices (ABM + ADE, or Apple Configurator).
- iPhones have **no Shared iPad** multi-user mode — shared identity lives in the apps, not the OS.
- A shared sign-in account is a shared credential; protect it (Conditional Access, rotation) and prefer
  app-level SSO where the app supports it.
- ADE is **zero-touch only on devices added to ABM**; phones bought outside ABM need Apple Configurator
  to supervise.

## The standard deployment model
> **Connect Apple (APNs + ADE) → create the shared no-affinity and corporate user-affinity enrollment
> profiles → build the lock-down (restrictions + optional kiosk) for shared and the lighter baseline
> for corporate → add compliance and access → pilot one of each → validate → expand.**
> repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
