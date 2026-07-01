<#
.SYNOPSIS
    MDMRDY-Report.ps1 — readiness/risk scoring + dependency map + draft wave plan (read-only).
.DESCRIPTION
    PURPOSE
        From the "Estate Inventory - MDM Migration - Assess", produces in one pass:
          - "Readiness Scorecard - MDM Migration - Assess"  (per-device readiness 0-100)
          - "Risk Register - MDM Migration - Assess"        (per-device risk + factors)
          - "Dependency Map - MDM Migration - Assess"       (what must move together)
          - draft "Wave Plan - MDM Migration - Configure"   (suggested wave per device)
        Read-only: it computes scores from the inventory and writes report CSVs only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDMRDY-Report.ps1 -InventoryCsv C:\MDMRDY\estate-inventory.csv -OutputFolder C:\MDMRDY
        Optional: -SupportedOS @{ Windows='10.0.19045'; iOS='16'; iPadOS='16'; macOS='13'; Android='12' }
                  -StaleDays 90
    EXPECTED RESULTS
        Writes readiness-scorecard.csv, risk-register.csv, dependency-map.csv, and wave-plan-draft.csv,
        then prints a readiness/risk and wave-distribution summary.
.NOTES
    Migrations — vendor-neutral pre-migration assessment. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InventoryCsv,
    [string]$OutputFolder = (Join-Path $PWD 'MDMRDY'),
    [hashtable]$SupportedOS = @{ Windows='10.0.19044'; iOS='16'; iPadOS='16'; macOS='13'; Android='11' },
    [int]$StaleDays = 90
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $InventoryCsv)) { throw "Inventory CSV not found: $InventoryCsv" }
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }

$rows = Import-Csv -Path $InventoryCsv
$staleCutoff = (Get-Date).AddDays(-$StaleDays)

function Get-MajorVersion { param($v) if ($v -match '(\d+)') { [int]$Matches[1] } else { 0 } }

$readiness  = New-Object System.Collections.Generic.List[object]
$risk       = New-Object System.Collections.Generic.List[object]
$deps       = New-Object System.Collections.Generic.List[object]
$wave       = New-Object System.Collections.Generic.List[object]

foreach ($r in $rows) {
    $name = $r.DeviceName
    $profiles = if ($r.Profiles) { $r.Profiles -split ';' | ForEach-Object { $_.Trim() } } else { @() }

    # ----- Readiness (0-100): start at 100, deduct gaps -----
    $rScore = 100; $rNotes = New-Object System.Collections.Generic.List[string]
    $minOS = $SupportedOS[$r.Platform]
    if ($minOS -and (Get-MajorVersion $r.OSVersion) -lt (Get-MajorVersion $minOS)) { $rScore -= 40; $rNotes.Add('OS below target baseline') }
    if ([string]::IsNullOrWhiteSpace($r.EnrollmentType)) { $rScore -= 15; $rNotes.Add('Enrollment type unknown') }
    if ([string]::IsNullOrWhiteSpace($r.Apps))    { $rScore -= 15; $rNotes.Add('App coverage unknown') }
    if ([string]::IsNullOrWhiteSpace($r.Profiles)){ $rScore -= 10; $rNotes.Add('Profile coverage unknown') }
    $dt = $null
    if ($r.LastCheckIn -and [datetime]::TryParse($r.LastCheckIn,[ref]$dt) -and $dt -lt $staleCutoff) { $rScore -= 20; $rNotes.Add('Stale check-in') }
    if ($r.Compliance -eq 'NonCompliant') { $rScore -= 10; $rNotes.Add('Non-compliant') }
    if ($rScore -lt 0) { $rScore = 0 }
    $readiness.Add([pscustomobject]@{ DeviceName=$name; Platform=$r.Platform; ReadinessScore=$rScore; Notes=($rNotes -join '; ') })

    # ----- Risk (0-100): start at 0, add factors -----
    $kScore = 0; $kFactors = New-Object System.Collections.Generic.List[string]
    if ($r.Criticality -eq 'Executive') { $kScore += 25; $kFactors.Add('Executive') }
    if ($r.Criticality -eq 'Critical')  { $kScore += 30; $kFactors.Add('Mission-critical') }
    if ($r.EnrollmentType -in 'Shared','Kiosk') { $kScore += 20; $kFactors.Add('Shared/Kiosk') }
    if ($profiles -contains 'Cert') { $kScore += 20; $kFactors.Add('Certificate dependency') }
    if ($profiles -contains 'VPN')  { $kScore += 15; $kFactors.Add('VPN dependency') }
    if ($minOS -and (Get-MajorVersion $r.OSVersion) -lt (Get-MajorVersion $minOS)) { $kScore += 15; $kFactors.Add('Unsupported OS for target') }
    if ($r.Compliance -eq 'NonCompliant') { $kScore += 10; $kFactors.Add('Non-compliant') }
    if ($r.LastCheckIn -and [datetime]::TryParse($r.LastCheckIn,[ref]$dt) -and $dt -lt $staleCutoff) { $kScore += 10; $kFactors.Add('Stale') }
    if ($kScore -gt 100) { $kScore = 100 }
    $riskLevel = if ($kScore -ge 50) { 'High' } elseif ($kScore -ge 25) { 'Medium' } else { 'Low' }
    $risk.Add([pscustomobject]@{ DeviceName=$name; RiskScore=$kScore; RiskLevel=$riskLevel; Factors=($kFactors -join '; ') })

    # ----- Dependencies (what must move together) -----
    foreach ($p in ($profiles | Where-Object { $_ -in 'Cert','VPN','Wi-Fi','Email' })) {
        $deps.Add([pscustomobject]@{ DeviceName=$name; DependencyType=$p; Group=("{0}:{1}" -f $r.Department,$p); Note='Move with same-dependency cohort' })
    }
    if ($r.EnrollmentType -in 'Shared','Kiosk') {
        $deps.Add([pscustomobject]@{ DeviceName=$name; DependencyType='SharedDevice'; Group=("Shared:{0}:{1}" -f $r.Department,$r.Region); Note='Migrate shared-device set together' })
    }

    # ----- Draft wave assignment -----
    $w = if ($kScore -ge 50 -or $rScore -lt 40) { 'Wave3-ComplexCritical' }
         elseif ($kScore -ge 25 -or $rScore -lt 70) { 'Wave2-Broad' }
         else { 'Wave1-Early' }
    $wave.Add([pscustomobject]@{ DeviceName=$name; Platform=$r.Platform; ReadinessScore=$rScore; RiskScore=$kScore; SuggestedWave=$w })
}

$f1 = Join-Path $OutputFolder 'readiness-scorecard.csv'
$f2 = Join-Path $OutputFolder 'risk-register.csv'
$f3 = Join-Path $OutputFolder 'dependency-map.csv'
$f4 = Join-Path $OutputFolder 'wave-plan-draft.csv'
$readiness | Export-Csv $f1 -NoTypeInformation -Encoding UTF8
$risk      | Export-Csv $f2 -NoTypeInformation -Encoding UTF8
$deps      | Export-Csv $f3 -NoTypeInformation -Encoding UTF8
$wave      | Export-Csv $f4 -NoTypeInformation -Encoding UTF8

Write-Host "=== Readiness / Risk / Waves ===" -ForegroundColor Cyan
$avgR = if ($readiness.Count) { [math]::Round((($readiness | Measure-Object ReadinessScore -Average).Average),1) } else { 0 }
Write-Host ("Devices            : {0}" -f $rows.Count)
Write-Host ("Avg readiness      : {0}" -f $avgR)
Write-Host "Risk distribution:"
$risk | Group-Object RiskLevel | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-7} {1}" -f $_.Name, $_.Count) }
Write-Host "Suggested waves:"
$wave | Group-Object SuggestedWave | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-22} {1}" -f $_.Name, $_.Count) }
Write-Host "Artifacts written:" -ForegroundColor Green
Write-Host "  $f1  (Readiness Scorecard - MDM Migration - Assess)"
Write-Host "  $f2  (Risk Register - MDM Migration - Assess)"
Write-Host "  $f3  (Dependency Map - MDM Migration - Assess)"
Write-Host "  $f4  (draft Wave Plan - MDM Migration - Configure)"
