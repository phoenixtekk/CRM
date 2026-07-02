# 1. Solution Overview — Endpoint Privilege Management (EPM)

## What Endpoint Privilege Management is
Endpoint Privilege Management (EPM) is a Microsoft Intune capability that lets users sign in and
work as **standard users** while still being able to perform the **specific** tasks that normally
require local administrator rights. Instead of granting a person permanent membership in the local
**Administrators** group, you define **elevation rules** that allow a named application or task to
run with administrative privileges — and nothing else does.

The result is **least privilege in practice**: the everyday account has no standing admin rights,
the legitimate "I need to install/run this one thing" cases are still handled, and every elevation
is governed by policy and recorded centrally.

## How it works
1. You enable EPM for the tenant and deploy the **EPM client (the elevation extension)** to devices
   through Intune. The client is what intercepts elevation requests on the endpoint.
2. You deploy an **Elevation settings (base) policy** that turns EPM on for targeted devices and
   sets the default behavior and reporting scope.
3. You deploy one or more **Elevation rules policies**. Each rule identifies an application by
   **file attributes** (file name plus a **certificate** or **file hash**) and assigns an
   **elevation type**.
4. When a standard user tries to run an approved application elevated (e.g. right-click → **Run with
   elevated access**), the EPM client checks the rules and applies the matching elevation type —
   silently, after a prompt, or after support approval. Unmatched requests fall back to the normal
   Windows behavior (a UAC admin-credential prompt the standard user cannot satisfy).
5. Every elevation — allowed or denied — is reported back to Intune, giving you a tenant-wide audit
   trail.

Because rules are tied to a **certificate or hash**, an attacker cannot simply rename a malicious
binary to a trusted application's name to gain elevation.

## The three elevation types
- **Automatic** — the application elevates silently with no user interaction. Use sparingly, only
  for fully trusted, signed software, because the user is never prompted.
- **User confirmed** — the default and recommended type. The user must actively confirm (and,
  optionally, authenticate with Windows Hello / credentials and/or type a business justification)
  before the app elevates. This keeps a human in the loop and produces a clean justification record.
- **Support approved** — the elevation request is sent to Intune and must be **approved by an
  administrator** before it runs. Use for high-risk or rarely-needed applications.

## Benefits
- **Removes standing local admin** — shrinks the blast radius of phishing, malware, and credential theft.
- **Keeps users productive** — the genuine elevation cases still work, without a help-desk ticket each time.
- **Granular and tamper-resistant** — rules are scoped to specific signed/hashed applications.
- **Fully audited** — a central, tenant-wide record of who elevated what, when, and why.
- **Compliance** — directly supports least-privilege and Zero Trust mandates and audit requirements.

## Limitations (be honest with buyers)
- EPM is **licensed** — it requires the **Microsoft Intune Suite** or the standalone **Endpoint
  Privilege Management add-on**. It is not included in base Intune Plan 1.
- It manages **Windows** devices (Windows 10/11) managed by Intune; it is not a macOS/Linux solution.
- Rules are as good as their definitions — an overly broad **Automatic** rule can re-introduce risk;
  prefer **User confirmed**.
- Removing users from the local Administrators group (the end goal) is a **change-management**
  exercise; plan communication and a support-approved safety valve during transition.
- EPM governs **elevation**, not application allow-listing — pair it with **WDAC/App Control** and
  **ASR** for defense in depth.

## The standard deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **Intune-managed, Microsoft Entra–joined Windows devices, with EPM enabled via a base policy and
> governed by certificate/hash-based elevation rules — User confirmed by default.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
You start with users still holding admin rights, observe what they actually elevate (reporting),
codify those into rules, then remove standing admin rights once the rules cover real-world usage.
