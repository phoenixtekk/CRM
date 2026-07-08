<#
.SYNOPSIS
    OPSADOPT-Discovery.ps1 — read-only inventory of the Purview ADOPTION SURFACE (published sensitivity labels, label policies + scope, DLP/retention modes) with optional baseline save/compare. Makes no changes.
.DESCRIPTION
    PURPOSE
        Builds the adoption surface the program drives people to use: every published sensitivity label,
        label policy (with the users/groups it is scoped to), and DLP / retention policy with its current
        MODE (Enable / Test / Disable). Optionally saves a known-good baseline (-SaveBaseline) and, on later
        runs, compares live state to it (-CompareBaseline) to report surface drift — new, removed, or
        mode/scope-changed controls since the last review. Read-only; uses Security & Compliance PowerShell.
    HOW TO RUN
        Connect-IPPSSession                                  # modern-auth admin sign-in (no secrets in code)
        .\OPSADOPT-Discovery.ps1                              # inventory to console + optional CSV
        .\OPSADOPT-Discovery.ps1 -SaveBaseline -BaselinePath .\Adoption-Baseline.json
        .\OPSADOPT-Discovery.ps1 -CompareBaseline -BaselinePath .\Adoption-Baseline.json
        PowerShell 5.1+/7+; requires the ExchangeOnlineManagement module (Connect-IPPSSession).
    EXPECTED RESULTS
        A per-control table (Family, Name, Mode, Scope) and, with -CompareBaseline, a DRIFT report listing
        Added / Removed / Changed controls. Zero drift against an unchanged tenant = pass.
.NOTES
    Purview — Adoption Program. Read-only. Purview is plan-gated (E5 / E5 Compliance for advanced DLP /
    auto-labeling) and the portal evolves; cmdlet/label availability depends on your licensing/role —
    verify for your tenant. Which labels exist and what they mean is a compliance determination, not set here.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$BaselinePath = '.\Adoption-Baseline.json',
    [switch]$SaveBaseline,
    [switch]$CompareBaseline
)

function Test-IPPSConnected {
    # Get-Label is only available inside a Connect-IPPSSession context.
    if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
        Write-Error "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first."
        return $false
    }
    return $true
}
if (-not (Test-IPPSConnected)) { return }

Write-Host "=== Adoption Surface - Purview ===" -ForegroundColor Cyan
$surface = New-Object System.Collections.Generic.List[object]

function Add-Item {
    param([string]$Family, [scriptblock]$Getter, [string]$ModeProp = 'Mode', [scriptblock]$ScopeSelector)
    try { $items = & $Getter } catch {
        Write-Warning ("{0}: not available in this tenant/role ({1})" -f $Family, $_.Exception.Message); return
    }
    foreach ($p in $items) {
        $mode  = if ($p.PSObject.Properties.Name -contains $ModeProp) { [string]$p.$ModeProp } else { '' }
        $scope = if ($ScopeSelector) { try { (& $ScopeSelector $p) } catch { '' } } else { '' }
        $surface.Add([pscustomobject]@{ Family=$Family; Name=[string]$p.Name; Mode=$mode; Scope=$scope })
    }
}

# --- Published controls users are asked to adopt (read-only) ---
Add-Item -Family 'Label'        -Getter { Get-Label } -ModeProp 'DisplayName'   # labels have no Mode; show display name
Add-Item -Family 'LabelPolicy'  -Getter { Get-LabelPolicy } -ScopeSelector {
    param($p)
    # Scope of a label policy is best-effort: exchange/SharePoint locations vary by tenant/version.
    $loc = @()
    foreach ($prop in 'ExchangeLocation','ModernGroupLocation','SharePointLocation') {
        if ($p.PSObject.Properties.Name -contains $prop -and $p.$prop) { $loc += ($p.$prop | ForEach-Object { $_.ToString() }) }
    }
    ($loc | Select-Object -First 5) -join '; '
}
Add-Item -Family 'AutoLabeling' -Getter { Get-AutoSensitivityLabelPolicy }
Add-Item -Family 'DLP'          -Getter { Get-DlpCompliancePolicy }
Add-Item -Family 'Retention'    -Getter { Get-RetentionCompliancePolicy }

$surface | Sort-Object Family, Name | Format-Table -AutoSize
Write-Host ("Total controls on the adoption surface: {0}" -f $surface.Count) -ForegroundColor Green

$enforce = @($surface | Where-Object { $_.Mode -eq 'Enable' }).Count
$testish = @($surface | Where-Object { $_.Mode -match 'Test' }).Count
Write-Host ("Modes -> Enforcing (Enable): {0}  |  In test/simulation: {1}  (adopt BEFORE you enforce)" -f $enforce, $testish) -ForegroundColor Cyan

if ($CsvPath) {
    $surface | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved surface CSV to {0}" -f $CsvPath) -ForegroundColor Green
}

if ($SaveBaseline) {
    $surface | ConvertTo-Json -Depth 4 | Set-Content -Path $BaselinePath -Encoding UTF8
    Write-Host ("Adoption baseline saved to {0} ({1} controls). Re-baseline only at approved milestones." -f $BaselinePath, $surface.Count) -ForegroundColor Green
}

if ($CompareBaseline) {
    if (-not (Test-Path $BaselinePath)) { Write-Error "Baseline not found at $BaselinePath. Run with -SaveBaseline first."; return }
    $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    $key = { param($o) "{0}|{1}" -f $o.Family, $o.Name }
    $baseMap = @{}; foreach ($b in $base)    { $baseMap[(& $key $b)] = $b }
    $liveMap = @{}; foreach ($l in $surface) { $liveMap[(& $key $l)] = $l }

    $drift = New-Object System.Collections.Generic.List[object]
    foreach ($k in $liveMap.Keys) {
        if (-not $baseMap.ContainsKey($k)) {
            $drift.Add([pscustomobject]@{ Change='Added'; Control=$k; From=''; To=$liveMap[$k].Mode })
        } elseif ($baseMap[$k].Mode -ne $liveMap[$k].Mode -or $baseMap[$k].Scope -ne $liveMap[$k].Scope) {
            $drift.Add([pscustomobject]@{ Change='Changed'; Control=$k; From=("{0}/{1}" -f $baseMap[$k].Mode,$baseMap[$k].Scope); To=("{0}/{1}" -f $liveMap[$k].Mode,$liveMap[$k].Scope) })
        }
    }
    foreach ($k in $baseMap.Keys) {
        if (-not $liveMap.ContainsKey($k)) { $drift.Add([pscustomobject]@{ Change='Removed'; Control=$k; From=$baseMap[$k].Mode; To='' }) }
    }

    Write-Host "`n=== SURFACE DRIFT vs baseline ===" -ForegroundColor Yellow
    if ($drift.Count -eq 0) { Write-Host "No surface drift. (PASS)" -ForegroundColor Green }
    else { $drift | Sort-Object Change, Control | Format-Table -AutoSize; Write-Warning ("{0} change(s) to the adoption surface since baseline." -f $drift.Count) }
}
