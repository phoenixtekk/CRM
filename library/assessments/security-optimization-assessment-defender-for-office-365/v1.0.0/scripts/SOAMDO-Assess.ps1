<#
.SYNOPSIS
    SOAMDO-Assess.ps1 — read-only scoring of Defender for Office 365 posture against a named preset + Secure Score baseline.
.DESCRIPTION
    PURPOSE
        Evaluates the discovery/coverage evidence as checks, each scored Pass / Partial / Fail / N-A
        against the named baseline (Microsoft preset Standard/Strict + Secure Score, and/or the org
        standard). Every non-pass gets a severity (High/Medium/Low) and becomes a finding with evidence
        and a remediation pointer; bypass findings are weighted high. Areas roll up into a weighted
        posture score (%). MDO-only checks on an EOP-only tenant are scored N-A, not Fail.
    HOW TO RUN
        pwsh -File .\SOAMDO-Assess.ps1 -InputDir ".\SOAMDO-Run - 2026-07-11 - Assess" -Baseline "Preset Strict + Secure Score (2026-07, verify)" -OutputCsv ".\SOAMDO-Scorecard - Tenant - Assess.csv"
        Run SOAMDO-Discovery.ps1 and SOAMDO-Coverage.ps1 first.
    EXPECTED RESULTS
        A scorecard CSV + findings.json in the run folder, and a posture score to console.
.NOTES
    White-label. Read-only. Scoring only. Risk-acceptance is the customer's decision.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$InputDir,
    [string]$Baseline = 'Microsoft preset Standard/Strict + Secure Score (verify current guidance)',
    [Parameter(Mandatory = $true)] [string]$OutputCsv
)

$ErrorActionPreference = 'Stop'
function Load([string]$Name) { $p = Join-Path $InputDir "$Name.json"; if (Test-Path $p) { @(Get-Content $p -Raw | ConvertFrom-Json) } else { @() } }

$antiphish  = Load 'antiphish-policies'
$safelinks  = Load 'safelinks-policies'
$safeattach = Load 'safeattach-policies'
$antimal    = Load 'antimalware-policies'
$antispam   = Load 'antispam-policies'
$presetEop  = Load 'preset-eop-rules'
$presetAtp  = Load 'preset-atp-rules'
$dkim       = Load 'dkim'
$bypasses   = if (Test-Path (Join-Path $InputDir 'coverage-bypasses.csv')) { @(Import-Csv (Join-Path $InputDir 'coverage-bypasses.csv')) } else { @() }
# MDO plan present if any Safe Links/Attachments/impersonation config exists
$mdoPresent = ($safelinks.Count -gt 0) -or ($safeattach.Count -gt 0) -or (@($antiphish | Where-Object { $_.EnableTargetedUserProtection -eq $true }).Count -gt 0)

$checks = [System.Collections.Generic.List[object]]::new()
function Add-Check($id, $area, $desc, $weight, $result, $severity, $evidence, $remediation) {
    $checks.Add([pscustomobject]@{
        CheckId = $id; Area = $area; Description = $desc; Weight = $weight
        Result = $result; Severity = $(if ($result -in @('Pass','N-A')) { '' } else { $severity })
        Evidence = $evidence; Remediation = $remediation; Baseline = $Baseline
    })
}

# --- Preset usage ------------------------------------------------------------
$presetOn = @($presetEop + $presetAtp | Where-Object { $_.State -eq 'Enabled' })
Add-Check 'MDO-01' 'Preset policies' 'Standard or Strict preset security policy enabled' 2 ($(if ($presetOn) { 'Pass' } else { 'Fail' })) 'High' "enabled presets = $($presetOn.Name -join ', ')" 'Enable the Strict (or Standard) preset to get Microsoft-maintained recommended settings.'

# --- Anti-phish / impersonation ---------------------------------------------
$impers = @($antiphish | Where-Object { $_.EnableTargetedUserProtection -eq $true -or $_.EnableOrganizationDomainsProtection -eq $true })
$imResult = if (-not $mdoPresent) { 'N-A' } elseif ($impers) { 'Pass' } else { 'Fail' }
Add-Check 'MDO-02' 'Anti-phish' 'Impersonation protection (user/domain) enabled' 3 $imResult 'High' "policies with impersonation = $($impers.Count) (MDO plan feature — verify)" 'Enable targeted-user and domain impersonation protection in the anti-phish policy.'

$spoof = @($antiphish | Where-Object { $_.EnableSpoofIntelligence -eq $true })
Add-Check 'MDO-03' 'Anti-phish' 'Spoof intelligence enabled' 1 ($(if ($antiphish.Count -eq 0) { 'N-A' } elseif ($spoof) { 'Pass' } else { 'Fail' })) 'Medium' "spoof-intel policies = $($spoof.Count)" 'Enable spoof intelligence and set the appropriate action on detected spoof.'

# --- Safe Links --------------------------------------------------------------
$slFull = @($safelinks | Where-Object { $_.EnableSafeLinksForEmail -eq $true -and ($_.EnableSafeLinksForOffice -eq $true -or $_.EnableSafeLinksForTeams -eq $true) })
$slResult = if (-not $mdoPresent) { 'N-A' } elseif ($slFull) { 'Pass' } elseif ($safelinks.Count -gt 0) { 'Partial' } else { 'Fail' }
Add-Check 'MDO-04' 'Safe Links' 'Safe Links covers email + Office/Teams' 2 $slResult 'High' "full-scope Safe Links policies = $($slFull.Count) of $($safelinks.Count)" 'Extend Safe Links to Office apps and Teams, not just email.'

# --- Safe Attachments --------------------------------------------------------
$saBlock = @($safeattach | Where-Object { $_.Action -eq 'Block' })
$saResult = if (-not $mdoPresent) { 'N-A' } elseif ($saBlock) { 'Pass' } elseif ($safeattach.Count -gt 0) { 'Partial' } else { 'Fail' }
Add-Check 'MDO-05' 'Safe Attachments' 'Safe Attachments in Block mode' 3 $saResult 'High' "Block policies = $($saBlock.Count) of $($safeattach.Count) (Monitor/Dynamic = weaker)" 'Set Safe Attachments action to Block; Monitor detonates but still delivers.'

# --- Anti-malware / anti-spam presence ---------------------------------------
Add-Check 'MDO-06' 'Anti-malware' 'Anti-malware policy present with ZAP' 1 ($(if ($antimal.Count -gt 0) { 'Pass' } else { 'Fail' })) 'Medium' "anti-malware policies = $($antimal.Count)" 'Ensure an anti-malware policy with ZAP is applied to all recipients.'
$dkimOn = @($dkim | Where-Object { $_.Enabled -eq $true })
Add-Check 'MDO-07' 'DKIM' 'DKIM signing enabled for custom domains' 1 ($(if ($dkim.Count -eq 0) { 'N-A' } elseif ($dkimOn.Count -eq $dkim.Count) { 'Pass' } elseif ($dkimOn) { 'Partial' } else { 'Fail' })) 'Low' "DKIM enabled on $($dkimOn.Count)/$($dkim.Count) domains" 'Enable DKIM signing for all custom sending domains.'

# --- BYPASS HYGIENE (weighted high) ------------------------------------------
$byResult = if ($bypasses.Count -eq 0) { 'Pass' } elseif ($bypasses.Count -le 3) { 'Partial' } else { 'Fail' }
Add-Check 'MDO-08' 'Override & bypass hygiene' 'No risky filtering bypasses (transport rules / allow lists / IP allow)' 3 $byResult 'High' "bypass entries = $($bypasses.Count) (see coverage-bypasses.csv)" 'Review and remove stale/over-broad bypasses pilot-first; keep only justified, dated exceptions.'

# --- Roll-up -----------------------------------------------------------------
$scoreable = $checks | Where-Object { $_.Result -ne 'N-A' }
$map = @{ 'Pass' = 1.0; 'Partial' = 0.5; 'Fail' = 0.0 }
$wsum = ($scoreable | Measure-Object -Property Weight -Sum).Sum
$ach = 0.0; foreach ($c in $scoreable) { $ach += ($map[$c.Result] * $c.Weight) }
$posture = if ($wsum -gt 0) { [math]::Round(100.0 * $ach / $wsum, 1) } else { 0 }

$checks | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
($checks | Where-Object { $_.Result -in @('Fail','Partial') }) | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $InputDir 'findings.json') -Encoding UTF8

Write-Host "SOAMDO posture score: $posture% against baseline: $Baseline`n" -ForegroundColor Cyan
$checks | Select-Object CheckId, Area, Result, Severity, Description | Format-Table -AutoSize
Write-Host "`nScorecard: $OutputCsv  |  Findings: findings.json  (N-A = EOP-only/inapplicable)" -ForegroundColor Green
Write-Host "Read-only. Risk-acceptance & remediation priority are the security owners' decisions." -ForegroundColor Green
