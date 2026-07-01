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
