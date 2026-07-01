# 1. Solution Overview — Entra ID + Apple Business Manager Federation & Account Auto-Provisioning

## What this solution is
This solution integrates **Microsoft Entra ID** with **Apple Business Manager (ABM)** so that two
things happen automatically: users sign in to Apple services with their **Entra credentials**
(federated authentication), and their **Managed Apple IDs** are created and kept in sync from Entra
(automatic account provisioning). With that identity foundation in place, every company iPhone then
enrolls into **Microsoft Intune** the right way for its purpose — **Corporate-Owned (COD)**, **BYOD**,
or **Shared**.

It is the identity-and-provisioning layer beneath iPhone management. It does not replace your
enrollment products; it makes them work on one clean identity.

## The two pillars

### Pillar 1 — Federated authentication (Entra ID is the identity provider for Apple)
You link Apple Business Manager to your Entra tenant and a **verified domain**. After federation,
when a user signs in to an Apple service with their work email, Apple redirects the sign-in to Entra
ID; the user authenticates with their normal Entra credentials (and MFA), and Apple trusts the
result. There is no separate Apple password to manage.

### Pillar 2 — Automatic Managed Apple ID provisioning
A **Managed Apple ID** is the organization-owned Apple account a user signs in with on managed
Apple devices and services. This solution creates them automatically by **two complementary paths**:

1. **SCIM provisioning from Entra ID to Apple Business Manager.** Entra has a gallery
   **Apple Business Manager** provisioning application. You scope it to a group, turn provisioning on,
   and Entra creates/updates the matching Managed Apple IDs in ABM on a recurring cycle — and
   de-provisions them when a user leaves the scope. This is the controlled, auditable bulk path.
2. **Just-in-time (JIT) creation on first federated sign-in.** With federation in place, a scoped
   user who has no Managed Apple ID yet can have one created the first time they sign in to an Apple
   service with their federated credentials. This catches users who provisioning has not reached yet.

Use SCIM as the primary path for predictable, scoped, reversible provisioning; treat JIT as the
backfill so no scoped user is ever blocked waiting for a cycle.

## The domain-capture / existing-Apple-ID conflict (read this before you federate)
Federating a domain tells Apple that your organization owns every Apple identity that uses an email
in that domain. If employees previously created **personal** Apple IDs using their work email
(`name@yourdomain.com`), those personal accounts now **conflict** with the Managed Apple IDs your
organization wants to own — Apple calls this domain capture / a Managed Apple ID conflict. Apple
gives those users a window to change their personal account to a different email so the company can
claim the work-email identity. If this is ignored, provisioning fails for the conflicted users and
their enrollment experience breaks. **Detecting and resolving these conflicts is a first-class step**
in the Implementation Guide and a dedicated section in Troubleshooting — never skip the conflict scan
before you widen the scope.

## How the foundation feeds the three enrollment models
Once a user has a federated Managed Apple ID, Intune can enroll their iPhone the right way:

- **Corporate-Owned (COD)** — company-owned phones enrolled zero-touch via **Automated Device
  Enrollment (ADE)** from ABM, **supervised**, account-driven so the user signs in with their Entra
  identity / Managed Apple ID during setup.
- **BYOD** — personal phones enrolled with **account-driven User Enrollment**: a modern,
  privacy-preserving model that uses the **Managed Apple ID + Entra federated sign-in** to create a
  managed, cryptographically separated work partition while leaving the user's personal data and
  personal Apple ID untouched.
- **Shared** — appliance phones enrolled with **no user affinity** plus restrictions; staff identity
  lives in a **Managed Apple ID / shared app sign-in**, not bound to one person.

The detailed per-model flows and end-user experience are in **Section 4 — Enrollment Scenarios**.

## An honest note on "Shared iPad" vs shared iPhone
Apple's true multi-user **Shared iPad** feature (where the device caches several users' Managed
Apple IDs and each gets a partition) is an **iPad-only** capability. **iPhones do not have Shared
iPad.** A "shared iPhone" in this solution means an iPhone enrolled with **no user affinity**,
locked down with restrictions, where staff sign in to the relevant **app/service with a Managed
Apple ID or a shared account** rather than personalizing the device. This solution states that
accurately and builds the shared model on no-affinity enrollment, not on a feature iPhones lack.

## What is in scope vs deferred
- **Exact navigation is given** for the **Entra side** (federation + the Apple Business Manager
  provisioning app) and the **Intune side** (APNs, ADE token, enrollment profiles, enrollment types).
- **Apple Business Manager console internals** (the exact ABM menu paths to add the federation /
  identity provider, manage Managed Apple IDs, and assign devices) change over time and are
  **deferred to Apple's official documentation** — this solution names the action and the control to
  use, and tells you what value to carry between consoles, without fabricating ABM menu paths.

## Benefits
- **One identity** — users sign in to Apple with Entra credentials; no separate Apple password.
- **Hands-off accounts** — Managed Apple IDs provision and de-provision themselves with the user's
  lifecycle (SCIM), with JIT as a safety net.
- **Right enrollment per phone** — COD, BYOD, and Shared each get the correct, modern model on the
  same federated identity.
- **Privacy for BYOD** — account-driven User Enrollment keeps personal data separate from work.
- **Auditable + reversible** — scoped to groups, piloted first, with scripts to validate and report.

## Limitations (be honest with buyers)
- Federation is **tenant-and-domain-wide for Apple sign-in** — pilot on a scoped group and resolve
  existing-Apple-ID conflicts before you widen it; this is the highest-risk change in the solution.
- **ABM console specifics are deferred to Apple** (they move); this solution covers the Entra and
  Intune sides exactly and names the ABM actions.
- Provisioning from Entra covers **Managed Apple IDs in ABM**; it is not a general Apple data sync.
- Account-driven User Enrollment and account-driven device enrollment require **supported iOS
  versions** and a correctly federated Managed Apple ID — unsupported/old devices fall back to older
  enrollment flows.

## The standard deployment model
> **Federate ABM with Entra (scoped) → turn on Managed Apple ID provisioning for a pilot group →
> resolve existing-Apple-ID conflicts → stand up COD / BYOD / Shared enrollment → validate on the
> pilot → expand.** Pattern: **Assess → Configure → Pilot → Validate → Expand.**
