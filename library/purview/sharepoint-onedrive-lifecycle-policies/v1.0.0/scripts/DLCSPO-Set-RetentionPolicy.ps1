<#
.SYNOPSIS
    DLCSPO-Set-RetentionPolicy.ps1 — Create the SharePoint/OneDrive retention policy RETAIN-ONLY, and (as a
    separate deliberate action) enable retain-then-delete (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Automates the retention-policy lifecycle SAFELY. -Action CreatePolicy creates
        'SPO-OneDrive Retention - Policy' + a RETAIN-ONLY rule scoped to the pilot sites (deletes nothing).
        -Action EnableDelete switches the rule to RETAIN-THEN-DELETE — a DELIBERATE, SEPARATE step run only
        after retain-only is validated and approved. DEFAULTS TO -WhatIf: prints exactly what it would do
        plus the reverse action and changes nothing; applies only with -Commit. No credentials/secrets.
    HOW TO RUN
        .\DLCSPO-Set-RetentionPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -RetainDays 2555 -WhatIf
        .\DLCSPO-Set-RetentionPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -RetainDays 2555 -Commit
        .\DLCSPO-Set-RetentionPolicy.ps1 -Action EnableDelete -RetainDays 2555 -WhatIf
        .\DLCSPO-Set-RetentionPolicy.ps1 -Action EnableDelete -RetainDays 2555 -Commit
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession (modern-auth/MFA admin).
    EXPECTED RESULTS
        -WhatIf: the plan + reverse command, no change. CreatePolicy -Commit: policy + retain-only rule
        exist (verify with Get-RetentionCompliancePolicy / ...Rule). EnableDelete -Commit: the rule is
        retain-then-delete (content deleted only AFTER the period).
.NOTES
    Purview — SharePoint & OneDrive Lifecycle Policies. Safe-by-default; deletion behind its own action.
    Verify your licensing/tenant. Deletion after the window is irreversible — enable only after approval.
#>
[CmdletBinding()]
param(
    [ValidateSet('CreatePolicy','EnableDelete')]
    [string]$Action = 'CreatePolicy',
    [string]$PolicyName = 'SPO-OneDrive Retention - Policy',
    [string]$RuleName   = 'SPO-OneDrive - Retention Rule',
    [string[]]$PilotSites = @(),                         # SharePoint site URLs for the pilot scope
    [switch]$IncludeAllOneDrive,                         # include OneDrive location (All) where designed
    [int]$RetainDays = 2555,                             # ~7 years; set per the schedule
    [switch]$WhatIf,
    [switch]$Commit
)

if (-not $Commit) { $WhatIf = $true }
if ($WhatIf -and $Commit) { Write-Host "Specify either -WhatIf or -Commit, not both." -ForegroundColor Yellow; return }

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
if (-not (Test-Command 'Get-RetentionCompliancePolicy')) {
    Write-Host "Security & Compliance PowerShell not connected. Run Connect-IPPSSession first." -ForegroundColor Yellow; return
}

$mode = $(if ($Commit) { 'COMMIT' } else { 'WHATIF (no changes)' })
Write-Host "`n=== Retention policy — Action: $Action — Mode: $mode ===" -ForegroundColor Cyan

if ($Action -eq 'CreatePolicy') {
    if ($PilotSites.Count -eq 0 -and -not $IncludeAllOneDrive) {
        Write-Host "Provide -PilotSites (SharePoint URLs) and/or -IncludeAllOneDrive to scope the pilot." -ForegroundColor Yellow; return
    }
    $existing = Get-RetentionCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($WhatIf) {
        if ($existing) { Write-Host ("  WOULD reuse existing policy '{0}' and ensure a RETAIN-ONLY rule ({1} days)." -f $PolicyName, $RetainDays) -ForegroundColor Yellow }
        else           { Write-Host ("  WOULD create policy '{0}' scoped to [{1}]{2}" -f $PolicyName, ($PilotSites -join ', '), $(if($IncludeAllOneDrive){' + OneDrive(All)'}else{''})) -ForegroundColor Yellow }
        Write-Host ("  WOULD create RETAIN-ONLY rule '{0}': retain {1} days, NO deletion." -f $RuleName, $RetainDays) -ForegroundColor Yellow
        Write-Host ("        reverse: Remove-RetentionCompliancePolicy -Identity '{0}'" -f $PolicyName) -ForegroundColor DarkGray
        Write-Host "  NOTE: retain-only deletes nothing. Deletion is a separate deliberate step: -Action EnableDelete." -ForegroundColor DarkGray
        return
    }
    try {
        if (-not $existing) {
            $splat = @{ Name = $PolicyName }
            if ($PilotSites.Count -gt 0) { $splat['SharePointLocation'] = $PilotSites }
            if ($IncludeAllOneDrive)     { $splat['OneDriveLocation']  = 'All' }
            New-RetentionCompliancePolicy @splat -ErrorAction Stop | Out-Null
            Write-Host ("  CREATED policy '{0}'." -f $PolicyName) -ForegroundColor Green
        } else {
            Write-Host ("  Reusing existing policy '{0}'." -f $PolicyName) -ForegroundColor DarkGray
        }
        # RETAIN-ONLY rule: retain for the period; do NOT delete afterward.
        $rule = Get-RetentionComplianceRule -Policy $PolicyName -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RuleName }
        if (-not $rule) {
            New-RetentionComplianceRule -Name $RuleName -Policy $PolicyName `
                -RetentionDuration $RetainDays -RetentionComplianceAction Keep -ErrorAction Stop | Out-Null
            Write-Host ("  CREATED RETAIN-ONLY rule '{0}' ({1} days, no deletion)." -f $RuleName, $RetainDays) -ForegroundColor Green
        } else {
            Set-RetentionComplianceRule -Identity $RuleName -RetentionComplianceAction Keep -ErrorAction Stop | Out-Null
            Write-Host ("  Ensured rule '{0}' is RETAIN-ONLY." -f $RuleName) -ForegroundColor Green
        }
        Write-Host "  Verify scope in the portal (Data Lifecycle Management). Pilot in retain-only before enabling deletion." -ForegroundColor DarkGray
    } catch {
        Write-Host ("  ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host "  Verify parameter names/actions for your ExchangeOnlineManagement version." -ForegroundColor Yellow
    }
    return
}

if ($Action -eq 'EnableDelete') {
    if ($WhatIf) {
        Write-Host ("  WOULD switch rule '{0}' to RETAIN-THEN-DELETE: retain {1} days, then delete." -f $RuleName, $RetainDays) -ForegroundColor Yellow
        Write-Host ("        reverse: Set-RetentionComplianceRule -Identity '{0}' -RetentionComplianceAction Keep" -f $RuleName) -ForegroundColor DarkGray
        Write-Host "  WARNING: deletion after the period is IRREVERSIBLE. Only enable after validation + approval." -ForegroundColor Red
        return
    }
    try {
        Set-RetentionComplianceRule -Identity $RuleName -RetentionDuration $RetainDays -RetentionComplianceAction KeepAndDelete -ErrorAction Stop | Out-Null
        Write-Host ("  ENABLED retain-then-delete on rule '{0}' ({1} days, then delete)." -f $RuleName, $RetainDays) -ForegroundColor Green
        Write-Host "  Communicate the change to site owners; content is deleted only AFTER the period elapses." -ForegroundColor DarkGray
    } catch {
        Write-Host ("  ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host "  Verify the retain-then-delete action name for your module version." -ForegroundColor Yellow
    }
}
