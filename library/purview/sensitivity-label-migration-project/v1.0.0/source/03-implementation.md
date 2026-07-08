# 3. Implementation Guide — Sensitivity Label Migration Project

Follow these steps **in order**. Work is done in the **Microsoft Purview portal**
(purview.microsoft.com), **Security & Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft
Graph**. Every write is previewed with `-WhatIf` (the default) before `-Commit`, and every
reclassification auto-labeling policy is created **in simulation** before it is enforced. Artifact names
follow the `<Purpose> – Purview – <Stage>` convention from the Overview and are reused verbatim.

> **Model:** Assess both sides → design the mapping matrix + detection → configure detection and
> auto-labeling **in simulation** → pilot to measure precision → validate coverage + precision →
> **enforce from simulation to reclassify** and expand location-by-location. Pattern: **Assess → Design
> → Configure → Pilot (simulate) → Validate → Expand (enforce).**
>
> **Auto-labeling is E5-gated and the reclassification cannot be undone by a single "unlabel" button —
> pilot in simulation and measure precision before enforcing.** The target labels must already exist and
> be published (Requirement 2.2). Portal paths are current at authoring — the Purview portal evolves, so
> **verify paths in your tenant.**

## Step 1 — Inventory both sides (Assess)
1. Export the **legacy classification values** from the source tool (Requirement 2.3) to a CSV — one row
   per distinct value, with (where available) the marking string, the metadata property or email header
   it writes, and an example item. Save it as `Legacy Classification Inventory – Migration – Assess`.
2. Run `IPMIG-Discovery.ps1 -LegacyCsv .\LegacyValues.csv -CsvFolder .\out`. Read-only, it captures the
   **target Purview estate** — sensitivity labels (`Get-Label`), label policies (`Get-LabelPolicy`),
   existing auto-labeling policies + mode (`Get-AutoSensitivityLabelPolicy`), and custom sensitive
   information types (`Get-DlpSensitiveInformationType`) — and cross-references your legacy CSV, listing
   each distinct legacy value and whether a matching target label / detection SIT already exists.
3. In the portal, open **Information Protection → Sensitivity labels**, **Label policies**, and
   **Auto-labeling** (verify paths) and confirm the on-screen estate matches the inventory.
4. **Pass/fail:** you have a dated inventory of every distinct legacy value **and** the full target
   estate — the baseline both sides of the migration map onto.

## Step 2 — Build the mapping matrix and choose detection (Design)
1. Build `Label Mapping Matrix – Design` — one row per legacy value:
   - **Target label** → exactly one existing, published Purview sensitivity label (confirm it exists,
     Requirement 2.2). If two legacy values should collapse to one label, that is allowed; if a value
     has **no clean target**, flag it as an explicit **owner decision** (do not guess).
   - **Detection method** → how Purview will recognize the value: a **custom SIT** matching the marking
     text/metadata, a **keyword**, or a **trainable classifier**. Record the exact match string
     (Requirement 2.4) and the SIT name `SIT – Legacy <Value> – Detect`.
   - **Protection intent** → whether the target label encrypts, and whether that reproduces protection
     the legacy tool applied (a **records/security decision**, deferred — Requirement 2.1 note).
   - **Locations in scope** and the **residual-marking reconciliation** decision (Requirement 2.8).
2. Author the **detection SITs** in the Purview portal (**Data classification → Sensitive info types →
   Create**) as a keyword/regex that matches each legacy marking. The portal is the documented path for
   custom-SIT authoring; name each `SIT – Legacy <Value> – Detect`. (The provided scripts **reference**
   these SITs by name; confirm they exist with `IPMIG-Discovery.ps1` before Step 3.)
3. **Pass/fail:** every in-scope legacy value has (a) one target label, (b) a named detection SIT that
   exists, and (c) a reconciliation decision. Unmapped values are named and owned, not silently dropped.

## Step 3 — Configure reclassification in simulation (Configure, preview-first)
1. Put the matrix into a mapping CSV (`LegacyValue,TargetLabel,SitName,Locations`) and dry-run:
   `IPMIG-Set-Migration.ps1 -MappingCsv .\mapping.csv -PilotSites <sites> -WhatIf`. With `-WhatIf` (the
   default) it makes **no changes** — it prints exactly which auto-labeling policy + rule it would create
   per mapping (`New-AutoSensitivityLabelPolicy -Mode TestWithoutNotifications`,
   `New-AutoSensitivityLabelRule -ContentContainsSensitiveInformation <SIT>` applying the mapped label)
   and confirms each referenced SIT and target label exists.
2. Read every line against `Label Mapping Matrix – Design`. Confirm each policy targets the **pilot
   locations only**, applies the **correct** target label, and is in **simulation**
   (`TestWithoutNotifications`) — it will **not** label anything yet.
3. Apply to the pilot: `IPMIG-Set-Migration.ps1 -MappingCsv .\mapping.csv -PilotSites <sites> -Commit`.
   This creates `Reclassify Sim – <Label> – Locations` policies in **simulation**. Nothing is
   reclassified.
4. **Pass/fail + rollback:** `Get-AutoSensitivityLabelPolicy` shows each policy in a `Test*`
   (simulation) mode, scoped to the pilot locations, applying the mapped label. Rollback:
   `IPMIG-Set-Migration.ps1 -PolicyName '<name>' -RemovePolicy -Commit` deletes the simulation policy
   (no content was touched).

## Step 4 — Run simulation and measure precision (Pilot)
1. Let the simulation scan the in-scope pilot locations (service-side scanning processes volume over
   time — **verify current scan limits for your tenant**). It scans and reports; **no content is
   labeled.**
2. Run `IPMIG-Validation.ps1 -SimReport -PolicyName 'Reclassify Sim – <Label> – Locations'` to report
   each policy's simulation mode/progress and the **items it would reclassify**.
3. Review the match set with the **data owner** against the mapping: sample matched items for **false
   positives** (content that would get the wrong label) and estimate **false negatives** (legacy-marked
   content the detection missed — Requirement 2.4).
4. **Pass/fail:** simulation has scanned, produced a match report, and the false-positive rate is within
   the agreed threshold. **This is the gate before enforcement.** If precision is poor, tune the
   detection SIT (tighter regex, higher instance counts, supporting keywords) in the portal and re-run
   simulation — do **not** enforce.

## Step 5 — Validate coverage and precision (Validate)
1. Run `IPMIG-Report.ps1 -MappingCsv .\mapping.csv -CsvPath .\MigrationCoverage.csv` to produce
   `Migration Coverage – Report`: every legacy value → mapped/unmapped, detection SIT present, policy in
   simulation vs enforced, and the simulated match count per policy.
2. Run `IPMIG-Scope-Health.ps1 -MappingCsv .\mapping.csv` for the **mapping-health** check — flags any
   legacy value with **no mapping**, a mapping referencing a **missing** SIT or target label, or a policy
   **enforcing before sign-off**.
3. **Pass/fail:** every in-scope legacy value is mapped and detected; no mapping references a missing
   object; every reclassification policy is still in simulation and has acceptable precision. Do **not**
   expand with an unmapped in-scope value or an unresolved detection gap.

## Step 6 — Enforce from simulation to reclassify (Expand — pilot locations)
1. Only after precision sign-off (Step 4/5), enforce the pilot policies:
   `IPMIG-Set-Migration.ps1 -PolicyName 'Reclassify Sim – <Label> – Locations' -EnforceFromSimulation
   -Commit`. This flips the accepted simulation policy to `Enable`, so the mapped target labels are now
   **actually applied** to the matching content — the reclassification.
2. Re-run `IPMIG-Validation.ps1 -SimReport -PolicyName '<name>'` and spot-check newly labeled items:
   the mapped label is applied, and any **encryption/marking** on the target label behaves as designed
   (co-authoring, access) — for encrypting labels, confirm an unauthorized user is denied.
3. Apply the **residual-marking reconciliation** decision (Requirement 2.8) for the pilot content.
4. **Pass/fail + rollback:** pilot content now carries the mapped Purview label; no surprise encryption
   or broken access. Rollback: return the policy to simulation
   (`IPMIG-Set-Migration.ps1 -PolicyName '<name>' -ReturnToSimulation -Commit`) — this stops further
   labeling; already-applied labels are reverted per your label-removal process (document it).

## Step 7 — Expand location-by-location and decommission the source tool (Expand)
1. With the pilot validated, widen each reclassification policy's **locations** to the next wave
   (`IPMIG-Set-Migration.ps1 -PolicyName '<name>' -AddSites <sites> -WhatIf` then `-Commit`), repeating
   the simulation → measure → enforce pattern per wave where a new location introduces new content
   patterns. Re-run `IPMIG-Report.ps1` after each wave.
2. Reconcile residual legacy markings per wave, and — once a population is fully reclassified and
   validated — **retire the source classification tool** for it per your decommission plan (Requirement
   2.8). Keep the source tool's export as migration evidence.
3. **Pass/fail:** the full in-scope estate carries mapped Purview labels, `Migration Coverage – Report`
   shows no unmapped in-scope value and no enforcing policy with poor precision, and the source tool is
   decommissioned on schedule.

---
### Order of operations
`Inventory legacy values + target estate → build mapping matrix + author detection SITs → dry-run
(-WhatIf) reclassification policies → create them in SIMULATION (pilot locations) → run simulation +
measure precision with the data owner → validate coverage + precision → enforce from simulation to
reclassify the pilot → expand location-by-location + reconcile markings + decommission the source tool`
