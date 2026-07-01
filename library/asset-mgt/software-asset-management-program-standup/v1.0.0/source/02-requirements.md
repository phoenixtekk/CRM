# 2. Requirements Guide — Software Asset Management (SAM) Program Standup & Governance

Verify every requirement before standing up the program. Each entry: Description, Why, Verify,
Implement-if-missing. Category-wide prerequisites are in `global-requirements-asset-mgt.md`.

## 2.1 A system of record for entitlements
Description: A single authoritative register of purchased entitlements, contracts, and renewal dates
— named `SAM Register - Entitlements - System of Record`. A SAM/ITAM tool, a ServiceNow/CMDB
instance, or, at minimum, a controlled spreadsheet/repository.
Why: Every other stage (reconciliation, renewal, reporting) compares against this register; without
one authoritative count there is no Effective License Position and no compliance answer.
Verify: You can locate the current entitlement quantity and renewal date for a representative product
in one place that everyone agrees is authoritative.
Implement-if-missing: Stand up the register (start with the controlled spreadsheet if no tool exists),
import current purchase orders and true-up statements, and declare it the single source of truth.

## 2.2 Deployment / usage discovery data
Description: A source of what is actually installed or used — Microsoft Intune, Configuration Manager,
a discovery tool, or sign-in/usage telemetry.
Why: Reconciliation compares deployed/used quantities to entitled quantities; without discovery data
the ELP cannot be computed.
Verify: You can export an installed-software or license-usage report for a sample of devices/users;
run `SAMPROG-Discovery.ps1`.
Implement-if-missing: Enable Intune/Configuration Manager inventory or onboard a discovery tool; for
SaaS, enable usage/sign-in reporting.

## 2.3 A request / intake channel
Description: One channel through which all software requests enter the program — named
`SAM Intake - Software Requests - Request Stage` — typically a ServiceNow request item or equivalent
service-desk form.
Why: A single intake is what makes the Request stage governable; scattered email/Teams requests can
never be tracked, approved, or measured for cycle time.
Verify: A test software request can be raised and is routed to the correct approver; run
`SAMPROG-Validation.ps1` (checks intake-coverage signals).
Implement-if-missing: Create the request item/form in the service-desk tool, define its fields
(product, business justification, cost center), and publish it as the only supported way to ask for
software.

## 2.4 Named owners and a RACI
Description: Named people for the core roles (Executive Sponsor, SAM Lead, Procurement Liaison,
IT/Deployment Owner, Finance Liaison), mapped to the lifecycle in a single RACI — named
`SAM RACI - Program - All Stages`.
Why: A program is a set of repeatable decisions; decisions need accountable owners or they stall.
Verify: For each lifecycle stage you can name the Responsible and Accountable person.
Implement-if-missing: Assign the roles to named individuals, complete the RACI, and circulate it for
acknowledgement.

## 2.5 Executive sponsorship
Description: A named Executive Sponsor with authority over IT, procurement, and finance stakeholders.
Why: SAM crosses department lines (IT owns deployment, procurement owns contracts, finance owns
budget); only a sponsor can resolve cross-team disputes and enforce the single intake.
Verify: The sponsor is named in the RACI and has agreed to chair the governance cadence.
Implement-if-missing: Secure a sponsor at the IT-director level or above and document the mandate.

## 2.6 A governance cadence and forum
Description: A recurring forum — named `SAM Governance Cadence - Program - Reconciliation & Renewal` —
where the SAM Lead presents the KPI set and the ELP, and renewal decisions are made.
Why: A lifecycle that is never reviewed drifts back to spreadsheet chaos; the cadence is what keeps it
running.
Verify: A recurring meeting exists with the right owners invited and an agenda anchored on the KPI
set.
Implement-if-missing: Schedule a monthly (reconciliation) and quarterly (renewal review) cadence; set
the standing agenda from the KPI set.

## 2.7 A pilot scope
Description: A representative subset — one product family, one department, or one publisher — to prove
the program before estate-wide rollout.
Why: The program is validated on a pilot before broad adoption to confirm the lifecycle, data, and
KPIs work end to end.
Verify: A pilot scope and its data owners are identified; run `SAMPROG-Set-ScopeTargeting.ps1` to
build the pilot scope group.
Implement-if-missing: Choose a high-value, well-understood product/department as the first pass.

---
## Checklist
- [ ] System of record exists — `SAM Register - Entitlements - System of Record`
- [ ] Discovery / usage data available — `SAMPROG-Discovery.ps1`
- [ ] Single intake channel — `SAM Intake - Software Requests - Request Stage`
- [ ] Named owners and RACI — `SAM RACI - Program - All Stages`
- [ ] Executive sponsor named
- [ ] Governance cadence scheduled — `SAM Governance Cadence - Program - Reconciliation & Renewal`
- [ ] Pilot scope identified — `SAMPROG-Set-ScopeTargeting.ps1`
