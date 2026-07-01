# 3. Implementation Guide — MDM Migration Readiness Assessment & Wave Planning

Follow these steps **in order**. This is a planning engagement: the output is a set of named
artifacts, not a changed device. The model is **Assess → Configure → Pilot → Validate → Expand**, with
a hard gate that the plan is **validated against a pilot wave** before it scales.

> **Vendor-neutral note:** every step reads either a generic CSV export from the source MDM or, when
> the current/target MDM is Intune-adjacent, a live Microsoft Graph pull. No step requires write
> access to the source platform.

## The input schema (map your source export to these columns)
The scripts read a CSV (the raw estate export) with these columns. Map your source MDM's export
columns to these names, or let `MDMRDY-Discovery.ps1` build them from Microsoft Graph.

| Column | Meaning |
|---|---|
| `DeviceName` | Unique device identifier/name |
| `Platform` | `Windows` / `iOS` / `iPadOS` / `macOS` / `Android` |
| `OSVersion` | Current OS version string |
| `Owner` | User principal name or owner identifier |
| `Department` | Department/business unit |
| `Region` | Site/region |
| `EnrollmentType` | `Corporate-ADE` / `UserDriven` / `BYOD` / `Shared` / `Kiosk` |
| `Compliance` | `Compliant` / `NonCompliant` / `Unknown` |
| `LastCheckIn` | Last check-in date (ISO 8601) |
| `Apps` | Semicolon-separated app list (or app count) |
| `Profiles` | Semicolon-separated profile list (Wi-Fi;VPN;Cert;Email;Restrictions;Kiosk) |
| `Criticality` | `Standard` / `Executive` / `Critical` (from stakeholder input) |

## Stage 1 — Assess (inventory + score)

### Step 1 — Inventory the estate
1. Produce the raw export from the source MDM (CSV), or confirm Microsoft Graph read access if Intune
   is source/target.
2. From the `scripts` folder run the discovery (read-only):
   - CSV source: `powershell -ExecutionPolicy Bypass -File .\MDMRDY-Discovery.ps1 -InputCsv .\source-export.csv -OutputFolder C:\MDMRDY`
   - Intune source: `powershell -ExecutionPolicy Bypass -File .\MDMRDY-Discovery.ps1 -UseGraph -OutputFolder C:\MDMRDY`
3. Output: the `Estate Inventory – MDM Migration – Assess` (a normalized CSV of every in-scope device
   with platform, OS, owner, department/region, enrollment type, compliance, apps, and profiles).

### Step 2 — Validate inventory completeness
1. Run the validation (read-only) against the inventory:
   `powershell -ExecutionPolicy Bypass -File .\MDMRDY-Validation.ps1 -InventoryCsv C:\MDMRDY\estate-inventory.csv -OutputFolder C:\MDMRDY`
2. It flags missing/blank fields, unknown platforms, stale check-ins, and rows that cannot be scored.
3. Output: a data-completeness report. Do not score readiness until completeness passes the gate in
   the Testing Guide (Test 1).

### Step 3 — Fill inventory gaps (safe remediation)
1. Where rows are incomplete, run the remediation in its **default `-WhatIf` mode** first to preview
   the fills:
   `powershell -ExecutionPolicy Bypass -File .\MDMRDY-Remediation.ps1 -InventoryCsv C:\MDMRDY\estate-inventory.csv -OutputFolder C:\MDMRDY`
2. Review the proposed fills (defaulting unknown enrollment type, inferring platform from OS, marking
   stale devices for review). Re-run with `-Apply` only when the proposed changes are correct.
3. Output: a completed `Estate Inventory – MDM Migration – Assess` ready to score.

### Step 4 — Score readiness and risk, map dependencies
1. Run the report (read-only) over the completed inventory:
   `powershell -ExecutionPolicy Bypass -File .\MDMRDY-Report.ps1 -InventoryCsv C:\MDMRDY\estate-inventory.csv -OutputFolder C:\MDMRDY`
2. It produces, in one pass:
   - the `Readiness Scorecard – MDM Migration – Assess` (per-device readiness score 0–100 against
     supported OS, reachable/recent check-in, enrolled, app coverage understood, no unsupported
     profile),
   - the `Risk Register – MDM Migration – Assess` (per-device risk score and the contributing risk
     factors: executive/critical, shared/kiosk, certificate/VPN dependency, unsupported config,
     non-compliant, stale),
   - the `Dependency Map – MDM Migration – Assess` (what must move together/in order: certificates,
     Wi-Fi/VPN, line-of-business apps, conditional access, shared-device groupings),
   - and a **draft** `Wave Plan – MDM Migration – Configure` with suggested wave assignment.

## Stage 2 — Configure (design the waves)

### Step 5 — Finalize the wave plan and cohorts
1. Review the draft wave plan with stakeholders; adjust assignments for criticality and change
   windows that only the business knows.
2. The wave model sequences from **lowest risk / highest readiness** to **highest risk / lowest
   readiness**:
   - **Wave 0 — Pilot:** a small, low-risk, high-readiness, representative cross-section.
   - **Wave 1 — Early:** standard devices, no special dependencies.
   - **Wave 2 — Broad:** the bulk of standard devices.
   - **Wave 3 — Complex/Critical:** executive, shared/kiosk, certificate/VPN-dependent, low-readiness.
3. Each wave carries an `Entry/Exit Criteria – Per Wave – Pilot` block (see Step 6).
4. Output: the finalized `Wave Plan – MDM Migration – Configure` and the
   `Wave Cohorts – MDM Migration – Configure` (the per-wave device membership lists).

### Step 6 — Define entry/exit criteria per wave
Record, for every wave, the `Entry/Exit Criteria – Per Wave – Pilot`:
- **Entry:** prior wave exited cleanly; target enrollment channel active for the platforms in this
  wave (`global-requirements-migrations.md` G5); rollback path documented (G7); cohort group built.
- **Exit:** all devices in the cohort migrated and enrolled in the target; compliance re-established;
  no open severity-1 issue; user-impact tickets below the agreed threshold.

### Step 7 — Build the cohort groups
1. Materialize each wave's membership as a `Cohort Group – Per Wave – Configure`.
2. Build the groups from the cohort lists:
   - Export-only (any MDM): `powershell -ExecutionPolicy Bypass -File .\MDMRDY-Set-WaveCohortTargeting.ps1 -CohortsCsv C:\MDMRDY\wave-cohorts.csv -OutputFolder C:\MDMRDY` — writes per-wave membership CSVs you can import into the target's grouping system.
   - Entra/Intune target: add `-CreateEntraGroups -WhatIf` to preview, then `-CreateEntraGroups -Apply` to create one Microsoft Entra security group per wave and add members (requires Graph `Group.ReadWrite.All`).
3. Naming: each group is `Cohort Group – Per Wave – Configure`, suffixed with the wave label (e.g.
   `MDMRDY-Wave0-Pilot`, `MDMRDY-Wave1-Early`).

## Stage 3 — Pilot

### Step 8 — Run the pilot wave
1. The `Pilot Wave – MDM Migration – Pilot` (Wave 0) is the first cohort to migrate, using your
   separate migration runbook (this solution plans; it does not cut over).
2. Confirm the pilot meets its `Entry/Exit Criteria – Per Wave – Pilot` before starting.

## Stage 4 — Validate (the gate)

### Step 9 — Validate the plan against the pilot
1. After the pilot wave migrates, re-run `MDMRDY-Discovery.ps1` and `MDMRDY-Report.ps1` against the
   post-pilot estate to confirm the pilot's exit criteria are met and the readiness/risk model held.
2. Reconcile predicted vs. actual: did the readiness scores predict the smooth devices, and did the
   risk register predict the friction? Adjust the scoring weights and the remaining waves if not.
3. **Do not expand** until the pilot wave passes its exit criteria and the plan is validated. This is
   the mandatory gate.

## Stage 5 — Expand

### Step 10 — Sequence the remaining waves
1. With the plan validated, release the remaining waves in order, each gated by its
   `Entry/Exit Criteria – Per Wave – Pilot`.
2. Re-run `MDMRDY-Report.ps1` after each wave to keep the readiness/risk picture and the cohorts
   current as devices leave the source estate.

---
### Order of operations
`Inventory (Discovery) → Validate completeness → Fill gaps (Remediation, -WhatIf first) → Score readiness/risk + dependencies (Report) → Finalize Wave Plan + Cohorts → Entry/Exit criteria → Build cohort groups → Pilot wave → Validate plan against pilot (gate) → Expand remaining waves`
