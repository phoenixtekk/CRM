# 1. Solution Overview — Dual-Device (Personal + Corporate) Management with Single Sign-On

## What this solution is
This solution targets a specific, very common reality: **one person carries two devices** — a
**personal device (BYOD)** they own and a **corporate-owned device (COD)** the company owns — and
needs the **same single work account to sign in seamlessly on both**, with the right level of
management applied to each. Think of the executive with a corporate laptop and a personal phone, the
field tech with a company tablet and their own handset, or the hybrid employee who answers Teams on
their personal device and does focused work on the corporate one.

It delivers that in Microsoft Intune under **one Microsoft Entra identity**, across the two
ownership models:

1. **Corporate-Owned Device (COD)** — the device the organization buys and owns. Fully enrolled in
   Intune (MDM), receives configuration and compliance policies, managed end to end by IT.
2. **Personal Device (BYOD)** — the device the employee owns. The corporate **identity and data** are
   protected without taking over the personal device, primarily through **App Protection Policies
   (MAM)**, with optional lightweight personal MDM enrollment.

The defining design goal: **the user signs in with one Entra account on both of their devices and
gets a single sign-on experience** — Intune applies controls based on **device ownership**, not on a
second account, so the personal device is protected (data-only) while the corporate device is fully
managed, simultaneously, for the same person.

## How it works
1. **One identity, two devices.** The user has a single Microsoft Entra account. That one account
   registers/enrolls their corporate device **and** signs into the managed work apps on their personal
   device — there is no separate "BYOD account," and both devices register to the same identity.
2. **Single sign-on across both.** Once the account is established on a device, the **Microsoft
   identity broker** (Microsoft Authenticator / Company Portal on the personal device; Entra-joined
   WAM on the corporate device) gives the user **silent SSO** into Microsoft 365 and SSO-enabled apps
   on each device — sign in once per device, then move between them without re-entering credentials.
3. **Ownership is tagged.** Every device is marked **Corporate** or **Personal** (by enrollment
   method, corporate device identifiers, or enrollment-restriction defaults).
4. **Ownership-based targeting.** Policies are assigned to the **user**, then scoped with **device
   filters** on `deviceOwnership` so the user's two devices each get the correct set:
   - the user's **Corporate** device receives full **device compliance** + **configuration** policies;
   - the user's **Personal** device receives **App Protection (MAM)** policies that encrypt corporate
     data, enforce a PIN, and block copy/paste or "Save As" to personal locations.
5. **Conditional Access ties it together.** A single Conditional Access policy for the user grants
   access when the request comes from their **compliant corporate device** *or* from an **approved app
   with an app-protection policy** on their personal device — so the one account works securely from
   **either** of the user's two devices.

## Single sign-on across the user's two devices
Because both devices register to the **same Entra identity**, the user gets a unified sign-in:
- **Corporate device:** Entra-joined (or hybrid-joined); Windows sign-in / the WAM broker provides
  primary-refresh-token (PRT) based SSO to Microsoft 365 and Entra apps — no repeated passwords.
- **Personal device:** the **Microsoft Authenticator** broker (registered via Company Portal during
  app-protection onboarding) brokers Entra auth, so Outlook/Edge/Teams and other approved apps get
  silent SSO with the same account.
- **Consistent posture either way:** Conditional Access evaluates each device on its own merits
  (compliant COD *or* MAM-protected BYOD), so the single account is honored from both without the user
  ever managing two logins.

## Management models (choose per ownership)
- **COD — full MDM:** complete device management, configuration profiles, compliance, and (optionally)
  Autopilot/ADE/Android Enterprise corporate enrollment for zero-touch provisioning.
- **BYOD — App Protection / MAM (recommended):** secures corporate data *inside* managed apps with no
  full device enrollment; least intrusive for employees, strong data-leak protection.
- **BYOD — personal MDM enrollment (optional):** when a personal device must receive a few device
  settings; still tagged Personal and scoped accordingly.

This solution standardizes on **full MDM for COD** and **App Protection for BYOD**, with personal MDM
called out as an option.

## Benefits
- **One account on both of the user's devices** — no duplicate identities; the same login on the
  personal and the corporate device.
- **Seamless single sign-on** — sign in once per device, then move between Microsoft 365 apps (and
  between the two devices) without re-entering credentials.
- **Right-sized control** — full management on the corporate device; data-only protection on the
  personal one — at the same time, for the same person.
- **Lower friction BYOD** — employees keep their personal device private; corporate data stays
  contained in managed apps.
- **Consistent security** — compliance for COD, app protection for BYOD, unified by one Conditional
  Access policy that accepts either device.
- **Scales cleanly** — ownership-based targeting means you assign once to the user and the right policy
  follows each of their devices.

## Limitations (be honest with buyers)
- **App Protection (MAM)** secures data **inside supported apps** (Microsoft 365 and SDK-enabled
  apps); it does not manage the whole personal device or unmanaged apps.
- BYOD users must use the **managed/approved apps** (e.g. Outlook, Edge, Teams) to get corporate data;
  built-in personal mail/browser apps are blocked from corporate data by design.
- COD zero-touch provisioning (Autopilot/ADE/Android Enterprise) is referenced but each platform's
  full enrollment is covered by its own Phoenixtekk solution; this solution unifies the **model**.
- A user signing in on a brand-new device enrolls/registers that device the first time.

## The standard Phoenixtekk deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **One Microsoft Entra identity per user, signed in across that user's two devices with single
> sign-on; the corporate-owned device under full MDM and the personal device under App Protection
> (MAM); ownership-based targeting routes the right policy to each; a single Conditional Access policy
> governs access from both.**

Every step follows the Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**
