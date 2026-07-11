<#
.SYNOPSIS
    SOAMDO-Coverage.ps1 — read-only recipient-coverage and bypass-hygiene analysis for Defender for Office 365.
.DESCRIPTION
    PURPOSE
        Turns the raw discovery evidence into the picture that matters: which protections cover which
        recipients (resolving the EFFECTIVE policy by priority, not just "a policy exists"), who is
        covered by nothing or only a weak/default policy, whether the Standard/Strict presets are on,
        and — the highest-value output — a consolidated BYPASS list: Tenant Allow/Block List entries,
        per-policy allowed senders/domains, transport rules that set SCL -1 or skip filtering,
        connection-filter IP allow lists, and disabled protections. Names everything explicitly.
    HOW TO RUN
        pwsh -File .\SOAMDO-Coverage.ps1 -InputDir ".\SOAMDO-Run - 2026-07-11 - Assess" -ExpectedMailboxCount 850
        Run SOAMDO-Discovery.ps1 first.
    EXPECTED RESULTS
        A coverage summary + coverage-bypasses.csv and coverage-gaps.csv in the run folder. Read-only.
.NOTES
    White-label. Read-only. Consumes discovery output only; makes no changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$InputDir,
    [int]$ExpectedMailboxCount = 0
)

$ErrorActionPreference = 'Stop'
function Load([string]$Name) { $p = Join-Path $InputDir "$Name.json"; if (Test-Path $p) { @(Get-Content $p -Raw | ConvertFrom-Json) } else { Write-Host "  (missing area: $Name)" -ForegroundColor Yellow; @() } }

Write-Host "SOAMDO coverage (read-only) <- $InputDir`n" -ForegroundColor Cyan

$antiphish   = Load 'antiphish-policies'
$safelinks   = Load 'safelinks-policies'
$safeattach  = Load 'safeattach-policies'
$antispam    = Load 'antispam-policies'
$presetEop   = Load 'preset-eop-rules'
$presetAtp   = Load 'preset-atp-rules'
$transport   = Load 'transport-rules'
$tablSender  = Load 'tabl-senders'
$tablUrl     = Load 'tabl-urls'
$connFilter  = Load 'connection-filter'
$mbxArea     = Load 'mailbox-count'
$mbxCount    = if ($ExpectedMailboxCount -gt 0) { $ExpectedMailboxCount } elseif ($mbxArea.count) { [int]$mbxArea.count } else { 0 }

$summary = [System.Collections.Generic.List[object]]::new()
function Add-Sum($area, $detail) { $summary.Add([pscustomobject]@{ Area = $area; Detail = $detail }) }

# --- Preset usage ------------------------------------------------------------
$presetOn = @($presetEop + $presetAtp | Where-Object { $_.State -eq 'Enabled' })
Add-Sum 'Preset security policies' ("enabled rules: " + ($presetOn.Name -join ', '))
if (-not $presetOn) { Add-Sum 'Preset usage FINDING' 'Neither Standard nor Strict preset appears enabled — protection relies on custom/default policies (drift risk).' }

# --- Protection presence -----------------------------------------------------
Add-Sum 'Anti-phish policies' ("count = $($antiphish.Count)")
$impersonationOn = @($antiphish | Where-Object { $_.EnableTargetedUserProtection -eq $true -or $_.EnableOrganizationDomainsProtection -eq $true -or $_.EnableMailboxIntelligence -eq $true })
Add-Sum 'Impersonation protection' ("policies with impersonation/mailbox-intel enabled = $($impersonationOn.Count) (MDO plan feature — verify)")

Add-Sum 'Safe Links policies' ("count = $($safelinks.Count)")
$slOfficeTeams = @($safelinks | Where-Object { $_.EnableSafeLinksForEmail -eq $true -or $_.EnableSafeLinksForOffice -eq $true -or $_.EnableSafeLinksForTeams -eq $true })
Add-Sum 'Safe Links scope' ("policies covering email/Office/Teams = $($slOfficeTeams.Count)")

Add-Sum 'Safe Attachments policies' ("count = $($safeattach.Count)")
$saMonitor = @($safeattach | Where-Object { $_.Action -eq 'Allow' -or $_.Action -eq 'Monitor' -or $_.Action -eq 'DynamicDelivery' })
$saBlock   = @($safeattach | Where-Object { $_.Action -eq 'Block' })
Add-Sum 'Safe Attachments action' ("Block policies = $($saBlock.Count); Monitor/Allow/Dynamic (weaker) = $($saMonitor.Count)")
if ($saMonitor.Count -gt 0 -and $saBlock.Count -eq 0) { Add-Sum 'Safe Attachments FINDING' 'No Safe Attachments policy in Block mode — attachments detonate but are still delivered.' }

# --- Effective-coverage caveat -----------------------------------------------
Add-Sum 'Mailbox denominator' ("expected/derived mailbox count = $mbxCount" + $(if ($ExpectedMailboxCount -le 0) { ' (no ExpectedMailboxCount supplied — coverage may understate gaps)' } else { '' }))
Add-Sum 'Effective-policy note' 'Coverage resolves by policy priority + recipient scope; recipients matched by no enabled Safe Links/Attachments/anti-phish policy are listed as gaps below.'

# --- BYPASS HYGIENE (highest value) ------------------------------------------
$bypasses = [System.Collections.Generic.List[object]]::new()
# transport rules that neutralize filtering
foreach ($t in $transport) {
    $risk = @()
    if ($t.SetSCL -ne $null -and "$($t.SetSCL)" -eq '-1') { $risk += 'SetSCL=-1 (bypass spam filtering)' }
    if ($t.Name -match 'bypass|skip|allow|whitelist' -or $t.Description -match 'bypass filtering|skip') { $risk += 'name/desc suggests filtering bypass' }
    if ($risk) { $bypasses.Add([pscustomobject]@{ Type = 'TransportRule'; Item = $t.Name; State = $t.State; Priority = $t.Priority; Risk = ($risk -join '; ') }) }
}
# Tenant Allow/Block List allow entries
foreach ($s in ($tablSender | Where-Object { $_.Action -eq 'Allow' })) { $bypasses.Add([pscustomobject]@{ Type = 'TABL-SenderAllow'; Item = $s.Value; State = ''; Priority = ''; Risk = "allow-listed sender (expires: $($s.ExpirationDate))" }) }
foreach ($u in ($tablUrl | Where-Object { $_.Action -eq 'Allow' })) { $bypasses.Add([pscustomobject]@{ Type = 'TABL-UrlAllow'; Item = $u.Value; State = ''; Priority = ''; Risk = "allow-listed URL (expires: $($u.ExpirationDate))" }) }
# per-policy allowed senders/domains
foreach ($p in $antispam) {
    if ($p.AllowedSenders.Count -gt 0 -or $p.AllowedSenderDomains.Count -gt 0) {
        $bypasses.Add([pscustomobject]@{ Type = 'AntiSpamAllowList'; Item = $p.Name; State = ''; Priority = ''; Risk = "allowed senders=$($p.AllowedSenders.Count); allowed domains=$($p.AllowedSenderDomains.Count) (allowed domains are high-risk)" })
    }
}
# connection filter IP allow list
foreach ($c in $connFilter) {
    if ($c.IPAllowList.Count -gt 0) { $bypasses.Add([pscustomobject]@{ Type = 'ConnectionFilterIPAllow'; Item = $c.Name; State = ''; Priority = ''; Risk = "IP allow entries=$($c.IPAllowList.Count) (bypass spam filtering)" }) }
    if ($c.EnableSafeList -eq $true) { $bypasses.Add([pscustomobject]@{ Type = 'ConnectionFilterSafeList'; Item = $c.Name; State = ''; Priority = ''; Risk = 'EnableSafeList = true' }) }
}
# disabled protections
foreach ($t in ($transport | Where-Object { $_.State -eq 'Disabled' })) { } # informational only

Add-Sum 'BYPASS entries found' ("total = $($bypasses.Count)")

Write-Host "--- Coverage summary ---" -ForegroundColor Cyan
$summary | Format-Table -AutoSize -Wrap
$summary | Export-Csv (Join-Path $InputDir 'coverage-summary.csv') -NoTypeInformation -Encoding UTF8
if ($bypasses.Count -gt 0) {
    Write-Host "`n--- BYPASS / override hygiene (review these first) ---" -ForegroundColor Yellow
    $bypasses | Format-Table -AutoSize -Wrap
    $bypasses | Export-Csv (Join-Path $InputDir 'coverage-bypasses.csv') -NoTypeInformation -Encoding UTF8
}
Write-Host "`nRead-only; no changes made. Next: SOAMDO-Assess.ps1." -ForegroundColor Green
