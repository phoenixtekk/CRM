# 2. Requirements Guide — Forcepoint Neo to Netskope Migration (Legacy Web Filtering)

Verify every requirement before configuring. Each entry: Description, Why, Verify,
Implement-if-missing. Category-wide prerequisites (Netskope tenant, Entra ID, Intune, admin roles,
network fundamentals, pilot group, change control) are in `global-requirements-network.md` and are
assumed in addition to the migration-specific items below.

> Vendor note: exact Netskope and Forcepoint console screens, menu paths, and policy-export and
> client-deployment steps change over time and are deferred to each vendor's official documentation
> and your tenant/console. Follow the named step and confirm the precise control there.

## 2.1 Netskope tenant with Secure Web Gateway (SWG)
Description: An active Netskope tenant with the SWG / real-time web-protection capability licensed.
Why: SWG is the destination control plane that will enforce the translated web-filtering policy.
Verify: Sign in to the Netskope admin console and confirm SWG / real-time protection policy is available (deferred to Netskope docs for the exact location).
Implement: Engage your Netskope account team / reseller to enable SWG on the tenant.

## 2.2 Existing Forcepoint Neo configuration and a policy export
Description: Admin access to the Forcepoint Neo console and an export of the current web-filtering policy (categories, allow/deny lists, SSL-inspection scope, exceptions).
Why: The export is the source of truth for what the translated Netskope policy must match for parity.
Verify: Open the Forcepoint Neo console and produce a policy export (deferred to Forcepoint docs for the exact export path); run `NSMIG-Discovery.ps1` to confirm which devices run the agent.
Implement: Obtain Forcepoint console admin access; export the active web-filtering policy and record it as the parity baseline.

## 2.3 Forcepoint Neo agent inventory across the estate
Description: A known, current list of which managed devices still run the Forcepoint Neo agent — the `Legacy Estate - Forcepoint Neo - Inventory` group.
Why: You cannot stage a cutover or confirm decommission without knowing where the legacy agent is installed.
Verify: Run `NSMIG-Discovery.ps1` (detects the Forcepoint Neo agent on a device); cross-check against the Intune managed-device inventory.
Implement: Build the `Legacy Estate - Forcepoint Neo - Inventory` group from discovery output; keep it current as agents are removed.

## 2.4 Netskope client deployable via Intune
Description: The Netskope client (and any required root/decryption certificates and steering config) packaged for deployment to managed devices through Microsoft Intune.
Why: The new agent and its certificates must reach endpoints to enforce SSL inspection and steering.
Verify: Confirm the Netskope client app/config and certificate profiles exist in Intune and can target a group; install paths are deferred to Netskope deployment docs.
Implement: Package the Netskope client per Netskope's deployment guidance; create the Intune app, certificate, and steering-config profiles.

## 2.5 Coexistence plan (one enforcing agent at a time)
Description: A defined posture where the Netskope client is installed present-but-passive while Forcepoint still enforces, with a single, controlled point where enforcement swaps.
Why: Two agents enforcing the same traffic collide (duplicated SSL inspection, broken certificate chains, dropped/looping connections).
Verify: Confirm the passive-vs-enforce posture per ring is documented and that `Coexistence Group - Netskope - Passive` and `Steering Group - Netskope - Enforce` are distinct, non-overlapping groups.
Implement: Define the coexistence posture with Netskope's guidance (deploy passive, then enforce); never enroll a device in both the passive and enforce groups at once.

## 2.6 Migration rings (staged device groups)
Description: Entra security groups `Migration Ring - Pilot - Cutover` (small, representative) and `Migration Ring - Broad - Cutover` (the rest), plus the steering/coexistence groups above.
Why: Cutover must be staged so a bad translation or steering issue is caught on the pilot, not the fleet.
Verify: Entra -> Groups; the pilot and broad migration rings exist and membership is non-overlapping; run `NSMIG-Set-MigrationRingTargeting.ps1 -WhatIf` to preview.
Implement: Create the groups with `NSMIG-Set-MigrationRingTargeting.ps1` (or Entra -> Groups -> New group -> Security) and populate the pilot ring first.

## 2.7 Parity test set (categories and URLs)
Description: A fixed list of representative URLs per legacy category (allowed, blocked, SSL-inspected, exception) used to compare Forcepoint behavior to Netskope behavior.
Why: Parity is proven by reproducible tests, not by assumption that the translation is complete.
Verify: The test set covers each category and rule in the policy export; results are recorded per ring.
Implement: Derive the test set from the `Translated Web Filtering Policy - Org - Netskope` mapping and the legacy export; keep it as the regression baseline.

## 2.8 Change control and a rollback path per stage
Description: A change window and a documented rollback (revert steering to `Forcepoint-steered`, set Netskope back to passive, do not remove the legacy agent) for each ring.
Why: Inline web-filtering changes affect live traffic and every cutover stage must be reversible until parity passes.
Verify: A per-ring rollback is written and approved before that ring is steered to Netskope.
Implement: Define rollback as revert-steering + Netskope-passive; only remove the Forcepoint agent after the ring passes parity and the change is approved.

---
## Checklist
- [ ] Netskope tenant with SWG licensed
- [ ] Forcepoint Neo console access + web-filtering policy export (parity baseline)
- [ ] Forcepoint Neo agent inventory — `NSMIG-Discovery.ps1`
- [ ] Netskope client + certificates deployable via Intune
- [ ] Coexistence plan: one enforcing agent at a time (passive vs enforce groups)
- [ ] Migration rings created — `NSMIG-Set-MigrationRingTargeting.ps1 -WhatIf`
- [ ] Parity test set (categories/URLs) defined
- [ ] Per-ring change control + rollback approved
