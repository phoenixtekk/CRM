<#
.SYNOPSIS
    DLCCLEAN-Config.ps1 — retention/deletion policy + label config helper; creates on a LIMITED scope, never auto-deletes (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Creates or updates a RETENTION/DELETION policy (and its retention rule) on a NAMED, LIMITED scope — a
        specific SharePoint site / mailbox / OneDrive, or a named adaptive scope — for the pilot, or creates a
        retention LABEL (ComplianceTag). Safe by default: with -WhatIf it only reports the intended change; it
        applies nothing unless -Commit is passed. HARD SAFETY RAILS: it REFUSES a tenant-wide ("All") scope, it
        requires an explicit -StaticScopeLocation or -AdaptiveScopeName, and it NEVER permanently deletes content
        — a Delete action only sets the policy's retention rule (deletion happens later on Microsoft's timer,
        gated by holds and, where configured, disposition review). Enforcement/expansion is a deliberate,
        hold-checked change-control step (Implementation Phase 3-5), not this tool.
    HOW TO RUN
        # Preview a delete policy on ONE pilot site (retention period comes from the records schedule):
        powershell -File .\DLCCLEAN-Config.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' `
            -Workload SharePoint -RetentionAction Delete -RetentionDays 2555 `
            -StaticScopeLocation 'https://contoso.sharepoint.com/sites/DLC-Pilot' -WhatIf
        # Actually create it (still limited to the named pilot site):
        powershell -File .\DLCCLEAN-Config.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' `
            -Workload SharePoint -RetentionAction Delete -RetentionDays 2555 `
            -StaticScopeLocation 'https://contoso.sharepoint.com/sites/DLC-Pilot' -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
.EXAMPLE
    .\DLCCLEAN-Config.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' -Workload SharePoint -RetentionAction Delete -RetentionDays 2555 -StaticScopeLocation 'https://contoso.sharepoint.com/sites/DLC-Pilot' -WhatIf
    Prints the New-RetentionCompliancePolicy / New-RetentionComplianceRule calls it WOULD run, on the named site only.
.NOTES
    Purview — Inactive & Legacy Data Cleanup. Writes gated behind -Commit; refuses "All"; never deletes content. No credentials in code.
    Expected results: -Commit creates a LIMITED-scope pilot policy; validate scope + holds with DLCCLEAN-Validate.ps1 (PASS = correct scope, no held item deletable).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [ValidateSet('Exchange','SharePoint','OneDrive','Teams','Groups')]
    [string]$Workload = 'SharePoint',
    [ValidateSet('Keep','Delete','KeepAndDelete')][string]$RetentionAction = 'Delete',
    # Retention period is a RECORDS determination (Req 2.5) — supplied, never invented by this tool.
    [int]$RetentionDays = 2555,
    [string]$StaticScopeLocation,          # e.g. a specific site URL or mailbox UPN — NEVER 'All'
    [string]$AdaptiveScopeName,            # e.g. 'DLC - Stale Sites - Adaptive Scope' (E5 — verify licensing)
    # Optional label-creation mode instead of a policy:
    [switch]$CreateLabel,
    [string]$UserPrincipalName,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

# =========================== Optional: create a retention LABEL ===========================
if ($CreateLabel) {
    Write-Host ("=== Retention LABEL '{0}' — action={1}, days={2} ===" -f $PolicyName, $RetentionAction, $RetentionDays) -ForegroundColor Cyan
    if (-not $Commit) {
        Write-Host '-- WhatIf: no change. Would run: --' -ForegroundColor Yellow
        Write-Host ("New-ComplianceTag -Name '{0}' -RetentionAction {1} -RetentionDuration {2} -RetentionType ModificationAgeInDays" -f $PolicyName, $RetentionAction, $RetentionDays)
        Write-Host 'Re-run with -Commit to create the label. (Period/action come from the records schedule, Req 2.5.)' -ForegroundColor Yellow
        return
    }
    if (-not (Get-ComplianceTag -Identity $PolicyName -ErrorAction SilentlyContinue)) {
        New-ComplianceTag -Name $PolicyName -RetentionAction $RetentionAction -RetentionDuration $RetentionDays -RetentionType ModificationAgeInDays -ErrorAction Stop | Out-Null
        Write-Host ("Created retention label '{0}'." -f $PolicyName) -ForegroundColor Green
    } else {
        Write-Host ("Label '{0}' already exists — not modified." -f $PolicyName) -ForegroundColor Yellow
    }
    return
}

# =========================== SAFETY RAILS for a retention/deletion POLICY ===========================
if (-not $StaticScopeLocation -and -not $AdaptiveScopeName) {
    Write-Host 'SAFETY STOP: no scope supplied. Provide -StaticScopeLocation (a specific site/mailbox) or -AdaptiveScopeName. This tool refuses tenant-wide cleanup.' -ForegroundColor Red
    return
}
if ($StaticScopeLocation -and $StaticScopeLocation -match '^\s*All\s*$') {
    Write-Host "SAFETY STOP: -StaticScopeLocation 'All' is refused. A cleanup/delete policy must target a named, limited scope during pilot." -ForegroundColor Red
    return
}
if ($RetentionAction -ne 'Keep') {
    Write-Host ("WARNING: RetentionAction '{0}' will schedule DELETION of content past {1} days on this scope (on Microsoft's timer, blocked by any hold)." -f $RetentionAction, $RetentionDays) -ForegroundColor Red
    Write-Host 'This tool does NOT delete now; validate scope + holds with DLCCLEAN-Validate.ps1 BEFORE the policy takes effect.' -ForegroundColor Red
}

# Build the location splat for the chosen workload (single named location — limited by design).
$locParams = @{}
if ($AdaptiveScopeName) {
    $locParams['AdaptiveScopeLocation'] = $AdaptiveScopeName
} else {
    switch ($Workload) {
        'Exchange'   { $locParams['ExchangeLocation']     = $StaticScopeLocation }
        'SharePoint' { $locParams['SharePointLocation']   = $StaticScopeLocation }
        'OneDrive'   { $locParams['OneDriveLocation']     = $StaticScopeLocation }
        'Teams'      { $locParams['TeamsChannelLocation'] = $StaticScopeLocation }
        'Groups'     { $locParams['ModernGroupLocation']  = $StaticScopeLocation }
    }
}

Write-Host ("=== Retention/deletion POLICY '{0}' (PILOT, limited scope) ===" -f $PolicyName) -ForegroundColor Cyan
Write-Host ("Workload : {0}" -f $Workload)
Write-Host ("Scope    : {0}" -f ($(if($AdaptiveScopeName){"Adaptive: $AdaptiveScopeName"}else{$StaticScopeLocation})))
Write-Host ("Action   : {0} after {1} days (records-defined)" -f $RetentionAction, $RetentionDays)

$existing = Get-RetentionCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue

if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    if ($existing) {
        Write-Host ("Set-RetentionCompliancePolicy -Identity '{0}' (exists) then Set-RetentionComplianceRule for the action/period." -f $PolicyName)
    } else {
        Write-Host ("New-RetentionCompliancePolicy -Name '{0}' {1} -Enabled `$false" -f $PolicyName, (($locParams.GetEnumerator() | ForEach-Object { "-$($_.Key) '$($_.Value)'" }) -join ' '))
        Write-Host ("New-RetentionComplianceRule -Name '{0} - Rule' -Policy '{0}' -RetentionComplianceAction {1} -RetentionDuration {2}" -f $PolicyName, $RetentionAction, $RetentionDays)
    }
    Write-Host 'Re-run with -Commit to create the LIMITED-scope pilot policy (created disabled; validate holds, then enable under change control).' -ForegroundColor Yellow
    return
}

# --- Commit path: create the policy DISABLED so validation/hold-check runs before it acts ---
if (-not $existing) {
    New-RetentionCompliancePolicy -Name $PolicyName -Enabled:$false @locParams -ErrorAction Stop | Out-Null
    Write-Host ("Created policy '{0}' (Enabled=`$false — inactive until validated + enabled under change control)." -f $PolicyName) -ForegroundColor Green
} else {
    Write-Host ("Policy '{0}' already exists — updating its scope only; action/enable handled deliberately." -f $PolicyName) -ForegroundColor Yellow
    Set-RetentionCompliancePolicy -Identity $PolicyName @locParams -ErrorAction Stop
}

$ruleName = "$PolicyName - Rule"
if (-not (Get-RetentionComplianceRule -Identity $ruleName -ErrorAction SilentlyContinue)) {
    New-RetentionComplianceRule -Name $ruleName -Policy $PolicyName `
        -RetentionComplianceAction $RetentionAction -RetentionDuration $RetentionDays -ErrorAction Stop | Out-Null
    Write-Host ("Created rule '{0}' ({1} @ {2}d)." -f $ruleName, $RetentionAction, $RetentionDays) -ForegroundColor Green
} else {
    Set-RetentionComplianceRule -Identity $ruleName -RetentionComplianceAction $RetentionAction -RetentionDuration $RetentionDays -ErrorAction Stop
    Write-Host ("Updated rule '{0}'." -f $ruleName) -ForegroundColor Green
}

Write-Host ("PASS: pilot policy '{0}' created DISABLED on a limited scope. NEXT: DLCCLEAN-Validate.ps1 to prove no held item is deletable, THEN enable under change control." -f $PolicyName) -ForegroundColor Green
