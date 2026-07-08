# 3. Implementation Guide — Sensitivity & Retention Labels

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com`) and **Security & Compliance PowerShell** (`Connect-IPPSSession`).
Every write is run `-WhatIf` first, every high-impact policy is **piloted in a small ring**, and
**service-side auto-labeling is created in simulation** before it is ever enforced. Artifact names
follow the `<Type> <Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim.
Portal paths are current at authoring — **verify in your tenant**, as the portal is evolving.

> **Model:** Assess the posture, design the taxonomy, publish sensitivity labels to a **pilot ring**,
> auto-label in **simulation**, validate accuracy, build retention labels + adaptive scopes, validate,
> then **expand and enforce.** Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate →
> Expand (enforce).**
>
> **Records/legal deferral:** the retention periods and disposition actions below are **placeholders**
> — confirm each with your records/legal owner before enforcing (see §2 deferral note).

## Step 1 — Assess the current label posture (Assess)
1. Run `PURVLABEL-Discovery.ps1` (read-only). It inventories existing **sensitivity labels** (`Get-Label`), **sensitivity label policies** (`Get-LabelPolicy`), **auto-labeling policies** and their mode (`Get-AutoSensitivityLabelPolicy`), **retention labels** (`Get-ComplianceTag`), **retention policies** (`Get-RetentionCompliancePolicy`), and **adaptive scopes** (`Get-AdaptiveScope`).
2. Review the output: which labels already exist, whether any auto-labeling is already enforced, and whether encryption is already in use. This is your baseline — **do not** duplicate or collide with existing labels.
3. **Gate:** you have a written baseline of every existing label/policy/scope and confirmed no name collisions with the taxonomy you are about to build.

## Step 2 — Design and record the taxonomy (Design)
1. With your governance owners, finalize the sensitivity taxonomy (order least → most sensitive) and the retention taxonomy, using the sample in the Overview as a starting point. Record for **each label**: display name, tooltip, whether it protects (and the exact encryption/marking/rights), and for retention labels the **period + action** (records/legal sign-off).
2. Decide the pilot ring (the group backing `SL Policy – Pilot – Ring1`) and the auto-labeling conditions (sensitive info types / keywords / classifiers) per §2.4.
3. **Gate:** a signed-off taxonomy sheet exists — names, protection, periods, and pilot scope — before any label is created.

## Step 3 — Build the sensitivity labels (Configure, -WhatIf first)
1. Run `PURVLABEL-SensitivityConfig.ps1 -WhatIf` (the default). It prints exactly which labels it would create with `New-Label` — parents (`Confidential`, `Highly Confidential`), sublabels with protection (`Confidential \ All Employees`, etc.), content marking, and encryption/rights — **without making changes**.
2. Review every line: confirm each encrypting label's rights definition targets the correct group (§2.6) and the label order matches the signed-off taxonomy.
3. Re-run `PURVLABEL-SensitivityConfig.ps1 -Commit` to create the labels. Encryption and content marking are set on the labels but **not yet visible to anyone** — labels only appear once published (Step 4).
4. **Gate:** `Get-Label` shows every taxonomy label with the intended protection; none is published yet.

## Step 4 — Publish sensitivity labels to the pilot ring (Pilot)
1. Run `PURVLABEL-SensitivityConfig.ps1 -PublishPolicy -PolicyName "SL Policy – Pilot – Ring1" -PilotGroup "<pilot-group>" -WhatIf`. It shows the `New-LabelPolicy` it would run — publishing the ordered label set to the pilot group only.
2. Re-run with `-Commit` to create `SL Policy – Pilot – Ring1`. Client-side auto-labeling settings (recommend/auto-apply on the label) surface through this policy for pilot users.
3. In the Purview portal (**Information Protection → Label policies**) confirm the policy is published to the pilot group and the labels appear in Office for a pilot user (allow time for client sync).
4. **Gate:** pilot users see the labels in Word/Excel/PowerPoint/Outlook; an encrypting label, applied by a pilot user, actually protects the file (open as an unauthorized user → access denied). Rollback: `Remove-LabelPolicy "SL Policy – Pilot – Ring1"` unpublishes without deleting the labels.

## Step 5 — Configure service-side auto-labeling **in simulation** (Pilot / simulate)
1. Run `PURVLABEL-SensitivityConfig.ps1 -AutoLabel -AutoLabelName "AL Sim – Financial – SPO+ODB" -ApplyLabel "Confidential \ All Employees" -WhatIf`. It shows the `New-AutoSensitivityLabelPolicy` **in simulation mode** (`-Mode TestWithoutNotifications`) plus the `New-AutoSensitivityLabelRule` (the sensitive-info-type conditions) it would create for SharePoint/OneDrive. **No content is labeled in simulation.**
2. Re-run with `-Commit` to create the simulation policy. Repeat for the Exchange policy (`AL Sim – Financial – Exchange`) if email is in scope.
3. Let the simulation run (it scans in-scope locations over time — **verify current throughput/limits for your tenant**).
4. **Gate:** the auto-labeling policy exists in **simulation** (never enforced yet) and has started scanning — verified in Step 6.

## Step 6 — Validate the simulation match report (Validate)
1. Run `PURVLABEL-SimulationReport.ps1 -PolicyName "AL Sim – Financial – SPO+ODB"`. It reports the policy **simulation status/progress** and the **items matched** — what *would* be labeled — so you can measure precision.
2. Review the matches for false positives (content that should **not** get the label). If precision is poor, tune the auto-labeling **rule** conditions (tighter sensitive info types / higher instance counts / add keywords) and let simulation re-run. Iterate until accuracy is acceptable.
3. **Gate:** the simulation match set is reviewed and accepted by the data owner; false-positive rate is within your agreed threshold. Do **not** proceed to enforce until this gate passes.

## Step 7 — Enforce auto-labeling (Expand)
1. Once simulation is accepted, turn the policy on: `PURVLABEL-SensitivityConfig.ps1 -AutoLabel -AutoLabelName "AL Sim – Financial – SPO+ODB" -EnforceFromSimulation -WhatIf`, review, then `-Commit`. This flips the policy `-Mode` from simulation to **Enable** — now matching content is actually labeled.
2. Monitor the first enforcement window and confirm labels are being applied as the simulation predicted (re-run `PURVLABEL-SimulationReport.ps1` and spot-check items).
3. **Gate:** enforced labels match the accepted simulation; no unexpected encryption/marking. Rollback: set the policy back to simulation/disabled via the same script with `-DisableAutoLabel`.

## Step 8 — Build retention labels (Configure, -WhatIf first)
1. Run `PURVLABEL-RetentionConfig.ps1 -WhatIf`. It shows the `New-ComplianceTag` calls for each retention label (`Business-General-3yr`, `Financial-Records-7yr`, `Transitory-1yr`, `Legal-Reference`) — with the **period and action confirmed by records/legal** (§2 deferral).
2. Review each: retention action (Keep / Delete / Keep-and-Delete / disposition review), duration, and duration trigger (creation vs modification). **Do not** mark anything as a *record* unless records/legal has declared it so.
3. Re-run with `-Commit` to create the retention labels. They exist but are **not published** yet.
4. **Gate:** `Get-ComplianceTag` lists every retention label with the signed-off period/action; none is published.

## Step 9 — Build the adaptive scopes (Configure, -WhatIf first)
1. Confirm the adaptive-scope query attributes are populated (§2.7).
2. Run `PURVLABEL-RetentionConfig.ps1 -AdaptiveScope -ScopeName "Scope – Users – Finance" -ScopeType User -Query 'Department -eq "Finance"' -WhatIf`, review the `New-AdaptiveScope` it would run, then `-Commit`. Repeat for site scopes (`Scope – Sites – Records`, `-ScopeType Site`) as needed.
3. Run `PURVLABEL-Validation.ps1 -ScopeName "Scope – Users – Finance"` to **preview scope membership** and confirm it resolves the expected population (not empty, not the whole tenant).
4. **Gate:** each adaptive scope resolves the intended, non-empty membership and matches the coverage assumption from §2.7.

## Step 10 — Publish retention labels to a pilot, then by adaptive scope (Pilot → Expand)
1. **Pilot first:** run `PURVLABEL-RetentionConfig.ps1 -PublishRetention -PolicyName "RL Publish – Pilot – Ring1" -PilotGroup "<pilot-group>" -Labels "Business-General-3yr" -WhatIf`, review the `New-RetentionCompliancePolicy` + `New-RetentionComplianceRule -PublishComplianceTag`, then `-Commit`. Confirm pilot users can apply the label in Office/SharePoint.
2. **Then adaptive:** run `PURVLABEL-RetentionConfig.ps1 -PublishRetention -PolicyName "RL Publish – Adaptive – FinanceUsers" -AdaptiveScopeName "Scope – Users – Finance" -Labels "Financial-Records-7yr" -WhatIf`, review, then `-Commit`. The policy binds the label to the adaptive scope and re-evaluates membership automatically.
3. **Gate:** pilot users see and can apply the retention label; the adaptive policy shows the correct scope bound. For any label with a **delete** action, confirm the disposition behavior in a controlled test item before broad reliance. Rollback: `Remove-RetentionCompliancePolicy "<policy>"` unpublishes without deleting the labels.

## Step 11 — Validate end to end and expand (Validate → Expand)
1. Run `PURVLABEL-Validation.ps1 -Full` — it re-checks label/policy health: labels published, auto-labeling enforced and matching simulation, retention policies bound to the right scopes, and adaptive scope membership healthy.
2. Complete the **Testing Guide (§5)**. Only after every gate passes, expand the sensitivity label policy from `SL Policy – Pilot – Ring1` to `SL Policy – Broad – AllUsers` (re-publish to all users) and widen auto-labeling/retention scopes as agreed.
3. **Gate:** all §5 tests pass; broad publish confirmed; a rollback path is documented for each policy.

---
### Order of operations
`Assess posture → Design taxonomy → Build sensitivity labels (-WhatIf → commit) → Publish to pilot ring → Auto-label in SIMULATION → Validate match report → Enforce auto-label → Build retention labels → Build adaptive scopes → Publish retention (pilot → adaptive) → Validate → Expand/enforce broadly`
