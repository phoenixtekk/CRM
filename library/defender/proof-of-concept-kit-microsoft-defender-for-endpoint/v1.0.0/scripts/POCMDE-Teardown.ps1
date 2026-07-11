<#
.SYNOPSIS
    POCMDE-Teardown.ps1 — clean rollback of the MDE proof of concept. -WhatIf-gated.
.DESCRIPTION
    PURPOSE
        Removes everything the PoC created so the tenant returns to its pre-PoC state. It:
          - removes the Intune EDR onboarding policy assignment from the pilot ring (and optionally
            deletes the policy),
          - prints the exact offboarding path for the pilot devices,
          - deletes the benign EICAR test file from the local machine,
          - reminds you to resolve the MDE-PoC-TESTSIGNAL test alerts.
        Every change is gated behind -WhatIf: run with -WhatIf first to preview, then without to apply.
    HOW TO RUN
        # Preview:
        powershell -ExecutionPolicy Bypass -File .\POCMDE-Teardown.ps1 -WhatIf
        # Apply:
        powershell -ExecutionPolicy Bypass -File .\POCMDE-Teardown.ps1 -DeletePolicy
        Requires Microsoft.Graph.Authentication and DeviceManagementConfiguration.ReadWrite.All.
    EXPECTED RESULTS
        The pilot EDR policy assignment removed, the EICAR file deleted, and printed steps to
        offboard the pilot devices and resolve the test alerts.
.NOTES
    White-label. Reversible teardown. Offboarding devices is asynchronous — allow time to reflect.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PilotGroup = 'MDE PoC - Pilot Ring - Pilot',
    [string]$EdrPolicyName = 'MDE PoC EDR Onboarding - Pilot Ring - Pilot',
    [switch]$DeletePolicy,
    [string]$WorkDir = "$env:TEMP\MDE-PoC"
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' -NoWelcome | Out-Null }
function Get-Json($Uri) { try { return Invoke-MgGraphRequest -Method GET -Uri $Uri } catch { return $null } }

Write-Host "`n=== POCMDE — teardown (preview by default) ===" -ForegroundColor Cyan

# 1) Remove EDR policy assignment (and optionally the policy).
$policy = Get-Json "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '$EdrPolicyName'"
if ($policy -and $policy.value.Count -gt 0) {
    $pid = $policy.value[0].id
    if ($PSCmdlet.ShouldProcess($EdrPolicyName, "Clear pilot assignment")) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$pid/assign" -Body (@{ assignments = @() } | ConvertTo-Json) -ContentType 'application/json' | Out-Null
            Write-Host "  Cleared assignment on '$EdrPolicyName'." -ForegroundColor Green
        } catch { Write-Host ("  Could not clear assignment: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    } else { Write-Host "  [WhatIf] Would clear assignment on '$EdrPolicyName'." -ForegroundColor Yellow }

    if ($DeletePolicy) {
        if ($PSCmdlet.ShouldProcess($EdrPolicyName, "Delete Intune EDR policy")) {
            try { Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$pid" | Out-Null; Write-Host "  Deleted policy '$EdrPolicyName'." -ForegroundColor Green }
            catch { Write-Host ("  Could not delete policy: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
        } else { Write-Host "  [WhatIf] Would delete policy '$EdrPolicyName'." -ForegroundColor Yellow }
    }
} else {
    Write-Host "  EDR policy '$EdrPolicyName' not found (already removed?)." -ForegroundColor Gray
}

# 2) Delete the benign EICAR file locally.
$eicarPath = Join-Path $WorkDir 'eicar-poc.com'
if (Test-Path $eicarPath) {
    if ($PSCmdlet.ShouldProcess($eicarPath, "Delete benign EICAR test file")) {
        Remove-Item $eicarPath -Force -ErrorAction SilentlyContinue
        Write-Host "  Deleted EICAR test file (if AV had not already quarantined it)." -ForegroundColor Green
    } else { Write-Host "  [WhatIf] Would delete $eicarPath." -ForegroundColor Yellow }
} else { Write-Host "  No local EICAR file to delete (likely quarantined by AV — expected)." -ForegroundColor Gray }

# 3) Manual, portal-side offboarding + alert cleanup.
Write-Host "`n[Finish in the portal]" -ForegroundColor Cyan
Write-Host "  Offboard pilot devices : security.microsoft.com -> Settings -> Endpoints -> Offboarding (or the Intune offboarding policy)." -ForegroundColor Gray
Write-Host "  Resolve test alerts    : Incidents & alerts -> filter 'MDE-PoC-TESTSIGNAL' -> Resolve as 'Not a threat / test'." -ForegroundColor Gray
Write-Host "  (Optional) delete group '$PilotGroup' once devices are offboarded." -ForegroundColor Gray
Write-Host "`nConfirm with: POCMDE-Validate.ps1  (should report nothing left onboarded)." -ForegroundColor Cyan
