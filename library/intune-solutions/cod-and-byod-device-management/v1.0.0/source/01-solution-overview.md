# 1. Solution Overview — Corporate-Owned (COD) & BYOD Device Management

## What this solution is
A unified way to manage **two device-ownership models** in Microsoft Intune under **one Microsoft
Entra identity**:

1. **Corporate-Owned Devices (COD)** — devices the organization buys and owns. They are fully
   enrolled in Intune (MDM), receive configuration and compliance policies, and are managed end to
   end by IT.
2. **Bring Your Own Device (BYOD)** — personal devices the employee owns. The corporate **identity
   and data** are managed without taking over the personal device, primarily through **App
   Protection Policies (MAM)**, with optional lightweight personal MDM enrollment.

The defining design goal of this solution: **the same user account signs in on both device types.**
A user authenticates with their single Entra ID everywhere; Intune applies the correct controls to
each device based on **ownership**, not on a second account.

## How it works
1. **One identity.** Each user has a single Microsoft Entra account. That account is what enrolls the
   corporate device and what signs into work apps on the personal device — there is no separate
   "BYOD account."
2. **Ownership is tagged.** Every enrolled device is marked **Corporate** or **Personal** (by
   enrollment method, corporate device identifiers, or enrollment-restriction defaults).
3. **Ownership-based targeting.** Policies are assigned to the **user** (or a user group), then scoped
   with **device filters** on `deviceOwnership` so:
   - **Corporate** devices receive full **device compliance** + **configuration** policies.
   - **Personal** devices receive **App Protection (MAM)** policies that encrypt corporate data,
     enforce a PIN, and block copy/paste or "Save As" to personal locations.
4. **Conditional Access ties it together.** A single Conditional Access policy for the user grants
   access when the request comes from a **compliant corporate device** *or* from an **approved app
   with an app-protection policy** on a personal device — so the one account works securely from both.

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
- **One account, both devices** — no duplicate identities; users sign in with what they already know.
- **Right-sized control** — full management where IT owns the device; data-only protection where the
  employee does.
- **Lower friction BYOD** — employees keep their device private; corporate data stays contained.
- **Consistent security** — compliance for COD, app protection for BYOD, unified by Conditional Access.
- **Scales cleanly** — ownership-based targeting means you assign once to the user and the right policy
  follows the device.

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

> **One Microsoft Entra identity per user; corporate-owned devices under full MDM and personal
> devices under App Protection (MAM); ownership-based targeting routes the right policy to each; a
> single Conditional Access policy governs access from both.**

Every step follows the Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**
