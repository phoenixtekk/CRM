<#
.SYNOPSIS
    TEAMSPHONE-Discovery.ps1 — read-only Teams Phone readiness, number, and voice-policy inventory (MicrosoftTeams module).
.DESCRIPTION
    PURPOSE
        Builds the Teams Phone baseline: which users are enterprise-voice-enabled, their assigned
        numbers and number type (CallingPlan / OperatorConnect / DirectRouting), assigned voice
        policies (calling policy, tenant dial plan, emergency calling policy), and spare unassigned
        number inventory. Read-only — makes no changes. Writes the export
        "Number Inventory - Teams Phone - Discovery".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TEAMSPHONE-Discovery.ps1 -CsvPath C:\Temp\TEAMSPHONE-Inventory.csv
        (PowerShell 5.1+/7+, MicrosoftTeams module; connect with Connect-MicrosoftTeams — modern auth / MFA)
    EXPECTED RESULTS
        A console summary of voice-enabled users and number inventory, plus an optional per-user CSV
        (UPN, EnterpriseVoiceEnabled, LineURI, PhoneNumberType, policies). No changes are made.
.NOTES
    Teams — Teams Phone Enablement (Calling Plans & Operator Connect). Read-only. No stored credentials.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$ReportName = 'Number Inventory - Teams Phone - Discovery'
)

if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
    Install-Module MicrosoftTeams -Scope CurrentUser -Force -AllowClobber
}
Import-Module MicrosoftTeams -ErrorAction Stop

# Modern-auth connect (no stored credentials). Reuse an existing session if present.
try { $null = Get-CsTenant -ErrorAction Stop } catch { Connect-MicrosoftTeams | Out-Null }

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

# --- Voice-enabled users and their assignments ---
$users = Get-CsOnlineUser -Filter 'EnterpriseVoiceEnabled -eq $true' -ErrorAction SilentlyContinue
if (-not $users) { $users = Get-CsOnlineUser | Where-Object { $_.EnterpriseVoiceEnabled } }

$rows = foreach ($u in $users) {
    [pscustomobject]@{
        UserPrincipalName          = $u.UserPrincipalName
        DisplayName                = $u.DisplayName
        EnterpriseVoiceEnabled     = $u.EnterpriseVoiceEnabled
        LineURI                    = $u.LineURI
        TeamsCallingPolicy         = $u.TeamsCallingPolicy
        TenantDialPlan             = $u.TenantDialPlan
        TeamsEmergencyCallingPolicy= $u.TeamsEmergencyCallingPolicy
    }
}

Write-Host ('--- Enterprise-voice-enabled users: {0} ---' -f @($rows).Count) -ForegroundColor Cyan
$rows | Sort-Object UserPrincipalName | Format-Table UserPrincipalName,LineURI,TeamsCallingPolicy,TenantDialPlan -AutoSize

# --- Number inventory: assigned vs unassigned, by type ---
$numbers = Get-CsPhoneNumberAssignment -ErrorAction SilentlyContinue
if ($numbers) {
    Write-Host '--- Number inventory by type / status ---' -ForegroundColor Cyan
    $numbers |
        Group-Object PhoneNumberType, PstnAssignmentStatus |
        Sort-Object Name |
        Select-Object Count, @{n='Type/Status';e={$_.Name}} |
        Format-Table -AutoSize

    $spare = @($numbers | Where-Object { $_.PstnAssignmentStatus -eq 'Unassigned' })
    Write-Host ('--- Spare (unassigned) numbers: {0} ---' -f $spare.Count) -ForegroundColor Green
    $spare | Select-Object TelephoneNumber, PhoneNumberType, NumberType | Format-Table -AutoSize
} else {
    Write-Warning 'Get-CsPhoneNumberAssignment returned no numbers (or is unavailable in this tenant/cloud — verify).'
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-MicrosoftTeams -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
