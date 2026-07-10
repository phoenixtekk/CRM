# 6. Troubleshooting Guide — SOC Onboarding: Microsoft Sentinel + Defender XDR Unified Incidents

Use `SOCXDRG-Discovery.ps1` for readiness, `SOCXDRG-Validate.ps1` for connector/sync state, `SOCXDRG-Report.ps1` for duplicate-rule and hand-off status, `SOCXDRG-IncidentQueue.ps1` for queue health, and `SOCXDRG-Set-SocRbacScope.ps1` for RBAC.

## A. Duplicate incidents in the queue

| Symptom | Cause | Remediation |
|---|---|---|
| Every threat appears as two incidents | A Microsoft incident-creation rule is still active alongside the Defender XDR connector | `Analytics` → `Active rules` → filter `Microsoft incident creation rule` → `Disable` the rules for the synced products (Implementation Step 4); run `SOCXDRG-Report.ps1` to confirm none remain |
| Duplicates returned after a while | A disabled rule was re-enabled, or a new product was added without disabling its rule | Re-run `SOCXDRG-Report.ps1` each cycle; disable the offending rule |

## B. Defender incidents not appearing in Sentinel

| Symptom | Cause | Remediation |
|---|---|---|
| No Defender XDR incidents in Sentinel | Connector not connected, or incident sync not enabled | `Data connectors` → `Microsoft Defender XDR` → `Connect incidents & alerts`; run `SOCXDRG-Validate.ps1` |
| Only alerts, no incidents | Alerts streamed but incident sync off | On the connector page enable incidents & alerts sync (not only the alert data types) |
| Sync delayed | First sync can lag | Wait, then re-run `SOCXDRG-Validate.ps1`; confirm the connector `data received` timestamp is recent |

## C. Status not syncing between portals

| Symptom | Cause | Remediation |
|---|---|---|
| Closing in Sentinel does not close in Defender | Bi-directional sync not established, or the incident predates sync | Confirm the connector's incident sync is on; test on a *new* incident created after sync was enabled (Test 5) |
| Owner/classification differs between portals | Change made during a sync delay | Allow sync to settle; avoid editing the same incident simultaneously in both portals |

## D. Severity / ownership not applied

| Symptom | Cause | Remediation |
|---|---|---|
| New incidents arrive unowned / untagged | Automation rule missing, disabled, or its conditions don't match | Confirm `Incident Alignment - SOC - Pilot` exists, is enabled, order `1`, and its conditions match the products in scope (Implementation Step 5) |
| Wrong severity applied | `Change severity` action too broad | Narrow the automation rule conditions, or remove the severity override and keep Defender's severity |

## E. Permission errors

- Cannot configure the connector / enable sync → the account lacks the tenant-scoped Sentinel permission or the Defender role (Requirement 2.3).
- Analysts cannot triage incidents → assign `Microsoft Sentinel Responder` on the workspace (Implementation Step 6); use `SOCXDRG-Set-SocRbacScope.ps1`.

## E2. GCC High: wrong cloud / endpoint (most common Government-cloud failure)

- Scripts or portal actions fail with "not found" / auth errors → you connected to the **commercial**
  cloud instead of US Gov. Use `Connect-AzAccount -Environment AzureUSGovernment` (the delivered
  `SOCXDRG-*.ps1` scripts document this); for Graph use `Connect-MgGraph -Environment USGov` (host
  `graph.microsoft.us`; **DoD/IL5 `dod-graph.microsoft.us`**). Portals are `portal.azure.us` /
  `security.microsoft.us` / `entra.microsoft.us`, token host `login.microsoftonline.us`.
- The Defender XDR connector, incident sync, or the unified experience behaves differently than the
  commercial docs describe → GCC High/DoD can **lag or differ**; **verify against current Microsoft
  Government documentation** for your cloud before opening a case (see `gcc-high-parity-notes.md`).

## F. Diagnostics quick reference (KQL in Microsoft Sentinel → Logs)

```kql
SecurityIncident | where TimeGenerated > ago(24h) | summarize count() by Severity, Status
SecurityAlert    | where TimeGenerated > ago(24h) | summarize count() by ProductName
SecurityIncident | where TimeGenerated > ago(24h) | where isempty(Owner) | project IncidentName, Severity, CreatedTime
```

## G. When to escalate

If the connector shows `Connected`, incident sync is on, the Microsoft incident-creation rules are disabled, and incidents still duplicate or fail to sync after a full sync interval and a re-validation, capture the output of `SOCXDRG-Validate.ps1` and `SOCXDRG-Report.ps1` and open a Microsoft support case for the Defender XDR connector / unified experience on the workspace.
