# 3. Implementation Guide — Automatic Sensitivity Labeling at Scale

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com`) and **Security & Compliance PowerShell** (`Connect-IPPSSession`).
Every write is run `-WhatIf` first, every service-side policy is **created in simulation**
(`TestWithoutNotifications`) and validated for precision **before** it is enforced, and enforcement is
**expanded by location** (pilot subset → tenant). Artifact names follow the
`AutoLabel <Type> – <Label> – <Workload/Stage>` convention from the Overview and are reused verbatim.
Portal paths are current at authoring — **verify in your tenant**, as the portal is evolving.

> **Model:** Assess the posture and confirm the labels exist, design the match conditions, configure
> client- and service-side auto-labeling in **simulation**, validate match precision, enforce on a
> **pilot location subset**, validate, then **expand tenant-wide (enforce at scale).**
> Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**
>
> **Prerequisite reminder (§2.1):** the labels you auto-apply must already exist and be published. This
> guide applies them automatically; it does not create them.

## Step 1 — Assess the auto-labeling posture (Assess)
1. Run `IPAUTO-Discovery.ps1` (read-only). It inventories the **existing sensitivity labels** (`Get-Label`) and which ones already carry **client-side auto-labeling** conditions, the **sensitivity label policies** (`Get-LabelPolicy`), and every **service-side auto-labeling policy with its mode** (`Get-AutoSensitivityLabelPolicy`) and its **rules** (`Get-AutoSensitivityLabelRule`).
2. Review the output: confirm the **target label exists and is published** (§2.1), and check whether any auto-labeling is already enforced so you don't collide or double-label.
3. **Gate:** you have a written baseline of existing labels + auto-labeling policies, and confirmed the target label (`Confidential \ All Employees`) exists, is published, and — if it encrypts — its protection already enforces.

## Step 2 — Design the match conditions (Design)
1. With the data owner, finalize per target label: the **sensitive info types / keywords / trainable classifiers**, the **minimum instance count and confidence**, and the **in-scope workloads** (SharePoint, OneDrive, Exchange) and any **exclusions** (§2.5, §2.6).
2. Decide the **pilot location subset** (the sites/mailboxes to enforce on first) and the eventual full scope, and the intended **behavior toward existing labels** (§2.8).
3. **Gate:** a signed-off condition sheet exists — label, conditions, thresholds, workloads, pilot subset, existing-label behavior — before any policy is created.

## Step 3 — Configure client-side auto-labeling (Configure, -WhatIf first)
1. Client-side auto-labeling is configured **on the label** itself (its "auto-labeling for files and emails" conditions) and surfaces to users through the label policy. Run `IPAUTO-AutoLabelConfig.ps1 -ClientSide -Label "Confidential \ All Employees" -Sit "<SIT name>" -MinCount <N> -Recommend -WhatIf`. It prints the `Set-Label` change it would make — setting the label's client-side auto-labeling conditions to *recommend* (user confirms) rather than silently apply, to start.
2. Review the change, then re-run with `-Commit`. Because it recommends, users are prompted (not surprised); you can switch to auto-apply later once behavior is trusted.
3. In the portal (**Information Protection → Labels → the label → Auto-labeling for files and emails**) confirm the condition is set. **Verify the exact path in your tenant.**
4. **Gate:** the label shows the client-side auto-labeling condition; a pilot user editing matching content sees the label **recommended** (validated in Testing §5).

## Step 4 — Create service-side auto-labeling **in simulation** — SharePoint/OneDrive (Configure / simulate)
1. Run `IPAUTO-AutoLabelConfig.ps1 -ServiceSide -PolicyName "AutoLabel Sim - Confidential - SPO+ODB" -RuleName "AutoLabel Rule - Confidential - SPO+ODB" -Label "Confidential \ All Employees" -Workload SharePoint,OneDrive -Sit "<SIT name>" -MinCount <N> -WhatIf`. It shows the `New-AutoSensitivityLabelPolicy` **in simulation mode** (`-Mode TestWithoutNotifications`) plus the `New-AutoSensitivityLabelRule` (the sensitive-info-type conditions) it would create. **No content is labeled in simulation.**
2. Review the `-WhatIf` output — confirm the mode is a `TestWithout...` (simulation) value, the label, the conditions/threshold, and the locations. Re-run with `-Commit` to create the simulation policy + rule.
3. **Gate:** `Get-AutoSensitivityLabelPolicy` shows the policy in a **simulation** mode; the rule exists with the intended conditions; nothing is enforced.

## Step 5 — Create service-side auto-labeling **in simulation** — Exchange (Configure / simulate)
1. If email is in scope, repeat Step 4 for Exchange: `IPAUTO-AutoLabelConfig.ps1 -ServiceSide -PolicyName "AutoLabel Sim - Confidential - Exchange" -RuleName "AutoLabel Rule - Confidential - Exchange" -Label "Confidential \ All Employees" -Workload Exchange -Sit "<SIT name>" -MinCount <N> -WhatIf`, review, then `-Commit`.
2. **Gate:** the Exchange simulation policy + rule exist in simulation mode; nothing is enforced.

## Step 6 — Let simulation run, then validate precision (Pilot / Validate)
1. Let the simulation scan the in-scope locations — it processes large volumes over time (**verify current throughput/limits for your tenant**).
2. Run `IPAUTO-SimulationReport.ps1 -PolicyName "AutoLabel Sim - Confidential - SPO+ODB"`. It confirms the policy is still in **simulation**, reports scan status, and points to the **items matched** — what *would* be labeled — for precision review.
3. Review the matches with the data owner for **false positives** (content that should **not** get the label) and **false negatives** (obvious content missed). If precision is poor, tune the **rule** conditions (tighter/different SITs, higher `-MinCount`, add keywords, or a trainable classifier) via `IPAUTO-AutoLabelConfig.ps1 -ServiceSide ... -UpdateRule -Commit`, and let simulation re-run. Iterate.
4. **Gate:** the simulation match set is **reviewed and accepted by the data owner**; false-positive rate is within the agreed threshold; behavior toward existing labels (§2.8) is confirmed. **Do not enforce until this gate passes.**

## Step 7 — Enforce on the pilot location subset (Pilot → Expand)
1. Once simulation is accepted, enforce **on the pilot subset only**: `IPAUTO-AutoLabelConfig.ps1 -ServiceSide -PolicyName "AutoLabel Sim - Confidential - SPO+ODB" -Enforce -Locations "<pilot sites>" -WhatIf`, review the `Set-AutoSensitivityLabelPolicy -Mode Enable` (scoped to the pilot locations) it would run, then `-Commit`.
2. Monitor the first enforcement window: run `IPAUTO-SimulationReport.ps1` and `IPAUTO-Reporting.ps1` and confirm labels are being applied on the pilot locations as simulation predicted — no unexpected encryption/marking.
3. **Gate:** enforced labels on the pilot subset match the accepted simulation; no surprises. Rollback: `IPAUTO-AutoLabelConfig.ps1 -ServiceSide -PolicyName "<name>" -BackToSimulation -Commit` returns the policy to simulation (stops labeling).

## Step 8 — Expand the scope tenant-wide (Expand / enforce at scale)
1. With the pilot enforcement validated, expand the location scope: `IPAUTO-AutoLabelConfig.ps1 -ServiceSide -PolicyName "AutoLabel Sim - Confidential - SPO+ODB" -Enforce -Locations All -WhatIf`, review, then `-Commit`. Repeat for the Exchange policy.
2. Optionally switch **client-side** auto-labeling from *recommend* to *auto-apply* (`IPAUTO-AutoLabelConfig.ps1 -ClientSide -Label "..." -AutoApply -Commit`) once the recommended behavior is trusted.
3. Run `IPAUTO-Reporting.ps1` on a cadence to confirm labeling coverage is climbing as expected, and `IPAUTO-ScopeHealth.ps1` to confirm policy distribution/scope health across the tenant.
4. **Gate:** all §5 tests pass; tenant-wide enforcement confirmed; labeling coverage reported; a rollback path is documented per policy.

---
### Order of operations
`Assess posture + confirm labels exist → Design match conditions → Configure client-side (recommend, -WhatIf → commit) → Create service-side SIMULATION policies (SPO/ODB, then Exchange) → Let simulation run → Validate precision → Enforce on PILOT location subset → Validate → Expand scope tenant-wide (enforce at scale) → Report + health-check`
