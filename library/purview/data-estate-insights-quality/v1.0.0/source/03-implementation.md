# 3. Implementation Guide — Data Estate Insights & Data Quality (Microsoft Purview)

Follow these steps in order. This guide confirms the governed estate and roles, stands up **Data Estate
Insights** (read-only reporting), authors **data-quality rules** on a bounded pilot data product,
**pilots data-quality scoring on that bounded scope**, validates the scores and the health picture
against the gate, then expands across the estate. Artifact names are fixed — create them with the exact
names shown and reuse them everywhere. **Data-quality scoring is piloted on one bounded data product
before the estate is scored.**

> Model: read the estate's health, prove data-quality scoring on a pilot data product, then expand. The
> repeatable way: **Assess → Design → Configure → Pilot → Validate → Expand.** Verify current portal
> paths, role names, capability availability, and API versions for your tenant as you go — the Purview
> insights and Data Quality experiences are evolving and parts may be in preview.

## Step 1 — Assess current state (read-only)
1. Run `DGINSIGHT-Discovery.ps1` to capture readiness signals: the Purview account endpoint is
   reachable, how many **assets** are catalogued, which **governance domains** and **data products**
   exist, whether the **Data Quality** surface responds (feature available), and role coverage. No
   changes are made.
2. Record gaps against the Requirements checklist. Do **not** proceed past a missing governed estate,
   missing least-privilege roles, or Data Quality not being enabled — remediate those first (a missing
   Data Map/catalog is a hard stop; Data Quality unavailable means the scoring steps are deferred).

## Step 2 — Design the insights and data-quality scope
1. Choose the pilot **governance domain** `DGI-Domain-Pilot` and pilot **data product**
   `DGI-DataProduct-Pilot` (an existing curated data product from the estate).
2. With the data owner, list the **critical data elements** as `DGI-CDE-<name>` (for example
   `DGI-CDE-CustomerID`, `DGI-CDE-Email`), and for each one agree the **quality dimension(s)**, the
   **rule** intent, and the **pass threshold** (Requirement 2.6). Thresholds are the owner's
   determination.
3. Assign least-privilege roles at the narrowest scope: **catalog / Data Governance reader** to
   insights viewers, **governance domain owner** / **data steward** to the curators, and
   **data-quality steward** to whoever authors and runs rules. Reserve Data Governance Administrator for
   a small named group. (Verify current role names for your tenant.)

## Step 3 — Record the pilot scope (read-only manifest)
1. Run `DGINSIGHT-Set-Scope.ps1` to record the pilot scope: the domain, the data product, its CDEs, and
   per-CDE the dimension / rule intent / threshold. This produces the scope manifest you configure
   against (read-only; writes nothing to Purview).
2. Confirm the manifest matches what the owner agreed before you author any rule.

## Step 4 — Stand up Data Estate Insights and take a baseline (read-only)
1. Open the estate **insights / analytics / Health management** experience in the Purview portal (verify
   the current path — classic "Data Estate Insights" vs the new analytics/health surface). Confirm you
   can see estate-level reports: asset counts, **classification distribution**, **ownership coverage**,
   scan health, glossary/data-product coverage.
2. Run `DGINSIGHT-Report.ps1` to capture the same picture as a **baseline** named `DGI-Insights-Baseline`
   (asset totals, classified %, owned %, per-domain/data-product coverage). Insights are read-only —
   this step changes nothing and is safe to repeat.
3. Record the baseline. It is the "before" number the estate's health is tracked against as you expand.

## Step 5 — Establish the data-quality connection and credentials (safe by design)
1. Configure the **data-quality connection** from the pilot data product to its backing source, using
   the Purview account's **managed identity** or an **Azure Key Vault**–stored secret. **Do not put any
   secret in a script or document.**
2. Grant the identity the **least read** role on the source (the scan reads live data — least-privilege
   is mandatory). Run **Test connection** and confirm it passes before authoring rules.

## Step 6 — Author data-quality rules on the pilot data product
1. In `DGI-DataProduct-Pilot`, create the data-quality rule set `DGI-DQ-Ruleset-Pilot`. For each CDE,
   author the agreed rule named `DGI-DQ-Rule-<Dimension>-<CDE>` (for example
   `DGI-DQ-Rule-Completeness-CustomerID`, `DGI-DQ-Rule-Conformity-Email`,
   `DGI-DQ-Rule-Uniqueness-CustomerID`) with the owner's **threshold**.
2. Use `DGINSIGHT-Configure-Quality.ps1` to stage the rules — it **defaults to `-WhatIf`** and prints
   exactly the rules/thresholds it would create; re-run with `-Commit` to author them. Or author them in
   the portal.
3. Keep the scope to the **pilot data product only** — do not attach rules across the domain yet.

## Step 7 — Pilot the data-quality scan on the bounded scope (test-first)
1. Trigger the **data-quality scan/assessment once** on `DGI-DataProduct-Pilot` only (not scheduled
   yet). Use `DGINSIGHT-Configure-Quality.ps1 -RunScan` (`-WhatIf` by default; `-Commit` to run) or the
   portal. The scan **reads live data** on the bounded scope with the owner's agreement.
   Pass/fail: the scan completes **Succeeded** and returns a **quality score** per rule and a rolled-up
   score for the data product.
2. **Rollback:** a data-quality scan does **not modify source data** — it reads and scores. If it
   over-reaches, runs long, or costs too much, cancel the run in the portal and set the rule set to not
   scheduled; re-scope to fewer CDEs/assets and re-run. To back out a mis-authored rule, disable or
   delete `DGI-DQ-Rule-*` (re-run `DGINSIGHT-Configure-Quality.ps1 -Remove -WhatIf` first to preview).

## Step 8 — Review the scores with the owner and tune rules
1. Run `DGINSIGHT-Report.ps1` to list the per-rule and per-data-product **quality scores** and which
   CDEs fall below threshold.
2. With the data owner, confirm each score reflects reality. Where a rule is wrong (false low/high),
   tune the rule or threshold in `DGI-DQ-Ruleset-Pilot` and re-run the scan on the pilot scope. **The
   solution produces the score; the owner decides what the score means and whether remediation is
   required** — remediation of the underlying data is the owner's, not this solution's, action.

## Step 9 — Wire estate-health tracking (health controls, if available)
1. If **Health management / health controls** is available in your tenant (verify — parts may be
   preview), define a small health control set `DGI-Health-Controls-Pilot` for the pilot domain (for
   example: every data product has an owner; every CDE has at least one data-quality rule; no stale
   scan). Use `DGINSIGHT-Scope-Health.ps1` to report these coverage checks read-only.
2. If the health-controls surface is not available, record it as deferred and use
   `DGINSIGHT-Scope-Health.ps1` alone to report the same coverage gaps — it does not depend on the
   feature being enabled.

## Step 10 — Validate against the pilot gate
1. Complete the Testing Guide. The pilot passes only when: the insights baseline `DGI-Insights-Baseline`
   is captured; the data-quality connection Test connection passes; `DGI-DQ-Ruleset-Pilot` is authored
   on `DGI-DataProduct-Pilot`; the data-quality scan **Succeeded** and returned a **quality score** per
   rule and a rolled-up score; and the owner has reviewed and accepted (or flagged remediation for) the
   scores.
2. Remediate any gaps and re-run the relevant validation before proceeding. Do **not** widen scope or
   schedule scoring until the gate passes.

## Step 11 — Expand across the estate (enforce)
1. After the pilot passes, extend data-quality rules to further data products one domain at a time,
   re-running `DGINSIGHT-Set-Scope.ps1`, `DGINSIGHT-Configure-Quality.ps1` (`-WhatIf` first), and
   `DGINSIGHT-Report.ps1` for each new scope.
2. Move data-quality scans from one-time to **scheduled** only once a scope is validated, so scores stay
   current as data changes.
3. Track estate health over time by re-running `DGINSIGHT-Report.ps1` against the `DGI-Insights-Baseline`
   and widening `DGI-Health-Controls-Pilot` as coverage grows. Keep threshold and remediation decisions
   with the data owners.

---
### Order of operations
`Assess -> Design (domain/data product/CDEs/rules/thresholds) -> Record scope -> Insights baseline (read-only) -> DQ connection & credentials -> Author DQ rules (pilot data product) -> Pilot DQ scan (bounded, one-time) -> Review scores & tune -> Health tracking -> Validate gate -> Expand (scheduled scoring)`
