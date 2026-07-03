# 6. Troubleshooting Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

Use `SENTLOGG-Discovery.ps1` for readiness, `SENTLOGG-Validation.ps1` for ingestion state, `SENTLOGG-Report.ps1` for coverage/retention, and `SENTLOGG-Remediation.ps1` (default `-WhatIf`) for safe fixes. **All scripts connect to US Gov endpoints** — `-Environment AzureUSGovernment` (Az) / `-Environment USGov` (Graph).

## A. Wrong-cloud / sign-in failures (the #1 GCC High gotcha)

| Symptom | Cause | Remediation |
|---|---|---|
| Portal shows no subscriptions / can't find the tenant | You are on a Commercial `.com` portal | Use `portal.azure.us`, `entra.microsoft.us`, `intune.microsoft.us` — not `.com` |
| `Connect-MgGraph` redirect / AADSTS auth error | Graph module defaulted to the Commercial endpoint | Run `Connect-MgGraph -Environment USGov`; or set `$PSDefaultParameterValues['Connect-MgGraph:Environment']='USGov'` |
| `Connect-AzAccount` cannot see the Gov subscription | Az defaulted to `AzureCloud` | Run `Connect-AzAccount -Environment AzureUSGovernment` |
| Script "works" but returns nothing | Authenticated against the wrong cloud | Re-run the script (it forces the US Gov environment); confirm the account is a GCC High account |

## B. No data arriving in the workspace

| Symptom | Cause | Remediation |
|---|---|---|
| `SigninLogs` empty after setup | Entra ID diagnostic setting missing or pointing at the wrong workspace | In `entra.microsoft.us` confirm `Audit Telemetry - Entra ID - Pilot` targets `Security Telemetry - Tenant - Workspace`; run `SENTLOGG-Remediation.ps1` to add it |
| `IntuneAuditLogs` empty | Intune diagnostic setting missing | In `intune.microsoft.us` → `Reports` → `Diagnostics settings` confirm `Audit Telemetry - Intune - Pilot` routes `AuditLogs` to the workspace |
| Connector shows `Not connected` | Connector page never applied | `portal.azure.us` → `Microsoft Sentinel` → `Data connectors` → `Microsoft Entra ID` → select log types → `Apply Changes` |
| Data delayed | First events can lag; Intune `DeviceComplianceOrg`/`IntuneDevices` up to 48h | Wait ~15-30 minutes (audit/operational) or up to 48h (compliance/devices); re-run `SENTLOGG-Validation.ps1` |

## C. Missing log categories

| Symptom | Cause | Remediation |
|---|---|---|
| Risky/non-interactive sign-ins absent | Category not selected, or Gov Entra SKU does not expose it | Add the category to the diagnostic setting; confirm the Entra ID Government plan exposes it (Requirement 2.1) and that the category is supported for Azure Government in the connector data-type matrix (**verify for GCC High** — see parity notes §3) |
| Intune compliance/device events absent | Only `AuditLogs` routed, or the 48h export window not elapsed | Add `OperationalLogs`/compliance categories to the Intune diagnostic setting; allow up to 48h |

## D. Unexpectedly high ingestion / cost

- High-volume categories (non-interactive, service-principal sign-ins) were enabled before the pilot gate — disable them or move them to a planned Expand phase.
- The same categories are routed by more than one diagnostic setting (double ingestion) — remove the duplicate.
- The Intune export pipeline duplicated data (documented behavior, up to 100% in a 24h window) — make downstream queries duplicate-tolerant; do not double-count.
- Retention set higher than needed — adjust per-table retention to the compliance requirement (Implementation Step 5).

## E. Analytics rules not firing

| Symptom | Cause | Remediation |
|---|---|---|
| Rule enabled but no incidents | The source table has no data, or the rule query window has no matching events | Confirm data is arriving (Test 4/5); generate a deliberate test event; check the rule's query period |
| Rule errored | Query references a table not present in this tenant | Edit the rule to the tables you ingest, or install the connector that provides them from Content hub |
| Expected a Commercial-only feature | `Summary rules` / `SOC optimizations` / `Hunts` are not in Azure Government | Use scheduled/NRT/Fusion rules and classic hunting instead (parity notes §2) |

## F. Content won't deploy the way the Commercial runbook says

- `Repositories` (CI/CD) and the `SIEM migration experience` are **not available in Azure Government**. Install solutions/connectors from **Content hub** and create analytics from **Analytics → Rule templates** directly.

## G. Permission errors

- Cannot edit the Entra ID diagnostic setting → the account lacks the Entra role (Requirement 2.2).
- Cannot route Intune logs → needs **Intune Service Administrator** + **Log Analytics Contributor** on the workspace (Requirement 2.3).
- Cannot manage Sentinel/analytics → assign `Microsoft Sentinel Contributor` on the workspace (Implementation Step 7); use `SENTLOGG-Set-ScopeTargeting.ps1`.

## H. Diagnostics quick reference (KQL in Microsoft Sentinel → Logs, in `portal.azure.us`)

```kql
SigninLogs      | where TimeGenerated > ago(1h)  | take 10
AuditLogs       | where TimeGenerated > ago(24h) | summarize count() by Category
IntuneAuditLogs | where TimeGenerated > ago(24h) | take 10
Usage           | where TimeGenerated > ago(24h) | summarize GB=sum(Quantity)/1000 by DataType | order by GB desc
```

## I. When to escalate

If the diagnostic settings and connector are confirmed correct in the `.us` portals, RBAC is sufficient, you have verified you are in the sovereign cloud (Section A), and no data arrives after 30+ minutes and a re-validation, capture the output of `SENTLOGG-Validation.ps1` and `SENTLOGG-Report.ps1` and open a Microsoft support case for the Azure Government workspace/connector.
