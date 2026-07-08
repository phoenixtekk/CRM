<#
.SYNOPSIS
    EDHOLD-Set-Scope.ps1 — hold scope/health helper: report a hold's locations/custodians and (with -Commit) ADD/adjust locations; NEVER releases a hold (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Reports a case hold policy's current locations, distribution status, and rule scope, and — only with
        -Commit — ADDS Exchange / OneDrive / SharePoint locations to the hold (Set-CaseHoldPolicy -Add*),
        so a hold can be widened as a custodian's role or data sources change. Safe by default: -WhatIf reports
        only; writes require -Commit. This helper only ADDS/adjusts coverage — it does NOT remove a location and
        NEVER releases a hold. Removing a location or releasing a hold reduces preservation and is a deliberate
        portal + release-authority sign-off action (Req 2.5); it is intentionally not automated here.
    HOW TO RUN
        # Report current scope/health:
        powershell -File .\EDHOLD-Set-Scope.ps1 -HoldPolicyName 'Hold Policy – Contoso-Matter-001 – Pilot' -WhatIf
        # Add a newly-relevant test custodian mailbox to the hold (widen coverage — still same hold):
        powershell -File .\EDHOLD-Set-Scope.ps1 -HoldPolicyName 'Hold Policy – Contoso-Matter-001 – Pilot' `
            -AddExchangeLocation 'testcustodian2@contoso.com' -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
.EXAMPLE
    .\EDHOLD-Set-Scope.ps1 -HoldPolicyName 'Hold Policy – Contoso-Matter-001 – Pilot' -WhatIf
    Prints the hold's locations/status and the Set-CaseHoldPolicy -Add* call it WOULD run.
.NOTES
    Purview — Legal-Hold & Custodian Management Program. Additive scope changes gated behind -Commit; never
    removes a location, never releases a hold. Expected results: -Commit ADDS the location; re-validate
    DistributionStatus=Success with EDHOLD-Validate.ps1 (PASS = wider hold, still distributing to Success).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$HoldPolicyName,
    [string[]]$AddExchangeLocation,
    [string[]]$AddOneDriveLocation,
    [string[]]$AddSharePointLocation,
    [string]$UserPrincipalName,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-CaseHoldPolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$p = Get-CaseHoldPolicy -Identity $HoldPolicyName -DistributionDetail -ErrorAction Stop
Write-Host ("=== Scope/health for hold '{0}' ===" -f $p.Name) -ForegroundColor Cyan
Write-Host ("  Enabled={0}  DistributionStatus={1}" -f $p.Enabled, $p.DistributionStatus)
if ($p.DistributionStatus -and $p.DistributionStatus -ne 'Success') {
    Write-Host ("  HEALTH: distribution is '{0}' — not fully propagated yet; re-validate before trusting." -f $p.DistributionStatus) -ForegroundColor Yellow
} else {
    Write-Host '  HEALTH: DistributionStatus=Success.' -ForegroundColor Green
}
foreach ($loc in 'ExchangeLocation','OneDriveLocation','SharePointLocation') {
    $val = $p.$loc
    if ($val -and $val.Count -gt 0) { Write-Host ("  {0} ({1}): {2}" -f $loc, $val.Count, ($val -join ', ')) -ForegroundColor DarkCyan }
}

# Build the additive splat (Set-CaseHoldPolicy uses -Add<Location> to widen coverage).
$addSplat = @{}
if ($AddExchangeLocation)   { $addSplat['AddExchangeLocation']   = $AddExchangeLocation }
if ($AddOneDriveLocation)   { $addSplat['AddOneDriveLocation']   = $AddOneDriveLocation }
if ($AddSharePointLocation) { $addSplat['AddSharePointLocation'] = $AddSharePointLocation }

if ($addSplat.Count -eq 0) {
    Write-Host 'No -Add*Location supplied — reporting only. Supply locations (and -Commit) to WIDEN the hold.' -ForegroundColor Yellow
    Write-Host 'Note: this helper never REMOVES a location or releases a hold — that reduces preservation (portal + sign-off, Req 2.5).' -ForegroundColor DarkGray
    return
}

$desc = ($addSplat.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value -join ',')" }) -join ' '
if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    Write-Host ("Set-CaseHoldPolicy -Identity '{0}' {1}" -f $HoldPolicyName, $desc) -ForegroundColor Yellow
    Write-Host 'Re-run with -Commit to ADD the location(s). Removing/releasing is never done here.' -ForegroundColor Yellow
    return
}

Set-CaseHoldPolicy -Identity $HoldPolicyName @addSplat -ErrorAction Stop
Write-Host ("Widened hold '{0}' ({1})." -f $HoldPolicyName, $desc) -ForegroundColor Green
$after = Get-CaseHoldPolicy -Identity $HoldPolicyName -DistributionDetail
Write-Host ("Re-validate distribution (now redistributing): DistributionStatus={0}. Run EDHOLD-Validate.ps1." -f $after.DistributionStatus) -ForegroundColor Cyan
