# 1. Solution Overview — Software License Usage Reporting & Cost Dashboards (Power BI)

## What this reporting layer is
This is the license and spend reporting layer for Software Asset Management — distinct from device or
endpoint health reporting. It takes three inputs (what you are entitled to, what is actually deployed
or used, and what each entitlement costs and when it renews), models them into a single Power BI
dataset, and presents a fixed set of license KPIs on dashboards that refresh on a schedule. The goal
is to turn license data into decisions: which seats to reclaim, which renewals to right-size, and
where the software spend actually goes.

## Why it matters
Most organizations already pay for the data — entitlement records, M365/SaaS usage telemetry,
discovery inventory, renewal dates — but it lives in disconnected exports. The result is predictable:
renewals arrive as surprises, true-ups are over-bought, idle seats are never reharvested, and finance
has no per-product cost view. Connecting those sources once and refreshing them on a schedule converts
recurring manual export work into a living dashboard, so the SAM analyst spends time deciding rather
than collecting. That is the only place in this document where the "why" is argued; the rest is "do
this."

## How it works
1. A defined KPI set (`License KPI Set – Software Assets – v1`) fixes exactly which numbers the
   reporting layer produces, how each is calculated, and from which source.
2. License entitlement data (counts, renewal dates, unit cost) and usage/deployment data (active
   users, installs, last activity) are connected as queries in one Power BI dataset.
3. A data model relates entitlements to usage by product, so each product shows entitled vs. deployed
   vs. actively used — the basis for compliance, reharvesting, and cost-per-seat.
4. A multi-page dashboard surfaces the KPI set: a deployment/usage page, an expirations timeline, a
   reharvesting opportunities page, and a cost-efficiency page.
5. Scheduled refresh keeps the dataset current; row-level reconciliation against the systems of record
   gates broad distribution so leadership never sees numbers that disagree with the source.
6. The published report is distributed to a named audience (a leadership/procurement group) through the
   Power BI service.

## The license KPI set (what the dashboards report)
- Deployment rate — deployed (or assigned) divided by entitled, per product.
- Active usage rate — actively-used divided by deployed, per product (the reharvesting signal).
- Days-to-expiration — days until each contract/renewal date, for the expirations timeline.
- Cost-per-seat — annualized unit cost per entitlement, and per actively-used seat.
- Reharvesting savings — idle seats (deployed but not used) multiplied by unit cost = reclaimable spend.

## Data sources (inputs to the model)
- License inventory / entitlements — counts, products, and unit cost from a SAM/ITAM tool, a
  controlled spreadsheet, or admin-center license exports.
- Usage / deployment data — M365/SaaS sign-in and activity reports, plus discovery/inventory (Intune,
  Configuration Manager, or a discovery tool) for installed software.
- Contracts / renewals — renewal dates and quantities from the entitlement system of record.

## What you can control
- Which products and publishers are in scope (the reporting scope).
- The KPI definitions and thresholds (for example, the "idle" window for reharvesting).
- The refresh cadence (daily or weekly) and the distribution audience.
- The reconciliation tolerance that must pass before broad distribution.

## Limitations (be honest with buyers)
- The dashboard is only as accurate as its inputs; a missing usage source produces blind spots, which
  the reconciliation gate is designed to catch.
- Scheduled refresh of cloud-to-on-prem sources may require an on-premises data gateway (called out in requirements).
- SaaS "usage" definitions vary by publisher; the KPI set documents the definition used per product.
- This layer reports and recommends; it does not reclaim seats or renew contracts — those run through the intake process.

## The standard deployment model
> Define the KPI set, connect license and usage data, build the dashboards, set scheduled refresh and
> distribution, validate the numbers, then pilot, validate, and expand. Pattern: Assess to Configure
> to Pilot to Validate to Expand, with a reconciliation gate before broad distribution.
