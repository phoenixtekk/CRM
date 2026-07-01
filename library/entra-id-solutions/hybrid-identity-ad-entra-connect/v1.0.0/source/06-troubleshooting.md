# 6. Troubleshooting Guide — Hybrid Identity with Active Directory & Microsoft Entra Connect

Use `HYBID-Validation.ps1` / `HYBID-Discovery.ps1` for host and identity state, `HYBID-Report.ps1`
for sync health and coverage, and `HYBID-Remediation.ps1` (`-WhatIf` by default) for safe fixes.
Keep your break-glass accounts ready before any change.

## A. Synchronization not running / stalled
| Symptom | Cause | Remediation |
|---|---|---|
| No new objects appear in Entra | Server in staging mode, or scheduler disabled | Run `Get-ADSyncScheduler`; exit staging mode (wizard); `Set-ADSyncScheduler -SyncCycleEnabled $true`; `Start-ADSyncSyncCycle -PolicyType Delta` |
| Cycle errors immediately | AD replication/DNS fault, or credentials expired | Run `HYBID-Discovery.ps1`; fix `dcdiag`/`repadmin` issues; refresh the connector account |
| Nothing in scope | OU/domain filter excludes the objects | Review with `HYBID-Set-SyncScopeHelper.ps1`; widen the sync scope in the wizard |

## B. Duplicate or merged accounts / sync errors
| Symptom | Cause | Remediation |
|---|---|---|
| Duplicate-attribute error | Two objects share a UPN or proxyAddress | Run `HYBID-Report.ps1` to list them; resolve with `HYBID-Remediation.ps1` (review the `-WhatIf` output first) |
| Cloud account separate from on-prem | Soft-match failed (UPN/proxyAddress mismatch) | Align the on-prem UPN/proxyAddress to the cloud value, or hard-match by `ImmutableId`; re-sync |
| `.onmicrosoft.com` UPN in cloud | Non-routable `.local` UPN on-premises | Add the verified public domain and matching UPN suffix; update user UPNs; re-sync |

## C. Sign-in failures
- Password hash sync: confirm PHS is enabled in `Hybrid management`; force a full sync if a single user is stale.
- Pass-through authentication: confirm at least two healthy authentication agents; an offline agent breaks PTA sign-in (PHS backup, if enabled, keeps users working).
- Federation: check the AD FS service and token-signing certificate validity; an expired certificate blocks all federated sign-in.
- Seamless SSO: confirm the `AZUREADSSO` computer object exists and the browser policies are applied to the device.

## D. Hybrid Entra join not completing
| Symptom | Cause | Remediation |
|---|---|---|
| `dsregcmd /status` shows `AzureAdJoined : NO` | Service connection point missing, or device not synced | Re-run the wizard `Configure device options`; confirm the `Hybrid Entra Join - Domain - Configure` SCP; let a policy cycle + sign-in complete |
| Join works for users but not devices | Computer objects out of sync scope | Add the device OU to the sync scope (`HYBID-Set-SyncScopeHelper.ps1`); re-sync |

## E. Accidental-deletion safeguard tripped
- A large scope change can trip the export deletion threshold (a safety feature). Confirm the deletes are intended, then `Enable-ADSyncExportDeletionThreshold` / re-run with the threshold raised only after verifying with `HYBID-Report.ps1`.

## F. Diagnostics quick reference
```powershell
Get-ADSyncScheduler                                  # sync schedule + staging mode
Start-ADSyncSyncCycle -PolicyType Delta              # trigger a delta sync
Get-ADSyncConnectorRunStatus                         # is a run in progress
dsregcmd /status                                     # device hybrid-join state
dcdiag /q ; repadmin /replsummary                    # AD health
```
Connector and run-profile detail is in the Synchronization Service Manager (`miisclient.exe`) on the host.

## G. When to escalate
If sync runs clean, AD is healthy, the auth method is enabled with healthy agents/certificates, and a
user still cannot sign in or hybrid-join after a full sync and a policy cycle, collect the
`HYBID-Report.ps1` output and the connector run details and open a Microsoft support case.
