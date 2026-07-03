# Solution Overview — Windows Autopilot (Government / GCC High)

## What this solution delivers

This is the **Government (GCC High) edition** of Windows Autopilot. The business goal is the
one every organization wants from Autopilot: a new Windows 11 device ships from the OEM, an
end user powers it on, signs in with their organizational account, and — with **no imaging,
no manual domain join, and no technician touch** — the device provisions itself into a
managed, compliant, ready-to-work state, **Microsoft Entra joined** and Intune-enrolled.

What is different here is **where** and **how** you build it. GCC High is a physically
separate, US-sovereign cloud (built on Azure Government, IL4/IL5) with its own admin portals
(`*.us`), its own service endpoints, and — critically — **a different feature set** than
Commercial. Following a Commercial Autopilot runbook on a GCC High tenant does not error
politely; it sends you looking for a portal blade that was never provisioned. This edition is
authored so a government tenant is configured **correctly**, on the supported technology,
with every Commercial-vs-GCC-High gap called out at the step where it bites.

> **The single most important fact in this solution — read it before anything else:**
> Classic **Windows Autopilot is NOT available in GCC High or DoD**, and Microsoft has **no
> plan to bring it** (Microsoft, *Intune Government Service overview*, table "Intune features
> not available in GCC High and DoD" lists **Windows Autopilot** as **n/a**). The **supported**
> zero-touch path in GCC High is **Windows Autopilot device preparation** — user-driven,
> Microsoft Entra join. **This entire solution is built on device preparation.** Every place a
> Commercial guide says "Autopilot," read "Autopilot **device preparation**."

## Commercial vs GCC High — what's different

This is the section to read before you touch anything. Every difference below is
doc-confirmed against Microsoft US Gov documentation unless explicitly flagged
*"verify for GCC High."*

### 1. The Autopilot technology itself is different (the pivot)

| Capability | Commercial | GCC High / DoD |
| --- | --- | --- |
| **Classic Windows Autopilot** (deployment profiles, hardware-hash registration, "Windows Autopilot devices" import, deployment groups) | Supported | **Not available. No plan to support.** (*Intune Government Service overview*) |
| **Windows Autopilot device preparation** (user-driven, Entra join) | Supported | **Supported** (*Intune Government Service overview*; *Autopilot device preparation overview*) |
| **Self-deploying** mode (kiosk/shared) | Supported (classic Autopilot) | **Not yet supported — planned** (*Intune Government Service overview*) |
| **Pre-provisioning** (white-glove) | Supported (classic Autopilot) | **Not yet supported — planned** |
| **Hybrid Microsoft Entra join** Autopilot | Supported (classic Autopilot) | **Not available** — device preparation is **Entra join only** (*Autopilot device preparation overview*) |
| Rename device during OOBE based on org structure | Supported | **Not yet supported — planned** |
| **DFCI** management (UEFI/BIOS lock via Autopilot) | Supported | **Not available — planned** |

**Consequence for design:** you cannot design around a hardware-hash CSV, a "Deployment
Profiles" blade, a "Windows Autopilot devices" import, self-deploying kiosks,
pre-provisioning (white-glove), Hybrid Entra join, or Autopilot device renaming. This
solution uses **device preparation profiles** with **Entra Join + Enrollment Time Grouping**
instead. If you are coming from a Commercial Autopilot background, this is the mental model
shift: **there is no hardware hash and no device registration step** in the user-driven
device-preparation flow.

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

(Portal and endpoint URLs: Microsoft, *Network endpoints for US government deployments*;
*Microsoft Graph national cloud deployments*.)

### 3. Servicing and update capabilities are reduced

Several servicing features a Commercial Autopilot rollout leans on **do not exist in GCC
High**:

- **Windows Autopatch** — not available.
- **Feature updates, Quality updates, Expedite updates, Driver updates for Windows in
  Intune** — not available.
- **Windows Subscription Activation** (auto step-up Pro → Enterprise) — not available.
- **Delivery Optimization for Win32 apps** — not available.

**Consequence:** in GCC High you service Windows through **Update rings for Windows 10 and
later** (which *are* available). Do not build a rollout that assumes Autopatch or the newer
per-update-class policies.

### 4. Other feature gaps that touch provisioning

- **Microsoft Store for Business** — not available (use Win32/line-of-business apps).
- **Remote Help** — not available (plan an alternative remote-assist tool for post-provisioning support).
- **Cloud PKI** — not available in GCC High (use SCEP/PKCS with your own PKI/NDES).
- **Device Health Attestation (DHA)** — not available (do not build compliance rules that depend on attestation).
- **Windows Hello for Business** — the WHfB policy path works, but the **Microsoft hosted PIN
  reset service is not available in Azure Government**; PIN recovery must be configured
  differently. *(See parity notes; verify for GCC High for your Windows build.)*

### 5. What is the same

The core experience genuinely transfers: **Entra Join**, **automatic MDM enrollment**, an
**assigned device group** with the **Intune Provisioning Client** service principal as its
owner (Enrollment Time Grouping), **app and PowerShell-script delivery during OOBE**,
**configuration and compliance policies**, an **Enrollment Status Page** progress experience,
and **near-real-time deployment monitoring**. The muscle memory transfers; the portals and the
servicing model do not.

## How the supported model works in GCC High (plain language)

1. You publish a **Windows Autopilot device preparation** profile in the GCC High Intune
   admin center (`https://intune.microsoft.us`).
2. The profile points at an **assigned** Microsoft Entra security group (the *device group*)
   whose **owner** is the **Intune Provisioning Client** service principal. That ownership is
   the mechanism — called *Enrollment Time Grouping* — that lets Intune drop each freshly
   enrolled device into the group **at enrollment time**, so the selected apps, scripts, and
   policies deploy immediately.
3. A user in your **provisioning user group** is allowed to Entra-join devices and is
   Intune-licensed.
4. The user powers on a supported Windows 11 device, connects to a network that reaches the
   sovereign endpoints, signs in with their GCC High account, and the device Entra-joins,
   MDM-enrolls, installs the selected apps/scripts, applies policy, and lands the user on the
   desktop with a progress percentage the whole way.

No serial-number hardware-hash upload is required for the user-driven flow — that is a
*classic Autopilot* concept that does not apply here. Optionally, **corporate identifiers**
can be pre-uploaded if you use enrollment restrictions to block personal devices.

## The standard deployment model (all solutions)

This solution follows the standard, gated model. **Do not skip a gate.**

**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — confirm every prerequisite in `02-requirements.md` (GCC High tenant, US Gov
  licensing, roles, sovereign portal access, supported Windows 11 build, endpoints allowed
  through filtering). *Gate:* every requirement verifies before you configure.
- **Configure** — build the named objects in `03-implementation.md` using the GCC High portals.
- **Pilot** — provision a small set of real devices for the pilot group.
- **Validate** — run the tests in `05-testing.md`; every gate must pass.
- **Expand** — widen scope group by group using `WAPG-Set-ScopeTargeting.ps1` (default `-WhatIf`).

## Named objects this solution creates (used verbatim throughout)

Reuse these exact names in every step and script so the pieces line up:

| Object | Exact name |
| --- | --- |
| Provisioning user group (allowed to Entra-join, Intune-licensed) | `WAPG-Provisioning-Users` |
| Device security group (**Assigned**; owner = Intune Provisioning Client) | `WAPG-Autopilot-Devices` |
| Pilot device/user group | `WAPG-Pilot` |
| Autopilot **device preparation** profile | `WAPG-DevicePrep-UserDriven-EntraJoin` |
| Enrollment Status Page profile | `WAPG-ESP-Provisioning` |
| Custom Intune RBAC role | `WAPG Device Preparation Administrator` |
| Windows update ring | `WAPG-UpdateRing-Pilot` |
| Compliance policy | `WAPG-Compliance-Win11` |
| Deployment scope tag | `WAPG` |

## Who this is for

Novice-to-intermediate administrators standing up Windows Autopilot on a **GCC High** (or
DoD) tenant who need the correct sovereign portals, the **supported** provisioning technology
(device preparation), and the Commercial-vs-GCC-High gaps called out — instead of a
Commercial runbook that silently fails.

## Sources

- Microsoft, *Microsoft Intune Government Service overview* (GCC High / DoD feature
  availability: classic Autopilot **not available**; device preparation **supported**;
  self-deploying/pre-provisioning/OOBE-rename **planned**).
- Microsoft, *Overview of Windows Autopilot device preparation* (GCCH/DoD support,
  Entra-join-only, user-driven, Enrollment Time Grouping, Autopilot precedence).
- Microsoft, *Windows Autopilot device preparation requirements* (software, networking,
  licensing, configuration, RBAC).
- Microsoft, *Network endpoints for US government deployments* (portal and service URLs).
- Microsoft, *Microsoft Graph national cloud deployments* (`-Environment USGov`).
