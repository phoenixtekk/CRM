# Solution Overview — Enable Microsoft Intune (Quick-Start)

## What this is
Microsoft Intune is the cloud service that enrolls, configures, secures, and reports on your
organization's devices — Windows PCs, iPhones/iPads, Macs, and Android. This Quick-Start enables Intune
with the **basics and defaults** so it becomes your device-management authority and can immediately
manage a **Windows** device and an **iPhone (iOS/iPadOS)**.

It covers the two ways organizations arrive here:

- **New tenant** — you just created a Microsoft 365 / Entra tenant (or are setting one up) and nothing
  is configured yet.
- **Existing tenant** — Microsoft 365 is already in use (mail, Teams, Entra ID) but Intune has never
  been turned on.

The steps are the same at the core; where a new tenant needs an extra confirmation (e.g. verifying a
domain, assigning your first licenses), this guide calls it out.

## How Intune works (the short version)
1. **Identity first.** Every device and user is an object in **Microsoft Entra ID** (formerly Azure AD).
   Intune trusts Entra for who the user is and which device is theirs.
2. **Licensing enables the service.** A user must hold an Intune license (standalone, or bundled in
   Enterprise Mobility + Security or a Microsoft 365 plan) to enroll devices.
3. **Enrollment brings a device under management.** A device enrolls into Intune, receives an MDM
   certificate, and from then on checks in for policy on a schedule.
4. **Policy configures and secures.** Configuration profiles set the device up; compliance policies
   define "healthy"; both are evaluated at every check-in.
5. **Reporting proves state.** The admin center shows each device's enrollment, configuration, and
   compliance status.

This Quick-Start puts the minimum of each in place: identity/licensing confirmed, enrollment turned on
for Windows and iOS, one configuration profile, and one compliance policy — enough for a **functioning
Intune**, not a full production hardening.

## The deployment model (the same across every solution)
Every solution — free or paid — follows the same repeatable shape, so each deployment feels familiar:

> **Assess → Configure → Pilot → Validate → Expand**

- **Assess** — confirm the prerequisites (licensing, roles, identity).
- **Configure** — set the tenant-wide switches and baseline policies.
- **Pilot** — enroll one Windows device and one iPhone.
- **Validate** — confirm both check in and report compliant, using the included scripts.
- **Expand** — when you are ready, roll out to more devices and layer on the deeper catalog solutions.

## What "functioning Intune" means when you finish
- Intune is the **MDM authority** for the tenant.
- **Windows** devices that are Entra-joined enroll **automatically**.
- **iPhones/iPads** can enroll (personal/BYOD) via the Company Portal.
- Every enrolled device receives a **baseline configuration** and is evaluated against a **compliance
  policy**.
- You can **see** device state in the Intune admin center and via the included reporting script.

## Supported enrollment in this Quick-Start
| Platform | Method covered here | External dependency |
|---|---|---|
| **Windows 10/11** | Automatic enrollment (Entra join → auto-MDM) | None |
| **iPhone/iPad — personal (BYOD)** | User enrollment via Company Portal + Apple MDM push certificate | None beyond the push certificate |
| **iPhone/iPad — corporate (zero-touch ADE)** | **Pointer only** — requires Apple Business Manager | **Apple Business Manager** (see `04-enrollment-scenarios.md`) |

## What is intentionally out of scope
This is a first-mile enablement. Zero-touch Autopilot, Conditional Access, app deployment, advanced
compliance, Defender integration, and Apple Business Manager setup are **deliberately not** covered in
depth here — each is its own catalog solution. Where one of them is the natural next step, this guide
points you to it.

## Auth and connections used
- **Microsoft Intune admin center** (`https://intune.microsoft.com`) — the primary UI.
- **Microsoft Entra admin center** (`https://entra.microsoft.com`) — licensing, groups, MDM auto-enrollment scope.
- **Microsoft Graph PowerShell** (optional) — the included scripts use it read-only to verify and report state.
- You act as a **Global Administrator** (new-tenant setup) or an **Intune Administrator** (existing tenant).
