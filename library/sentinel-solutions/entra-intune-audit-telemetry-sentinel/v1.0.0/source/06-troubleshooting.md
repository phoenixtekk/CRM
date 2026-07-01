# 6. Troubleshooting Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

Use `SENTLOG-Discovery.ps1` for readiness, `SENTLOG-Validation.ps1` for ingestion state, `SENTLOG-Report.ps1` for coverage/retention, and `SENTLOG-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. No data arriving in the workspace

| Symptom | Cause | Remediation |
|---|---|---|
| `SigninLogs` empty after setup | Diagnostic setting missing or pointing at the wrong workspace | Confirm `Audit Telemetry - Entra ID - Pilot` exists and targets `Security Telemetry - Tenant - Workspace`; run `SENTLOG-Remediation.ps1` to add it |
| Connector shows `Not connected` | Connector page never applied | `Microsoft Sentinel` → `Data connectors` → `Microsoft Entra ID` → select log types → `Apply Changes` |
| Data delayed | First events can lag | Wait ~15-30 minutes after enabling; re-run `SENTLOG-Validation.ps1` |

## B. Missing log categories

| Symptom | Cause | Remediation |
|---|---|---|
| Risky/non-interactive sign-ins absent | Category not selected, or license does not expose it | Add the category to the diagnostic setting; confirm the Entra ID plan exposes it (Requirement 2.1) |
| Intune device/compliance events absent | Source not routed, or dedicated solution not installed | Confirm Intune audit telemetry routing (Implementation Step 4); install the endpoint/Intune solution from `Content hub` if offered |

## C. Unexpectedly high ingestion / cost

- High-volume categories (non-interactive, service-principal sign-ins) were enabled before the pilot gate — disable them or move them to a planned Expand phase.
- The same categories are routed by more than one diagnostic setting (double ingestion) — remove the duplicate.
- Retention set higher than needed — adjust per-table retention to the compliance requirement (Implementation Step 5).

## D. Analytics rules not firing

| Symptom | Cause | Remediation |
|---|---|---|
| Rule enabled but no incidents | The source table has no data, or the rule query window has no matching events | Confirm data is arriving (Test 3/4); generate a deliberate test event; check the rule's query period |
| Rule errored | Query references a table not present in this tenant | Edit the rule to the tables you ingest, or install the connector that provides them |

## E. Permission errors

- Cannot edit the Entra ID diagnostic setting → the account lacks the Entra role (Requirement 2.2).
- Cannot manage Sentinel/analytics → assign `Microsoft Sentinel Contributor` on the workspace (Implementation Step 7); use `SENTLOG-Set-WorkspaceScopeTargeting.ps1`.

## F. Diagnostics quick reference (KQL in Microsoft Sentinel → Logs)

```kql
SigninLogs | where TimeGenerated > ago(1h) | take 10
AuditLogs  | where TimeGenerated > ago(24h) | summarize count() by Category
Usage | where TimeGenerated > ago(24h) | summarize GB=sum(Quantity)/1000 by DataType | order by GB desc
```

## G. When to escalate

If the diagnostic setting and connector are confirmed correct, RBAC is sufficient, and no data arrives after 30+ minutes and a re-validation, capture the output of `SENTLOG-Validation.ps1` and `SENTLOG-Report.ps1` and open a Microsoft support case for the workspace/connector.
