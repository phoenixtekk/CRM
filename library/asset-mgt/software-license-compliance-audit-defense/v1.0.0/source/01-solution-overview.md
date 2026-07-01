# 1. Solution Overview — Software License Compliance & Audit-Defense (Effective License Position)

## What an Effective License Position is
An Effective License Position (ELP) is a point-in-time statement, per publisher and product, of what
you are *entitled* to use (purchased licenses, subscriptions, and the rights attached to them)
reconciled against what you have *deployed and used* (installs, assignments, and active usage). The
difference is your compliance position: a shortfall (you run more than you own) is exposure; a
surplus (you own more than you run) is wasted spend. The ELP is the single number an auditor —
and your finance team — actually cares about.

## Why this matters (the why lives here)
A vendor software audit is a financial event. When the auditor's measurement is the only measurement
in the room, you negotiate from behind: unproven entitlements are treated as zero, every install is
assumed licensable, and shortfalls settle at list price plus back-maintenance and penalties.
Building your own ELP *first* flips that: you know the gaps before the auditor does, you close the
cheap ones quietly, and you arrive with reconciled numbers and the proofs to defend them. The same
ELP also surfaces surplus you can reharvest or stop renewing — so the work pays for itself even
without an audit.

## How it works (the reconciliation model)
1. Gather entitlements into an `Entitlement Baseline – <Publisher/Product> – Source` — every license
   and subscription you own, with quantity, edition/version, metric (per-user, per-device, per-core),
   and a proof of purchase for each line.
2. Collect deployment and usage into a `Deployment Inventory – <Publisher/Product> – Discovered` —
   what is installed, assigned, or actively used, from your discovery and identity sources.
3. Normalize both sides so they compare on the same key: same product name, same edition, same
   counting metric (a per-core product counts cores, not installs).
4. Reconcile the two into an `Effective License Position – <Publisher/Product> – ELP`: entitled
   quantity minus consumed quantity, per product line, applying the product use rights (downgrade,
   second-use, virtualization, BYOL) that change the count.
5. Record every difference in a `Gap Register – <Publisher/Product> – Reconciled` — shortfalls
   (compliance exposure) and surpluses (reharvest/renewal candidates), each with an owner and action.
6. Close the gaps (true-up, reharvest, reassign, or correct the data) and re-reconcile.
7. Assemble an `Audit Package – <Publisher/Product> – Defense` — the entitlement proofs, deployment
   evidence, normalization notes, product-use-rights interpretation, the ELP, and the gap closure
   record — so the position is defensible on demand.

## What you can control
- Which publishers/products are in scope and the reconciliation cadence (per product family).
- The counting metric and product use rights applied to each line (the most common source of dispute).
- How shortfalls are closed: true-up purchase, reharvest of unused, reassignment, or a data fix.
- The contents and freshness of the audit package, so you are always audit-ready, not audit-reactive.

## The four named artifacts (reuse these names verbatim everywhere)
- `Entitlement Baseline – <Publisher/Product> – Source` — what you own, with proofs.
- `Deployment Inventory – <Publisher/Product> – Discovered` — what you run, with sources.
- `Effective License Position – <Publisher/Product> – ELP` — the reconciliation workbook.
- `Gap Register – <Publisher/Product> – Reconciled` — shortfalls and surpluses with actions.
- `Audit Package – <Publisher/Product> – Defense` — the bundled, defensible evidence set.

## Common compliance gaps (what reconciliation surfaces)
- Over-deployment — more installs/assignments than entitlements (direct exposure).
- Edition mismatch — a Standard entitlement running a Professional install.
- Wrong metric — counting installs for a per-core or per-processor product.
- Unproven entitlements — licenses you believe you own but cannot evidence with a purchase record.
- Stale assignments — licenses assigned to disabled or departed users (reharvest candidates).
- Virtualization/second-use rights not applied — over-counting because rights were ignored.

## Limitations (be honest with buyers)
- An ELP is only as good as its two inputs: incomplete entitlement records or partial discovery
  produce a position you cannot defend. Requirements G3 and G4 are non-negotiable.
- Product use rights vary by publisher and contract; this package gives the repeatable method and
  where to record the interpretation, not legal advice on a specific contract clause.
- Reconciliation is point-in-time; deployment drifts, so the cadence (not a one-off) is what keeps
  you audit-ready.
- This package covers the SAM reconciliation and audit-defense process; it does not replace a
  full discovery tool where one is required for accurate deployment data.

## The standard deployment model
> Build the entitlement baseline and deployment inventory, normalize, reconcile to an ELP, register
> and close gaps, then assemble the audit package — proven on one publisher/product pilot before
> expanding. Model: Assess to Configure to Pilot to Validate to Expand.
