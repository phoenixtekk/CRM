<#
.SYNOPSIS
    DGSTEWARD-Check-Cadence.ps1 — read-only review-cadence health: flags controls due or overdue for re-certification (no changes).
.DESCRIPTION
    PURPOSE
        Runs the review-cadence check that keeps the framework from decaying: reads each in-scope control's
        Reviewed= (last-reviewed) and ReviewBy= dates from its ownership tag, computes days-until-due
        against the agreed interval, and flags items that are DUE-SOON or OVERDUE for the steward to
        re-certify. Read-only — makes no changes. Writes the export "Review Cadence - Health".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGSTEWARD-Check-Cadence.ps1 -CadenceDays 90 -WarnWithinDays 14
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-IPPSSession).
    EXPECTED RESULTS
        A due/overdue table. PASS = zero overdue items (or every overdue item is a named, owned action).
        An item just re-certified drops off the overdue list; an item past ReviewBy appears on it.
.NOTES
    Purview — Data-Owner & Steward Framework. Read-only. No secrets in code. If a control has no ReviewBy=
    date, ReviewBy is derived as Reviewed + CadenceDays; if it has neither, it is reported as NEVER-REVIEWED.
#>
[CmdletBinding()]
param(
    [int]$CadenceDays = 90,
    [int]$WarnWithinDays = 14,
    [string]$CsvPath,
    [string]$ReportName = 'Review Cadence - Health'
)

Write-Host ("=== {0} (read-only; cadence {1} days) ===" -f $ReportName, $CadenceDays) -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

function Get-Tag {
    param([string]$Text,[string]$Key)
    if ($Text -match ($Key + '\s*=\s*([^;]+)')) { return $Matches[1].Trim() }
    return $null
}
function ConvertTo-DateOrNull {
    param([string]$s)
    if (-not $s) { return $null }
    $d = [datetime]::MinValue
    if ([datetime]::TryParse($s, [ref]$d)) { return $d }
    return $null
}

$controls = @()
$controls += (Get-Label -ErrorAction SilentlyContinue                     | ForEach-Object { [pscustomobject]@{ Type='SensitivityLabel'; Name=$_.DisplayName; Comment=$_.Comment } })
$controls += (Get-DlpCompliancePolicy -ErrorAction SilentlyContinue       | ForEach-Object { [pscustomobject]@{ Type='DlpPolicy';        Name=$_.Name;        Comment=$_.Comment } })
$controls += (Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | ForEach-Object { [pscustomobject]@{ Type='RetentionPolicy'; Name=$_.Name;        Comment=$_.Comment } })

$today = (Get-Date).Date
$rows = New-Object System.Collections.Generic.List[object]

foreach ($c in $controls) {
    $owner    = Get-Tag -Text $c.Comment -Key 'Owner'
    $steward  = Get-Tag -Text $c.Comment -Key 'Steward'
    $reviewed = ConvertTo-DateOrNull (Get-Tag -Text $c.Comment -Key 'Reviewed')
    $reviewBy = ConvertTo-DateOrNull (Get-Tag -Text $c.Comment -Key 'ReviewBy')

    if (-not $reviewBy -and $reviewed) { $reviewBy = $reviewed.AddDays($CadenceDays) }

    if (-not $reviewed -and -not $reviewBy) {
        $status = 'NEVER-REVIEWED'; $daysToDue = $null
    } else {
        $daysToDue = [int]([math]::Floor(($reviewBy.Date - $today).TotalDays))
        if     ($daysToDue -lt 0)               { $status = 'OVERDUE' }
        elseif ($daysToDue -le $WarnWithinDays) { $status = 'DUE-SOON' }
        else                                    { $status = 'OK' }
    }

    $rows.Add([pscustomobject]@{ ControlType=$c.Type; Name=$c.Name; Owner=$owner; Steward=$steward;
        LastReviewed=$(if ($reviewed) {$reviewed.ToString('yyyy-MM-dd')} else {''});
        ReviewBy=$(if ($reviewBy) {$reviewBy.ToString('yyyy-MM-dd')} else {''});
        DaysToDue=$daysToDue; Status=$status })
}

$rows | Sort-Object @{e={switch($_.Status){'OVERDUE'{0}'NEVER-REVIEWED'{1}'DUE-SOON'{2}default{3}}}}, DaysToDue |
    Format-Table ControlType, Name, Steward, LastReviewed, ReviewBy, DaysToDue, Status -AutoSize

$overdue = @($rows | Where-Object { $_.Status -eq 'OVERDUE' }).Count
$never   = @($rows | Where-Object { $_.Status -eq 'NEVER-REVIEWED' }).Count
$soon    = @($rows | Where-Object { $_.Status -eq 'DUE-SOON' }).Count
Write-Host '--- Cadence health ---' -ForegroundColor Cyan
Write-Host ("Overdue: {0} | Never-reviewed: {1} | Due-soon: {2} | Total: {3}" -f $overdue, $never, $soon, $rows.Count) -ForegroundColor $(if ($overdue -eq 0 -and $never -eq 0) {'Green'} else {'Yellow'})
if ($overdue -eq 0 -and $never -eq 0) {
    Write-Host 'PASS — no overdue or never-reviewed controls.' -ForegroundColor Green
} else {
    Write-Host 'ACTION — the steward should re-certify the OVERDUE / NEVER-REVIEWED controls and update their Reviewed=/ReviewBy= tag (DGSTEWARD-Set-Stewardship.ps1 -Commit).' -ForegroundColor Yellow
}

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
Write-Host 'Cadence check complete (read-only).' -ForegroundColor Green
