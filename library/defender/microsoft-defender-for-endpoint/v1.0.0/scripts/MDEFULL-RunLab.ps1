<#
.SYNOPSIS
    MDEFULL-RunLab.ps1 — run a chosen endpoint hunting-lab query from MDEFULL-Labs.kql read-only.
.DESCRIPTION
    PURPOSE
        The enablement-workstream lab runner for the comprehensive "Microsoft Defender for Endpoint"
        solution. Lets a learner execute one hunting lab's query from PowerShell as well as the portal,
        so the whole cohort can run the same query and compare results. Carries a compact, self-contained
        copy of each hunting lab's query. Read-only — it only queries endpoint telemetry.
    HOW TO RUN
        pwsh -File .\MDEFULL-RunLab.ps1 -Lab 4
        pwsh -File .\MDEFULL-RunLab.ps1 -Lab 5 -LookbackDays 7 -OutputCsv .\lab5.csv
        Prereqs: Microsoft.Graph; sign in with an account holding ThreatHunting.Read.All. Government
        cloud: pass -Environment. Verify table/column names / ASR ActionType names against your schema.
    EXPECTED RESULTS
        Matching rows to the console and, optionally, CSV. Labs 2/3/6/7 (incident graph, device timeline,
        Live Response, response-action walkthrough) are PORTAL exercises — not run here. The full commented
        pack is MDEFULL-Labs.kql; Lab 8 is the alert-only detection candidate ('MDE Lab Detection - Team - Pilot').
.NOTES
    White-label. Read-only. KQL via Graph runHuntingQuery. No credentials in code.
#>
[CmdletBinding()]
param(
    [ValidateSet('1','4','5','8')] [string] $Lab = '1',
    [int] $LookbackDays = 1,
    [string] $OutputCsv,
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
$look = "ago({0}d)" -f $LookbackDays

$LabQueries = @{
    '1' = "DeviceProcessEvents | where Timestamp > $look | project Timestamp, DeviceName, AccountName, FileName, ProcessCommandLine, InitiatingProcessFileName | sort by Timestamp desc | take 20"
    '4' = "let scriptHosts = dynamic(['powershell.exe','cmd.exe','wscript.exe','cscript.exe','mshta.exe','rundll32.exe']); DeviceProcessEvents | where Timestamp > $look | where FileName in~ (scriptHosts) | project ProcTime = Timestamp, DeviceId, DeviceName, AccountName, FileName, ProcessCommandLine | join kind=inner (DeviceNetworkEvents | where Timestamp > $look | project NetTime = Timestamp, DeviceId, RemoteIP, RemoteUrl) on DeviceId | where NetTime between (ProcTime .. (ProcTime + 5m)) | project ProcTime, NetTime, DeviceName, AccountName, FileName, RemoteIP, RemoteUrl | sort by ProcTime desc"
    '5' = "DeviceEvents | where Timestamp > $look | where ActionType startswith 'Asr' | summarize Events = count(), Devices = dcount(DeviceName), Sample = make_set(FileName, 5) by ActionType | sort by Events desc"
    '8' = "let scriptHosts = dynamic(['powershell.exe','wscript.exe','cscript.exe','mshta.exe','rundll32.exe']); DeviceProcessEvents | where Timestamp > $look | where FileName in~ (scriptHosts) | where InitiatingProcessFileName !in~ ('explorer.exe','services.exe','svchost.exe') | join kind=inner (DeviceNetworkEvents | where Timestamp > $look | summarize Connections = count() by DeviceId) on DeviceId | where Connections > 0 | project Timestamp, DeviceId, DeviceName, AccountName, FileName, InitiatingProcessFileName, ProcessCommandLine, Connections | sort by Timestamp desc"
}

Write-Host 'Note: Labs 2/3/6/7 (incident graph, device timeline, Live Response, response-action walkthrough) are portal exercises — see 03-implementation.md Part C.' -ForegroundColor DarkGray

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
    else { Write-Host 'No matches — widen -LookbackDays, relax the filter, or confirm table freshness (MDEFULL-Discovery.ps1).' -ForegroundColor Yellow }
}
catch { Write-Error ("Lab query failed: {0}. Verify table/column/ASR-ActionType names for your tenant (Advanced hunting -> schema)." -f $_.Exception.Message) }
