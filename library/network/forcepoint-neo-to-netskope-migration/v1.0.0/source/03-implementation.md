# 3. Implementation Guide — Forcepoint Neo to Netskope Migration (Legacy Web Filtering)

Follow these steps in order. Endpoint agent and group work is done in the Microsoft Intune admin
center (`https://intune.microsoft.com`) and Microsoft Entra (`https://entra.microsoft.com`).
Netskope and Forcepoint console steps are deferred to each vendor's official documentation — the
named action is given; confirm the exact control in your console.

> Model: translate the legacy policy, deploy Netskope present-but-passive alongside Forcepoint, cut
> over one ring at a time, validate parity, remove the legacy agent per ring, and decommission the
> platform only after a final parity gate. Pattern: `Assess -> Configure -> Pilot -> Validate -> Expand.`

## Step 1 — Assess: inventory the legacy estate
1. Run `NSMIG-Discovery.ps1` on representative devices (or via your management tooling) to detect the Forcepoint Neo agent and capture its version and the device's current web-steering state.
2. In Entra -> Groups -> New group -> Security, create `Legacy Estate - Forcepoint Neo - Inventory` and populate it from the discovery output. This group tracks where the legacy agent still lives so you can confirm decommission later.

## Step 2 — Assess: export and capture the legacy policy
1. In the Forcepoint Neo console, export the active web-filtering policy — categories, allow/deny lists, SSL-inspection scope, and exceptions (exact export path deferred to Forcepoint docs).
2. Record the export as the parity baseline. Derive the parity test set (Requirement 2.7): representative URLs for each allowed, blocked, SSL-inspected, and exception rule.

## Step 3 — Configure: translate the policy into Netskope
1. In the Netskope console, build the SWG real-time-protection policy set named `Translated Web Filtering Policy - Org - Netskope` that mirrors the legacy export (exact policy screens deferred to Netskope docs).
2. Map each legacy category and custom rule to its Netskope equivalent. Where a legacy category has no one-to-one Netskope category, choose the closest mapping and flag it for a parity test.
3. Do not assign this policy to enforce yet — at this stage Netskope is configured but not steering live traffic for any production device.

## Step 4 — Configure: build the migration rings and groups
1. Run `NSMIG-Set-MigrationRingTargeting.ps1 -WhatIf` to preview, then run it to create/populate the Entra groups: `Migration Ring - Pilot - Cutover` (small, representative), `Migration Ring - Broad - Cutover` (the rest), `Coexistence Group - Netskope - Passive`, and `Steering Group - Netskope - Enforce`.
2. Keep membership non-overlapping: a device is in either the passive group or the enforce group, never both.

## Step 5 — Configure: deploy Netskope present-but-passive (coexistence)
1. In Intune, assign the Netskope client app, certificate profiles, and steering config to `Coexistence Group - Netskope - Passive` (which initially contains `Migration Ring - Pilot - Cutover`).
2. Deploy Netskope in a passive posture so Forcepoint continues to steer and enforce; Netskope is installed but not inspecting the same traffic (passive-vs-enforce posture deferred to Netskope docs).
3. On a pilot device, run `NSMIG-Validation.ps1` to confirm both agents are present and that only Forcepoint is currently steering (no dual enforcement).

## Step 6 — Pilot: cut over the pilot ring to Netskope
1. Move the pilot ring out of passive and into enforce: remove `Migration Ring - Pilot - Cutover` devices from `Coexistence Group - Netskope - Passive` and add them to `Steering Group - Netskope - Enforce` (use `NSMIG-Set-MigrationRingTargeting.ps1`).
2. In Netskope, ensure `Translated Web Filtering Policy - Org - Netskope` enforces for the enforce group, and set Forcepoint to stop steering those devices (exact steering controls deferred to each vendor's docs).
3. Confirm the swap: exactly one agent now enforces. Run `NSMIG-Validation.ps1` — it should report Netskope steering active and Forcepoint no longer steering on pilot devices.

## Step 7 — Validate: parity gate on the pilot ring
1. Run the parity test set on pilot devices: each allowed URL still loads, each blocked category is still blocked, SSL-inspected sites present the expected certificate, and exceptions behave as before.
2. Run `NSMIG-Report.ps1` for a coverage and conflict report (devices steered, agents present, parity status). Complete the Testing Guide.
3. Parity gate: do not proceed until the pilot ring passes. If it fails, roll back (Step 6 reversed: return the ring to passive, revert steering to Forcepoint, do not remove the legacy agent) and fix the translation.

## Step 8 — Validate: remove the legacy agent from the pilot ring
1. Only after the pilot passes parity, remove the Forcepoint Neo agent from pilot devices. Run `NSMIG-Remediation.ps1` (default `-WhatIf`) to preview, then re-run with `-Confirm` to remove the legacy agent.
2. Run `NSMIG-Validation.ps1` to confirm Forcepoint Neo is gone and Netskope is the sole enforcing agent. Update `Legacy Estate - Forcepoint Neo - Inventory` to drop the removed devices.

## Step 9 — Expand: repeat per ring
1. Add `Migration Ring - Broad - Cutover` devices to `Coexistence Group - Netskope - Passive`, deploy Netskope passive (Step 5), then repeat Steps 6-8 for the broad ring.
2. Re-run `NSMIG-Report.ps1` each ring to confirm coverage grows and no device is left dual-enforced or unprotected.

## Step 10 — Decommission Forcepoint (final gate)
1. Final parity gate: confirm `Legacy Estate - Forcepoint Neo - Inventory` is empty (every device has had the agent removed and validated) and `NSMIG-Report.ps1` shows full Netskope coverage with no conflicts.
2. Only then decommission the Forcepoint Neo platform (retire the tenant/console and management infrastructure per Forcepoint's guidance).

---
### Order of operations
`Inventory -> policy export -> translate -> rings/groups -> Netskope passive -> pilot cutover -> pilot parity gate -> remove legacy agent (pilot) -> repeat per ring -> decommission Forcepoint`

### Rollback note
At any ring before the legacy agent is removed, roll back by returning the ring to
`Coexistence Group - Netskope - Passive`, reverting steering to `Forcepoint-steered`, and leaving the
Forcepoint Neo agent installed. Legacy-agent removal (Step 8) is the point of no easy return — it is
gated on a passed parity test for that ring.
