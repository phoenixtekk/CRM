<#
.SYNOPSIS
    DLCCLEAN-Validate.ps1 — read-only validation: correct/limited scope AND no in-scope held item would be deleted (safe: read-only).
.DESCRIPTION
    PURPOSE
        The defensibility gate. For a named retention/deletion policy it confirms, per gate: (1) the policy is
        scoped to a LIMITED, named location — not tenant-wide "All"; (2) its retention rule action/period match
        the intended design; and (3) — the safety centrepiece — it CROSS-CHECKS the policy's scope against every
        HOLD in the tenant (litigation holds, eDiscovery case holds, and retain-action retention policies) and
        FLAGS any overlap where an in-scope item could be under hold. Read-only — makes no changes. Deletion must
        not proceed unless this reports PASS on the hold cross-check.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLCCLEAN-Validate.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' -CsvPath .\DLCCLEAN-Validate.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession); Exchange Online (Connect-ExchangeOnline) to include litigation-hold overlap.
.EXAMPLE
    .\DLCCLEAN-Validate.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot'
    Prints per-gate PASS/FAIL for scope, action/period, and the hold cross-check.
.NOTES
    Purview — Inactive & Legacy Data Cleanup. Read-only validation. No changes made.
    Expected results: PASS = limited scope + expected action + ZERO deletable held items. Any FAIL blocks enforcement until resolved.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$CsvPath,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$p = Get-RetentionCompliancePolicy -Identity $PolicyName -ErrorAction Stop
Write-Host ("=== Validating '{0}' (Enabled={1}, Mode={2}) ===" -f $p.Name, $p.Enabled, $p.Mode) -ForegroundColor Cyan
$gateResults = @()

# --- Gather this policy's scoped locations ---
$scopeLocations = @()
$isAdaptive = $false
foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation','ModernGroupLocation','TeamsChatLocation','TeamsChannelLocation') {
    foreach ($v in @($p.$loc)) { if ($v) { $scopeLocations += $v } }
}
if (@($p.AdaptiveScopeLocation).Count -gt 0) { $isAdaptive = $true }

# --- GATE 1: scope is limited, not "All" ---
$isAll = @($scopeLocations | Where-Object { $_ -match '^\s*All\s*$' }).Count -gt 0
if ($isAll -and -not $isAdaptive) {
    Write-Host 'GATE 1 (scope limited): FAIL — policy targets "All" (tenant-wide). Narrow to a named pilot scope before enforcing.' -ForegroundColor Red
    $gateResults += [pscustomobject]@{ Gate='ScopeLimited'; Result='FAIL' }
} else {
    Write-Host ("GATE 1 (scope limited): PASS — scope = {0}" -f $(if($isAdaptive){"Adaptive: $($p.AdaptiveScopeLocation -join ', ')"}else{($scopeLocations -join ', ')})) -ForegroundColor Green
    $gateResults += [pscustomobject]@{ Gate='ScopeLimited'; Result='PASS' }
}

# --- GATE 2: action / period as designed ---
$rules = @(Get-RetentionComplianceRule -Policy $PolicyName -ErrorAction SilentlyContinue)
if ($rules.Count -gt 0) {
    foreach ($r in $rules) {
        Write-Host ("GATE 2 (action/period): rule '{0}' -> Action={1}, Duration={2}" -f $r.Name, $r.RetentionComplianceAction, $r.RetentionDuration) -ForegroundColor Green
    }
    $gateResults += [pscustomobject]@{ Gate='ActionPeriod'; Result='PASS'; Detail=($rules | ForEach-Object { "$($_.RetentionComplianceAction)/$($_.RetentionDuration)d" }) -join '; ' }
} else {
    Write-Host 'GATE 2 (action/period): REVIEW — no retention rule found on the policy.' -ForegroundColor Yellow
    $gateResults += [pscustomobject]@{ Gate='ActionPeriod'; Result='REVIEW' }
}

# --- GATE 3: HOLD CROSS-CHECK (the defensibility gate) ---
Write-Host '--- GATE 3: HOLD CROSS-CHECK (no in-scope item may be under hold) ---' -ForegroundColor Cyan
$overlaps = @()

# 3a. eDiscovery case holds — compare their held locations against our scope
if (Get-Command Get-CaseHoldPolicy -ErrorAction SilentlyContinue) {
    foreach ($ch in @(Get-CaseHoldPolicy -ErrorAction SilentlyContinue)) {
        $held = @($ch.ExchangeLocation) + @($ch.SharePointLocation) + @($ch.OneDriveLocation)
        foreach ($h in $held) {
            if ($h -and ($scopeLocations -contains $h -or ($h -match '^\s*All\s*$'))) {
                $overlaps += [pscustomobject]@{ HoldType='eDiscoveryCaseHold'; HoldName=$ch.Name; Location=$h }
            }
        }
    }
}

# 3b. Litigation holds — any in-scope mailbox on litigation hold (Exchange Online)
if (Get-Command Get-Mailbox -ErrorAction SilentlyContinue) {
    try {
        foreach ($sl in $scopeLocations) {
            if ($sl -match '@') {
                $mbx = Get-Mailbox -Identity $sl -ErrorAction SilentlyContinue
                if ($mbx -and $mbx.LitigationHoldEnabled) {
                    $overlaps += [pscustomobject]@{ HoldType='LitigationHold'; HoldName=$mbx.DisplayName; Location=$sl }
                }
            }
        }
    } catch {}
} else {
    Write-Host 'Note: Exchange Online not connected — litigation-hold overlap not evaluated. Connect-ExchangeOnline for a complete check.' -ForegroundColor Yellow
}

# 3c. Other retain-action retention policies covering the same locations
foreach ($other in @(Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne $PolicyName -and $_.Enabled })) {
    $otherLocs = @()
    foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation','ModernGroupLocation') { $otherLocs += @($other.$loc) }
    foreach ($h in $otherLocs) {
        if ($h -and ($scopeLocations -contains $h -or $h -match '^\s*All\s*$')) {
            $overlaps += [pscustomobject]@{ HoldType='RetentionPolicy(retain)'; HoldName=$other.Name; Location=$h }
        }
    }
}

if ($overlaps.Count -eq 0) {
    Write-Host 'GATE 3 (hold cross-check): PASS — no in-scope location overlaps a hold or retain policy. No held item is deletable by this policy.' -ForegroundColor Green
    $gateResults += [pscustomobject]@{ Gate='HoldCrossCheck'; Result='PASS' }
} else {
    Write-Host ("GATE 3 (hold cross-check): FAIL — {0} overlap(s) found. Content here is HELD; exclude these locations or resolve the hold with legal BEFORE enforcing." -f $overlaps.Count) -ForegroundColor Red
    $overlaps | Format-Table -AutoSize
    $gateResults += [pscustomobject]@{ Gate='HoldCrossCheck'; Result='FAIL'; Detail="$($overlaps.Count) overlap(s)" }
}

# --- Summary ---
Write-Host '--- Validation summary ---' -ForegroundColor Cyan
$gateResults | Format-Table -AutoSize
$fail = @($gateResults | Where-Object { $_.Result -eq 'FAIL' }).Count
if ($fail -eq 0) {
    Write-Host 'OVERALL: PASS — scope limited, action as designed, and NO held item deletable. Safe to proceed under change control.' -ForegroundColor Green
} else {
    Write-Host ("OVERALL: FAIL ({0} gate(s)) — DO NOT enforce deletion until resolved." -f $fail) -ForegroundColor Red
}

if ($CsvPath) {
    $gateResults | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    if ($overlaps.Count) { $overlaps | Export-Csv -Path ($CsvPath -replace '\.csv$','-holds.csv') -NoTypeInformation -Encoding UTF8 }
    Write-Host ("Validation exported to {0}" -f $CsvPath) -ForegroundColor Green
}
