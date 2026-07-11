<#
.SYNOPSIS
    SOPMDE-Validate.ps1 — confirm the tuning applied: ASR rules blocking on the pilot ring,
    tamper protection & EDR block mode on, web filtering active, sensor health healthy.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Solution Optimization — Microsoft Defender for Endpoint"
        solution. Checks the pass/fail gates from the Testing Guide: the pilot ASR policy exists
        and targets the pilot ring, the intended ASR rules are set to block, endpoint-hardening
        policy is present, and sensor-health coverage is healthy. Reports PASS/WARN per check and
        an overall verdict. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Validate.ps1
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Validate.ps1 `
            -AsrPolicyName 'ASR Hardening - Pilot Ring - Pilot' `
            -HardeningPolicyName 'Endpoint Hardening - Pilot Ring - Pilot'
        Requires Microsoft.Graph.Authentication with read scopes
        (DeviceManagementConfiguration.Read.All, Machine.Read.All, SecurityEvents.Read.All).
    EXPECTED RESULTS
        A PASS/WARN line per check and an overall verdict — the gate for expanding beyond the
        pilot ring (Implementation Step 7).
.NOTES
    White-label. Read-only. Portal-only toggles (tamper/EDR/web-filter) are prompted for manual
    confirmation where an API read is not available.
#>
[CmdletBinding()]
param(
    [string]$AsrPolicyName = 'ASR Hardening - Pilot Ring - Pilot',
    [string]$HardeningPolicyName = 'Endpoint Hardening - Pilot Ring - Pilot',
    [string]$PilotGroupName = 'MDE Optimize - Pilot Ring - Pilot'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','Machine.Read.All','SecurityEvents.Read.All' -NoWelcome | Out-Null }

$pass = 0; $warn = 0
function Check($name, $ok, $detail) {
    if ($ok) { Write-Host ("   [PASS] {0} — {1}" -f $name, $detail) -ForegroundColor Green; $script:pass++ }
    else     { Write-Host ("   [WARN] {0} — {1}" -f $name, $detail) -ForegroundColor Yellow; $script:warn++ }
}

Write-Host "`n=== SOPMDE validation (read-only) ===" -ForegroundColor Cyan

# 1. ASR policy exists and is assigned to the pilot ring.
$asr = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '{0}'&`$expand=assignments" -f $AsrPolicyName)).value | Select-Object -First 1
Check 'ASR policy present' ([bool]$asr) ($(if ($asr) { "found id $($asr.id)" } else { "'$AsrPolicyName' not found (Implementation Step 2)" }))
if ($asr) {
    $assigned = $asr.assignments -and $asr.assignments.Count -gt 0
    Check 'ASR policy assigned' $assigned ($(if ($assigned) { "assigned ($($asr.assignments.Count) target[s]) — confirm it targets '$PilotGroupName'" } else { 'no assignment — assign to the pilot ring' }))

    # 2. Any ASR rule set to block?
    try {
        $settings = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/{0}/settings" -f $asr.id)).value
        $blockCount = ($settings | Where-Object { ($_ | ConvertTo-Json -Depth 8) -match '_block' }).Count
        Check 'ASR rules in Block' ($blockCount -gt 0) ("$blockCount rule setting(s) resolve to block")
    } catch { Check 'ASR rules in Block' $false ("could not read settings: " + $_.Exception.Message) }
}

# 3. Hardening policy present.
$hard = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '{0}'" -f $HardeningPolicyName)).value | Select-Object -First 1
Check 'Hardening policy present' ([bool]$hard) ($(if ($hard) { "found id $($hard.id)" } else { "'$HardeningPolicyName' not found (Implementation Step 5)" }))

# 4. Sensor-health coverage.
try {
    $m = Invoke-MgGraphRequest -Method GET -Uri 'https://api.securitycenter.microsoft.com/api/machines' -ErrorAction SilentlyContinue
    if ($m -and $m.value) {
        $total = $m.value.Count
        $active = ($m.value | Where-Object { $_.healthStatus -eq 'Active' }).Count
        $pct = if ($total) { [math]::Round(100.0 * $active / $total) } else { 0 }
        Check 'Sensor health coverage' ($pct -ge 90) ("$active/$total Active ($pct%) — target >=90%")
    } else { Check 'Sensor health coverage' $false 'machines API returned none here — verify via SOPMDE-Hunt.ps1 -Mode Coverage' }
} catch { Check 'Sensor health coverage' $false ("could not read machines: " + $_.Exception.Message) }

# 5. Portal-only reminders.
Write-Host "`n-- Confirm manually (portal-only toggles) --" -ForegroundColor Cyan
Write-Host "   Tamper Protection = On, EDR in block mode = On (Settings -> Endpoints -> Advanced features)"
Write-Host "   Web content filtering 'Web Filtering - All Devices - Prod' active (Settings -> Endpoints -> Web content filtering)"

Write-Host ""
if ($warn -eq 0) { Write-Host ("VERDICT: PASS — {0} checks passed. Safe to proceed per the Testing Guide exit gate." -f $pass) -ForegroundColor Green }
else { Write-Host ("VERDICT: {0} PASS / {1} WARN — resolve WARN items before expanding (Implementation Step 7)." -f $pass, $warn) -ForegroundColor Yellow }
