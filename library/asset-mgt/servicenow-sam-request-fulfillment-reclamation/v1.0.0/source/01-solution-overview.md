# 1. Solution Overview — ServiceNow SAM Request Fulfillment & License Reclamation Workflow

## What this solution is
This is a repeatable workflow design for running the full software-license request lifecycle inside
ServiceNow Software Asset Management (SAM): a user asks for software, the request is triaged and
approved, the system checks whether an entitlement is available, the license is fulfilled and recorded,
and — later — unused licenses are automatically reclaimed back into the available pool. It uses
ServiceNow's Service Catalog, Flow Designer / workflows, the SAM entitlement and reconciliation engine,
discovery/usage data, and reporting. The exact ServiceNow module internals (plugin names, store apps,
console menus) are deferred to ServiceNow's official documentation; this solution defines the correct
workflow and the named artifacts to build.

## Why this matters (the why — covered only here)
Two failure modes cost real money. First, when requests live in email and chat, the service desk has no
queue, no SLA, and no audit trail — work is lost, duplicated, and slow. Second, when nobody reclaims
licenses, every assignment is permanent: a license handed to a user who leaves, changes role, or simply
stops using the product is paid for forever. Over a renewal cycle this is the single largest source of
SAM waste. A clean intake-to-reclamation workflow fixes both: it gives requests a measured queue and
gives licenses a return path, so the pool you pay for is the pool you actually use.

## The request lifecycle
1. Intake — a user submits a request through a published catalog item; the request becomes a tracked
   record with a requester, product, and justification.
2. Triage — the request is validated, categorized, and routed (auto-approve for low-cost/owned
   entitlements; manager/owner approval for paid or restricted software).
3. Entitlement check — before fulfillment, the workflow checks the entitlement pool: is a license
   available, or must one be purchased / reharvested first?
4. Fulfillment — the license is allocated to the user/device, the assignment is recorded against the
   entitlement, and deployment is triggered or instructed.
5. Reclamation — on a schedule, the workflow finds assignments with no recent usage (or for departed
   users) and reclaims them, returning the license to the available pool.

## Named artifacts (use these exact names everywhere)
The naming convention is `<Purpose> – <Scope> – <Stage>`. Reuse these strings verbatim in every guide
and in ServiceNow.

Catalog items:
- `Software Request – Standard – Intake`
- `Software Request – Restricted – Intake`

Workflows / flows:
- `Request Triage – Software – Triage`
- `Entitlement Check – Software – Entitlement`
- `License Fulfillment – Software – Fulfillment`
- `License Reclamation – Unused – Reclamation`

Reclamation rules:
- `Reclaim Rule – Inactive User – Reclamation`
- `Reclaim Rule – No Usage 90d – Reclamation`

Assignment / fulfillment groups:
- `Fulfillment Group – Software – Fulfillment`
- `Approval Group – Restricted Software – Triage`

KPI set:
- `KPI Set – Request & Reclamation – Reporting`

Pilot scope:
- `Pilot Scope – First Product Family – Pilot`

## What you can control
- Which products are self-service (standard) versus approval-gated (restricted).
- Triage routing and approval rules per product or cost band.
- The entitlement-match logic: which entitlement record a request consumes.
- Reclamation criteria: inactivity window, departed-user trigger, and grace period.
- The KPI set: request volume, time-to-fulfill, reclamation count, and pool utilization.

## Benefits
- Speed — a catalog queue with SLAs replaces untracked email; time-to-fulfill becomes measurable.
- Savings — automated reclamation returns idle licenses, shrinking true-ups and renewals.
- Compliance — every assignment is recorded against an entitlement, so the position is auditable.
- Visibility — one KPI set shows request throughput and reclamation yield over time.

## Limitations (be honest with buyers)
- Reclamation accuracy depends on usage/discovery data quality; without it, reclamation is conservative.
- The exact ServiceNow SAM plugin/store-app configuration is product-version specific and deferred to
  ServiceNow's documentation; this solution gives the workflow design, not the menu clicks.
- SaaS products without a sign-in/usage signal can only be reclaimed on the departed-user trigger.
- Approval routing requires named owners; an unstaffed approval step stalls the queue.

## The standard deployment model
> Build the catalog items and intake, then the triage, entitlement, fulfillment, and reclamation
> workflows, then the KPI set; pilot on one product family, validate, then expand.
> Pattern: Assess to Configure to Pilot to Validate to Expand.
