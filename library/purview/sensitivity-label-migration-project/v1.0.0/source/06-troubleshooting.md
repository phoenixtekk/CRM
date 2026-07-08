# 6. Troubleshooting — Sensitivity Label Migration Project (Microsoft Purview)

Common issues, grouped by step. Each has a **symptom**, the **likely cause**, and a **resolution**.
Every write in this solution is `-WhatIf` by default and every reclassification policy is created **in
simulation** first — `IPMIG-Discovery.ps1`, `IPMIG-Report.ps1`, `IPMIG-Scope-Health.ps1`, and
`IPMIG-Validation.ps1` are read-only; only `IPMIG-Set-Migration.ps1` writes, and it labels no content until
you enforce from simulation after precision sign-off. **Auto-labeling is E5-gated and reclassification is
not undone by one button — pilot in simulation and measure before enforcing.**

## Licensing & connectivity

**Symptom:** `Get-AutoSensitivityLabelPolicy` / `New-AutoSensitivityLabelPolicy` not found or errors.
**Likely cause:** service-side auto-labeling is licensing-gated (typically E5), or `ExchangeOnlineManagement`
isn't connected.
**Resolution:** `Install-Module ExchangeOnlineManagement`, `Connect-IPPSSession`, and **verify your
licensing/tenant** for service-side auto-labeling before Step 3. If unlicensed, that is a prerequisite gap,
not a script bug.

## Inventory & mapping (Steps 1–2)

**Symptom:** `IPMIG-Discovery.ps1` shows a legacy value with no matching target label or SIT.
**Likely cause:** the target taxonomy isn't published yet, or the detection SIT hasn't been authored.
**Resolution:** publish the target label (Requirement 2.2, its own taxonomy solution) and author the
detection SIT in the portal (`SIT – Legacy <Value> – Detect`) before Step 3. Confirm with
`IPMIG-Discovery.ps1`.

**Symptom:** a legacy value has no clean target label.
**Likely cause:** this is a mapping **owner decision**, not a technical gap.
**Resolution:** flag it explicitly in `Label Mapping Matrix – Design` and route it to the data owner — do
**not** guess a mapping. `IPMIG-Scope-Health.ps1` will keep flagging it until resolved.

## Creating simulation policies (Step 3)

**Symptom:** `IPMIG-Set-Migration.ps1` skips a mapping row with "target label not found" / "detection SIT not found".
**Likely cause:** the CSV references a label or SIT that doesn't exist (name mismatch or not yet created).
**Resolution:** fix the `mapping.csv` name to match exactly, or create/publish the object first. The guard is
intentional — it won't build a policy on a missing object.

**Symptom:** nothing was created.
**Likely cause:** `-Commit` was omitted (default is `-WhatIf`).
**Resolution:** review the previewed `New-AutoSensitivityLabelPolicy/Rule` lines, then re-run with `-Commit`.
Policies are created in **simulation** (`TestWithoutNotifications`) only.

## Running simulation & measuring precision (Step 4)

**Symptom:** simulation shows few/no matches after creation.
**Likely cause:** service-side scanning processes volume over time; the scan hasn't completed, or the
detection SIT is too tight.
**Resolution:** allow time (verify current scan limits for your tenant) and re-check with
`IPMIG-Validation.ps1 -SimReport`. If the SIT truly misses legacy-marked content (false negatives), loosen
the regex / lower instance count in the portal and re-simulate — do **not** enforce to compensate.

**Symptom:** the per-item match set isn't in the script output.
**Likely cause:** the detailed simulated match set lives in the portal, not a public cmdlet.
**Resolution:** open **Information Protection → Auto-labeling → [policy] → Simulation** to sample matches for
false positives with the data owner. `IPMIG-Validation.ps1` reports mode/status/config and points you there.

**Symptom:** false-positive rate is too high.
**Likely cause:** the detection SIT is too broad (matches look-alike content).
**Resolution:** tune the SIT (tighter regex, higher instance count, supporting keywords) in the portal and
re-simulate. Precision sign-off by the data owner is the **gate before enforcement**.

## Coverage & health (Step 5)

**Symptom:** `IPMIG-Report.ps1` shows `LabelExists=MISSING` though the label seems to exist.
**Likely cause:** name mismatch (DisplayName vs Name), or the label exists but isn't **published**.
**Resolution:** match the exact label name in the CSV; confirm the label is **published** in
**Label policies** (published-scope is portal-authoritative — the report notes this).

**Symptom:** `IPMIG-Scope-Health.ps1` flags a policy "ENFORCING before sign-off".
**Likely cause:** a reclassification policy is in `Enable` mode without recorded precision sign-off.
**Resolution:** confirm the data owner signed off (Step 4/5); once recorded, re-run with `-AllowEnforced`, or
return the policy to simulation (`IPMIG-Set-Migration.ps1 -PolicyName '<name>' -ReturnToSimulation -Commit`).

## Enforcing & rollback (Steps 6–7)

**Symptom:** after enforcing, users hit unexpected encryption / access denial.
**Likely cause:** the target label applies encryption that the legacy tool did not — a protection-intent
difference (Requirement 2.1 note).
**Resolution:** confirm the protection intent per label was reviewed as a records/security decision before
enforcing. Rollback: `IPMIG-Set-Migration.ps1 -PolicyName '<name>' -ReturnToSimulation -Commit` stops further
labeling; already-applied labels are reverted per your documented label-removal process.

**Symptom:** you need to widen locations.
**Resolution:** `IPMIG-Set-Migration.ps1 -PolicyName '<name>' -AddSites <sites> -WhatIf` then `-Commit`;
re-simulate for a wave whose new location introduces new content patterns before enforcing it.

## What this solution does NOT decide
Whether a target label's **protection intent** correctly reproduces the legacy tool's protection, the
**acceptable false-positive threshold**, and **when to decommission** the source tool are
**records / security / data-owner determinations** (Requirement 2.1, 2.8). This solution delivers the
mapping, detection, simulation evidence, and the enforced reclassification — not the determination.
