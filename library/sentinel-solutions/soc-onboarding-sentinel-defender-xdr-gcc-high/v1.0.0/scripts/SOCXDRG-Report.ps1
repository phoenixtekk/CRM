<#
.SYNOPSIS
    SOCXDRG-Report.ps1 — duplicate-rule status and the open-incident shift hand-off list.
.DESCRIPTION
    PURPOSE
        Two reports the SOC needs every cycle: (1) which Microsoft incident-creation rules are still
        ENABLED (duplicate-incident risk that should be disabled), and (2) the open-incident hand-off
        view — incidents not yet closed, with owner, severity, age, and whether they breach the SLA.
        Read-only — makes no changes.
    HOW TO RUN
        Connect-AzAccount -Environment AzureUSGovernment first (US Gov / GCC High — verify endpoints for your cloud), then:
        powershell -ExecutionPolicy Bypass -File .\SOCXDRG-Report.ps1 -ResourceGroup <rg> -WorkspaceName "Security Telemetry - SOC - Workspace" [-SlaHours 4]
        Requires modules: Az.Accounts, Az.OperationalInsights, Az.SecurityInsights.
    EXPECTED RESULTS
        A list of enabled Microsoft incident-creation rules (should be empty after de-duplication) and
        a table of open incidents for shift hand-off, flagging any older than -SlaHours.
.NOTES
    Sentinel Solutions. White-label. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [int]$SlaHours = 4
)

Write-Host "=== SOCXDRG Report — duplicates & hand-off ===" -ForegroundColor Cyan

# 1. Duplicate-rule status
Write-Host "`n--- Microsoft incident-creation rules (should be NONE enabled after de-dup) ---" -ForegroundColor Cyan
try {
    $rules = Get-AzSentinelAlertRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop
    $enabled = $rules | Where-Object { $_.Kind -eq 'MicrosoftSecurityIncidentCreation' -and $_.Enabled }
    if ($enabled) {
        $enabled | ForEach-Object { Write-Host ("  ENABLED — {0}  (disable to de-duplicate, Implementation Step 4)" -f $_.DisplayName) -ForegroundColor Yellow }
    } else {
        Write-Host "  None enabled — de-duplication holds." -ForegroundColor Green
    }
} catch { Write-Host ("  Could not read rules: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# 2. Open-incident hand-off list
Write-Host "`n--- Open incidents (shift hand-off) ---" -ForegroundColor Cyan
try {
    $incidents = Get-AzSentinelIncident -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop |
        Where-Object { $_.Status -ne 'Closed' }
    if (-not $incidents) { Write-Host "  No open incidents." -ForegroundColor Green; return }
    $now = Get-Date
    $incidents | Sort-Object Severity, CreatedTimeUtc | ForEach-Object {
        $ageH = [math]::Round(($now.ToUniversalTime() - [datetime]$_.CreatedTimeUtc).TotalHours, 1)
        $owner = if ($_.OwnerAssignedTo) { $_.OwnerAssignedTo } elseif ($_.OwnerUserPrincipalName) { $_.OwnerUserPrincipalName } else { 'UNOWNED' }
        $breach = if ($ageH -gt $SlaHours -and $_.Status -in @('New')) { '  <-- SLA BREACH (untriaged)' } else { '' }
        $color = if ($breach -or $owner -eq 'UNOWNED') { 'Yellow' } else { 'Gray' }
        Write-Host ("  [{0}] {1}  owner={2}  status={3}  age={4}h{5}" -f $_.Severity, $_.Title, $owner, $_.Status, $ageH, $breach) -ForegroundColor $color
    }
} catch { Write-Host ("  Could not read incidents: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`nUse this list at shift change: add a hand-off comment per open incident and re-assign owner to the next shift." -ForegroundColor Cyan
