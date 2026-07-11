<#
.SYNOPSIS
    POCMDE-Enable.ps1 — pilot-scoped enable of Microsoft Defender for Endpoint for a proof of concept. -WhatIf-gated.
.DESCRIPTION
    PURPOSE
        Stands up the MDE proof of concept on a small pilot ring ONLY. It previews readiness
        (licensed plan, admin roles, MDE activation state, onboarding channel, pilot group
        membership) and then assigns the Intune EDR onboarding policy to the pilot device
        group. Every change is gated behind -WhatIf: run with -WhatIf first to preview, then
        without -WhatIf to apply. Touches test devices only; nothing production is changed.
    HOW TO RUN
        # Preview only (changes nothing):
        powershell -ExecutionPolicy Bypass -File .\POCMDE-Enable.ps1 -WhatIf
        # Apply to the pilot ring:
        powershell -ExecutionPolicy Bypass -File .\POCMDE-Enable.ps1 -PilotGroup "MDE PoC - Pilot Ring - Pilot"
        Requires Microsoft.Graph.Authentication and consent to read directory + manage the
        pilot Intune policy (DeviceManagementConfiguration.ReadWrite.All).
    EXPECTED RESULTS
        A readiness summary, then (when applied) the Intune EDR policy assigned to the pilot
        group so the test devices begin onboarding to MDE.
.NOTES
    White-label. Read-only by default (-WhatIf). Pilot-scoped. Reverse with POCMDE-Teardown.ps1.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PilotGroup = 'MDE PoC - Pilot Ring - Pilot',
    [string]$EdrPolicyName = 'MDE PoC EDR Onboarding - Pilot Ring - Pilot'
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'Directory.Read.All','DeviceManagementConfiguration.ReadWrite.All','DeviceManagementManagedDevices.Read.All' -NoWelcome | Out-Null
}

function Get-Json($Uri) { try { return Invoke-MgGraphRequest -Method GET -Uri $Uri } catch { return $null } }

Write-Host "`n=== POCMDE — pilot enable (preview by default) ===" -ForegroundColor Cyan
Write-Host "Pilot group : $PilotGroup" -ForegroundColor Gray
Write-Host "EDR policy  : $EdrPolicyName" -ForegroundColor Gray

# --- Readiness (read-only) ---
Write-Host "`n[1] Readiness checks (read-only):" -ForegroundColor Cyan
$grp = Get-Json "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$PilotGroup'"
if ($grp -and $grp.value.Count -gt 0) {
    $gid = $grp.value[0].id
    $members = Get-Json "https://graph.microsoft.com/v1.0/groups/$gid/members?`$select=displayName"
    Write-Host ("  Pilot group found ({0} member[s]). Ensure these are TEST devices only." -f ($members.value.Count)) -ForegroundColor Green
} else {
    Write-Host "  Pilot group NOT found — create '$PilotGroup' with 1-3 test devices first." -ForegroundColor Yellow
    $gid = $null
}

$me = Get-Json "https://graph.microsoft.com/v1.0/me?`$select=displayName,userPrincipalName"
if ($me) { Write-Host ("  Signed in as: {0}" -f $me.userPrincipalName) -ForegroundColor Gray }
Write-Host "  Verify: Defender for Endpoint plan (P1/P2) licensed and MDE activated in security.microsoft.com -> Settings -> Endpoints." -ForegroundColor Gray
Write-Host "  Verify: security.microsoft.com -> Settings -> Endpoints -> Advanced features -> Automated Investigation = ON, pilot automation level = 'Semi - require approval'." -ForegroundColor Gray

# --- Apply (gated) ---
Write-Host "`n[2] Assign EDR onboarding policy to the pilot ring:" -ForegroundColor Cyan
if (-not $gid) { Write-Host "  Skipping assignment — pilot group missing." -ForegroundColor Yellow; return }

$policy = Get-Json "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '$EdrPolicyName'"
if (-not ($policy -and $policy.value.Count -gt 0)) {
    Write-Host "  EDR policy '$EdrPolicyName' not found." -ForegroundColor Yellow
    Write-Host "  Create it in Intune -> Endpoint security -> Endpoint detection and response (client config = Auto from connector)," -ForegroundColor Gray
    Write-Host "  name it exactly '$EdrPolicyName', then re-run to assign it to the pilot group." -ForegroundColor Gray
    return
}
$pid = $policy.value[0].id

if ($PSCmdlet.ShouldProcess("$EdrPolicyName -> $PilotGroup", "Assign Intune EDR onboarding policy to pilot ring")) {
    $body = @{ assignments = @(@{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $gid } }) } | ConvertTo-Json -Depth 6
    try {
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$pid/assign" -Body $body -ContentType 'application/json' | Out-Null
        Write-Host "  ASSIGNED — pilot devices will begin onboarding. Confirm in Assets -> Devices." -ForegroundColor Green
    } catch {
        Write-Host ("  Assignment failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WhatIf] Would assign '$EdrPolicyName' to '$PilotGroup'. No change made." -ForegroundColor Yellow
}

Write-Host "`nNext: POCMDE-TestSignal.ps1 (benign signal) -> POCMDE-Validate.ps1 -> POCMDE-Scorecard.ps1 -> POCMDE-Teardown.ps1" -ForegroundColor Cyan
