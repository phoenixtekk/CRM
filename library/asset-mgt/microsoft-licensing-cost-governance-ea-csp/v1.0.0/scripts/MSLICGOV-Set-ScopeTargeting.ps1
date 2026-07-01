<#
.SYNOPSIS
    MSLICGOV-Set-ScopeTargeting.ps1 — create the governance-scope groups for pilot and estate.
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the two security groups that scope licensing cost governance:
        'License Governance - Pilot Scope - Stage1' and 'License Governance - Estate Scope - Stage2'.
        Optionally seeds the pilot group from a CSV of user principal names so the pilot scope is
        ready for the position read and remediation steps.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MSLICGOV-Set-ScopeTargeting.ps1
        Seed the pilot group:
            powershell -ExecutionPolicy Bypass -File .\MSLICGOV-Set-ScopeTargeting.ps1 -PilotMembersCsv C:\Temp\pilot.csv
        PilotMembersCsv needs a UserPrincipalName column. Requires the Microsoft Graph PowerShell SDK
        and the Group.ReadWrite.All and User.Read.All scopes.
    EXPECTED RESULTS
        Both groups exist (created if missing, reused if present); the pilot group is seeded if a CSV
        is supplied. Group object IDs are printed for use in the register.
.NOTES
    Workplace Marketplace — Asset Mgt. Creates/updates Entra groups.
#>
[CmdletBinding()] param([string]$PilotMembersCsv)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

function Get-OrNewGroup {
    param([string]$DisplayName, [string]$MailNickname)
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$DisplayName'").value | Select-Object -First 1
    if ($existing) { Write-Host "  Reusing group: $DisplayName ($($existing.id))" -ForegroundColor DarkYellow; return $existing.id }
    $body = @{
        displayName     = $DisplayName
        mailEnabled     = $false
        mailNickname    = $MailNickname
        securityEnabled = $true
    } | ConvertTo-Json
    $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body -ContentType 'application/json'
    Write-Host "  Created group: $DisplayName ($($g.id))" -ForegroundColor Green
    return $g.id
}

Write-Host "`n=== Governance-scope groups ===" -ForegroundColor Cyan
$pilotId  = Get-OrNewGroup -DisplayName 'License Governance - Pilot Scope - Stage1'  -MailNickname 'lic-gov-pilot-stage1'
$estateId = Get-OrNewGroup -DisplayName 'License Governance - Estate Scope - Stage2' -MailNickname 'lic-gov-estate-stage2'

if ($PilotMembersCsv) {
    if (-not (Test-Path $PilotMembersCsv)) { Write-Host "Pilot CSV not found: $PilotMembersCsv" -ForegroundColor Red }
    else {
        Write-Host "`nSeeding pilot group membership..." -ForegroundColor Cyan
        foreach ($m in (Import-Csv $PilotMembersCsv)) {
            $upn = $m.UserPrincipalName
            if (-not $upn) { continue }
            try {
                $user = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn`?`$select=id"
                $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.id)" } | ConvertTo-Json
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$pilotId/members/`$ref" -Body $ref -ContentType 'application/json' | Out-Null
                Write-Host "  Added $upn to pilot group" -ForegroundColor Green
            } catch {
                Write-Host "  Skipped $upn : $($_.Exception.Message)" -ForegroundColor DarkYellow
            }
        }
    }
}

Write-Host ("`nPilot group ID : {0}" -f $pilotId)  -ForegroundColor Cyan
Write-Host ("Estate group ID: {0}" -f $estateId) -ForegroundColor Cyan
Write-Host "Record these IDs in the License Position Register." -ForegroundColor DarkYellow
Disconnect-MgGraph | Out-Null
