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
