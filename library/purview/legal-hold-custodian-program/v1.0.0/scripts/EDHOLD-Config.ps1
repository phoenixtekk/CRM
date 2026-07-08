<#
.SYNOPSIS
    EDHOLD-Config.ps1 — eDiscovery legal-hold config helper: create/update a case hold, add a custodian, or enable Litigation Hold (-WhatIf by default; NEVER releases a hold).
.DESCRIPTION
    PURPOSE
        One safe-by-default helper for the write actions of the hold program:
          -Action NewCaseHold         : New-CaseHoldPolicy on an eDiscovery case, scoped to the given locations.
          -Action NewCaseHoldRule     : New-CaseHoldRule on a policy (empty ContentMatchQuery = preserve-everything;
                                        a KQL query = query-based, as authored by legal).
          -Action EnableLitigationHold: Set-Mailbox -LitigationHoldEnabled $true (belt-and-suspenders mailbox hold).
          -Action AddCustodian        : add a custodian via the Microsoft Graph eDiscovery API (Premium; beta —
                                        if unavailable in your tenant, add the custodian in the Purview portal).
          -Action RemoveCaseHold      : Remove a PILOT case hold policy/rule (test custodians only).
        Safe by default: with -WhatIf (the default when -Commit is absent) it only reports the intended change;
        it applies nothing unless -Commit is passed. It NEVER releases a hold on a real matter — hold release is a
        deliberate portal + release-authority sign-off action (Req 2.5). Use RemoveCaseHold only to tear down a
        PILOT hold on fabricated custodians.
    HOW TO RUN
        # Preview a pilot case hold policy:
        powershell -File .\EDHOLD-Config.ps1 -Action NewCaseHold `
            -CaseName 'Legal Hold Case – Contoso-Matter-001 – Pilot' `
            -HoldPolicyName 'Hold Policy – Contoso-Matter-001 – Pilot' `
            -ExchangeLocation 'testcustodian1@contoso.com' -WhatIf
        # Apply it (add -Commit). Then create a preserve-everything rule:
        powershell -File .\EDHOLD-Config.ps1 -Action NewCaseHoldRule `
            -HoldPolicyName 'Hold Policy – Contoso-Matter-001 – Pilot' `
            -HoldRuleName 'Hold Rule – Contoso-Matter-001 – Pilot' -ContentMatchQuery '' -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession); AddCustodian also needs Graph.
.EXAMPLE
    .\EDHOLD-Config.ps1 -Action NewCaseHold -CaseName 'Legal Hold Case – Contoso-Matter-001 – Pilot' -HoldPolicyName 'Hold Policy – Contoso-Matter-001 – Pilot' -ExchangeLocation 'testcustodian1@contoso.com' -WhatIf
    Prints the New-CaseHoldPolicy call it WOULD run. Re-run with -Commit to apply.
.NOTES
    Purview — Legal-Hold & Custodian Management Program. Writes gated behind -Commit; NEVER releases a real hold.
    Expected results: -Commit creates/updates the pilot hold; verify DistributionStatus=Success with EDHOLD-Validate.ps1 (PASS).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('NewCaseHold','NewCaseHoldRule','EnableLitigationHold','AddCustodian','RemoveCaseHold')]
    [string]$Action,

    [string]$CaseName,
    [string]$HoldPolicyName,
    [string]$HoldRuleName,
    [string[]]$ExchangeLocation,
    [string[]]$SharePointLocation,
    [string[]]$OneDriveLocation,
    [string]$ContentMatchQuery = '',           # '' = preserve everything; KQL = query-based (from legal)
    [int]$LitigationHoldDurationDays = 3650,
    [string]$CustodianEmail,                   # for -Action AddCustodian (Graph, Premium/beta)
    [string]$EdiscoveryCaseId,                 # Graph case id for -Action AddCustodian
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

$preview = -not $Commit
function Show-Would([string]$cmd) { Write-Host ("  WOULD RUN: {0}" -f $cmd) -ForegroundColor Yellow }

Write-Host ("=== EDHOLD-Config — Action: {0} ({1}) ===" -f $Action, ($(if ($preview) { 'WhatIf / preview' } else { 'COMMIT' }))) -ForegroundColor Cyan

switch ($Action) {

    'NewCaseHold' {
        if (-not $CaseName -or -not $HoldPolicyName) { throw 'NewCaseHold requires -CaseName and -HoldPolicyName.' }
        $locSplat = @{}
        if ($ExchangeLocation)   { $locSplat['ExchangeLocation']   = $ExchangeLocation }
        if ($SharePointLocation) { $locSplat['SharePointLocation'] = $SharePointLocation }
        if ($OneDriveLocation)   { $locSplat['OneDriveLocation']   = $OneDriveLocation }
        if ($locSplat.Count -eq 0) { throw 'Provide at least one location (-ExchangeLocation / -SharePointLocation / -OneDriveLocation).' }
        $desc = ($locSplat.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value -join ',')" }) -join ' '
        if ($preview) {
            Show-Would ("New-CaseHoldPolicy -Name '{0}' -Case '{1}' {2} -Enabled `$true" -f $HoldPolicyName, $CaseName, $desc)
            Write-Host 'Re-run with -Commit to create the case hold policy (a following NewCaseHoldRule places the hold).' -ForegroundColor Yellow
            return
        }
        New-CaseHoldPolicy -Name $HoldPolicyName -Case $CaseName @locSplat -Enabled $true -ErrorAction Stop | Out-Null
        Write-Host ("Created case hold policy '{0}' on case '{1}'." -f $HoldPolicyName, $CaseName) -ForegroundColor Green
        Write-Host 'Next: create the rule (EDHOLD-Config.ps1 -Action NewCaseHoldRule) — the hold is not active until a rule exists.' -ForegroundColor Cyan
    }

    'NewCaseHoldRule' {
        if (-not $HoldPolicyName -or -not $HoldRuleName) { throw 'NewCaseHoldRule requires -HoldPolicyName and -HoldRuleName.' }
        $kind = if ([string]::IsNullOrWhiteSpace($ContentMatchQuery)) { 'preserve-everything' } else { 'query-based' }
        Write-Host ("Rule kind: {0}" -f $kind)
        if ($preview) {
            if ([string]::IsNullOrWhiteSpace($ContentMatchQuery)) {
                Show-Would ("New-CaseHoldRule -Name '{0}' -Policy '{1}'   # no query = preserve everything" -f $HoldRuleName, $HoldPolicyName)
            } else {
                Show-Would ("New-CaseHoldRule -Name '{0}' -Policy '{1}' -ContentMatchQuery '{2}'" -f $HoldRuleName, $HoldPolicyName, $ContentMatchQuery)
            }
            Write-Host 'Re-run with -Commit to place the hold. The ContentMatchQuery is legal-authored (Req 2.4).' -ForegroundColor Yellow
            return
        }
        if ([string]::IsNullOrWhiteSpace($ContentMatchQuery)) {
            New-CaseHoldRule -Name $HoldRuleName -Policy $HoldPolicyName -ErrorAction Stop | Out-Null
        } else {
            New-CaseHoldRule -Name $HoldRuleName -Policy $HoldPolicyName -ContentMatchQuery $ContentMatchQuery -ErrorAction Stop | Out-Null
        }
        Write-Host ("Created rule '{0}' on policy '{1}' ({2}). Hold is now placing — validate distribution with EDHOLD-Validate.ps1." -f $HoldRuleName, $HoldPolicyName, $kind) -ForegroundColor Green
    }

    'EnableLitigationHold' {
        if (-not $ExchangeLocation -or $ExchangeLocation.Count -ne 1) { throw 'EnableLitigationHold requires exactly one -ExchangeLocation (a mailbox).' }
        $mbx = $ExchangeLocation[0]
        if ($preview) {
            Show-Would ("Set-Mailbox -Identity '{0}' -LitigationHoldEnabled `$true -LitigationHoldDuration {1}" -f $mbx, $LitigationHoldDurationDays)
            Write-Host 'Re-run with -Commit to enable the mailbox-level hold (reinforcement, not a replacement for the case hold).' -ForegroundColor Yellow
            return
        }
        # Set-Mailbox lives in Exchange Online PowerShell; ensure a session (Connect-ExchangeOnline) is present.
        if (-not (Get-Command Set-Mailbox -ErrorAction SilentlyContinue)) { Connect-ExchangeOnline -ShowBanner:$false }
        Set-Mailbox -Identity $mbx -LitigationHoldEnabled $true -LitigationHoldDuration $LitigationHoldDurationDays -ErrorAction Stop
        Write-Host ("Enabled Litigation Hold on '{0}' for {1} days." -f $mbx, $LitigationHoldDurationDays) -ForegroundColor Green
    }

    'AddCustodian' {
        # Custodian management is eDiscovery Premium; exposed via the Microsoft Graph eDiscovery API (beta).
        if (-not $CustodianEmail -or -not $EdiscoveryCaseId) { throw 'AddCustodian requires -CustodianEmail and -EdiscoveryCaseId (Graph eDiscovery case id).' }
        if (-not (Get-Command New-MgSecurityCaseEdiscoveryCaseCustodian -ErrorAction SilentlyContinue)) {
            Write-Host 'Graph eDiscovery custodian cmdlets not available (install Microsoft.Graph.Security; endpoints are BETA).' -ForegroundColor Yellow
            Write-Host 'PORTAL FALLBACK: add the custodian in Purview → eDiscovery (Premium) → the case → Data sources / Custodians (verify tab name in your tenant).' -ForegroundColor Yellow
            return
        }
        if ($preview) {
            Show-Would ("New-MgSecurityCaseEdiscoveryCaseCustodian -EdiscoveryCaseId '{0}' -Email '{1}'   (Graph, Premium/beta)" -f $EdiscoveryCaseId, $CustodianEmail)
            Write-Host 'Re-run with -Commit to add the custodian, or add it in the portal. Placing on hold maps + holds their data sources.' -ForegroundColor Yellow
            return
        }
        New-MgSecurityCaseEdiscoveryCaseCustodian -EdiscoveryCaseId $EdiscoveryCaseId -BodyParameter @{ email = $CustodianEmail } -ErrorAction Stop | Out-Null
        Write-Host ("Added custodian '{0}' to Graph eDiscovery case '{1}'. Place on hold + issue the notice in the portal." -f $CustodianEmail, $EdiscoveryCaseId) -ForegroundColor Green
    }

    'RemoveCaseHold' {
        # PILOT teardown only. This removes a hold's PRESERVATION — use only on fabricated test custodians.
        if (-not $HoldPolicyName) { throw 'RemoveCaseHold requires -HoldPolicyName (a PILOT policy on test custodians).' }
        Write-Host 'SAFETY: RemoveCaseHold deletes preservation. Only ever run this on a PILOT hold with fabricated custodians.' -ForegroundColor Red
        Write-Host '        Releasing a REAL-matter hold is a portal + release-authority sign-off action (Req 2.5) — not this script.' -ForegroundColor Red
        if ($preview) {
            if ($HoldRuleName) { Show-Would ("Remove-CaseHoldRule -Identity '{0}'" -f $HoldRuleName) }
            Show-Would ("Remove-CaseHoldPolicy -Identity '{0}'" -f $HoldPolicyName)
            Write-Host 'Re-run with -Commit ONLY for a pilot teardown.' -ForegroundColor Yellow
            return
        }
        if ($HoldRuleName -and (Get-CaseHoldRule -Identity $HoldRuleName -ErrorAction SilentlyContinue)) {
            Remove-CaseHoldRule -Identity $HoldRuleName -Confirm:$false -ErrorAction Stop
            Write-Host ("Removed pilot rule '{0}'." -f $HoldRuleName) -ForegroundColor Green
        }
        Remove-CaseHoldPolicy -Identity $HoldPolicyName -Confirm:$false -ErrorAction Stop
        Write-Host ("Removed pilot hold policy '{0}'." -f $HoldPolicyName) -ForegroundColor Green
    }
}
