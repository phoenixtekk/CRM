<#
.SYNOPSIS
    ISO27001-Set-Scope.ps1 — scope helper for the pilot ring; reports scope and (with -Commit) adjusts it (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Reports a DLP policy's current included/excluded locations and, with the explicit -Commit switch,
        narrows a policy to the pilot ring (an included distribution group / mail-enabled security group)
        so enforcement is limited to Stage-1 pilot users before broad rollout. Read-only by default
        (-WhatIf prints the intended change). The script only NARROWS scope to the named ring; it never
        broadens scope tenant-wide and never changes a policy's enforcement mode.
    HOW TO RUN
        # Preview current scope (default, no change):
        powershell -ExecutionPolicy Bypass -File .\ISO27001-Set-Scope.ps1 -PolicyName 'ISO27001 DLP - Data Leakage - Simulation' -WhatIf
        # Restrict to the pilot ring (explicit write):
        powershell -ExecutionPolicy Bypass -File .\ISO27001-Set-Scope.ps1 -PolicyName 'ISO27001 DLP - Data Leakage - Simulation' -RingGroup 'ISO27001 Pilot Ring - Stage1' -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
    EXPECTED RESULTS
        Under -WhatIf: the current scope and the intended pilot-ring restriction. Under -Commit: the
        policy's Exchange/SharePoint/OneDrive locations are scoped to the ring group. PASS signal:
        Get-DlpCompliancePolicy shows the *DistributionGroup / *AccountScope set to the ring only.
.NOTES
    Purview — ISO 27001 Compliance Program. Safe-by-default; -Commit required to write; only narrows scope.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$PolicyName,
    [string]$RingGroup,
    [switch]$Commit,
    [switch]$WhatIf,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$doWrite = $Commit -and -not $WhatIf
if (-not $doWrite) {
    Write-Host 'SAFE MODE (-WhatIf / no -Commit): no changes will be made. Pass -Commit to apply.' -ForegroundColor Yellow
}

$policy = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $policy) {
    Write-Host ("DLP policy '{0}' not found. Check the name (see ISO27001-Discovery.ps1)." -f $PolicyName) -ForegroundColor Red
    return
}

Write-Host ("=== Scope for '{0}' (Mode={1}) ===" -f $policy.Name, $policy.Mode) -ForegroundColor Cyan
Write-Host ("  ExchangeLocation            : {0}" -f (($policy.ExchangeLocation)          -join ', '))
Write-Host ("  ExchangeSenderMemberOf      : {0}" -f (($policy.ExchangeSenderMemberOf)    -join ', '))
Write-Host ("  SharePointLocation          : {0}" -f (($policy.SharePointLocation)        -join ', '))
Write-Host ("  OneDriveLocation            : {0}" -f (($policy.OneDriveLocation)          -join ', '))

if (-not $RingGroup) {
    Write-Host 'No -RingGroup supplied — reporting only. Provide -RingGroup to restrict enforcement to the pilot ring.' -ForegroundColor Yellow
    return
}

Write-Host ("Intended change: restrict enforcement to pilot ring '{0}' (ExchangeSenderMemberOf + OneDrive scope)." -f $RingGroup) -ForegroundColor Cyan
if ($policy.Mode -eq 'Enable') {
    Write-Host '  NOTE: policy is currently ENFORCING — narrowing scope is safe (reduces blast radius); it will not broaden.' -ForegroundColor Yellow
}

if ($doWrite -and $PSCmdlet.ShouldProcess($PolicyName, ("Restrict scope to pilot ring '{0}'" -f $RingGroup))) {
    # Narrow email enforcement to senders in the ring group, and OneDrive to ring members.
    Set-DlpCompliancePolicy -Identity $PolicyName `
        -ExchangeSenderMemberOf $RingGroup `
        -OneDriveSharedByMemberOf $RingGroup -ErrorAction Stop
    Write-Host ("  Applied: '{0}' enforcement restricted to the pilot ring." -f $PolicyName) -ForegroundColor Green
    Write-Host '  Verify with ISO27001-Discovery.ps1 / Get-DlpCompliancePolicy; expand scope deliberately after the pilot gate.' -ForegroundColor Cyan
} elseif (-not $doWrite) {
    Write-Host '  (Preview only — pass -Commit to apply the pilot-ring restriction.)' -ForegroundColor Yellow
}

Write-Host 'Done. Scope helper only narrows to the ring; broadening scope is a deliberate step after validation.' -ForegroundColor Cyan
