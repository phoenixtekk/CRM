# Troubleshooting — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion

Common failures, each as **symptom → cause → fix**. Start with `SENTDEP-Discovery.ps1` (state) and
`SENTDEP-Report.ps1` (volume/health) — most issues here are visible in one of the two.

---

## A connector shows "Connected" but no data arrives

- **Symptom:** The connector page reads connected, but `TableName | take 10` returns nothing after 30+
  minutes.
- **Cause:** Source-side telemetry was never switched on, or the diagnostic setting routes categories to
  a **different** workspace. "Connected" reflects the Sentinel side, not that the source is emitting.
- **Fix:** Confirm the source-side switch (**R5**): for Entra ID, that `Diag-EntraID-SignInAudit-Pilot`
  exists and points at `Security Telemetry - Tenant - Workspace` with the right categories; for Azure
  Activity, that `DCR-AzureActivity-Subscription-Pilot` targets this workspace. Allow up to ~30 minutes
  for first data. Check for a competing diagnostic setting sending the same categories elsewhere.

## Ingestion volume (and cost) explodes after enabling syslog/CEF

- **Symptom:** GB/day jumps sharply right after the AMA path goes live; `Syslog`/`CommonSecurityLog`
  dominate `Usage`.
- **Cause:** The DCR was created **without** a facility/severity filter (all facilities at
  `Debug`/`Info`), so the full firehose is being ingested and billed.
- **Fix:** Edit `DCR-Syslog-Linux-Pilot` to select **only** the needed facilities at **`LOG_WARNING`+**;
  constrain `DCR-CEF-Appliances-Pilot` to the required streams. Re-check with
  `Syslog | summarize count() by SeverityLevel`. This filter is the single biggest cost control — treat
  a missing filter as a Sev-2.

## Syslog/CEF: nothing arrives at all

- **Symptom:** `Syslog`/`CommonSecurityLog` stay empty after configuring the forwarder.
- **Cause:** The AMA is not installed on `Log Forwarder - Perimeter - Pilot`, the source cannot reach it
  on 514, the local syslog daemon is not handing messages to AMA, or (CEF) the portal installer command
  was not run for the correct distribution.
- **Fix:** Confirm the VM shows the **AzureMonitorLinuxAgent** extension; confirm the appliance can
  reach the forwarder on UDP/TCP 514 (NSG/firewall); re-run the **exact** CEF installer command from the
  connector page for your distro; check the daemon (`rsyslog`/`syslog-ng`) is running and forwarding.

## Entra ID sign-in / audit logs missing despite a diagnostic setting

- **Symptom:** `SigninLogs` or `AuditLogs` empty though `Diag-EntraID-SignInAudit-Pilot` exists.
- **Cause:** The needed **categories were not selected** (e.g. `SignInLogs` unchecked), the setting
  targets the wrong workspace, or the operator lacked rights to save it so it silently reverted.
- **Fix:** `entra.microsoft.com` → **Diagnostic settings** → open `Diag-EntraID-SignInAudit-Pilot`,
  confirm `SignInLogs` + `AuditLogs` are checked and the destination is the correct workspace, saved by
  an account with the required Entra role (**R5**).

## Data lands in the workspace but not visible to analysts

- **Symptom:** An analyst cannot see logs/incidents others can.
- **Cause:** The analyst is not in `SG-Sentinel-Reader-Tenant`/`Responder`, or the role was assigned at
  the wrong scope, or **table-level / resource-context RBAC** is restricting the table.
- **Fix:** Add the analyst to the correct group; confirm the role is assigned at
  `RG-Security-Sentinel`/workspace scope (Gate 3); check for table-level RBAC that narrows access.

## Retention / tier change did not take effect

- **Symptom:** A table still shows the old retention or is still on Analytics after you meant to move it.
- **Cause:** The plan was previewed with `-WhatIf` but never committed, the table is not eligible for
  the target tier, or the change is still propagating.
- **Fix:** Re-run `SENTDEP-Set-Retention.ps1 -Commit`; confirm the table supports Basic/Auxiliary
  (*eligibility varies — verify*); allow propagation, then confirm in **Tables**.

## PowerShell: "resource not found" / authentication or context errors

- **Symptom:** A script errors on connect, on the workspace, or with an access-denied.
- **Cause:** Wrong Azure subscription context, missing Az/Graph modules, insufficient role, or (Gov
  cloud) the wrong environment endpoint.
- **Fix:** `Connect-AzAccount` then `Set-AzContext -Subscription <id>`; `Install-Module Az,
  Microsoft.Graph`; confirm at least Sentinel Reader on the workspace; for Government cloud pass
  `-Environment AzureUSGovernment` (Az) / the matching Graph environment (**R8**) — *verify endpoints
  for your cloud*.

## A previously healthy source silently stopped (ingestion drift)

- **Symptom:** A table has no recent rows; a detection depending on it is now blind, with no error.
- **Cause:** A diagnostic setting/DCR was deleted or changed, the forwarder VM is down, source-side
  logging was disabled, or a credential/permission lapsed.
- **Fix:** `SENTDEP-Report.ps1` flags any source with zero rows in the last N hours;
  `SentinelHealth | summarize by SentinelResourceName, Status` shows connector health. Restore the
  setting/DCR or the forwarder; enable health monitoring (Gate 8) so drift is caught proactively next
  time.

## Duplicate data / double billing for a source

- **Symptom:** A source's volume looks doubled; the same events appear twice.
- **Cause:** Two diagnostic settings/DCRs route the **same** categories to the workspace (e.g. a legacy
  connector plus the new AMA path), so everything is ingested (and billed) twice.
- **Fix:** Inventory settings/DCRs per source (`SENTDEP-Discovery.ps1`); remove the redundant one so
  only one path per source per category remains (global requirement **G6**).
