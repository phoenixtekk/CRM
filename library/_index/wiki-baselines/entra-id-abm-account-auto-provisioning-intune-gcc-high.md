# Implement Entra ID Integration with ABM for Account Auto Provisioning for Microsoft Intune — Government (GCC High)

> **Version 1.0.0** · Category: Entra · Solution code: ABMPROVG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

## The bottom line

This is the **Government (GCC High)** edition of integrating Microsoft Entra ID with Apple Business
Manager (ABM) for Apple device provisioning. The single most important fact for a decision-maker:
**the Entra ⇄ ABM _federation_ and _SCIM auto-provisioning_ link does not support national clouds
(GCC High / DoD) today.** Apple's documentation states, verbatim, "Integration with national clouds
isn't currently supported," and Microsoft does not offer the ABM provisioning gallery app for the US
Government cloud.

**What this means:** a pure GCC High tenant **cannot** deliver the "sign in to Apple devices with your
Entra work account, auto-created and kept in sync by SCIM" experience the way a Commercial tenant can.
That is a **feature parity gap**, not a portal-URL difference.

**What is delivered instead — and is fully supported:** Apple device management through **Intune
Government** — ABM linked to Intune for **Automated Device Enrollment** and **User Enrollment**, with
Managed Apple IDs created through ABM's own tooling (manual, SFTP, or ABM API). This achieves the
device-management outcome government teams need, on a supported path, using the sovereign `*.us`
portals and the US Gov Microsoft Graph endpoint.

## Why this edition exists

Commercial implementation steps **silently fail** on GCC High: the admin URLs differ (`*.us`), the
tooling must be told it is US Gov (`Connect-MgGraph -Environment USGov`), the licensing is Government
SKUs, and — most importantly — the headline federation/SCIM capability is unavailable. A government
administrator following a Commercial guide would waste effort configuring a flow that cannot complete.
This edition sets expectations correctly and guides the supported path.

## What you get

- A **decision gate** that tells you, before any spend, whether your requirement is achievable on
  GCC High today or depends on the unsupported federation/SCIM link.
- Ordered, novice-friendly **Assess → Configure → Pilot → Validate → Expand** steps using the
  sovereign portals, with GCC-High caveats called out where they matter.
- **Five PowerShell scripts** (discovery, validation, reporting, safe remediation, scope targeting)
  that connect to `graph.microsoft.us` via `-Environment USGov`.
- A **cited parity reference**, **pass/fail testing gates**, and **GCC-High-specific troubleshooting**.

## The risk it removes

Deploying with Commercial assumptions on a government tenant leads to failed enrollments,
misconfigured identity, and — worst of all — stakeholders expecting a capability the sovereign cloud
does not offer. This edition delivers a **correct, supported, pilot-proven** configuration and a
**documented parity gap**, so the outcome is right the first time and no one is surprised.

_Sovereign-cloud capabilities change. The federation limitation is quoted from Apple's current
documentation; re-verify the cited Apple and Microsoft pages (see `gcc-high-parity-notes.md`) before
implementation._


---


# Solution Overview — Entra ID + Apple Business Manager Managed Apple ID Auto-Provisioning (Government / GCC High)

This is the **Government (GCC High)** edition of the solution that integrates Microsoft Entra ID with
Apple Business Manager (ABM) so that Managed Apple IDs and Apple device enrollment are driven from
your directory. It is written for an administrator working in the **US sovereign cloud**, using the
`*.us` admin portals and the US Gov Microsoft Graph endpoint. It follows the standard deployment
model — **Assess → Configure → Pilot → Validate → Expand** — with a gate at the end of each phase.

## Read this first — the most important GCC High difference

Before anything else: **the Entra ID ⇄ Apple Business Manager _federation_ and _SCIM
auto-provisioning_ link does not currently support national clouds (GCC High / DoD).** Apple's own
documentation states, verbatim, "Integration with national clouds isn't currently supported," and the
integration is built for the Commercial global sign-in service `login.microsoftonline.com`, not the
sovereign `login.microsoftonline.us`. On the Microsoft side, the gallery provisioning app for ABM is
not offered for provisioning in the US Government cloud.

What that means in plain terms:

- A **pure GCC High tenant cannot complete the "sign in to Apple with your Entra work account,
  auto-created and kept in sync by SCIM" flow** the way a Commercial tenant can. This is a **feature
  parity gap**, not a portal-URL change.
- What **is** fully supported in GCC High is **Apple device management through Intune Government** —
  linking ABM to Intune for **Automated Device Enrollment (ADE)** and **User Enrollment**, with
  Managed Apple IDs created by ABM's own tooling (manual, SFTP, or ABM API) rather than by the Entra
  federation/SCIM connector.

This solution therefore guides you to **implement the supported GCC High path** and **explicitly
call out the federation/SCIM step as a Commercial-only capability** to evaluate separately with your
security and compliance team. Full citations are in `gcc-high-parity-notes.md`; do not skip it.

## What this solution delivers

- A clear **decision gate** up front: confirm whether your requirement can be met in GCC High today,
  or whether it depends on the unsupported federation/SCIM link.
- The **supported GCC High deployment**: ABM linked to **Intune Government** (`endpoint.microsoft.us`)
  for Apple ADE/User Enrollment, with Managed Apple ID lifecycle handled through ABM.
- **Five PowerShell scripts** that connect to the **US Gov** Graph endpoint
  (`Connect-MgGraph -Environment USGov`) to discover readiness, validate configuration, report state,
  safely remediate, and build the pilot scope group.
- A **parity reference**, **testing gates**, and **troubleshooting** tuned to GCC-High-specific
  behaviour.

## Commercial vs GCC High — what's different

This section is the orientation every government administrator needs. The differences are not
cosmetic — one of them changes what is achievable at all.

### 1. Feature parity — the federation/SCIM link (the big one)

| | Commercial | GCC High |
| --- | --- | --- |
| Sign in to Apple devices with Entra **work credentials** (federation) | Supported via `login.microsoftonline.com` | **Not supported** — Apple excludes national clouds |
| **SCIM auto-provisioning** of Managed Apple IDs from Entra | Supported (gallery provisioning app) | **Not supported / verify** — gallery app not offered for US Gov provisioning |
| ABM ⇄ **Intune** device enrollment (ADE, User Enrollment) | Supported | **Supported** via Intune Government |
| Managed Apple ID creation via **ABM** (manual / SFTP / ABM API) | Supported | Supported (ABM is a single global service, not cloud-bound) |

Because the top two rows are the literal title of this solution ("Entra ID integration with ABM for
account auto-provisioning"), a government reader must understand up front that the **Entra-driven**
auto-provisioning is the gated capability, while the **device-management outcome** is achievable
through the supported Intune path.

### 2. Admin portals — every URL changes to `*.us`

You do all supported configuration in the sovereign portals, never the Commercial ones:

- Entra admin center → **entra.microsoft.us**
- Intune / Endpoint admin → **endpoint.microsoft.us**
- Microsoft 365 admin → **portal.office365.us**
- Azure portal → **portal.azure.us**
- Sign-in authority → **login.microsoftonline.us**
- Microsoft Graph → **graph.microsoft.us**

Using a Commercial URL either fails to authenticate your GCC High credentials or silently targets the
wrong tenant.

### 3. Tooling — Graph must be told it is US Gov

Every script and any manual Graph call must specify the sovereign environment. In the Microsoft Graph
PowerShell SDK that is `Connect-MgGraph -Environment USGov` (which targets `graph.microsoft.us`).
Omitting it authenticates against the Commercial endpoint and fails.

### 4. Licensing — Government SKUs

Licensing uses **Government** SKUs (for example Microsoft 365 **G3/G5 Gov** and **Intune for
Government**) rather than the Commercial E3/E5 line. Confirm your tenant carries the Government
licensing that includes Entra ID P1/P2 and Intune Government.

### 5. ABM itself is unchanged

Apple Business Manager has **no sovereign variant** — there is one global `business.apple.com`. The
sovereign constraint lives entirely on the **Entra-side federation/SCIM link into ABM**. So Managed
Apple IDs, MDM server tokens, and device sync tokens are configured in the same ABM you would use for
Commercial; only the **identity link into it** is subject to the national-cloud limitation.

## The deployment model (Assess → Configure → Pilot → Validate → Expand)

- **Assess** — inventory the tenant, licensing, roles, ABM account, and — critically — decide whether
  your requirement can be met on the supported GCC High path or depends on the unsupported
  federation/SCIM link. Gate: no configuration until the decision is recorded.
- **Configure** — link ABM to **Intune Government**, establish the MDM push certificate and ADE/User
  Enrollment tokens, and define the Managed Apple ID approach ABM will use. Gate: tokens valid, no
  errors in `endpoint.microsoft.us`.
- **Pilot** — enrol a small, named group of Apple devices/users (built by
  `ABMPROVG-Set-ScopeTargeting.ps1`). Gate: pilot devices enrol and receive policy.
- **Validate** — run the validation and report scripts; confirm enrollment, Managed Apple ID sign-in
  behaviour, and policy delivery against pass/fail criteria. Gate: all checks pass.
- **Expand** — widen the scope group in controlled waves. Gate: each wave green before the next.

## Named objects you will create and reuse

To keep the deployment repeatable, create these once and reuse them by name throughout:

- **`ABM-Apple-Pilot-Devices`** — the pilot scope group (built by the scope-targeting script).
- **`ABM-Apple-Enroll-Users`** — the user group scoped for Apple enrollment.
- **`ABM-ADE-Profile-Gov`** — the Automated Device Enrollment profile in Intune Government.
- **`ABM-Managed-AppleID-Standard`** — your documented standard for how Managed Apple IDs are named
  and created in ABM.

## Who this is for and what "done" looks like

For a novice-friendly government administrator with the required roles. You are done when: the
GCC-High-vs-Commercial decision is recorded; ABM is linked to Intune Government with valid tokens;
a named pilot group of Apple devices enrols and receives policy; the validation script reports all
checks green; and the federation/SCIM parity gap is documented for stakeholders so no one expects a
capability the sovereign cloud does not offer today.

_Sovereign-cloud capabilities change. Re-verify the cited Apple and Microsoft pages (see
`gcc-high-parity-notes.md`) before implementation._


---


# Requirements — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

The category-level prerequisites are in `global-requirements-entra-id-solutions.md` — confirm those
first (Entra tenant, licensing, admin roles, break-glass accounts, network access). This document
adds the requirements **specific to this solution on GCC High**, each with how to **verify** it and
how to **implement it if missing**.

> Everything below assumes the **US sovereign cloud**. Use the `*.us` portals and
> `Connect-MgGraph -Environment USGov`. Confirm the parity gap in `gcc-high-parity-notes.md` before
> you spend money or time — some requirements only matter if you pursue a path GCC High does not
> support today.

---

## R0. (Gate) Decision — supported path vs unsupported federation/SCIM link
Description: A recorded decision on whether your requirement can be met on the **supported GCC High
path** (ABM ⇄ Intune Government enrollment) or depends on the **unsupported** Entra ⇄ ABM
federation/SCIM link (national clouds excluded by Apple).
Why: This decision determines whether the rest of the deployment is achievable in GCC High today.
Skipping it risks configuring toward a capability that cannot complete.
Verify: A short written statement citing `gcc-high-parity-notes.md`, approved by the project owner.
Implement: Read `gcc-high-parity-notes.md`, re-check the Apple federated-authentication page live,
confirm with your security/compliance team, and record the decision before any configuration.

## R1. GCC High tenant with Government licensing
Description: An active GCC High Entra tenant carrying Government SKUs — Microsoft 365 **G3/G5 Gov** (or
equivalent) that includes **Entra ID P1/P2** and **Intune for Government**.
Why: Apple enrollment through Intune Government requires the Government Intune service and Entra P1/P2
for scoping and Conditional Access.
Verify: Sign in to `https://portal.office365.us` → `Billing → Licenses`; confirm Government SKUs with
Intune and Entra P1/P2. Sign in to `https://entra.microsoft.us` as an administrator.
Implement: Assign Government licensing (M365 G3/G5 Gov or EMS Gov + Intune for Government).

## R2. Administrative roles (sovereign)
Description: **Intune Administrator** (for the Apple enrollment configuration) and a **Global
Administrator** available for one-time consent steps; least privilege thereafter.
Why: Linking ABM to Intune and creating enrollment profiles requires Intune Administrator; some
one-time trust/consent actions require Global Administrator.
Verify: `entra.microsoft.us` → `Roles and administrators`; confirm the operator holds Intune
Administrator and that a Global Administrator is available.
Implement: Assign **Intune Administrator** to the operator; reserve **Global Administrator** for
one-time consent, then step down to least privilege.

## R3. Break-glass accounts (sovereign)
Description: Two cloud-only emergency-access Global Administrator accounts (`@onmicrosoft.us` /
your `.onmicrosoft.com` sovereign vanity), excluded from broad Conditional Access/MFA lockout.
Why: Enrollment and Conditional Access changes can lock out admins; break-glass restores access.
Verify: `entra.microsoft.us` → `Users`; confirm two cloud-only accounts with stored strong
credentials and sign-in monitoring.
Implement: Create two cloud-only Global Administrator accounts, exclude them from broad policies, and
store credentials securely.

## R4. Apple Business Manager account
Description: An active Apple Business Manager account at `business.apple.com` with an administrator
who can create tokens and manage Managed Apple IDs.
Why: ABM is where the MDM server (Intune) is linked, ADE tokens are issued, and Managed Apple IDs
live. ABM is a single global Apple service — there is no sovereign variant.
Verify: Sign in to `https://business.apple.com` as an ABM Administrator; confirm the organization is
enrolled and verified.
Implement: Enrol your organization in Apple Business Manager and complete Apple's verification.
Note (**verify for GCC High**): ABM is not a sovereign service; the sovereign constraint is only on
the Entra federation/SCIM link into ABM, not on ABM itself.

## R5. Intune Government configured for Apple
Description: Intune Government reachable at `https://endpoint.microsoft.us`, with the Apple **MDM push
certificate (APNs)** established.
Why: Apple device enrollment through Intune requires a valid APNs certificate and the Intune
Government service.
Verify: `endpoint.microsoft.us` → `Devices → Enrollment → Apple` → confirm a valid, non-expired Apple
MDM push certificate. Run `ABMPROVG-Discovery.ps1`.
Implement: In `endpoint.microsoft.us`, create/download the APNs CSR, obtain the certificate from
Apple, and upload it; record the Apple ID used so it can be renewed annually.

## R6. ABM ⇄ Intune enrollment tokens (ADE / User Enrollment)
Description: An Automated Device Enrollment (ADE) token (and/or User Enrollment configuration) linking
ABM to Intune Government.
Why: This is the **supported** GCC High mechanism to enrol Apple devices and apply the Managed Apple
ID experience through Intune.
Verify: `endpoint.microsoft.us` → `Devices → Enrollment → Apple → Enrollment program tokens`; confirm
a valid, non-expired token synced with ABM. Run `ABMPROVG-Validation.ps1`.
Implement: In ABM, add Intune Government as an MDM server, download the public key, upload it to
`endpoint.microsoft.us`, then upload the ABM token back to Intune; set the token to sync.

## R7. Managed Apple ID approach (ABM-native, not Entra federation)
Description: A documented standard (`ABM-Managed-AppleID-Standard`) for how Managed Apple IDs are
created — **manually, via ABM SFTP, or via the ABM API** — since Entra federation/SCIM is not
available in GCC High.
Why: With the federation/SCIM link unavailable, Managed Apple ID lifecycle must be handled by ABM's
own tooling; a written standard keeps it repeatable and auditable.
Verify: A documented naming and creation standard exists and matches how accounts are created in ABM.
Implement: Choose an ABM-native creation method, document the naming convention and lifecycle
(create/suspend/delete), and record it as `ABM-Managed-AppleID-Standard`.

## R8. Network endpoints for US Government Intune + Apple
Description: Outbound HTTPS to the **US Government Intune** service endpoints and to Apple's ABM/APNs
endpoints from managed devices and the admin workstation.
Why: Enrollment, policy delivery, and ABM/APNs communication depend on these being reachable through
sovereign filtering.
Verify: From the admin workstation and a test device, reach `endpoint.microsoft.us`,
`login.microsoftonline.us`, `graph.microsoft.us`, `business.apple.com`, and Apple's push endpoints;
compare to Microsoft's published US Government Intune network endpoints.
Implement: Allow the US Government Intune network endpoints and Apple ABM/APNs ranges through the
proxy/firewall. Source: *Network endpoints for US government deployments (Intune)* —
https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints

## R9. Microsoft Graph PowerShell SDK targeting US Gov
Description: A workstation with the **Microsoft Graph PowerShell SDK** installed, able to run
`Connect-MgGraph -Environment USGov` against `graph.microsoft.us`.
Why: All five solution scripts connect to the sovereign Graph endpoint; the Commercial endpoint
rejects GCC High credentials.
Verify: `Get-Module Microsoft.Graph -ListAvailable` returns a version; `Connect-MgGraph -Environment
USGov` succeeds. Run `ABMPROVG-Discovery.ps1`.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`; use `-Environment USGov` on every
connect. Source: *Connect-MgGraph* —
https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph

## R10. Pilot scope groups
Description: The named groups `ABM-Apple-Pilot-Devices` and `ABM-Apple-Enroll-Users` for staged
rollout.
Why: Staged Pilot → Validate → Expand requires a small, named scope you can widen in waves.
Verify: `entra.microsoft.us` → `Groups`; confirm both groups exist. Run
`ABMPROVG-Set-ScopeTargeting.ps1 -WhatIf`.
Implement: Create the groups (or let `ABMPROVG-Set-ScopeTargeting.ps1` create/populate the pilot group
with `-WhatIf` removed after review).

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


# Global Requirements — Entra ID Solutions (category-level)

These requirements apply to every solution in the Entra ID Solutions category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying any identity solution. Each entry: Description / Why / Verify / Implement-if-missing.

> The identity plane is high risk. A mistake here breaks sign-in for everyone, so every change is
> staged and a break-glass account is kept ready before you touch anything.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID tenant.
Why: It is the cloud identity backbone every other identity service builds on.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 or Azure subscription, which provisions a tenant.

## G2. Entra ID licensing (P1, P2 where noted)
Description: Microsoft Entra ID P1 (or P2 for risk-based and PIM features).
Why: Hybrid features such as seamless sign-in, password writeback, and Conditional Access require P1+.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1/P2 (often bundled in M365 E3/E5 or EMS).
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone Entra ID P1/P2.

## G3. Administrative roles
Description: Hybrid Identity Administrator and Global Administrator for the operator.
Why: Configuring directory synchronization and authentication methods needs these elevated roles.
Verify: Entra -> `Roles and administrators`; confirm `Hybrid Identity Administrator` (and a Global Administrator for the one-time first-sync consent).
Implement: Assign `Hybrid Identity Administrator`; reserve `Global Administrator` for tenant-wide and first-sync changes.

## G4. Break-glass (emergency access) accounts
Description: At least two cloud-only emergency access accounts, excluded from Conditional Access and MFA-broad policies.
Why: If sync, federation, or an auth-method change locks out admins, break-glass accounts get you back in.
Verify: Entra -> `Users`; confirm two cloud-only accounts (`@onmicrosoft.com`) with strong stored credentials and documented use.
Implement: Create two cloud-only Global Administrator accounts; exclude them from policies; store credentials securely and monitor sign-ins.

## G5. Healthy on-premises Active Directory
Description: A functional AD forest/domain with healthy replication and DNS.
Why: Synchronization reads from AD; replication or DNS faults corrupt or stall the sync.
Verify: Run `dcdiag` and `repadmin /replsummary` on a domain controller with no errors; run `HYBID-Discovery.ps1`.
Implement: Resolve AD replication, DNS, and time-sync issues before synchronizing.

## G6. An Entra Connect host server
Description: A domain-joined Windows Server (2016+), patched, for Microsoft Entra Connect Sync (or a lightweight host with the Cloud Sync agent).
Why: Connect Sync runs as a service on this host and must reach both AD and Entra ID.
Verify: A supported, domain-joined server with TLS 1.2, .NET, and PowerShell available; run `HYBID-Discovery.ps1`.
Implement: Provision a dedicated server (not a domain controller for production), patch it, and enable TLS 1.2.

## G7. UPN / domain hygiene
Description: User principal names use a public, verified, routable domain (not `.local`).
Why: A non-routable UPN suffix produces sign-in problems and `onmicrosoft.com` fallbacks in the cloud.
Verify: Entra -> `Identity -> Settings -> Domain names` shows the public domain Verified; AD UPN suffixes match it; run `HYBID-Discovery.ps1`.
Implement: Add and verify the public domain in Entra; add the matching UPN suffix in AD and update user UPNs.

## G8. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS (443) from the Connect host to Entra ID, plus required Microsoft 365 service URLs.
Why: Synchronization, authentication-agent traffic, and tokens depend on these endpoints.
Verify: From the Connect host, reach `https://login.microsoftonline.com` and the Microsoft 365 published URL/IP ranges.
Implement: Allow the Microsoft 365 / Entra service URLs and IP ranges through the proxy/firewall.

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# Implementation Guide — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

Follow these steps in order, using the **US sovereign portals** (`*.us`) throughout. Each phase ends
with a **gate** — do not proceed until it is met. This guide implements the **supported GCC High
path** and flags the **unsupported Entra ⇄ ABM federation/SCIM** capability inline where a Commercial
guide would tell you to configure it.

> Parity reminder (read `gcc-high-parity-notes.md`): Apple states "Integration with national clouds
> isn't currently supported," so the Entra-driven federation + SCIM auto-provisioning of Managed
> Apple IDs **does not complete on a GCC High tenant today**. The device-management outcome is reached
> through **Intune Government**. Every "auto-provisioning" step below is therefore the **ABM-native +
> Intune** path, not the Commercial gallery/SCIM path.

---

## Phase 1 — Assess

### Step 1.1 — Record the parity decision (Gate R0)
Before touching any portal, read `gcc-high-parity-notes.md`, re-check the Apple federated
authentication page, and record — in writing, approved by the owner — whether your requirement is met
by the supported GCC High path or depends on the unsupported federation/SCIM link. If it depends on
federation/SCIM, **stop** and escalate the parity gap; do not attempt to force the Commercial flow
against `login.microsoftonline.us`.

### Step 1.2 — Confirm tenant, licensing, roles
1. Sign in to `https://portal.office365.us` → `Billing → Licenses`; confirm Government SKUs including
   Intune Government and Entra ID P1/P2.
2. Sign in to `https://entra.microsoft.us` → `Roles and administrators`; confirm the operator holds
   **Intune Administrator** and a **Global Administrator** is available for one-time consent.
3. Confirm two break-glass accounts exist (`entra.microsoft.us` → `Users`).

### Step 1.3 — Run discovery
On the admin workstation, run the read-only discovery script:

```
powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Discovery.ps1
```

It connects with `Connect-MgGraph -Environment USGov` and reports tenant, licensing signals, Apple
enrollment configuration presence, and the pilot groups. Resolve any red items before configuring.

**Gate (Assess):** parity decision recorded; licensing/roles/break-glass confirmed; discovery shows
no blocking gaps.

---

## Phase 2 — Configure

### Step 2.1 — Establish the Apple MDM push certificate (APNs)
1. In `https://endpoint.microsoft.us` → `Devices → Enrollment → Apple`.
2. Under **Apple MDM Push certificate**, download the CSR, obtain the certificate from Apple's push
   portal, and upload it.
3. Record the **Apple ID** used (you must renew with the same Apple ID annually). Name your record
   consistently so the renewal owner can find it.

### Step 2.2 — Link Apple Business Manager to Intune Government (ADE token)
1. In `https://endpoint.microsoft.us` → `Devices → Enrollment → Apple → Enrollment program tokens →
   Add`.
2. Download the Intune **public key**.
3. In `https://business.apple.com` → `Preferences → MDM Servers → Add`, name the server
   **`Intune-Gov-MDM`**, and upload the Intune public key.
4. Download the ABM **server token** and upload it back into Intune to complete the link.
5. Set the token to **sync** on a schedule.

> This is the step where a Commercial guide would instead (or additionally) add the **"Apple Business
> Manager" provisioning gallery app** in Enterprise Applications and configure **SCIM** with a tenant
> URL + secret token from ABM to auto-provision Managed Apple IDs. **In GCC High, that gallery
> provisioning app is not offered for the US Government cloud (verify live in `entra.microsoft.us`),
> and Apple does not support the federation that underpins it.** Do not attempt it here — use the
> ABM-native Managed Apple ID approach in Step 2.4.

### Step 2.3 — Create the Automated Device Enrollment profile
1. In `endpoint.microsoft.us` → `Devices → Enrollment → Apple → Enrollment program tokens →` select
   your token → `Profiles → Create profile`.
2. Name it **`ABM-ADE-Profile-Gov`**, choose supervised/user-affinity settings per your policy, and
   assign it (initially unassigned or to a tiny test group; broaden in Pilot).

### Step 2.4 — Define the Managed Apple ID approach (ABM-native)
Because Entra federation/SCIM is unavailable in GCC High, create Managed Apple IDs with ABM's own
tooling per your documented **`ABM-Managed-AppleID-Standard`**:

- **Manual** — for small pilots, create Managed Apple IDs directly in `business.apple.com → Accounts`.
- **SFTP** — for bulk, use ABM's SFTP directory-sync feed (ABM-side, independent of Entra cloud).
- **ABM API** — for automation, use the Apple Business Manager API.

Record the naming convention and the create/suspend/delete lifecycle so it is auditable.

**Gate (Configure):** APNs certificate valid; ABM ⇄ Intune Government token valid and syncing;
`ABM-ADE-Profile-Gov` created; Managed Apple ID standard documented. Run:

```
powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Validation.ps1
```

All configuration checks should pass before piloting.

---

## Phase 3 — Pilot

### Step 3.1 — Build the pilot scope
Review, then apply, the pilot scope group:

```
powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Set-ScopeTargeting.ps1 -WhatIf
```

Inspect the planned membership of **`ABM-Apple-Pilot-Devices`** / **`ABM-Apple-Enroll-Users`**, then
re-run **without** `-WhatIf` to apply.

### Step 3.2 — Assign the ADE profile to the pilot
Assign **`ABM-ADE-Profile-Gov`** to **`ABM-Apple-Pilot-Devices`** in `endpoint.microsoft.us`.

### Step 3.3 — Enrol pilot devices
Wipe/prepare a small set of ABM-assigned Apple devices and run them through Setup Assistant. They
should appear as ADE-enrolled in Intune Government and receive the assigned profile/policy. If using
Managed Apple IDs, confirm sign-in with an ABM-created Managed Apple ID (not an Entra work account —
that federation path is unavailable in GCC High).

**Gate (Pilot):** pilot devices enrol via ADE, appear in `endpoint.microsoft.us`, and receive policy.

---

## Phase 4 — Validate

### Step 4.1 — Run validation and report
```
powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Validation.ps1
powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Report.ps1
```

Confirm: token valid and syncing; APNs valid; pilot devices enrolled; profile applied; Managed Apple
ID sign-in behaves per your standard. See `05-testing.md` for the pass/fail matrix.

### Step 4.2 — Remediate safely if needed
If validation flags a fixable drift (for example a missing group assignment), preview and apply the
safe remediation:

```
powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Remediation.ps1 -WhatIf
```

Review the planned actions, then re-run without `-WhatIf`.

**Gate (Validate):** every check in `05-testing.md` is green.

---

## Phase 5 — Expand

### Step 5.1 — Widen in waves
Grow **`ABM-Apple-Pilot-Devices`** (or graduate to a production group) in controlled waves using
`ABMPROVG-Set-ScopeTargeting.ps1`. After each wave, re-run `ABMPROVG-Validation.ps1` and
`ABMPROVG-Report.ps1` and only proceed when green.

### Step 5.2 — Operationalize
- Calendar the **APNs certificate** and **ABM token** renewals (both expire annually).
- Keep the parity gap documented for stakeholders so no one expects Entra federation/SCIM
  auto-provisioning that GCC High does not offer today.
- Re-check the Apple federated-authentication page periodically — Apple's wording ("isn't
  *currently* supported") implies national-cloud support could be added later.

**Gate (Expand):** each wave green before the next; renewals scheduled; parity documented.

---

## GCC-High-specific caveats (inline summary)

- **Federation/SCIM:** not supported for national clouds (Apple) — do not configure the Commercial
  gallery/SCIM flow; it will not complete.
- **Portals:** every URL is `*.us`; a Commercial URL fails or targets the wrong tenant.
- **Graph:** every script/manual call uses `-Environment USGov` (`graph.microsoft.us`).
- **Licensing:** Government SKUs (Intune Government, Entra P1/P2).
- **ABM:** single global service; no `.us` variant — configure it as you would for Commercial, but
  only the Intune link (not Entra federation) applies.

_Re-verify the cited Apple and Microsoft pages (see `gcc-high-parity-notes.md`) before implementation;
sovereign-cloud capabilities change._


---


# Testing & Validation — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

Use this pass/fail matrix at each phase gate. Run the scripts with
`Connect-MgGraph -Environment USGov` (the scripts do this for you). All portal checks use the `*.us`
sovereign URLs.

> Reminder: on GCC High the **Entra ⇄ ABM federation/SCIM auto-provisioning** path is **not
> supported** (Apple excludes national clouds). Tests below validate the **supported** path (ABM ⇄
> Intune Government enrollment) — there is deliberately **no** test for SCIM provisioning success,
> because that connector is not available in the US Government cloud.

---

## T0. Parity decision recorded
- **Check:** A written, approved decision exists stating the requirement is met by the supported GCC
  High path (or the project is stopped/escalated if it depends on federation/SCIM).
- **Pass:** Decision document present and approved, citing `gcc-high-parity-notes.md`.
- **Fail:** No decision recorded — do not proceed.

## T1. Sovereign sign-in and Graph environment
- **Check:** `Connect-MgGraph -Environment USGov` succeeds; the connected context shows a
  `graph.microsoft.us` / US Gov environment.
- **Pass:** Connected to the US Gov Graph endpoint with the expected tenant ID.
- **Fail:** Auth error, or connection lands on the Commercial endpoint (you omitted `-Environment
  USGov`).

## T2. Licensing and roles
- **Check:** `portal.office365.us` shows Government SKUs with Intune Government and Entra P1/P2; the
  operator holds Intune Administrator.
- **Pass:** Correct Government licensing and roles present.
- **Fail:** Commercial SKUs, missing Intune Government, or insufficient role.

## T3. Apple MDM push certificate (APNs)
- **Check:** `endpoint.microsoft.us` → `Devices → Enrollment → Apple` shows a valid, non-expired APNs
  certificate; `ABMPROVG-Validation.ps1` reports it present.
- **Pass:** Certificate valid, expiry > 30 days out, renewal Apple ID recorded.
- **Fail:** Missing/expired certificate, or unknown renewal Apple ID.

## T4. ABM ⇄ Intune Government token
- **Check:** `endpoint.microsoft.us` → `Enrollment program tokens` shows a valid, non-expired token
  named for the ABM link (`Intune-Gov-MDM`), last sync recent; `ABMPROVG-Validation.ps1` confirms.
- **Pass:** Token valid, syncing, expiry > 30 days out.
- **Fail:** Token missing, expired, or not syncing.

## T5. ADE profile exists and is assigned
- **Check:** `ABM-ADE-Profile-Gov` exists and is assigned to `ABM-Apple-Pilot-Devices`.
- **Pass:** Profile present and assigned to the pilot scope.
- **Fail:** Profile missing or unassigned.

## T6. Pilot enrollment succeeds
- **Check:** A wiped, ABM-assigned pilot device runs Setup Assistant and appears ADE-enrolled in
  `endpoint.microsoft.us`, receiving the assigned profile/policy.
- **Pass:** Device enrolls automatically and shows compliant/managed with policy applied.
- **Fail:** Device does not enroll automatically, or does not receive policy.

## T7. Managed Apple ID sign-in (ABM-native)
- **Check:** Signing in with an **ABM-created Managed Apple ID** behaves per
  `ABM-Managed-AppleID-Standard`.
- **Pass:** Managed Apple ID sign-in works as designed.
- **Fail (expected on the federation path):** Attempting to sign in with an **Entra work account via
  federation** fails — this is **expected** in GCC High and is not a defect; it confirms the parity
  gap. Do not log this as a bug.

## T8. Scope targeting is deterministic
- **Check:** `ABMPROVG-Set-ScopeTargeting.ps1 -WhatIf` lists the intended pilot membership with no
  unexpected additions/removals.
- **Pass:** Planned membership matches intent; applying it yields exactly that.
- **Fail:** Unexpected members, or `-WhatIf` output differs from applied result.

## T9. Reporting is accurate
- **Check:** `ABMPROVG-Report.ps1` output matches what the portals show (token, APNs, enrolled pilot
  devices, group membership).
- **Pass:** Report matches portal reality.
- **Fail:** Report diverges from the portal — investigate before trusting it.

## T10. Remediation is safe by default
- **Check:** `ABMPROVG-Remediation.ps1` runs in `-WhatIf` mode by default and only changes state when
  `-WhatIf` is removed.
- **Pass:** Default run makes no changes and previews actions clearly.
- **Fail:** Any change occurs without explicitly removing `-WhatIf`.

---

## Phase gate summary

| Phase | Must pass |
| --- | --- |
| Assess | T0, T1, T2 |
| Configure | T3, T4, T5 |
| Pilot | T6, T7, T8 |
| Validate | T9, T10 (plus re-confirm T3–T6) |
| Expand | Re-run T4–T9 after each wave |

Record the result (pass/fail + date) for each test at each gate so the deployment is auditable.


---


# Troubleshooting — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

GCC-High-specific symptoms and fixes. Most issues fall into one of three buckets: you hit a Commercial
endpoint, you expected the unsupported federation/SCIM path, or a token/certificate expired. Always
work in the `*.us` portals and connect Graph with `-Environment USGov`.

---

## "Sign in to Apple with the Entra work account fails" / federation won't turn on
- **Cause:** This is the **expected parity gap**, not a defect. Apple states "Integration with national
  clouds isn't currently supported," and the federation is built for the Commercial global service
  `login.microsoftonline.com`, not `login.microsoftonline.us`.
- **Fix:** Do not attempt to force the Commercial federation flow against the sovereign endpoint. Use
  **ABM-native Managed Apple IDs** (manual / SFTP / ABM API) and enrol devices via **Intune
  Government ADE/User Enrollment**. See `gcc-high-parity-notes.md`. If the requirement truly depends on
  federation, escalate the parity gap — it is not solvable in a pure GCC High tenant today.

## "Apple Business Manager provisioning app isn't in my Enterprise Applications gallery"
- **Cause:** The ABM provisioning gallery app is **not offered for provisioning in the US Government
  cloud**. Its absence in `entra.microsoft.us` is expected.
- **Fix:** Do not search for a workaround gallery app. Provision Managed Apple IDs with ABM's own
  tooling per `ABM-Managed-AppleID-Standard`. (**Verify for GCC High** live — gallery availability
  changes over time.)

## `Connect-MgGraph` fails or connects to the wrong tenant
- **Cause:** You omitted `-Environment USGov`, so the SDK authenticated against the Commercial endpoint
  and rejected your GCC High credentials (looks like an auth failure), or silently used a Commercial
  context.
- **Fix:** Always run `Connect-MgGraph -Environment USGov`. Optionally set
  `$PSDefaultParameterValues['Connect-MgGraph:Environment'] = 'USGov'` in your profile. Confirm the
  connected context targets `graph.microsoft.us`.

## Portal shows nothing / "you don't have access"
- **Cause:** You opened a Commercial URL (`entra.microsoft.com`, `endpoint.microsoft.com`) instead of
  the sovereign `*.us` equivalent, or lack the Intune Administrator role.
- **Fix:** Use `entra.microsoft.us`, `endpoint.microsoft.us`, `portal.office365.us`. Confirm the
  operator holds **Intune Administrator** in `entra.microsoft.us → Roles and administrators`.

## Devices don't auto-enrol during Setup Assistant
- **Cause:** The ABM ⇄ Intune token isn't syncing, the device isn't assigned to the Intune MDM server
  in ABM, or `ABM-ADE-Profile-Gov` isn't assigned to the pilot group.
- **Fix:** In `endpoint.microsoft.us → Enrollment program tokens`, confirm the token is valid and
  synced; in `business.apple.com`, confirm the device is assigned to `Intune-Gov-MDM`; confirm
  `ABM-ADE-Profile-Gov` is assigned to `ABM-Apple-Pilot-Devices`. Run `ABMPROVG-Validation.ps1`.

## Enrolled devices get no policy
- **Cause:** The device enrolled but isn't in the scoped group, or the APNs certificate is invalid.
- **Fix:** Verify APNs validity in `endpoint.microsoft.us → Apple → MDM push certificate`; confirm
  group membership with `ABMPROVG-Set-ScopeTargeting.ps1 -WhatIf`.

## APNs certificate or ABM token "expired"
- **Cause:** Both expire annually; a lapse breaks Apple enrollment and push.
- **Fix:** Renew before expiry. Renew the APNs certificate with the **same Apple ID** (a new Apple ID
  forces re-enrollment of all devices). Re-download and re-upload the ABM token. Calendar both
  renewals with 30-day lead time.

## `ABMPROVG-Report.ps1` disagrees with the portal
- **Cause:** Stale sync, insufficient Graph scopes, or a Commercial-context connection.
- **Fix:** Re-run after a sync; ensure you consented to the read scopes the script requests; confirm
  the connection is US Gov (`-Environment USGov`). Trust the portal until the report matches.

## Remediation changed something unexpectedly
- **Cause:** `-WhatIf` was removed before the preview was reviewed.
- **Fix:** Always run `ABMPROVG-Remediation.ps1 -WhatIf` and `ABMPROVG-Set-ScopeTargeting.ps1 -WhatIf`
  first, read the planned actions, then re-run without `-WhatIf`. If an unwanted change occurred,
  reverse it in the portal and re-validate.

## Network filtering blocks enrollment
- **Cause:** US Government Intune endpoints or Apple ABM/APNs ranges aren't allowed through the proxy.
- **Fix:** Allow the published **US Government Intune network endpoints** and Apple ABM/APNs ranges.
  Source: https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints

---

## When to escalate
- The requirement genuinely needs **Entra federation / SCIM auto-provisioning** — that is a national
  cloud limitation on Apple's side, not a configuration you can fix. Escalate with the citation from
  `gcc-high-parity-notes.md` and evaluate alternatives (ABM-native provisioning) with stakeholders.
- Any consideration of a separate Commercial/GCC tenant purely to obtain federation — route to your
  ISSO first; it may breach your CMMC/ITAR/DFARS compliance boundary.

_Re-verify the cited Apple and Microsoft pages before implementation; sovereign-cloud capabilities
change._


---


# Best Practices — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

Practices that keep this deployment correct, auditable, and low-risk on the US sovereign cloud.

## Set expectations on the parity gap first
- Communicate up front, in writing, that **Entra ⇄ ABM federation and SCIM auto-provisioning are not
  supported for national clouds** (Apple's statement). Stakeholders who expect "sign in to Apple with
  your GCC High work account, auto-provisioned by SCIM" will otherwise treat a documented limitation
  as a project failure. Frame the delivered outcome as **ABM ⇄ Intune Government enrollment** with
  **ABM-native Managed Apple IDs**.
- Re-check the Apple federated-authentication page periodically — the wording "isn't *currently*
  supported" implies it may change; revisit before any future re-scope.

## Always target the sovereign cloud
- Use only `*.us` portals (`entra.microsoft.us`, `endpoint.microsoft.us`, `portal.office365.us`).
  Bookmark them so no one accidentally lands on a Commercial URL.
- Every Graph call — script or manual — uses `Connect-MgGraph -Environment USGov`. Consider setting
  `$PSDefaultParameterValues['Connect-MgGraph:Environment'] = 'USGov'` in the admin profile so the
  Commercial endpoint is never hit by accident.

## Stage everything; never big-bang
- Follow **Assess → Configure → Pilot → Validate → Expand** with the gates in `05-testing.md`.
- Keep a small, named **`ABM-Apple-Pilot-Devices`** group and widen in waves, validating between each.
- Use `-WhatIf` first on `ABMPROVG-Set-ScopeTargeting.ps1` and `ABMPROVG-Remediation.ps1` — review the
  preview before applying.

## Protect sign-in with break-glass
- Maintain two cloud-only break-glass Global Administrators excluded from broad Conditional
  Access/MFA lockout, with monitored sign-ins. Enrollment and CA changes can lock admins out.

## Name and reuse objects
- Create named objects once and reuse them: `ABM-Apple-Pilot-Devices`, `ABM-Apple-Enroll-Users`,
  `ABM-ADE-Profile-Gov`, `Intune-Gov-MDM` (the ABM MDM server), and the documented
  `ABM-Managed-AppleID-Standard`. Consistent names make scripts, reports, and troubleshooting
  predictable.

## Manage the two annual expiries
- Both the **Apple MDM push certificate (APNs)** and the **ABM enrollment token** expire yearly.
  Calendar both renewals with 30-day lead time. Renew the APNs certificate with the **same Apple ID**
  — a different Apple ID forces re-enrollment of every device.
- Record the renewal owner and the Apple ID used, so a departing admin does not orphan the
  certificate.

## Keep Managed Apple ID lifecycle auditable
- With federation/SCIM unavailable, document how Managed Apple IDs are created (manual / SFTP / ABM
  API), named, suspended, and deleted. Tie suspension/deletion to your joiner-mover-leaver process
  even though it is a manual/ABM-side step rather than an Entra-driven one.

## Least privilege
- Use **Intune Administrator** for day-to-day enrollment work; reserve **Global Administrator** for
  one-time consent, then step down. Do not run routine operations as Global Administrator.

## Validate before you trust reporting
- Cross-check `ABMPROVG-Report.ps1` against the portals during the first few runs. Once you trust it,
  use it as your recurring health snapshot after each expansion wave and before each renewal.

## Compliance-boundary caution on any "hybrid tenant" workaround
- A design that uses a separate Commercial/GCC tenant solely to obtain ABM federation (with GCC High
  for everything else) is **not a documented Microsoft path** and may violate your CMMC/ITAR/DFARS
  boundary. Treat it as a security/compliance decision to evaluate with your ISSO — never adopt it
  silently to "make federation work."

## Re-verify sources before implementation
- Sovereign-cloud capabilities move. Before each deployment, re-read the cited Apple and Microsoft
  pages in `gcc-high-parity-notes.md` and confirm nothing has changed.


---


# Deliverables Summary — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

Everything included in this Government (GCC High) edition and what each piece is for.

## Documents (source)

| File | Purpose |
| --- | --- |
| `01-solution-overview.md` | What the solution delivers on GCC High, and the **Commercial vs GCC High — what's different** section (federation/SCIM parity gap up front). |
| `02-requirements.md` | Every GCC-High-specific prerequisite with **verify** and **implement-if-missing**, including the R0 parity decision gate. |
| `03-implementation.md` | Ordered Assess → Configure → Pilot → Validate → Expand steps using `*.us` portals, with GCC-High caveats inline. |
| `05-testing.md` | Pass/fail matrix mapped to phase gates (no SCIM-success test — that path is unsupported in US Gov). |
| `06-troubleshooting.md` | GCC-High-specific symptoms and fixes, including the "federation won't complete" expected behaviour. |
| `07-best-practices.md` | Operating practices: sovereign targeting, staging, expiries, least privilege, compliance-boundary caution. |
| `08-deliverables-summary.md` | This file. |
| `executive-summary.md` | One-page summary for decision-makers, leading with the parity gap. |
| `gcc-high-parity-notes.md` | Cited reference for every Commercial-vs-GCC-High difference; the factual backbone. |
| `global-requirements-entra-id-solutions.md` | Category-level Entra prerequisites (shared). |

## Scripts (scripts/)

All scripts connect to the **US Gov** Microsoft Graph endpoint with
`Connect-MgGraph -Environment USGov`. Read-only scripts make no changes; change scripts default to
`-WhatIf`.

| Script | Type | Purpose |
| --- | --- | --- |
| `ABMPROVG-Discovery.ps1` | Read-only | Inventory tenant, licensing signals, Apple enrollment configuration, and pilot groups; surface readiness gaps. |
| `ABMPROVG-Validation.ps1` | Read-only | Check APNs certificate, ABM ⇄ Intune token, ADE profile, and pilot assignment against pass/fail criteria. |
| `ABMPROVG-Report.ps1` | Read-only | Produce a health snapshot (token/APNs expiry, enrolled pilot devices, group membership) for records and reviews. |
| `ABMPROVG-Remediation.ps1` | Change (**-WhatIf default**) | Safely fix common drift (e.g. missing group assignment) after previewing the planned actions. |
| `ABMPROVG-Set-ScopeTargeting.ps1` | Change (**-WhatIf default**) | Build/populate the `ABM-Apple-Pilot-Devices` scope group for staged rollout. |

## How they fit the deployment model

- **Assess:** `ABMPROVG-Discovery.ps1`
- **Configure:** `ABMPROVG-Validation.ps1`
- **Pilot:** `ABMPROVG-Set-ScopeTargeting.ps1`
- **Validate:** `ABMPROVG-Validation.ps1`, `ABMPROVG-Report.ps1`, `ABMPROVG-Remediation.ps1`
- **Expand:** re-run `ABMPROVG-Set-ScopeTargeting.ps1`, then `ABMPROVG-Validation.ps1` +
  `ABMPROVG-Report.ps1`

## The one thing to remember

On GCC High, **Entra ⇄ ABM federation and SCIM auto-provisioning are not supported** (Apple excludes
national clouds). This edition delivers the **supported** outcome — ABM ⇄ Intune Government enrollment
with ABM-native Managed Apple IDs — and documents the parity gap so expectations are set correctly.
See `gcc-high-parity-notes.md` for citations.
