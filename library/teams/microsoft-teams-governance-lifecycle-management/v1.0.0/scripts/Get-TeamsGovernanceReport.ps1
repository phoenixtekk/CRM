<#
.SYNOPSIS
  Read-only governance & lifecycle report: creation-control status, naming/classification coverage,
  ownership, stale/duplicate teams, and expiration posture. Exports CSV + HTML. Makes NO changes.
.DESCRIPTION
  Produces a single, schedulable governance posture report by combining the Group.Unified directory
  setting (creation control + naming), the M365 Groups expiration policy, sensitivity-label coverage, and
  owner/stale/duplicate metrics across all teams. Intended to run monthly to trend the estate.
.EXAMPLE
  .\Get-TeamsGovernanceReport.ps1 -StaleDays 180 -OutHtml .\teams-governance-report.html
  (PowerShell 5.1+/7+, Microsoft.Graph + Microsoft.Graph.Beta; connect with Connect-MgGraph)
.NOTES
  Expected results: a console summary plus CSV and HTML files showing each governance control's status
  and the counts of ownerless/stale/duplicate/unclassified teams. Read-only — safe to schedule.
#>
[CmdletBinding()]
param(
    [int]$StaleDays = 180,
    [int]$MinOwners = 2,
    [string]$OutCsv  = ".\teams-governance-report.csv",
    [string]$OutHtml = ".\teams-governance-report.html"
)

$ErrorActionPreference = 'Stop'
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "Group.Read.All","Directory.Read.All","GroupMember.Read.All" | Out-Null
}

# --- Control posture ---
$posture = [ordered]@{}
$dir = Get-MgBetaDirectorySetting -All -ErrorAction SilentlyContinue | Where-Object DisplayName -eq 'Group.Unified'
$posture['CreationControlled'] = if ($dir) { (($dir.Values | Where-Object Name -eq 'EnableGroupCreation').Value -eq 'false') } else { $false }
$posture['NamingPolicy']       = if ($dir) { [bool](($dir.Values | Where-Object Name -eq 'PrefixSuffixNamingRequirement').Value) } else { $false }
$posture['BlockedWords']       = if ($dir) { [bool](($dir.Values | Where-Object Name -eq 'CustomBlockedWordsList').Value) } else { $false }
$posture['LabelsEnabled']      = if ($dir) { (($dir.Values | Where-Object Name -eq 'EnableMIPLabels').Value -eq 'true') } else { $false }

$life = Get-MgGroupLifecyclePolicy -ErrorAction SilentlyContinue
$posture['ExpirationActive']   = [bool]$life
$posture['ExpirationDays']     = if ($life) { $life.GroupLifetimeInDays } else { 'n/a' }
$posture['ExpirationScope']    = if ($life) { $life.ManagedGroupTypes }   else { 'n/a' }

# --- Estate metrics ---
$groups = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All `
    -Property "id,displayName,createdDateTime,renewedDateTime,assignedLabels,resourceProvisioningOptions"
$now = Get-Date
$rows = foreach ($g in $groups) {
    $owners = @(Get-MgGroupOwner -GroupId $g.Id -All -ErrorAction SilentlyContinue).Count
    $lastTouch = if ($g.RenewedDateTime) { $g.RenewedDateTime } else { $g.CreatedDateTime }
    $ageDays = if ($lastTouch) { [int]($now - $lastTouch).TotalDays } else { $null }
    [pscustomobject]@{
        DisplayName  = $g.DisplayName
        GroupId      = $g.Id
        IsTeam       = ($g.ResourceProvisioningOptions -contains 'Team')
        Owners       = $owners
        Ownerless    = ($owners -eq 0)
        UnderOwned   = ($owners -lt $MinOwners)
        AgeDays      = $ageDays
        Stale        = ($ageDays -ne $null -and $ageDays -ge $StaleDays)
        Classified   = (($g.AssignedLabels | Measure-Object).Count -gt 0)
        NameKey      = ($g.DisplayName -replace '[^a-zA-Z0-9]','').ToLower()
    }
}
$dupKeys = $rows | Group-Object NameKey | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name
foreach ($r in $rows) { $r | Add-Member Duplicate ($dupKeys -contains $r.NameKey) -Force }

$metrics = [ordered]@{
    TotalTeams   = @($rows | Where-Object IsTeam).Count
    TotalGroups  = $rows.Count
    Ownerless    = @($rows | Where-Object Ownerless).Count
    UnderOwned   = @($rows | Where-Object UnderOwned).Count
    Stale        = @($rows | Where-Object Stale).Count
    Unclassified = @($rows | Where-Object { -not $_.Classified }).Count
    Duplicates   = @($rows | Where-Object Duplicate).Count
}

# --- Output ---
Write-Host "`n===== TEAMS GOVERNANCE POSTURE =====" -ForegroundColor Yellow
$posture.GetEnumerator() | ForEach-Object { Write-Host ("  {0,-20}: {1}" -f $_.Key, $_.Value) }
Write-Host "`n===== ESTATE METRICS =====" -ForegroundColor Yellow
$metrics.GetEnumerator()  | ForEach-Object { Write-Host ("  {0,-20}: {1}" -f $_.Key, $_.Value) }

$rows | Sort-Object DisplayName | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8

$style = "<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px}h1{font-size:20px}table{border-collapse:collapse;margin:12px 0}td,th{border:1px solid #ccc;padding:4px 8px;font-size:13px}th{background:#f3f3f3;text-align:left}.bad{color:#c00;font-weight:bold}.ok{color:#080}</style>"
$postureHtml = ($posture.GetEnumerator() | ForEach-Object { "<tr><th>$($_.Key)</th><td>$($_.Value)</td></tr>" }) -join ''
$metricsHtml = ($metrics.GetEnumerator() | ForEach-Object { "<tr><th>$($_.Key)</th><td>$($_.Value)</td></tr>" }) -join ''
$detail = $rows | Sort-Object DisplayName |
    Select-Object DisplayName,Owners,AgeDays,Ownerless,Stale,Classified,Duplicate |
    ConvertTo-Html -Fragment
$html = "<html><head>$style</head><body><h1>Teams Governance &amp; Lifecycle Report</h1><p>Generated $(Get-Date -Format u)</p><h2>Control posture</h2><table>$postureHtml</table><h2>Estate metrics</h2><table>$metricsHtml</table><h2>Teams detail</h2>$detail</body></html>"
$html | Out-File -FilePath $OutHtml -Encoding UTF8

Write-Host "`nCSV : $OutCsv" -ForegroundColor Green
Write-Host "HTML: $OutHtml" -ForegroundColor Green
