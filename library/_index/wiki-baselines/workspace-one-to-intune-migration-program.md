# Workspace ONE to Microsoft Intune Migration Program

> **Version 1.0.0** · Category: Migrations · Solution code: WS1PROG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

## The situation

Many organizations standardizing on Microsoft 365 are carrying a second, separately-licensed endpoint platform — **VMware Workspace ONE UEM** — alongside the Microsoft stack they already own. Consolidating onto **Microsoft Intune** removes that duplicate spend and unifies endpoint management, identity, and compliance under one console and one Conditional Access model.

The critical, often-underestimated reality: a device has **one** active MDM enrollment per platform, and there is no in-place "convert" from Workspace ONE to Intune. Migrating means **un-enrolling each device from Workspace ONE, enrolling it into Intune, and rebuilding the management state** — profiles, compliance, and apps — to parity. Across thousands of live Windows, iOS, Android, and Mac devices, with zero tolerance for a user losing email or access mid-day, this is one of the highest-risk endpoint projects an organization can run.

## The solution

This program delivers a controlled, reversible, no-loss migration across **four platform workstreams — Windows, iOS/iPadOS, Android, and macOS** — using a phased methodology with named objects, an explicit pilot-wave gate, and per-device rollback at every cutover.

It follows the standard program model: **Discover → Assess → Plan → Configure the Intune target (identity, per-platform enrollment, rebuilt parity policy and apps) → Pilot → Validate (pilot-wave gate) → Expand wave by wave (coexistence → cutover → validate) → Decommission Workspace ONE.** Each platform has its own runbook reflecting its real cutover mechanics — Windows and BYOD typically re-enroll without a wipe; corporate Apple (Apple Business Manager / Automated Device Enrollment) and fully managed Android typically reset.

## The outcome

- **A single Microsoft-native endpoint stack** — Intune + Entra (and optionally Defender for Endpoint), one console, one compliance and Conditional Access model.
- **Licensing consolidated** — the separate Workspace ONE spend is retired once the fleet is fully migrated.
- **Controlled, low-surprise execution** — one coordinated program instead of four uncoordinated platform moves: shared discovery, one wave plan, pilots, parity validation, and a per-device rollback.
- **No device and no app left behind** — every Workspace ONE device is retired only after its Intune counterpart passes validation and a defined grace period elapses.

## What leadership must know

- **Enrollment plumbing gates the timeline.** Apple Push (APNs), Apple Business Manager, managed Google Play, and Windows automatic enrollment must be live first — these have real lead times.
- **Policies and apps are rebuilt, not migrated.** There is no native Workspace ONE → Intune configuration import; parity is re-authored and proven on a pilot before fleet cutover.
- **Some corporate devices reset.** Corporate Apple (ADE) and fully managed/dedicated Android devices commonly require a wipe to move enrollment cleanly — this drives the wave model and user communications.
- **Plan for weeks to months, not days.** A full multi-platform fleet migration is a phased program; users cut over wave by wave, with both platforms coexisting (each device managed by exactly one) during the transition.

## Investment

A flagship migration program kit: a complete phased playbook, four per-platform cutover runbooks with exact Intune / Entra / Apple Business Manager navigation, five operational PowerShell tools (discovery, validation, reporting, remediation, wave targeting), and the testing/acceptance and troubleshooting references that de-risk a high-stakes UEM exit across live production devices.


---


# 1. Solution Overview — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

## What this solution is

This is a multi-platform **program** to migrate an organization's entire endpoint estate off **VMware Workspace ONE UEM** and onto **Microsoft Intune** — Windows, iOS/iPadOS, Android, and macOS — as one repeatable, documented operating model. It is a **program playbook**, not a single wizard: it pairs a phased methodology with per-platform runbooks so a program lead and a team of admins can execute a controlled, reversible, no-loss migration across live, enrolled production devices.

The program covers four platform workstreams, each with its own enrollment model, app delivery channel, and parity surface:

1. **Windows** — move from Workspace ONE Windows management to Intune MDM via Entra join / hybrid join and Windows automatic enrollment; rebuild configuration profiles, compliance, and apps (Win32/Store/MSI).
2. **iOS/iPadOS** — move from Workspace ONE Apple management to Intune; re-establish Apple Push (APNs) and (for corporate devices) Apple Business Manager / Automated Device Enrollment; rebuild profiles and app assignments (VPP/managed store apps).
3. **Android** — move from Workspace ONE Android management to Intune managed Google Play (Android Enterprise — work profile, fully managed, or dedicated); rebuild policies and managed app assignments.
4. **macOS** — move from Workspace ONE Mac management to Intune; re-establish APNs and (for corporate Macs) ABM/ADE; rebuild configuration profiles, compliance, and apps (PKG/DMG/managed store).

## The single most important reality: an endpoint cannot be enrolled in two MDMs at once

A device has **one** active MDM enrollment per platform channel. Workspace ONE and Intune are **separate UEM platforms**; there is no in-place "convert" that flips a device from one to the other while preserving state. Consequently, migrating a device means **un-enrolling it from Workspace ONE and (re-)enrolling it into Intune**, and rebuilding the management state (profiles, compliance, apps) that Workspace ONE was delivering. Key implications that shape every phase:

- **Policies and apps are rebuilt, not copied.** There is no Workspace ONE → Intune configuration export that lands as native Intune policy. Each in-scope profile, compliance rule, and app is **re-authored** in Intune to achieve **parity** with what Workspace ONE delivered.
- **Identity must resolve in Entra first.** Devices and users must exist and authenticate in Microsoft Entra ID before Intune can enroll and target them.
- **Enrollment plumbing is per platform.** APNs (Apple), ABM/ADE token (corporate Apple), managed Google Play (Android), and Windows automatic enrollment must each be live in Intune before that platform's devices can move.
- **Coexistence is real but bounded.** During transition both platforms exist in the org, but a given **device** is managed by one at a time. The program runs a controlled coexistence window per wave (source still managing un-migrated devices, target managing migrated ones), not indefinite dual-management of the same device.
- **Cutover is reversible per device.** Because cutover is "leave source, join target," the rollback is "re-enroll to source" — but only inside the change window and before the source assignment is removed.
- **Re-enrollment is user-visible.** Most platforms require user action or a wipe/reset for corporate ADE devices. This drives the wave model, comms, and the pilot gate.

## Why this is one of the highest-risk endpoint projects there is

A UEM exit touches every employee's primary work device. Done ad hoc it stalls in finger-pointing between the source team, the target team, and the helpdesk; done without parity it silently drops a VPN profile or a Wi-Fi cert and breaks access mid-day; done without waves it turns a bad pilot into a fleet-wide outage. The value of running it **as a program** is:

- **One coordinated effort** instead of four uncoordinated platform migrations — shared discovery, one wave plan, one set of acceptance gates, one rollback posture.
- **Parity is proven before cutover.** Every device migrates into a known-good Intune state that was validated on a pilot wave first.
- **No device and no app is left behind.** Decommission of Workspace ONE happens only after each wave's devices pass validation in Intune.
- **The whole program is evidenced** — every wave, profile set, enrollment profile, and group is named and recorded, so status and rollback are unambiguous.

## How it works (the flow)

1. **Discover** the Workspace ONE estate and the Intune target side: every enrolled device, its platform/ownership, the apps and profiles assigned, and the users behind them.
2. **Assess** parity scope and per-platform complexity; rate each profile/app/device-cohort High/Med/Low.
3. **Plan** waves and per-platform sequencing; name every object that will be created.
4. **Configure** the Intune target: identity readiness, per-platform enrollment plumbing, and the rebuilt parity policy sets and apps.
5. **Pilot** every platform end-to-end against a small representative wave (the pilot-wave gate).
6. **Validate** the pilot against explicit parity and access gates.
7. **Expand** wave by wave: coexistence → per-device cutover (un-enroll source, enroll target) → validate.
8. **Decommission** Workspace ONE per wave only after its devices pass, then retire the platform.

## Per-platform approach at a glance

| Platform | Target enrollment model | App delivery (target) | Cutover mechanics | Notes |
|---|---|---|---|---|
| Windows | Entra join / hybrid join + Windows automatic enrollment | Win32 (`.intunewin`), Store (new), MSI line-of-business | Unenroll from source, auto-enroll to Intune; often no wipe | Hybrid join needs Entra Connect + GPO/SCP. |
| iOS/iPadOS | APNs; corporate via ABM/ADE; BYOD via user enrollment / device enrollment | VPP/managed store apps, managed app config | Corporate ADE devices typically wipe/reset; BYOD re-enrolls | ADE re-assignment is done in `business.apple.com`. |
| Android | managed Google Play (Android Enterprise): work profile / fully managed / dedicated | managed Google Play apps, managed config | Work profile re-enrolls; fully managed/dedicated reset | Mode chosen per ownership. |
| macOS | APNs; corporate via ABM/ADE | PKG/DMG line-of-business, managed store apps, shell scripts | Corporate ADE Macs typically wipe/reset; others re-enroll | Mirrors the Apple model. |

> **Vendor boundary:** the **Workspace ONE (VMware)** console actions in this program (export inventory, locate device/app/profile assignments, release an enrolled device, release the ADE/DEP token, retire the platform) are named by **action and control**, not by exact menu path — Workspace ONE console internals are deferred to current VMware documentation. The **Microsoft Intune / Entra / Apple Business Manager** side is given as exact navigation (`intune.microsoft.com`, `entra.microsoft.com`, `business.apple.com`).

## Benefits

- **A single Microsoft-native endpoint stack** — Intune + Entra + (optionally) Defender for Endpoint, with one console and one compliance/Conditional Access model.
- **Licensing consolidation** — Intune is typically already owned via Microsoft 365 E3/E5 / Business Premium, removing the separate Workspace ONE spend.
- **Controlled, low-surprise execution** — one program, one wave plan, pilots, parity validation, and a per-device rollback, instead of four ad-hoc platform moves.
- **Auditability** — every wave, parity policy set, enrollment profile, and group is named and recorded; every cutover is gated and evidenced.

## Honest limitations

- **This is not a same-day cutover.** A full multi-platform fleet program runs weeks to months; enrollment-plumbing lead times (APNs, ABM, managed Google Play) come first.
- **Policies and apps are rebuilt, not migrated.** There is no native Workspace ONE → Intune config import; parity is re-authored.
- **Corporate Apple/Android devices commonly require a wipe/reset** to move enrollment cleanly (especially ADE/DEP and fully managed Android) — plan user comms and data backup accordingly.
- **Coexistence is per device, not per policy.** Both platforms exist during transition, but a device is managed by exactly one at a time; "dual-managing" the same device is not a supported state.
- **Identity must lead.** Devices/users must resolve and authenticate in Entra ID before Intune can manage them; that work is foundational, not optional.

## The standard program model

This solution follows the standard deployment model — **Assess → Configure → Pilot → Validate → Expand** — applied as a phased program with named objects, an explicit **pilot-wave gate**, and per-device rollback at every cutover:

**Discover → Assess → Plan → Configure (identity + enrollment + parity rebuild) → Pilot → Validate (pilot-wave gate) → Expand (coexistence → cutover → validate, wave by wave) → Decommission.**

No production wave begins until the pilot wave passes its parity and access gates, and **no Workspace ONE device or assignment is decommissioned until its wave's devices have passed validation in Intune** and a defined grace period has elapsed.


---


# 2. Requirements — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

Each requirement is structured as **Description / Why / Verify / Implement-if-missing**. **Never assume a prerequisite exists** — verify each one before the program proceeds past the Plan gate. Requirements are numbered R1–R14. R1–R4 are **hard gating prerequisites**: no device cutover starts until they are satisfied.

> **Naming convention used throughout the program (reused verbatim in implementation and scripts):** every created object is named `<Purpose> – <Scope> – <Stage>`, where **Scope** is the platform or function (`Windows`, `iOS`, `Android`, `macOS`, `All`, `Identity`) and **Stage** is `Source` (Workspace ONE), `Target` (Intune), or `Program` (cross-cutting). Examples reused later: the security group `Wave 00 Devices – All – Pilot`, the parity policy set `Parity Policy Set – Windows – Target`, the enrollment profile `ADE Enrollment Profile – iOS – Target`.

> These layer on top of the category baseline in `global-requirements-migrations.md` (G1–G7). Where this list says "see Gn", the baseline entry is the source of truth.

---

## R1. Target Microsoft Entra ID tenant + Intune licensing/admin  *(GATING)*

- **Description:** An active Microsoft Entra ID tenant with Intune-bearing licenses for all in-scope users, and the Intune Administrator role for the migration team. (Baseline G1, G2.)
- **Why:** Intune binds to Entra; devices and users must resolve and authenticate there, and no policy/app/enrollment can be built without licensing and rights. This is the program's first gate.
- **Verify:** Sign in to `https://entra.microsoft.com` as an admin; sign in to `https://intune.microsoft.com` → **Tenant administration → Tenant status** shows active; **Tenant administration → Roles** confirms you hold **Intune Administrator**. Under licensing, confirm Intune-bearing SKUs (M365 E3/E5, Business Premium, or Intune Plan 1) cover the in-scope user count from Discovery.
- **Implement-if-missing:** Provision/confirm the tenant; assign Intune-bearing licenses sized to Discovery (add ~10% headroom for shared/kiosk devices); grant least-privilege admin roles.

## R2. Administrative access to Workspace ONE (source)  *(GATING)*

- **Description:** Administrative read access to the Workspace ONE UEM console and its REST API (and change access for the team that will release devices/tokens at cutover). (Baseline G3.)
- **Why:** Migration begins by inventorying the source — its enrolled devices, profiles, compliance, and app assignments — and ends by releasing devices and retiring the platform. You cannot plan parity for what you cannot read.
- **Verify:** You can sign in to the Workspace ONE UEM console and export a device/app/profile inventory for a sample organization group, and the REST API returns data for a test call. (Exact console locations and API auth are deferred to current VMware documentation.)
- **Implement-if-missing:** Obtain the Workspace ONE admin role and REST API credentials (API key / OAuth) from the platform owner; confirm scope covers all in-scope organization groups.

## R3. Per-platform enrollment plumbing in Intune  *(GATING per platform in scope)*

- **Description:** The Intune enrollment channels for each in-scope platform, live and **Active**: Windows automatic enrollment; Apple **APNs** certificate (iOS/iPadOS and macOS); Apple **Business Manager + ADE token** for corporate Apple devices; **managed Google Play** connection for Android. (Baseline G5.)
- **Why:** A device cannot enroll into Intune until that platform's enrollment channel exists. APNs and ABM/managed-Google-Play have real lead times and must precede any cutover for that platform.
- **Verify:** In `https://intune.microsoft.com` → **Devices → Enrollment**: Apple → **Apple MDM Push certificate** shows **Active** and not near expiry; **Enrollment program tokens** lists the ADE token (corporate Apple); **Android** → managed Google Play shows the connected Google account; **Windows → Automatic Enrollment** is configured (MDM user scope set). In `https://entra.microsoft.com` → **Mobility (MDM and MAM) → Microsoft Intune**, MDM user scope is set for Windows auto-enroll.
- **Implement-if-missing:** Add the APNs certificate (renew, never recreate); connect Apple Business Manager and upload/sync the ADE token; connect managed Google Play; set Windows MDM user scope. Each is per-platform — only the platforms in scope gate.

## R4. Identity readiness for in-scope users & devices  *(GATING)*

- **Description:** In-scope users (and, for hybrid Windows, device objects) resolve in Entra ID and can authenticate; Windows devices in scope can achieve **Entra join** or **Entra hybrid join**. (Baseline G1.)
- **Why:** Intune targets policy and apps to Entra users/devices and enforces compliance through Entra Conditional Access. Identity is the foundation every platform workstream sits on.
- **Verify:** A sample in-scope user signs in to `https://myaccount.microsoft.com`; in `https://entra.microsoft.com` → **Devices**, confirm whether in-scope Windows devices are Entra-joined/hybrid-joined or need to be. For hybrid Windows, confirm Entra Connect sync and the on-prem hybrid-join configuration (SCP/GPO).
- **Implement-if-missing:** Confirm/enable Entra Connect sync; configure Entra hybrid join (SCP via Entra Connect or GPO) for domain-joined Windows; for cloud-only, plan Entra join at enrollment.

## R5. Source estate inventory (Discovery baseline)

- **Description:** A complete, current inventory of the Workspace ONE estate: every enrolled device with platform, ownership (corporate/BYOD), assigned user, OS version, and the profiles/compliance/apps assigned to it. (Baseline G4.)
- **Why:** Wave sizing, parity scope, per-platform sequencing, and acceptance gates all derive from this baseline. You cannot plan what you have not inventoried.
- **Verify:** A device-and-assignment export exists from Workspace ONE for 100% of in-scope organization groups (the input to wave planning). Cross-check counts against the Intune target side captured by `WS1PROG-Discovery.ps1`.
- **Implement-if-missing:** Export the device/app/profile inventory from the Workspace ONE console / REST API (deferred to VMware docs for the exact export); run `scripts\WS1PROG-Discovery.ps1` (read-only) to capture the Intune/Entra target-side baseline and reconcile.

## R6. Parity scope — the profile/compliance/app catalog to rebuild

- **Description:** A documented list of every Workspace ONE profile, compliance policy, and app **in scope to achieve parity** in Intune, mapped to its Intune equivalent (configuration profile, compliance policy, app type), per platform.
- **Why:** Migration rebuilds management state; without an explicit parity catalog, profiles (Wi-Fi, VPN, certificates, restrictions) silently drop and break access at cutover.
- **Verify:** A parity matrix exists listing each source object → target Intune object → owner → High/Med/Low complexity, for Windows, iOS/iPadOS, Android, and macOS. The target rebuilds are named `Parity Policy Set – <Platform> – Target`.
- **Implement-if-missing:** Build the parity matrix from the Workspace ONE export (R5); decide per object: rebuild, retire, or replace. Flag certificate/Wi-Fi/VPN profiles as High complexity (they gate access).

## R7. Apps & app-delivery readiness in the target

- **Description:** The app sources and tooling to rebuild app delivery in Intune: the **Microsoft Win32 Content Prep Tool** (`.intunewin` packaging) for Windows, **Apple VPP** tokens (via ABM) for managed iOS/macOS apps, **managed Google Play** approvals for Android, and the source installers/metadata for line-of-business apps.
- **Why:** Apps are re-packaged and re-assigned in Intune, not exported from Workspace ONE. Managed store apps need VPP/managed-Google-Play; Win32/PKG/MSI apps need the source media.
- **Verify:** The Win32 Content Prep Tool is available; ABM **Apps and Books** (VPP) token is uploaded in Intune (Apple); managed Google Play app approvals are possible; source installers for LOB apps are gathered.
- **Implement-if-missing:** Download the Win32 Content Prep Tool; upload the Apple VPP token under **Devices → Enrollment → Apple → VPP tokens**; approve required apps in managed Google Play; collect LOB installers and silent-install commands.

## R8. Conditional Access & compliance design (do-no-harm during coexistence)

- **Description:** A Conditional Access and compliance design that lets **both** Workspace ONE-managed and Intune-managed devices retain access **during** the coexistence window, then tightens to Intune once a wave cuts over.
- **Why:** If Conditional Access requires Intune compliance before devices are migrated, un-migrated users lose access mid-program; if it never tightens, the migration earns no security benefit. The transition must be do-no-harm.
- **Verify:** A written CA plan exists describing the coexistence posture and the post-cutover tightening, plus the compliance policies `Compliance Policy – <Platform> – Target`. In `https://entra.microsoft.com` → **Protection → Conditional Access**, current policies are reviewed for migration impact.
- **Implement-if-missing:** Author the CA transition plan; create Intune compliance policies per platform; stage CA changes (report-only first) so coexisting devices are not locked out.

## R9. Pilot group and wave structure

- **Description:** A documented wave plan and the Entra security groups that drive targeting — a pilot wave and production waves grouped by department/region/platform. (Baseline G6.)
- **Why:** Every migration is piloted and ringed before fleet cutover to contain risk; Intune assignment is group-driven.
- **Verify:** In `https://entra.microsoft.com` → **Groups**, the pilot group `Wave 00 Devices – All – Pilot` exists and the wave plan (`Wave-Plan – Program – Program.csv`) is documented; per-wave groups follow `Wave NN Devices – <Scope> – Wave NN`.
- **Implement-if-missing:** Create the pilot and wave groups (Entra → **Groups → New group → Security**); generate the plan with `scripts\WS1PROG-Set-WaveTargeting.ps1`.

## R10. Migration service / API accounts (both platforms)

- **Description:** Dedicated, least-privilege accounts for automation: a Workspace ONE REST API credential (source) and an Entra app registration / service account with the scoped Microsoft Graph permissions the scripts need (target).
- **Why:** Tooling should authenticate as named, scoped identities (not personal admin accounts) for auditability and so cutover does not depend on one person's session.
- **Verify:** `Migration SvcAcct – WS1 API – Source` (Workspace ONE REST credential) and `Migration App – Graph – Target` (Entra app registration with `DeviceManagementManagedDevices.Read.All`, `DeviceManagementConfiguration.ReadWrite.All`, `Group.ReadWrite.All`, etc., consented) exist and authenticate.
- **Implement-if-missing:** Create the Workspace ONE API credential (deferred to VMware docs); register the Entra app, grant and admin-consent the least-privilege Graph scopes the scripts require.

## R11. Network, endpoints, and device prerequisites

- **Description:** Network egress to the required Intune/Apple/Google endpoints from where devices live, and per-platform device prerequisites (supported OS versions, Apple/Google account posture, sufficient free disk for re-imaging where ADE wipe applies).
- **Why:** Enrollment and app delivery depend on reaching Microsoft, Apple (APNs), and Google (managed Play) endpoints; unsupported OS versions or blocked endpoints fail enrollment silently.
- **Verify:** Confirm the Intune/Apple/Google required endpoints are reachable (allow-listed in proxy/firewall); confirm in-scope OS versions meet Intune minimums; confirm corporate Apple/Android devices that will reset have a backup/restore path.
- **Implement-if-missing:** Allow-list the required endpoints; remediate unsupported OS versions before their wave; document the backup/restore path for wipe-based cutovers.

## R12. Communications & change management

- **Description:** A per-wave communications plan (what users will see and must do — re-enroll, sign in, MFA, app reinstall, possible reset) and an approved change process with maintenance windows. (Baseline G7.)
- **Why:** Re-enrollment is user-visible and some platforms reset; uncommunicated cutovers generate helpdesk floods and failed waves.
- **Verify:** Approved change records exist per planned wave cutover; comms templates exist (announce → pre-cutover steps → cutover-complete).
- **Implement-if-missing:** Stand up the change/comms process; author per-platform user instructions (re-enroll vs. reset path).

## R13. Coexistence & rollback posture (per platform)

- **Description:** A defined coexistence approach (source manages un-migrated devices, target manages migrated ones; a device is managed by one platform at a time) and a documented **per-device rollback** (re-enroll to Workspace ONE / revert assignment) usable inside the change window. (Baseline G7.)
- **Why:** Cutovers touch live production devices and must be reversible; coexistence must be explicit so the same device is never targeted by both platforms simultaneously.
- **Verify:** A written coexistence + rollback runbook exists per platform, approved before any cutover; the order coexistence → cutover → decommission is documented.
- **Implement-if-missing:** Author the per-platform rollback (how to re-enroll to source, how to revert the Intune assignment); define the grace period before source decommission.

## R14. Decommission & data-retention plan for Workspace ONE

- **Description:** A plan to retire Workspace ONE only after each wave validates in Intune: release devices/tokens, export any retained records, reclaim/cancel Workspace ONE licensing.
- **Why:** Premature source decommission removes the rollback path and can orphan devices; orderly decommission is the program's final, evidenced step.
- **Verify:** A decommission checklist exists keyed to per-wave validation (no source resource retired until its wave passes and the grace period elapses); a record-retention/export step is defined.
- **Implement-if-missing:** Author the decommission checklist; identify records to export; plan the Workspace ONE license/tenant wind-down with the platform owner (deferred to VMware docs for console steps). See also `07-best-practices.md`.


---


# Global Requirements — Migrations (category-level)

These requirements apply to **every** solution in the **Migrations** category (platform-to-platform
migration programs — e.g. Workspace ONE → Microsoft Intune, Configuration Manager → Intune, Group
Policy → Intune, Exchange/Microsoft 365 tenant moves). They are published once at the category level
so individual listings stay small. Confirm these before running *any* Migrations solution. Each entry:
**Description · Why · Verify · Implement-if-missing.**

## G1. Target Microsoft Entra ID tenant
**Description:** An active, correctly-configured Microsoft Entra ID (Azure AD) tenant — the migration target's identity backbone.
**Why:** Every modern endpoint/identity workload binds to Entra ID; users and devices must resolve there before migration.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create/confirm the Microsoft 365 / Azure subscription that provisions the tenant.

## G2. Target platform licensing & admin access (Intune)
**Description:** An Intune-bearing license plan and the admin roles to build/assign policies and apps in the target.
**Why:** You can't rebuild apps, profiles, or enrollment in the target without licensing and rights.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** active; you hold **Intune Administrator**.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1; grant least-privilege admin roles.

## G3. Access to the SOURCE platform
**Description:** Administrative read (and, for cutover, change) access to the platform you are migrating *from* (e.g. Workspace ONE UEM, Configuration Manager, Active Directory, the source tenant).
**Why:** Migration begins by inventorying and exporting the source's apps, profiles, policies, and device assignments.
**Verify:** You can sign in to the source console and export/inventory its configuration for a sample.
**Implement:** Obtain the source admin role / API credentials from the platform owner.

## G4. A current inventory / source of truth
**Description:** An accurate inventory of in-scope devices, users, apps, and policies on the source platform.
**Why:** Wave planning, parity validation, and decommission all depend on knowing exactly what is in scope.
**Verify:** You can produce a device/app/policy export from the source for the migration scope.
**Implement:** Build the inventory from the source console / discovery before scoping waves.

## G5. Enrollment prerequisites for the target
**Description:** The enrollment plumbing for each in-scope platform — e.g. Apple MDM Push (APNs) certificate and Apple Business Manager for iOS/iPadOS/macOS, managed Google Play for Android, automatic enrollment for Windows.
**Why:** Devices cannot move to the target MDM until its enrollment channels are live.
**Verify:** In Intune, the relevant connector/cert/token shows **Active** for each platform in scope.
**Implement:** Configure the APNs certificate, ABM/ADE token, managed Google Play, and Windows automatic enrollment as needed.

## G6. A pilot group and wave structure
**Description:** A Microsoft Entra security group for the pilot, and a planned set of migration waves/rings.
**Why:** Every migration is piloted and ringed before fleet cutover to contain risk.
**Verify:** Entra → **Groups**; the pilot group exists and the wave plan is documented.
**Implement:** Entra → **Groups → New group → Security**; define waves by department/region/device type.

## G7. Change control, coexistence, and a rollback path
**Description:** A change window, a defined coexistence approach (both platforms managed during transition), and a documented rollback (re-enroll to source / revert assignment).
**Why:** Migrations touch live, enrolled production devices; cutover must be reversible and coordinated.
**Verify:** A rollback procedure and coexistence plan are written and approved before any cutover.
**Implement:** Define rollback per platform, a comms plan, and the order of operations for coexistence → cutover → decommission.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

This is the **program runbook**. It follows the standard program model — **Discover → Assess → Plan → Configure → Pilot → Validate (pilot-wave gate) → Expand (coexistence → cutover → validate) → Decommission** — and contains a phase-by-phase methodology plus a self-contained runbook for each of the four platform workstreams.

> **Vendor boundary (read first):** the **Microsoft Intune / Entra / Apple Business Manager** side is given as exact navigation. The **Workspace ONE (VMware)** side is named by **action and control** only — exact Workspace ONE console menus are deferred to current VMware documentation. Target portals used below:
> - Microsoft Intune admin center: `https://intune.microsoft.com`
> - Microsoft Entra admin center: `https://entra.microsoft.com`
> - Apple Business Manager: `https://business.apple.com`
> - Managed Google Play / Google admin: reached through the Intune Android enrollment connector.

> **Naming convention (mandatory, reused verbatim):** every created object is `<Purpose> – <Scope> – <Stage>`. **Scope** = `Windows | iOS | Android | macOS | All | Identity`; **Stage** = `Source` (Workspace ONE) | `Target` (Intune) | `Program`. Canonical names introduced in a phase are reused later: `Wave 00 Devices – All – Pilot`, `Parity Policy Set – <Platform> – Target`, `Compliance Policy – <Platform> – Target`, `ADE Enrollment Profile – iOS – Target`, `ADE Enrollment Profile – macOS – Target`, `Wave NN Devices – <Scope> – Wave NN`.

---

## Phase 1 — Discover

**Goal:** produce the authoritative estate baseline for both sides.

1. **Source (Workspace ONE):** export the full device, profile, compliance, and app-assignment inventory from the Workspace ONE console / REST API for every in-scope organization group. (Action named; exact export deferred to VMware docs.) Capture per device: platform, ownership (corporate/BYOD), assigned user (UPN), OS version, and the profiles/apps assigned.
2. **Target (Intune/Entra):** run the read-only `scripts\WS1PROG-Discovery.ps1` to baseline the Intune side — existing managed devices, enrollment configuration (APNs/ADE/managed Google Play/Windows auto-enroll status), groups, and licensing readiness.
3. **Reconcile** the two: every in-scope Workspace ONE user must resolve to an Entra user (match on UPN); flag mismatches now (they break targeting later).
4. Record **counts per platform** (Windows / iOS-iPadOS / Android / macOS) and per ownership (corporate vs. BYOD) — these drive wave sizing and the per-platform cutover mechanics (reset vs. re-enroll).

**Exit gate:** a signed-off source inventory plus the Intune-side baseline CSV (`Estate-Inventory – Discovery – Source.csv` for the source export, plus the script's `Intune-Baseline – Discovery – Target.csv`), covering 100% of in-scope devices, with UPN reconciliation complete.

---

## Phase 2 — Assess

**Goal:** turn the inventory into a sized, risk-rated parity plan.

1. **Parity matrix (R6):** for each platform, list every in-scope Workspace ONE profile, compliance policy, and app → its Intune equivalent → owner → High/Med/Low complexity. Mark **certificate, Wi-Fi, and VPN** profiles High — they gate access and must be exact.
2. **App assessment (R7):** classify each app as managed-store (VPP / managed Google Play / new Store), Win32/PKG/MSI line-of-business (needs source media + silent command), or retire.
3. **Cutover mechanics per cohort:** corporate Apple (ADE) and fully managed/dedicated Android cohorts typically **reset**; Windows and BYOD cohorts typically **re-enroll without wipe**. Tag each cohort.
4. **Conditional Access impact (R8):** review current CA for anything that would lock out un-migrated devices during coexistence.

**Exit gate:** an approved parity matrix and app catalog with a complexity rating per object and a cutover-mechanic tag per cohort.

---

## Phase 3 — Plan

**Goal:** wave plan + per-platform sequencing + named objects.

1. **Generate the wave plan + groups** from Discovery:
   - `scripts\WS1PROG-Set-WaveTargeting.ps1 -InputCsv "Estate-Inventory – Discovery – Source.csv" -OutputCsv "Wave-Plan – Program – Program.csv"` groups devices/users into waves (`Wave 00 … Wave NN`), keeping departments/cohorts together, and (with `-Apply`) creates the Entra security groups `Wave 00 Devices – All – Pilot` and `Wave NN Devices – <Scope> – Wave NN`.
2. **Pilot wave:** designate `Wave 00 Devices – All – Pilot` — a small representative spread (e.g. 10–25 devices) **covering every in-scope platform and both ownership types**, so the pilot exercises every cutover mechanic.
3. **Per-platform sequencing (recommended within each wave):** Windows and BYOD cohorts first (lowest user disruption, no wipe), then corporate Apple/Android reset cohorts (highest disruption, most comms).
4. **Name every object** that will be created (parity policy sets, compliance policies, enrollment profiles, apps, groups) and record them in the program register.
5. **Schedule cutover windows and rollback owners** per wave (R12, R13).

**Exit gate:** approved `Wave-Plan – Program – Program.csv`, created wave groups, named objects, scheduled windows.

---

## Phase 4 — Configure the Intune target

**Goal:** stand up identity, enrollment, parity policy, and apps so devices have a known-good state to land in. **Prerequisites R1–R4 (and R3 per platform in scope) must be satisfied.**

### 4.1 Confirm enrollment plumbing (R3)
At `https://intune.microsoft.com` → **Devices → Enrollment**:
- **Apple → Apple MDM Push certificate:** **Active**, not near expiry (renew, never recreate).
- **Apple → Enrollment program tokens:** the ADE token is present and synced (corporate Apple). VPP token present under **Apple → VPP tokens** (R7).
- **Android → managed Google Play:** the connected Google account shows linked.
- **Windows → Automatic Enrollment:** MDM user scope set (mirror in `https://entra.microsoft.com` → **Mobility (MDM and MAM) → Microsoft Intune**).

### 4.2 Rebuild parity policy sets (R6) — per platform
For each platform create the configuration profiles that achieve parity with Workspace ONE, grouped under the named set `Parity Policy Set – <Platform> – Target`:
- `https://intune.microsoft.com` → **Devices → Configuration → Create → New policy** → select **Platform** and **Profile type**; re-author Wi-Fi, VPN, certificates (SCEP/PKCS — stand up the connector first if used), restrictions, and platform-specific settings to match the source.
- Assign each profile to the **wave groups** (start unassigned or pilot-only; production groups are added at expand).

### 4.3 Create compliance policies (R8) — per platform
`https://intune.microsoft.com` → **Devices → Compliance → Create policy** → per platform → author `Compliance Policy – <Platform> – Target` (OS minimums, encryption, jailbreak/root, etc.). Pair with the Conditional Access transition plan (do-no-harm during coexistence).

### 4.4 Rebuild apps (R7) — per platform
`https://intune.microsoft.com` → **Apps → All apps → Add**:
- **Windows:** Win32 app (`.intunewin` from the Win32 Content Prep Tool) with silent install/uninstall/detection; or Microsoft Store app (new); or line-of-business MSI.
- **iOS/iPadOS & macOS:** iOS/macOS store app (VPP-backed, identify by exact publisher + bundle ID), or line-of-business (`.ipa` / `.pkg`/`.dmg`), plus managed app configuration where the source had it.
- **Android:** managed Google Play app (approve in managed Google Play), with managed config.
- Name nothing ad hoc — record each app and its assignment in the parity matrix.

**Exit gate:** enrollment channels Active per platform; `Parity Policy Set – <Platform> – Target`, `Compliance Policy – <Platform> – Target`, and the app set built and ready to assign; Conditional Access staged report-only.

---

## Phase 5 — Pilot

Run **every** in-scope platform workstream end-to-end against `Wave 00 Devices – All – Pilot`. Assign the parity policy sets, compliance policies, and apps to the pilot group; execute each platform's cutover runbook (Phase 7) for the pilot devices only. Capture real timings per platform to refine the wave schedule. **No production wave starts until Phase 6 passes.**

---

## Phase 6 — Validate (the pilot-wave gate)

Run `scripts\WS1PROG-Validation.ps1` plus the manual gates in `05-testing.md` against the pilot devices. The pilot-wave gate is the program's go/no-go: it passes only when every platform's acceptance gate (enrollment, parity, compliance, app delivery, access) passes for the pilot wave. **Do not expand to production waves until this gate is green.** Record results in `Validation Results – Program – Wave 00`.

---

## Workstream Runbooks (Phase 7 — Expand: coexistence → cutover → validate, per platform)

Each runbook runs **per wave** after the pilot gate passes. The pattern per device is identical: ensure the target state is assigned → **un-enroll from Workspace ONE** → **enroll into Intune** → confirm parity/compliance/apps → validate. Both platforms coexist across the fleet during this phase, but each device is managed by exactly one.

> **Coexistence rule (all platforms):** target only **migrated** devices with the production assignment, via the wave group `Wave NN Devices – <Scope> – Wave NN`. Never assign the same device to both platforms at once; that is the failure mode the wave model prevents.

### WS-A — Windows

1. **Assign target state:** add `Wave NN Devices – Windows – Wave NN` to `Parity Policy Set – Windows – Target`, `Compliance Policy – Windows – Target`, and the Windows apps.
2. **Identity:** confirm each device will Entra-join or Entra-hybrid-join (R4). For hybrid, the SCP/Entra Connect config must already publish the join.
3. **Cutover (per device, usually no wipe):**
   - In Workspace ONE, **release / unenroll** the Windows device from source management (action named; deferred to VMware docs).
   - With Windows automatic enrollment configured (R3), the device **auto-enrolls into Intune** on the next Entra sign-in / MDM enrollment; or trigger enrollment via **Access work or school → Connect**. The `WS1PROG-Set-WaveTargeting.ps1` group membership pulls policy/apps.
4. **Confirm** profiles (Wi-Fi/VPN/cert), compliance, and apps land (see `05-testing.md` Windows gate).
5. **Remediate** failed devices with `WS1PROG-Remediation.ps1` (e.g. `-Mode RetryEnrollmentSync` / `-Mode AddToWaveGroup`).

**Named objects:** `Wave NN Devices – Windows – Wave NN`, `Parity Policy Set – Windows – Target`, `Compliance Policy – Windows – Target`.

### WS-B — iOS/iPadOS

1. **Assign target state:** add `Wave NN Devices – iOS – Wave NN` to `Parity Policy Set – iOS – Target`, `Compliance Policy – iOS – Target`, and the iOS apps (VPP-backed where managed).
2. **Corporate (ADE) devices:**
   - In **Apple Business Manager** (`https://business.apple.com`) → **Devices**, **re-assign** the device's MDM server from the Workspace ONE MDM server to the **Intune MDM server**. (ABM is the system of record for ADE assignment — a device's MDM server is changed here, then released from the source.)
   - In Workspace ONE, **release** the device (action named; deferred to VMware docs).
   - Create/confirm the Intune ADE enrollment profile: `https://intune.microsoft.com` → **Devices → Enrollment → Apple → Enrollment program tokens → (open the ADE token) → Profiles → Create profile → iOS/iPadOS** → name it `ADE Enrollment Profile – iOS – Target`; assign it to the synced devices. The device is then **wiped/reset** and re-enrolls into Intune through Setup Assistant.
3. **BYOD / user-enrollment devices:** user removes the Workspace ONE management profile (action named; deferred to VMware docs) and re-enrolls via the Intune Company Portal app.
4. **Confirm** APNs-delivered profiles, compliance, and managed apps install (see `05-testing.md` iOS gate).

**Named objects:** `Wave NN Devices – iOS – Wave NN`, `ADE Enrollment Profile – iOS – Target`, `Parity Policy Set – iOS – Target`, `Compliance Policy – iOS – Target`.

### WS-C — Android

1. **Assign target state:** add `Wave NN Devices – Android – Wave NN` to `Parity Policy Set – Android – Target`, `Compliance Policy – Android – Target`, and the managed Google Play apps.
2. **Pick the enrollment mode per ownership** (matches the source posture): work profile (BYOD), fully managed (corporate), or dedicated/kiosk. Confirm the corresponding Intune enrollment profile under **Devices → Enrollment → Android → (mode)**.
3. **Cutover (per device):**
   - **Work profile:** user removes the Workspace ONE work profile (action named; deferred to VMware docs) and re-enrolls via Company Portal.
   - **Fully managed / dedicated:** device is **factory reset** and enrolled into Intune via the corporate enrollment method (QR / NFC / zero-touch / token).
4. **Confirm** managed Google Play apps and policies land (see `05-testing.md` Android gate).

**Named objects:** `Wave NN Devices – Android – Wave NN`, `Parity Policy Set – Android – Target`, `Compliance Policy – Android – Target`.

### WS-D — macOS

1. **Assign target state:** add `Wave NN Devices – macOS – Wave NN` to `Parity Policy Set – macOS – Target`, `Compliance Policy – macOS – Target`, and the macOS apps (PKG/DMG/managed store, plus shell scripts where the source used custom config).
2. **Corporate (ADE) Macs:** in **Apple Business Manager** → **Devices**, re-assign the Mac's MDM server to the **Intune MDM server**; **release** the Mac from Workspace ONE (action named; deferred to VMware docs); create/confirm `https://intune.microsoft.com` → **Devices → Enrollment → Apple → Enrollment program tokens → (open the ADE token) → Profiles → Create profile → macOS** → `ADE Enrollment Profile – macOS – Target`. The Mac is **wiped/reset** and re-enrolls through Setup Assistant.
3. **Non-ADE Macs:** remove the Workspace ONE management profile (action named; deferred to VMware docs) and enroll via the Company Portal / enrollment profile download.
4. **Confirm** APNs-delivered profiles, FileVault/compliance, and apps land (see `05-testing.md` macOS gate).

**Named objects:** `Wave NN Devices – macOS – Wave NN`, `ADE Enrollment Profile – macOS – Target`, `Parity Policy Set – macOS – Target`, `Compliance Policy – macOS – Target`.

---

## Phase 8 — Validate (per wave)

After each wave's cutover, run `scripts\WS1PROG-Validation.ps1` and the manual gates in `05-testing.md` for every platform in the wave: enrollment state, parity profiles applied, compliance evaluated, apps installed, and access (Conditional Access) working. Track wave progress with `scripts\WS1PROG-Report.ps1`. **No Workspace ONE device or assignment is decommissioned until its wave passes.**

**Exit gate:** all platform acceptance gates PASS for the wave; report shows 100% migrated-and-compliant for the wave.

---

## Phase 9 — Tighten Conditional Access (per wave / at fleet completion)

As waves complete, move the staged Conditional Access from report-only to enforced so access requires Intune compliance — but only for cohorts that have cut over (R8, do-no-harm). At full fleet completion, the org requires Intune-managed, compliant devices everywhere.

---

## Phase 10 — Decommission Workspace ONE

**Goal:** retire the source under change control, only after validation.

1. **Confirm** all waves validated (`WS1PROG-Report.ps1` shows 100% migrated per platform and the grace period elapsed).
2. **Soft-retire first:** keep migrated devices read-only in Workspace ONE / disable assignments for a defined **grace period** so per-device rollback stays available (R13).
3. **Release devices and tokens:** release remaining devices from Workspace ONE; release the ADE/DEP token from the source so ABM assignment is fully owned by Intune (action named; deferred to VMware docs).
4. **Export retained records** (compliance/inventory history) per policy before teardown.
5. **Reclaim/cancel Workspace ONE licensing/tenant** last, with the platform owner (deferred to VMware docs for console steps).
6. **Document** final state and archive the program register as evidence.

**Exit gate:** Workspace ONE retired; ADE/DEP fully owned by Intune; evidence archived; program closed.


---


# 5. Testing & Acceptance — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

Testing is organized as numbered tests, each with an explicit **PASS/FAIL gate**, grouped by platform plus program-level groups. Each platform also has an **acceptance gate** — the combined condition that must be met before that platform's wave is declared complete and before the corresponding Workspace ONE devices may be decommissioned (Phase 10). The pilot wave must clear **all** gates before any production wave begins (the pilot-wave gate).

> Run `scripts\WS1PROG-Validation.ps1` to automate the scripted portions; the manual gates below are operator-verified on a device. Record results in `Validation Results – Program – <Wave NN>`.

---

## Group 0 — Target readiness (run before any cutover)

**T0.1 — Enrollment plumbing.** In `https://intune.microsoft.com` → **Devices → Enrollment**, APNs is **Active** (not near expiry), the ADE token is synced (corporate Apple), managed Google Play is connected (Android), and Windows automatic enrollment is set.
- PASS: every in-scope platform's channel is Active. FAIL: any required channel missing/expired.

**T0.2 — Parity & compliance built.** `Parity Policy Set – <Platform> – Target` and `Compliance Policy – <Platform> – Target` exist for each in-scope platform.
- PASS: present for all in-scope platforms. FAIL: any missing.

**Target-readiness gate:** T0.1–T0.2 PASS before assigning to any wave.

---

## Group 1 — Windows

**T1.1 — Enrollment state.** The device shows in `https://intune.microsoft.com` → **Devices → Windows** as Intune-managed and Entra-joined/hybrid-joined, and is no longer managed by Workspace ONE.
- PASS: Intune-managed, single MDM. FAIL: not enrolled or dual-managed.

**T1.2 — Parity profiles.** Wi-Fi, VPN, certificate, and restriction profiles from `Parity Policy Set – Windows – Target` show **Succeeded**.
- PASS: all applied. FAIL: any profile error / missing access (e.g. Wi-Fi cert).

**T1.3 — Compliance.** Device evaluates **Compliant** against `Compliance Policy – Windows – Target`.
- PASS: Compliant. FAIL: Not compliant.

**T1.4 — Apps.** Required Windows apps (Win32/Store/MSI) install and report **Installed**.
- PASS: all required apps installed. FAIL: install failure.

**Windows acceptance gate:** T1.1–T1.4 PASS for 100% of the wave's Windows devices.

---

## Group 2 — iOS/iPadOS

**T2.1 — Enrollment state.** Device shows Intune-managed under **Devices → iOS/iPadOS**; corporate devices show enrolled via `ADE Enrollment Profile – iOS – Target`; no Workspace ONE management profile remains.
- PASS: Intune-managed, single MDM. FAIL: still on source / unmanaged.

**T2.2 — Parity profiles.** Wi-Fi, VPN, certificate, and restriction profiles apply (delivered via APNs).
- PASS: profiles present and effective. FAIL: missing profile / broken access.

**T2.3 — Compliance.** Device is **Compliant** against `Compliance Policy – iOS – Target`.
- PASS: Compliant. FAIL: Not compliant.

**T2.4 — Apps.** VPP/managed apps install with correct managed app config.
- PASS: apps installed, config applied. FAIL: app/config missing.

**iOS/iPadOS acceptance gate:** T2.1–T2.4 PASS for the wave's iOS devices.

---

## Group 3 — Android

**T3.1 — Enrollment state & mode.** Device shows Intune-managed under **Devices → Android** in the correct mode (work profile / fully managed / dedicated); no Workspace ONE work profile remains.
- PASS: correct mode, single MDM. FAIL: wrong mode / still on source.

**T3.2 — Parity profiles.** Android policies (restrictions, Wi-Fi, certificate) apply.
- PASS: applied. FAIL: missing.

**T3.3 — Compliance.** Device is **Compliant** against `Compliance Policy – Android – Target`.
- PASS: Compliant. FAIL: Not compliant.

**T3.4 — Apps.** managed Google Play apps install with managed config.
- PASS: apps installed. FAIL: install failure.

**Android acceptance gate:** T3.1–T3.4 PASS for the wave's Android devices.

---

## Group 4 — macOS

**T4.1 — Enrollment state.** Mac shows Intune-managed under **Devices → macOS**; corporate Macs show enrolled via `ADE Enrollment Profile – macOS – Target`; no Workspace ONE profile remains.
- PASS: Intune-managed, single MDM. FAIL: still on source / unmanaged.

**T4.2 — Parity profiles.** Wi-Fi, VPN, certificate, and configuration profiles (and any shell scripts) apply.
- PASS: applied. FAIL: missing / broken access.

**T4.3 — Compliance.** Mac is **Compliant** (e.g. FileVault, OS minimum) against `Compliance Policy – macOS – Target`.
- PASS: Compliant. FAIL: Not compliant.

**T4.4 — Apps.** PKG/DMG/managed-store apps install.
- PASS: apps installed. FAIL: install failure.

**macOS acceptance gate:** T4.1–T4.4 PASS for the wave's Macs.

---

## Group 5 — Identity & Access (program-level, per wave)

**T5.1 — Sign-in & MFA.** A migrated user signs in and satisfies MFA on the migrated device.
- PASS: authenticates. FAIL: auth error.

**T5.2 — Conditional Access.** Migrated, compliant devices retain access; the do-no-harm posture has not locked out un-migrated cohorts in the same wave window.
- PASS: migrated devices access resources, un-migrated cohorts unaffected. FAIL: lockout of either.

**Access acceptance gate:** T5.1–T5.2 PASS for the wave.

---

## Group 6 — Coexistence integrity (program-level)

**T6.1 — Single-MDM check.** No in-scope device is simultaneously managed by Workspace ONE and Intune.
- PASS: every migrated device is single-MDM (Intune). FAIL: any dual-managed device.

**T6.2 — Rollback rehearsal (pilot only).** On a pilot device, the documented per-device rollback (re-enroll to Workspace ONE / revert assignment) is exercised successfully.
- PASS: rollback restores source management. FAIL: rollback fails.

**Coexistence acceptance gate:** T6.1 PASS for the wave; T6.2 PASS once during pilot.

---

## Program-level exit (per wave)

A wave is **complete** only when **every** platform acceptance gate plus the access and coexistence gates above are PASS, and `scripts\WS1PROG-Report.ps1` shows the wave 100% migrated-and-compliant. **No Workspace ONE device or assignment may be decommissioned** (Phase 10) until its wave's gates pass and the grace period defined in `07-best-practices.md` has elapsed. The **pilot wave** must clear all of the above before any production wave begins.


---


# 6. Troubleshooting — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

Failure modes and fixes, grouped by area. Most migration problems trace back to two root causes: **a device still (partly) enrolled in Workspace ONE while Intune tries to take over**, and **a profile/app that was never rebuilt to parity** in the target. Workspace ONE console actions below are named by action only — exact menus are deferred to current VMware documentation.

---

## A. Enrollment — device won't enroll into Intune

**Symptom:** Windows device released from Workspace ONE but does not appear in Intune.
- **Cause:** Windows automatic enrollment / MDM user scope not set, or the device hasn't re-signed in to Entra.
- **Fix:** Confirm `https://entra.microsoft.com` → **Mobility (MDM and MAM) → Microsoft Intune** MDM user scope (R3); on the device, **Access work or school → Connect** or sign out/in; re-run `WS1PROG-Remediation.ps1 -Mode RetryEnrollmentSync`.

**Symptom:** iOS/macOS device fails to enroll or shows an APNs error.
- **Cause:** APNs certificate missing/expired, or it was **recreated** instead of renewed (which orphans existing devices).
- **Fix:** In `https://intune.microsoft.com` → **Devices → Enrollment → Apple → Apple MDM Push certificate**, confirm **Active**; if expired, **renew** the same certificate (never recreate). Re-attempt enrollment.

**Symptom:** Android device won't enroll in the expected mode.
- **Cause:** managed Google Play not connected, or the wrong enrollment profile/mode for the device's ownership.
- **Fix:** Confirm **Devices → Enrollment → Android** managed Google Play is connected; select the correct mode (work profile / fully managed / dedicated) for the cohort; for fully managed/dedicated, the device must be factory reset and enrolled via the corporate method.

---

## B. Coexistence — dual management / single-MDM violations

**Symptom:** Device shows managed by both Workspace ONE and Intune (or behaves erratically with conflicting policy).
- **Cause:** The device was assigned the Intune production state before being released from Workspace ONE — both platforms targeting the same device.
- **Fix:** A device is single-MDM by design. Release it from Workspace ONE (action named; deferred to VMware docs), confirm only the Intune enrollment remains, then re-validate (T6.1). Target only migrated devices via `Wave NN Devices – <Scope> – Wave NN`.

**Symptom:** Un-migrated users in the same wave window lose access during coexistence.
- **Cause:** Conditional Access was tightened to require Intune compliance before those devices migrated.
- **Fix:** Restore the do-no-harm posture (R8): set the tightening CA policy to **report-only**, and enforce Intune-compliance requirements **only** for cohorts that have cut over (Phase 9).

---

## C. Apple Business Manager / ADE assignment

**Symptom:** Corporate Apple device re-enrolls but lands unmanaged or on the wrong MDM.
- **Cause:** The device's MDM server in Apple Business Manager still points at the source, or no Intune ADE enrollment profile is assigned.
- **Fix:** In `https://business.apple.com` → **Devices**, re-assign the device's **MDM server** to the Intune MDM server; in `https://intune.microsoft.com` → **Devices → Enrollment → Apple → Enrollment program tokens → (open the ADE token) → Profiles**, confirm `ADE Enrollment Profile – iOS – Target` / `ADE Enrollment Profile – macOS – Target` is assigned; reset the device so Setup Assistant re-enrolls it into Intune.

**Symptom:** ADE token shows no devices / devices missing after sync.
- **Cause:** Token not synced, or devices not yet released by the source.
- **Fix:** Sync the ADE token in Intune; release the devices from Workspace ONE / re-assign in ABM; re-sync. Releasing the source DEP/ADE token entirely is a Phase 10 (decommission) step, not a per-device one.

---

## D. Parity profiles — applied in Intune but access broken

**Symptom:** Device shows compliant/enrolled but loses Wi-Fi, VPN, or a certificate-gated resource after leaving Workspace ONE.
- **Cause:** The Wi-Fi / VPN / certificate profile was not rebuilt to parity, or the certificate connector (SCEP/PKCS) isn't issuing.
- **Fix:** Check `Parity Policy Set – <Platform> – Target` for the missing profile; rebuild it in **Devices → Configuration** to match the source exactly; if cert-based, confirm the SCEP/PKCS connector is healthy and the profile chains correctly. A profile that shows **Succeeded** but doesn't grant access is still a FAIL (T*.2) — test real access.

**Symptom:** Profile shows **Error** / conflict in Intune.
- **Cause:** Two profiles set conflicting values, or a residual Workspace ONE profile remains on the device.
- **Fix:** Resolve the conflicting Intune profiles; confirm the Workspace ONE management profile was fully removed at cutover; re-sync the device.

---

## E. App delivery

**Symptom:** Required apps don't install after migration.
- **Cause:** App not rebuilt/assigned in Intune, missing VPP/managed-Google-Play licensing, or a bad Win32 detection rule/silent command.
- **Fix:** Confirm the app exists in **Apps → All apps** and is assigned to the wave group; for store apps confirm VPP/managed Google Play licensing; for Win32 verify the `.intunewin`, silent install/uninstall, and **detection rule**. Identify store apps by exact publisher + bundle/package ID to avoid the wrong app.

**Symptom:** App installs but per-app config (mail, per-app VPN) is missing.
- **Cause:** Managed app configuration that Workspace ONE delivered was not rebuilt.
- **Fix:** Add the Intune managed app configuration policy for that app; re-assign; re-validate (T*.4).

---

## F. Compliance & Conditional Access

**Symptom:** Migrated device shows **Not compliant**.
- **Cause:** `Compliance Policy – <Platform> – Target` not assigned, OS below minimum, or encryption/jailbreak/root check failing.
- **Fix:** Confirm the compliance policy is assigned to the wave group; remediate the failing setting (OS update, enable encryption); use `WS1PROG-Remediation.ps1 -Mode ReEvaluateCompliance` to force a re-check.

**Symptom:** User blocked from resources right after a successful migration.
- **Cause:** Compliance not yet evaluated, or CA enforcing before the grace evaluation completes.
- **Fix:** Allow compliance evaluation to complete; confirm the device is Compliant (T*.3); keep CA report-only for the wave until devices evaluate, then enforce (Phase 9).

---

## G. Identity / targeting

**Symptom:** Device enrolls but receives no policy or apps.
- **Cause:** The device/user isn't in the wave group, or the user didn't reconcile to an Entra user (UPN mismatch from Discovery).
- **Fix:** Confirm membership of `Wave NN Devices – <Scope> – Wave NN`; fix the UPN reconciliation flagged in Phase 1; re-add with `WS1PROG-Remediation.ps1 -Mode AddToWaveGroup`.

**Symptom:** Hybrid Windows device won't Entra-hybrid-join.
- **Cause:** SCP/Entra Connect hybrid-join config incomplete, or the device hasn't synced.
- **Fix:** Confirm Entra Connect sync and the hybrid-join SCP/GPO (R4); allow the join task to run; verify in `https://entra.microsoft.com` → **Devices**.

---

## H. Rollback

**Symptom:** A migrated device must be reverted to Workspace ONE.
- **Cause:** Failed parity/access on a production device inside the change window.
- **Fix:** Execute the documented per-device rollback (R13): revert/remove the Intune assignment, re-enroll the device into Workspace ONE (action named; deferred to VMware docs). Only possible while the source assignment is still warm — which is why the grace period exists before decommission (Phase 10).

**Symptom:** Rollback fails because the source already released the device/token.
- **Cause:** Workspace ONE was decommissioned (or the device released) before the grace period elapsed.
- **Fix:** Do not decommission until the wave passes and the grace period elapses (Phase 10 discipline). If already released, treat the device as a fresh Intune enrollment and remediate forward rather than rolling back.

---

## I. Reporting / evidence gaps

**Symptom:** Wave status is unclear or a device's state is ambiguous.
- **Cause:** The program register / wave plan isn't current, or reporting wasn't run per wave.
- **Fix:** Run `scripts\WS1PROG-Report.ps1` after each wave; keep the named-object list, wave plan, and per-gate results current as you go (best practice §07) — backfilling after the fact is unreliable and undermines rollback decisions.


---


# 7. Best Practices — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

Program-grade practices for a UEM exit across live, enrolled production devices. These reduce risk, protect user access, and produce the evidence a controlled migration requires.

## Program & wave planning

- **Lead with enrollment plumbing, not policy.** APNs (Apple), Apple Business Manager + ADE token, managed Google Play, and Windows automatic enrollment (R3) have real lead times and gate every cutover for their platform. Stand them up first.
- **Pilot every platform end-to-end.** `Wave 00 Devices – All – Pilot` must include each in-scope platform **and** both ownership types so the pilot exercises every cutover mechanic (no-wipe re-enroll and ADE/fully-managed reset). The pilot-wave gate is the program's go/no-go.
- **Keep cohorts intact.** Group a user, their device(s), and their department into the same wave so collaboration and shared resources move together.
- **Sequence low-disruption first.** Windows and BYOD cohorts (no wipe) before corporate Apple/Android reset cohorts (most comms, most user action).
- **Right-size waves to support capacity.** Cap each wave to what the helpdesk can shepherd through re-enrollment in the window.

## Parity discipline (the thing that breaks access)

- **Rebuild to parity, don't approximate.** Build the parity matrix (R6) and treat **Wi-Fi, VPN, and certificate** profiles as High complexity — a missing Wi-Fi cert or VPN profile breaks access the moment the device leaves Workspace ONE.
- **Validate parity on the pilot before trusting it.** A profile that shows **Succeeded** in Intune but doesn't actually grant access is a FAIL — test real access (T1.2 / T2.2 / T3.2 / T4.2), not just policy status.
- **Reuse the naming convention verbatim.** `Parity Policy Set – <Platform> – Target`, `Compliance Policy – <Platform> – Target`, `ADE Enrollment Profile – <Platform> – Target`, and `Wave NN Devices – <Scope> – Wave NN` so discovery, planning, validation, and reporting cross-reference cleanly.

## Identity & Conditional Access

- **Resolve identity first.** Users (and hybrid Windows device objects) must exist and authenticate in Entra before Intune can target them (R4).
- **Make Conditional Access do-no-harm during coexistence.** Stage CA changes **report-only**, keep coexisting (un-migrated) cohorts accessing resources, and tighten to require Intune compliance **only** as cohorts cut over (R8, Phase 9). Never require Intune compliance fleet-wide before the fleet is migrated.

## Apps

- **Re-package, don't expect export.** Win32 apps need the Content Prep Tool and a silent install/detection; managed store apps need VPP / managed Google Play. Identify store apps by **exact publisher name and bundle/package ID** to avoid the wrong near-identical app.
- **Carry managed app configuration across.** If Workspace ONE delivered per-app config (e.g. mail, VPN-per-app), rebuild it as Intune managed app config — apps installing without config is a partial migration.

## Cutover mechanics

- **A device is single-MDM, always.** Target only migrated devices with the production assignment, via `Wave NN Devices – <Scope> – Wave NN`. Never assign the same device to both platforms (T6.1) — that is the failure mode the wave model exists to prevent.
- **Plan the reset cohorts deliberately.** Corporate ADE Apple and fully managed/dedicated Android typically wipe; confirm backup/restore and comms before their wave (R11, R12).
- **Re-assign ADE in Apple Business Manager.** ABM is the system of record for ADE device-to-MDM-server assignment; change the MDM server there, then release the device from the source.

## Communications

- **Per-wave cadence:** announce → pre-cutover steps (re-enroll vs. reset, sign-in URL, MFA, app reinstall) → cutover-complete confirmation.
- **Tell users what they'll see.** Re-enrollment is user-visible and some platforms reset; clear instructions prevent the helpdesk flood that fails a wave.

## Coexistence & rollback

- **Define rollback per platform and per device (R13).** The rollback is "re-enroll to Workspace ONE / revert the Intune assignment," usable **inside the change window** before the source assignment is removed. Rehearse it once during pilot (T6.2).
- **Keep the source warm through a grace period.** Hold migrated devices read-only in Workspace ONE for a defined window (e.g. 14–30 days) after a wave passes before releasing them — that window is your rollback path.

## Decommission discipline

- **Validate before you retire.** No Workspace ONE device or assignment is decommissioned until its wave passes its acceptance gate and the grace period elapses (Phase 10).
- **Release the ADE/DEP token last**, so Apple Business Manager assignment is fully owned by Intune before the source is gone.
- **Export retained records first**, then reclaim/cancel Workspace ONE licensing — coordinate console steps with the platform owner (deferred to VMware docs).

## Documentation & evidence

- **Keep the program register current as you go** — named objects, wave plan, change records, and per-gate results. A complete, dated record of who moved what, how parity was proven, and how each cutover was validated (and could be rolled back) is the deliverable that makes the program auditable.


---


# 8. Deliverables Summary — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

This package is a complete, enterprise-grade program kit for migrating an organization's entire endpoint estate off VMware Workspace ONE UEM and onto Microsoft Intune — Windows, iOS/iPadOS, Android, and macOS. It contains the documentation playbook, five PowerShell tools, and a hero image.

## Documentation

| File | What it covers |
|---|---|
| `01-solution-overview.md` | What the program is, the four platform workstreams, the single-MDM-per-device reality, why it's high-risk, how it works, the per-platform approach, benefits, honest limitations, and the standard program model. |
| `02-requirements.md` | R1–R14 prerequisites (Description / Why / Verify / Implement-if-missing), including the GATING identity/licensing, Workspace ONE access, per-platform enrollment plumbing, and identity-readiness requirements; introduces the `<Purpose> – <Scope> – <Stage>` naming convention. |
| `global-requirements-migrations.md` | Category-level baseline requirements common to every Migrations engagement (target tenant, licensing, source access, inventory, enrollment prerequisites, pilot/waves, change control & rollback). |
| `03-implementation.md` | The full program runbook: Discover → Assess → Plan → Configure → Pilot → Validate (pilot-wave gate) → Expand (coexistence → cutover → validate, per platform) → Decommission, with named objects, exact Intune/Entra/ABM navigation, and per-platform cutover runbooks. |
| `05-testing.md` | Numbered tests with PASS/FAIL gates and a per-platform acceptance gate (enrollment, parity, compliance, apps, access, coexistence integrity, rollback rehearsal). |
| `06-troubleshooting.md` | Enrollment, coexistence/dual-MDM, ADE/ABM, parity-profile, app-delivery, Conditional Access, and rollback failure modes with fixes. |
| `07-best-practices.md` | Program best practices: enrollment-plumbing-first, pilot every platform, parity discipline, do-no-harm Conditional Access, cutover mechanics, comms, rollback, decommission discipline, evidence. |
| `executive-summary.md` | One-page business case and outcomes for sponsors/leadership. |

## PowerShell scripts

All scripts carry a header with PURPOSE / HOW TO RUN / EXPECTED RESULTS and a neutral, white-label note. The Intune/Entra target side uses **Microsoft Graph PowerShell** (`Connect-MgGraph`, `Get-MgDeviceManagementManagedDevice`, groups). Any Workspace ONE source-side call is a **generic `Invoke-RestMethod`** against the Workspace ONE REST API, clearly flagged and deferred to current VMware documentation (no invented endpoints).

| Script | What it does |
|---|---|
| `scripts\WS1PROG-Discovery.ps1` | **Read-only baseline.** Captures the Intune/Entra target side (managed devices by platform, enrollment-channel status, groups, licensing readiness) via Microsoft Graph, and provides a flagged optional Workspace ONE REST inventory hook — the Discovery baseline (R5) reconciled against the source export. |
| `scripts\WS1PROG-Validation.ps1` | **Per-device / per-wave migration validation.** Checks each wave device's Intune enrollment state, single-MDM status, compliance, and assigned-app/profile state via Graph; emits PASS/FAIL per check for the acceptance gates. Read-only. |
| `scripts\WS1PROG-Report.ps1` | **Program/wave status report.** Reads the wave plan + live Graph state and produces per-platform and per-wave % migrated, compliant, and app-success as a CSV plus a console summary — the program dashboard. Read-only. |
| `scripts\WS1PROG-Remediation.ps1` | **Safe remediation helpers.** Retry enrollment sync, (re-)add devices to the correct wave group, and re-evaluate compliance for failed migrations. Runs `-WhatIf` by default; requires `-Apply` to make any change. |
| `scripts\WS1PROG-Set-WaveTargeting.ps1` | **Wave + targeting builder.** Reads the Discovery/source CSV, groups devices/users into balanced waves (cohort-aware), and creates/populates the Entra security groups (`Wave 00 Devices – All – Pilot`, `Wave NN Devices – <Scope> – Wave NN`) that drive Intune assignment. Supports `-WhatIf`. |

## Hero image

| File | Purpose |
|---|---|
| `WS1PROG-hero.png` | Listing/marketing hero image for the solution. |

> **Naming convention reminder:** the scripts and runbooks share the object-naming standard `<Purpose> – <Scope> – <Stage>` (e.g. `Wave NN Devices – Windows – Wave 03`, `Parity Policy Set – iOS – Target`) so outputs cross-reference cleanly across discovery, planning, validation, and reporting.
