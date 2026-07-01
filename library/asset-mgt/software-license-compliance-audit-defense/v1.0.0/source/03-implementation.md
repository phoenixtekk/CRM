# 3. Implementation Guide — Software License Compliance & Audit-Defense (Effective License Position)

Follow these steps in order. Do the work for one publisher/product first (the pilot), validate it,
then expand to more publishers.

> Model: Build both inputs, normalize, reconcile to an ELP, register and close gaps, assemble the
> audit package — proven on a single publisher/product before you scale.

## Step 1 — Choose the pilot scope (one publisher/product)
1. Pick one high-value, well-understood product as the pilot (for example, a single publisher's
   flagged product with a known entitlement count and a clear discovery source).
2. Define the population to reconcile (the users/devices that could consume it). Run
   `LICCOMP-Set-ScopeTargeting.ps1 -ProductName "<Product>" -WhatIf` to preview the in-scope group,
   then run it without `-WhatIf` to build the reconciliation-scope group.

## Step 2 — Build the entitlement baseline
1. From the entitlement system of record, export every line for the in-scope product: quantity,
   edition/version, counting metric, renewal date, and a proof-of-purchase reference per line.
2. Save it as the `Entitlement Baseline – <Publisher/Product> – Source`.
3. Confirm every line has a proof reference (Requirement 2.2); flag any line you cannot evidence as
   "unproven" — it counts as zero until evidenced.

## Step 3 — Collect the deployment inventory
1. Export installs/assignments/usage for the in-scope product from your discovery and identity
   sources. For installed software, run `LICCOMP-Discovery.ps1 -CsvPath .\deployment.csv` against your
   inventory export, or export from Intune/Configuration Manager. For SaaS, export per-user license
   assignments and recent sign-in/usage.
2. Save it as the `Deployment Inventory – <Publisher/Product> – Discovered`.

## Step 4 — Normalize both sides
1. In the `Effective License Position – <Publisher/Product> – ELP` workbook, build a normalization
   mapping table: raw product/edition names to one canonical product, edition, and counting metric.
2. Map both the baseline and the inventory through it so they compare on the same key.
3. Convert the deployment count to the entitlement's metric (for a per-core product, count cores; for
   per-user, count distinct active users — not installs).

## Step 5 — Reconcile to an Effective License Position
1. In the ELP workbook, for each canonical product line compute: entitled quantity minus consumed
   quantity, after applying the product use rights from Requirement 2.4 (downgrade, second-use,
   virtualization, BYOL).
2. Record the metric and rights interpretation as a note on each line (with the contract clause).
3. Run `LICCOMP-Validation.ps1` to confirm both inputs are present, normalized, and reconcilable
   before you trust the numbers.

## Step 6 — Register the gaps
1. Run `LICCOMP-Report.ps1 -ElpPath .\elp.csv -CsvPath .\gap-register.csv` to produce the ELP summary
   and the gap list.
2. Record every difference in the `Gap Register – <Publisher/Product> – Reconciled`: shortfalls
   (compliance exposure) and surpluses (reharvest/renewal candidates), each with a cause, an owner,
   and a planned action.

## Step 7 — Close the gaps
1. For each shortfall, choose the closure: reharvest unused assignments, reassign, correct the data,
   or true-up (purchase). Get owner sign-off (Requirement 2.6) before any spend.
2. For safe reclamation of clear over-deployment (stale/disabled-user assignments), run
   `LICCOMP-Remediation.ps1` — it defaults to `-WhatIf` and only previews; re-run with
   `-WhatIf:$false` after sign-off to act.
3. For surpluses, route to procurement as reharvest or renewal-reduction candidates.

## Step 8 — Re-reconcile and confirm
1. Refresh the deployment inventory and re-run Steps 4 to 6.
2. Confirm the `Gap Register – <Publisher/Product> – Reconciled` shortfalls are closed or have an
   approved, dated action. Complete the Testing Guide.

## Step 9 — Assemble the audit package
1. Bundle into the `Audit Package – <Publisher/Product> – Defense`: the entitlement baseline with
   proofs, the deployment inventory with its source/date, the normalization notes, the product use
   rights interpretation, the ELP, and the gap-closure record.
2. Have the named owners sign off the package so the position is defensible on demand.

## Step 10 — Expand to more publishers
1. Once the pilot passes, repeat Steps 1 to 9 for the next publisher/product, reusing the same five
   artifact names and the same workbook structure.
2. Set the reconciliation cadence (per product family) so the ELP stays current, not a one-off.

---
### Order of operations
`Pilot scope -> Entitlement baseline -> Deployment inventory -> Normalize -> Reconcile (ELP) -> Gap register -> Close gaps -> Re-reconcile -> Audit package -> Expand`
