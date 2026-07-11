<#
.SYNOPSIS
    SOAXDR-Validate.ps1 — validate that recommended Defender-suite best-practice controls are present
    across the four assessment domains; returns Pass/Gap with evidence. Read-only.
.DESCRIPTION
    PURPOSE
        Consumes the baseline produced by SOAXDR-Discovery.ps1 (plus operator portal-confirmed inputs)
        and evaluates, per domain:
          - Cross-pillar coverage: all in-scope pillars onboarded
          - Unified RBAC: unified RBAC activated + no excessive Global Admins
          - Incident correlation: alerts span more than one pillar (serviceSource)
          - Suite-wide Secure Score: score above a floor
        Each check returns Pass or Gap WITH the evidence. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOAXDR-Validate.ps1 `
            -BaselinePath ".\Posture Baseline - Defender Suite - Assess.json" `
            -PillarsOnboarded @('endpoint','identity','email','cloudapps','cloud') `
            -PillarsInScope   @('endpoint','identity','email','cloudapps','cloud') `
            -UnifiedRbacActivated $true -SecureScoreFloor 70 -MaxGlobalAdmins 5 `
            -OutputPath ".\SOAXDR-validation.json"
    EXPECTED RESULTS
        A per-domain Pass/Gap table with evidence — the input to SOAXDR-Score.ps1 and the report.
.NOTES
    White-label. Read-only. Point-in-time snapshot. A dark/unlicensed pillar is a coverage finding
    (licensing has a cost the customer accepts). Mark truly N/A pillars out of scope. Verify current
    RBAC model and licensing facts.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaselinePath,
    [string[]]$PillarsInScope   = @('endpoint','identity','email','cloudapps','cloud'),
    [string[]]$PillarsOnboarded = @(),
    [bool]$UnifiedRbacActivated = $false,
    [int]$SecureScoreFloor = 70,
    [int]$MaxGlobalAdmins = 5,
    [string]$OutputPath = ".\SOAXDR-validation.json"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $BaselinePath)) { throw "Baseline not found: $BaselinePath. Run SOAXDR-Discovery.ps1 first." }
$baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json

$checks = @()
function Add-Check {
    param([string]$Domain,[string]$Control,[bool]$Pass,[string]$Evidence)
    $script:checks += [ordered]@{ domain=$Domain; control=$Control; result=($(if($Pass){'Pass'}else{'Gap'})); evidence=$Evidence }
}

# Domain 1 — Cross-pillar coverage (one check per in-scope pillar)
foreach ($pillar in $PillarsInScope) {
    $onboarded = $PillarsOnboarded -contains $pillar
    Add-Check "crossPillarCoverage" "Pillar onboarded: $pillar" $onboarded "$pillar = $(if($onboarded){'onboarded'}else{'DARK - coverage finding (license/onboard to gain this pillar)'})"
}

# Domain 2 — Unified RBAC
Add-Check "unifiedRbac" "Defender XDR Unified RBAC activated" $UnifiedRbacActivated "unifiedRbacActivated=$UnifiedRbacActivated (legacy per-product permissions is a finding)"
$gaCount = [int]$baseline.domains.unifiedRbac.globalAdminCount
Add-Check "unifiedRbac" "Global Admin count within limit (<= $MaxGlobalAdmins)" ($gaCount -le $MaxGlobalAdmins) "globalAdminCount=$gaCount (excess standing privilege is high-risk)"

# Domain 3 — Incident correlation
$srcCount = [int]$baseline.domains.incidentCorrelation.distinctSourceCount
Add-Check "incidentCorrelation" "Alerts span more than one pillar (correlation possible)" ($srcCount -gt 1) "distinctAlertSources=$srcCount (single source => only one pillar feeding signal)"

# Domain 4 — Suite-wide Secure Score
$pct = $baseline.domains.suiteSecureScore.percentage
$scorePct = if ($pct) { [double]$pct } else { 0 }
Add-Check "suiteSecureScore" "Suite Secure Score at or above floor ($SecureScoreFloor%)" ($scorePct -ge $SecureScoreFloor) "secureScore=$scorePct% (floor $SecureScoreFloor%)"

$summary = $checks | Group-Object domain | ForEach-Object {
    $g = $_.Group
    [ordered]@{ domain=$_.Name; pass=@($g|?{$_.result -eq 'Pass'}).Count; gap=@($g|?{$_.result -eq 'Gap'}).Count }
}

$out = [ordered]@{
    solution        = "SOAXDR"
    generatedUtc    = (Get-Date).ToUniversalTime().ToString("o")
    readOnly        = $true
    pillarsInScope  = $PillarsInScope
    checks          = $checks
    summary         = $summary
}
$out | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Validation complete (read-only)." -ForegroundColor Green
$checks | ForEach-Object {
    $color = if ($_.result -eq 'Pass') { 'Green' } else { 'Yellow' }
    Write-Host ("[{0}] {1} :: {2} — {3}" -f $_.result, $_.domain, $_.control, $_.evidence) -ForegroundColor $color
}
Write-Host "Written: $OutputPath" -ForegroundColor Green
