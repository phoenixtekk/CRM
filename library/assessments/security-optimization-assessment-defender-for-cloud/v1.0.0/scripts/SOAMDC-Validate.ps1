<#
.SYNOPSIS
    SOAMDC-Validate.ps1 — validate that recommended Defender for Cloud best-practice controls are
    present across the four assessment domains; returns Pass/Gap with evidence. Read-only.
.DESCRIPTION
    PURPOSE
        Consumes the baseline produced by SOAMDC-Discovery.ps1 and evaluates, per domain, whether the
        recommended controls exist:
          - Secure Score & recommendations: score above a floor
          - Plan coverage: the key workload plans on (Servers, Storage, SQL/Databases, Containers, KeyVault)
          - Regulatory compliance: the REQUIRED standard mapped and enabled
          - Agent/agentless: agentless scanning enabled and provider registered
        Each check returns Pass or Gap WITH the evidence. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOAMDC-Validate.ps1 `
            -BaselinePath ".\Posture Baseline - Defender for Cloud - Assess.json" `
            -RequiredStandard "Microsoft cloud security benchmark" `
            -SecureScoreFloor 70 `
            -OutputPath ".\SOAMDC-validation.json"
    EXPECTED RESULTS
        A per-domain Pass/Gap table with evidence — the input to SOAMDC-Score.ps1 and the report.
.NOTES
    White-label. Read-only. Point-in-time snapshot. Plan/preview facts flagged verify. A plan being
    Off is a coverage finding (enabling it has a cost the customer accepts), not automatically a defect.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaselinePath,
    [string]$RequiredStandard = "Microsoft cloud security benchmark",
    [int]$SecureScoreFloor = 70,
    [string[]]$RequiredPlans = @('VirtualMachines','StorageAccounts','SqlServers','Containers','KeyVaults'),
    [string]$OutputPath = ".\SOAMDC-validation.json"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $BaselinePath)) { throw "Baseline not found: $BaselinePath. Run SOAMDC-Discovery.ps1 first." }
$baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json

$checks = @()
function Add-Check {
    param([string]$Domain,[string]$Control,[bool]$Pass,[string]$Evidence)
    $script:checks += [ordered]@{ domain=$Domain; control=$Control; result=($(if($Pass){'Pass'}else{'Gap'})); evidence=$Evidence }
}

# Domain 1 — Secure Score
$pct = $null
if ($baseline.domains.secureScore.secureScore) { $pct = [double]$baseline.domains.secureScore.secureScore.percentage }
$scorePct = if ($pct) { [math]::Round($pct * 100, 1) } else { 0 }
Add-Check "secureScore" "Secure Score at or above floor ($SecureScoreFloor%)" ($scorePct -ge $SecureScoreFloor) "secureScore=$scorePct% (floor $SecureScoreFloor%)"

# Domain 2 — Plan coverage
$standardPlans = @($baseline.domains.planCoverage.standardPlans)
foreach ($rp in $RequiredPlans) {
    $on = $standardPlans -contains $rp
    Add-Check "planCoverage" "Workload plan on: $rp" $on "$rp = $(if($on){'Standard/On'}else{'Free/Off - coverage finding (enabling has a cost)'})"
}

# Domain 3 — Regulatory compliance
$mapped = @($baseline.domains.regulatoryCompliance.mappedStandards)
$reqMatch = $mapped | Where-Object { $_.name -like "*$RequiredStandard*" -and $_.state -ne 'Unsupported' }
Add-Check "regulatoryCompliance" "Required standard mapped: $RequiredStandard" ([bool]$reqMatch) "mapped=$($reqMatch -ne $null); standardsPresent=$(@($mapped | ForEach-Object { $_.name }) -join ', ')"

# Domain 4 — Agent/agentless coverage
$agentless = [bool]$baseline.domains.agentCoverage.agentlessScanning
$providerReg = [bool]$baseline.domains.agentCoverage.providerRegistered
Add-Check "agentCoverage" "Microsoft.Security provider registered" $providerReg "providerRegistered=$providerReg"
Add-Check "agentCoverage" "Agentless machine scanning enabled" $agentless "agentlessScanning=$agentless (requires Defender CSPM / Servers - verify)"

$summary = $checks | Group-Object domain | ForEach-Object {
    $g = $_.Group
    [ordered]@{ domain=$_.Name; pass=@($g|?{$_.result -eq 'Pass'}).Count; gap=@($g|?{$_.result -eq 'Gap'}).Count }
}

$out = [ordered]@{
    solution     = "SOAMDC"
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    readOnly     = $true
    requiredStandard = $RequiredStandard
    checks       = $checks
    summary      = $summary
}
$out | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Validation complete (read-only)." -ForegroundColor Green
$checks | ForEach-Object {
    $color = if ($_.result -eq 'Pass') { 'Green' } else { 'Yellow' }
    Write-Host ("[{0}] {1} :: {2} — {3}" -f $_.result, $_.domain, $_.control, $_.evidence) -ForegroundColor $color
}
Write-Host "Written: $OutputPath" -ForegroundColor Green
