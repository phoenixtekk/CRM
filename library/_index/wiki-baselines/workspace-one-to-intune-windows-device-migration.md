# Workspace ONE to Intune — Windows Device Migration

> **Version 1.0.0** · Category: Migrations · Solution code: WS1WIN

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Workspace ONE to Intune (Windows Device Migration)

Migrating Windows endpoints off Workspace ONE is risky in three specific ways: a device can end up
managed by *neither* platform, managed by *both* at once, or re-enrolled into Intune *without* the
configuration, compliance, and access it had before. Any of those breaks users or weakens security.

This is a complete, deploy-it-today package for the repeatable Workspace ONE to Intune Windows
device migration: prepare identity and enrollment, build configuration and compliance parity in
Intune, unenroll from Workspace ONE and enroll to Intune in controlled rings, and validate every
device before moving to the next ring. It is written for an administrator with no prior migration
experience.

## What you get
- A plain-language Solution Overview of the migration model — unenroll from Workspace ONE, Entra
  join, automatic enrollment to Intune, configuration and compliance parity, Conditional Access
  continuity, and the ringed cutover that avoids dual management.
- A Requirements Guide with `Verify` and `Implement-if-missing` for every prerequisite.
- An Implementation Guide of precise, ordered Intune and Entra steps in the required sequence.
- Five PowerShell scripts for migration-readiness discovery, per-device enrollment and parity
  validation, a migration status and compliance report, safe remediation of dual or failed
  enrollment, and a migration-ring group builder.
- Testing and Troubleshooting guides with explicit pass/fail gates.

## What this delivers
A ringed cutover built on named, reusable artifacts: a `Parity Configuration – Windows – Migration`
that recreates the source settings in Intune, a `Compliance Policy – Windows – Migration` that
mirrors the source compliance bar, Conditional Access continuity so access never depends on the old
MDM, and two rings — `Migration Ring – Pilot – Windows` and `Migration Ring – Broad – Windows` —
that move devices in safe, validated waves.

## The deployment model
`Assess → Configure → Pilot → Validate → Expand`, with a pilot-ring gate and a documented rollback.

## Outcome
Windows devices moved from Workspace ONE to Intune — re-enrolled with full configuration and
compliance parity, access uninterrupted, none left dual- or un-managed — proven on a pilot ring
before you scale.


---


# 1. Solution Overview — Workspace ONE to Intune (Windows Device Migration)

## What this migration is
This solution moves managed Windows devices from VMware Workspace ONE UEM to Microsoft Intune. Each
device is cleanly removed from Workspace ONE management, joined to (or confirmed in) Microsoft Entra
ID, and enrolled into Intune via Windows automatic enrollment — landing the same configuration,
compliance posture, and access it had before. The work is done in controlled rings so that risk is
contained to a small pilot before the fleet moves.

## Why it is done this way (the *why* — this section only)
A Windows device can only have one MDM authority at a time. If you enroll into Intune without first
removing Workspace ONE, you risk *dual management* — two MDMs fighting over the same settings,
producing unpredictable policy, broken compliance reporting, and confused users. If you remove
Workspace ONE without a confirmed Intune enrollment path, you risk an *unmanaged* device with no
policy and no compliance signal. And if you re-enroll without first rebuilding the device's
configuration and compliance in Intune, the device loses settings it depended on and may fail
Conditional Access, locking the user out of corporate resources.

The repeatable way removes all three risks in order:
1. Build configuration and compliance parity in Intune *first*, so the target is ready before any
   device moves.
2. Make access depend on Entra ID and Intune compliance — not on Workspace ONE — *before* cutover,
   so removing the old MDM never breaks sign-in.
3. Cut over in rings, unenrolling from Workspace ONE and enrolling into Intune one wave at a time,
   validating each device before the next ring begins.

## How it works
1. The target is prepared: Entra ID, Intune licensing, and Windows automatic enrollment are confirmed,
   and a `Parity Configuration – Windows – Migration` and `Compliance Policy – Windows – Migration`
   are built in Intune to match the Workspace ONE baseline.
2. Conditional Access is set so corporate access requires a compliant, Entra-joined device — call this
   `Conditional Access Continuity – Windows – Migration` — independent of Workspace ONE.
3. Devices are grouped: `Group – Migration Pilot – Windows` (a few representative devices) and
   `Group – Migration Broad – Windows` (the rest), with parity and compliance assigned to both up
   front so policy is waiting when each device enrolls.
4. Pilot devices unenroll from Workspace ONE (the unenrollment is performed per VMware's Workspace ONE
   documentation — see the vendor note below), join Entra ID, and enroll into Intune automatically.
5. Each migrated device is validated — enrollment state, parity configuration applied, compliance
   green, access working — using the included scripts.
6. Once the pilot passes its gate, the broad ring follows the same path; remediation handles any
   device left dual- or un-managed.

## The named artifacts (used verbatim throughout)
- `Parity Configuration – Windows – Migration` — the Intune configuration profile(s) that recreate the
  Workspace ONE Windows settings in the target.
- `Compliance Policy – Windows – Migration` — the Intune compliance policy that mirrors the source
  compliance bar (e.g. encryption, firewall, minimum OS).
- `Conditional Access Continuity – Windows – Migration` — the Conditional Access policy that ties
  access to a compliant, Entra-joined Windows device.
- `Migration Ring – Pilot – Windows` and `Migration Ring – Broad – Windows` — the cutover waves.
- `Group – Migration Pilot – Windows`, `Group – Migration Broad – Windows` — the Entra security groups
  the rings target.
- `Group – Workspace ONE Managed – Windows` — the inventory/exclusion group of devices still on the
  source, used to track progress and scope assignments.

## What you control
- The parity target (which Workspace ONE Windows settings are recreated in Intune).
- The compliance bar carried over to Intune.
- The Conditional Access policy that keeps access continuous through cutover.
- Ring membership and the order/pace of the cutover.

## Vendor boundary (read this)
Workspace ONE internals — how to unenroll a Windows device, retire/wipe behavior, the Workspace ONE
UEM console navigation, and any Workspace ONE Intelligent Hub steps — are owned by VMware and are
deferred to the official VMware Workspace ONE documentation. This solution gives exact navigation for
the Intune and Entra side and flags each point where a Workspace ONE action is required.

## Limitations (be honest with buyers)
- Parity is a *recreation*, not an export/import — Workspace ONE profiles do not convert to Intune
  profiles; you rebuild the equivalent settings in Intune.
- A device cannot be Intune-enrolled while Workspace ONE still holds MDM authority; the unenroll step
  is a hard prerequisite for each device.
- User-driven steps (sign-in, restart) may be required during cutover depending on your join method;
  plan communications accordingly.

## The deployment model
> `Build parity + compliance + Conditional Access continuity → group into rings → unenroll from
> Workspace ONE + enroll to Intune by ring → validate each device → expand.` Standard model:
> `Assess → Configure → Pilot → Validate → Expand.`


---


# 2. Requirements Guide — Workspace ONE to Intune (Windows Device Migration)

Verify **every** requirement before configuring. Each entry: `Description · Why · Verify ·
Implement-if-missing`. Category-wide prerequisites (Entra tenant, Intune licensing, source access,
inventory, enrollment prerequisites, pilot/wave structure, change control) are in
`global-requirements-migrations.md` — confirm those first; the requirements below are specific to the
Workspace ONE to Intune Windows device migration.

## 2.1 Windows automatic enrollment (MDM user scope)
**Description:** Intune Windows automatic enrollment is enabled so an Entra-joining Windows device
enrolls into Intune without manual MDM setup.
**Why:** Migrated devices must enroll into Intune the moment they join Entra; without automatic
enrollment each device needs manual enrollment, which does not scale and leaves gaps.
**Verify:** Intune admin center → `Devices > Windows > Windows enrollment > Automatic enrollment`;
confirm MDM user scope is `All` (or the migration users' group). Run `WS1WIN-Validation.ps1` on a
test device to confirm it enrolls after join.
**Implement:** In `Automatic enrollment`, set MDM user scope to `All` (or scope it to the migration
group) and save. MAM user scope can stay `None` for device migration.

## 2.2 Source MDM removed before Intune enrollment (no dual management)
**Description:** Each in-scope Windows device is fully unenrolled from Workspace ONE before (or as part
of) its Intune enrollment, so only one MDM authority exists.
**Why:** Windows allows one MDM enrollment; a device still held by Workspace ONE cannot cleanly enroll
in Intune, and a device in both is dual-managed with conflicting policy.
**Verify:** Run `WS1WIN-Discovery.ps1` — it reports the device's current MDM enrollment(s) and flags a
Workspace ONE provider or a second enrollment alongside Intune.
**Implement:** Unenroll from Workspace ONE per the official VMware Workspace ONE documentation (the
unenroll/retire action is a VMware-owned step). For devices left in a dual or failed state, run
`WS1WIN-Remediation.ps1` (defaults to `-WhatIf`).

## 2.3 Parity target defined from the Workspace ONE baseline
**Description:** A documented list of the Workspace ONE Windows settings in scope (security baseline,
configuration profiles, certificates, Wi-Fi/VPN, restrictions) that must be recreated in Intune.
**Why:** Parity is a recreation in Intune — you cannot validate parity without first knowing exactly
what the source enforced.
**Verify:** You can produce the Workspace ONE Windows configuration export/inventory for the scope
(see global G3/G4). The parity list is written and reviewed.
**Implement:** Inventory the source configuration per VMware documentation, then map each setting to its
Intune equivalent in `Parity Configuration – Windows – Migration` (built in the Implementation Guide).

## 2.4 Intune configuration profile(s) for parity
**Description:** The Intune configuration that recreates the source Windows settings — named
`Parity Configuration – Windows – Migration`.
**Why:** A migrated device must land the same settings it had under Workspace ONE, or users lose
function and security drops.
**Verify:** Intune → `Devices > Windows > Configuration`; the `Parity Configuration – Windows –
Migration` profile(s) exist and are assigned to `Group – Migration Pilot – Windows` and
`Group – Migration Broad – Windows`. Run `WS1WIN-Validation.ps1` on a migrated device to confirm the
profile reports as applied.
**Implement:** Build the profile(s) in the Implementation Guide (Step 3) from the parity target in 2.3.

## 2.5 Intune compliance policy for parity
**Description:** An Intune Windows compliance policy mirroring the source compliance bar — named
`Compliance Policy – Windows – Migration`.
**Why:** Conditional Access continuity depends on Intune compliance; without it, migrated devices are
"not evaluated" and may be blocked.
**Verify:** Intune → `Devices > Compliance`; `Compliance Policy – Windows – Migration` exists and is
assigned to both migration groups. `WS1WIN-Report.ps1` shows migrated devices as compliant.
**Implement:** Build the compliance policy in the Implementation Guide (Step 4).

## 2.6 Conditional Access continuity
**Description:** A Conditional Access policy — `Conditional Access Continuity – Windows – Migration` —
that grants access only to a compliant, Entra-joined Windows device, independent of Workspace ONE.
**Why:** If access ever depends on the Workspace ONE state, removing the source MDM breaks sign-in.
Tying access to Entra + Intune compliance makes cutover safe.
**Verify:** Entra → `Protection > Conditional Access`; the policy exists, targets the migration users,
and requires device compliance. Confirm a migrated, compliant device can sign in.
**Implement:** Build/confirm the policy in the Implementation Guide (Step 5); start in report-only and
move to On after pilot validation.

## 2.7 Migration groups
**Description:** Two Entra security groups — `Group – Migration Pilot – Windows` and
`Group – Migration Broad – Windows` — plus an inventory/exclusion group `Group – Workspace ONE Managed
– Windows`.
**Why:** Rings target groups; the inventory group tracks what is still on the source and scopes
assignments cleanly.
**Verify:** Entra → `Groups`; the three groups exist with the expected members. Run
`WS1WIN-Set-MigrationRingTargeting.ps1` (defaults to `-WhatIf`) to preview membership.
**Implement:** Create the groups in the Implementation Guide (Step 2) / with
`WS1WIN-Set-MigrationRingTargeting.ps1`.

## 2.8 Supported Windows build and Entra join method
**Description:** In-scope devices run a supported Windows 10/11 build and can join Entra ID (Entra join,
or Hybrid Entra join if you keep on-prem AD).
**Why:** Automatic enrollment and modern compliance require a supported build and a working Entra join.
**Verify:** `winver`; run `WS1WIN-Discovery.ps1` (reports OS build and current join state).
**Implement:** Patch/upgrade to a supported build; configure Entra join (or Hybrid join) per your
identity model before cutover.

---
## Checklist
- [ ] Global Migrations requirements confirmed (`global-requirements-migrations.md`)
- [ ] Windows automatic enrollment enabled — `WS1WIN-Validation.ps1`
- [ ] Source MDM removal path confirmed; no dual management — `WS1WIN-Discovery.ps1`
- [ ] Parity target documented from the Workspace ONE baseline
- [ ] `Parity Configuration – Windows – Migration` built and assigned
- [ ] `Compliance Policy – Windows – Migration` built and assigned
- [ ] `Conditional Access Continuity – Windows – Migration` in place
- [ ] `Group – Migration Pilot – Windows` / `Group – Migration Broad – Windows` / `Group – Workspace ONE Managed – Windows` created
- [ ] Supported Windows build and Entra join method confirmed — `WS1WIN-Discovery.ps1`


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


# 3. Implementation Guide — Workspace ONE to Intune (Windows Device Migration)

Follow these steps **in order**. Intune steps are in the Microsoft Intune admin center
(`https://intune.microsoft.com`); identity and Conditional Access steps are in the Microsoft Entra
admin center (`https://entra.microsoft.com`). Workspace ONE actions are flagged and deferred to the
official VMware Workspace ONE documentation.

> **Model:** Build the target (parity + compliance + Conditional Access continuity) first, group
> devices into rings, then cut over ring by ring — unenroll from Workspace ONE, enroll to Intune,
> validate — pilot before broad. Deployment model: `Assess → Configure → Pilot → Validate → Expand`.

## Step 1 — Confirm identity and enrollment (Assess)
1. Entra → `Identity > Overview` — confirm the target tenant (global G1).
2. Intune → `Devices > Windows > Windows enrollment > Automatic enrollment` — confirm MDM user scope is
   `All` or the migration users' group (requirement 2.1).
3. Confirm each in-scope device's join method (Entra join or Hybrid Entra join) is working and the OS
   build is supported — run `WS1WIN-Discovery.ps1` against the scope.
4. Confirm you have the Workspace ONE Windows configuration inventory (global G3/G4) and a written
   parity target (requirement 2.3).

## Step 2 — Create the migration groups
1. Entra → `Groups > New group` → Type `Security` → Name `Group – Migration Pilot – Windows` (a few
   representative devices/users). `Create`.
2. Repeat for `Group – Migration Broad – Windows` (the rest of the fleet).
3. Repeat for `Group – Workspace ONE Managed – Windows` (the inventory/exclusion group of devices still
   on the source).
4. You can preview/seed membership with `WS1WIN-Set-MigrationRingTargeting.ps1` (defaults to `-WhatIf`).

## Step 3 — Build the parity configuration in Intune
1. Intune → `Devices > Windows > Configuration > Create > New policy`.
2. Platform `Windows 10 and later`; profile type `Settings catalog` (or the template that matches each
   source setting). `Create`.
3. Name `Parity Configuration – Windows – Migration`. `Next`.
4. Add the settings that recreate the Workspace ONE Windows baseline from your parity target
   (requirement 2.3) — for example encryption/BitLocker, firewall, restrictions, Wi-Fi/VPN, and
   certificates. Build additional profiles under the same name with a suffix
   (`Parity Configuration – Windows – Migration (Wi-Fi)`) if one profile type cannot hold them all.
5. `Next > Assignments > Add groups` → add `Group – Migration Pilot – Windows` **and**
   `Group – Migration Broad – Windows`. `Next > Create`.

> Why assign both groups now: policy is then waiting for each device the instant it enrolls, so a
> migrated device lands parity immediately rather than sitting unconfigured.

## Step 4 — Build the compliance policy in Intune
1. Intune → `Devices > Compliance > Create policy`. Platform `Windows 10 and later`. `Create`.
2. Name `Compliance Policy – Windows – Migration`. `Next`.
3. Set the compliance rules to mirror the source bar (e.g. BitLocker required, firewall on, minimum OS
   version, Defender). `Next`.
4. `Actions for noncompliance` — keep the default `Mark device noncompliant` immediately for the pilot
   so you see real status; add a user email if desired. `Next`.
5. `Assignments > Add groups` → `Group – Migration Pilot – Windows` and
   `Group – Migration Broad – Windows`. `Next > Create`.

## Step 5 — Establish Conditional Access continuity
1. Entra → `Protection > Conditional Access > Policies > New policy`.
2. Name `Conditional Access Continuity – Windows – Migration`.
3. `Users` → the migration users (or a group containing them).
4. `Target resources` → the corporate apps/resources users must keep reaching.
5. `Conditions > Device platforms` → include `Windows`.
6. `Grant` → `Grant access` → check `Require device to be marked as compliant`.
7. `Enable policy` → start in `Report-only`. `Create`.
8. After the pilot validates (Step 8), switch the policy to `On`.

> This makes access depend on Entra + Intune compliance, not on Workspace ONE — so unenrolling the
> source MDM never breaks sign-in.

## Step 6 — Pilot cutover: unenroll from Workspace ONE
1. For each device in `Group – Migration Pilot – Windows`, unenroll the device from Workspace ONE.
   **This is a VMware-owned action** — perform the unenroll/retire per the official VMware Workspace
   ONE documentation; do not improvise the source-side steps.
2. After unenroll, confirm the device no longer reports a Workspace ONE MDM enrollment — run
   `WS1WIN-Discovery.ps1` (it flags a remaining Workspace ONE provider or a dual enrollment).

## Step 7 — Pilot cutover: join Entra and enroll to Intune
1. Ensure the device is Entra-joined (or Hybrid Entra-joined per your model). For a user-driven Entra
   join: `Settings > Accounts > Access work or school > Connect > Join this device to Microsoft Entra
   ID`, then sign in and restart if prompted.
2. With automatic enrollment enabled (Step 1), the device enrolls into Intune on join. Confirm in
   Intune → `Devices > Windows > Windows devices` that the device appears as managed by Intune.
3. Trigger a sync if needed: `Settings > Accounts > Access work or school > (account) > Info > Sync`.
4. Run `WS1WIN-Validation.ps1` on the device to confirm: single MDM authority (Intune), parity profile
   applied, compliance evaluated.

## Step 8 — Validate the pilot (pilot-ring gate)
1. Run `WS1WIN-Validation.ps1` per migrated pilot device → confirms single-MDM, parity applied,
   compliant.
2. Run `WS1WIN-Report.ps1` → fleet view of migration status, MDM authority, and compliance from
   Microsoft Graph.
3. Confirm a migrated, compliant pilot device can sign in to the Conditional Access target resources.
4. Complete the Testing Guide. **Do not proceed to the broad ring until every pilot device passes the
   gate** (single-MDM, parity applied, compliant, access working). If a device is stuck dual- or
   un-managed, run `WS1WIN-Remediation.ps1` (defaults to `-WhatIf`; review, then re-run with
   `-WhatIf:$false`).

> **Rollback note:** if the pilot fails, the documented rollback (global G7) is to re-enroll the
> affected devices into Workspace ONE per VMware documentation and revert the Conditional Access policy
> to `Report-only`. The parity and compliance objects can stay in place; they affect only migrated
> devices.

## Step 9 — Turn Conditional Access continuity On
1. Once the pilot passes, Entra → `Conditional Access` → open
   `Conditional Access Continuity – Windows – Migration` → set `Enable policy` to `On` → `Save`.

## Step 10 — Expand to the broad ring
1. Move devices from `Group – Workspace ONE Managed – Windows` into `Group – Migration Broad – Windows`
   in waves (use `WS1WIN-Set-MigrationRingTargeting.ps1`, `-WhatIf` first).
2. For each wave, repeat Steps 6–8: unenroll from Workspace ONE (VMware), Entra join + Intune enroll,
   validate. Parity, compliance, and Conditional Access are already assigned, so each device lands
   configured and protected.
3. Re-run `WS1WIN-Report.ps1` each wave to confirm progress and catch laggards; remediate dual/failed
   devices with `WS1WIN-Remediation.ps1`.
4. When `Group – Workspace ONE Managed – Windows` is empty, the migration is complete; decommission the
   source per global G7.

---
### Order of operations
`Confirm identity/enrollment → create groups → build parity config → build compliance → Conditional
Access continuity → pilot unenroll (VMware) → pilot Entra join + Intune enroll → validate pilot (gate)
→ CA On → expand broad by wave → validate → decommission source`


---


# 5. Testing Guide — Workspace ONE to Intune (Windows Device Migration)

Run after the pilot ring cuts over (Implementation Step 8) and again for each broad wave. The goal of
every test is to prove the device is managed by **only** Intune, has **parity**, is **compliant**, and
keeps **access**.

## Test 1 — Source MDM removed (no Workspace ONE)
**Do:** On a migrated device run `WS1WIN-Discovery.ps1`; in Intune check
`Devices > Windows > Windows devices` for the device.
**Expected:** No Workspace ONE MDM enrollment remains; the device shows a single MDM authority.

## Test 2 — Enrolled in Intune (single authority)
**Do:** Run `WS1WIN-Validation.ps1` on the device.
**Expected:** Exactly one MDM enrollment, and it is Intune; no dual-enrollment warning.

## Test 3 — Parity configuration applied
**Do:** Intune → `Devices > Windows > Configuration` → `Parity Configuration – Windows – Migration` →
`Device status`; and run `WS1WIN-Validation.ps1`.
**Expected:** The device reports the parity profile(s) as `Succeeded`/applied; key settings match the
Workspace ONE baseline.

## Test 4 — Compliance green
**Do:** Intune → `Devices > Compliance > Compliance Policy – Windows – Migration > Device status`; and
run `WS1WIN-Report.ps1`.
**Expected:** The migrated device is `Compliant` (not `Not evaluated` / `Not compliant`).

## Test 5 — Conditional Access continuity (access works)
**Do:** From the migrated, compliant device sign in to a Conditional Access target resource.
**Expected:** Access is granted; `Conditional Access Continuity – Windows – Migration` shows the device
satisfied the `compliant device` grant. The Entra sign-in log confirms the policy applied.

## Test 6 — No dual management across the ring
**Do:** Run `WS1WIN-Report.ps1` for the whole ring.
**Expected:** No device appears with both a Workspace ONE and an Intune enrollment; none appear
unmanaged.

## Test 7 — Ring targeting correct
**Do:** Run `WS1WIN-Set-MigrationRingTargeting.ps1` with `-WhatIf` and review the report.
**Expected:** Pilot members are in `Group – Migration Pilot – Windows`; broad members in
`Group – Migration Broad – Windows`; un-migrated devices remain in `Group – Workspace ONE Managed –
Windows`.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass (gate before broad)** | Tests 1–5 pass for **every** device in `Migration Ring – Pilot – Windows`; no device dual- or un-managed (Test 6) |
| **Broad wave pass** | Tests 1–4 and 6 pass for the wave before the next wave begins; access (Test 5) spot-checked |
| **Migration complete** | `Group – Workspace ONE Managed – Windows` empty; all devices single-MDM (Intune), parity applied, compliant |


---


# 6. Troubleshooting Guide — Workspace ONE to Intune (Windows Device Migration)

Use `WS1WIN-Discovery.ps1` / `WS1WIN-Validation.ps1` for device state, `WS1WIN-Report.ps1` for fleet
status, and `WS1WIN-Remediation.ps1` (defaults to `-WhatIf`) for safe fixes to dual/failed enrollment.
Workspace ONE-side actions (unenroll/retire) are deferred to the official VMware Workspace ONE
documentation.

## A. Dual management (managed by both)
| Symptom | Cause | Remediation |
|---|---|---|
| Device shows both a Workspace ONE and an Intune enrollment | Enrolled in Intune before Workspace ONE was fully removed | Unenroll from Workspace ONE per VMware docs, then run `WS1WIN-Remediation.ps1` to clear the stale enrollment and resync; confirm with `WS1WIN-Discovery.ps1` |
| Conflicting/flapping policy on the device | Two MDM authorities | Resolve to single MDM (Intune) as above; re-validate parity with `WS1WIN-Validation.ps1` |

## B. Device left unmanaged
| Symptom | Cause | Remediation |
|---|---|---|
| Removed from Workspace ONE but never appears in Intune | Automatic enrollment off, or device not Entra-joined | Confirm `Devices > Windows > Windows enrollment > Automatic enrollment` MDM user scope; ensure Entra join; trigger enroll/sync; run `WS1WIN-Remediation.ps1` |
| Device enrolled but no policy | Not a member of a migration group | Add to `Group – Migration Pilot – Windows` / `Group – Migration Broad – Windows` (use `WS1WIN-Set-MigrationRingTargeting.ps1`); sync |

## C. Parity not applied
| Symptom | Cause | Remediation |
|---|---|---|
| Migrated device missing settings it had under Workspace ONE | `Parity Configuration – Windows – Migration` not assigned to the device's group, or a setting was not recreated | Confirm assignment to both migration groups; check the parity target covers the setting; sync and re-run `WS1WIN-Validation.ps1` |
| Profile shows `Error`/`Conflict` in Intune | Conflicting profile or unsupported setting | Open `Configuration > Parity Configuration – Windows – Migration > Device status`; resolve the conflicting policy; re-sync |

## D. Compliance stuck
| Symptom | Cause | Remediation |
|---|---|---|
| Device `Not evaluated` | Compliance policy not assigned, or device just enrolled | Confirm `Compliance Policy – Windows – Migration` assignment; allow a policy cycle; sync; re-check `WS1WIN-Report.ps1` |
| Device `Not compliant` | A compliance rule is failing (e.g. BitLocker, firewall) | Identify the failing rule in `Compliance > … > Device status`; remediate the setting via the parity profile; re-evaluate |

## E. Access broken after cutover
- Confirm the user/device is in scope of `Conditional Access Continuity – Windows – Migration` and the
  device is `Compliant` — a non-compliant device will be blocked by the `require compliant device`
  grant. Check the Entra sign-in log for the policy result.
- If you switched the policy to `On` before the device was compliant, return it to `Report-only`,
  bring the device compliant, then re-enable.

## F. Enrollment fails on a specific device
- Run `WS1WIN-Discovery.ps1` — confirm the source MDM is gone, the OS build is supported, and Entra
  join succeeded. A leftover Workspace ONE enrollment is the most common blocker; remove it per VMware
  docs first.

## G. Diagnostics quick reference
```powershell
dsregcmd /status                # Entra join + MDM enrollment state
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -Recurse -EA SilentlyContinue   # enrollment(s)
Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -EA SilentlyContinue  # MDM sync tasks
```

## H. When to escalate
- For Workspace ONE unenroll/retire behavior that will not complete, escalate to VMware Workspace ONE
  support per their documentation — those internals are outside this solution's scope.
- For Intune enrollment that still fails after the source MDM is confirmed gone, the build is
  supported, Entra join succeeded, and a sync has run, collect `dsregcmd /status` output and open a
  Microsoft support case.


---


# 7. Best Practices — Workspace ONE to Intune (Windows Device Migration)

- **Build the target before you move a device.** Have `Parity Configuration – Windows – Migration`,
  `Compliance Policy – Windows – Migration`, and `Conditional Access Continuity – Windows – Migration`
  in place and assigned to both rings *first*, so every device lands configured, compliant, and able to
  sign in the moment it enrolls.
- **Never dual-manage.** A Windows device has one MDM authority — unenroll from Workspace ONE (per
  VMware documentation) before, or as part of, Intune enrollment. Run `WS1WIN-Discovery.ps1` to catch
  any device still held by the source.
- **Make access depend on Entra + Intune, not Workspace ONE.** Tying Conditional Access to a compliant,
  Entra-joined device means removing the old MDM never breaks sign-in.
- **Always pilot, always ring.** Move `Migration Ring – Pilot – Windows` first and hold the gate; only
  expand to `Migration Ring – Broad – Windows` after every pilot device passes. This catches a parity
  or compliance gap on a handful of devices instead of the fleet.
- **Hold the pilot-ring gate honestly.** Single-MDM, parity applied, compliant, access working — all
  four, every pilot device. A partial pass is a fail.
- **Keep a written rollback.** Re-enroll to Workspace ONE (VMware) and revert Conditional Access to
  report-only is the documented fallback; confirm it before cutover (global G7).
- **Validate per device, not per ring.** Run `WS1WIN-Validation.ps1` on each migrated device; a ring
  is only as migrated as its worst device.
- **Track what is left.** Keep `Group – Workspace ONE Managed – Windows` accurate; the migration is
  done when it is empty. Use `WS1WIN-Report.ps1` each wave to chase laggards.
- **Recreate, don't expect to import.** Workspace ONE profiles do not convert to Intune — map each
  source setting to its Intune equivalent in the parity target and verify with
  `WS1WIN-Validation.ps1`.
- **Communicate cutover to users.** A short note about the sign-in/restart and what "managed by your
  organization" means dramatically reduces tickets.
- **Reuse the names verbatim.** The same artifact names across config, compliance, Conditional Access,
  groups, and scripts make the process auditable and repeatable for the next wave and the next estate.


---


# 8. Deliverables Summary — Workspace ONE to Intune (Windows Device Migration)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The migration model, the *why* (no dual/un-managed, parity, access continuity), named artifacts, vendor boundary, limitations |
| 2. Requirements Guide | Every prerequisite with `Verify` / `Implement-if-missing` |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Entra + Intune steps; Workspace ONE actions flagged to VMware docs |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WS1WIN-Discovery.ps1` | Read-only. Reports OS build, Entra/join state, and current MDM enrollment(s); flags a Workspace ONE provider or dual enrollment |
| `WS1WIN-Validation.ps1` | Read-only. Per-device check: single MDM (Intune), parity profile applied, compliance evaluated |
| `WS1WIN-Report.ps1` | Read-only. Fleet migration status, MDM authority, and compliance via Microsoft Graph |
| `WS1WIN-Remediation.ps1` | Safe remediation (defaults to `-WhatIf`) of dual/failed enrollment — forces MDM sync and resolves a stuck enrollment state |
| `WS1WIN-Set-MigrationRingTargeting.ps1` | Builds/updates the migration-ring Entra groups and previews membership (defaults to `-WhatIf`) |

## Named artifacts (created during implementation, reused verbatim)
| Artifact | Scope · Stage |
|---|---|
| `Parity Configuration – Windows – Migration` | Intune configuration profile(s) — Windows — Migration |
| `Compliance Policy – Windows – Migration` | Intune compliance policy — Windows — Migration |
| `Conditional Access Continuity – Windows – Migration` | Entra Conditional Access policy — Windows — Migration |
| `Migration Ring – Pilot – Windows` / `Migration Ring – Broad – Windows` | Cutover waves |
| `Group – Migration Pilot – Windows` / `Group – Migration Broad – Windows` / `Group – Workspace ONE Managed – Windows` | Entra security groups |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: `Assess → Configure → Pilot → Validate → Expand`.

## Outcome
Windows devices moved from Workspace ONE to Intune — re-enrolled with full configuration and
compliance parity, access uninterrupted, none left dual- or un-managed — proven on a pilot ring before
you scale.
