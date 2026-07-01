# 3. Implementation Guide — Tier-1 Publisher License & Audit-Risk Management

Follow these steps in order. Run them for one pilot publisher first, validate, then repeat for the
others. The artifacts named below (the per-publisher position worksheet, the deployment-to-metric
mapping, the per-publisher exposure register, and the tier-1 publisher controls) are reused verbatim
for each publisher.

> Model: Per publisher, gather contracts and metrics, map deployment to the metric, calculate
> position and exposure, close gaps and set controls, prepare for audit. Pilot one publisher, then
> expand. Assess to Configure to Pilot to Validate to Expand.

## Step 1 — Choose the pilot publisher and build the scope
1. Pick the pilot publisher (clearest contracts and inventory — see Requirements 2.8).
2. Run `TIER1LIC-Set-ScopeTargeting.ps1 -Publisher <Name>` to build the publisher-scope group from
   the inventory — the list of hosts/users in scope for this publisher.
3. Record the scope as the header of the per-publisher position worksheet.

## Step 2 — Gather contracts and define the metric per product
1. For the pilot publisher, collect the agreement set and entitlement quantities (Requirement 2.1).
2. For each product in scope, record in the per-publisher position worksheet: product/edition, the
   governing metric (for example Oracle Processor or NUP, IBM PVU, SAP named-user type or digital
   access), the one-line counting rule, and the entitled quantity.
3. Where a clause is ambiguous, mark it open and raise it with the publisher rather than assuming.

## Step 3 — Discover deployment
1. Run `TIER1LIC-Discovery.ps1 -InventoryCsv <path> -Publisher <Name>` to assemble the deployment
   inventory: each install with host, edition, cores per host, virtualization host/cluster, and (for
   user metrics) authorized users.
2. Reconcile the discovered list against the scope group from Step 1; resolve any host the inventory
   missed by adding it manually.

## Step 4 — Map deployment to the licensing metric
1. Run `TIER1LIC-Validation.ps1 -InventoryCsv <path> -Publisher <Name>` to produce the
   deployment-to-metric mapping: for each install it applies the metric's counting basis (processor
   cores adjusted by the recorded core factor, value units per core, named users by type, or
   document volume for digital access).
2. Validation flags every row that cannot be mapped (missing metric, missing core count, missing
   core factor, claimed sub-capacity without the prerequisite). Resolve each flag before continuing —
   an unmapped row is unknown exposure.
3. For virtualized processor/value-unit products, confirm the topology decision (host, cluster, or
   guest counting) is recorded per Requirement 2.4.

## Step 5 — Calculate position and exposure
1. Run `TIER1LIC-Report.ps1 -InventoryCsv <path> -Publisher <Name>` to calculate, per product,
   consumption required by the metric versus entitlement held.
2. The report writes the per-publisher exposure register: each product with its position (shortfall
   or headroom), the exposure quantity, and a severity based on the gap.
3. Review the register with the named owner/approver (Requirement 2.7); assign each exposure item a
   disposition: remediate, acquire, or accept-and-budget.

## Step 6 — Close gaps and set controls
1. For over-deployment, run `TIER1LIC-Remediation.ps1 -InventoryCsv <path> -Publisher <Name>` to
   produce the remediation work list (it runs in `-WhatIf` mode by default and only proposes
   actions — uninstall unused installs, consolidate processor-counted software onto fewer hosts,
   remove unlicensed options/users). Nothing is changed until an owner approves and the action is
   performed through your normal change process.
2. Re-run validation and the report after each approved change so the exposure register reflects the
   new position.
3. Record the tier-1 publisher controls for the highest-risk products: where the software may run,
   who may install it, which options are permitted, and the sub-capacity prerequisites that must
   stay in place. Wire these into your intake/change process so new deployments cannot silently
   recreate exposure.

## Step 7 — Validate the pilot publisher
1. Confirm every product in the position worksheet has a mapped metric, a calculated position, and a
   register entry with an owner and disposition.
2. Confirm no validation flags remain unresolved. Complete the Testing Guide pass/fail gate.

## Step 8 — Prepare the audit evidence pack
1. Assemble the contracts, the position worksheet, the deployment-to-metric mapping, the exposure
   register with dispositions, and proof of any sub-capacity prerequisites into a single audit
   evidence pack per publisher.
2. Keep it current: it is what you hand an auditor instead of granting open-ended access.

## Step 9 — Expand to the remaining publishers
1. Repeat Steps 1 to 8 for the next publisher, reusing the same artifacts and scripts.
2. Re-validate each publisher on a set cadence (renewal-driven at minimum) so the position stays
   defensible cycle after cycle.

---
### Order of operations
`Scope -> Contracts/metric -> Discover deployment -> Map to metric -> Position & exposure ->
Close gaps & controls -> Validate -> Audit evidence pack -> Expand`
