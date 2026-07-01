# 2. Requirements Guide — Tier-1 Publisher License & Audit-Risk Management

Verify every requirement before configuring. Each entry: Description, Why, Verify, and
Implement-if-missing. Category-wide prerequisites are in `global-requirements-asset-mgt.md` and are
assumed here.

## 2.1 Per-publisher contracts and entitlement records
Description: The signed agreements and ordering documents for each tier-1 publisher in scope —
master agreement, ordering documents / order forms, license metric definitions, and any
amendments — plus the current entitlement quantities they grant.
Why: The contract defines which metric governs each product and how it is counted; you cannot
calculate a defensible position without it.
Verify: For one product per publisher, you can locate the governing metric and the entitled
quantity in the contract documents.
Implement: Collect the agreement set from procurement / legal and record entitled quantities into
the per-publisher position worksheet; where a clause is ambiguous, flag it for the publisher rather
than guessing.

## 2.2 Metric definitions for each product in scope
Description: The specific metric (for example Oracle Processor or Named-User Plus, IBM PVU, SAP
named-user type or digital access) that applies to each deployed product, with the counting rules
that go with it.
Why: Mapping deployment to the wrong metric produces a wrong position and false confidence.
Verify: Each product line in the position worksheet has a named metric and a one-line counting rule.
Implement: Confirm each metric from the contract and the publisher's current definitions; record the
applicable core factor, user-type, or document-counting basis per product. Defer exact rates to the
publisher.

## 2.3 Deployment / installation inventory for tier-1 products
Description: An export of what is actually installed and where it runs for each publisher's
products — host name, the product/edition, the host's processor/core configuration, virtualization
host and cluster, and (for user-based metrics) the authorized users or accounts.
Why: Position is calculated by mapping real deployment to the metric; the inventory is the input.
Verify: You can produce a CSV of tier-1 product installs with host, edition, and core/user data for
a sample.
Implement: Export from your discovery tool / CMDB / inventory (see global requirement on deployment
data); where automated discovery misses a product, supplement with a manual host list. Run
`TIER1LIC-Discovery.ps1` to assemble the inventory baseline.

## 2.4 Host and virtualization topology
Description: A record of physical hosts, cores per host, hypervisor type, clusters, and which
guests can run tier-1 software — because processor- and value-unit metrics often count the host or
cluster capacity, not just the guest.
Why: For Oracle Processor and IBM PVU, virtualization and clustering rules can pull entire hosts or
clusters into scope; getting topology wrong is the single most common cause of a wrong position.
Verify: For a sampled processor-counted product, you can state the host, cores, and cluster it
belongs to.
Implement: Capture topology from your virtualization platform export and join it to the deployment
inventory in the deployment-to-metric mapping.

## 2.5 Sub-capacity / lower-cost-counting prerequisites (where claimed)
Description: The conditions a publisher requires before you may license less than full capacity —
for example a required metering/measurement tool deployed and reporting, or an approved deployment
configuration.
Why: If you assume sub-capacity counting but the prerequisites are not met, the publisher will count
full capacity and your real exposure is far larger than your worksheet shows.
Verify: For any product where you claim reduced counting, the required tool is installed and
producing current reports.
Implement: Deploy and confirm the required measurement tooling, or recalculate that product at full
capacity until the prerequisites are genuinely in place.

## 2.6 Reporting toolchain for position and exposure
Description: Spreadsheet / BI tooling to hold the per-publisher position worksheet and exposure
register and to produce the reports (see category global requirement on the reporting toolchain).
Why: Position, exposure, and gap-closure are delivered as auditable worksheets and reports.
Verify: You can open the worksheet template and connect it to the inventory CSV.
Implement: Stand up the worksheet/BI workbook; `TIER1LIC-Report.ps1` writes the position and
exposure outputs into it.

## 2.7 Owner sign-off and the exposure register
Description: A named owner (SAM analyst plus a business/procurement approver) for each publisher and
an agreed register where exposure items, decisions, and controls are recorded and tracked.
Why: Closing a gap or accepting risk is a business decision; exposure must have an owner and an
audit trail.
Verify: For the pilot publisher, the register exists and has a named owner and approver.
Implement: Create the per-publisher exposure register and assign owners (see category global
requirement on stakeholder alignment).

## 2.8 Pilot publisher scope
Description: One tier-1 publisher chosen to prove the process end-to-end before the others.
Why: Every solution is piloted before broad adoption to validate accuracy and avoid disruption.
Verify: A pilot publisher and its data owners are identified.
Implement: Choose the publisher with the clearest contracts and inventory as the first pass; use
`TIER1LIC-Set-ScopeTargeting.ps1` to build the scope group.

---
## Checklist
- [ ] Per-publisher contracts and entitlement records gathered
- [ ] Metric defined for each in-scope product
- [ ] Deployment / installation inventory exported — `TIER1LIC-Discovery.ps1`
- [ ] Host and virtualization topology captured
- [ ] Sub-capacity / lower-cost-counting prerequisites verified where claimed
- [ ] Reporting toolchain ready (position worksheet + exposure register)
- [ ] Exposure register created with named owner and approver
- [ ] Pilot publisher scope chosen — `TIER1LIC-Set-ScopeTargeting.ps1`
