# Solution Overview — Cloud-First Autopilot Zero-Touch Provisioning (Government / GCC High)

## What this solution delivers

This is the **Government (GCC High) edition** of Cloud-First Autopilot Zero-Touch
Provisioning. The goal is unchanged from the Commercial edition: a new Windows 11 device
ships from the OEM, an end user powers it on, signs in with their organizational account,
and — with **no imaging, no manual domain join, and no technician touch** — the device
provisions itself into a managed, compliant, ready-to-work state. The device is
**Microsoft Entra joined** (cloud-first), with the option to add on-premises resource
access later.

What is different here is **where** and **how** you build it. GCC High is a physically
separate, US-sovereign cloud with its own admin portals (`*.us`), its own service
endpoints, and — critically — **a different feature set** than Commercial. Some
capabilities you would reach for in a Commercial Autopilot design **do not exist in
GCC High**. Following Commercial steps on a GCC High tenant does not error politely; it
silently sends you to the wrong portal or has you look for a blade that was never
provisioned. This edition is authored so a government tenant is configured **correctly**.

> **The single most important fact in this solution:** Classic **Windows Autopilot is NOT
> available in GCC High or DoD** and there is **no plan to bring it** (Microsoft,
> *Intune Government Service overview*, "Intune features not available in GCC High and
> DoD"). The supported zero-touch path in GCC High is **Windows Autopilot device
> preparation** (user-driven, Microsoft Entra join). This solution is built entirely on
> the supported path.

## The zero-touch model in GCC High (plain language)

1. You publish a **Windows Autopilot device preparation** profile in the GCC High Intune
   admin center (`https://intune.microsoft.us`).
2. The profile points at an **assigned** Microsoft Entra security group (the *device
   group*) whose **owner** is the **Intune Provisioning Client** service principal. This
   ownership is the mechanism (called *Enrollment Time Grouping*) that lets Intune drop
   each freshly enrolled device into the group **at enrollment time**, so apps, scripts,
   and policies deploy immediately.
3. A user in your **provisioning user group** is allowed to Entra-join devices and is
   licensed for Intune.
4. The user powers on a supported Windows 11 device, connects to network, signs in with
   their GCC High account (`...@yourtenant.onmicrosoft.us` or your routed domain), and the
   device Entra-joins, MDM-enrolls, installs the selected apps/scripts, applies policy, and
   lands the user on the desktop with a progress percentage the whole way.

No serial-number hardware hash upload is required for the basic user-driven flow (that is a
*classic Autopilot* concept, which does not apply here). Optionally, **corporate
identifiers** can be pre-uploaded if you use enrollment restrictions to block personal
devices.

## Commercial vs GCC High — what's different

This is the section to read before you touch anything. Every difference below is
doc-confirmed against Microsoft US Gov documentation unless explicitly flagged
*"verify for GCC High."*

### 1. The provisioning technology itself is different

| Capability | Commercial | GCC High / DoD |
| --- | --- | --- |
| **Classic Windows Autopilot** (deployment profiles, hardware-hash registration, deployment groups) | Supported | **Not available. No plan to support.** (*Intune Government Service overview*) |
| **Windows Autopilot device preparation** (user-driven, Entra join) | Supported | **Supported** (*Intune Government Service overview*; *Autopilot device preparation overview*) |
| Self-deploying mode / pre-provisioning (white-glove) | Supported (classic Autopilot) | **Not yet supported** — "planned" (*Intune Government Service overview*) |
| Rename device during OOBE based on org structure | Supported | **Not yet supported** — "planned" |
| DFCI management (UEFI/BIOS lock via Autopilot) | Supported | **Not available** |

**Consequence for design:** you cannot design around a hardware-hash CSV, a "Deployment
Profiles" blade, a "Windows Autopilot devices" import, self-deploying kiosks, or Autopilot
device renaming. This solution uses **device preparation profiles** and **Entra Join +
enrollment-time grouping** instead. Where a Commercial runbook says "Autopilot," read
"Autopilot **device preparation**."

### 2. The portals are different (`*.us`, not `*.com`)

| Purpose | Commercial URL | GCC High URL |
| --- | --- | --- |
| Intune admin center | `intune.microsoft.com` | `https://intune.microsoft.us` |
| Entra admin center | `entra.microsoft.com` | `https://entra.microsoft.us` *(verify for GCC High — see parity notes)* |
| Azure portal | `portal.azure.com` | `https://portal.azure.us` |
| Microsoft 365 admin | `admin.microsoft.com` | `https://portal.office365.us` |
| Sign-in / identity (Evo STS) | `login.microsoftonline.com` | `https://login.microsoftonline.us` |
| Company Portal service | `portal.manage.microsoft.com` | `https://portal.manage.microsoft.us` |
| Microsoft Graph | `graph.microsoft.com` | `https://graph.microsoft.us` |

(Portal and endpoint URLs: Microsoft, *Network endpoints for US government deployments*.)

### 3. Update and servicing capabilities are reduced

Several servicing features a Commercial design leans on **do not exist in GCC High**:

- **Windows Autopatch** — not available.
- **Feature updates, Quality updates, Expedite updates, Driver updates for Windows in
  Intune** — not available.
- **Windows Subscription Activation** (auto step-up Pro → Enterprise) — not available.
- **Delivery Optimization for Win32 apps** — not available.

**Consequence:** in GCC High you service Windows through **Update rings for Windows 10 and
later** (which *are* available) rather than the newer per-update-class policies or
Autopatch. Do not build a rollout that assumes Autopatch or feature-update policies.

### 4. Other feature gaps that touch provisioning

- **Microsoft Store for Business** — not available (do not plan Store-for-Business app
  provisioning; use Win32/line-of-business apps and the newer Store integration where
  supported).
- **Remote Help** — not available (plan an alternative remote-assist tool for
  post-provisioning support).
- **Cloud PKI** — not available in GCC High.
- **Device Health Attestation** — not available.
- **Windows Hello for Business** — the WHfB policy path is available, but the **Microsoft
  PIN reset service is not available in Azure Government**; PIN recovery must be configured
  differently. *(See parity notes.)*

### 5. What is the same

The core of the deployment is genuinely the same experience: **Entra Join**, **automatic
MDM enrollment**, **assigned device group with the Intune Provisioning Client as owner**,
**app and PowerShell-script delivery during OOBE**, **configuration and compliance
policies**, and **near-real-time deployment monitoring**. The muscle memory transfers; the
portals and the servicing model do not.

## The standard deployment model (all solutions)

This solution follows the standard, gated model. **Do not skip a gate.**

**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — confirm every prerequisite in `02-requirements.md` (GCC High tenant, US Gov
  licensing, roles, sovereign portal access, supported Windows 11 build, endpoints allowed
  through filtering). *Pass/fail gate:* every requirement verifies before you configure.
- **Configure** — build the named objects in `03-implementation.md` using the GCC High
  portals.
- **Pilot** — provision a small set of real devices for the pilot group.
- **Validate** — run the tests in `05-testing.md`; every gate must pass.
- **Expand** — widen scope group by group using `CFAPG-Set-ScopeTargeting.ps1` (default
  `-WhatIf`).

## Named objects this solution creates (used verbatim throughout)

Reuse these exact names in every step and script so the pieces line up:

| Object | Exact name |
| --- | --- |
| Provisioning user group (allowed to Entra-join, Intune-licensed) | `CFAPG-Provisioning-Users` |
| Device security group (assigned; owner = Intune Provisioning Client) | `CFAPG-Autopilot-Devices` |
| Pilot device/user group | `CFAPG-Pilot` |
| Autopilot device preparation profile | `CFAPG-DevicePrep-UserDriven-EntraJoin` |
| Enrollment Status Page profile | `CFAPG-ESP-Provisioning` |
| Custom Intune RBAC role | `CFAPG Device Preparation Administrator` |
| Windows update ring | `CFAPG-UpdateRing-Pilot` |
| Compliance policy | `CFAPG-Compliance-Win11` |
| Deployment scope tag | `CFAPG` |

## Who this is for

Novice-to-intermediate administrators standing up cloud-first Windows provisioning on a
**GCC High** (or DoD) tenant who need the correct sovereign portals, the supported
provisioning technology, and the Commercial-vs-GCC-High gaps called out — instead of a
Commercial runbook that silently fails.

## Sources

- Microsoft, *Microsoft Intune Government Service overview* (GCC High / DoD feature
  availability, planned, and not-available tables).
- Microsoft, *Overview of Windows Autopilot device preparation* (GCCH/DoD support,
  Entra-join-only, Enrollment Time Grouping).
- Microsoft, *Windows Autopilot device preparation requirements* (software, networking,
  licensing, configuration, RBAC).
- Microsoft, *Network endpoints for US government deployments* (portal and service URLs).
