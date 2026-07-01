# 2. Requirements Guide — Software License Compliance & Audit-Defense (Effective License Position)

Verify every requirement before reconciling. Each entry: Description, Why, Verify, and
Implement-if-missing. Category-wide prerequisites are in `global-requirements-asset-mgt.md`.

## 2.1 Entitlement system of record
Description: An authoritative record of purchased entitlements for the in-scope publisher/product —
quantity, edition/version, counting metric, and renewal date — that becomes the
`Entitlement Baseline – <Publisher/Product> – Source`.
Why: An ELP is meaningless without a known, authoritative entitlement count to reconcile against.
Verify: You can locate the current entitlement quantity, edition, and renewal date for the pilot product.
Implement-if-missing: Stand up the records repository (SAM tool, CMDB, or a controlled spreadsheet)
and import current purchase orders, license certificates, and true-up statements.

## 2.2 Proofs of purchase / entitlement evidence
Description: The supporting documents that prove each entitlement line — purchase orders, license
certificates, true-up statements, contract/agreement numbers.
Why: In an audit, an entitlement you cannot evidence is counted as zero; proofs are what make the ELP defensible.
Verify: For a sample of entitlement lines, you can produce the matching purchase record.
Implement-if-missing: Collect proofs from procurement, the publisher portal, and finance; store one
proof reference per entitlement line in the `Entitlement Baseline – <Publisher/Product> – Source`.

## 2.3 Deployment / usage discovery data
Description: A source of what is actually installed, assigned, or used for the in-scope product —
Microsoft Intune, Configuration Manager, a discovery tool, or sign-in/usage telemetry — exported to
the `Deployment Inventory – <Publisher/Product> – Discovered`.
Why: Reconciling entitlements against real deployment/usage is the core of the ELP.
Verify: You can export an installed-software or license-assignment report for the in-scope product;
run `LICCOMP-Discovery.ps1`.
Implement-if-missing: Enable Intune/Configuration Manager inventory or onboard a discovery tool; for
SaaS, enable usage/sign-in reporting and export per-user assignments.

## 2.4 Product use rights for the in-scope product
Description: The licensing rules that govern how the product is counted — counting metric
(per-user, per-device, per-core/processor), downgrade rights, second-use, virtualization, and BYOL.
Why: Applying the wrong metric or ignoring a right is the most common source of an inaccurate ELP and
of audit disputes.
Verify: You can state the counting metric and the applicable rights for the pilot product, with the
contract/agreement clause they come from.
Implement-if-missing: Obtain the publisher's product terms and your contract; record the metric and
rights interpretation as a note in the `Effective License Position – <Publisher/Product> – ELP`.

## 2.5 A reconciliation method
Description: A repeatable way to normalize and reconcile both sides on the same key — the
`Effective License Position – <Publisher/Product> – ELP` workbook (Excel/Power Query) or an equivalent.
Why: Entitlements and deployment rarely share product names or metrics; normalization is what makes
the subtraction valid.
Verify: A workbook exists that joins entitlements to deployment on a normalized product key; run
`LICCOMP-Validation.ps1` to confirm the two input sets are present and reconcilable.
Implement-if-missing: Build the ELP workbook with a normalization mapping table (raw name to
canonical product/edition) and a reconciliation sheet; or use your SAM tool's reconciliation feature.

## 2.6 Owner sign-off
Description: Named owners across SAM, procurement, and finance who approve the ELP and authorize gap
closure (true-up, reharvest, reassignment).
Why: Closing a shortfall spends money and closing a surplus changes renewals — both require an
auditable decision, not an analyst acting alone.
Verify: A gap action can be raised and routed to the correct owner for approval.
Implement-if-missing: Define the SAM analyst, approver, and procurement liaison roles and a documented
intake/approval step for gap actions.

---
## Checklist
- [ ] Entitlement system of record located — `Entitlement Baseline – <Publisher/Product> – Source`
- [ ] Proofs of purchase collected for each entitlement line
- [ ] Deployment/usage discovery exported — `LICCOMP-Discovery.ps1`
- [ ] Product use rights and counting metric recorded for the in-scope product
- [ ] Reconciliation workbook/method ready — `LICCOMP-Validation.ps1`
- [ ] Owners named for ELP sign-off and gap closure
- [ ] Pilot scope chosen (one publisher/product) — `LICCOMP-Set-ScopeTargeting.ps1`
