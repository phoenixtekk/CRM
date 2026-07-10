<#
.SYNOPSIS
    DEFMDOP2-Hunt.ps1 — run the email Advanced Hunting KQL library against Defender for Office 365 (read-only).
.DESCRIPTION
    PURPOSE
        Runs a curated library of email-focused Advanced Hunting KQL queries via the Microsoft Graph
        security runHuntingQuery endpoint — post-delivery malicious clicks, recipients of a known-bad
        sender/subject, and attachments matching a known-bad hash — so hunting is repeatable instead
        of ad-hoc portal clicking. Read-only — it only queries.
    HOW TO RUN
        pwsh -File .\DEFMDOP2-Hunt.ps1 -QuerySet PostDeliveryPhish -LookbackDays 7
        pwsh -File .\DEFMDOP2-Hunt.ps1 -QuerySet SenderCampaign -Indicator "badsender@contoso.com"
        pwsh -File .\DEFMDOP2-Hunt.ps1 -QuerySet BadAttachmentHash -Indicator "<sha256>"

        Prereqs: Microsoft.Graph; sign in with an admin holding ThreatHunting.Read.All. Government
        cloud: pass -Environment. Verify table/column names against your tenant schema — they evolve.
    EXPECTED RESULTS
        The matching rows (recipients, click verdicts, attachments) written to the console and,
        optionally, to CSV via -OutputCsv. Feed a saved CSV into DEFMDOP2-Remediate.ps1 -WhatIf to
        PREVIEW a gated response. Read-only.
.NOTES
    White-label. Read-only. KQL via Graph runHuntingQuery. No credentials in code.
#>

[CmdletBinding()]
param(
    [ValidateSet('PostDeliveryPhish','SenderCampaign','BadAttachmentHash')] [string] $QuerySet = 'PostDeliveryPhish',
    [int] $LookbackDays = 7,
    [string] $Indicator,
    [string] $OutputCsv,
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
if ($QuerySet -in @('SenderCampaign','BadAttachmentHash') -and -not $Indicator) {
    Write-Error "QuerySet '$QuerySet' requires -Indicator (sender/subject or file hash)."; return
}
$look = "ago({0}d)" -f $LookbackDays

# --- KQL library (verify table/column names for your tenant/cloud) ----------------------------------
$Queries = @{
    # Users who CLICKED a URL after delivery (the post-delivery risk the prevention layer missed).
    PostDeliveryPhish = @"
let clicks = UrlClickInfo | where Timestamp > $look | where ActionType == 'ClickAllowed' or IsClickedThrough == 1;
clicks
| join kind=inner (EmailUrlInfo | where Timestamp > $look) on NetworkMessageId
| join kind=inner (EmailEvents | where Timestamp > $look and DeliveryAction == 'Delivered') on NetworkMessageId
| project Timestamp, RecipientEmailAddress, SenderFromAddress, Subject, Url, ThreatTypes, DeliveryLocation
| sort by Timestamp desc
"@
    # Everyone who RECEIVED mail from a known-bad sender / subject indicator.
    SenderCampaign = @"
EmailEvents
| where Timestamp > $look
| where SenderFromAddress =~ '$Indicator' or Subject has '$Indicator'
| project Timestamp, NetworkMessageId, RecipientEmailAddress, SenderFromAddress, Subject, DeliveryAction, DeliveryLocation, ThreatTypes
| sort by Timestamp desc
"@
    # Recipients of an attachment matching a known-bad SHA256.
    BadAttachmentHash = @"
EmailAttachmentInfo
| where Timestamp > $look
| where SHA256 =~ '$Indicator'
| join kind=inner (EmailEvents | where Timestamp > $look) on NetworkMessageId
| project Timestamp, NetworkMessageId, RecipientEmailAddress, SenderFromAddress, Subject, FileName, SHA256, DeliveryLocation
| sort by Timestamp desc
"@
}

try {
    Connect-MgGraph -Scopes 'ThreatHunting.Read.All' -Environment $Environment -NoWelcome -ErrorAction Stop
    Write-Host ("Connected. Running query set: {0} (lookback {1}d)." -f $QuerySet, $LookbackDays) -ForegroundColor Green
}
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

try {
    $body = @{ Query = $Queries[$QuerySet] } | ConvertTo-Json -Depth 4
    $resp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
    $rows = @($resp.results)
    Write-Host ("Rows returned: {0}" -f $rows.Count) -ForegroundColor Cyan
    if ($rows.Count -gt 0) {
        $rows | Format-Table -AutoSize
        if ($OutputCsv) { $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8; Write-Host ("Wrote {0}" -f $OutputCsv) -ForegroundColor Green }
        Write-Host 'To PREVIEW a gated response on these rows: DEFMDOP2-Remediate.ps1 -InputCsv <csv> -Action SoftDelete -WhatIf' -ForegroundColor Yellow
    }
    else { Write-Host 'No matches — adjust indicator/lookback, or confirm table freshness (DEFMDOP2-Discovery.ps1).' -ForegroundColor Yellow }
}
catch { Write-Error ("Hunting query failed: {0}. Verify table/column names for your tenant/cloud." -f $_.Exception.Message) }
