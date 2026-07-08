<#
.SYNOPSIS
    OPSAUTO-Report.ps1 - Report deployed Purview policy inventory and a coverage scorecard vs the config (read-only).
.DESCRIPTION
    PURPOSE
        Produces two standing evidence artifacts from the live tenant (or a captured snapshot) against the
        desired-state config (Automation Config - Purview Ops - Baseline): "Automation Report - Policy
        Inventory - Tenant" (every managed DLP/label/retention object, its mode/enable state, and whether
        the config expects it) and "Automation Report - Coverage Scorecard - Tenant" (counts by type,
        % of expected policies present, % in the expected safe-first mode, and enforced count). Read-only -
        changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OPSAUTO-Report.ps1 -ConfigPath .\baseline.json -Scope Pilot
        Optional: -SnapshotPath .\snapshot.json to report against a Discovery snapshot instead of live;
        -OutDir to set where the CSV/JSON land. Requires ExchangeOnlineManagement (Connect-IPPSSession) for
        live mode. No secrets.
    EXPECTED RESULTS
        A printed inventory table + scorecard, plus a CSV inventory and a JSON scorecard on disk. PASS
        signal: the scorecard's "present vs expected" is 100% for the scope and every present policy is in
        the mode the config expects (safe-first until deliberately enforced). VERIFY expected DLP mode
        values for your tenant.
.NOTES
    Purview category - Automation Framework. Read-only. DLP mode values evolve/are licensing-dependent;
    confirm expected values against your tenant and current Microsoft documentation. No client names; no secrets.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [ValidateSet('Pilot','Full')][string]$Scope = 'Pilot',
    [string]$SnapshotPath,
    [string]$UserPrincipalName,
    [string]$OutDir = "."
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }

$cfg = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
$expected = @($cfg.policies | Where-Object { $_.scope -eq $Scope -or $Scope -eq 'Full' })

# --- Load current state: from snapshot or live ---
$live = @{ dlp=@{}; label=@{}; labelPolicy=@{}; retention=@{} }
if ($SnapshotPath) {
    $snap = Get-Content -Raw -Path $SnapshotPath | ConvertFrom-Json
    foreach ($d in $snap.dlpPolicies)        { $live.dlp[$d.name]        = $d }
    foreach ($l in $snap.sensitivityLabels)  { $live.label[$l.name]      = $l }
    foreach ($p in $snap.labelPolicies)      { $live.labelPolicy[$p.name] = $p }
    foreach ($r in $snap.retentionPolicies)  { $live.retention[$r.name]  = $r }
    Write-Section "Reporting against snapshot: $SnapshotPath"
} else {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { throw "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser" }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    $cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }
    Connect-IPPSSession @cp -ErrorAction Stop | Out-Null
    try { Get-DlpCompliancePolicy -ErrorAction Stop        | ForEach-Object { $live.dlp[$_.Name]        = $_ } } catch {}
    try { Get-Label -ErrorAction Stop                      | ForEach-Object { $live.label[$_.Name]      = $_ } } catch {}
    try { Get-LabelPolicy -ErrorAction Stop                | ForEach-Object { $live.labelPolicy[$_.Name] = $_ } } catch {}
    try { Get-RetentionCompliancePolicy -ErrorAction Stop  | ForEach-Object { $live.retention[$_.Name]  = $_ } } catch {}
    Write-Section "Reporting against LIVE tenant"
}

$configNames = @($cfg.policies | ForEach-Object { $_.name })

# --- Build the inventory (every managed-name object, plus expected-but-missing) ---
$inventory = New-Object System.Collections.Generic.List[object]
function Get-State($type,$obj){
    switch ($type) {
        'dlp'         { return "$($obj.mode)$($obj.Mode)" }
        'retention'   { return $(if (($obj.enabled -eq $false) -or ($obj.Enabled -eq $false)) { 'Disabled' } else { 'Enabled' }) }
        'label'       { return $(if ($obj.Disabled) { 'Disabled' } else { 'Defined' }) }
        'labelPolicy' { return $(if ($obj.Enabled -eq $false) { 'Disabled' } else { 'Enabled' }) }
        default       { return '' }
    }
}

foreach ($bucket in 'dlp','label','labelPolicy','retention') {
    foreach ($name in $live[$bucket].Keys) {
        $isManaged = ($configNames -contains $name) -or ($name -like 'Automation *')
        if (-not $isManaged) { continue }
        $expectEntry = $expected | Where-Object { $_.name -eq $name -and $_.type -eq $bucket } | Select-Object -First 1
        $state = Get-State $bucket $live[$bucket][$name]
        $inventory.Add([pscustomobject]@{
            Type        = $bucket
            Name        = $name
            State       = $state
            InConfig    = $(if ($configNames -contains $name) { 'YES' } else { 'EXTRA' })
            ExpectMode  = $(if ($expectEntry) { $expectEntry.expectMode } else { '' })
            InScope     = $(if ($expectEntry) { 'YES' } else { '' })
        })
    }
}
# Expected-but-missing
foreach ($e in $expected) {
    $present = $live[$e.type].ContainsKey($e.name)
    if (-not $present) {
        $inventory.Add([pscustomobject]@{
            Type=$e.type; Name=$e.name; State='MISSING'; InConfig='YES'; ExpectMode=$e.expectMode; InScope='YES'
        })
    }
}

# --- Scorecard ---
$expCount     = $expected.Count
$presentCount = @($expected | Where-Object { $live[$_.type].ContainsKey($_.name) }).Count
$modeOk = @($expected | Where-Object {
    $_.type -eq 'dlp' -and $_.expectMode -and $live.dlp.ContainsKey($_.name) -and
    ("$($live.dlp[$_.name].mode)$($live.dlp[$_.name].Mode)" -match [regex]::Escape($_.expectMode))
}).Count
$dlpExpectMode = @($expected | Where-Object { $_.type -eq 'dlp' -and $_.expectMode }).Count
$enforcedCount = @($live.dlp.Values | Where-Object { "$($_.mode)$($_.Mode)" -match 'Enable' }).Count
$extraCount    = @($inventory | Where-Object { $_.InConfig -eq 'EXTRA' }).Count

$scorecard = [ordered]@{
    generatedUtc          = (Get-Date).ToUniversalTime().ToString('o')
    scope                 = $Scope
    expectedPolicies      = $expCount
    presentPolicies       = $presentCount
    presentPct            = $(if ($expCount) { [math]::Round(100.0 * $presentCount / $expCount, 1) } else { 0 })
    dlpWithExpectedMode   = $dlpExpectMode
    dlpInExpectedMode     = $modeOk
    dlpEnforcedInTenant   = $enforcedCount
    extraManagedNames     = $extraCount
    byType                = @{
        dlp        = $live.dlp.Count
        label      = $live.label.Count
        labelPolicy= $live.labelPolicy.Count
        retention  = $live.retention.Count
    }
}

# --- Emit ---
$invPath = Join-Path $OutDir 'Automation-Report-Policy-Inventory-Tenant.csv'
$scoPath = Join-Path $OutDir 'Automation-Report-Coverage-Scorecard-Tenant.json'
$inventory | Sort-Object Type,Name | Export-Csv -Path $invPath -NoTypeInformation -Encoding UTF8
$scorecard | ConvertTo-Json -Depth 6 | Out-File -FilePath $scoPath -Encoding UTF8

Write-Section 'Automation Report - Policy Inventory - Tenant'
$inventory | Sort-Object Type,Name | Format-Table -AutoSize | Out-String | Write-Host
Write-Section 'Automation Report - Coverage Scorecard - Tenant'
Write-Host ("  Expected (scope {0}): {1}   Present: {2} ({3}%)" -f $Scope, $expCount, $presentCount, $scorecard.presentPct)
Write-Host ("  DLP expecting a mode: {0}   in expected mode: {1}   enforced in tenant: {2}" -f $dlpExpectMode, $modeOk, $enforcedCount)
if ($extraCount -gt 0) { Write-Host ("  EXTRA managed-style names not in config: {0} - investigate with the owner." -f $extraCount) -ForegroundColor Yellow }
Write-Host ("`nInventory -> {0}" -f $invPath) -ForegroundColor Green
Write-Host ("Scorecard -> {0}" -f $scoPath) -ForegroundColor Green
Write-Host 'Hand these to compliance/security as the standing inventory + monitoring evidence. Read-only - nothing changed.'
