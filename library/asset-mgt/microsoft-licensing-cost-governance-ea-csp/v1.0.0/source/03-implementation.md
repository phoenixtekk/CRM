# 3. Implementation Guide — Microsoft Licensing Cost Governance (EA, CSP & True-Up Readiness)

Follow these steps in order. Reads happen in the Microsoft 365 admin center
(`https://admin.microsoft.com`) and via Microsoft Graph PowerShell; commercial actions (true-up,
renewal) are executed in your EA/procurement portal or with your licensing partner — this guide
gives the correct general procedure and defers the specifics to your agreement.

> Model: Assess to Configure to Pilot to Validate to Expand. You build a known position on a pilot
> scope, prove the cadence and the numbers, then expand estate-wide. A pilot gate (Step 7) must pass
> before any estate-wide decision.

Named artifacts you will produce (reuse these names verbatim):
- `License Position Register – EA+CSP – Steady-State`
- `True-Up Worksheet – Enterprise Agreement – Annual`
- `Renewal Decision Log – EA+CSP – Per-Cycle`
- `Cost Governance Cadence – Tenant-Wide – Ongoing`
- `Licensing KPI Set – Governance – Standard`
- Governance-scope groups: `License Governance – Pilot Scope – Stage1` and
  `License Governance – Estate Scope – Stage2`

## Step 1 — Assess: inventory agreements and entitlements (owned side)
1. From the EA/procurement portal or your licensing partner, capture the EA committed baseline
   (products and quantities), the anniversary/true-up window, and term dates. Record them in the
   register's owned column with channel `EA`.
2. From the CSP partner export (or the partner-managed admin experience), capture each CSP
   subscription's product and seat count and term; record them with channel `CSP`.
3. Do not assume any term. Where a value is unclear, mark it `confirm with agreement` and resolve it
   with procurement before relying on it.

## Step 2 — Assess: read the deployed position (assigned side)
1. In `https://admin.microsoft.com`, open Billing then Your products to see subscriptions and total
   quantities, and Billing then Licenses to see assigned counts per product.
2. For the authoritative machine-readable count, run `MSLICGOV-Discovery.ps1` (read-only) to
   enumerate `subscribedSkus` and assigned/consumed units per SKU.
3. Enter the assigned quantity for each product into the
   `License Position Register – EA+CSP – Steady-State`. The position column is owned minus assigned.

## Step 3 — Map deployment and growth
1. For each product, compare assigned vs owned. Positive position is headroom; negative is exposure.
2. Add expected growth (new hires, projects) from the procurement/finance calendar to a planned
   column, so the register reflects the trajectory, not just today.
3. For per-user products, layer in utilization: use the usage/sign-in signal (Requirement 2.5) to
   flag assigned-but-unused seats as reharvest candidates.

## Step 4 — Model true-up exposure (EA)
1. Open the `True-Up Worksheet – Enterprise Agreement – Annual`. For each EA product, record the
   committed baseline, the current assigned count, and the difference (assigned minus baseline).
2. Run `MSLICGOV-Validation.ps1` (read-only) to compute, per EA SKU, the assigned-vs-baseline delta
   from the tenant — the forecast true-up quantity. Supply your baselines via the worksheet/CSV input.
3. The positive delta is your forecast true-up; reductions are not trued down mid-term (defer to
   renewal). Confirm the true-up window and process with your agreement/partner before reporting.

## Step 5 — Set renewal and right-sizing decisions
1. In the `Renewal Decision Log – EA+CSP – Per-Cycle`, for each product record: current quantity,
   utilization, recommended renewal quantity, and channel recommendation (keep EA, move to CSP, or
   split).
2. Right-size: reduce over-bought products at the next allowed point (renewal for EA; the defined
   adjustment point for CSP per the partner terms) and reharvest unused seats now via Step 6.
3. Defer all pricing and final quantities to procurement and the agreement; the log captures the
   recommendation and its rationale, not a negotiated price.

## Step 6 — Build governance-scope groups and remediate safely
1. Create the scope groups in `https://entra.microsoft.com` then Groups then New group (Security):
   `License Governance – Pilot Scope – Stage1` (the pilot product family/department) and
   `License Governance – Estate Scope – Stage2` (the remainder). Use `MSLICGOV-Set-ScopeTargeting.ps1`
   to create them and seed membership from a filter.
2. Remediate mis-assignments (for example, a user holding a license they do not use, or a duplicate
   product) with `MSLICGOV-Remediation.ps1`. It defaults to `-WhatIf` — review the planned changes,
   then re-run with `-Confirm` only on the pilot scope first.

## Step 7 — Pilot: validate the position on the pilot scope (GATE)
1. Run `MSLICGOV-Report.ps1` scoped to `License Governance – Pilot Scope – Stage1` to produce the
   pilot's license-position and cost report.
2. Confirm the register, true-up worksheet, and report agree for the pilot products. Complete the
   Testing Guide.
3. Gate: do not proceed to estate-wide action until the pilot's owned/assigned/position numbers
   reconcile and at least one reharvest or right-size action has been validated without disruption.

## Step 8 — Establish the governance cadence and KPIs
1. Stand up the `Cost Governance Cadence – Tenant-Wide – Ongoing`: a monthly operational review
   (assignments, reharvest), a quarterly strategic review (position vs growth), and an annual review
   at renewal/true-up.
2. Adopt the `Licensing KPI Set – Governance – Standard`: License Position, Assignment Utilization,
   True-Up Exposure, Renewal Variance, Reharvest Yield. Record the baseline values now.

## Step 9 — Expand: apply estate-wide
1. Extend the register, worksheet, and cadence from the pilot scope to
   `License Governance – Estate Scope – Stage2`, repeating Steps 2 to 6 for all products.
2. Re-run `MSLICGOV-Report.ps1` estate-wide each cadence cycle and update the KPI set.
3. Feed the renewal/true-up decisions to procurement ahead of each window.

---
### Order of operations
`Inventory entitlements (owned) -> Read deployment (assigned) -> Map growth -> Model true-up ->
Renewal/right-size decisions -> Scope groups + remediate -> Pilot gate -> Cadence + KPIs -> Expand`
