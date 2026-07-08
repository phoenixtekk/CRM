# Requirements

These are the **solution-specific** prerequisites for migrating Intune's Android Enterprise
management to the **Android Management API (AMAPI)**. They build **on top of** the category-level
**Global Requirements — Microsoft Intune Android** (M365 tenant with Intune + Android Enterprise,
the managed Google Play binding, least-privilege admin roles, the enrollment-method decision +
Graph toolchain, network reachability, and a pilot scope with change control) — confirm those
first; this document does **not** repeat them.

Each requirement is stated as **Description · Why · Verify · Implement-if-missing.**

> **Version boundary (applies to R3, R4, R5).** The AMAPI transition, web/account-driven
> enrollment, and re-enrollment behavior are **actively evolving**. Where a requirement depends on
> current Microsoft behavior, it says **"verify against current Microsoft guidance / your tenant"** —
> that verification is part of satisfying the requirement, not optional.

---

## R1. A healthy managed Google Play binding (the connection you are migrating)

**Description:** The tenant's **managed Google Play** connection — either the **account
enterprise** model (no Google Workspace) or the **Google Workspace / Cloud Identity ↔ Intune
third-party EMM** integration — must be **present and healthy** before migrating.
**Why:** AMAPI does not remove managed Google Play; the migration moves the *management plane*
while the binding continues to underpin enrollment and app delivery. A broken/expired binding will
surface as migration and app-sync failures.
**Verify:** Intune admin center → **Devices > Android > Android enterprise** (or **Enrollment**) —
confirm the connection status is **connected** and app sync is current. Via Graph (beta):
`GET /deviceManagement/androidManagedStoreAccountEnterpriseSettings` — check `bindStatus` and
`lastAppSyncDateTime`. `AMAPIMIG-Config.ps1 -HealthSummary` reports it.
**Implement:** Repair or re-establish the binding first (see the category Global Requirements and
the Android Enterprise connection solution). Do **not** migrate on top of a degraded binding.

## R2. A current inventory of the Android estate and enrollment models

**Description:** A known inventory of enrolled Android devices grouped by **enrollment model**
(work profile / fully managed / corporate-owned work profile / dedicated-COSU), ownership,
OS/OEM, and last check-in.
**Why:** Migration risk and end-user impact differ per enrollment model; you cannot wave-plan or
scope communications without knowing the population.
**Verify:** Intune → **Devices > All devices** (filter OS = Android), or run
`AMAPIMIG-Assess-AndroidEstate.ps1` (read-only) for a breakdown by
`deviceEnrollmentType` / `managementAgent` / `ownerType` / `osVersion` / `manufacturer`.
**Implement:** Run the assessment and reconcile against your CMDB before designing waves.

## R3. Confirmed current AMAPI migration guidance and status for the tenant

**Description:** The **current** Microsoft guidance on the AMAPI transition — what has moved, what
is pending, any admin action Microsoft requires, and any tenant-level migration status Microsoft
surfaces — **read at the time you plan the migration**.
**Why:** The rollout is staged and changing; the correct sequence and whether admin action is
needed are version-dependent and **must not** be assumed from memory.
**Verify:** Review Microsoft's current **Android Management API / Intune "What's new" and Android
Enterprise** documentation and any **Message center** posts for the tenant. Confirm whether Intune
presents an AMAPI migration status or required action in the admin center.
**Implement (if unknown):** Do not proceed on assumptions — establish the current guidance first.
This requirement is satisfied only when the team can state, in writing, what the current rollout
requires. **Verify against current Microsoft guidance / your tenant.**

## R4. A verified end-user / re-enrollment impact statement (per enrollment model)

**Description:** A written, **tenant-verified** statement of what each enrollment model's users
will experience during migration — **no change**, **re-consent**, **re-enrollment**, or a **work-
profile reset/wipe** — confirmed by pilot observation and current Microsoft guidance.
**Why:** This is the highest-impact unknown. Communicating the wrong outcome (or none) erodes
trust and can cause data loss on dedicated devices. It **cannot** be asserted from memory because
it is version- and model-dependent.
**Verify:** Confirm the behavior in the **pilot** (Phase Pilot in Implementation) and against
current Microsoft guidance for each model you operate. Capture screenshots of the actual user flow.
**Implement (if unknown):** Treat "unknown" as a blocker for that model's production wave. Pilot
it, verify it, write it down, **then** communicate. **Verify against current Microsoft guidance /
your tenant.**

## R5. Web / account-driven enrollment readiness decision (where applicable)

**Description:** A decision — informed by a readiness check — on whether the migration will adopt
the newer **web / account-driven enrollment** path for any model, based on its **current
availability** for your tenant and enrollment model.
**Why:** Web/account-driven enrollment is part of the modern direction but its availability and
flow are evolving; designing a wave around it before confirming availability creates rework.
**Verify:** `AMAPIMIG-Test-WebEnrollmentReadiness.ps1` (read-only) checks the binding, enrollment
profiles, and prerequisite signals; then **confirm the method's availability for your enrollment
model against current Microsoft guidance.**
**Implement:** If available and desired, include it in the wave design; if not (or unverified),
plan the migration on the currently-supported enrollment method and revisit later. **Verify
against current Microsoft guidance / your tenant.**

## R6. Enrollment profiles, app assignments, and Conditional Access reviewed

**Description:** The current **Android enrollment profiles** (e.g. device-owner enrollment
profiles / tokens for dedicated & fully managed), **managed Google Play app assignments**, and any
**Conditional Access / compliance policies** targeting Android are reviewed and understood before
migration.
**Why:** A migration that changes enrollment must preserve app delivery and not inadvertently lock
users out via a compliance/CA policy that re-evaluates on re-enrollment.
**Verify:** Intune → **Devices > Android > Enrollment** (profiles/tokens), **Apps > Android**, and
**Endpoint security / CA**. Via Graph (beta): `androidDeviceOwnerEnrollmentProfiles`,
`deviceAppManagement/mobileApps` (androidManagedStoreApp), and compliance/CA policies.
**Implement:** Document the current assignments so post-migration validation (apps deliver,
compliant, CA passes) has a known baseline.

## R7. A pilot cohort per enrollment model and change control

**Description:** A **named pilot cohort for each enrollment model** you operate (a few work-profile
users, a fully-managed device, a spare dedicated/COSU device), plus a **change window** — because
AMAPI-migration changes are **high-impact and may affect existing devices**.
**Why:** The house model is pilot-first; re-enrollment/impact behavior must be proven per model on
throwaway/representative devices before any production wave.
**Verify:** Confirm the pilot devices/users exist per model and a change window is approved.
**Implement:** Recruit pilot users, set aside spare corporate/dedicated devices, and agree change
control before touching production.

## R8. Microsoft Graph PowerShell for automation

**Description:** The **Microsoft.Graph** PowerShell SDK (v2+), modern-auth, for the five tools in
this solution.
**Why:** The scripts inventory the estate, plan waves, check readiness, and validate — all via
Microsoft Graph, read-only or `-WhatIf` by default.
**Verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a module;
`Connect-MgGraph` succeeds interactively.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Consent the **least** scopes
the scripts request — read tools use `DeviceManagementManagedDevices.Read.All`,
`DeviceManagementServiceConfig.Read.All`, `DeviceManagementConfiguration.Read.All`,
`DeviceManagementApps.Read.All`; the wave-planner requests `Group.ReadWrite.All` **only** when you
opt into creating wave groups (and only with `-Commit`). No app secrets are stored — all scripts
use interactive/delegated `Connect-MgGraph`.

---

**Prerequisite gate:** Do not begin a production wave until **R1–R4, R6, R7** are satisfied (and
**R5** where web/account-driven enrollment is in scope). R3 and R4 in particular are only
satisfied once the current Microsoft guidance and the pilot-observed impact are **written down** —
migrating on assumptions about re-enrollment is the failure this solution exists to prevent.
