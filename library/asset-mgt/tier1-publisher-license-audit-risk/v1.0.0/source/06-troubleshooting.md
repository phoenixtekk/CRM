# 6. Troubleshooting Guide — Tier-1 Publisher License & Audit-Risk Management

Use `TIER1LIC-Discovery.ps1` to (re)assemble the inventory, `TIER1LIC-Validation.ps1` for
metric-mapping flags, `TIER1LIC-Report.ps1` for position and exposure, and
`TIER1LIC-Remediation.ps1` (default `-WhatIf`) to propose safe gap closure.

## A. Deployment will not map to a metric
| Symptom | Cause | Remediation |
|---|---|---|
| Rows flagged "no metric" | Product not in the position worksheet, or metric undefined | Add the product and its governing metric from the contract (Requirement 2.2); re-run validation |
| Rows flagged "missing cores/core factor" | Inventory lacks core count or the core factor was not recorded | Join host topology to the inventory (Requirement 2.4) and record the core factor; re-run validation |
| Named-user products show zero users | User/authorization data not in the export | Add authorized users/accounts to the inventory for that product; re-run validation |

## B. Position looks wrong (too good or too bad)
| Symptom | Cause | Remediation |
|---|---|---|
| Exposure unrealistically low | Sub-capacity counting assumed without the prerequisite | Confirm the required measurement tool is deployed and reporting; if not, recalculate at full capacity (Requirement 2.5) |
| Exposure unrealistically high | Processor/value-unit product counted at host/cluster when guest counting applies (or vice versa) | Re-check the topology decision per Requirement 2.4 and correct the counting basis; re-run report |
| Entitlement looks short | Contract amendments or additional orders not loaded | Reconcile entitlements against all ordering documents/amendments; update the worksheet |

## C. Discovery is incomplete
- A tier-1 product is installed but missing from the inventory: confirm the discovery source covers
  that host; supplement with a manual host list and re-run `TIER1LIC-Discovery.ps1`. Inventory gaps
  are unknown exposure, not zero exposure.

## D. Options / add-ons appear unexpectedly
- Oracle options/management packs or unentitled SAP user types/engines show as deployed: verify
  entitlement in the contract; if unentitled, add to the exposure register and treat as licensable
  until proven otherwise.

## E. Remediation concern
- Remediation must never change a system on its own: it runs in `-WhatIf` by default and only
  proposes a work list. Perform approved actions through your normal change process, then re-run
  validation and the report so the exposure register reflects the new position.

## F. Quick reference
```text
TIER1LIC-Discovery.ps1   -InventoryCsv <path> -Publisher <Name>   # assemble inventory (read-only)
TIER1LIC-Validation.ps1  -InventoryCsv <path> -Publisher <Name>   # map to metric, list flags
TIER1LIC-Report.ps1      -InventoryCsv <path> -Publisher <Name>   # position + exposure register
TIER1LIC-Remediation.ps1 -InventoryCsv <path> -Publisher <Name>   # propose fixes (-WhatIf default)
```
The contract and the publisher remain authoritative for exact metric definitions, core factors, user
categories, and rates — confirm there before acting on a calculated position.

## G. When to escalate
If deployment maps cleanly, topology and sub-capacity prerequisites are confirmed, entitlements are
fully reconciled, and the calculated position still looks implausible, escalate to the contract
owner / procurement and, where the metric interpretation itself is in question, to the publisher —
in writing — before an audit is opened.
