<#
.SYNOPSIS
    TEAMSPHONE-Validation.ps1 — validate calling + emergency-calling readiness per user (read-only report).
.DESCRIPTION
    PURPOSE
        For each supplied user, confirms Teams Phone is correctly enabled: enterprise voice on, a
        LineURI/number assigned with the expected PhoneNumberType, the named calling policy / tenant
        dial plan / emergency calling policy granted, and an emergency LocationId attached to the
        number. Emits a PASS/FAIL per check so gaps are obvious. Read-only — makes no changes. Writes
        "Voice Validation - Teams Phone - Report".
    HOW TO RUN
        .\TEAMSPHONE-Validation.ps1 -UserUpns "a@contoso.com","b@contoso.com" `
            -ExpectCallingPolicy "Calling Policy - Standard - Prod" `
            -ExpectDialPlan "Dial Plan - US - Prod" `
            -ExpectEmergencyPolicy "Emergency Calling Policy - HQ - Prod" -CsvPath C:\Temp\voice-validation.csv
        (PowerShell 5.1+/7+, MicrosoftTeams module; connect with Connect-MicrosoftTeams — modern auth / MFA)
    EXPECTED RESULTS
        A per-user, per-check PASS/FAIL table and an optional CSV. Any FAIL points at the exact remediation.
.NOTES
    Teams — Teams Phone Enablement (Calling Plans & Operator Connect). Read-only. No stored credentials.
    contoso.com is a documentation placeholder — substitute your tenant's users.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$UserUpns,
    [string]$ExpectCallingPolicy   = 'Calling Policy - Standard - Prod',
    [string]$ExpectDialPlan        = 'Dial Plan - US - Prod',
    [string]$ExpectEmergencyPolicy = 'Emergency Calling Policy - HQ - Prod',
    [string]$CsvPath,
    [string]$ReportName = 'Voice Validation - Teams Phone - Report'
)

if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
    Install-Module MicrosoftTeams -Scope CurrentUser -Force -AllowClobber
}
Import-Module MicrosoftTeams -ErrorAction Stop
try { $null = Get-CsTenant -ErrorAction Stop } catch { Connect-MicrosoftTeams | Out-Null }

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

$results = foreach ($upn in $UserUpns) {
    $u = Get-CsOnlineUser -Identity $upn -ErrorAction SilentlyContinue
    if (-not $u) {
        [pscustomobject]@{ User=$upn; EnterpriseVoice='FAIL (no user)'; Number='-'; CallingPolicy='-'; DialPlan='-'; EmergencyPolicy='-'; Location='-' }
        continue
    }

    $numRec   = Get-CsPhoneNumberAssignment -AssignedPstnTargetId $upn -ErrorAction SilentlyContinue | Select-Object -First 1
    $hasLoc   = $numRec -and $numRec.LocationId
    $evOk     = [bool]$u.EnterpriseVoiceEnabled
    $numOk    = [bool]$u.LineURI

    [pscustomobject]@{
        User            = $upn
        EnterpriseVoice = if ($evOk) { 'PASS' } else { 'FAIL (not voice-enabled — check Teams Phone license)' }
        Number          = if ($numOk) { "PASS ($($u.LineURI))" } else { 'FAIL (no number assigned)' }
        CallingPolicy   = if ("$($u.TeamsCallingPolicy)"  -eq $ExpectCallingPolicy)   { 'PASS' } else { "FAIL (is '$($u.TeamsCallingPolicy)')" }
        DialPlan        = if ("$($u.TenantDialPlan)"      -eq $ExpectDialPlan)        { 'PASS' } else { "FAIL (is '$($u.TenantDialPlan)')" }
        EmergencyPolicy = if ("$($u.TeamsEmergencyCallingPolicy)" -eq $ExpectEmergencyPolicy) { 'PASS' } else { "FAIL (is '$($u.TeamsEmergencyCallingPolicy)')" }
        Location        = if ($hasLoc) { "PASS ($($numRec.LocationId))" } else { 'FAIL (no emergency LocationId on number)' }
    }
}

$results | Format-Table -AutoSize
$fails = @($results | Where-Object { ($_ | Out-String) -match 'FAIL' }).Count
Write-Host ('--- {0} user(s) checked, {1} with at least one FAIL ---' -f @($results).Count, $fails) -ForegroundColor $(if ($fails) { 'Yellow' } else { 'Green' })

if ($CsvPath) {
    $results | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-MicrosoftTeams -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
