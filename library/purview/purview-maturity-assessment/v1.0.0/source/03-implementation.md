# 3. Implementation Guide — Microsoft Purview Maturity Assessment

Follow these steps **in order**. The assessment runs mostly in the **Microsoft Purview portal**
(`https://purview.microsoft.com`) and in **Security & Compliance PowerShell** / **Microsoft Graph**;
the optional quick-win baseline (Steps 7–9) makes changes and is **piloted in simulation/test first**.

> **Model:** Gather evidence across all ten domains (Assess), score against the rubric (Score), agree
> target levels and sequence the gaps (Design), apply any quick-win baseline in simulation/test
> (Configure → Pilot), validate, then expand/enforce. Pattern: Assess → Design → Configure → Pilot
> (simulate) → Validate → Expand.

The named objects below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| Maturity model (rubric) | `Purview Maturity Model - 10 Domains x 6 Levels` |
| Scored output | `Purview Maturity Scorecard` |
| Roadmap | `Purview Maturity Roadmap - 3 Horizons` (Now 0–3 mo · Next 3–6 mo · Later 6–12 mo) |
| Pilot scope group | `Purview - Pilot Users` |
| Quick-win baseline (piloted in test) | `Sensitivity Label - Confidential - Baseline`, `DLP Policy - Baseline PII - Test`, unified audit enabled |

## Step 1 — Confirm the model, targets, and weighting (Design)
1. Adopt `Purview Maturity Model - 10 Domains x 6 Levels` (Solution Overview) as the default.
2. With the compliance, security, records, HR, and legal owners, set each domain's **target level**
   (L0–L5) and its **weight** in the overall band. Record this one-pager — it is Requirement 2.3.
3. Note any domain whose ceiling is capped by licensing (Requirement 2.2) so the roadmap treats the
   license as a dependency, not a config task.

## Step 2 — Verify read access and health (Assess)
1. Run `PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck`.
2. Confirm it reports successful `Connect-IPPSSession` / `Connect-MgGraph`, the account's roles, and
   which domains are **readable**. A domain the account cannot read must be fixed (Requirement 2.1)
   before scoring, or it will false-score as `L0 Absent`.
3. **Pass/fail:** all ten domains readable, or a documented reason (licensing/role) for each that is
   not.

## Step 3 — Gather evidence across all ten domains (Assess)
1. Run `PURVIEW-Discovery.ps1`. It inventories, per domain:
   - **D1** sensitivity labels + label/auto-labeling policies (`Get-Label`, `Get-LabelPolicy`,
     `Get-AutoSensitivityLabelPolicy`)
   - **D2** DLP policies and their mode (test vs enforce) (`Get-DlpCompliancePolicy`)
   - **D3** retention labels/policies and records config (`Get-ComplianceTag`,
     `Get-RetentionCompliancePolicy`)
   - **D4** insider-risk policy presence (portal signal — HR/legal-gated; presence only, no case data)
   - **D5** communication-compliance policy presence (portal signal — HR/legal-gated; presence only)
   - **D6** unified audit log on/off and Audit Premium signal (`Get-AdminAuditLogConfig` /
     `Get-OrganizationConfig` where available)
   - **D7** eDiscovery cases/holds presence (`Get-ComplianceCase`)
   - **D8** DSPM presence/recommendations signal (portal / Graph where available — flag preview)
   - **D9** Data Governance / Unified Catalog registration signal (Graph where available)
   - **D10** Compliance Manager assessments/score signal (portal / Graph where available)
2. Where an API or portal path is uncertain or plan-gated, the report marks the domain
   **"verify your licensing/tenant"** rather than asserting a value.
3. **Pass/fail:** the discovery output lists a signal (or an explicit "unreadable/unlicensed") for each
   of the ten domains.

## Step 4 — Score each domain against the rubric (Score)
1. Run `PURVIEW-MaturityScore.ps1`. It applies the model's per-domain rubric to the discovery evidence
   and emits the `Purview Maturity Scorecard`. The rubric, applied uniformly to every domain:

   | Level | Evidence signal (generalized) |
   |---|---|
   | L0 Absent | Capability not present / not licensed |
   | L1 Initial | Present but ad hoc — objects exist with no policy scope, owner, or documentation |
   | L2 Developing | Basic config piloted in **test/simulation**, limited scope (one workload / pilot group) |
   | L3 Defined | Standardized and **enforced** at meaningful scope, documented, owner assigned |
   | L4 Managed | Measured/reported, tuned on metrics, integrated (e.g. audit→SIEM), reviewed on a cadence |
   | L5 Optimized | Automated, continuously improved, org-wide, evidence-driven |

2. Each domain gets a 0–5 score **with the specific signal behind it** (e.g. "D2 = L2: one DLP policy,
   Exchange-only, in Test mode"). The overall band is the **weighted average** of the ten domain
   scores, mapped to the same L0–L5 labels.
3. Domains capped by licensing are scored against their **achievable** ceiling and flagged, so the
   overall band is not unfairly depressed by an unlicensable capability.
4. **Pass/fail:** every domain has a score and an evidence sentence; the overall band is computed.

## Step 5 — Build the roadmap (Design)
1. From the scorecard, sequence each domain's gap (current → target) into
   `Purview Maturity Roadmap - 3 Horizons`:
   - **Now (0–3 mo):** close `L0`/`L1` gaps and quick wins — enable audit, publish a baseline label,
     stand up a DLP policy in **test** mode, turn on Compliance Manager.
   - **Next (3–6 mo):** raise priority domains to **L3** — enforce after a clean pilot, document, assign
     owners.
   - **Later (6–12 mo):** reach **L4/L5** — measurement, SIEM integration, automation, org-wide scope.
2. Mark D4/D5 items as **HR/legal-gated** and any regulated retention/records/hold item as a
   **compliance/records/legal determination** — the roadmap lists the technical step, not the
   determination.
3. **Pass/fail:** every below-target domain appears in exactly one horizon with a named owner.

## Step 6 — Executive readout (Design)
1. Run `PURVIEW-MaturityScore.ps1 -EvidencePath .\purview-evidence.json -CsvPath .\scorecard.csv` to
   render and export the scorecard (per-domain scores + overall band); pair it with the roadmap
   horizons for the readout deck.
2. Present current state, target state, and the sequenced next steps to the stakeholders from
   Requirement 2.5. Get sign-off on the roadmap before any configuration.

> Steps 7–10 are **optional** — run them only when the roadmap's *Now* horizon calls for a quick-win
> baseline and change control (Requirement 2.7) is approved. The assessment itself ends at Step 6.

## Step 7 — Prepare the pilot scope (Configure)
1. Run `PURVIEW-Set-ScopeTargeting.ps1` to create/confirm the Entra group `Purview - Pilot Users` and
   add the agreed pilot members.
2. **Pass/fail:** the group exists and contains the pilot users.

## Step 8 — Apply the quick-win baseline in SIMULATION/TEST (Configure → Pilot)
1. Run `PURVIEW-Remediation.ps1` **without** `-Commit` first (default `-WhatIf`) to preview exactly what
   it would create/enable. Review the plan.
2. Run `PURVIEW-Remediation.ps1 -Commit` to apply only the approved quick wins, all in
   **non-enforcing** mode:
   - **Enable the unified audit log** (D6) if off — low-risk, read-enabling, reversible.
   - Publish `Sensitivity Label - Confidential - Baseline` and its label policy scoped to
     `Purview - Pilot Users` (D1) — no auto-labeling on yet.
   - Create `DLP Policy - Baseline PII - Test` in **Test mode** (audit only, policy tips) scoped to the
     pilot (D2) — **not** enforce.
   - Turn on **Compliance Manager** (D10) if not initialized.
3. The script **never** enables enforce, auto-labeling out of simulation, insider-risk actions, or any
   retention-deletion policy — those are roadmap *Next/Later* items requiring their own change and
   (for D3/D4/D5) a records/HR/legal determination.
4. **Pass/fail:** the named baseline objects exist in **test/simulation/disabled** mode, scoped to the
   pilot only.
5. **Rollback:** disable/delete the baseline label policy, set `DLP Policy - Baseline PII - Test` off,
   and (if it was off before) leave audit as-is per the change ticket. `PURVIEW-Remediation.ps1` records
   what it created so it can be reverted.

## Step 9 — Validate the baseline (Validate)
1. Run `PURVIEW-Validation.ps1`. It confirms the baseline objects exist, are in **test/non-enforcing**
   mode, and are scoped to `Purview - Pilot Users`, and re-checks the domain gates.
2. Complete the Testing Guide against the pilot.
3. **Pass/fail:** validation reports every expected baseline object present and non-enforcing.

## Step 10 — Re-assess and expand (Validate → Expand)
1. Re-run `PURVIEW-Discovery.ps1` → `PURVIEW-MaturityScore.ps1` to show the scorecard moving (the quick
   wins should lift D1/D2/D6/D10 from L0/L1 toward L2).
2. Expansion (enforcing DLP, auto-labeling out of simulation, records/retention, insider risk) is the
   roadmap's *Next/Later* work — each is its own piloted, change-controlled project, with regulated
   determinations deferred to the relevant governance function.
3. Schedule the next assessment (e.g. quarterly) to track the maturity trend.

---
### Order of operations
`Model + targets → health/read check → cross-domain discovery → score (rubric) → roadmap (3 horizons) → readout → [optional] pilot scope → quick-win baseline in test → validate → re-assess/expand`
