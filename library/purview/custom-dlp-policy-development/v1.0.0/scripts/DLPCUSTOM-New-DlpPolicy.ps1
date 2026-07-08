<#
.SYNOPSIS
    DLPCUSTOM-New-DlpPolicy.ps1 — create/tune a custom DLP policy IN SIMULATION by default (-WhatIf preview; -Commit to apply; never starts in enforcement).
.DESCRIPTION
    PURPOSE
        Authors a custom Microsoft Purview DLP policy and its rule from a JSON design file: conditions
        (sensitive info types + confidence + instance counts), exceptions (approved flows), and staged
        actions. SAFE BY DEFAULT — previews with -WhatIf and changes nothing until -Commit, and the policy
        is created in SIMULATION (New-DlpCompliancePolicy -Mode TestWithoutNotifications), never straight to
        enforcement. Use -Update to tune an existing policy/rule, and -Mode to stage it toward enforcement.
        Prints the exact reverse (rollback) command for every change.
    HOW TO RUN
        # Dry-run create (no changes):
        powershell -ExecutionPolicy Bypass -File .\DLPCUSTOM-New-DlpPolicy.ps1 -PolicyName 'Custom DLP - Sensitive Data - Pilot' -DesignPath .\DlpDesign.json -WhatIf
        # Create in simulation:
        powershell -ExecutionPolicy Bypass -File .\DLPCUSTOM-New-DlpPolicy.ps1 -PolicyName 'Custom DLP - Sensitive Data - Pilot' -DesignPath .\DlpDesign.json -Commit
        # Tune an existing policy's rule, then re-simulate:
        powershell ... -PolicyName 'Custom DLP - Sensitive Data - Pilot' -DesignPath .\DlpDesign.json -Update -Commit
        # Stage toward enforcement (only after tuning passes the gate):
        powershell ... -PolicyName 'Custom DLP - Sensitive Data - Pilot' -Update -Mode TestWithNotifications -Commit
        DesignPath JSON (example):
          { "RuleName":"Custom DLP Rule - Sensitive Data - R1",
            "ExchangeLocation":["All"], "SharePointLocation":["All"], "OneDriveLocation":["All"],
            "PilotScope":{"ExchangeSenderMemberOf":["DLP-Pilot@contoso.com"]},
            "Sit":[{"Name":"Credit Card Number","MinCount":10,"Confidence":85}],
            "Actions":{"NotifyUser":["Owner"],"BlockAccess":false,"GenerateIncidentReport":["Owner"]},
            "ExceptIfRecipientDomainIs":["approved-partner.example"] }
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-IPPSSession).
    EXPECTED RESULTS
        Dry-run prints the exact New-/Set-DlpCompliancePolicy + New-/Set-DlpComplianceRule it would run, the
        MODE, locations, conditions and exceptions, and each reverse command; flags any missing referenced
        SIT. With -Commit (create), Get-DlpCompliancePolicy shows the policy in TestWithoutNotifications on
        the pilot scope with NO block active. PASS = policy exists in simulation, matching the design.
.NOTES
    Purview — Custom DLP Policy Development. NEVER creates a policy in Enable mode; enforcement is reached
    only via -Update -Mode after the simulation match evidence passes the gate. Determinations about what is
    sensitive / which regulation applies are deferred to compliance/privacy/legal. No secrets in code.
#>
[CmdletBinding(DefaultParameterSetName='WhatIf')]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$DesignPath,
    [switch]$Update,
    [ValidateSet('TestWithoutNotifications','TestWithNotifications','Enable','Disable')]
    [string]$Mode = 'TestWithoutNotifications',
    [switch]$Commit,
    [switch]$WhatIf = $true
)
if ($Commit) { $WhatIf = $false }

# Guardrail: creating a brand-new policy is always forced into a test mode.
if (-not $Update -and $Mode -in @('Enable')) {
    Write-Host "[GUARDRAIL] A new custom DLP policy must start in simulation. Forcing -Mode TestWithoutNotifications." -ForegroundColor Yellow
    $Mode = 'TestWithoutNotifications'
}

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

$modeBanner = if ($WhatIf) { 'DRY-RUN (-WhatIf): no changes' } else { 'COMMIT: changes WILL be applied' }
Write-Host ("=== Custom DLP - Sensitive Data - Pilot  [{0}]  Mode={1} ===" -f $modeBanner, $Mode) -ForegroundColor Cyan

$design = $null
if ($DesignPath) {
    if (-not (Test-Path $DesignPath)) { throw "Design file not found: $DesignPath" }
    $design = Get-Content -Path $DesignPath -Raw | ConvertFrom-Json
}

$existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue

# --- Validate referenced SITs exist -----------------------------------------
if ($design -and $design.Sit) {
    $allSit = @(Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue).Name
    foreach ($s in $design.Sit) {
        if ($allSit -notcontains $s.Name) {
            Write-Host ("  [MISSING SIT] '{0}' is not in this tenant — build it first in its own solution, or fix the design." -f $s.Name) -ForegroundColor Yellow
        }
    }
}

# --- Stage a mode change on an existing policy (e.g. toward enforcement) ------
if ($Update -and $existing -and ($Mode -ne $existing.Mode)) {
    $reverse = ("Set-DlpCompliancePolicy -Identity '{0}' -Mode {1}" -f $PolicyName, $existing.Mode)
    if ($WhatIf) {
        Write-Host ("  [WOULD SET MODE] '{0}': {1} -> {2}" -f $PolicyName, $existing.Mode, $Mode) -ForegroundColor Yellow
        Write-Host ("                  reverse: {0}" -f $reverse) -ForegroundColor DarkGray
    } else {
        Set-DlpCompliancePolicy -Identity $PolicyName -Mode $Mode -ErrorAction Stop
        Write-Host ("  [MODE SET] '{0}' -> {1}   (reverse: {2})" -f $PolicyName, $Mode, $reverse) -ForegroundColor Green
    }
}

# --- Create the policy (always in a test mode) -------------------------------
if (-not $existing -and -not $Update) {
    $locParams = @{}
    foreach ($loc in 'Exchange','SharePoint','OneDrive','Teams','Endpoint') {
        $key = "${loc}Location"
        if ($design -and $design.$key) { $locParams[$key] = @($design.$key) }
    }
    $reverse = ("Remove-DlpCompliancePolicy -Identity '{0}' -Confirm:`$false" -f $PolicyName)
    if ($WhatIf) {
        Write-Host ("  [WOULD CREATE] New-DlpCompliancePolicy -Name '{0}' -Mode {1} {2}" -f $PolicyName, $Mode, (($locParams.GetEnumerator()|ForEach-Object{"-$($_.Key) $($_.Value -join ',')"}) -join ' ')) -ForegroundColor Yellow
        Write-Host ("                 reverse: {0}" -f $reverse) -ForegroundColor DarkGray
    } else {
        New-DlpCompliancePolicy -Name $PolicyName -Mode $Mode @locParams -ErrorAction Stop | Out-Null
        Write-Host ("  [CREATED] policy '{0}' in {1}   (reverse: {2})" -f $PolicyName, $Mode, $reverse) -ForegroundColor Green
    }
}

# --- Create / update the rule (conditions, exceptions, actions) --------------
if ($design -and $design.RuleName) {
    $ruleName = $design.RuleName
    $sitConditions = @()
    foreach ($s in $design.Sit) {
        $h = @{ Name = $s.Name }
        if ($s.MinCount)   { $h['mincount']   = $s.MinCount }
        if ($s.MaxCount)   { $h['maxcount']   = $s.MaxCount }
        if ($s.Confidence) { $h['confidencelevel'] = $s.Confidence }
        $sitConditions += $h
    }
    $ruleParams = @{ Name = $ruleName; Policy = $PolicyName }
    if ($sitConditions.Count) { $ruleParams['ContentContainsSensitiveInformation'] = $sitConditions }
    if ($design.Actions.NotifyUser)             { $ruleParams['NotifyUser'] = @($design.Actions.NotifyUser) }
    if ($design.Actions.GenerateIncidentReport) { $ruleParams['GenerateIncidentReport'] = @($design.Actions.GenerateIncidentReport) }
    # BlockAccess stays OFF while the policy is in a test mode — enforcement action is enabled later, deliberately.
    if ($design.Actions.BlockAccess -eq $true -and $Mode -eq 'Enable') { $ruleParams['BlockAccess'] = $true }
    if ($design.ExceptIfRecipientDomainIs)      { $ruleParams['ExceptIfRecipientDomainIs'] = @($design.ExceptIfRecipientDomainIs) }

    $existingRule = Get-DlpComplianceRule -Identity $ruleName -ErrorAction SilentlyContinue
    if ($existingRule) {
        $reverse = ("(re-run this script with the prior design to restore rule '{0}')" -f $ruleName)
        if ($WhatIf) {
            Write-Host ("  [WOULD UPDATE RULE] Set-DlpComplianceRule -Identity '{0}' (conditions/exceptions/actions per design)" -f $ruleName) -ForegroundColor Yellow
        } else {
            $setParams = $ruleParams.Clone(); $setParams.Remove('Policy'); $setParams['Identity'] = $ruleName; $setParams.Remove('Name')
            Set-DlpComplianceRule @setParams -ErrorAction Stop
            Write-Host ("  [RULE UPDATED] '{0}'   {1}" -f $ruleName, $reverse) -ForegroundColor Green
        }
    } else {
        $reverse = ("Remove-DlpComplianceRule -Identity '{0}' -Confirm:`$false" -f $ruleName)
        if ($WhatIf) {
            Write-Host ("  [WOULD CREATE RULE] New-DlpComplianceRule -Name '{0}' -Policy '{1}' (SITs, exceptions, notify)" -f $ruleName, $PolicyName) -ForegroundColor Yellow
            Write-Host ("                     reverse: {0}" -f $reverse) -ForegroundColor DarkGray
        } else {
            New-DlpComplianceRule @ruleParams -ErrorAction Stop | Out-Null
            Write-Host ("  [RULE CREATED] '{0}'   (reverse: {1})" -f $ruleName, $reverse) -ForegroundColor Green
        }
    }
}

if ($WhatIf) {
    Write-Host "`nDry-run complete. Re-run with -Commit to apply. New policies are created in SIMULATION (TestWithoutNotifications)." -ForegroundColor Cyan
} else {
    Write-Host ("`nDone. Verify with: DLPCUSTOM-Test-DlpPolicy.ps1 -PolicyName '{0}'.  Simulate and tune before enforcement." -f $PolicyName) -ForegroundColor Green
    Write-Host "Rollback to no-impact simulation any time: Set-DlpCompliancePolicy -Identity '<name>' -Mode TestWithoutNotifications  (or -Mode Disable)." -ForegroundColor DarkGray
}
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
