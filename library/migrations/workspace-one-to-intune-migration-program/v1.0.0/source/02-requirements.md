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
