# Workspace ONE to Intune Coexistence & Cutover Runbook

> **Version 1.0.0** · Category: Migrations · Solution code: WS1COEX

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Workspace ONE to Intune Coexistence & Cutover Runbook

During a Workspace ONE to Microsoft Intune migration you inevitably run **both MDMs at once**, and
that overlap is where migrations break: devices end up double-managed, Conditional Access locks users
out mid-transition, and apps and certificates collide. Without a runbook, the coexistence window is
improvised — and improvisation on live production devices is how a migration turns into an outage.

This is the operational runbook for that window. It is not a feature guide; it is the order of
operations, the guardrails, the go/no-go gates, the per-cohort cutover sequence, and the tested
rollback that keep both platforms running safely in parallel until every device has cleanly cut over.

## What you get
- A **Solution Overview** of the coexistence model and the three risks it controls — double
  management, Conditional Access lockouts, and app/certificate conflicts — and *why* each matters.
- A **Requirements Guide** with verify / implement-if-missing for every coexistence prerequisite.
- An **Implementation Guide** of precise, ordered steps: establish guardrails, define cohorts and
  order, run the per-cohort cutover sequence behind a go/no-go gate, roll back on failure, then expand.
- Five **PowerShell scripts** for dual-management discovery, per-device cutover-readiness validation,
  a coexistence/cutover status report, a safe rollback helper, and a cohort group builder.
- **Testing** and **Troubleshooting** guides with explicit pass/fail gates.

## What this delivers
A controlled coexistence-and-cutover process: a single compliance authority, Conditional Access
scoped to one cohort at a time, a no-double-targeting rule for apps and profiles, a risk-ordered
cohort sequence, a go/no-go gate before and after each cutover, and a rollback proven on the pilot
before any production wave. Workspace ONE internals are deferred to VMware's documentation; the
Intune and Microsoft Entra side is given with exact navigation.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a per-cohort go/no-go gate and a tested
rollback at the Validate step. This is the repeatable way: assign the guardrails once, then repeat the
cohort sequence everywhere.

## Outcome
A calm migration window instead of a chaotic one — guardrails against double management, gated
cutovers, a per-cohort sequence, and a tested rollback — proven on a pilot cohort before you scale.


---


# 1. Solution Overview — Workspace ONE to Intune Coexistence & Cutover Runbook

## What this runbook is
This is an operational runbook for the riskiest phase of a Workspace ONE to Microsoft Intune
migration: the window where **both MDMs are live at the same time**. It is not a feature guide — it
is the order of operations, the guardrails, the go/no-go gates, the per-cohort cutover sequence, and
the tested rollback that keep that window controlled instead of chaotic. The destination side
(Intune and Microsoft Entra) is given with exact navigation; Workspace ONE internals are deferred to
VMware's own documentation, because the source console changes independently of this runbook.

## Why coexistence is the dangerous part
During a migration you cannot flip an entire fleet at once, so for a period each device is in transit
between two management authorities. Three things break in that period:

- **Double management** — a device that is still enrolled in Workspace ONE while also enrolled in
  Intune can receive conflicting policy (two compliance engines, two sets of profiles, two app
  catalogs), get pushed contradictory settings, or silently drop one authority's payloads.
- **Conditional Access lockouts** — if Microsoft Entra Conditional Access starts requiring a
  compliant or enrolled device before the device is actually managed by Intune and reporting
  compliant, users get locked out of email and apps mid-migration.
- **App and certificate conflicts** — the same app, Wi-Fi/VPN profile, or certificate delivered by
  both platforms can collide, duplicate, or revoke each other.

The *why* lives only in this Overview. Everything after this file is procedure.

## How the runbook works
1. Establish the `Coexistence Guardrails – Tenant – Configure` so the two platforms cannot fight:
   one compliance authority, scoped Conditional Access, and a no-double-targeting rule for apps and
   profiles.
2. Define cohorts and their order with the `Cohort Cutover Order – Fleet – Pilot` plan — small,
   low-risk groups first; high-impact groups last.
3. For each cohort, run the `Cutover Sequence – Cohort – Validate` steps behind the
   `Go/No-Go Checklist – Cohort – Validate`. A cohort only proceeds if every gate passes.
4. If a gate fails, execute the `Rollback Plan – Cohort – Validate` to return the cohort to
   Workspace ONE management with no user lockout.
5. Repeat per cohort, expanding only after each prior cohort is validated and stable.

## What you control with this runbook
- Which platform owns **device compliance** during coexistence (the single compliance authority).
- The **Conditional Access scope** so policies tighten only as devices actually become Intune-managed.
- The **cutover order** — cohort sequencing from pilot to fleet.
- The **go/no-go gates** that must pass before each cohort proceeds.
- The **rollback** path that reverses a cohort cleanly if a gate fails.

## What is in scope vs deferred
- **In scope, exact:** Intune (`https://intune.microsoft.com`) and Microsoft Entra
  (`https://entra.microsoft.com`) configuration — managed devices, Conditional Access, security
  groups, enrollment readiness, compliance.
- **Deferred to VMware documentation:** Workspace ONE UEM console navigation, unenrollment/retirement
  steps, smart-group and profile internals, and the Workspace ONE Intelligent Hub behavior. Where the
  runbook needs a Workspace ONE action it is flagged as `[WS1 — see VMware docs]` rather than
  invented.

## Limitations (be honest with buyers)
- This runbook governs the **coexistence and cutover** phase. Building the target estate (apps,
  configuration profiles, compliance policies, enrollment connectors) is the prerequisite work and is
  assumed complete or in progress per the category global requirements.
- It does **not** automate Workspace ONE-side unenrollment; that action is performed in the source
  console per VMware's documentation and is represented here as a flagged step.
- Conditional Access changes affect live sign-ins; every CA change in this runbook is **scoped to a
  cohort group**, never the whole tenant, until the final expand stage.

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand**, with a **per-cohort go/no-go gate and a tested
> rollback** at the Validate step. No cohort expands until the prior cohort passes its gate. This is
> the repeatable way: assign the guardrails once, then repeat the cohort sequence everywhere.


---


# 2. Requirements Guide — Workspace ONE to Intune Coexistence & Cutover Runbook

Verify **every** requirement before running any cutover. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-migrations.md` (G1–G7);
this guide adds the coexistence-and-cutover-specific requirements.

## 2.1 Both-platform admin access (target and source)
**Description:** Intune Administrator (target) plus administrative access to the Workspace ONE UEM console (source).
**Why:** Coexistence is operated from both sides — you assign and validate in Intune/Entra, and you retire devices in Workspace ONE.
**Verify:** `https://intune.microsoft.com` loads and you hold Intune Administrator; you can sign in to the Workspace ONE UEM console. Run `WS1COEX-Discovery.ps1` to confirm Graph access to the target.
**Implement:** Obtain the Intune Administrator role (least privilege) and the source-console admin role from the platform owner `[WS1 — see VMware docs]`.

## 2.2 Single compliance authority decided
**Description:** A documented decision on which platform owns device compliance during coexistence (the migration target, Intune, is the recommended authority once a cohort is enrolled).
**Why:** Two compliance engines reporting to Conditional Access produce inconsistent compliant/non-compliant states and lockouts.
**Verify:** The decision is written into the `Coexistence Guardrails – Tenant – Configure` and Conditional Access references the chosen authority.
**Implement:** Document the authority; ensure Intune compliance policies exist and are assigned to the migration target groups before tightening Conditional Access.

## 2.3 Conditional Access readiness (scoped, not tenant-wide)
**Description:** Conditional Access policies that can require compliant/Intune-enrolled devices must be **scoped to cohort groups**, not all users, during coexistence.
**Why:** A tenant-wide "require compliant device" policy will lock out every user whose device is not yet Intune-managed.
**Verify:** Entra → **Protection → Conditional Access** — any device-compliance/enrollment policy targets a cohort group, not All users. Run `WS1COEX-Validation.ps1` for per-device readiness.
**Implement:** Create or edit the policy to assign only the current cohort group; expand assignment one cohort at a time. See Implementation Step 2.

## 2.4 Cohort plan and cohort groups
**Description:** A `Cohort Cutover Order – Fleet – Pilot` plan and one Microsoft Entra security group per cohort.
**Why:** Cutover is sequenced; each cohort is a unit that is gated, cut over, validated, or rolled back together.
**Verify:** Entra → **Groups** — cohort groups exist (e.g. `Cutover Cohort – Pilot – Stage1`); the order plan is documented.
**Implement:** Build cohort groups with `WS1COEX-Set-CohortTargeting.ps1`; define order by risk (pilot, low-impact, high-impact) per the global requirement G6.

## 2.5 Target enrollment channels active
**Description:** The enrollment plumbing for each in-scope platform is live in Intune (APNs for Apple, managed Google Play for Android, automatic enrollment for Windows).
**Why:** A device cannot become Intune-managed during cutover if the target enrollment channel is not active.
**Verify:** Intune shows the relevant connector/cert/token **Active** for each platform in scope (global requirement G5). Run `WS1COEX-Validation.ps1`.
**Implement:** Configure the APNs certificate, ABM/ADE token, managed Google Play, and Windows automatic enrollment as needed (global requirement G5).

## 2.6 No-double-targeting rule for apps and profiles
**Description:** A written rule that the same app, Wi-Fi/VPN profile, or certificate is not delivered by both platforms to the same cohort at the same time.
**Why:** Dual delivery causes app duplication, profile collisions, and certificate revocation conflicts.
**Verify:** Intune app/profile assignments for a cohort do not overlap with still-active Workspace ONE assignments for that cohort `[WS1 — see VMware docs]`. Captured in the `Coexistence Guardrails – Tenant – Configure`.
**Implement:** Sequence delivery — keep the source delivering until the cohort cuts over, then remove the source assignment as part of the cutover step.

## 2.7 Change control and a tested rollback
**Description:** An approved change window, a comms channel, and a `Rollback Plan – Cohort – Validate` that has been tested on the pilot cohort before any production cutover.
**Why:** Cutover touches live production devices and live sign-ins; it must be reversible and coordinated (global requirement G7).
**Verify:** The rollback procedure is written, approved, and proven once on the pilot. Run `WS1COEX-Remediation.ps1 -WhatIf` to preview the rollback actions.
**Implement:** Write the rollback per platform, schedule the change window, and rehearse rollback on the pilot cohort before expanding.

## 2.8 Coexistence and cutover status reporting
**Description:** The ability to report which devices are Workspace ONE-only, Intune-only, dual-managed, or compliant.
**Why:** Go/no-go gates depend on knowing the exact management state of every device in a cohort.
**Verify:** Run `WS1COEX-Report.ps1` and confirm it returns per-device management/compliance state.
**Implement:** Install the Microsoft Graph PowerShell SDK and grant the read scopes the scripts request (see Implementation).

---
## Checklist
- [ ] Intune Administrator (target) and Workspace ONE UEM admin (source) access — `WS1COEX-Discovery.ps1`
- [ ] Single compliance authority decided and documented
- [ ] Conditional Access scoped to cohort groups (not All users) — `WS1COEX-Validation.ps1`
- [ ] Cohort plan written; cohort Entra groups created — `WS1COEX-Set-CohortTargeting.ps1`
- [ ] Target enrollment channels Active for each in-scope platform
- [ ] No-double-targeting rule for apps/profiles in place
- [ ] Change window approved; rollback tested on the pilot — `WS1COEX-Remediation.ps1 -WhatIf`
- [ ] Coexistence/cutover status report runs — `WS1COEX-Report.ps1`


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


# 3. Implementation Guide — Workspace ONE to Intune Coexistence & Cutover Runbook

Follow these steps **in order**. Intune steps are in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`); identity/Conditional Access steps are in the **Microsoft Entra admin
center** (`https://entra.microsoft.com`). Any Workspace ONE-side action is flagged
`[WS1 — see VMware docs]` and performed in the source console per VMware's documentation.

> **Model:** Establish guardrails once, then repeat the cohort sequence everywhere. Each cohort
> passes through a go/no-go gate; a failed gate triggers the tested rollback. No cohort expands until
> the prior cohort is validated and stable. This is the repeatable way.

## Stage A — Assess

### Step 1 — Discover the current management state
1. Run `WS1COEX-Discovery.ps1` to inventory managed devices in the target, flag **dual-managed**
   devices (present in Intune while still Workspace ONE-enrolled), and snapshot Conditional Access
   policies and cohort groups. Read-only.
2. Record the baseline counts: Workspace ONE-only, Intune-only, dual-managed, and unmanaged.
3. Confirm every requirement in `02-requirements.md` and `global-requirements-migrations.md` is met.

## Stage B — Configure (the coexistence guardrails)

### Step 2 — Establish `Coexistence Guardrails – Tenant – Configure`
1. **Single compliance authority.** In Intune confirm compliance policies exist and are assigned to
   the migration-target groups. Decide and document that Intune owns compliance for cohorts once they
   enroll. Keep Workspace ONE compliance reporting for not-yet-cut-over devices `[WS1 — see VMware docs]`.
2. **Scope Conditional Access to cohorts.** Entra → **Protection → Conditional Access**. For any
   policy that requires a compliant or Intune-enrolled device, set **Assignments → Users → Include →
   Select users and groups** to the **current cohort group only** — never **All users** during
   coexistence. Leave non-cohort users unaffected.
3. **No-double-targeting rule.** Record that an app, Wi-Fi/VPN profile, or certificate is delivered by
   only one platform to a given cohort at a time; the source keeps delivering until the cohort cuts
   over `[WS1 — see VMware docs]`.
4. Save this configuration as the named `Coexistence Guardrails – Tenant – Configure` artifact and
   reuse it verbatim for every cohort.

### Step 3 — Build the cohorts and their order
1. Define the `Cohort Cutover Order – Fleet – Pilot` plan: order cohorts by risk — a small pilot
   first, then low-impact groups, then high-impact groups last.
2. Create one Microsoft Entra security group per cohort (e.g. `Cutover Cohort – Pilot – Stage1`).
   Use `WS1COEX-Set-CohortTargeting.ps1` to create the group and add members from a device or user
   list. Run it with `-WhatIf` first to preview membership changes.

## Stage C — Pilot (cut over the first cohort)

### Step 4 — Pre-cutover go/no-go gate
1. Run `WS1COEX-Validation.ps1` against the pilot cohort to confirm per-device cutover readiness:
   target enrollment channel active, Conditional Access scoped to this cohort, no conflicting double
   assignment, and device reachable.
2. Apply the `Go/No-Go Checklist – Cohort – Validate` (see `05-testing.md`). Proceed only if **every**
   gate passes; otherwise hold and remediate.

### Step 5 — Execute `Cutover Sequence – Cohort – Validate` for the pilot
1. **Enroll into the target.** Add the cohort group to the relevant Intune enrollment/app/compliance
   assignments so devices become Intune-managed.
2. **Confirm Intune compliance.** Wait for the cohort's devices to report compliant in Intune
   (`WS1COEX-Report.ps1` shows the live state).
3. **Tighten Conditional Access for the cohort.** With the cohort compliant in Intune, the
   cohort-scoped Conditional Access policy from Step 2 now safely enforces compliant/enrolled device.
4. **Remove the source assignment / retire from Workspace ONE.** Remove the cohort's Workspace ONE
   app/profile assignments and unenroll/retire the devices from the source `[WS1 — see VMware docs]`
   so the device is no longer double-managed.
5. **Confirm single management.** Re-run `WS1COEX-Report.ps1`; the cohort should now show Intune-only,
   not dual-managed.

### Step 6 — Roll back the pilot if a gate fails
1. If validation fails at any point, execute `Rollback Plan – Cohort – Validate`:
   run `WS1COEX-Remediation.ps1 -WhatIf` to preview, then re-run without `-WhatIf` to remove the
   cohort group from the cohort-scoped Conditional Access policy and from Intune assignments, returning
   the cohort to Workspace ONE management with no user lockout.
2. Re-enroll/keep the device in Workspace ONE per the source console as needed `[WS1 — see VMware docs]`.
3. Confirm with `WS1COEX-Report.ps1` that the cohort is back to its pre-cutover state, then diagnose
   the failed gate before retrying.

## Stage D — Validate

### Step 7 — Validate the pilot cohort
1. Complete the **Testing Guide** (`05-testing.md`) for the pilot cohort; confirm every pass/fail gate.
2. Confirm the rollback was tested at least once on the pilot (requirement 2.7).
3. Record results; the pilot is the proof that the guardrails and the cutover sequence are sound.

## Stage E — Expand

### Step 8 — Repeat per cohort, then expand
1. For each subsequent cohort in `Cohort Cutover Order – Fleet – Pilot`, repeat Steps 4–7 verbatim:
   pre-cutover gate → cutover sequence → validate (or roll back).
2. Add the next cohort group to the cohort-scoped Conditional Access policy only after the prior
   cohort is Intune-only and stable — never widen Conditional Access ahead of the cutover.
3. After the final cohort, the migration-target groups cover the fleet; only then consider broadening
   Conditional Access to the full population.
4. Re-validate each cohort with `WS1COEX-Report.ps1` before moving on.

---
### Order of operations
`Discover → Guardrails → Cohorts & order → Pre-cutover gate → Cutover sequence → Validate (or Rollback) → Repeat per cohort → Expand`


---


# 5. Testing Guide — Workspace ONE to Intune Coexistence & Cutover Runbook

Run these tests as the `Go/No-Go Checklist – Cohort – Validate`. They apply **per cohort**: once
before cutover (the pre-cutover gate, Implementation Step 4) and again after cutover (the validate
gate, Implementation Step 7). A cohort only proceeds when every gate in the relevant stage passes;
any failure triggers the `Rollback Plan – Cohort – Validate`.

## Pre-cutover gate (before Step 5)

### Test 1 — Cohort group is correct
**Do:** Entra → **Groups →** the cohort group → **Members**; or run `WS1COEX-Validation.ps1`.
**Expected:** Membership matches the intended cohort exactly — no extra or missing devices/users.

### Test 2 — Conditional Access is cohort-scoped
**Do:** Entra → **Protection → Conditional Access**; check every compliance/enrollment policy.
**Expected:** Each such policy includes the **cohort group**, not **All users**. No tenant-wide
"require compliant device" is active during coexistence.

### Test 3 — Target enrollment channel active
**Do:** Confirm the relevant connector/cert/token shows **Active** for the cohort's platform; run `WS1COEX-Validation.ps1`.
**Expected:** Apple APNs / ABM-ADE, managed Google Play, or Windows automatic enrollment is **Active**.

### Test 4 — No double-targeting for the cohort
**Do:** Compare Intune app/profile assignments for the cohort against still-active Workspace ONE assignments `[WS1 — see VMware docs]`.
**Expected:** The same app/profile/certificate is not delivered by both platforms to this cohort at once.

## Post-cutover gate (after Step 5)

### Test 5 — Devices are Intune-managed and compliant
**Do:** Run `WS1COEX-Report.ps1` for the cohort, or Intune → **Devices → All devices**.
**Expected:** Cohort devices are enrolled in Intune and report **compliant**.

### Test 6 — No longer dual-managed
**Do:** Run `WS1COEX-Report.ps1`; review the management-state column.
**Expected:** Cohort devices show **Intune-only** — not dual-managed (Workspace ONE assignment/enrollment removed) `[WS1 — see VMware docs]`.

### Test 7 — No Conditional Access lockout
**Do:** With a pilot user in the cohort, confirm sign-in to a Conditional-Access-protected app succeeds; check Entra → **Sign-in logs**.
**Expected:** The compliant Intune device satisfies the cohort-scoped policy; no unexpected block.

### Test 8 — Rollback proven (pilot cohort only)
**Do:** On the pilot cohort, run `WS1COEX-Remediation.ps1 -WhatIf` then execute the rollback once, and confirm with `WS1COEX-Report.ps1`.
**Expected:** The cohort returns to Workspace ONE management with no user lockout; state matches pre-cutover.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pre-cutover go** | Tests 1–4 pass for the cohort |
| **Post-cutover go** | Tests 5–7 pass for the cohort |
| **Pilot complete** | Tests 1–8 pass, including a proven rollback (Test 8) |
| **No-go → rollback** | Any gate fails → execute `Rollback Plan – Cohort – Validate`, then diagnose before retry |


---


# 6. Troubleshooting Guide — Workspace ONE to Intune Coexistence & Cutover Runbook

Use `WS1COEX-Discovery.ps1` and `WS1COEX-Validation.ps1` for state, `WS1COEX-Report.ps1` for the
live management/compliance picture, and `WS1COEX-Remediation.ps1` (default `-WhatIf`) for the safe
rollback helper. Workspace ONE-side actions are flagged `[WS1 — see VMware docs]`.

## A. Conditional Access lockouts during coexistence
| Symptom | Cause | Remediation |
|---|---|---|
| Users locked out of email/apps after a cutover | A compliance/enrollment Conditional Access policy is scoped to All users, or to a cohort whose devices are not yet Intune-compliant | Re-scope the policy to the **cohort group only**; confirm devices are compliant in Intune first (`WS1COEX-Report.ps1`); if needed, execute `Rollback Plan – Cohort – Validate` to remove the cohort from the policy |
| Cohort blocked even though enrolled | Devices enrolled but not yet reporting compliant | Wait for compliance to evaluate; re-run `WS1COEX-Report.ps1`; tighten Conditional Access only once compliant |

## B. Double management / conflicting policy
| Symptom | Cause | Remediation |
|---|---|---|
| Device shows in both platforms after cutover | Source assignment/enrollment not removed | Remove the Workspace ONE assignment and retire the device from the source `[WS1 — see VMware docs]`; confirm Intune-only with `WS1COEX-Report.ps1` |
| Conflicting/duplicated profiles or settings | The same payload delivered by both platforms | Enforce the no-double-targeting rule from the `Coexistence Guardrails – Tenant – Configure`; remove one platform's assignment for that cohort |

## C. App and certificate conflicts
- The same app installed twice, or a certificate revoked unexpectedly, usually means both platforms
  targeted the cohort. Keep the source delivering until cutover, then remove the source assignment;
  re-issue the certificate from the surviving authority only `[WS1 — see VMware docs]`.

## D. Cutover gate fails
- If `WS1COEX-Validation.ps1` fails a pre-cutover gate, do **not** proceed. Hold the cohort, fix the
  flagged item (enrollment channel, Conditional Access scope, double-targeting), and re-run the gate.
- If a post-cutover gate fails, execute the `Rollback Plan – Cohort – Validate`
  (`WS1COEX-Remediation.ps1 -WhatIf` to preview, then run for real).

## E. Rollback did not fully revert
- Confirm the cohort group was removed from both the cohort-scoped Conditional Access policy **and**
  the Intune assignments; re-run `WS1COEX-Remediation.ps1 -WhatIf` to see remaining actions, then
  re-enroll/keep the device in Workspace ONE per the source console `[WS1 — see VMware docs]`. Verify
  with `WS1COEX-Report.ps1`.

## F. Discovery shows unexpected dual-managed devices
- Devices appearing as dual-managed before any cutover indicate a prior overlap; quarantine them out
  of the current cohort, resolve the source enrollment `[WS1 — see VMware docs]`, then re-add to a
  later cohort.

## G. When to escalate
If gates pass, Conditional Access is correctly cohort-scoped, devices report compliant in Intune, and
users are still blocked or devices still show dual-managed after a clean rollback, collect the
`WS1COEX-Report.ps1` output and the Entra **Sign-in logs** for the affected user and open a Microsoft
support case (and a VMware case for source-side enrollment issues).


---


# 7. Best Practices — Workspace ONE to Intune Coexistence & Cutover Runbook

- **Never run a tenant-wide "require compliant device" during coexistence.** Scope every Conditional
  Access compliance/enrollment policy to the **current cohort group** and widen it one cohort at a
  time. This is the single most important guardrail against migration lockouts.
- **Pick one compliance authority and write it down.** Two compliance engines reporting to
  Conditional Access produce flapping compliant/non-compliant states. Let the target (Intune) own
  compliance for a cohort the moment it enrolls.
- **Cut over in cohorts, smallest and lowest-risk first.** A pilot cohort proves the guardrails and
  the cutover sequence before any high-impact group is touched.
- **Gate every cohort.** Apply the `Go/No-Go Checklist – Cohort – Validate` before and after each
  cutover; a cohort that fails a gate rolls back rather than limping forward.
- **Test the rollback on the pilot before you need it in production.** A rollback that has never been
  run is not a rollback. Prove it once on the pilot cohort.
- **Never double-target the same app, profile, or certificate.** Keep the source delivering until the
  cohort cuts over, then remove the source assignment as part of the cutover — not before, not after.
- **Remove the source assignment as part of cutover, not later.** A device left dual-managed is a
  device waiting to receive conflicting policy. Confirm Intune-only with the status report.
- **Assign once, repeat everywhere.** Build the `Coexistence Guardrails – Tenant – Configure` one
  time and reuse it verbatim per cohort; only the cohort group changes between waves.
- **Report before every gate.** Run `WS1COEX-Report.ps1` so go/no-go decisions are based on the live
  management state, not assumptions.
- **Defer Workspace ONE internals to VMware.** Perform source-console actions per VMware's
  documentation; this runbook flags them rather than guessing at a console that changes independently.
- **Communicate the window to users.** A short note about the cutover and what to expect dramatically
  reduces tickets during the coexistence period.
- **Document each cohort's result.** Record gate outcomes, the cutover date, and any rollback for
  audits and repeatability across the remaining waves.


---


# 8. Deliverables Summary — Workspace ONE to Intune Coexistence & Cutover Runbook

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The coexistence model, the risks (double management, Conditional Access, app conflicts), the cutover sequence, go/no-go gates, and rollback — and *why* |
| 2. Requirements Guide | Every coexistence/cutover prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: guardrails, cohorts, per-cohort cutover sequence, validate, rollback, expand |
| 5. Testing Guide | The `Go/No-Go Checklist – Cohort – Validate` with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for the assign-once, repeat-everywhere model |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WS1COEX-Discovery.ps1` | Read-only. Inventories target managed devices, flags dual-managed devices, and snapshots Conditional Access policies and cohort groups |
| `WS1COEX-Validation.ps1` | Read-only. Per-device cutover-readiness gate: enrollment channel, Conditional Access scope, double-targeting, reachability |
| `WS1COEX-Report.ps1` | Read-only. Coexistence/cutover status report: Workspace ONE-only / Intune-only / dual-managed / compliant per device |
| `WS1COEX-Remediation.ps1` | Safe remediation and rollback helper (default `-WhatIf`); removes a cohort from cohort-scoped Conditional Access and Intune assignments to revert a cutover |
| `WS1COEX-Set-CohortTargeting.ps1` | Builds a cohort Entra security group and sets its membership (default `-WhatIf`) |

## Named artifacts (reuse verbatim)
| Artifact | Scope · Stage |
|---|---|
| `Coexistence Guardrails – Tenant – Configure` | One compliance authority, scoped Conditional Access, no-double-targeting |
| `Cohort Cutover Order – Fleet – Pilot` | The risk-ordered cohort sequence |
| `Go/No-Go Checklist – Cohort – Validate` | The per-cohort gate (Testing Guide) |
| `Cutover Sequence – Cohort – Validate` | The ordered per-cohort cutover steps |
| `Rollback Plan – Cohort – Validate` | The tested per-cohort rollback |

## What the buyer receives
- This runbook as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP (read-only discovery/validation/report; `-WhatIf`-default remediation and cohort builder).
- A repeatable process: **Assess → Configure → Pilot → Validate → Expand**, with a per-cohort go/no-go gate and a tested rollback.

## Outcome
A controlled transition while both MDMs run in parallel — guardrails against double management,
go/no-go gates, a per-cohort cutover sequence, and a tested rollback — proven on a pilot cohort before
you scale.
