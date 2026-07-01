# 6. Troubleshooting Guide — ServiceNow SAM Request Fulfillment & License Reclamation Workflow

Use `SNOWSAM-Validation.ps1` / `SNOWSAM-Discovery.ps1` for state, `SNOWSAM-Report.ps1` for KPIs, and
`SNOWSAM-Remediation.ps1` (default `-WhatIf`) for safe fixes. ServiceNow module internals are deferred to
ServiceNow's documentation; the table below addresses the workflow design.

## A. Requests not flowing through triage
| Symptom | Cause | Remediation |
|---|---|---|
| Request submitted but never triaged | `Request Triage – Software – Triage` not active or trigger mismatched | Confirm the flow is active and its trigger matches the catalog item; run `SNOWSAM-Validation.ps1` |
| Restricted request never approved | `Approval Group – Restricted Software – Triage` empty or unstaffed | Add members and a group manager; re-test routing |
| Standard request asks for approval | Auto-approve rule not matching the owned entitlement | Check the triage categorization and the entitlement-match rule |

## B. Entitlement check wrong
| Symptom | Cause | Remediation |
|---|---|---|
| "Available" when pool is exhausted | available not computed as purchased minus allocated | Fix `Entitlement Check – Software – Entitlement` math; reconcile entitlement records |
| Consumes the wrong entitlement | Entitlement-match rule ambiguous when several records exist | Make the match rule deterministic (edition / version / cost-center) |
| No entitlement found | Software model not linked to an entitlement | Link the model to the entitlement record; run `SNOWSAM-Discovery.ps1` |

## C. Fulfillment not recording
- Confirm `License Fulfillment – Software – Fulfillment` decrements available and stamps fulfillment time.
- If the task never assigns, check `Fulfillment Group – Software – Fulfillment` membership.

## D. Reclamation flags active users (false positives)
| Symptom | Cause | Remediation |
|---|---|---|
| Active user flagged for reclaim | No/stale usage signal feeding `Reclaim Rule – No Usage 90d – Reclamation` | Confirm discovery/usage data is current; lengthen the window; keep report-only until clean |
| Departed user not flagged | `Reclaim Rule – Inactive User – Reclamation` not reading the HR/identity status | Confirm the inactive/terminated source field; map it into the rule |
| Reclaim removed a needed license | No grace period / notification | Add a grace period and assignee notification before removal |

## E. KPI set empty or wrong
- `SNOWSAM-Report.ps1` returns nothing → confirm Table API access and that requests/entitlements exist in
  scope; check the instance URL and credentials.
- Numbers look off → confirm time-to-fulfill uses the fulfillment timestamp from Step 5 and reclamation
  events are recorded.

## F. Diagnostics quick reference
- Run `SNOWSAM-Discovery.ps1` to dump request, entitlement, and usage records via the Table API.
- Run `SNOWSAM-Validation.ps1` to confirm catalog items, flows, and entitlements are present.
- Run `SNOWSAM-Remediation.ps1` with the default `-WhatIf` to preview stale-entitlement fixes before
  applying.

## G. When to escalate
If the flows are active and staffed, entitlement and usage data are current, the scripts confirm records
are present, and requests still stall or reclamation still misfires, capture the script output and the
flow execution details and open a ServiceNow support case (module-internal behavior is vendor-supported).
