# 3. Implementation Guide — Zero Trust Network Access (ZTNA) with Netskope Private Access

Follow these steps in order. Identity and group work is done in the Microsoft Entra admin center
(`https://entra.microsoft.com`); endpoint work in the Microsoft Intune admin center
(`https://intune.microsoft.com`). All Netskope Private Access work (deploying `publishers`,
publishing private apps, and authoring access policy) is done in the Netskope tenant admin console —
the exact screens and menu paths are deferred to the official Netskope documentation, so this guide
names each step and the artifact to create and you confirm the precise control in your console.

> Model: deploy a `publisher` next to the apps, publish each private app, grant identity- and
> posture-based least-privilege access, prove it on a pilot while the VPN still runs, then cut over.
> Reuse the artifact names from Requirements section 2 (Naming convention) verbatim.
>
> Pilot gate (do not pass without it): every pilot user reaches every entitled app through ZTNA,
> posture is enforced, and the VPN is no longer needed by the pilot — only then expand and cut over.
>
> Rollback note: this is access-affecting. At every stage the VPN remains the fall-back. If ZTNA
> access fails, leave or re-enable the user's VPN access and remove them from the ZTNA `Access Group`
> until the issue is resolved; do not retire the VPN until the cutover stage passes.

## Step 1 — Assess: confirm prerequisites and inventory
1. Run `NSZTNA-Discovery.ps1` to capture endpoint posture, current VPN routes/hosts, and candidate
   `publisher` hosts. Reconcile its output against the private application inventory from
   Requirements 2.3.
2. Confirm every requirement in section 2 is met (Netskope Private Access licensed, `publisher` host
   capacity, client deployable, posture available, DNS path planned).

## Step 2 — Configure: build the entitlement groups
1. Create the pilot entitlement group `Access Group – Pilot – Pilot` and add a few representative
   users/devices (use `NSZTNA-Set-AccessGroupTargeting.ps1` with `-WhatIf` first, then commit).
2. Create a per-app or per-role entitlement group for each app set, named
   `Access Group – <App or Role> – Pilot` (and the matching `Access Group – <App or Role> – Production`
   for later expansion).
3. Run `NSZTNA-Validation.ps1` to confirm each group exists and has members.

## Step 3 — Configure: deploy the publisher (connector)
1. In the Netskope console, deploy a `publisher` on the host prepared in Requirements 2.2, named
   `Publisher – <Site> – Pilot`. It connects outbound to the Netskope cloud — no inbound ports are
   opened (deferred to Netskope documentation for the image and registration steps).
2. Confirm the `publisher` shows healthy/connected in the Netskope console before continuing.
3. For resilience, plan a second `publisher` per site (`Publisher – <Site> – Production`) to add at
   the Expand stage.

## Step 4 — Configure: publish the private apps
1. For each app in the inventory, create a private-application object named
   `Private App – <App> – Pilot`, mapping it to the exact internal host(s)/FQDN and port(s)/protocol
   recorded in Requirements 2.3, and associate it with `Publisher – <Site> – Pilot`.
2. Confirm DNS for each published app resolves through the ZTNA path (Requirements 2.7).
3. Keep the published app set small for the pilot (the apps the pilot users actually need).

## Step 5 — Configure: author least-privilege access policy
1. For each app (or role), create an access policy named `Access Policy – <App or Role> – Pilot` that:
   - matches the identity/group `Access Group – <App or Role> – Pilot` (or the pilot group), and
   - requires the device posture condition from Requirements 2.6 (managed/compliant or certificate),
   - and grants only `Private App – <App> – Pilot` — nothing broader.
2. Default-deny everything else: a user reaches only the apps an explicit policy grants.
3. Confirm policy order so the least-privilege rules evaluate as intended (deferred to Netskope
   documentation for the policy editor specifics).

## Step 6 — Pilot: deploy the client and steer the pilot users
1. Deploy the Netskope client to the pilot devices via Intune (Requirements 2.5) and confirm it is
   enrolled and steering.
2. Leave the VPN in place for the pilot users — coexistence: ZTNA and VPN run side by side so a
   failed app reach falls back to the VPN.
3. Run `NSZTNA-Validation.ps1` on a pilot device to confirm client state, group membership, posture,
   and that a published app resolves and is reachable.

## Step 7 — Validate: prove the pilot against the gate
1. Run `NSZTNA-Validation.ps1` for each pilot user/app: confirm entitled apps are reachable and
   non-entitled apps are not.
2. Run `NSZTNA-Report.ps1` to produce the access and usage report (who is entitled to what, posture,
   and which apps the pilot is actually using through ZTNA).
3. Complete the Testing Guide. The pilot gate passes only when every pilot user reaches every
   entitled app through ZTNA, posture is enforced, and the pilot no longer relies on the VPN.

## Step 8 — Expand: widen entitlement and add production publishers
1. Add the second `publisher` per site (`Publisher – <Site> – Production`) for resilience and
   capacity.
2. Promote each app to `Private App – <App> – Production` and each rule to
   `Access Policy – <App or Role> – Production`, targeting the `Access Group – <App or Role> – Production`
   groups; add users in waves using `NSZTNA-Set-AccessGroupTargeting.ps1` (`-WhatIf` first).
3. Re-run `NSZTNA-Validation.ps1` and `NSZTNA-Report.ps1` after each wave; use
   `NSZTNA-Remediation.ps1` (default `-WhatIf`) to fix broken access (e.g. a user missing from an
   entitlement group).

## Step 9 — Cut over: retire the VPN
1. Only after each wave passes the gate, remove that wave's users from VPN access (keep the VPN
   reachable as fall-back until the wave is confirmed stable).
2. When all waves are cut over and stable, decommission the VPN concentrator/access.
3. Keep `NSZTNA-Report.ps1` on a schedule to audit entitlement and usage going forward.

---
### Order of operations
`Assess (Discovery) -> entitlement groups -> deploy publisher -> publish apps -> least-privilege policy -> deploy client + steer pilot (coexistence) -> validate against gate -> expand in waves -> cut over and retire VPN`
