# 1. Solution Overview — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

## What this solution is
This solution targets a specific, very common reality: **one person carries two iPhones** — a
**personal iPhone (BYOD)** they own and a **corporate iPhone (COD)** the company owns — and needs the
**same single work account to sign in seamlessly on both**, with the right level of management applied
to each. Think of the executive who carries a company iPhone for work and their own iPhone for life,
the clinician or field tech issued a corporate handset who still uses a personal one, or the hybrid
employee who answers Teams on either phone — all under one identity.

It delivers that in Microsoft Intune under **one Microsoft Entra identity**, across the two iOS
ownership models:

1. **Corporate iPhone (COD)** — the iPhone the organization buys and owns. Enrolled **supervised via
   Apple Business Manager + Automated Device Enrollment (ADE)**, fully managed in Intune (MDM); it
   receives configuration and compliance policies and the iOS Enterprise SSO extension.
2. **Personal iPhone (BYOD)** — the iPhone the employee owns. The corporate **identity and data** are
   protected without taking over the personal phone, primarily through **App Protection Policies
   (MAM)**, with optional lightweight **Account-Driven Apple User Enrollment**.

The defining design goal: **the user signs in with one Entra account on both iPhones and gets a single
sign-on experience** — Intune applies controls based on **device ownership**, not on a second account,
so the personal iPhone is protected (data-only) while the corporate iPhone is fully managed,
simultaneously, for the same person.

## How it works
1. **One identity, two iPhones.** The user has a single Microsoft Entra account. That one account
   enrolls their corporate iPhone **and** signs into the managed work apps on their personal iPhone —
   there is no separate "BYOD account," and both iPhones register to the same identity.
2. **Single sign-on across both.** On iOS the **Microsoft Authenticator** app is the identity broker;
   on the corporate iPhone the **iOS Enterprise SSO extension** (deployed by Intune) extends that SSO
   to Safari and other apps. The user signs in once per iPhone, then moves between Microsoft 365 and
   SSO-enabled apps without re-entering credentials.
3. **Ownership is tagged.** Each iPhone is marked **Corporate** (ADE-enrolled) or **Personal**
   (App Protection / User Enrollment defaults).
4. **Ownership-based targeting.** Policies are assigned to the **user**, then scoped with **iOS device
   filters** on `deviceOwnership` so the user's two iPhones each get the correct set:
   - the user's **Corporate** iPhone receives full **device compliance** + **configuration** policies
     and the **Enterprise SSO extension**;
   - the user's **Personal** iPhone receives **App Protection (MAM)** policies that encrypt corporate
     data, enforce a PIN, and block copy/paste or "Save As" to personal locations.
5. **Conditional Access ties it together.** A single Conditional Access policy for the user grants
   access when the request comes from their **compliant corporate iPhone** *or* from an **approved app
   with an app-protection policy** on their personal iPhone — so the one account works securely from
   **either** of the user's two iPhones.

## Single sign-on across the user's two iPhones
Because both iPhones register to the **same Entra identity**, the user gets a unified sign-in:
- **Corporate iPhone:** supervised and Entra-registered; the **iOS Enterprise SSO extension** (the
  Microsoft Entra ID plug-in, brokered by Authenticator) gives **silent SSO** to Microsoft 365, Entra
  apps, and Safari — no repeated passwords.
- **Personal iPhone:** the **Microsoft Authenticator** broker (registered during app-protection
  onboarding) brokers Entra auth, so Outlook/Edge/Teams and other approved apps get silent SSO with
  the same account.
- **Consistent posture either way:** Conditional Access evaluates each iPhone on its own merits
  (compliant COD *or* MAM-protected BYOD), so the single account is honored from both without the user
  ever managing two logins.

## Management models (choose per ownership)
- **Corporate iPhone — full MDM (supervised ADE):** complete device management, configuration
  profiles, compliance, and zero-touch provisioning via Apple Business Manager + Automated Device
  Enrollment.
- **Personal iPhone — App Protection / MAM (recommended):** secures corporate data *inside* managed
  apps with no full device enrollment; least intrusive for employees, strong data-leak protection.
- **Personal iPhone — Account-Driven User Enrollment (optional):** when a personal iPhone must receive
  a few device settings while keeping personal data separate; still tagged Personal and scoped
  accordingly.

This solution standardizes on **supervised full MDM for the corporate iPhone** and **App Protection
for the personal iPhone**, with Account-Driven User Enrollment called out as an option.

## Benefits
- **One account on both of the user's iPhones** — no duplicate identities; the same login on the
  personal and the corporate iPhone.
- **Seamless single sign-on** — sign in once per iPhone, then move between Microsoft 365 apps (and
  between the two phones) without re-entering credentials.
- **Right-sized control** — full management on the corporate iPhone; data-only protection on the
  personal one — at the same time, for the same person.
- **Lower friction BYOD** — employees keep their personal iPhone private; corporate data stays
  contained in managed apps.
- **Consistent security** — compliance for the corporate iPhone, app protection for the personal one,
  unified by one Conditional Access policy that accepts either iPhone.
- **Scales cleanly** — ownership-based targeting means you assign once to the user and the right policy
  follows each of their iPhones.

## Limitations (be honest with buyers)
- **App Protection (MAM)** secures data **inside supported apps** (Microsoft 365 and SDK-enabled
  apps); it does not manage the whole personal iPhone or unmanaged apps.
- BYOD users must use the **managed/approved apps** (e.g. Outlook, Edge, Teams) to get corporate data;
  the built-in personal Mail/Safari apps are blocked from corporate data by design.
- Supervised corporate-iPhone enrollment requires the device to be in **Apple Business Manager** (ADE);
  iPhones not in ABM can still enroll, but not supervised/zero-touch.
- The iOS **Enterprise SSO extension** requires **Microsoft Authenticator** present on the device, and
  silent SSO applies to Entra-integrated apps.
- A user signing in on a brand-new iPhone enrolls/registers that device the first time.

## The standard deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **One Microsoft Entra identity per user, signed in across that user's two iPhones with single
> sign-on; the corporate iPhone under supervised full MDM (ABM + ADE) and the personal iPhone under
> App Protection (MAM); ownership-based targeting routes the right policy to each; a single Conditional
> Access policy governs access from both.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
