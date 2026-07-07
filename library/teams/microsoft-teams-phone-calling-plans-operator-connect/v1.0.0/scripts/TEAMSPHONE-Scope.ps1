<#
.SYNOPSIS
    TEAMSPHONE-Scope.ps1 — read-only pilot/target-group readiness + tenant PSTN scope helper.
.DESCRIPTION
    PURPOSE
        Lists the members of a pilot/target group (e.g. "Teams Phone Pilot - Voice - Pilot") with their
        current voice-readiness — enterprise-voice state, assigned number, and assigned policies — so you
        know exactly who is ready to enable before touching anything. Also surfaces tenant-level PSTN
        scope signals: number inventory by type/status and the count of enterprise-voice-enabled users.
        Read-only — makes no changes.
    HOW TO RUN
        .\TEAMSPHONE-Scope.ps1 -GroupName "Teams Phone Pilot - Voice - Pilot"
        (PowerShell 5.1+/7+, MicrosoftTeams module; connect with Connect-MicrosoftTeams — modern auth / MFA)
    EXPECTED RESULTS
        A per-member readiness table (Ready / Needs-enable) and a tenant PSTN summary. Nothing changes.
.NOTES
    Teams — Teams Phone Enablement (Calling Plans & Operator Connect). Read-only. No stored credentials.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GroupName,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
    Install-Module MicrosoftTeams -Scope CurrentUser -Force -AllowClobber
}
Import-Module MicrosoftTeams -ErrorAction Stop
try { $null = Get-CsTenant -ErrorAction Stop } catch { Connect-MicrosoftTeams | Out-Null }

Write-Host ("=== TEAMSPHONE Scope: '{0}' ===" -f $GroupName) -ForegroundColor Cyan

# --- Resolve group members (uses the Teams-connected directory) ---
$members = @()
try {
    $grp = Get-Team -DisplayName $GroupName -ErrorAction Stop | Select-Object -First 1
    if ($grp) { $members = (Get-TeamUser -GroupId $grp.GroupId | Select-Object -ExpandProperty User) }
} catch { }
if (-not $members) {
    Write-Warning ("Could not resolve members of '{0}' via Get-Team/Get-TeamUser. Supply the members another way (e.g. an Entra group via Microsoft.Graph) — this helper reports readiness for whatever UPNs resolve." -f $GroupName)
}

$rows = foreach ($upn in $members) {
    $u = Get-CsOnlineUser -Identity $upn -ErrorAction SilentlyContinue
    if (-not $u) { continue }
    $ready = $u.EnterpriseVoiceEnabled -and $u.LineURI
    [pscustomobject]@{
        UserPrincipalName      = $upn
        EnterpriseVoiceEnabled = [bool]$u.EnterpriseVoiceEnabled
        LineURI                = $u.LineURI
        CallingPolicy          = $u.TeamsCallingPolicy
        DialPlan               = $u.TenantDialPlan
        EmergencyPolicy        = $u.TeamsEmergencyCallingPolicy
        State                  = if ($ready) { 'Ready (already enabled)' } else { 'Needs-enable' }
    }
}

if ($rows) {
    $rows | Sort-Object State, UserPrincipalName | Format-Table UserPrincipalName,State,LineURI,CallingPolicy -AutoSize
    Write-Host ('--- {0} member(s); {1} need enabling ---' -f @($rows).Count, @($rows | Where-Object { $_.State -eq 'Needs-enable' }).Count) -ForegroundColor Green
}

# --- Tenant PSTN scope signals ---
Write-Host '--- Tenant PSTN scope ---' -ForegroundColor Cyan
$evCount = @(Get-CsOnlineUser -Filter 'EnterpriseVoiceEnabled -eq $true' -ErrorAction SilentlyContinue).Count
Write-Host ("Enterprise-voice-enabled users: {0}" -f $evCount)
$nums = Get-CsPhoneNumberAssignment -ErrorAction SilentlyContinue
if ($nums) {
    $nums | Group-Object PhoneNumberType, PstnAssignmentStatus | Sort-Object Name |
        Select-Object Count, @{n='Type/Status';e={$_.Name}} | Format-Table -AutoSize
} else {
    Write-Warning 'No number inventory returned (or unavailable in this cloud — verify in your tenant).'
}

if ($CsvPath -and $rows) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved readiness to {0}" -f $CsvPath) -ForegroundColor Green
}

Disconnect-MicrosoftTeams -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
