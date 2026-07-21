# 2. Requirements Guide — Remote Help — Government (GCC High) Edition

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

This edition targets the **US sovereign cloud**. The **first requirement is availability** — it is the
gate that decides whether the rest of this guide applies to a Remote Help deployment (GCC) or to the
compliant alternative (GCC High / DoD). Every sovereign-specific fact below is flagged **verify
against current Microsoft documentation** — availability, endpoints, and licensing in the government
clouds change over time.

## 2.0 THE GATING REQUIREMENT — Remote Help availability for your sovereign tier

**Description:** Confirm, against current Microsoft documentation, whether Remote Help is available in
*your* government cloud tier before doing anything else.
**Why:** Remote Help availability is **not uniform** across GCC / GCC High / DoD. Building a "Remote
Help for GCC High" rollout is wasted (and misdirected) effort if the feature is not there.
**Verify:** Read **Microsoft Learn — "Plan for Remote Help with Microsoft Intune"** and **"Microsoft
Intune Government Service overview."** At authoring time these state:
- **GCC** — Remote Help **supported** (except AVD). *(Intune GCC = the commercial instance.)*
- **GCC High / DoD** — Remote Help **not supported**; listed under **"features planned for GCC High and
  DoD"**, no ETA.
**Implement:**
- If **GCC** → proceed with this guide's deployment path, using the **commercial** endpoints (2.1a).
- If **GCC High / DoD** → **stop the Remote Help build**; go to the **compliant alternative**
  (Implementation Step 6 and `gcc-high-parity-notes.md` §4). Re-verify availability at deployment time
  and monitor the roadmap. **Verify against current Microsoft documentation.**

## 2.1 Correct cloud plane / national-cloud endpoints (verify against current Microsoft documentation)

**Description:** Administer on the plane that matches your tier. GCC High / DoD use the `*.us`
sovereign portals and US Gov Graph; **GCC uses the commercial `*.com` portals** because Intune GCC is
the commercial instance.
**Why:** Signing in or scripting against the wrong cloud fails or silently targets the wrong tenant.
**Verify:** You can sign in at the correct admin portal for your tier; `RHELPG-Test-Endpoints.ps1`
confirms the tenant resolves the expected endpoints; `RHELPG-Discovery.ps1` connects with the matching
`-Environment`.

| Purpose | GCC (commercial instance) | GCC High | DoD |
|---|---|---|---|
| Intune admin center | `https://intune.microsoft.com` | `https://intune.microsoft.us` | `https://intune.microsoft.us` |
| Entra admin center | `https://entra.microsoft.com` | `https://entra.microsoft.us` | `https://entra.microsoft.us` |
| Azure portal | `https://portal.azure.com` | `https://portal.azure.us` | `https://portal.azure.us` |
| Microsoft 365 admin center | `https://admin.microsoft.com` | `https://portal.office365.us` | `https://portal.office365.us` |
| Defender / security portal | `https://security.microsoft.com` | `https://security.microsoft.us` | `https://security.microsoft.us` |
| Sign-in / authentication | `https://login.microsoftonline.com` | `https://login.microsoftonline.us` | `https://login.microsoftonline.us` |
| Microsoft Graph | `https://graph.microsoft.com` | `https://graph.microsoft.us` | `https://dod-graph.microsoft.us` |
| Graph PowerShell `-Environment` | `Global` | `USGov` | `USGovDoD` |

**Implement:** Bookmark the correct portals for your tier; in scripts pass `-Environment USGov`
(GCC High) or `USGovDoD` (DoD), or `Global` for GCC. **Every endpoint in this table is flagged verify
against current Microsoft documentation** (Microsoft Learn — "Microsoft Graph national cloud
deployments" and the US Government endpoint articles). **Note there is no documented sovereign Remote
Help service endpoint for GCC High / DoD** — the commercial service endpoint (`remotehelp.microsoft.com`,
port 443, TLS 1.2) serves GCC; a GCC High / DoD endpoint does not exist because the feature is not
offered there (verify against current Microsoft documentation).

## 2.2 Remote Help licensing (only where available — verify against current Microsoft documentation)

**Description:** A **Remote Help license** — an add-on in addition to Intune Plan 1 or Plan 2 — for
**every** helper *and* sharer.
**Why:** Remote Help is a licensed add-on capability; it won't enable without the license, and both
parties must be licensed.
**Verify:** M365 admin center (correct portal for your tier) → **Billing → Licenses**; Intune →
**Tenant administration → Remote Help**.
**Implement:** Purchase the Remote Help add-on (or the Intune Suite) and assign to helpers and sharers.
**Confirm the exact SKU and its availability in your government tier (the government SKU names and
whether the add-on is offered for your tier) — verify against current Microsoft documentation.** On
GCC High / DoD this requirement is moot until the feature ships.

## 2.3 Intune enrollment + Entra registration

**Description:** Intune subscription with target devices enrolled; enrolled devices registered with
Microsoft Entra.
**Why:** Remote Help is deployed and governed through Intune; participants must be in the same tenant.
**Verify:** Intune → **Devices → All devices** (correct portal for your tier).
**Implement:** Enable automatic enrollment; enroll devices. (See global G4.)

## 2.4 Supported platforms in the government cloud (verify against current Microsoft documentation)

**Description:** In **GCC**, Remote Help supports a **subset** of platforms: Windows, Windows on ARM64,
Windows 365, Samsung and Zebra devices enrolled as Android Enterprise **dedicated** devices, and macOS
13 / 14 / 15. It is **not** supported in **Azure Virtual Desktop (AVD)**.
**Why:** Assigning the app to an unsupported platform (e.g. AVD hosts) will not deliver a working
session.
**Verify:** `winver` / device platform; confirm the platform against Microsoft Learn — "Plan for
Remote Help."
**Implement:** Scope the deployment to supported platforms only; exclude AVD. **Verify the current
supported-platform list against current Microsoft documentation.**

## 2.5 The Remote Help app

**Description:** The Remote Help application installed on participating helper and sharer devices.
**Why:** Both parties run the app (or the web app, per the supported modes) to connect.
**Verify:** App present at `C:\Program Files\Remote help\` on Windows (or run `RHELPG-Discovery.ps1`);
Microsoft AutoUpdate on macOS; Play Store app on supported Android.
**Implement:** Deploy the Remote Help app via Intune as **Required** to the relevant groups (Windows
Store/Win32, macOS, or approved Android app). Keep it auto-updating.

## 2.6 RBAC roles (Remote Help permissions)

**Description:** Intune RBAC granting the Remote Help permissions — **View screen**, **Take full
control**, **Elevation**, **Unattended** (Android dedicated only), plus **Remote Tasks — Offer remote
assistance** and **Remote Assistance Connector — Read**.
**Why:** A helper needs *Offer remote assistance* + *Remote Assistance Connector — Read* + at least one
Remote Help permission. Least privilege keeps view-only for tier-1 and full control for tier-2.
**Verify:** Intune → **Tenant administration → Roles**; the built-in **Help Desk Operator** role
includes the Remote Help permissions.
**Implement:** Assign **Help Desk Operator** (or a custom role with the specific Remote Help
permissions) to help-desk staff, scoped to a **user** scope group (the *All Devices* scope does **not**
include unenrolled devices). Use `RHELPG-Set-RoleScope.ps1` (default `-WhatIf`). **Note:** on GCC High /
DoD the Remote Help permissions may not be present in the role catalog until the feature ships —
verify against current Microsoft documentation.

## 2.7 Conditional Access for helpers (Windows/macOS only — verify against current Microsoft documentation)

**Description:** Optional Conditional Access requiring MFA or a compliant device for helper accounts,
which hold elevated access.
**Why:** A compromised helper account is high-impact; CA reduces the blast radius.
**Verify:** Entra → **Protection → Conditional Access** (correct portal for your tier).
**Implement:** Scope a CA policy to the helper group. **Conditional Access for Remote Help is supported
only on Windows and macOS** — verify against current Microsoft documentation.

## 2.8 Network access to the Remote Help service (verify against current Microsoft documentation)

**Description:** Outbound HTTPS (port 443) from helpers and sharers to the Remote Help service
endpoints; no SSL inspection of that traffic.
**Why:** Sessions are brokered through the cloud service over TLS 1.2 (RDP).
**Verify:** Helpers and sharers can reach the Remote Help endpoints (the app connects).
**Implement:** Allow the published Remote Help / Intune service URLs through proxy/firewall and
**exclude them from SSL inspection**. **Confirm the exact endpoint list for your tier against current
Microsoft documentation** ("Network endpoints for Remote Help").

## 2.9 Pilot group + (GCC High/DoD) compliant-alternative decision

**Description:** An Entra security group for a pilot (helpers + pilot sharers). For GCC High / DoD, a
documented **compliant-alternative** decision instead of a Remote Help build.
**Why:** Every deployment is piloted; and where Remote Help is unavailable, the buyer needs a governed
substitute, not a gap.
**Verify:** Entra → **Groups**; the pilot group exists. For GCC High / DoD, the alternative is chosen
(see `gcc-high-parity-notes.md` §4).
**Implement:** Create `RemoteHelp – GCCH – Pilot` (helpers + pilot sharers). For GCC High / DoD, select
a compliant alternative within your authorization boundary (Implementation Step 6).

---
## Checklist
- [ ] **Availability gate resolved** — Remote Help confirmed available (GCC) or not (GCC High/DoD) per current Microsoft docs
- [ ] Correct cloud plane for your tier (`*.us` for GCC High/DoD; commercial for GCC) — `RHELPG-Test-Endpoints.ps1`
- [ ] Remote Help license (add-on) assigned to helpers **and** sharers (where available)
- [ ] Devices enrolled in Intune and Entra-registered
- [ ] Target platforms supported (not AVD)
- [ ] Remote Help app deployed — `RHELPG-Discovery.ps1`
- [ ] RBAC (Remote Help permissions) assigned via a user scope group — `RHELPG-Set-RoleScope.ps1`
- [ ] Conditional Access for helpers (Windows/macOS) considered
- [ ] Network allows Remote Help endpoints; no SSL inspection
- [ ] Pilot group created — or (GCC High/DoD) compliant alternative selected
