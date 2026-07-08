<#
.SYNOPSIS
    IPMANREC-Health.ps1 — flag conflicting settings across overlapping label policies, inconsistent default labels, and pilot-scope drift (read-only).
.DESCRIPTION
    A cadence health check for the mandatory-vs-recommended design. It reads all label policies and their
    advanced settings and reports: policies with DIFFERENT mandatory/default values that could target
    overlapping populations (priority decides opaquely), inconsistent default labels across policies, and
    pilot-named policies still mandating (a sign a pilot ring was never expanded or dissolved). Read-only —
    makes no changes. Policy-priority resolution and true population overlap can only be confirmed against
    your directory groups — this flags candidates for review.
.EXAMPLE
    .\IPMANREC-Health.ps1
    Reports conflicting/inconsistent policy settings and pilot-scope sanity across all label policies.
.EXAMPLE
    .\IPMANREC-Health.ps1 -PilotNamePattern 'Pilot'
    Treats policies whose name matches 'Pilot' as pilot policies for the stale-pilot check.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession).
    Role: Information Protection Admin (read).
    Expected results: PASS (green) = no conflicts, one consistent default, no stale pilot mandating.
    FAIL/WARN (yellow/red) = conflicting or inconsistent settings to reconcile before they cause
    unpredictable client behaviour. Population overlap is inferred from policy scope metadata only -
    confirm true overlap against your directory groups.
#>
[CmdletBinding()]
param(
    [string]$PilotNamePattern = 'Pilot'
)

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-LabelPolicy -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

function Get-AdvSetting($obj, [string]$key) {
    try {
        $s = $obj.Settings | Where-Object { $_ -match [regex]::Escape($key) }
        if ($s) { return ($s -join '; ') }
    } catch { }
    return ''
}
function Say([string]$tag, [string]$msg, [string]$col) {
    Write-Host ("  [{0}] {1}" -f $tag, $msg) -ForegroundColor $col
}

Write-Host "=== IPMANREC health check (read-only) ===" -ForegroundColor Cyan
$policies = @(Get-LabelPolicy -ErrorAction SilentlyContinue)
if (-not $policies) { Write-Host "  [WARN] No label policies found (verify Connect-IPPSSession / licensing)." -ForegroundColor Yellow; return }

$issues = 0

# --- 1. Inconsistent default labels across policies ---
Write-Host "`n--- Default-label consistency ---" -ForegroundColor Cyan
$defaults = @{}
foreach ($p in $policies) {
    $def = (Get-AdvSetting $p 'DefaultLabelId') -replace '.*=', ''
    $def = $def.Trim()
    if ($def) { $defaults[$p.Name] = $def }
}
$distinct = $defaults.Values | Sort-Object -Unique
if ($distinct.Count -gt 1) {
    Say 'WARN' "Policies set $($distinct.Count) different default labels: $($distinct -join ', '). Confirm this is intended per population." 'Yellow'
    $defaults.GetEnumerator() | ForEach-Object { Write-Host "        $($_.Key) -> $($_.Value)" -ForegroundColor Gray }
    $issues++
} else {
    Say 'PASS' 'Default label is consistent (or set on a single policy).' 'Green'
}

# --- 2. Conflicting mandatory settings (some ON, some off) ---
Write-Host "`n--- Mandatory-labeling consistency ---" -ForegroundColor Cyan
$mandOn  = @($policies | Where-Object { (Get-AdvSetting $_ 'Mandatory') -match 'true' })
$mandOff = @($policies | Where-Object { -not ((Get-AdvSetting $_ 'Mandatory') -match 'true') })
if ($mandOn.Count -gt 0 -and $mandOff.Count -gt 0) {
    Say 'WARN' "$($mandOn.Count) policy(ies) mandate a label, $($mandOff.Count) do not - users covered by both get priority-resolved behaviour (opaque). Review overlap." 'Yellow'
    Write-Host "        Mandating: $(( $mandOn | Select-Object -Expand Name) -join ', ')" -ForegroundColor Gray
    $issues++
} else {
    Say 'PASS' 'Mandatory labeling is consistent across policies.' 'Green'
}

# --- 3. Stale pilot policies still mandating ---
Write-Host "`n--- Pilot-scope sanity ---" -ForegroundColor Cyan
$stalePilots = @($policies | Where-Object { $_.Name -match $PilotNamePattern -and ((Get-AdvSetting $_ 'Mandatory') -match 'true') })
if ($stalePilots.Count -gt 0) {
    Say 'WARN' "Pilot-named policy(ies) still mandating - confirm the pilot expanded to a broad policy and the pilot is retired: $(( $stalePilots | Select-Object -Expand Name) -join ', ')" 'Yellow'
    $issues++
} else {
    Say 'PASS' "No stale pilot policy left mandating (pattern '$PilotNamePattern')." 'Green'
}

Write-Host ("`n=== Health check complete: {0} item(s) to review ===" -f $issues) -ForegroundColor $(if ($issues -eq 0) { 'Green' } else { 'Yellow' })
if ($issues -gt 0) { Write-Host 'Reconcile with the signed-off design; confirm true population overlap against directory groups.' -ForegroundColor Yellow }
