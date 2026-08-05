<#
.SYNOPSIS
    APPOPS-Remediation.ps1 — stamp governance metadata (owner + ARB reference + scope tag) onto apps.
.DESCRIPTION
    PURPOSE
        The one WRITE script in this package. It reads a CSV of applications and writes a
        structured governance block into each application's Notes field (Owner, ARB reference,
        governed date) and applies the named scope tag. It changes NOTHING about the
        application's package, assignments, or deployment behaviour — it only records who owns
        the app and that it was governed. Defaults to -WhatIf: it previews and writes nothing
        until you re-run with -Apply.
    HOW TO RUN
        Preview (writes nothing):
          powershell -ExecutionPolicy Bypass -File .\APPOPS-Remediation.ps1 -InputCsv .\AppEstate-Governance.csv
        Apply:
          powershell -ExecutionPolicy Bypass -File .\APPOPS-Remediation.ps1 -InputCsv .\AppEstate-Governance.csv -Apply
        Government tenant:  add  -GraphEnvironment USGov
        Required Graph scopes: DeviceManagementApps.ReadWrite.All, DeviceManagementRBAC.Read.All

        Input CSV columns (produced in Step 12): AppId, AppName, GovernedOwner, ArbReference, ScopeTagToApply
    EXPECTED RESULTS
        In preview: a table of the intended change per app (old vs new Notes, scope tag).
        With -Apply: each app's Notes updated with the governance block and the scope tag
        applied; a PASS line per app. Verify in Intune: Apps > All apps > <app> > Properties.
.NOTES
    Intune Solutions — write, gated by -WhatIf/-Apply. Uses the Microsoft Graph PowerShell SDK.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $InputCsv,
    [switch] $Apply,
    [ValidateSet('Global','USGov')]
    [string] $GraphEnvironment = 'Global'
)

$ErrorActionPreference = 'Stop'

function Connect-Graph { param([string]$Environment,[switch]$Write)
    $scopes = if ($Write) { @('DeviceManagementApps.ReadWrite.All','DeviceManagementRBAC.Read.All') }
              else        { @('DeviceManagementApps.Read.All','DeviceManagementRBAC.Read.All') }
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

if (-not (Test-Path $InputCsv)) { throw "Input CSV not found: $InputCsv" }
$rows = Import-Csv -Path $InputCsv
if (-not $rows) { throw "Input CSV is empty: $InputCsv" }

Connect-Graph -Environment $GraphEnvironment -Write:$Apply
$base = Get-GraphBase -Environment $GraphEnvironment

# Map scope tag display names -> ids
$tags = Invoke-GraphGet -Uri "$base/deviceManagement/roleScopeTags"
$tagMap = @{}
foreach ($t in $tags) { $tagMap[$t.displayName] = $t.id }

$mode = if ($Apply) { 'APPLY' } else { 'PREVIEW (-WhatIf)' }
Write-Host ("Mode: {0}" -f $mode) -ForegroundColor $(if($Apply){'Red'}else{'Cyan'})

foreach ($row in $rows) {
    $appId = $row.AppId
    if (-not $appId) { Write-Host "Row missing AppId; skipped." -ForegroundColor Yellow; continue }

    try { $app = Invoke-MgGraphRequest -Method GET -Uri "$base/deviceAppManagement/mobileApps/$appId" }
    catch { Write-Host ("AppId {0} not found; skipped." -f $appId) -ForegroundColor Yellow; continue }

    $odataType = $app.'@odata.type'
    $governedBlock = @(
        "----- APP GOVERNANCE -----"
        "Owner: $($row.GovernedOwner)"
        "ARB-Reference: $($row.ArbReference)"
        "Governed-Date: $((Get-Date).ToString('yyyy-MM-dd'))"
        "--------------------------"
    ) -join "`n"

    # Preserve any human text above the governance block
    $existing = [string]$app.notes
    $preserved = ($existing -replace '(?ms)-----\s*APP GOVERNANCE\s*-----.*?--------------------------','').Trim()
    $newNotes = if ($preserved) { "$preserved`n`n$governedBlock" } else { $governedBlock }

    $scopeName = $row.ScopeTagToApply
    $scopeId = $null
    if ($scopeName) {
        if ($tagMap.ContainsKey($scopeName)) { $scopeId = $tagMap[$scopeName] }
        else { Write-Host ("Scope tag '{0}' not found in tenant; will keep existing tags." -f $scopeName) -ForegroundColor Yellow }
    }

    Write-Host ""
    Write-Host ("App : {0}" -f $app.displayName) -ForegroundColor White
    Write-Host ("  Owner        -> {0}" -f $row.GovernedOwner)
    Write-Host ("  ARB ref      -> {0}" -f $row.ArbReference)
    Write-Host ("  Scope tag    -> {0}{1}" -f $scopeName, $(if($scopeId){" (id $scopeId)"}else{" (unchanged)"}))

    if (-not $Apply) { Write-Host "  [PREVIEW] no change written." -ForegroundColor Cyan; continue }

    $body = @{ '@odata.type' = $odataType; notes = $newNotes }
    if ($scopeId) { $body['roleScopeTagIds'] = @([string]$scopeId) }

    try {
        Invoke-MgGraphRequest -Method PATCH -Uri "$base/deviceAppManagement/mobileApps/$appId" `
            -Body ($body | ConvertTo-Json -Depth 5)
        Write-Host "  [PASS] governance metadata written." -ForegroundColor Green
    } catch {
        Write-Host ("  [FAIL] {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

Write-Host ""
if (-not $Apply) {
    Write-Host "Preview complete. Re-run with -Apply to write the changes." -ForegroundColor Cyan
} else {
    Write-Host "Apply complete. Verify in Intune: Apps > All apps > <app> > Properties." -ForegroundColor Green
}
