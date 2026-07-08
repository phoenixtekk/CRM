# 5. Testing & Validation Guide — Automatic Sensitivity Labeling at Scale

Run these tests after the Implementation Guide, **in order**. Each has an explicit **pass/fail** signal
and a rollback. Do not enforce a service-side policy, and do not expand from the pilot location subset,
until the relevant tests pass. All checks use the Purview portal and Security & Compliance PowerShell —
the provided scripts automate the read-only ones.

> **Reminder:** you are validating that auto-labeling *behaves as specified and applies the right label
> accurately* — not deciding which content is sensitive (that classification is the data owner's
> determination, §2 deferral).

## Test 1 — Target labels exist and are publishable
- **How:** `IPAUTO-Discovery.ps1`, or `Get-Label | Format-Table DisplayName,Name` and `Get-LabelPolicy`.
- **Pass:** the label to be auto-applied (`Confidential \ All Employees`) exists, is published, and — if it encrypts — its protection already enforces (§2.1).
- **Fail:** label missing or unpublished → stop; complete the labels prerequisite before auto-labeling.

## Test 2 — Client-side auto-labeling recommends correctly
- **How:** as a **pilot** user, create a document/email containing content that matches the rule (e.g. test data with the configured SIT). Observe whether the label is **recommended**.
- **Pass:** the intended label is recommended for matching content and **not** for clearly non-matching content; the user is prompted (not silently overridden).
- **Fail:** over- or under-recommending → tune the label's client-side auto-labeling conditions (`Set-Label` via `IPAUTO-AutoLabelConfig.ps1 -ClientSide ... -Commit`) and re-test.

## Test 3 — Service-side policy is created in simulation (not enforcing)
- **How:** `IPAUTO-SimulationReport.ps1 -PolicyName "AutoLabel Sim - Confidential - SPO+ODB"` (and the Exchange policy); confirm **Mode** is a `TestWithout/WithNotifications` (simulation) value, not `Enable`.
- **Pass:** each policy is in **simulation**, has begun scanning its in-scope locations, and has **labeled nothing**.
- **Fail:** a policy is already `Enable` before sign-off → return it to simulation (`IPAUTO-AutoLabelConfig.ps1 -ServiceSide ... -BackToSimulation -Commit`) and investigate why.

## Test 4 — Simulation has scanned and produced a match set
- **How:** `IPAUTO-SimulationReport.ps1 -PolicyName "AutoLabel Sim - Confidential - SPO+ODB"`; check scan/deployment status and the matched-items pointer.
- **Pass:** the simulation has progressed and there is a reviewable match set (what *would* be labeled).
- **Fail:** no results yet → allow scan time (service-side scanning is not instant and is subject to limits — **verify limits for your tenant**); confirm the in-scope locations actually contain matching content.

## Test 5 — Simulation precision is acceptable (the enforcement gate)
- **How:** review the simulation match set with the **data owner**; sample matched items for false positives and spot-check obvious sensitive content for false negatives.
- **Pass:** the false-positive rate is within the agreed threshold **and** the data owner accepts the match set; behavior toward already-labeled content (§2.8) is as intended.
- **Fail:** too many false positives / misses → tune the rule conditions (`-UpdateRule -Commit`), re-run simulation, re-review. **This is the gate before any enforcement.**

## Test 6 — Existing/manual labels are handled as intended
- **How:** in the simulation match set, inspect items that **already carry a label**. Confirm the policy's behavior toward them matches the §2.8 decision (e.g. it does not lower a higher-priority manual label).
- **Pass:** already-labeled content is treated exactly as decided; no deliberate manual classification is silently overwritten.
- **Fail:** unexpected override/no-op → adjust the behavior setting (**verify the setting in your tenant**), re-simulate, re-review.

## Test 7 — Enforcement on the pilot subset matches the accepted simulation
- **How:** after enforcing on the pilot locations (Step 7), run `IPAUTO-SimulationReport.ps1` and `IPAUTO-Reporting.ps1` and spot-check newly labeled items on those locations.
- **Pass:** enforced labels on the pilot subset match what simulation predicted; no unexpected encryption or content marking on user content.
- **Fail:** divergence or surprise protection → roll the policy back to simulation (`-BackToSimulation -Commit`) and investigate before expanding.

## Test 8 — Scope and policy health are green
- **How:** `IPAUTO-ScopeHealth.ps1 -PolicyName "AutoLabel Sim - Confidential - SPO+ODB"`.
- **Pass:** the policy's locations resolve as intended (pilot subset, or `All` after expansion), no unintended inclusions/exclusions, and distribution/deployment status is healthy.
- **Fail:** wrong locations or a distribution error → correct the scope (`-Enforce -Locations ...`) or investigate the distribution status; re-check.

## Test 9 — Tenant-wide labeling coverage is climbing (at scale)
- **How:** after expanding to `All` (Step 8), run `IPAUTO-Reporting.ps1` on a cadence to report labeled-item activity/coverage.
- **Pass:** the volume of auto-applied labels grows and stabilizes across workloads, consistent with the accepted simulation precision — content is being labeled **without the user**.
- **Fail:** flat/zero coverage → confirm enforcement mode, locations, and that matching content exists; re-check scan limits for your tenant.

## Test 10 — Rollback works
- **How:** on a test policy, run `IPAUTO-AutoLabelConfig.ps1 -ServiceSide -PolicyName "<name>" -BackToSimulation -Commit`.
- **Pass:** the policy returns to simulation and stops labeling; existing labels already applied remain (auto-labeling does not un-label on rollback) — confirm this is understood.
- **Fail:** policy stays enforcing → verify the `Set-AutoSensitivityLabelPolicy -Mode` change and role/permissions.

---
### Exit criteria (all must be true before tenant-wide enforcement)
`Target labels exist + publishable · client-side recommends accurately · service-side created in SIMULATION · simulation scanned + match set produced · precision accepted by data owner · existing-label behavior correct · pilot enforcement == accepted simulation · scope/health green · coverage climbing at scale · rollback proven`
