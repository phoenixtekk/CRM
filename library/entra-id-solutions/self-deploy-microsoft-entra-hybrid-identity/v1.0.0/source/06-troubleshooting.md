# 6. Troubleshooting — Self-Deploy: Microsoft Entra Hybrid Identity

Common failures while working the labs, as **symptom → cause → fix**. These are lab / inspection issues;
production hybrid troubleshooting lives in the **HYBID** implementation solution and the dedicated
source-anchor and Cloud Sync troubleshooting solutions.

## Scripts

### `Connect-MgGraph` fails or prompts endlessly
- **Symptom:** the discovery/validation/report/health-check scripts cannot connect to Graph.
- **Cause:** the `Microsoft.Graph` module is missing/old, or consent to the read scopes was declined.
- **Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and **accept** the requested read
  scopes (e.g. `Directory.Read.All`, `Domain.Read.All`, `Organization.Read.All`, `AuditLog.Read.All`).
  Confirm with `Get-MgContext`.

### "Insufficient privileges" on a read script
- **Symptom:** cmdlets return authorization errors.
- **Cause:** the operator lacks a directory-read role, or a scope needs admin consent.
- **Fix:** sign in as **Global Reader** (or higher read); have a Global Administrator consent once to
  any scope requiring admin consent.

### `EKHYBID-Discovery.ps1` shows no sync engine / last sync time
- **Symptom:** engine and last-sync fields are blank.
- **Cause:** the tenant has no hybrid sync configured, or `onPremisesSyncEnabled` is false, or the
  operator cannot read organization sync properties.
- **Fix:** this is expected in a cloud-only tenant — complete Labs 1–2 conceptually. If a hybrid setup
  exists, confirm the read role and that Entra → **Hybrid management → Microsoft Entra Connect** shows
  sync status.

### AD-side commands fail (`Get-ADUser`, `Get-ADForest`)
- **Symptom:** the source-anchor / UPN-hygiene inspection commands error.
- **Cause:** the RSAT ActiveDirectory module is not installed, or you are not on a domain-joined host.
- **Fix:** install RSAT AD tools and run from a domain-joined workstation or the Connect host; or skip
  the AD-side inspection and complete those labs conceptually.

## Sync / health-check labs

### Health check reports the last sync time is very old
- **Symptom:** `EKHYBID-HealthCheck.ps1` flags last sync older than the expected window.
- **Cause:** the Connect Sync scheduler is disabled/stopped, the Connect host is offline, or the Cloud
  Sync agent is unhealthy.
- **Fix (inspection):** on the Connect host, read status only — `Get-ADSyncScheduler`,
  `Get-ADSyncConnectorRunStatus`. For an actual restart/repair, follow **HYBID** (do not change
  production sync from the kit).

### Federated domains appear where cloud auth was expected
- **Symptom:** discovery lists a domain as **Federated**.
- **Cause:** the domain still uses AD FS.
- **Fix:** this is a finding, not an error — record the federation→cloud migration action in the runbook
  and execute it (staged rollout) in **HYBID**.

### UPN-hygiene flag: `.local` UPNs present
- **Symptom:** discovery/health check reports non-routable UPNs.
- **Cause:** AD UPN suffixes use a non-routable domain (e.g. `.local`).
- **Fix (plan):** add and verify a public domain in Entra, add the matching UPN suffix in AD, and update
  user UPNs — executed in **HYBID**; the kit only surfaces the finding.

## Hybrid join / Conditional Access labs

### `dsregcmd /status` shows the device is not hybrid joined
- **Symptom:** `AzureAdJoined : NO` on a domain-joined test device.
- **Cause:** hybrid join is not configured/advertised, the device has not completed registration, or the
  SCP is missing.
- **Fix (inspection):** read `DomainJoined`, `AzureAdPrt`, and any error in the output; understand the
  cause. Enabling hybrid join for the fleet is a **HYBID** task.

### The report-only hybrid-device CA policy shows no impact
- **Symptom:** the report-only workbook shows nothing for `CA – Hybrid Pilot – Require Compliant/Hybrid
  Device (Report-only)`.
- **Cause:** no pilot user has signed in since creation, or the pilot group scope is wrong.
- **Fix:** sign in as a pilot lab user, wait a few minutes, then re-check **Conditional Access →
  Insights and reporting**. Confirm `Hybrid Identity – Pilot – Lab` is included and break-glass excluded.

### CA blades / device conditions unavailable
- **Symptom:** Conditional Access or the device-grant options are greyed out.
- **Cause:** the tenant lacks **Entra ID P1**.
- **Fix:** assign P1 to lab users or complete Lab 5 as concept-only. *Verify current licensing in your
  tenant.*

## KQL lab

### KQL queries error on table not found or return nothing
- **Symptom:** `SigninLogs` is unknown or results are empty.
- **Cause:** Entra diagnostic settings are not exporting logs to the workspace, the time range predates
  collection, or you are querying the wrong workspace.
- **Fix:** configure Entra → **Diagnostic settings** to send `SignInLogs`/`AuditLogs` to the workspace;
  widen the time range; confirm the correct workspace. Column/table names evolve — *verify the current
  schema in your tenant.*
