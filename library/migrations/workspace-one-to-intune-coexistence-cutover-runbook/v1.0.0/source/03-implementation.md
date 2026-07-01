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
