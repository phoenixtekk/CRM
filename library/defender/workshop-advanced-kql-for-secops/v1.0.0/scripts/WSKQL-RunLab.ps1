<#
.SYNOPSIS
    WSKQL-RunLab.ps1 — run a chosen lab query from WSKQL-Labs.kql read-only (Defender advanced hunting).
.DESCRIPTION
    PURPOSE
        Lets a learner execute one lab's query from PowerShell as well as the portal, so the whole
        cohort can run the same query and compare results. It carries a small, self-contained copy of
        each lab's Defender-XDR query so it runs without parsing the .kql file. Read-only — it only
        queries telemetry.
    HOW TO RUN
        pwsh -File .\WSKQL-RunLab.ps1 -Lab 1
        pwsh -File .\WSKQL-RunLab.ps1 -Lab 6 -LookbackDays 2 -OutputCsv .\lab6.csv

        Prereqs: Microsoft.Graph; sign in with an account holding ThreatHunting.Read.All. Government
        cloud: pass -Environment. Verify table/column names against your tenant schema — they evolve.
    EXPECTED RESULTS
        The matching rows written to the console and, optionally, to CSV via -OutputCsv. Lab 5b
        (Sentinel) is intentionally NOT run here — run it in Sentinel -> Logs (different schema).
.NOTES
    White-label. Read-only. KQL via Graph runHuntingQuery. No credentials in code. The authoritative,
    fuller queries live in WSKQL-Labs.kql; these are compact runnable equivalents for the helper.
#>

[CmdletBinding()]
param(
    [ValidateSet('1','2','3','4','5','6','8')] [string] $Lab = '1',
    [int] $LookbackDays = 1,
    [string] $OutputCsv,
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
$look = "ago({0}d)" -f $LookbackDays

# --- Compact runnable copies of the lab queries (see WSKQL-Labs.kql for the full, commented pack) ----
$LabQueries = @{
    '1' = "DeviceProcessEvents | where Timestamp > $look | project Timestamp, DeviceName, AccountName, FileName, ProcessCommandLine | sort by Timestamp desc | take 20"
    '2' = "DeviceProcessEvents | where Timestamp > $look | where FileName =~ 'powershell.exe' | where ProcessCommandLine has '-enc' or ProcessCommandLine has '-encodedcommand' | project Timestamp, DeviceName, AccountName, ProcessCommandLine | sort by Timestamp desc"
    '3' = "DeviceNetworkEvents | where Timestamp > $look | summarize DistinctRemoteIPs = dcount(RemoteIP) by DeviceName | sort by DistinctRemoteIPs desc | take 25"
    '4' = "DeviceProcessEvents | where Timestamp > $look | where FileName in~ ('powershell.exe','cmd.exe','wscript.exe','mshta.exe','rundll32.exe') | project ProcTime = Timestamp, DeviceId, DeviceName, AccountName, FileName, ProcessCommandLine | join kind=inner (DeviceNetworkEvents | where Timestamp > $look | project NetTime = Timestamp, DeviceId, RemoteIP, RemoteUrl) on DeviceId | where NetTime between (ProcTime .. (ProcTime + 5m)) | project ProcTime, NetTime, DeviceName, AccountName, FileName, RemoteIP, RemoteUrl | sort by ProcTime desc"
    '5' = "IdentityLogonEvents | where Timestamp > $look | summarize Failed = countif(ActionType == 'LogonFailed'), Succeeded = countif(ActionType == 'LogonSuccess') by AccountUpn = tolower(AccountUpn), bin(Timestamp, 1h) | where Failed >= 10 and Succeeded >= 1 | sort by Failed desc"
    '6' = "let scriptHosts = dynamic(['powershell.exe','wscript.exe','cscript.exe','mshta.exe','rundll32.exe']); DeviceProcessEvents | where Timestamp > $look | where FileName in~ (scriptHosts) | join kind=inner (DeviceNetworkEvents | where Timestamp > $look | summarize Connections = count() by DeviceId) on DeviceId | summarize Runs = count(), Cmds = make_set(ProcessCommandLine, 3) by DeviceName, AccountName, FileName, InitiatingProcessFileName, Connections | where Connections > 0 | sort by Runs desc"
    '8' = "DeviceProcessEvents | where Timestamp > ago(14d) | where FileName in~ ('powershell.exe','wscript.exe','cscript.exe','mshta.exe','rundll32.exe') | summarize Executions = count() by bin(Timestamp, 1d), DeviceName | sort by Timestamp asc"
}

if ($Lab -eq '5') { Write-Host 'Note: Lab 5a (Defender) runs here; Lab 5b (Sentinel/SigninLogs) must be run in Sentinel -> Logs — different schema.' -ForegroundColor DarkGray }

try {
    Connect-MgGraph -Scopes 'ThreatHunting.Read.All' -Environment $Environment -NoWelcome -ErrorAction Stop
    Write-Host ("Connected. Running Lab {0} (lookback {1}d). Read-only." -f $Lab, $LookbackDays) -ForegroundColor Green
}
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

try {
    $body = @{ Query = $LabQueries[$Lab] } | ConvertTo-Json -Depth 4
    $resp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
    $rows = @($resp.results)
    Write-Host ("Rows returned: {0}" -f $rows.Count) -ForegroundColor Cyan
    if ($rows.Count -gt 0) {
        $rows | Format-Table -AutoSize
        if ($OutputCsv) { $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8; Write-Host ("Wrote {0}" -f $OutputCsv) -ForegroundColor Green }
    }
    else { Write-Host 'No matches — widen -LookbackDays, relax the filter, or confirm table freshness (WSKQL-Discovery.ps1).' -ForegroundColor Yellow }
}
catch { Write-Error ("Lab query failed: {0}. Verify table/column names for your tenant/cloud (Advanced hunting -> schema)." -f $_.Exception.Message) }
