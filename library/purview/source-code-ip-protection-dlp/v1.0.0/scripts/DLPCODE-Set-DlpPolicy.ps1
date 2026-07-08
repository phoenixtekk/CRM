<#
.SYNOPSIS
    DLPCODE-Set-DlpPolicy.ps1 — Create the source-code/IP DLP policy across channels in TEST mode, and (as
    separate deliberate actions) switch to Enforce or back to Test (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Automates the DLP-policy lifecycle SAFELY. -Action CreatePolicy creates 'Source-Code & IP DLP -
        Policy' + 'Source-Code Detection Rule' across the in-scope channels (Exchange/SharePoint/OneDrive/
        Teams/Endpoint) for the pilot users, in TEST mode (enforces nothing). -Action Enforce switches the
        policy to Enable (enforce) — a DELIBERATE step run only after test-mode is validated and approved.
        -Action Test returns it to test mode. DEFAULTS TO -WhatIf: prints exactly what it would do plus the
        reverse action and changes nothing; applies only with -Commit. No secrets in code.
    HOW TO RUN
        .\DLPCODE-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotUsers "codedlp-pilot@contoso.com" -UseSourceCodeClassifier -WhatIf
        .\DLPCODE-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotUsers "codedlp-pilot@contoso.com" -UseSourceCodeClassifier -Commit
        .\DLPCODE-Set-DlpPolicy.ps1 -Action Enforce -Commit
        .\DLPCODE-Set-DlpPolicy.ps1 -Action Test -Commit
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession (modern-auth/MFA admin).
    EXPECTED RESULTS
        -WhatIf: the plan + reverse command, no change. CreatePolicy -Commit: policy + rule exist in test
        mode across the chosen channels (verify with Get-DlpCompliancePolicy). Enforce/Test -Commit: policy
        Mode changes accordingly. Complete the Source Code classifier + endpoint egress detail in the portal.
.NOTES
    Purview — Source-Code & IP Protection DLP. Safe-by-default; enforcement behind its own action. Verify
    your licensing/tenant: Endpoint DLP + Source Code classifier require E5; confirm the classifier's exact
    reference in the portal.
#>
[CmdletBinding()]
param(
    [ValidateSet('CreatePolicy','Enforce','Test')]
    [string]$Action = 'CreatePolicy',
    [string]$PolicyName = 'Source-Code & IP DLP - Policy',
    [string]$RuleName   = 'Source-Code Detection Rule',
    [string[]]$PilotUsers = @(),                                  # UPNs / groups for the pilot ring (Exchange/Teams/Endpoint scoping)
    [switch]$IncludeEndpoint,                                     # include Endpoint DLP (requires E5 + onboarding)
    [switch]$UseSourceCodeClassifier,                            # reference the built-in Source Code trainable classifier
    [string[]]$CustomSensitiveTypes = @(),                       # exact custom IP SIT names (see DLPCODE-Discover)
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
Write-Host "`n=== Source-Code & IP DLP — Action: $Action — Mode: $mode ===" -ForegroundColor Cyan

if ($Action -eq 'CreatePolicy') {
    $existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    $channels = @('Exchange','SharePoint (All)','OneDrive (All)','Teams')
    if ($IncludeEndpoint) { $channels += 'Endpoint' }
    $detect = @()
    if ($UseSourceCodeClassifier) { $detect += 'Source Code trainable classifier' }
    if ($CustomSensitiveTypes.Count -gt 0) { $detect += ("custom IP types: {0}" -f ($CustomSensitiveTypes -join ', ')) }
    if ($detect.Count -eq 0) { $detect += '(specify -UseSourceCodeClassifier and/or -CustomSensitiveTypes)' }

    if ($WhatIf) {
        if ($existing) { Write-Host ("  WOULD reuse policy '{0}' (Mode: {1}) and ensure the rule." -f $PolicyName, $existing.Mode) -ForegroundColor Yellow }
        else           { Write-Host ("  WOULD create policy '{0}' in TEST mode. Channels: {1}. Pilot users: {2}" -f $PolicyName, ($channels -join ', '), ($PilotUsers -join ', ')) -ForegroundColor Yellow }
        Write-Host ("  WOULD create rule '{0}': detect [{1}] on egress -> restrict/notify (test)." -f $RuleName, ($detect -join ' + ')) -ForegroundColor Yellow
        Write-Host ("        reverse: Remove-DlpCompliancePolicy -Identity '{0}'" -f $PolicyName) -ForegroundColor DarkGray
        Write-Host "  NOTE: test mode enforces nothing. Enforcement is a separate deliberate step: -Action Enforce." -ForegroundColor DarkGray
        Write-Host "  NOTE: complete the Source Code classifier reference + endpoint egress activities in the portal." -ForegroundColor DarkGray
        return
    }
    try {
        if (-not $existing) {
            $splat = @{
                Name = $PolicyName; Mode = 'TestWithoutNotifications'
                ExchangeLocation   = 'All'
                SharePointLocation = 'All'
                OneDriveLocation   = 'All'
                TeamsLocation      = 'All'
            }
            if ($IncludeEndpoint) { $splat['EndpointDlpLocation'] = 'All' }
            New-DlpCompliancePolicy @splat -ErrorAction Stop | Out-Null
            Write-Host ("  CREATED policy '{0}' in TEST mode across channels: {1}." -f $PolicyName, ($channels -join ', ')) -ForegroundColor Green
            Write-Host "  Scope Exchange/Teams/Endpoint to the pilot users/devices in the portal (or via account scoping)." -ForegroundColor DarkGray
        } else {
            Write-Host ("  Reusing existing policy '{0}'." -f $PolicyName) -ForegroundColor DarkGray
        }
        $rule = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RuleName }
        if (-not $rule) {
            $sit = @()
            foreach ($t in $CustomSensitiveTypes) { $sit += @{ Name = $t; minCount = 1 } }
            # NOTE: the Source Code trainable classifier is added by CLASSIFIER reference in the portal (or via
            # the appropriate -ContentContainsSensitiveInformation classifier group for your module version).
            if ($sit.Count -gt 0) {
                New-DlpComplianceRule -Name $RuleName -Policy $PolicyName `
                    -ContentContainsSensitiveInformation $sit -NotifyUser 'Owner','LastModifier' -ErrorAction Stop | Out-Null
            } else {
                New-DlpComplianceRule -Name $RuleName -Policy $PolicyName -NotifyUser 'Owner','LastModifier' -ErrorAction Stop | Out-Null
            }
            Write-Host ("  CREATED rule '{0}' (test mode). ADD the Source Code classifier + endpoint egress conditions in the portal." -f $RuleName) -ForegroundColor Green
        } else {
            Write-Host ("  Rule '{0}' already exists — review it in the portal." -f $RuleName) -ForegroundColor DarkGray
        }
        Write-Host "  Complete classifier, endpoint egress activities, policy tips, notifications, alerts, exceptions in the portal. Pilot in test mode." -ForegroundColor DarkGray
    } catch {
        Write-Host ("  ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host "  Verify parameter names (locations / ContentContainsSensitiveInformation / classifier reference) for your module version." -ForegroundColor Yellow
    }
    return
}

if ($Action -in @('Enforce','Test')) {
    $target = if ($Action -eq 'Enforce') { 'Enable' } else { 'TestWithoutNotifications' }
    if ($WhatIf) {
        Write-Host ("  WOULD set policy '{0}' Mode -> {1}." -f $PolicyName, $target) -ForegroundColor Yellow
        $rev = if ($Action -eq 'Enforce') { 'TestWithoutNotifications' } else { 'Enable' }
        Write-Host ("        reverse: Set-DlpCompliancePolicy -Identity '{0}' -Mode {1}" -f $PolicyName, $rev) -ForegroundColor DarkGray
        if ($Action -eq 'Enforce') { Write-Host "  WARNING: Enforce blocks real egress (email/USB/upload). Only after validation + approval; tell developers first." -ForegroundColor Red }
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
