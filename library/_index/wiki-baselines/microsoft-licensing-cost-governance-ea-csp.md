# Microsoft Licensing Cost Governance — EA, CSP & True-Up Readiness

> **Version 1.0.0** · Category: Asset Mgt · Solution code: MSLICGOV

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Licensing Cost Governance (EA, CSP & True-Up Readiness)

Microsoft licensing is a moving target. An Enterprise Agreement (EA) here, Cloud Solution Provider
(CSP) subscriptions there, an annual true-up that arrives with surprises, and a renewal that lands
before anyone has modelled what is actually needed. Without governance, organizations over-buy to
feel safe or under-license and carry a shortfall risk. Both cost money.

This is a complete, repeatable package for establishing Microsoft licensing cost governance across
EA and CSP. It gives a competent software asset management (SAM) analyst a known license position,
true-up readiness, right-sized renewals, and an ongoing governance cadence with measurable KPIs —
without inventing a single contract term.

## What you get
- A plain-language Solution Overview of the EA and CSP commercial models, how true-ups work, the
  cost-governance cadence, and how entitlement counts map to deployment and growth.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps — inventory agreements and entitlements, map
  deployment and growth, model true-up exposure, set renewal and right-sizing decisions, then
  pilot, validate, and expand.
- Five PowerShell scripts for entitlement and assignment discovery, true-up-exposure validation, a
  license-position and cost report, safe remediation of mis-assignments, and a governance-scope
  group builder.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best
  Practices.

## What this delivers
A governed, predictable licensing estate: an authoritative `License Position Register – EA+CSP –
Steady-State`, a completed `True-Up Worksheet – Enterprise Agreement – Annual`, right-sized renewal
decisions, and a recurring `Cost Governance Cadence – Tenant-Wide – Ongoing` measured by a defined
KPI set. Proven on a pilot scope before it is applied estate-wide.

## The standard deployment model
Assess to Configure to Pilot to Validate to Expand — with a pilot gate that must pass before any
estate-wide action.

## Outcome
Microsoft licensing under control across EA and CSP — a known license position, true-ups that hold
no surprises, and right-sized renewals — established by a single SAM analyst and validated before
you scale.


---


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


---


# 2. Requirements Guide — Microsoft Licensing Cost Governance (EA, CSP & True-Up Readiness)

Verify every requirement before you configure anything. Each entry follows: Description · Why ·
Verify · Implement-if-missing. Category-wide prerequisites (tenant, admin access, system of record,
discovery data, reporting toolchain, stakeholders, pilot) are in
`global-requirements-asset-mgt.md` — confirm those first; the items below are specific to licensing
cost governance across EA and CSP.

## 2.1 Billing/admin visibility into the license sources
Description: An account that can read licensing and billing in the Microsoft 365 admin center
(`https://admin.microsoft.com`) — at minimum the License Administrator and Billing Administrator
roles (or Global Reader for read-only governance).
Why: The deployed/assigned position and the subscribed quantities are read here; cost governance
cannot proceed without it.
Verify: Sign in to `https://admin.microsoft.com` and open Billing then Your products, and Billing
then Billing accounts — both load and show subscriptions/quantities.
Implement: Assign least-privilege roles (License Administrator plus Billing Administrator, or Global
Reader) in `https://entra.microsoft.com` then Roles and admins; reserve Global Administrator for
tenant-wide changes only.

## 2.2 Microsoft Graph access for license reads
Description: The ability to run Microsoft Graph PowerShell with the `Organization.Read.All` and
`User.Read.All` scopes (read-only) to enumerate `subscribedSkus` and per-user license assignments.
Why: The Discovery, Validation, and Report scripts read the deployed position directly from the
tenant via Graph; this is the authoritative assignment count.
Verify: Run `Connect-MgGraph -Scopes 'Organization.Read.All','User.Read.All'` and then
`Get-MgSubscribedSku` returns rows.
Implement: Install the Microsoft Graph PowerShell SDK
(`Install-Module Microsoft.Graph -Scope CurrentUser`) and consent the read scopes when prompted; a
Global Reader or License Administrator can consent for themselves.

## 2.3 Agreement details (EA and/or CSP) — from the agreement, not assumed
Description: The signed EA enrolment details (committed baseline quantities, products in scope,
anniversary/true-up window, term dates) and/or the CSP subscription details (products, seat counts,
term, adjustment points) as recorded in the agreement and the procurement/licensing portal.
Why: The entitlement (owned) side of every position comes from the agreement; without it you can
read deployment but cannot compute position or true-up exposure.
Verify: You can state, for one representative product, the committed/owned quantity and the renewal
or anniversary date from the agreement or portal.
Implement: Obtain the current EA enrolment summary and CSP subscription export from the licensing
partner or the procurement/EA portal; record them in the system of record (G3). Do not estimate
contract terms — defer specifics to the agreement and procurement.

## 2.4 The License Position Register
Description: A controlled register — `License Position Register – EA+CSP – Steady-State` — listing,
per product/SKU, the owned quantity (from the agreement), the channel (EA or CSP), the assigned
quantity (from the tenant), the resulting position, and the renewal/anniversary date.
Why: This is the single artifact that reconciles entitlement to deployment; every KPI and decision
references it.
Verify: The register exists and has at least the pilot scope's products populated with owned and
assigned columns.
Implement: Create the register (spreadsheet or SAM tool) using the columns above; seed owned counts
from 2.3 and assigned counts from `MSLICGOV-Report.ps1`.

## 2.5 Deployment/usage data for utilization
Description: Sign-in/usage telemetry sufficient to distinguish assigned-but-unused licenses from
active ones (covered category-wide in G4) for the products in scope.
Why: Reharvesting and right-sizing depend on knowing which assigned seats are actually used.
Verify: You can export or read a last-activity/sign-in signal for a sample of licensed users.
Implement: Enable usage/sign-in reporting (Microsoft 365 usage reports or Entra sign-in logs);
where richer data is needed, onboard the discovery tool from G4.

## 2.6 Procurement and finance alignment
Description: Named owners in procurement and finance, plus the renewal/true-up calendar, so position
data turns into purchasing decisions on time.
Why: True-ups and renewals have fixed windows; a known position is only valuable if a decision-maker
acts on it before the deadline.
Verify: You can name the procurement liaison and the next renewal/true-up date for the pilot scope.
Implement: Confirm roles (SAM analyst, approver, procurement liaison) per G6 and record the renewal
and anniversary/true-up dates in the register.

---
## Checklist
- [ ] Billing/admin visibility in `https://admin.microsoft.com` (License + Billing roles)
- [ ] Microsoft Graph read access — `Get-MgSubscribedSku` returns rows
- [ ] Agreement details captured (EA baseline / CSP subscriptions) from the agreement/portal
- [ ] `License Position Register – EA+CSP – Steady-State` created and seeded
- [ ] Deployment/usage signal available for utilization
- [ ] Procurement/finance owners and renewal/true-up dates known
- [ ] Pilot scope chosen (one product family or department) per G7


---


# Global Requirements — Asset Mgt (category-level)

These requirements apply to **every** solution in the **Asset Mgt** category (Software Asset
Management, license compliance, and entitlement governance). They are published once at the category
level so individual listings stay small. Confirm these before deploying *any* Asset Mgt solution.
Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** Identity is the backbone for user-based license assignment, access, and reporting.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Administrative access to the license sources
**Description:** Admin rights to the consoles that hold entitlements — at minimum the Microsoft 365
admin center (`https://admin.microsoft.com`), plus any others in scope (Adobe Admin Console,
publisher portals).
**Why:** Reading and adjusting entitlements, assignments, and true-ups requires elevated rights.
**Verify:** Each console loads and shows the licensing/billing area for an admin account.
**Implement:** Assign the least-privilege admin role per console (e.g. License Administrator or
Billing Administrator in Microsoft 365); reserve Global Administrator for tenant-wide changes.

## G3. A system of record for entitlements
**Description:** A maintained record of purchased entitlements, contracts, and renewal dates — a
SAM/ITAM tool, a ServiceNow/CMDB instance, or (at minimum) a controlled spreadsheet/repository.
**Why:** Compliance and optimization are only possible against a known, authoritative entitlement count.
**Verify:** You can locate the current entitlement quantity and renewal date for a representative product.
**Implement:** Stand up the records repository and import current purchase orders / true-up statements.

## G4. Deployment / usage discovery data
**Description:** A source of what is actually installed or used — Microsoft Intune, Configuration
Manager (SCCM), a discovery tool (e.g. Flexera), or sign-in/usage telemetry.
**Why:** Reconciling entitlements against real deployment/usage is the core of compliance and reharvesting.
**Verify:** You can export an installed-software or license-usage report for a sample of devices/users.
**Implement:** Enable Intune/Configuration Manager inventory or onboard a discovery tool; for SaaS,
enable usage/sign-in reporting.

## G5. Reporting toolchain
**Description:** Excel (PivotTables, Power Query) and/or Power BI for analysis and dashboards.
**Why:** License usage, compliance, and cost-optimization findings are delivered as reports/dashboards.
**Verify:** Power BI Desktop opens and can connect to a data source; Excel Power Query is available.
**Implement:** Install Power BI Desktop and a current Excel; provision a Power BI workspace if sharing.

## G6. Stakeholder and process alignment
**Description:** Named owners across IT, procurement, and finance, plus a request/intake channel
(e.g. ServiceNow) for license actions.
**Why:** Renewals, true-ups, and reharvesting require coordinated decisions and an auditable workflow.
**Verify:** A request can be raised and routed to the correct owner; procurement contacts are known.
**Implement:** Define roles (SAM analyst, approver, procurement liaison) and a documented intake process.

## G7. A pilot scope
**Description:** A representative subset (one product family, one department, or one publisher) to prove
the process before fleet-wide rollout.
**Why:** Every solution is piloted before broad adoption to validate accuracy and avoid disruption.
**Verify:** A pilot scope and its data owners are identified.
**Implement:** Choose a high-value, well-understood product/department as the first pass.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# 5. Testing Guide — Microsoft Licensing Cost Governance (EA, CSP & True-Up Readiness)

Run these after the pilot scope is built (Implementation Step 7) and again each governance cadence
cycle. Use `MSLICGOV-Discovery.ps1` and `MSLICGOV-Validation.ps1` for tenant reads and
`MSLICGOV-Report.ps1` for the position/cost report.

## Test 1 — Entitlements captured (owned side)
Do: Open the `License Position Register – EA+CSP – Steady-State`.
Expected: Every pilot product has an owned quantity, a channel (EA or CSP), and a
renewal/anniversary date sourced from the agreement (no blank or assumed terms).

## Test 2 — Deployment read (assigned side)
Do: Run `MSLICGOV-Discovery.ps1` and compare its assigned/consumed counts to Billing then Licenses
in `https://admin.microsoft.com`.
Expected: Script counts match the admin center for the pilot products; assigned column in the
register is populated from these.

## Test 3 — Position reconciles
Do: For each pilot product confirm position equals owned minus assigned in the register.
Expected: Position is correct and signed (positive is headroom, negative is exposure); no product is
left unreconciled.

## Test 4 — True-up exposure forecast (EA)
Do: Run `MSLICGOV-Validation.ps1` with the EA baselines supplied; compare to the
`True-Up Worksheet – Enterprise Agreement – Annual`.
Expected: Per EA SKU, assigned-minus-baseline delta matches the worksheet; the forecast true-up
quantity is stated. CSP products correctly show no true-up.

## Test 5 — Utilization and reharvest candidates
Do: Run `MSLICGOV-Report.ps1`; review assigned-but-unused seats.
Expected: A list of reharvest candidates with a utilization signal; at least one is validated as
genuinely unused before remediation.

## Test 6 — Safe remediation preview
Do: Run `MSLICGOV-Remediation.ps1` (default `-WhatIf`) against the pilot scope.
Expected: It prints the planned changes only and makes no change; re-running with `-Confirm` applies
exactly those changes on the pilot scope.

## Test 7 — Scope targeting
Do: Run `MSLICGOV-Set-ScopeTargeting.ps1` and confirm in `https://entra.microsoft.com` then Groups.
Expected: `License Governance – Pilot Scope – Stage1` and `License Governance – Estate Scope –
Stage2` exist with the intended membership.

## Test 8 — Position/cost report
Do: Run `MSLICGOV-Report.ps1` scoped to the pilot.
Expected: A per-product report (owned, assigned, position, utilization) that agrees with the
register and the worksheet.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 4 and Test 8 pass for the pilot scope; at least one reharvest/right-size action validated (Tests 5 to 6) without disruption |
| Estate pass | Tests 1 to 4, 7, 8 pass estate-wide before the next renewal/true-up window |


---


# 6. Troubleshooting Guide — Microsoft Licensing Cost Governance (EA, CSP & True-Up Readiness)

Use `MSLICGOV-Discovery.ps1` and `MSLICGOV-Validation.ps1` for tenant reads, `MSLICGOV-Report.ps1`
for the position/cost report, and `MSLICGOV-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. Script counts do not match the admin center
| Symptom | Cause | Remediation |
|---|---|---|
| Assigned count differs from Billing then Licenses | Stale read, or group-based licensing still processing | Re-run `MSLICGOV-Discovery.ps1`; allow group-based assignments to finish; reconcile per-user vs group counts |
| `Get-MgSubscribedSku` returns nothing | Not connected, or missing scope | Run `Connect-MgGraph -Scopes 'Organization.Read.All','User.Read.All'` and retry |
| Friendly product names missing | SKU part numbers not mapped | Map `skuPartNumber` to product names in the register; the script reports the raw part number |

## B. Position looks wrong
| Symptom | Cause | Remediation |
|---|---|---|
| Position negative but no shortfall expected | Owned quantity missing/under-recorded | Confirm the owned count from the agreement (Requirement 2.3); update the register |
| Position hugely positive | Counting CSP and EA owned twice, or shelfware | Verify channel per product; flag surplus as reharvest/right-size in the decision log |
| Numbers drift between cycles | No cadence; assignments creep | Run the `Cost Governance Cadence – Tenant-Wide – Ongoing` on schedule |

## C. True-up exposure questions
- True-up reports a large delta: confirm the committed baseline you supplied matches the agreement;
  the delta is assigned minus baseline, not assigned minus zero.
- Expecting to reduce at true-up: you cannot true down mid-term; record the reduction in the
  `Renewal Decision Log – EA+CSP – Per-Cycle` for the next renewal.
- CSP product appears in true-up output: CSP has no true-up — exclude CSP SKUs from the EA worksheet;
  confirm the channel column is correct.
- Unsure of the true-up window or process: defer to the agreement and your licensing partner; do not
  report against an assumed window.

## D. Remediation concerns
- Remediation made no change: that is correct in `-WhatIf` mode (the default). Review the planned
  output, then re-run with `-Confirm` on the pilot scope first.
- Removed a license a user actually needed: restore by re-assigning in `https://admin.microsoft.com`
  then Billing then Licenses; always confirm a utilization signal (Requirement 2.5) before removal.

## E. Scope groups / targeting
- Group not appearing: allow Entra replication; re-run `MSLICGOV-Set-ScopeTargeting.ps1`; confirm the
  account has Groups Administrator or equivalent.
- Wrong membership: review the seeding filter; membership for the named groups
  (`License Governance – Pilot Scope – Stage1`, `License Governance – Estate Scope – Stage2`) should
  match the pilot vs estate split.

## F. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Organization.Read.All','User.Read.All'
Get-MgSubscribedSku | Select-Object SkuPartNumber, @{n='Owned';e={$_.PrepaidUnits.Enabled}}, ConsumedUnits
Get-MgUser -All -Property AssignedLicenses,UserPrincipalName | Select-Object UserPrincipalName, AssignedLicenses
```

## G. When to escalate
If tenant reads match the admin center, the register's owned counts are confirmed from the
agreement, and a position or true-up figure still cannot be reconciled, take the
`License Position Register – EA+CSP – Steady-State` and the `True-Up Worksheet – Enterprise Agreement
– Annual` to procurement and your licensing partner — the remaining gap is a commercial/agreement
question, not a tenant data question.


---


# 7. Best Practices — Microsoft Licensing Cost Governance (EA, CSP & True-Up Readiness)

- Maintain one license position. The `License Position Register – EA+CSP – Steady-State` is the
  single source of truth that reconciles owned to assigned across both channels. Everything else
  references it.
- Own the true-up before it owns you. Keep the `True-Up Worksheet – Enterprise Agreement – Annual`
  current year-round so the anniversary report is a confirmation, not a discovery. Remember you can
  true up but not true down mid-term — reductions wait for renewal.
- Source terms from the agreement, never from memory. Owned quantities, baselines, anniversary
  dates, and adjustment points come from the signed EA/CSP agreement and procurement — confirm,
  don't assume.
- Right-channel each product. EA suits a stable, large core; CSP suits variable headcount and
  granular add-ons. Record a channel recommendation per product in the
  `Renewal Decision Log – EA+CSP – Per-Cycle` and revisit it each cycle.
- Reharvest continuously. Assigned-but-unused seats are pure waste; reclaim them every cadence cycle
  and track Reharvest Yield to prove the governance pays for itself.
- Pilot before estate-wide. Prove the position, the numbers, and at least one right-size action on
  `License Governance – Pilot Scope – Stage1` before touching the estate.
- Remediate with a preview. Always run remediation in `-WhatIf` first; apply with `-Confirm` on the
  pilot scope before the estate. Never bulk-remove licenses without a utilization signal.
- Run a cadence, not a project. The `Cost Governance Cadence – Tenant-Wide – Ongoing` (monthly,
  quarterly, annual) keeps the position from drifting back out of control.
- Measure with the standard KPIs. Track the `Licensing KPI Set – Governance – Standard` (License
  Position, Assignment Utilization, True-Up Exposure, Renewal Variance, Reharvest Yield) and watch
  the trend, not just the snapshot.
- Align procurement and finance to the calendar. A known position only saves money if a decision-
  maker acts before the renewal/true-up window. Keep those dates in the register and brief owners
  ahead of time.
- Keep buffers small and deliberate. A modest positive position absorbs growth without over-buying;
  a large surplus is just early renewal money spent on shelfware.


---


# 8. Deliverables Summary — Microsoft Licensing Cost Governance (EA, CSP & True-Up Readiness)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The EA vs CSP models, how true-ups work, entitlement-to-deployment mapping, the cadence and KPIs, benefits and limits |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps from inventory to cadence, with a pilot gate |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts produced
| Artifact | Purpose |
|---|---|
| `License Position Register – EA+CSP – Steady-State` | Single source of truth reconciling owned to assigned per product/channel |
| `True-Up Worksheet – Enterprise Agreement – Annual` | Forecasts EA true-up exposure year-round |
| `Renewal Decision Log – EA+CSP – Per-Cycle` | Records right-size and channel recommendations per cycle |
| `Cost Governance Cadence – Tenant-Wide – Ongoing` | The recurring monthly/quarterly/annual review |
| `Licensing KPI Set – Governance – Standard` | The five governance KPIs and their baselines |

## PowerShell scripts
| Script | What it does |
|---|---|
| `MSLICGOV-Discovery.ps1` | Reads `subscribedSkus` and assigned/consumed units per SKU via Microsoft Graph (read-only) |
| `MSLICGOV-Validation.ps1` | Computes per-SKU assigned-vs-committed-baseline delta — the forecast true-up exposure (read-only) |
| `MSLICGOV-Report.ps1` | Produces the per-product license-position and cost report with utilization (read-only) |
| `MSLICGOV-Remediation.ps1` | Safely remediates mis-assignments; defaults to `-WhatIf` |
| `MSLICGOV-Set-ScopeTargeting.ps1` | Creates and seeds the governance-scope groups |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess to Configure to Pilot to Validate to Expand.

## Outcome
Microsoft licensing governed across EA and CSP — a known position, predictable true-ups, right-sized
renewals, and an ongoing cadence with KPIs — proven on a pilot before it scales.
