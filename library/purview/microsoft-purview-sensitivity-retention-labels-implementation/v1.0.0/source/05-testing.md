# 5. Testing & Validation Guide — Sensitivity & Retention Labels

Run these tests after the Implementation Guide, **in order**. Each has an explicit **pass/fail** signal
and a rollback. Do not expand from the pilot ring, and do not enforce auto-labeling, until the
relevant tests pass. All checks use the Purview portal and Security & Compliance PowerShell — the
provided scripts automate the read-only ones.

> **Reminder:** retention periods/actions under test are the records/legal determinations from §2 —
> you are validating that the configuration *behaves as specified*, not deciding the schedule.

## Test 1 — Taxonomy created as designed
- **How:** `PURVLABEL-Discovery.ps1`, or `Get-Label | Format-Table DisplayName,ParentId` and `Get-ComplianceTag | Format-Table Name,RetentionAction,RetentionDuration`.
- **Pass:** every sensitivity label (parents + sublabels, correct order) and every retention label from the signed-off taxonomy exists with the intended protection and period/action.
- **Fail:** missing/extra labels, wrong order, or wrong protection → fix in `PURVLABEL-SensitivityConfig.ps1` / `PURVLABEL-RetentionConfig.ps1` and re-run.

## Test 2 — Sensitivity labels visible to pilot users
- **How:** as a **pilot** user, open Word/Excel/PowerPoint and Outlook; check the Sensitivity button lists the labels. Confirm a **non-pilot** user does **not** see them.
- **Pass:** pilot users see the full ordered label set; non-pilot users see nothing (publish is scoped).
- **Fail:** labels missing for pilot users (allow client sync time) or visible to non-pilot users (policy scope wrong) → re-check `SL Policy – Pilot – Ring1` targeting.

## Test 3 — Encryption/protection actually enforces
- **How:** as a pilot user, apply `Confidential \ Trusted People` (or `Highly Confidential \ Specified People`) to a test document. Attempt to open it as a user **outside** the rights definition.
- **Pass:** the unauthorized user is **denied**; the authorized rights (e.g. Co-Author vs View-only) behave as defined; content marking (header/footer/watermark) appears where configured.
- **Fail:** unauthorized access succeeds, or rights are wrong → the protection service or the label's `EncryptionRightsDefinitions` is misconfigured (§2.6). **Do not publish broadly** until fixed.

## Test 4 — Client-side auto-labeling recommends/applies correctly
- **How:** as a pilot user, create a document containing a matching sensitive info type (e.g. test financial data). Observe whether the label is recommended or auto-applied per the label's configuration.
- **Pass:** the intended label is recommended/applied for matching content and **not** for clearly non-matching content.
- **Fail:** over- or under-labeling → tune the label's auto-labeling conditions and re-test.

## Test 5 — Service-side auto-labeling stays in simulation until accepted
- **How:** `PURVLABEL-SimulationReport.ps1 -PolicyName "AL Sim – Financial – SPO+ODB"`; confirm the policy **Mode** is a simulation/test mode, not Enable.
- **Pass:** the policy is in simulation, has scanned in-scope locations, and produced a match report — **no content was actually labeled**.
- **Fail:** the policy is enforcing before sign-off, or has not scanned → set it back to simulation (`-DisableAutoLabel`) / allow scan time.

## Test 6 — Simulation precision is acceptable before enforcement
- **How:** review the `PURVLABEL-SimulationReport.ps1` match set with the data owner; sample matched items for false positives.
- **Pass:** the false-positive rate is within the agreed threshold and the data owner accepts the match set.
- **Fail:** too many false positives → tune the auto-labeling rule conditions, re-run simulation, re-review. **This is the gate before Step 7 enforcement.**

## Test 7 — Enforced auto-labeling matches the accepted simulation
- **How:** after enforcing (Step 7), re-run `PURVLABEL-SimulationReport.ps1` and spot-check newly labeled items.
- **Pass:** enforced labels match what simulation predicted; no unexpected encryption or marking on user content.
- **Fail:** divergence or surprise protection → roll the policy back to simulation/disabled (`-DisableAutoLabel`) and investigate.

## Test 8 — Adaptive scope resolves the right membership
- **How:** `PURVLABEL-Validation.ps1 -ScopeName "Scope – Users – Finance"` (previews membership) or the portal scope preview.
- **Pass:** the scope resolves the expected, **non-empty** population and does not accidentally include the whole tenant; membership matches the §2.7 coverage assumption.
- **Fail:** empty, too broad, or missing expected members → fix the query or backfill the attribute (§2.7), re-preview.

## Test 9 — Retention label publishes and applies (pilot)
- **How:** as a pilot user, apply `Business-General-3yr` to a test item in SharePoint/Outlook; confirm it appears and is recorded.
- **Pass:** the retention label is available to pilot users and applies to content; the item shows the label.
- **Fail:** label not offered → re-check `RL Publish – Pilot – Ring1` scope and label publishing rule.

## Test 10 — Retention *behavior* is safe (controlled disposition test)
- **How:** for any retention label with a **delete** action, apply it to a **disposable test item** with a short/adjusted trigger in a controlled area (never production records) and confirm the disposition/disposition-review behaves as specified.
- **Pass:** at end of period the item is retained/disposed/sent to review exactly as the records/legal determination specifies.
- **Fail:** unexpected deletion or no disposition → **halt broad reliance**, review the label action/trigger with records/legal before enforcing anywhere real.

## Test 11 — Full health check before expansion
- **How:** `PURVLABEL-Validation.ps1 -Full`.
- **Pass:** labels published to intended scopes, auto-labeling enforced == accepted simulation, retention policies bound to correct static/adaptive scopes, adaptive membership healthy — all green.
- **Fail:** any red → resolve before publishing `SL Policy – Broad – AllUsers` or widening retention/auto-label scope.

---
### Exit criteria (all must be true before broad enforcement)
`Taxonomy built as designed · pilot users see labels · encryption enforces · simulation precision accepted · enforced == simulation · adaptive scopes resolve correctly · retention applies + disposition safe · full health check green · rollback documented per policy`
