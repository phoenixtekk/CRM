# 5. Testing & Validation Guide — Sensitivity Label Migration Project

Run these tests after the Implementation Guide, **in order**. Each has an explicit **pass/fail** signal
and a rollback. Do not enforce a reclassification policy, and do not expand from the pilot locations,
until the relevant tests pass. All checks use the Purview portal and Security & Compliance PowerShell —
the provided scripts automate the read-only ones.

> **Reminder:** whether a mapped label should **encrypt**, and whether a legacy value is a "record," are
> records/security/legal determinations from §2 — you are validating that the **mapping and
> reclassification behave as specified**, not deciding the target protection.

## Test 1 — Both sides inventoried and cross-referenced
- **How:** `IPMIG-Discovery.ps1 -LegacyCsv .\LegacyValues.csv -CsvFolder .\out`.
- **Pass:** every distinct legacy value from the source export is listed, and for each the report shows
  whether a target label and a detection SIT already exist — the full baseline.
- **Fail:** the legacy CSV is incomplete, or target labels are missing (build/publish them first, §2.2)
  → fix the inputs and re-run.

## Test 2 — Mapping matrix is complete
- **How:** review `Label Mapping Matrix – Design` with `IPMIG-Scope-Health.ps1 -MappingCsv .\mapping.csv`.
- **Pass:** every **in-scope** legacy value maps to exactly one existing, published target label and
  names a detection SIT; every unmapped value is flagged as an explicit owner decision.
- **Fail:** any in-scope value with no target, a mapping to a non-existent label, or a duplicate/
  ambiguous mapping → resolve with the owner before configuring.

## Test 3 — Detection SITs exist and match a sample
- **How:** `Get-DlpSensitiveInformationType | Where-Object Name -like 'SIT - Legacy*'`, then test each SIT
  against a **sample legacy-marked item** (portal test pane, or apply the SIT in a test).
- **Pass:** every `SIT – Legacy <Value> – Detect` exists and fires on a genuinely legacy-marked sample,
  and does **not** fire on clearly unmarked content.
- **Fail:** a SIT is missing, or does not detect the legacy marking (the value may be in an opaque store,
  §2.4) → re-author the SIT, or escalate the value as undetectable (manual/source remediation).

## Test 4 — Reclassification policies are created in simulation only
- **How:** `IPMIG-Validation.ps1 -Full`, or `Get-AutoSensitivityLabelPolicy | Format-Table Name,Mode`.
- **Pass:** every `Reclassify Sim – <Label> – Locations` policy is in a **simulation** mode
  (`TestWithoutNotifications`), scoped to the **pilot locations**, applying the **mapped** label — and
  **nothing has been labeled**.
- **Fail:** a policy is enforcing before sign-off, or scoped tenant-wide → return it to simulation
  (`-ReturnToSimulation`) / re-scope before proceeding.

## Test 5 — Simulation has scanned and produced a match report
- **How:** `IPMIG-Validation.ps1 -SimReport -PolicyName 'Reclassify Sim – <Label> – Locations'`.
- **Pass:** the policy has scanned the in-scope locations and produced a match set — the **preview** of
  what it would reclassify — with **no content actually labeled**.
- **Fail:** no results yet (allow scan time; confirm the locations contain matching content) or the
  policy is not in simulation → investigate before measuring precision.

## Test 6 — Reclassification precision is acceptable (the enforcement gate)
- **How:** review the `IPMIG-Validation.ps1 -SimReport` match set with the **data owner**; sample matched
  items for false positives and estimate false negatives against the legacy inventory.
- **Pass:** the false-positive rate is within the agreed threshold, coverage of known legacy-marked
  content is acceptable, and the data owner **accepts the match set** for enforcement.
- **Fail:** too many wrong-label matches, or too much legacy content missed → tune the detection SIT
  (tighter regex, higher instance counts, keywords/classifier) in the portal, re-run simulation,
  re-review. **This is the gate before any enforcement.**

## Test 7 — Enforced reclassification matches the accepted simulation
- **How:** after `-EnforceFromSimulation` (Step 6), re-run `IPMIG-Validation.ps1 -SimReport` and
  spot-check newly labeled items.
- **Pass:** the mapped target label is applied to the same content simulation predicted; nothing outside
  the accepted match set was labeled.
- **Fail:** divergence or unexpected labeling → return the policy to simulation (`-ReturnToSimulation`)
  and investigate before continuing.

## Test 8 — Encryption/marking on a mapped label behaves as designed
- **How:** for any mapped label that **encrypts**, take a reclassified test item and attempt to open it
  as a user **outside** the label's rights; confirm content marking (header/footer/watermark) appears.
- **Pass:** the unauthorized user is **denied**; authorized rights behave as defined; marking appears
  where configured — the reclassification's protection is correct.
- **Fail:** unauthorized access succeeds, co-authoring breaks unexpectedly, or marking is wrong → the
  target label's protection is misconfigured. **Halt broad enforcement** of encrypting mappings until
  fixed (this is why encryption is piloted).

## Test 9 — Residual legacy marking is reconciled as decided
- **How:** inspect reclassified pilot content for the **old** legacy marking and confirm it matches the
  §2.8 reconciliation decision (left, co-existing, or cleaned up).
- **Pass:** content carries the intended Purview label and the residual legacy marking is in the agreed
  end state — no undocumented double-marking.
- **Fail:** unexpected double-marking or a lost marking → apply the reconciliation step / revisit the
  decision with the content owner.

## Test 10 — Coverage & mapping-health check before expansion
- **How:** `IPMIG-Report.ps1 -MappingCsv .\mapping.csv -CsvPath .\MigrationCoverage.csv` and
  `IPMIG-Scope-Health.ps1 -MappingCsv .\mapping.csv`.
- **Pass:** every in-scope legacy value is mapped + detected; no mapping references a missing SIT/label;
  every policy is either still in simulation or enforcing **with signed-off precision** — all green.
- **Fail:** any unmapped in-scope value, missing object, or a policy enforcing without precision sign-off
  → resolve before widening locations.

---
### Exit criteria (all must be true before broad enforcement)
`Both sides inventoried · mapping matrix complete · detection SITs exist and match · policies created in
simulation only · simulation scanned + match report produced · precision accepted by the data owner ·
enforced == accepted simulation · encryption/marking correct · residual markings reconciled · coverage +
health check green · rollback (return-to-simulation / remove-policy) documented per policy`
