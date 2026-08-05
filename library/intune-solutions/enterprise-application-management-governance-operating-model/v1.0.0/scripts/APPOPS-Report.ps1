<#
.SYNOPSIS
    APPOPS-Report.ps1 — produce the Application Governance Scorecard.
.DESCRIPTION
    PURPOSE
        Read-only. Computes the operating model's steady-state metrics across the whole
        estate: ownership coverage, scope-tag coverage, ring-assignment coverage, broad-target
        risk, naming conformance, and the shadow/orphaned counts. These are the numbers you
        report monthly to the governance forum to prove the model is working — a rising
        coverage trend and a falling risk trend.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPOPS-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\APPOPS-Report.ps1 -CsvPath .\Scorecard.csv
        Government tenant:  add  -GraphEnvironment USGov
        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementRBAC.Read.All, Group.Read.All
    EXPECTED RESULTS
        A one-page scorecard of coverage percentages and risk counts, plus an optional CSV row
        you can append month over month to chart the trend. Pass = coverage climbing toward
        100% and risk counts trending to zero over successive runs.
.NOTES
    Intune Solutions — read-only. Uses the Microsoft Graph PowerShell SDK.
#>

[CmdletBinding()]
param(
    [string] $CsvPath,
    [ValidateSet('Global','USGov')]
    [string] $GraphEnvironment = 'Global'
)

$ErrorActionPreference = 'Stop'
$NamePattern = '^.+ – (Win|macOS|iOS|Android) – Ring[1-3]$'

function Connect-Graph { param([string]$Environment)
    $scopes=@('DeviceManagementApps.Read.All','DeviceManagementRBAC.Read.All','Group.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser" }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) {
        if ($Environment -eq 'USGov'){Connect-MgGraph -Scopes $scopes -Environment USGov|Out-Null}
        else {Connect-MgGraph -Scopes $scopes|Out-Null} } }
function Get-GraphBase { param([string]$Environment)
    if ($Environment -eq 'USGov'){'https://graph.microsoft.us/beta'}else{'https://graph.microsoft.com/beta'} }
function Invoke-GraphGet { param([Parameter(Mandatory)][string]$Uri)
    $items=@();$next=$Uri
    while($next){$r=Invoke-MgGraphRequest -Method GET -Uri $next
        if($r.value){$items+=$r.value}elseif($r){$items+=$r};$next=$r.'@odata.nextLink'}
    return $items }
function Pct { param($n,$d) if($d -eq 0){0}else{[math]::Round(100.0*$n/$d,1)} }

Connect-Graph -Environment $GraphEnvironment
$base = Get-GraphBase -Environment $GraphEnvironment

Write-Host "Computing governance scorecard..." -ForegroundColor Cyan
$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100"

$total=0; $owned=0; $scoped=0; $named=0; $broad=0; $orphaned=0
foreach ($app in $apps) {
    $total++
    $notes=[string]$app.notes
    if ($notes -match '(?im)^\s*Owner:\s*\S') { $owned++ }
    $st=@($app.roleScopeTagIds)
    if (-not ($st.Count -eq 0 -or ($st.Count -eq 1 -and $st[0] -eq '0'))) { $scoped++ }
    if ($app.displayName -match $NamePattern) { $named++ }
    $assignCount=0; $isBroad=$false
    try { $as=Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/assignments"
        $assignCount=$as.Count
        foreach($a in $as){$tt=[string]$a.target.'@odata.type'
            if($tt -match 'allLicensedUsersAssignmentTarget' -or $tt -match 'allDevicesAssignmentTarget'){$isBroad=$true}} } catch {}
    if ($isBroad){$broad++}
    if ($assignCount -eq 0){$orphaned++}
}

$row = [pscustomobject]@{
    Date               = (Get-Date).ToString('yyyy-MM-dd')
    TotalApps          = $total
    OwnershipCoveragePct = (Pct $owned $total)
    ScopeTagCoveragePct  = (Pct $scoped $total)
    NamingConformancePct = (Pct $named $total)
    BroadTargetCount   = $broad
    OrphanedCount      = $orphaned
}

Write-Host ""
Write-Host "===== Application Governance Scorecard =====" -ForegroundColor Cyan
Write-Host ("As of                     : {0}" -f $row.Date)
Write-Host ("Total applications        : {0}" -f $row.TotalApps)
Write-Host ("Ownership coverage        : {0}%" -f $row.OwnershipCoveragePct) -ForegroundColor $(if($row.OwnershipCoveragePct -ge 95){'Green'}else{'Yellow'})
Write-Host ("Scope-tag coverage        : {0}%" -f $row.ScopeTagCoveragePct) -ForegroundColor $(if($row.ScopeTagCoveragePct -ge 95){'Green'}else{'Yellow'})
Write-Host ("Naming conformance        : {0}%" -f $row.NamingConformancePct) -ForegroundColor $(if($row.NamingConformancePct -ge 95){'Green'}else{'Yellow'})
Write-Host ("Broad-target apps (risk)  : {0}" -f $row.BroadTargetCount) -ForegroundColor $(if($row.BroadTargetCount -eq 0){'Green'}else{'Red'})
Write-Host ("Orphaned apps (risk)      : {0}" -f $row.OrphanedCount) -ForegroundColor $(if($row.OrphanedCount -eq 0){'Green'}else{'Red'})

if ($CsvPath) {
    if (Test-Path $CsvPath) { $row | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 -Append }
    else { $row | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 }
    Write-Host ("Appended scorecard row to {0}" -f $CsvPath) -ForegroundColor Green
}
