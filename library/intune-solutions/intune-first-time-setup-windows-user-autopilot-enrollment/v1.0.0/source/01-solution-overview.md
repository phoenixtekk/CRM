# 1. Solution Overview — Microsoft Intune First-Time Setup for Windows

## What this is
This is the **first-time, beginner setup** for managing **Windows** with Microsoft Intune. It assumes
Intune is switched on for your tenant (if it is not, do the free **Enable Microsoft Intune Quick-Start**
first) and gets your **first Windows PCs enrolled two complementary ways**:

- **User-driven enrollment** — a user takes an existing Windows PC, joins it to **Microsoft Entra ID**,
  and the PC **automatically enrolls** into Intune. Best for PCs already in someone's hands.
- **Basic Windows Autopilot (Entra-ID joined)** — a **new or freshly reset** PC provisions itself into
  a managed state during the out-of-box experience (OOBE), zero-touch. Best for new devices you want to
  ship straight to a user.

Both paths land the device in the same place: **Microsoft Entra joined, enrolled in Intune, managed,
and reporting compliant.**

## Scope — deliberately basic
- **Windows only.** No iOS/iPadOS, macOS, or Android here.
- **Microsoft Entra ID–joined only** (cloud join). **Hybrid Microsoft Entra join is out of scope.**
- **A first pilot**, not a production hardening. You enroll one PC each way and validate, using a small
  named pilot footprint you can expand later.

## How Windows enrollment works (the short version)
1. **Identity first.** Every user and device is an object in **Microsoft Entra ID**. Intune trusts Entra
   for who the user is and which device is theirs.
2. **Licensing enables enrollment.** The enrolling user must hold an **Intune license**.
3. **Automatic enrollment** is a tenant switch: when a Windows device Entra-joins, it enrolls into Intune
   automatically (no separate step for the user).
4. **User-driven** = a user Entra-joins an existing PC (**Settings → Accounts → Access work or school**)
   and it auto-enrolls.
5. **Autopilot** = the device's **hardware hash** is registered ahead of time; at OOBE the device fetches
   its **deployment profile**, Entra-joins, MDM-enrolls, and an **Enrollment Status Page (ESP)** tracks
   setup until the device is ready.
6. **Policy and compliance** apply at every check-in; **reporting** proves state in the admin center.

## Autopilot deployment modes (this solution standardizes on the first)
- **User-driven, Microsoft Entra joined** — the user drives OOBE; simplest and most common. **(Used
  here.)**
- Self-deploying (kiosk/shared, no user) — out of scope.
- Pre-provisioning ("white glove") for IT/partner staging — out of scope.
- Hybrid Entra join — **out of scope** (see the deeper Autopilot catalog solutions).

## The objects you will create (named once, reused everywhere)
| Object | Name to use | Notes |
|---|---|---|
| Pilot **user** group (Entra security, Assigned) | `INTBASE - Windows Users - Pilot` | Scopes auto-enrollment + compliance to pilot users. |
| Autopilot **device** group (Entra security, **Assigned**) | `INTBASE - Autopilot Devices` | Enrollment-time targeting; see the ownership note below. |
| Autopilot **deployment profile** | `INTBASE - Autopilot - Pilot` | User-driven, Entra join. |
| **Enrollment Status Page** | `INTBASE - ESP - Pilot` | Minimal; blocks nothing heavy on the pilot. |
| **Windows enrollment restriction** | `INTBASE - Windows Enrollment - Pilot` | Allow Windows; a sensible personal-device stance. |
| **Compliance policy** | `INTBASE - Compliance - Windows Pilot` | Minimal baseline so devices report compliant. |

> **Enrollment-time grouping (important):** the Autopilot device group `INTBASE - Autopilot Devices`
> is an **Assigned** group (not Dynamic), and the **Intune Provisioning Client** first-party service
> principal (AppId `f1346770-5b25-470b-88bd-d5744ab7952c`, shown in many tenants as *Intune Autopilot
> ConfidentialClient*) must be an **Owner** of it. Enrollment-time device grouping works by this
> principal *owning* the assigned group; without the owner the group stays empty at enrollment and
> nothing deploys. This is covered as a step and a prerequisite.

## Benefits
- **Two enrollment paths from one setup** — cover PCs already in use *and* brand-new devices.
- **Zero-touch for new devices** — ship straight to users; no technician imaging.
- **Consistent, named objects** — easy to audit and clean up.
- **Pilot-first** — prove it works on one device each way before you expand.

## Limitations (be honest with buyers)
- Windows editions must be **Pro, Enterprise, or Education** — **not Home**.
- Autopilot devices must be **registered** (hardware hash) before the profile applies.
- OOBE requires **internet** and reachable Entra/Intune endpoints.
- **Entra-joined only** — Hybrid Entra join, advanced/multi-profile Autopilot, and deep ESP tuning are
  out of scope (deferred to the deeper Autopilot catalog solutions).

## Government (GCC / GCC High / DoD) note
US Government tenants use **different portals and endpoints**: Intune admin center at
`https://intune.microsoft.us`, Microsoft Entra at `https://entra.microsoft.us`, sign-in at
`login.microsoftonline.us`, and Microsoft Graph at `https://graph.microsoft.us`
(`Connect-MgGraph -Environment USGov`, or `USGovDoD` for DoD). The steps are otherwise the same, but
**Autopilot and enrollment feature timing can differ in GCC High/DoD** — where a difference is
uncertain, follow the Commercial path and **verify for GCC High** against Microsoft's US sovereign-cloud
documentation rather than assuming parity.

## Auth and connections used
- **Microsoft Intune admin center** (`https://intune.microsoft.com`) — enrollment settings, Autopilot,
  ESP, compliance.
- **Microsoft Entra admin center** (`https://entra.microsoft.com`) — licensing, groups, auto-enrollment
  scope, service-principal ownership.
- **Microsoft Graph PowerShell** (optional) — the included scripts use it **read-only** to verify and
  report state (remediation defaults to a safe `-WhatIf` preview).
- You act as a **Global Administrator** (first-time tenant changes) or an **Intune Administrator**.

## The standard deployment model
> **Enable auto-enrollment → create pilot groups → configure user-driven enrollment → register + build
> basic Autopilot (profile + ESP) → enroll one PC each way → validate → expand.**
> Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
