# 6. Troubleshooting Guide — SCCM Task Sequence Troubleshooting & Status Message Analysis

This is the formal troubleshooting section for the **runbook and its tooling** — what to do when the
diagnostic process itself misbehaves (queries return nothing, WMI is denied, the log is in a place
you didn't expect, the module won't load). For diagnosing the *task-sequence failure*, follow the
Implementation runbook (§3).

## A. Status message query returns nothing
| Symptom | Cause | Remediation |
|---|---|---|
| Query runs but no rows | Wrong device name / time window, or messages haven't summarized yet | Widen the time range; use the exact NetBIOS name; wait for status summarization (or refresh the summarizer) |
| No `11124`/`11170` at all | The run never reported (client couldn't reach the MP), or wrong Message IDs | Confirm the client reached the MP; verify the query filters IDs `11123`,`11124`,`11127`,`11170`,`11171` |
| RBAC hides the messages | Operator's role isn't scoped to the collection | Scope the RBAC role (Req 2.2) to the target collection |

## B. WMI / SMS_StatusMessage access errors
- `Access denied` querying `root\SMS\site_<code>` → the account lacks provider access or DCOM/WMI is
  blocked. Grant the RBAC role (Req 2.2/2.5) and open WMI to the SMS Provider server.
- Empty `SMS_StatusMessage` results → confirm you're querying the **SMS Provider** server and the
  correct three-character **site code**; check the `MessageID` filter.

## C. Can't find or open `smsts.log`
| Symptom | Cause | Remediation |
|---|---|---|
| Log not at `c:\windows\ccm\logs` | Failure happened in WinPE or before client install | Use the phase path: `x:\windows\temp\smstslog` (WinPE) or `c:\_SMSTaskSequence\Logs\Smstslog` |
| WinPE reboots before you can read it | No command support on the boot image | Enable **Enable command support (F8)** on the boot image; capture the log before the reboot, or add an SMSTSLogPath step |
| Log is unreadable / truncated | Opened in Notepad; or rotated | Use CMTrace/OneTrace; check for `smsts-*.log` rollover files in the same folder |

## D. ConfigurationManager PowerShell module won't import / cmdlets missing
- `Import-Module` fails → import from the console path:
  `Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"`, then `cd XYZ:` (your site
  drive) before running `Get-CM*` cmdlets.
- `Get-CMTaskSequenceDeployment` returns nothing → confirm you're on the site drive and the RBAC scope
  includes the deployments; check the exact task-sequence/deployment name.

## E. Exit code is `0x80004005` (unspecified) or blank
- `0x80004005` is generic — the real error is the **inner** failure in `smsts.log`. Read up from the
  last error line for the actual command/return code; don't act on `0x80004005` alone.
- Blank/missing exit code → the step may have failed before returning (timeout, engine crash);
  correlate with the smsts.log timestamp of the `11170` message.

## F. Re-run doesn't pick up the fix
- Cached policy / last-run state → force a machine policy retrieval, or clear the prior run state and
  re-deploy. `SCCMTS-Remediation.ps1` (default `-WhatIf`) shows the retry and ccmcache-clear actions;
  re-run with `-WhatIf:$false` to execute.
- Content still stale on the client → clear ccmcache so the client re-downloads corrected content.

## G. Diagnostics quick reference
```powershell
# On the client — find the active/most recent smsts.log
Get-ChildItem 'C:\Windows\CCM\Logs\smsts*.log','C:\_SMSTaskSequence\Logs\Smstslog\smsts*.log' -EA SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object FullName,LastWriteTime

# From an admin workstation — task-sequence execution failure messages for a device
Get-CimInstance -Namespace 'root\SMS\site_<code>' -ComputerName '<SMSProvider>' `
    -ClassName SMS_StatusMessage -Filter 'MessageID=11124' -EA SilentlyContinue |
    Select-Object -First 20 MachineName,Time,MessageID,SiteCode
```
Open logs with CMTrace (`cmtrace.exe smsts.log`). The last `0x...` line is the failure; read upward.

## H. When to escalate
If the status message query returns the failure, the exit code is mapped, the phase-correct
`smsts.log` is read, the class fix is applied, and the re-run still fails with the same code — collect
`smsts.log` (all rollover files) plus the client's `CAS.log`/`ContentTransferManager.log` (content
failures) and open a Microsoft support case with the step name and exit code.
