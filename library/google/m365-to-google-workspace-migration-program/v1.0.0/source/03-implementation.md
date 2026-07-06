# 3. Implementation Guide — Microsoft 365 → Google Workspace Migration Program & Wave Plan

Follow these steps in order. This guide runs the migration program end to end: baseline the estate,
design the target/tooling and coexistence, build the wave plan, prove the full cutover runbook on a
pilot wave, then expand wave by wave until the 150k estate is covered. Artifact names are fixed —
create them with the exact names shown and reuse them for every wave. The per-service data-movement
mechanics (mail, Drive, chat) are executed from their own solutions; this guide sequences and gates
them.

> Model: baseline and design once, stand up coexistence, prove the cutover on a pilot wave, validate
> against the gate, then expand. The repeatable way: Assess, then Configure, then Pilot, then Validate,
> then Expand.

## Step 1 — Assess: baseline the source estate and stand up governance
1. Run `GWMIGPROG-Discovery.ps1` to capture the source baseline: user/mailbox counts, licensed users,
   shared mailboxes and resource calendars, distribution lists/groups, and mail-touching signals.
   Record it as `GWMIGPROG Discovery - Source Estate - Baseline`, then add the data-volume and
   integration details the script cannot read (per-user mailbox/OneDrive sizes, relay connectors,
   service accounts, apps that send mail).
2. Stand up `GWMIGPROG Cadence & RACI - Program - All Stages`: a recurring program forum with named
   Responsible/Accountable owners for each cutover stage, chairing every go/no-go, operating under the
   change-control process from the global requirements.
3. Record gaps against the Requirements checklist. Do not proceed past a missing baseline or missing
   identity source of truth — resolve those first.

## Step 2 — Design the target architecture and tooling strategy
1. Fix the target Google Workspace architecture: edition/licensing for the estate, org-unit structure,
   and group model. Record it in `GWMIGPROG Design - Target & Tooling - Program`.
2. Choose the identity/provisioning model (GCDS or SCIM) against the identity source of truth.
3. Choose the migration tooling/pattern **per service** and write it into the design:
   - **Mail & calendar** — the tool/pattern that moves mailboxes, calendars, and contacts and the
     order relative to the mail cutover (mechanics deferred to the Exchange Online → Gmail solution).
   - **Drive** — the tool/pattern that moves OneDrive/SharePoint content to Google Drive/shared drives
     with permissions preserved, staged ahead of cutover and finalized at cutover (mechanics deferred
     to the SharePoint/OneDrive → Google Drive solution).
   - **Chat / collaboration** — the tool/pattern for Teams → Google Chat/Meet aligned to the user's
     move (mechanics deferred to the Teams → Chat/Meet solution).
   Author the tooling **tool-agnostically** here — this program governs *which pattern and when*, not a
   specific vendor's console steps.
4. Freeze the design before Wave 0. Every wave executes this same design.

## Step 3 — Design and stand up coexistence
1. Design the transition state as `GWMIGPROG Coexistence - Mail & Calendar - Transition`:
   - **Mail routing.** Decide **split delivery** (inbound mail routed to Google or Microsoft 365 per
     recipient/mailbox rules — the usual pattern for a per-wave move where MX points at Google and
     not-yet-migrated users are routed on to Microsoft 365) or **dual delivery** (deliver to a primary
     and forward to a secondary), per
     [Google — dual delivery](https://support.google.com/a/answer/9228551) and
     [Google — split delivery](https://support.google.com/a/answer/12971016). Define how the routing
     rule keys off each wave's migrated population so mail follows users as they move.
   - **Calendar interop.** Define how free/busy resolves across the two platforms during the split so
     cross-platform scheduling works.
2. Stand up the routing on a test domain/host and prove it: a test message reaches the correct platform
   for a migrated and a not-yet-migrated user, and a cross-platform meeting resolves free/busy.
3. Set coexistence's intended **end** — it is transitional, decommissioned as waves complete, never a
   permanent state.

## Step 4 — Build the wave plan
1. Segment the 150k population into `GWMIGPROG Wave Plan - Segmentation - 150k`. Size waves from the
   discovery baseline, driven by user count, data volume, and data types
   ([Google — plan your phases](https://support.google.com/workspacemigrate/answer/9275515)).
2. Apply the sizing rules:
   - **Wave 0 = pilot** — 50–150 users of core IT and early adopters that exercises the full runbook
     end to end before any production business unit moves.
   - **Coherent business units.** Keep each wave a single business unit/geography so comms, support,
     and coexistence routing are focused.
   - **Spread data-heavy users.** Distribute the largest mailboxes/Drives across waves so no single
     wave exceeds migration throughput.
   - **Essential data at go-live, archives later** where the tooling allows deferring low-value
     historical data past cutover.
   - **One wave per user, fixed.** Assign every user to exactly one wave and do not move users between
     waves once confirmed (that risks duplicate data).
3. Build each wave's target group with `GWMIGPROG-Set-ScopeTargeting.ps1` (runs with `-WhatIf` by
   default).

## Step 5 — Author the per-wave cutover runbook and go/no-go gate
1. Author `GWMIGPROG Runbook - Cutover - Per Wave` with the fixed five-stage sequence:
   1. **Readiness** — the wave's users/groups are provisioned in Google, licenses assigned, Drive
      pre-stage complete, comms/training delivered, and `GWMIGPROG-Validation.ps1` reports the wave
      ready.
   2. **Mail-flow / DNS** — apply the coexistence routing change for this wave under change control so
      mail follows the migrated users; stage any DNS/MX change with a documented back-out.
   3. **Data move** — execute the per-service data move for the wave (mail/calendar, Drive finalize,
      chat) via the individual solutions, in the designed order.
   4. **Validation** — run the per-wave validation gates (Testing Guide) and `GWMIGPROG-Report.ps1` to
      confirm coverage.
   5. **Rollback** — the documented back-out (revert routing/DNS to the prior platform, re-point the
      wave) used only if the gate fails.
2. Define `GWMIGPROG Gate - Go/No-Go - Per Wave`: the wave passes only when readiness held, mail-flow
   is correct, the data move completed for the wave's users, validation passed, and hypercare owners
   are ready. The next wave does not start until this gate passes.

## Step 6 — Run Wave 0 (the pilot) end to end
1. Build the Wave 0 group with `GWMIGPROG-Set-ScopeTargeting.ps1 -WhatIf:$false`.
2. Execute the full runbook on Wave 0: readiness → mail-flow/DNS → data move → validation.
3. Run `GWMIGPROG-Validation.ps1` for the wave and `GWMIGPROG-Report.ps1` for progress/coverage.
4. Hold the Wave 0 `GWMIGPROG Gate - Go/No-Go - Per Wave` at the program cadence. The pilot passes only
   when the whole runbook ran end to end and validation is clean.

## Step 7 — Validate the pilot and fix the runbook, not just the wave
1. Complete the Testing Guide for Wave 0. Treat every issue as a **runbook** defect: fix the runbook,
   the coexistence design, or the tooling pattern so later waves inherit the fix.
2. Remediate any data/coverage gaps with `GWMIGPROG-Remediation.ps1` (runs with `-WhatIf` by default)
   before re-running validation.

## Step 8 — Expand wave by wave
1. For each subsequent wave, re-run the same runbook: build the wave group
   (`GWMIGPROG-Set-ScopeTargeting.ps1`), execute readiness → mail-flow/DNS → data move → validation,
   run `GWMIGPROG-Validation.ps1` and `GWMIGPROG-Report.ps1`, and pass the go/no-go gate before the
   next wave.
2. Keep coexistence routing current as the migrated population grows; the routing rule must always
   send each user's mail to their current platform.

## Step 9 — Hypercare and decommission
1. After each wave, run a heightened-support hypercare window: triage issues fast, confirm the wave's
   users are fully functional, and formally close the wave at the cadence.
2. After the **final** wave clears hypercare, decommission coexistence routing, retire the transition
   DNS/MX configuration, and stand down the source-tenant footprint per the design's end-state — never
   mid-program.

---
### Order of operations
`Assess/baseline -> Design (target+tooling) -> Coexistence -> Wave plan -> Runbook+gate -> Wave 0 pilot -> Validate/fix runbook -> Expand wave by wave -> Hypercare + decommission`
