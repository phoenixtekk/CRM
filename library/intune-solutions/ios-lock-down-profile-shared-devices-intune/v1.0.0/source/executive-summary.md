# Executive Summary — iOS Lock-Down Profile for Shared & Corporate iPhones (Microsoft Intune)

**White-label · Intune Solutions**

Most organizations hand out two kinds of iPhone: **shared devices** that anyone on shift picks up, and
**corporate devices** assigned to one person. The shared ones need a real **lock-down profile** so they
stay clean, consistent, and limited to the job; the corporate ones need a lighter, user-owned
experience — and staff need to know exactly how to **provision, sign in to, and use each**. Done ad hoc,
shared phones drift, get tied to whoever set them up, and users are confused about which device does
what.

This is a complete, **deploy-it-today** package for implementing an **iOS lock-down profile for shared
iPhones in Microsoft Intune**, alongside the full provisioning and login model for **both** shared and
corporate devices — written for an administrator with no prior Apple-management experience.

## What you get
- A plain-language **Solution Overview** of the shared-vs-corporate model, what a lock-down profile is
  (device restrictions, optional single/multi-app kiosk, supervised controls), and the two
  provisioning models.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (APNs, Apple
  Business Manager + ADE, supervision, groups, the shared sign-in account).
- An **Implementation Guide** of precise, click-by-click Intune steps: the shared **no-user-affinity**
  ADE enrollment, the corporate **user-affinity** ADE enrollment, the lock-down (restrictions + optional
  kiosk) for shared, a lighter baseline for corporate, plus compliance and access.
- A dedicated **Use & Login Guide** for end users: how staff pick up, sign in to, use, and hand back a
  shared phone, and how a user provisions and signs in to their own corporate phone.
- Five **PowerShell scripts** for readiness discovery, per-device model validation, fleet posture
  reporting, safe remediation, and the shared/corporate device-group builder.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
Two cleanly separated provisioning models from one Apple connection: **shared** iPhones with no primary
user, locked down with supervised restrictions (and an optional kiosk), where staff sign into the apps
with a **shared/managed account**; and **corporate** iPhones assigned to the user via their **own Entra
ID**, kept light and user-owned. (iPhones have no Apple "Shared iPad" mode — this solution implements
the accurate iPhone shared model: no user affinity + lock-down + app-level shared sign-in.)

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Shared iPhones locked to exactly what the job needs, corporate iPhones kept light and user-owned, and
staff who know how to provision, sign in to, and use both — managed at fleet scale in Intune and proven
on a pilot before you scale.
