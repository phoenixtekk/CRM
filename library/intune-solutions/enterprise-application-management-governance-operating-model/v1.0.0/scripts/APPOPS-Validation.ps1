<#
.SYNOPSIS
    APPOPS-Validation.ps1 — test the application estate against the operating-model gates.
.DESCRIPTION
    PURPOSE
        Read-only. Checks whether the governance controls this solution defines actually
        exist and are applied. It validates: the two scope tags exist
        (Scope - App Management - Prod / - Pilot); the custom role exists
        (Role - App Deployment Engineer); the four APPGOV role groups and three ring groups
        exist; and every application conforms to the naming standard, has a governed owner,
        and is not assigned to All Users / All Devices. Produces a PASS/FAIL line per gate.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPOPS-Validation.ps1
        powershell -ExecutionPolicy Bypass -File .\APPOPS-Validation.ps1 -CsvPath .\Validation.csv
        Government tenant:  add  -GraphEnvironment USGov
        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementRBAC.Read.All, Group.Read.All
    EXPECTED RESULTS
        A gate-by-gate PASS/FAIL report and an overall verdict. Pass = every structural gate
        present and every application conformant. Fail = any missing object or any
        non-conforming application, itemised so you can remediate the exact gap.
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

# Named objects this model creates (must match 03-implementation.md verbatim)
$ExpectedScopeTags = @('Scope – App Management – Prod','Scope – App Management – Pilot')
$ExpectedRole      = 'Role – App Deployment Engineer'
$ExpectedGroups    = @(
    'APPGOV – Application Owners','APPGOV – Technical Owners',
    'APPGOV – Security Reviewers','APPGOV – Deployment Engineers',
    'PILOT – App Ring 1 – Validation','PILOT – App Ring 2 – Early Adopters','PROD – App Ring 3 – Broad'
)
# Naming standard: "<Vendor> <Product> <Version> – <Platform> – <Ring>"
$NamePattern = '^.+ – (Win|macOS|iOS|Android) – Ring[1-3]$'

function Connect-Graph {
    param([string] $Environment)
    $scopes = @('DeviceManagementApps.Read.All','DeviceManagementRBAC.Read.All','Group.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) {
        if ($Environment -eq 'USGov') { Connect-MgGraph -Scopes $scopes -Environment USGov | Out-Null }
        else { Connect-MgGraph -Scopes $scopes | Out-Null }
    }
}
function Get-GraphBase { param([string]$Environment)
    if ($Environment -eq 'USGov') { 'https://graph.microsoft.us/beta' } else { 'https://graph.microsoft.com/beta' } }
function Invoke-GraphGet { param([Parameter(Mandatory)][string]$Uri)
    $items=@(); $next=$Uri
    while ($next) { $r=Invoke-MgGraphRequest -Method GET -Uri $next
        if ($r.value){$items+=$r.value}elseif($r){$items+=$r}; $next=$r.'@odata.nextLink' }
    return $items }

Connect-Graph -Environment $GraphEnvironment
$base = Get-GraphBase -Environment $GraphEnvironment

$gateResults = New-Object System.Collections.Generic.List[object]
function Add-Gate { param($Name,$Pass,$Detail)
    $gateResults.Add([pscustomobject]@{ Gate=$Name; Result=$(if($Pass){'PASS'}else{'FAIL'}); Detail=$Detail }) }

# Gate 1 — scope tags exist
$tags = Invoke-GraphGet -Uri "$base/deviceManagement/roleScopeTags"
foreach ($t in $ExpectedScopeTags) {
    $found = $tags | Where-Object { $_.displayName -eq $t }
    Add-Gate "Scope tag: $t" ([bool]$found) $(if($found){"present"}else{"MISSING — create per Step 5a"})
}

# Gate 2 — custom role exists
$roles = Invoke-GraphGet -Uri "$base/deviceManagement/roleDefinitions?`$filter=isBuiltIn eq false"
$role = $roles | Where-Object { $_.displayName -eq $ExpectedRole }
Add-Gate "Custom role: $ExpectedRole" ([bool]$role) $(if($role){"present"}else{"MISSING — create per Step 5b"})

# Gate 3 — governance groups exist
$groups = Invoke-GraphGet -Uri "$base/groups?`$select=id,displayName&`$top=999"
foreach ($g in $ExpectedGroups) {
    $found = $groups | Where-Object { $_.displayName -eq $g }
    Add-Gate "Group: $g" ([bool]$found) $(if($found){"present"}else{"MISSING — create per Step 4 / Step 6"})
}

# Gate 4 — application conformance
$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100"
$appRows = New-Object System.Collections.Generic.List[object]
foreach ($app in $apps) {
    $nameOk = ($app.displayName -match $NamePattern)
    $notes  = [string]$app.notes
    $ownerOk = ($notes -match '(?im)^\s*Owner:\s*\S')
    $broad = $false
    try {
        $as = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/assignments"
        foreach ($a in $as) { $tt=[string]$a.target.'@odata.type'
            if ($tt -match 'allLicensedUsersAssignmentTarget' -or $tt -match 'allDevicesAssignmentTarget'){$broad=$true} }
    } catch {}
    $conform = $nameOk -and $ownerOk -and (-not $broad)
    $appRows.Add([pscustomobject]@{
        AppName=$app.displayName; NameConforms=$nameOk; HasOwner=$ownerOk; BroadTarget=$broad; Conformant=$conform })
}
$nonConf = $appRows | Where-Object { -not $_.Conformant }
Add-Gate "Application conformance" ($nonConf.Count -eq 0) `
    $("{0} of {1} conformant; {2} need remediation" -f ($appRows.Count-$nonConf.Count), $appRows.Count, $nonConf.Count)

Write-Host ""
Write-Host "===== Operating-model validation =====" -ForegroundColor Cyan
$gateResults | ForEach-Object {
    $c = if ($_.Result -eq 'PASS') { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1} — {2}" -f $_.Result, $_.Gate, $_.Detail) -ForegroundColor $c
}
if ($nonConf.Count -gt 0) {
    Write-Host "`nNon-conformant applications:" -ForegroundColor Yellow
    $nonConf | Format-Table -AutoSize AppName, NameConforms, HasOwner, BroadTarget
}
$overall = ($gateResults | Where-Object { $_.Result -eq 'FAIL' }).Count -eq 0
Write-Host ""
Write-Host ("OVERALL: {0}" -f $(if($overall){'PASS'}else{'FAIL'})) -ForegroundColor $(if($overall){'Green'}else{'Red'})

if ($CsvPath) {
    $gateResults | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Saved validation to {0}" -f $CsvPath) -ForegroundColor Green
}
