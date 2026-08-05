<#
.SYNOPSIS
    APPASMT-Assignment-Analysis.ps1 — analyze app assignment sprawl and conflicts (READ-ONLY).
.DESCRIPTION
    PURPOSE
        Evidences dimensions D1 (Governance) and D3 (Deployment & Rings) by finding assignment sprawl
        and conflicts across the Intune app estate: apps assigned to All Devices / All Licensed Users
        (no ring discipline), apps carrying conflicting intents (required AND available/uninstall to
        overlapping audiences), apps assigned to groups that have zero members (orphaned assignments),
        and the overall assignment-per-app spread. READ-ONLY — Graph .Read.All scopes only.
    HOW TO RUN
        Connect-MgGraph -Scopes "DeviceManagementApps.Read.All","Group.Read.All"
        #   GCC High: add -Environment USGov
        powershell -ExecutionPolicy Bypass -File .\APPASMT-Assignment-Analysis.ps1 -OutDir .\APPASMT-EvidencePack
    EXPECTED RESULTS
        Console summary plus:
          APPASMT-Assignment-Findings.csv   (one row per flagged app/assignment issue)
          APPASMT-Assignment-Summary.json   (aggregate counts for the maturity aggregator)
.NOTES
    Intune Solutions — application management assessment. READ-ONLY (analysis; no tenant writes).
    Least-privilege: Intune "Read Only Operator" + Graph *.Read.All. Government: -Environment USGov
    (GCC High) / USGovDoD (DoD); verify GCC High feature parity where uncertain.
#>
[CmdletBinding()]
param([string]$OutDir = ".\APPASMT-EvidencePack")

$ctx = Get-MgContext -ErrorAction SilentlyContinue
if (-not $ctx) { throw "Not connected. Run Connect-MgGraph with read-only scopes first (see .NOTES)." }
Write-Host ("Connected as {0} | Environment: {1}" -f $ctx.Account, $ctx.Environment) -ForegroundColor Cyan
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

Write-Host "Reading apps with assignments (paged) ..." -ForegroundColor Cyan
$apps = @()
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/mobileApps?`$top=50&`$expand=assignments"
while ($uri) { $p = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $p.value; $uri = $p.'@odata.nextLink' }

# Cache group membership counts so an orphaned (empty) group assignment can be flagged.
$groupCountCache = @{}
function Get-GroupMemberCount([string]$groupId) {
    if (-not $groupId) { return $null }
    if ($groupCountCache.ContainsKey($groupId)) { return $groupCountCache[$groupId] }
    try {
        $r = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$groupId/members/`$count" -Headers @{ ConsistencyLevel = 'eventual' }
        $c = [int]$r
    } catch { $c = $null }
    $groupCountCache[$groupId] = $c
    return $c
}

$findings = New-Object System.Collections.Generic.List[object]
$allDevCount = 0; $conflictCount = 0; $orphanCount = 0; $overlapCount = 0

foreach ($a in $apps) {
    $assigns = @($a.assignments)
    if ($assigns.Count -eq 0) { continue }

    $intents = $assigns | ForEach-Object { $_.intent } | Sort-Object -Unique
    # Conflicting intents on the same app (required + uninstall, or required + available).
    if (($intents -contains 'required') -and (($intents -contains 'uninstall') -or ($intents -contains 'available'))) {
        $conflictCount++
        $findings.Add([pscustomobject]@{ App=$a.displayName; Issue='Conflicting intents'; Detail=($intents -join '+'); Dimension='D3' })
    }
    # More than 4 assignments on one app = sprawl candidate.
    if ($assigns.Count -gt 4) {
        $overlapCount++
        $findings.Add([pscustomobject]@{ App=$a.displayName; Issue='Assignment sprawl'; Detail="$($assigns.Count) assignments"; Dimension='D1' })
    }
    foreach ($asg in $assigns) {
        $tt = [string]$asg.target.'@odata.type'
        if ($tt -match 'allDevices|allLicensedUsers') {
            $allDevCount++
            $findings.Add([pscustomobject]@{ App=$a.displayName; Issue='Assigned to All Devices/Users (no ring)'; Detail=$asg.intent; Dimension='D3' })
        } elseif ($tt -match 'groupAssignmentTarget' -and $asg.target.groupId) {
            $mc = Get-GroupMemberCount $asg.target.groupId
            if ($mc -eq 0) {
                $orphanCount++
                $findings.Add([pscustomobject]@{ App=$a.displayName; Issue='Orphaned assignment (empty group)'; Detail=$asg.target.groupId; Dimension='D1' })
            }
        }
    }
}

Write-Host ("`n=== APPASMT Assignment Analysis — {0} apps scanned ===" -f $apps.Count) -ForegroundColor Cyan
Write-Host ("  Assigned to All Devices/Users (D3 ring gap): {0}" -f $allDevCount)
Write-Host ("  Conflicting intents (D3):                    {0}" -f $conflictCount)
Write-Host ("  Assignment sprawl >4 (D1):                   {0}" -f $overlapCount)
Write-Host ("  Orphaned assignments to empty groups (D1):   {0}" -f $orphanCount)

$summary = [ordered]@{
    generatedUtc        = (Get-Date).ToUniversalTime().ToString('o')
    appsScanned         = $apps.Count
    allDevicesOrUsers   = $allDevCount
    conflictingIntents  = $conflictCount
    assignmentSprawl    = $overlapCount
    orphanedAssignments = $orphanCount
}
$findings | Export-Csv (Join-Path $OutDir 'APPASMT-Assignment-Findings.csv') -NoTypeInformation -Encoding UTF8
$summary  | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $OutDir 'APPASMT-Assignment-Summary.json') -Encoding UTF8
Write-Host ("`nWrote APPASMT-Assignment-Findings.csv and APPASMT-Assignment-Summary.json to {0}" -f $OutDir) -ForegroundColor Green
Write-Host "Read-only complete. No tenant changes were made." -ForegroundColor Green
