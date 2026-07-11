<#
.SYNOPSIS
    WSMDO-RunLab.ps1 — run a chosen email hunting-lab query from WSMDO-Labs.kql read-only.
.DESCRIPTION
    PURPOSE
        Lets a learner execute one email hunting lab's query from PowerShell as well as the portal, so
        the whole cohort can run the same query and compare results. Carries a compact, self-contained
        copy of each hunting lab's query. Read-only — it only queries email telemetry.
    HOW TO RUN
        pwsh -File .\WSMDO-RunLab.ps1 -Lab 5a
        pwsh -File .\WSMDO-RunLab.ps1 -Lab 5b -Indicator "badsender@contoso.com" -LookbackDays 7
        pwsh -File .\WSMDO-RunLab.ps1 -Lab 5c -Indicator "<sha256>" -OutputCsv .\lab5c.csv

        Prereqs: Microsoft.Graph; sign in with an account holding ThreatHunting.Read.All. Government
        cloud: pass -Environment. Verify table/column names against your tenant schema — they evolve.
    EXPECTED RESULTS
        Matching rows (recipients, clicks, attachments) to the console and, optionally, CSV. Labs
        1/2/3/4/6 (console tour, Explorer, policy inspection, simulation, AIR) are PORTAL exercises.
.NOTES
    White-label. Read-only. KQL via Graph runHuntingQuery. No credentials in code. Full commented pack:
    WSMDO-Labs.kql.
#>

[CmdletBinding()]
param(
    [ValidateSet('5a','5b','5c','8')] [string] $Lab = '5a',
    [int] $LookbackDays = 7,
    [string] $Indicator,
    [string] $OutputCsv,
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
if ($Lab -in @('5b','5c') -and -not $Indicator) {
    Write-Error "Lab '$Lab' requires -Indicator (sender/subject for 5b, or a SHA256 for 5c)."; return
}
$look = "ago({0}d)" -f $LookbackDays

$LabQueries = @{
    '5a' = "let look = $look; UrlClickInfo | where Timestamp > look | where ActionType == 'ClickAllowed' or IsClickedThrough == 1 | join kind=inner (EmailUrlInfo | where Timestamp > look) on NetworkMessageId | join kind=inner (EmailEvents | where Timestamp > look and DeliveryAction == 'Delivered') on NetworkMessageId | project Timestamp, RecipientEmailAddress, SenderFromAddress, Subject, Url, ThreatTypes, DeliveryLocation | sort by Timestamp desc"
    '5b' = "EmailEvents | where Timestamp > $look | where SenderFromAddress =~ '$Indicator' or Subject has '$Indicator' | project Timestamp, NetworkMessageId, RecipientEmailAddress, SenderFromAddress, Subject, DeliveryAction, DeliveryLocation, ThreatTypes | sort by Timestamp desc"
    '5c' = "EmailAttachmentInfo | where Timestamp > $look | where SHA256 =~ '$Indicator' | join kind=inner (EmailEvents | where Timestamp > $look) on NetworkMessageId | project Timestamp, NetworkMessageId, RecipientEmailAddress, SenderFromAddress, Subject, FileName, SHA256, DeliveryLocation | sort by Timestamp desc"
    '8'  = "EmailEvents | where Timestamp > $look | where DeliveryAction == 'Delivered' | where ThreatTypes has 'Phish' or ThreatTypes has 'Malware' | summarize Messages = count(), Recipients = dcount(RecipientEmailAddress) by bin(Timestamp, 1d), ThreatTypes | sort by Timestamp desc"
}

Write-Host 'Note: Labs 1/2/3/4/6 (console tour, Threat Explorer, policy inspection, simulation, AIR) are portal exercises — see 03-implementation.md.' -ForegroundColor DarkGray

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
    else { Write-Host 'No matches — adjust indicator/lookback, or confirm table freshness (WSMDO-Discovery.ps1).' -ForegroundColor Yellow }
}
catch { Write-Error ("Lab query failed: {0}. Verify table/column names for your tenant/cloud (Advanced hunting -> schema)." -f $_.Exception.Message) }
