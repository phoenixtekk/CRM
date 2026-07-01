# Windows Firewall GPO to Intune Migration

> **Version 1.0.0** · Category: Migrations · Solution code: FWMIG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Windows Firewall GPO to Intune Migration

**Phoenixtekk Workplace Marketplace · Migrations**

Moving Windows Defender Firewall from Group Policy to Microsoft Intune is a known minefield. Do it
before the foundation is ready and you get policy conflicts or merge/loop conditions that leave
devices in an unpredictable state — the firewall is on, but nobody is sure which rules are actually
enforced. Because the firewall governs connectivity, a botched cutover does not just misconfigure a
setting; it can cut a fleet off from line-of-business apps, remote management, or each other.

This is a complete, deploy-it-today package for the controlled migration of Windows Defender
Firewall from GPO to Intune endpoint-security firewall policy, written for an administrator with no
prior migration experience. It does not re-teach net-new firewall design — it is the disciplined
GPO-to-Intune move: inventory the GPO firewall rules, translate them into Intune firewall policy and
firewall rule profiles, manage GPO/Intune coexistence so the two never fight, cut over in rings with
parity validation, and only then retire the GPO firewall settings.

## What you get
- A plain-language Solution Overview of the migration model, GPO-to-Intune rule mapping, and the
  conflict/merge/loop dynamics this migration is built to avoid.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered Intune steps: inventory, translate, configure
  coexistence, assign in rings, validate parity, retire GPO, expand.
- Five PowerShell scripts for firewall-rule discovery, post-migration rule-parity validation, a
  coverage and conflict report, safe conflict remediation, and a migration-ring group builder.
- Testing and Troubleshooting guides with explicit pass/fail gates and conflict/loop diagnosis.

## What this delivers
A ringed firewall migration — `Migration Ring – Pilot`, `Migration Ring – Wave 1`, and
`Migration Ring – Broad` — in which GPO firewall rules are translated into a named Intune
`Firewall Policy – Migrated Rules – Pilot` and matching `Firewall Rules` profiles, GPO and Intune
coexist without conflict during transition, rule parity is validated on every ring before the next,
and the GPO firewall settings are retired only after parity holds.

## The Phoenixtekk deployment model
Assess → Configure → Pilot → Validate → Expand — with a parity gate and a rollback path at every
ring, because the firewall affects connectivity.

## Outcome
Windows Defender Firewall moved from GPO to Intune — rules translated, conflicts and loops avoided
through managed coexistence, cut over in rings with parity validated, and the legacy GPO firewall
settings cleanly retired — proven on a pilot before you scale.


---


# 1. Solution Overview — Windows Firewall GPO to Intune Migration

## What this migration is
This solution moves Windows Defender Firewall management from Active Directory Group Policy (GPO) to
Microsoft Intune endpoint-security firewall policy. It is not net-new firewall design — it assumes
you already have working firewall rules in GPO and need to relocate that enforcement to Intune
without breaking connectivity. The deliverable is a controlled, ringed cutover: inventory what GPO
enforces, translate it into Intune firewall objects, run both side by side without conflict during
transition, validate rule parity, then retire the GPO firewall settings.

## Why move firewall management to Intune
- Cloud-managed, internet-facing devices do not reliably receive GPO; a domain-joined-only firewall
  policy leaves remote and Entra-joined devices unmanaged or inconsistently managed.
- Intune gives a single endpoint-security surface (`Endpoint security` → `Firewall`) with assignment
  by Entra group, per-device reporting, and no dependency on line-of-sight to a domain controller.
- Co-management and modern provisioning (Autopilot, Entra join) expect endpoint security to live in
  Intune, not GPO.

## Why this migration is risky (the *why* behind the discipline)
Group Policy and Intune can both write Windows Defender Firewall settings to the same device. When
both are active and unmanaged, three failure modes appear:
- Conflict — GPO and Intune set the same firewall setting to different values; the device's effective
  state becomes ambiguous and can flip between policy refreshes.
- Merge condition — local, GPO, and Intune (MDM) rules all merge into the effective rule set. If you
  do not control rule merging, you get unexpected union behavior: rules you thought you removed are
  still enforced from another source.
- Merge loop — GPO re-asserts a firewall setting on its refresh cycle while Intune re-asserts a
  conflicting value on its check-in; the device oscillates and never settles, and reporting shows
  intermittent compliance. This is the pain point this solution is built to avoid.

Because the firewall governs connectivity, an unmanaged conflict does not fail safe — it can block
inbound management, RDP/Remote Help, or LOB traffic. That is why the migration is staged
(inventory → translate → coexist → ring → validate → retire) rather than a flip of a switch.

## How GPO firewall rules map to Intune
| GPO firewall concept | Intune endpoint-security equivalent |
|---|---|
| Firewall profile state (Domain/Private/Public on, default inbound/outbound action, stealth, logging) | A `Firewall Policy` (profile `Windows Firewall`) — one policy enabling the three profiles with the same defaults |
| Individual inbound/outbound allow/block rules | `Firewall Rules` profile entries (one rule each: name, direction, action, protocol/ports, program, address scope) |
| GPO scoping by OU / security group | Intune assignment to an Entra security group (the migration ring) |
| GPO refresh / gpupdate | Intune device check-in / sync |

A single GPO firewall section typically becomes one `Firewall Policy` (the profile defaults) plus one
or more `Firewall Rules` profiles (the explicit rules), assigned to the same ring group.

## The coexistence model (how conflicts/loops are avoided)
During transition, every in-scope device is targeted by GPO and Intune at once. The migration
controls this so they never fight:
1. Translate first, assign nothing — build the Intune objects but do not assign them until the device
   is ready to leave GPO.
2. Move a device out of GPO firewall scope at the same moment it enters the Intune ring — one
   authority per device, never two enforcing the same firewall settings.
3. Control rule merging explicitly in the Intune policy so local/GPO leftovers cannot silently
   re-merge.
4. Validate parity (the Intune effective rule set equals the old GPO rule set) before advancing.

## The named artifacts this solution creates
All objects follow `<Purpose> – <Scope> – <Stage>` and are reused verbatim throughout the guides:
- Groups: `FW Migration – Pilot Devices – Stage Pilot`, `FW Migration – Wave 1 Devices – Stage Wave1`,
  `FW Migration – Fleet Devices – Stage Broad`.
- Firewall policy (profile defaults): `Firewall Policy – Migrated Rules – Pilot`,
  `Firewall Policy – Migrated Rules – Broad`.
- Firewall rules profiles: `Firewall Rules – Migrated Inbound – Pilot`,
  `Firewall Rules – Migrated Outbound – Pilot` (and the Broad equivalents).
- Migration rings: `Migration Ring – Pilot`, `Migration Ring – Wave 1`, `Migration Ring – Broad`.

## The standard Phoenixtekk deployment model
> Assess (inventory GPO firewall rules) → Configure (translate to Intune policy + rules,
> set coexistence) → Pilot (`Migration Ring – Pilot`) → Validate (rule parity + connectivity) →
> Expand (waves, then retire GPO). Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Windows Firewall GPO to Intune Migration

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-migrations.md`
(target tenant, Intune licensing/admin, source-platform access, inventory, enrollment, pilot/wave
structure, change control + coexistence + rollback) — confirm those first.

## 2.1 Intune endpoint-security admin access
**Description:** Rights to create and assign `Endpoint security` → `Firewall` policies in Intune.
**Why:** The migration target is an Intune firewall policy and firewall rule profiles; you cannot
build them without these rights.
**Verify:** `https://intune.microsoft.com` → `Endpoint security` → `Firewall` loads and `Create Policy`
is available; you hold **Intune Administrator** or **Endpoint Security Manager**.
**Implement:** Assign the Intune/Endpoint Security admin role (least privilege) to the migrator.

## 2.2 Source GPO firewall rule access and export
**Description:** Read access to the Group Policy Object(s) that configure Windows Defender Firewall
profiles and rules for the in-scope devices.
**Why:** The migration begins by inventorying exactly what GPO enforces so it can be translated.
**Verify:** In Group Policy Management you can open the GPO and see
`Computer Configuration` → `Windows Settings` → `Security Settings` →
`Windows Defender Firewall with Advanced Security`; or run `FWMIG-Discovery.ps1` on a domain-joined
in-scope device (it exports GPO + applied firewall rules, read-only).
**Implement:** Obtain delegated read on the firewall GPO(s) from the AD/GPO owner.

## 2.3 Targeted devices enrolled in Intune
**Description:** In-scope devices enrolled in Intune (co-managed or Intune-managed).
**Why:** A `Firewall Policy` and `Firewall Rules` profiles apply only to enrolled devices.
**Verify:** Intune → `Devices` → `All devices` shows the in-scope devices.
**Implement:** Enable automatic enrollment / co-management; enroll the devices.

## 2.4 Supported Windows OS and MDM firewall CSP
**Description:** Windows 10/11 (Pro/Enterprise/Education) that supports the Firewall configuration
service provider Intune uses.
**Why:** Intune firewall policy and rules require a supported build to apply.
**Verify:** `winver` on a sample device; run `FWMIG-Discovery.ps1` (reports OS build).
**Implement:** Patch/upgrade devices to a supported build before migrating them.

## 2.5 A documented GPO firewall rule inventory (source of truth)
**Description:** An accurate export of the GPO firewall profile defaults and every explicit rule for
the migration scope.
**Why:** Parity validation and GPO retirement depend on knowing exactly what is in scope.
**Verify:** You can produce a rule export (CSV/JSON) from `FWMIG-Discovery.ps1` and
`FWMIG-Report.ps1`.
**Implement:** Run `FWMIG-Discovery.ps1` across a representative device set to build the inventory
before scoping rings.

## 2.6 Coexistence control — one firewall authority per device
**Description:** A defined approach so that, for any device, GPO **or** Intune enforces the firewall —
never both at once on the same settings.
**Why:** Two authorities on the same firewall settings cause conflicts and merge loops (Overview).
**Verify:** For each ring you can both remove devices from GPO firewall scope and add them to the
Intune ring group at the same change step; run `FWMIG-Report.ps1` to flag devices currently double-managed.
**Implement:** Use a security-group-filtered GPO (deny-apply or remove from OU scope) keyed to the
same membership the ring group uses, so moving a device flips authority atomically.

## 2.7 Migration ring groups (pilot + waves)
**Description:** Entra security groups for `Migration Ring – Pilot`, `Migration Ring – Wave 1`, and
`Migration Ring – Broad`.
**Why:** The firewall is cut over in rings with a parity gate between each; connectivity risk demands it.
**Verify:** Entra → `Groups`; the three groups exist (or run `FWMIG-Set-MigrationRingTargeting.ps1`
to create/populate them).
**Implement:** Create the groups (`FWMIG-Set-MigrationRingTargeting.ps1` or Entra →
`Groups` → `New group` → Security).

## 2.8 Change control + rollback (connectivity-aware)
**Description:** A change window and a written rollback (re-scope the device to GPO firewall / unassign
the Intune policy) for each ring, because the firewall affects connectivity.
**Why:** A bad rule translation can block management or LOB traffic; cutover must be reversible.
**Verify:** A rollback procedure is written and approved before any ring cutover.
**Implement:** Define per-ring rollback, comms, and the order coexistence → cutover → retire (see §G7
of the global requirements).

---
## Checklist
- [ ] Intune endpoint-security admin access
- [ ] Source GPO firewall rules readable / exportable — `FWMIG-Discovery.ps1`
- [ ] In-scope devices enrolled in Intune
- [ ] Supported Windows build (firewall CSP) — `FWMIG-Discovery.ps1`
- [ ] GPO firewall rule inventory captured — `FWMIG-Report.ps1`
- [ ] Coexistence control (one authority per device) defined
- [ ] `Migration Ring – Pilot` / `Wave 1` / `Broad` groups created
- [ ] Change control + connectivity-aware rollback approved


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


# 3. Implementation Guide — Windows Firewall GPO to Intune Migration

Follow these steps **in order**. Intune work is in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`); inventory work uses the included scripts on a domain-joined,
in-scope device. Reuse the named artifacts from the Overview verbatim.

> **Model:** Inventory GPO firewall rules → translate to an Intune `Firewall Policy` plus
> `Firewall Rules` profiles → set coexistence so GPO and Intune never enforce the same device at once
> → assign in rings with a parity gate → retire GPO firewall settings → expand.
> **Assess → Configure → Pilot → Validate → Expand.**

## Step 1 — Assess: inventory the GPO firewall rules
1. On a domain-joined in-scope device, run `FWMIG-Discovery.ps1`. It exports the applied
   Windows Defender Firewall profile defaults and every rule (read-only) using the NetSecurity module
   (`Get-NetFirewallProfile`, `Get-NetFirewallRule`) and the GPO-sourced rule store.
2. Run `FWMIG-Report.ps1` to produce the coverage + conflict report — the source-of-truth rule
   inventory you will validate parity against, plus any device already double-managed.
3. Confirm the inventory matches the GPO in Group Policy Management
   (`Computer Configuration` → `Windows Settings` → `Security Settings` →
   `Windows Defender Firewall with Advanced Security`).

## Step 2 — Create the migration ring groups
1. Run `FWMIG-Set-MigrationRingTargeting.ps1` to create/populate
   `Migration Ring – Pilot`, `Migration Ring – Wave 1`, and `Migration Ring – Broad`; or in Entra →
   `Groups` → `New group` → Security create them manually.
2. Put a few representative devices in `Migration Ring – Pilot` (varied locations/roles so connectivity
   edge cases surface early).

## Step 3 — Configure: translate the profile defaults to a Firewall Policy
1. Intune → `Endpoint security` → `Firewall` → `Create Policy`.
2. **Platform:** Windows. **Profile:** `Windows Firewall`. **Create**.
3. **Name:** `Firewall Policy – Migrated Rules – Pilot`. **Next**.
4. On `Configuration settings`, for **Domain**, **Private**, and **Public** profiles, set the values
   read from the GPO inventory (Step 1):
   - `Firewall enabled` = `Allowed`.
   - `Default inbound action` = match the GPO (typically `Block`).
   - `Default outbound action` = match the GPO (typically `Allow`).
   - `Stealth mode`, `Inbound notifications`, `Unicast responses to multicast broadcast`,
     logging path/size and `Log dropped packets` = match the GPO values.
5. Set the rule-merge controls explicitly so leftovers cannot silently re-merge (key to avoiding
   merge conditions): set the policy/local rule-merge settings to the values your coexistence plan
   requires — during transition do not allow uncontrolled merging of local or GPO rules.
6. **Do not assign yet.** Click **Next** through assignments leaving them empty, then **Create**.

## Step 4 — Configure: translate the explicit rules to Firewall Rules profiles
1. `Endpoint security` → `Firewall` → `Create Policy` → Windows → `Windows Firewall Rules`. **Create**.
2. **Name:** `Firewall Rules – Migrated Inbound – Pilot`.
3. For each inbound rule in the inventory, add one rule entry: `Name`, `Direction` = In, `Action`
   (Allow/Block), `Protocol`/`Ports`, `Program`/service, and `Local`/`Remote address` scope —
   mirroring the GPO rule exactly. `FWMIG-Report.ps1` lists each rule's fields to transcribe.
4. **Do not assign yet.** **Create**.
5. Repeat for outbound rules as `Firewall Rules – Migrated Outbound – Pilot` (omit if the GPO has no
   explicit outbound rules).

## Step 5 — Configure coexistence (avoid conflicts and merge loops)
1. Confirm the coexistence control from Requirement 2.6: a device leaves GPO firewall scope at the
   same moment it joins `Migration Ring – Pilot` (group-filtered GPO deny-apply, or OU move keyed to
   the same membership). One authority per device.
2. Run `FWMIG-Report.ps1` and confirm no pilot device is double-managed before assigning.

## Step 6 — Pilot: assign to the first ring
1. Open `Firewall Policy – Migrated Rules – Pilot` → `Assignments` → `Add groups` →
   `Migration Ring – Pilot`. **Save**.
2. Assign `Firewall Rules – Migrated Inbound – Pilot` (and the outbound profile) to
   `Migration Ring – Pilot`.
3. As each device joins the ring, the coexistence control removes it from GPO firewall scope. On a
   pilot device, sync policy (`Settings` → `Accounts` → `Access work or school` → `Info` → `Sync`).

## Step 7 — Validate: rule parity and connectivity (the gate)
1. Run `FWMIG-Validation.ps1` on pilot devices → confirms the **effective** firewall rule set now
   matches the captured GPO inventory (profile defaults + each rule), and that GPO is no longer
   enforcing firewall settings on that device.
2. Run `FWMIG-Report.ps1` → coverage report shows pilot devices fully translated with no conflicts.
3. Verify connectivity: required inbound services (RDP/Remote Help, LOB listeners) and outbound paths
   still work. Complete the **Testing Guide**.
4. **Parity gate:** do not advance until parity passes and connectivity is confirmed on the pilot.
   If it fails, use the rollback (re-scope the device to GPO firewall / unassign the Intune policy).

## Step 8 — Retire the GPO firewall settings (for migrated devices only)
1. Once a device has passed parity in Intune and is out of GPO firewall scope, it no longer needs the
   GPO firewall section — but do not delete the GPO until **all** rings are migrated.
2. Re-run `FWMIG-Report.ps1` to confirm no remaining device depends on the GPO firewall settings,
   then disable/remove the firewall section from the GPO (or unlink it) as the final retirement step.

## Step 9 — Expand: waves, then broad
1. Move to `Migration Ring – Wave 1`: clone the pilot objects as
   `Firewall Policy – Migrated Rules – Broad` / `Firewall Rules – Migrated * – Broad` (or reuse the
   pilot policy by adding the wave group to its assignments), assign, validate parity, retire GPO scope.
2. Repeat for `Migration Ring – Broad` (the rest of the fleet), passing the parity gate each ring.
3. Only after the final ring passes parity, retire the GPO firewall settings (Step 8) fleet-wide.

---
### Order of operations
`Inventory GPO rules → ring groups → translate to Firewall Policy → translate to Firewall Rules → set coexistence → assign Pilot → validate parity → retire GPO scope → expand (waves → Broad) → retire GPO`


---


# 5. Testing Guide — Windows Firewall GPO to Intune Migration

Run after each ring is assigned (Implementation Step 7) and again before retiring any GPO firewall
settings. The firewall affects connectivity, so every ring must pass before the next.

## Test 1 — Intune policy applied
**Do:** Intune → `Endpoint security` → `Firewall` → `Firewall Policy – Migrated Rules – Pilot` →
`Device status`.
**Expected:** Ring devices show **Succeeded** (also for the `Firewall Rules` profiles).

## Test 2 — Profile defaults match the GPO
**Do:** On a ring device run `FWMIG-Validation.ps1`.
**Expected:** Domain/Private/Public enabled state and default inbound/outbound actions equal the
captured GPO inventory values.

## Test 3 — Rule parity (effective rule set equals the GPO inventory)
**Do:** Run `FWMIG-Validation.ps1` (compares the effective `Get-NetFirewallRule` set against the
captured GPO rule inventory).
**Expected:** Every migrated rule is present with matching direction, action, protocol/ports, program,
and address scope; no expected rule missing, no stray rule.

## Test 4 — Single authority (no double management)
**Do:** Run `FWMIG-Report.ps1` for the ring; on a device check the rule source via
`FWMIG-Validation.ps1`.
**Expected:** Firewall settings come from Intune (MDM) only; the device is out of GPO firewall scope —
no conflict, no merge loop, stable compliance across two check-ins.

## Test 5 — Connectivity preserved
**Do:** Exercise required inbound services (e.g. RDP/Remote Help, a LOB listener) and outbound paths
from a ring device.
**Expected:** All traffic that worked under GPO still works under Intune; nothing newly blocked.

## Test 6 — No merge-loop oscillation
**Do:** Re-run `FWMIG-Validation.ps1` after two device check-ins / a `gpupdate /force` on a migrated
device.
**Expected:** Effective firewall state is identical both times — no flipping values, no reintroduced
GPO rules.

## Test 7 — Coverage report
**Do:** Run `FWMIG-Report.ps1` for the ring.
**Expected:** A clear per-device coverage and conflict report — devices translated, parity status, and
zero conflicts before the gate.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Ring parity pass** | Tests 1–4 and 6 pass; effective Intune rule set equals the GPO inventory with one authority |
| **Connectivity pass** | Test 5 passes — no required service newly blocked |
| **Retire-GPO pass** | Test 7 shows no device depends on the GPO firewall settings (all rings migrated) |


---


# 6. Troubleshooting Guide — Windows Firewall GPO to Intune Migration

Use `FWMIG-Discovery.ps1` and `FWMIG-Validation.ps1` for per-device state, `FWMIG-Report.ps1` for
fleet coverage/conflicts, and `FWMIG-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. Conflict — GPO and Intune disagree on a setting
| Symptom | Cause | Remediation |
|---|---|---|
| Effective default inbound/outbound action differs from the Intune policy | The device is still in GPO firewall scope while the Intune policy is assigned (two authorities) | Run `FWMIG-Report.ps1` (flags double-managed); remove the device from GPO firewall scope so only Intune enforces; re-sync |
| Intune policy shows Succeeded but the device behaves differently | GPO refresh re-asserts the old value after Intune applies | Confirm the coexistence control moved the device out of GPO scope at ring entry; `FWMIG-Remediation.ps1` to confirm/fix authority |

## B. Merge condition — unexpected rules still enforced
| Symptom | Cause | Remediation |
|---|---|---|
| A rule you "removed" is still active | Local/GPO rules are merging into the effective set | Set the rule-merge controls in `Firewall Policy – Migrated Rules – *` to disallow uncontrolled local/GPO merging; re-validate with `FWMIG-Validation.ps1` |
| Effective rule set is a superset of the Intune rules | Multiple rule sources merged | Identify the extra rules' source with `FWMIG-Validation.ps1` (reports rule origin); remove the stray source |

## C. Merge loop — oscillating / intermittent compliance
| Symptom | Cause | Remediation |
|---|---|---|
| Compliance flips between check-ins; effective firewall state changes each cycle | GPO re-asserts on its refresh while Intune re-asserts on check-in — the two are fighting | This is the classic loop: ensure exactly one authority per device. Use `FWMIG-Report.ps1` to find double-managed devices, remove them from GPO firewall scope, then `FWMIG-Validation.ps1` over two check-ins / a `gpupdate /force` to confirm the state is now stable |
| `FWMIG-Validation.ps1` returns different results on consecutive runs | Same as above | Do not advance the ring until the state is stable; fix coexistence first |

## D. Parity failure — Intune rule set != GPO inventory
| Symptom | Cause | Remediation |
|---|---|---|
| A migrated rule is missing | Rule not transcribed into the `Firewall Rules` profile | Add the missing rule from the `FWMIG-Report.ps1` inventory; re-validate |
| A rule's behavior differs | Field mistranslated (protocol/ports/program/address scope) | Compare the `FWMIG-Validation.ps1` diff to the inventory; correct the rule field |

## E. Connectivity broken after cutover
- A required inbound service (RDP/Remote Help, LOB listener) or outbound path stopped working →
  the corresponding allow rule was not translated or was mistranslated. Find it in the
  `FWMIG-Report.ps1` inventory, add/fix the rule in the `Firewall Rules` profile, re-validate. If it
  is blocking management, use the ring rollback (re-scope to GPO firewall / unassign Intune) and fix
  before re-attempting.

## F. Policy not applying at all
- Device not enrolled / not in the ring group → confirm enrollment (Intune → `Devices`) and
  membership of `Migration Ring – Pilot` (or current ring); sync.
- Unsupported build → `FWMIG-Discovery.ps1` reports the OS build; patch/upgrade.

## G. Diagnostics quick reference
```powershell
Get-NetFirewallProfile | Select Name, Enabled, DefaultInboundAction, DefaultOutboundAction
Get-NetFirewallRule -PolicyStore ActiveStore | Select DisplayName, Direction, Action, Enabled
Get-NetFirewallRule -PolicyStore ActiveStore | Get-NetFirewallRule  # inspect effective (merged) store
gpresult /h gpo-firewall.html   # confirm whether the firewall GPO still applies to the device
gpupdate /force                 # force a GPO refresh to test for oscillation
```
Effective rules live in the `ActiveStore`; GPO-sourced rules in the `RSOP`/GPO store — comparing the
two shows whether GPO is still contributing.

## H. When to escalate
If exactly one authority enforces the firewall (no double management), rule parity passes, and the
device is synced, but connectivity still fails or compliance still oscillates, capture
`FWMIG-Validation.ps1` output plus `gpresult /h` and open a Microsoft support case.


---


# 7. Best Practices — Windows Firewall GPO to Intune Migration

- **Inventory before you translate.** Capture the GPO firewall profile defaults and every rule with
  `FWMIG-Discovery.ps1` / `FWMIG-Report.ps1` first; that export is your parity source of truth and your
  GPO-retirement checklist.
- **One authority per device, always.** The single most important practice: never let GPO and Intune
  enforce the same firewall settings on the same device at once. Move a device out of GPO firewall
  scope at the same step it enters the Intune ring.
- **Control rule merging explicitly.** Set the merge controls in the Intune `Firewall Policy` so local
  and GPO leftovers cannot silently re-merge — uncontrolled merging is how merge conditions and loops
  start.
- **Ring it; never big-bang the firewall.** `Migration Ring – Pilot` → `Wave 1` → `Broad`, with a
  parity gate between each. The firewall affects connectivity, so a small ring catches a bad
  translation before the fleet feels it.
- **Gate on parity, not on "it deployed."** Advance only when the effective Intune rule set equals the
  captured GPO inventory and connectivity is confirmed — not just when the policy shows Succeeded.
- **Translate faithfully, then improve later.** Migrate rules as-is for parity; defer firewall
  redesign/cleanup to a separate change after the migration is complete, so a connectivity break is
  unambiguously a translation error.
- **Keep a connectivity-aware rollback ready.** For each ring, pre-write how to re-scope the device to
  GPO firewall / unassign the Intune policy, because a wrong rule can block management or LOB traffic.
- **Watch for oscillation.** Re-validate after two check-ins / a `gpupdate /force`; a flipping
  effective state means two authorities are still fighting — fix coexistence before expanding.
- **Retire GPO last.** Disable/unlink the GPO firewall section only after every ring has passed parity
  and `FWMIG-Report.ps1` shows no device depends on it.
- **Name everything consistently.** Use `<Purpose> – <Scope> – <Stage>` for every policy, rules
  profile, ring, and group so the migration state is self-documenting and auditable.


---


# 8. Deliverables Summary — Windows Firewall GPO to Intune Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The migration model, GPO-to-Intune rule mapping, conflict/merge/loop dynamics, coexistence, and the named artifacts |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: inventory, translate, coexist, ring, validate parity, retire GPO, expand |
| 5. Testing Guide | Parity/connectivity validation with pass/fail gates |
| 6. Troubleshooting Guide | Field issues, including conflict/merge/loop diagnosis |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `FWMIG-Discovery.ps1` | Read-only inventory of GPO + applied Windows Defender Firewall profile defaults and rules (NetSecurity module) |
| `FWMIG-Validation.ps1` | Read-only post-migration rule-parity check: effective rule set vs the captured GPO inventory, plus authority/source |
| `FWMIG-Report.ps1` | Read-only coverage + conflict report across devices (local NetSecurity + Intune firewall policy via Microsoft Graph) |
| `FWMIG-Remediation.ps1` | Safe (`-WhatIf` by default) resolution of conflicts / double-management — proposes fixes, applies only when confirmed |
| `FWMIG-Set-MigrationRingTargeting.ps1` | Creates/populates the `Migration Ring – Pilot` / `Wave 1` / `Broad` Entra groups (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the Phoenixtekk model: **Assess → Configure → Pilot → Validate → Expand**
  with a parity gate and rollback at every ring.

## Outcome
Windows Defender Firewall migrated from GPO to Intune — rules translated and validated for parity,
conflicts and merge loops avoided through managed coexistence, cut over in rings, and the legacy GPO
firewall settings cleanly retired.
