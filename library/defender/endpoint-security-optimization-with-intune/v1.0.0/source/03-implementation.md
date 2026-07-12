# 3. Implementation Guide — optimization: Endpoint Security with Microsoft Intune

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`) and the **Microsoft Entra admin center** (`https://entra.microsoft.com`) for Conditional Access review. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Baseline the current estate, tune on the **pilot ring** `Intune Optimize – Pilot Ring – Pilot` first, **measure the before/after delta**, then expand ring by ring. Every disruptive change — especially compliance and Conditional Access — starts **report-only / staged**, and every step names a rollback. **Which compliance thresholds and Conditional Access grants are required is the security/identity team's decision.**

## Naming (set once, reuse verbatim)
- Pilot device group (Entra): `Intune Optimize – Pilot Ring – Pilot`
- Migrated security baseline (pilot): `Security Baseline – Pilot Ring – Pilot`
- Migrated security baseline (production, on expand): `Security Baseline – All Devices – Prod`
- Consolidated endpoint-security policy (per setting area): `Endpoint Security – <area> – Prod` (e.g. `Endpoint Security – Antivirus – Prod`)
- Tuned compliance policy: `Compliance – Windows Corporate – Prod`
- Conditional Access (report-only during tuning): `CA – Require Compliant Device – ReportOnly`

## Step 1 — Baseline the current estate (measure "before")
1. `intune.microsoft.com` → **Endpoint security** and **Devices → Compliance**. Note the current baseline versions, the count of devices in **Conflict/Error**, and the **non-compliant** proportion.
2. Run `SOPEIS-Discovery.ps1` to capture, read-only: all endpoint-security and compliance policies, their assignments, applied security-baseline versions, per-policy assignment coverage, and groups.
3. Run `SOPEIS-ConflictReport.ps1` to list devices/settings reporting **Conflict** or **Error** and the policies contributing to each.
4. Run `SOPEIS-Report.ps1 -SaveBaseline` to record the **before** metrics — conflict/error counts, non-compliant proportion, coverage % per policy type — to `sopeis-baseline.json`.

## Step 2 — Migrate security baselines to the current version (pilot)
1. **Endpoint security → Security baselines** → open the baseline with a newer version available → **Create profile** on the **latest version**, named `Security Baseline – Pilot Ring – Pilot`.
2. Carry forward only **justified** customizations from the old profile; take Microsoft's new defaults otherwise. *Baseline versions/settings change — verify current.*
3. **Assign** the new baseline to `Intune Optimize – Pilot Ring – Pilot` **only**, and **remove the pilot ring** from the old baseline's assignment so the two don't overlap (overlap causes conflict — Step 3).
4. Force a sync on a pilot device; allow the check-in cadence to apply the new baseline.

## Step 3 — Resolve policy conflicts (pilot)
1. Re-run `SOPEIS-ConflictReport.ps1` (scoped to the pilot ring). For each conflicting setting, identify every policy that sets it.
2. Choose **one authoritative** policy per setting area, named `Endpoint Security – <area> – Prod`. **Remove the setting** from the non-authoritative policies (or remove those policies' assignment to the ring) so only one source remains.
3. Prefer consolidating overlapping legacy device-configuration profiles into the security-baseline / endpoint-security policy rather than maintaining parallel copies.
4. Re-run `SOPEIS-ConflictReport.ps1` → confirm the conflict/error count on the pilot ring drops toward zero.

## Step 4 — Tune compliance and understand the Conditional Access impact (pilot)
1. **Devices → Compliance → Policies** → open/clone the policy as `Compliance – Windows Corporate – Prod`. Adjust the settings that generate **false** non-compliance (e.g. an OS-version floor set too high, a Defender-signal check that's flaky) and ensure real gaps (encryption off, no Defender) still fail.
2. Set **Actions for noncompliance** with a **grace period** (notify before mark non-compliant) so users aren't blocked instantly. *The grace period and thresholds are the security team's decision.*
3. **Review the CA impact first:** `entra.microsoft.com` → **Conditional Access** → put/keep the compliance-grant policy in **Report-only** (`CA – Require Compliant Device – ReportOnly`) and use the **What-If** tool to model who would be blocked before enforcing. **The enforce decision is the identity team's.**
4. **Assign** the tuned compliance policy to the pilot ring; monitor results before expanding.

## Step 5 — Expand coverage to unassigned devices (pilot → estate)
1. Run `SOPEIS-Discovery.ps1` (and review the coverage section) to find devices/users **not receiving** baseline, compliance, or Defender policy — the coverage gaps.
2. Fix the assignment model: point policies at a consistent set of groups; correct empty dynamic-group rules and over-broad **exclusions**.
3. **Preview the assignment change first:** run `SOPEIS-Set-Assignment.ps1 -PolicyName '<policy>' -GroupName 'Intune Optimize – Pilot Ring – Pilot'` (defaults to `-WhatIf`) to see the assignment it would add; re-run with `-Apply`.
4. Run `SOPEIS-Validate.ps1` → confirms coverage improved and no device is now double-targeted (which would re-introduce conflict).

## Step 6 — Validate the pilot (measure "after")
1. Run `SOPEIS-Validate.ps1` → confirms the latest baseline applied to the pilot, conflict/error count near zero, tuned compliance policy assigned, and coverage improved.
2. Run `SOPEIS-Report.ps1 -BaselinePath .\sopeis-baseline.json` → shows the **before/after delta**: fewer conflicts/errors, lower false-non-compliant proportion, higher coverage.
3. Confirm no pilot user was unexpectedly blocked (check the CA report-only results). Complete the **Testing Guide** before expanding.

## Step 7 — Expand ring by ring across the estate
1. Clone the validated pilot artifacts to production scope: `Security Baseline – All Devices – Prod`, the consolidated `Endpoint Security – <area> – Prod` policies, and the tuned compliance policy, assigned to the next ring, then the estate.
2. Only after the report-only CA impact is acceptable to the identity team, move `CA – Require Compliant Device – ReportOnly` to **On** in a staged manner.
3. Re-baseline with `SOPEIS-Report.ps1 -SaveBaseline` after each wave and track drift — conflicts should stay near zero and coverage complete as new devices and baseline versions appear.

---
### Order of operations
`Baseline (before) → migrate baseline version (pilot) → resolve conflicts → tune compliance + review CA (report-only) → expand coverage → validate the before/after delta → expand ring by ring (enforce CA last)`
