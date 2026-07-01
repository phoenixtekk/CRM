# 3. Implementation Guide — Software Asset Management (SAM) Program Standup & Governance

Follow these steps in order. This guide stands up the program: scope and roles, the system of record
and intake, the SOP set and KPI set, the first governance cycle, then pilot, validate, and expand.
Artifact names are fixed — create them with the exact names shown and reuse them everywhere.

> Model: define the program, prove it on a pilot scope, then expand. The repeatable way: Assess, then
> Configure, then Pilot, then Validate, then Expand.

## Step 1 — Assess current state
1. Run `SAMPROG-Discovery.ps1` to capture readiness signals: whether a discovery source and tenant
   entitlement/usage data are reachable, and a snapshot of managed devices and assigned licenses.
2. Record the gaps against the Requirements Guide checklist. Do not proceed past a missing system of
   record or missing discovery data — implement those first.

## Step 2 — Define scope and roles
1. Confirm the program scope (which publishers/product families are in v1) and write it down.
2. Create the RACI named `SAM RACI - Program - All Stages`. Map each lifecycle stage (Request,
   Entitlement, Deployment, Reconciliation, Renewal/Retirement) to Responsible, Accountable,
   Consulted, Informed against the core roles: Executive Sponsor, SAM Lead, Procurement Liaison,
   IT/Deployment Owner, Finance Liaison.
3. Circulate the RACI for acknowledgement so every owner has accepted their stage.

## Step 3 — Stand up the system of record
1. Create or designate the register named `SAM Register - Entitlements - System of Record`.
2. Define its required fields: product, publisher, entitlement quantity, metric, contract ID,
   renewal date, cost center, and latest Effective License Position (ELP).
3. Import current entitlements from purchase orders and true-up statements; declare this register the
   single source of truth and retire competing spreadsheets.

## Step 4 — Stand up the intake channel
1. Create the request item/form named `SAM Intake - Software Requests - Request Stage` in the
   service-desk tool.
2. Define its fields (product, business justification, cost center, approver) and its routing so an
   approved request reaches the Procurement Liaison.
3. Publish it as the only supported way to request software, and link it from the IT portal.

## Step 5 — Author the SOP set
1. Create the SOP set named `SAM SOP Set - Program - All Stages` with one procedure per lifecycle
   stage:
   - Request SOP — capture, classify, and route through the intake; approve against budget/policy.
   - Entitlement SOP — fulfil from reharvested/pooled entitlements first, then procure; record the
     purchase and terms in the register.
   - Deployment SOP — deliver to the user/device and record the assignment for later reconciliation.
   - Reconciliation SOP — compare deployment/usage to entitlement; compute and record the ELP.
   - Renewal/Retirement SOP — review upcoming renewals against ELP and usage; renew, renegotiate, or
     retire and reharvest.
2. Store the SOP set alongside the register and reference it from the RACI.

## Step 6 — Define the KPI set and reporting
1. Create the KPI set named `SAM KPI Set - Program - All Stages` with these measures and targets:
   - License compliance (% of products with ELP at or above 100% entitled, none under-licensed).
   - Reconciliation coverage (% of in-scope products reconciled within the cadence).
   - Renewal lead time (days of notice before each renewal; target: review opened 90 days out).
   - Reharvest savings (entitlements reclaimed and reused, in currency).
   - Request cycle time (median days from intake to fulfilment).
2. Build the report with `SAMPROG-Report.ps1`, which renders the KPI set and a simple maturity
   snapshot from available signals.

## Step 7 — Establish the governance cadence
1. Schedule the forum named `SAM Governance Cadence - Program - Reconciliation & Renewal`: monthly for
   reconciliation, quarterly for renewal review.
2. Set the standing agenda from the KPI set; the SAM Lead presents, the Executive Sponsor chairs,
   renewal decisions are recorded back into the register.

## Step 8 — Build the pilot scope
1. Run `SAMPROG-Set-ScopeTargeting.ps1` to create the pilot scope group (for example, one department
   or one publisher) so the first governance cycle has a bounded, well-understood target.
2. Confirm the pilot scope's data owners are named in the RACI for that scope.

## Step 9 — Run the first governance cycle on the pilot
1. Execute the lifecycle end to end on the pilot scope using the SOP set: process a real request,
   record the entitlement, confirm deployment, then reconcile.
2. Run `SAMPROG-Validation.ps1` to confirm process/data coverage for the pilot scope (register
   populated, discovery data present, intake live).
3. Run `SAMPROG-Report.ps1` to produce the first KPI/ELP snapshot for the pilot.

## Step 10 — Validate against the pilot gate
1. Complete the Testing Guide. The pilot passes only when the lifecycle ran end to end, the ELP is
   computed for the pilot scope, and the KPI set reports without gaps.
2. Remediate any data gaps with `SAMPROG-Remediation.ps1` (runs with `-WhatIf` by default) before
   re-running validation.

## Step 11 — Expand across the estate
1. After the pilot passes the gate, widen scope one publisher/department at a time, re-running
   `SAMPROG-Set-ScopeTargeting.ps1`, `SAMPROG-Validation.ps1`, and `SAMPROG-Report.ps1` for each new
   scope.
2. Keep the cadence running; the KPI set and ELP now cover the expanding estate.

---
### Order of operations
`Assess -> Roles/RACI -> System of record -> Intake -> SOP set -> KPI set -> Cadence -> Pilot scope -> First cycle -> Validate gate -> Expand`
