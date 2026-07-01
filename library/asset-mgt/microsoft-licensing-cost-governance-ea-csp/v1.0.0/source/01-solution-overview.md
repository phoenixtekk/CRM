# 1. Solution Overview — Microsoft Licensing Cost Governance (EA, CSP & True-Up Readiness)

This overview is the one place that explains *why* licensing cost governance matters and *how* the
EA and CSP models behave. The rest of the package is procedure; this section is the model you carry
into it.

## The problem this solves
Most organizations buy Microsoft licensing through more than one channel and lose track of the
total position. Two failure modes recur:

- Over-buying to feel safe — paying for entitlements nobody uses, which compounds at every renewal.
- Under-licensing — assigning more product than is owned, creating a true-up bill or a compliance
  shortfall that surfaces at the worst time.

Cost governance replaces both with a known position: what you own under each agreement, what is
deployed against it, and the cadence that keeps the two reconciled.

## The two commercial models

### Enterprise Agreement (EA)
An EA is a volume-licensing agreement, typically a three-year term negotiated for larger
organizations, with pricing tied to an enrolment level and committed quantities. Its defining
mechanic is the annual true-up (below): you enrol with a baseline, deploy throughout the year, and
reconcile the increase once per anniversary. EA is a commitment-based model — you pay for what you
committed to, then settle growth annually. Specific terms (price levels, included products,
anniversary date, true-up window) live in the signed agreement and are negotiated with the
licensing partner or the procurement portal; this solution never invents them.

### Cloud Solution Provider (CSP)
CSP is a partner-led subscription model. Licenses are bought through a CSP partner (or the
partner-managed admin experience) as monthly or annual subscriptions that can usually be increased
at any time and decreased at defined points (for example, within a cancellation window or at term
end, per the partner's terms). CSP is flexible and granular — good for variable headcount and
add-on products — but that flexibility means seat counts drift quietly upward if nobody governs
them. CSP has no annual true-up; instead the discipline is continuous right-sizing.

### EA vs CSP — the practical contrast
| Dimension | Enterprise Agreement (EA) | Cloud Solution Provider (CSP) |
|---|---|---|
| Buying motion | Committed quantities, negotiated term | Subscriptions via a partner, adjustable |
| Reconciliation | Annual true-up at anniversary | Continuous; adjust seats as needed |
| Growth | Deploy now, settle annually | Add seats as you go |
| Reduction | At renewal / per agreement terms | At defined points per partner terms |
| Best for | Stable, large, predictable estates | Variable headcount, granular add-ons |

Many estates run both — an EA for the stable core and CSP for flex and niche products. Governing
the combined position is the whole point of this solution.

## How a true-up works
A true-up is the annual reconciliation under an EA. During the year you deploy and assign more
licenses than your committed baseline; at the anniversary you report the net increase and pay for
it for the remainder of the term. Key facts a SAM analyst must hold:

1. True-up counts the *increase* over the committed baseline, not the total.
2. It is typically processed once per year within the agreement's defined window.
3. Reductions are generally not handled at true-up — you cannot true *down* mid-term; reductions
   happen at renewal (per the agreement).
4. The exact baseline, products in scope, and window are in the agreement — confirm them, do not
   assume.

True-up readiness means: at any point in the year you can state your current deployed/assigned
count, compare it to the committed baseline, and forecast the true-up cost — so the annual report
holds no surprises.

## Entitlement-to-deployment mapping
The core analytical move in this whole package is mapping what you own to what is deployed:

- Entitlement = what you have the right to use (owned quantity per product, per agreement).
- Deployment/assignment = what is actually assigned to users or in use (read from the tenant).
- Position = entitlement minus deployment. Positive is headroom; negative is exposure.

For Microsoft 365 and similar per-user products, deployment is read from the tenant as assigned
license counts against each subscribed SKU. The scripts in this package read those counts directly;
the entitlement side comes from your `License Position Register – EA+CSP – Steady-State`, sourced
from the agreements.

## The cost-governance cadence and KPIs
Governance is not a one-time clean-up; it is a cadence. This solution establishes the
`Cost Governance Cadence – Tenant-Wide – Ongoing` — a recurring review (monthly operational,
quarterly strategic, annual at renewal/true-up) tracked against the `Licensing KPI Set – Governance
– Standard`:

- License Position (owned minus assigned) per major product — target a small positive buffer.
- Assignment Utilization (active/assigned) — surfaces paid-for, unused seats to reharvest.
- True-Up Exposure (assigned minus committed baseline) — the forecast annual settlement.
- Renewal Variance (planned vs current quantity) — what you intend to change at renewal.
- Reharvest Yield (seats reclaimed per cycle) — proves the cadence saves money.

## What this solution does and does not do
- It does: build a known, repeatable license position across EA and CSP, make true-ups predictable,
  inform renewal decisions, and stand up a governance cadence with KPIs.
- It does not: invent your contract terms, negotiate with Microsoft or a partner, or move spend on
  your behalf. It gives the correct general procedure and defers all commercial specifics to the
  agreement and procurement.

## The standard deployment model
Assess to Configure to Pilot to Validate to Expand. A pilot scope (one product family or one
department) proves the position and the cadence before they are applied estate-wide.
