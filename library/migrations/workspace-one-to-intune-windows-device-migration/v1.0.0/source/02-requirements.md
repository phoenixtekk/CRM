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
