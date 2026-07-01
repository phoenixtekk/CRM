# 1. Solution Overview — Tier-1 Publisher License & Audit-Risk Management

## What "tier-1 publisher" means here
Oracle, IBM, and SAP are the publishers most likely to audit you and most expensive to get wrong.
Their licensing differs from ordinary per-device or per-user software in three ways: the metrics are
indirect (you are not licensed per install — you are licensed per processor core, per named user, or
per value unit), the rules for counting are detailed and publisher-specific, and the audit programs
behind them are formal, scheduled, and designed to find shortfalls. This solution is the repeatable
way to manage that risk: know the metric, map your deployment to it, calculate where you stand, and
control the gap before an auditor does.

## The metrics, at a correct but general level
Precise rates, core factors, user-type definitions, and price lists live in your own agreements and
with the publisher. Treat the summaries below as the model, not the contract.

- Oracle — Processor and Named-User Plus (NUP). The Processor metric counts the processors
  (cores adjusted by Oracle's core factor) where a program runs or is installed and available to
  run; virtualization and clustering rules strongly affect what must be counted. Named-User Plus
  counts individuals and devices authorized to use the program, subject to per-program minimums.
  Options and management packs are licensed separately and are a common source of unplanned use.
- IBM — Processor Value Unit (PVU). Eligible products are licensed by the number of value units
  assigned to each processor core the software can run on, where a per-core value-unit rating
  applies. Sub-capacity (licensing only the virtual capacity used) is permitted only when the
  required metering tool is deployed and reporting; without it, full-capacity counting applies.
- SAP — named-user and digital (indirect) access. Named users are licensed by user type/category
  according to what each person is entitled to do; engine/package metrics license specific
  functional consumption. Digital access addresses indirect/third-party and automated consumption of
  SAP data (commonly measured by document volume) rather than by a human logging in.

## How the repeatable way works
1. Per publisher, gather the contracts and entitlement records and confirm which metric governs
   each product you run (the per-publisher position worksheet).
2. Discover what is actually deployed for that publisher from your inventory exports and map each
   deployment to the licensing metric (deployment-to-metric mapping).
3. Calculate the licensing position: entitlements held versus consumption required by the metric.
4. Quantify the difference as exposure (a shortfall) or headroom (a surplus) and record it (the
   per-publisher exposure register).
5. Close gaps on your terms — reduce deployment, re-deploy to lower-cost configurations, or acquire
   licenses — and put controls around the highest-risk products (the tier-1 publisher controls).
6. Prepare the evidence pack so an audit is a confirmation, not a discovery.

## What you can control
- Which deployments are counted, and how, by removing unused installs and unlicensed options before
  they are measured.
- Where high-metric software runs (for example, isolating processor-counted software so unrelated
  hosts are not pulled into scope).
- Whether sub-capacity / lower-cost counting is available to you, by ensuring the prerequisites for
  it are actually in place and reporting.
- Who owns each exposure item and the decision to remediate, budget, or accept it.

## Why this matters (the why lives here only)
Tier-1 audits are not random. They are triggered by renewals, mergers, big infrastructure changes,
and lapsed engagement, and they are run by teams whose job is to find the gap between what you
deployed and what you licensed. The organizations that come through them cheaply are the ones that
already knew their position, had already closed or budgeted the gap, and could hand the auditor a
worksheet instead of root access. Calculating your own position first converts a one-sided audit
into a negotiation you are prepared for — and it is the only point in the process where you still
hold leverage.

## Limitations (be honest with buyers)
- This is a methodology and tooling package, not legal or contractual advice. Exact metric
  definitions, core factors, user categories, and rates are governed by your agreements and the
  publisher and must be confirmed there.
- The scripts operate on inventory exports / CSV, not on vendor-proprietary measurement tools; they
  estimate position from the deployment data you provide and are only as good as that inventory.
- Verified metric outputs (for example, official sub-capacity reports or a publisher's own
  measurement scripts) remain authoritative for a formal audit; this package builds your internal,
  defensible position ahead of that.

## The standard deployment model
> Per publisher: gather contracts and metrics, map deployment to metric, calculate position and
> exposure, close gaps and set controls, prepare for audit — pilot one publisher, then expand.
> Model: Assess to Configure to Pilot to Validate to Expand.
