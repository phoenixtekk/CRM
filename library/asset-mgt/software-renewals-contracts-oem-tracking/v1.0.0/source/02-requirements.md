# 2. Requirements Guide — Software Renewals, Contracts & OEM Bundle Tracking

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-asset-mgt.md` (G1–G7);
the items below are specific to the renewal, contract, and OEM-bundle process.

## 2.1 Contract and entitlement source documents
Description: Access to the actual contracts, order forms, true-up statements, and OEM/bundle
agreements for the products in scope.
Why: The repository can only be as accurate as the documents it is built from; renewal dates, notice
periods, and bundle entitlements come from these.
Verify: You can open a representative contract and read its term, renewal date, and notice period.
Implement-if-missing: Collect contracts from procurement, finance, and vendor portals; for missing
documents, request a renewal/entitlement statement from each vendor or reseller.

## 2.2 A controlled repository location
Description: A maintained, access-controlled store for the `Contract & Entitlement Repository – All
Products – Master` — a SAM/ITAM tool, a CMDB table, or a controlled spreadsheet/CSV.
Why: The repository is the single source of truth the calendar, alerts, and cost report all read from.
Verify: You can locate and edit a controlled record with the repository schema (see Step 2 of the
Implementation Guide); access is limited to the SAM team.
Implement-if-missing: Stand up the repository using the documented schema; restrict edit rights to
the SAM analyst and approver; keep a version history.

## 2.3 Renewal dates and contract terms captured
Description: For each in-scope contract: renewal date, notice/cancellation period, auto-renew flag,
quantity, and cost.
Why: These five fields drive the calendar and the lead-time alerts; without them a renewal cannot be
watched or decided.
Verify: Run `SWRENEW-Validation.ps1` against the repository CSV — it flags records missing any of
these fields.
Implement-if-missing: Fill the gaps from the source documents; for truly unknown dates, request them
from the vendor and use `SWRENEW-Remediation.ps1` to insert placeholder records pending confirmation.

## 2.4 OEM and bundle relationships known
Description: Knowledge of which purchases are OEM/suite/volume bundles and which child entitlements
each one contains.
Why: Bundles share a single renewal anchor; tracking children separately double-counts cost and hides
dependencies.
Verify: You can identify, for a representative bundle, its parent SKU and the products it entitles.
Implement-if-missing: Build the `OEM Bundle Map – Vendor Bundles – Master` from order forms and
vendor SKU documentation; link each child entitlement to its parent and shared renewal anchor.

## 2.5 An alerting mechanism
Description: A way to deliver the `Lead-Time Alert Rules – Renewals – Tiered` notifications — email,
a ticketing queue, a calendar with reminders, or a scheduled report.
Why: A renewal date with no notification is invisible; the alert is what triggers the decision
workflow.
Verify: You can send a test reminder to a renewal owner and confirm receipt.
Implement-if-missing: Choose the channel (a shared mailbox, a ServiceNow queue, or scheduled
`SWRENEW-Report.ps1` output) and document who receives each tier.

## 2.6 Named renewal owners and a procurement liaison
Description: A named owner per contract (or product family) and a procurement contact who executes
decisions.
Why: The decision workflow routes each renewal to a person; unrouted renewals stall.
Verify: For a representative contract you can name the renewal owner and the procurement liaison.
Implement-if-missing: Assign owners in the repository; build `Renewal Owners – Pilot Scope – Group`
and `Renewal Owners – All Products – Group` with `SWRENEW-Set-ScopeTargeting.ps1` for routing.

## 2.7 Subscription data access (where available)
Description: Microsoft Graph read access to subscribed-SKU / subscription data for products that
expose it (e.g. Microsoft 365).
Why: Where a vendor exposes renewal/subscription data programmatically, the discovery script can seed
the repository instead of manual entry.
Verify: `SWRENEW-Discovery.ps1` connects to Graph and returns subscribed SKUs.
Implement-if-missing: Grant the read scope (`Organization.Read.All` / `Directory.Read.All`) and
install the Microsoft Graph PowerShell SDK; for vendors with no API, rely on the CSV repository.

---
## Checklist
- [ ] Contract / order / true-up / bundle documents collected
- [ ] Controlled repository location stood up (schema in Implementation Step 2)
- [ ] Renewal date, notice period, auto-renew, quantity, cost captured — `SWRENEW-Validation.ps1`
- [ ] OEM/bundle parent-child relationships known
- [ ] Alerting channel chosen and tested
- [ ] Named renewal owners + procurement liaison assigned
- [ ] Microsoft Graph subscription read access (where the product exposes it) — `SWRENEW-Discovery.ps1`
- [ ] Pilot product family selected (G7)
