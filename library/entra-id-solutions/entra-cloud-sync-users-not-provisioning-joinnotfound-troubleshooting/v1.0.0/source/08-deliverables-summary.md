# 8. Deliverables Summary — Troubleshooting Microsoft Entra Connect Cloud Sync (JoinNotFound)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | The problem, what is in the box, and the outcome |
| 1. Solution Overview | Cloud sync vs. Connect Sync, what JoinNotFound means, the pipeline, the conditions, the five tools |
| 2. Requirements Guide | Every read-access prerequisite with Verify / Implement-if-missing |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Diagnostic Workflow | The ordered Collect → Analyze → Remediate → Verify process, symptom → tool map, and gates |
| 5. Testing Guide | Validation procedures with pass/fail gates (decisive test: provision on demand = Create) |
| 6. Troubleshooting Guide | The comprehensive symptom → cause → fix matrix — the heart of the product |
| 7. Best Practices | Field-proven triage habits and clean escalation |

## PowerShell diagnostic tools (all read-only)
| Script | What it does |
|---|---|
| `CLDSYNCDX-Collect-Diagnostics.ps1` | On the agent host: agent services, execution policy, proxy, Trace folder, and (if present) `Export-AADCloudSyncToolsLogs`, zipped to a timestamped folder |
| `CLDSYNCDX-Check-Agent.ps1` | On the agent host: PASS/FAIL agent-health checks (services Running, execution policy, outbound 443, proxy/config) with a remedy per FAIL |
| `CLDSYNCDX-Get-ProvisioningLog.ps1` | Microsoft Graph: the provisioning-log entries for an `ObjectGuid`/`UPN` — action, status, and **skipReason** (e.g. JoinNotFound) with step detail |
| `CLDSYNCDX-Check-Provisioning.ps1` | Microsoft Graph: the sync job Active/Enabled/Quarantined, the sync-service SP presence, `onPremisesSyncEnabled`; flags `AzureDirectoryServiceAuthorizationFailed` + deletion-threshold |
| `CLDSYNCDX-Test-Object.ps1` | Active Directory: `IsCriticalSystemObject`, in-scope-OU test, UPN routability, and a same-UPN/proxyAddress duplicate advisory for one user |

## What the buyer receives
- This diagnostics toolkit as a Word document and PDF.
- All five PowerShell tools in a single ZIP.
- A repeatable diagnostic process: Collect → Analyze → Remediate → Verify, with pass/fail gates.

## Outcome
The reason cloud sync is skipping users — JoinNotFound, an already-existing target, an out-of-scope OU,
a critical object, a quarantined job, a missing service principal, a deletion threshold, or an unhealthy
agent — isolated fast with read-only tools, so provision on demand creates the user and the provisioning
log shows **action = Create**.
