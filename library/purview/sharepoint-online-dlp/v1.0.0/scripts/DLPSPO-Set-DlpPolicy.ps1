<#
.SYNOPSIS
    DLPSPO-Set-DlpPolicy.ps1 — Create the SharePoint/OneDrive DLP policy in TEST mode, and (as separate
    deliberate actions) switch to Enforce or back to Test (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Automates the DLP-policy lifecycle SAFELY. -Action CreatePolicy creates 'SPO-OneDrive DLP - Policy'
        + 'SPO DLP - External Sharing Rule' scoped to the pilot sites, in TEST mode (enforces nothing).
        -Action Enforce switches the policy to Enable (enforce) — a DELIBERATE step run only after test-mode
        is validated and approved. -Action Test returns it to test mode. DEFAULTS TO -WhatIf: prints exactly
        what it would do plus the reverse action and changes nothing; applies only with -Commit. No secrets.
    HOW TO RUN
        .\DLPSPO-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -SensitiveTypes "Credit Card Number" -WhatIf
        .\DLPSPO-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -SensitiveTypes "Credit Card Number" -Commit
        .\DLPSPO-Set-DlpPolicy.ps1 -Action Enforce -Commit
        .\DLPSPO-Set-DlpPolicy.ps1 -Action Test -Commit
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession (modern-auth/MFA admin).
    EXPECTED RESULTS
        -WhatIf: the plan + reverse command, no change. CreatePolicy -Commit: policy + rule exist in test
        mode (verify with Get-DlpCompliancePolicy). Enforce/Test -Commit: policy Mode changes accordingly.
.NOTES
    Purview — SharePoint Online DLP. Safe-by-default; enforcement behind its own action. Verify your
    licensing/tenant. Complete tip/notification/exception detail in the portal.
#>
[CmdletBinding()]
param(
    [ValidateSet('CreatePolicy','Enforce','Test')]
    [string]$Action = 'CreatePolicy',
    [string]$PolicyName = 'SPO-OneDrive DLP - Policy',
    [string]$RuleName   = 'SPO DLP - External Sharing Rule',
    [string[]]$PilotSites = @(),                                  # SharePoint site URLs for the pilot scope
    [switch]$IncludeAllOneDrive,                                  # include OneDrive (All) where designed
    [string[]]$SensitiveTypes = @('Credit Card Number'),         # exact SIT names (see DLPSPO-Discover)
    [int]$MinCount = 1,
    [switch]$WhatIf,
    [switch]$Commit
)

if (-not $Commit) { $WhatIf = $true }
if ($WhatIf -and $Commit) { Write-Host "Specify either -WhatIf or -Commit, not both." -ForegroundColor Yellow; return }

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
if (-not (Test-Command 'Get-DlpCompliancePolicy')) {
    Write-Host "Security & Compliance PowerShell not connected. Run Connect-IPPSSession first." -ForegroundColor Yellow; return
}

$mode = $(if ($Commit) { 'COMMIT' } else { 'WHATIF (no changes)' })
Write-Host "`n=== SharePoint Online DLP — Action: $Action — Mode: $mode ===" -ForegroundColor Cyan

if ($Action -eq 'CreatePolicy') {
    if ($PilotSites.Count -eq 0 -and -not $IncludeAllOneDrive) {
        Write-Host "Provide -PilotSites (SharePoint URLs) and/or -IncludeAllOneDrive to scope the pilot." -ForegroundColor Yellow; return
    }
    $existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($WhatIf) {
        if ($existing) { Write-Host ("  WOULD reuse policy '{0}' (Mode: {1}) and ensure the rule." -f $PolicyName, $existing.Mode) -ForegroundColor Yellow }
        else           { Write-Host ("  WOULD create policy '{0}' in TEST mode scoped to [{1}]{2}" -f $PolicyName, ($PilotSites -join ', '), $(if($IncludeAllOneDrive){' + OneDrive(All)'}else{''})) -ForegroundColor Yellow }
        Write-Host ("  WOULD create rule '{0}': match [{1}] (min {2}) AND shared externally -> restrict/notify (test)." -f $RuleName, ($SensitiveTypes -join ', '), $MinCount) -ForegroundColor Yellow
        Write-Host ("        reverse: Remove-DlpCompliancePolicy -Identity '{0}'" -f $PolicyName) -ForegroundColor DarkGray
        Write-Host "  NOTE: test mode enforces nothing. Enforcement is a separate deliberate step: -Action Enforce." -ForegroundColor DarkGray
        return
    }
    try {
        if (-not $existing) {
            $splat = @{ Name = $PolicyName; Mode = 'TestWithoutNotifications' }
            if ($PilotSites.Count -gt 0) { $splat['SharePointLocation'] = $PilotSites }
            if ($IncludeAllOneDrive)     { $splat['OneDriveLocation']  = 'All' }
            New-DlpCompliancePolicy @splat -ErrorAction Stop | Out-Null
            Write-Host ("  CREATED policy '{0}' in TEST mode." -f $PolicyName) -ForegroundColor Green
        } else {
            Write-Host ("  Reusing existing policy '{0}'." -f $PolicyName) -ForegroundColor DarkGray
        }
        $rule = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RuleName }
        if (-not $rule) {
            $sit = $SensitiveTypes | ForEach-Object { @{ Name = $_; minCount = $MinCount } }
            New-DlpComplianceRule -Name $RuleName -Policy $PolicyName `
                -ContentContainsSensitiveInformation $sit `
                -AccessScope NotInOrganization `
                -BlockAccess $true -NotifyUser 'Owner','LastModifier' -ErrorAction Stop | Out-Null
            Write-Host ("  CREATED rule '{0}' (test mode enforces nothing yet)." -f $RuleName) -ForegroundColor Green
        } else {
            Write-Host ("  Rule '{0}' already exists — review it in the portal." -f $RuleName) -ForegroundColor DarkGray
        }
        Write-Host "  Complete policy-tip text, notifications, alerts, and exceptions in the portal. Pilot in test mode." -ForegroundColor DarkGray
    } catch {
        Write-Host ("  ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host "  Verify parameter names (AccessScope/ContentContainsSensitiveInformation) for your module version." -ForegroundColor Yellow
    }
    return
}

if ($Action -in @('Enforce','Test')) {
    $target = if ($Action -eq 'Enforce') { 'Enable' } else { 'TestWithoutNotifications' }
    if ($WhatIf) {
        Write-Host ("  WOULD set policy '{0}' Mode -> {1}." -f $PolicyName, $target) -ForegroundColor Yellow
        $rev = if ($Action -eq 'Enforce') { 'TestWithoutNotifications' } else { 'Enable' }
        Write-Host ("        reverse: Set-DlpCompliancePolicy -Identity '{0}' -Mode {1}" -f $PolicyName, $rev) -ForegroundColor DarkGray
        if ($Action -eq 'Enforce') { Write-Host "  WARNING: Enforce blocks real sharing. Only after validation + approval; communicate to users first." -ForegroundColor Red }
        return
    }
    try {
        Set-DlpCompliancePolicy -Identity $PolicyName -Mode $target -ErrorAction Stop | Out-Null
        Write-Host ("  SET policy '{0}' Mode -> {1}." -f $PolicyName, $target) -ForegroundColor Green
    } catch {
        Write-Host ("  ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host "  Verify the -Mode values for your ExchangeOnlineManagement version." -ForegroundColor Yellow
    }
}
