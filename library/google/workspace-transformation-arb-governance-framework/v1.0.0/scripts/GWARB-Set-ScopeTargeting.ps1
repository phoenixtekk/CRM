<#
.SYNOPSIS
    GWARB-Set-ScopeTargeting.ps1 — create the ARB membership and reviewer groups in Entra.
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the security groups that scope the Architecture and Design Review Board:
        'ARB - Voting Members - Board' (quorum-bearing decision-makers) and
        'ARB - Advisory Reviewers - Panel' (subject-matter reviewers with no vote). Optionally seeds
        each group from a CSV of user principal names so the board's roster is ready for the tracker
        and notifications. Defaults to -WhatIf so nothing is created until you review the plan.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\GWARB-Set-ScopeTargeting.ps1
        Create groups and seed rosters (after review):
            powershell -ExecutionPolicy Bypass -File .\GWARB-Set-ScopeTargeting.ps1 -VotingMembersCsv C:\Temp\voting.csv -AdvisoryMembersCsv C:\Temp\advisory.csv -Confirm
        Each CSV needs a UserPrincipalName column. Requires the Microsoft Graph PowerShell SDK and the
        Group.ReadWrite.All and User.Read.All scopes.
    EXPECTED RESULTS
        In -WhatIf: the groups and seed actions that WOULD run — no change.
        With -Confirm: both groups exist (created if missing, reused if present) and are seeded from any
        CSV supplied; group object IDs are printed. Pass = both ARB groups exist with the intended
        rosters. Record the IDs in the ARB Charter.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$VotingMembersCsv,
    [string]$AdvisoryMembersCsv
)

# Default to a preview unless the caller explicitly confirms.
if (-not $PSBoundParameters.ContainsKey('Confirm') -and -not $WhatIfPreference) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

function Get-OrNewGroup {
    param([string]$DisplayName, [string]$MailNickname)
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$DisplayName'").value | Select-Object -First 1
    if ($existing) { Write-Host "  Reusing group: $DisplayName ($($existing.id))" -ForegroundColor DarkYellow; return $existing.id }
    if ($PSCmdlet.ShouldProcess($DisplayName, "Create security group")) {
        $body = @{ displayName = $DisplayName; mailEnabled = $false; mailNickname = $MailNickname; securityEnabled = $true } | ConvertTo-Json
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body -ContentType 'application/json'
        Write-Host "  Created group: $DisplayName ($($g.id))" -ForegroundColor Green
        return $g.id
    } else {
        Write-Host "  WOULD create group: $DisplayName" -ForegroundColor DarkYellow
        return $null
    }
}

function Add-Members {
    param([string]$GroupId, [string]$Csv, [string]$Label)
    if (-not $GroupId -or -not $Csv) { return }
    if (-not (Test-Path $Csv)) { Write-Host "  $Label CSV not found: $Csv" -ForegroundColor Red; return }
    foreach ($m in (Import-Csv $Csv)) {
        $upn = $m.UserPrincipalName
        if (-not $upn) { continue }
        if ($PSCmdlet.ShouldProcess($upn, "Add to $Label group")) {
            try {
                $user = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn`?`$select=id"
                $ref  = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.id)" } | ConvertTo-Json
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$GroupId/members/`$ref" -Body $ref -ContentType 'application/json' | Out-Null
                Write-Host "    Added $upn to $Label" -ForegroundColor Green
            } catch {
                Write-Host "    Skipped $upn : $($_.Exception.Message)" -ForegroundColor DarkYellow
            }
        } else {
            Write-Host "    WOULD add $upn to $Label" -ForegroundColor DarkYellow
        }
    }
}

Write-Host "`n=== ARB membership groups ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "PREVIEW MODE (-WhatIf) — no groups will be created. Re-run with -Confirm to apply." -ForegroundColor Yellow }

$votingId   = Get-OrNewGroup -DisplayName 'ARB - Voting Members - Board'     -MailNickname 'arb-voting-board'
$advisoryId = Get-OrNewGroup -DisplayName 'ARB - Advisory Reviewers - Panel' -MailNickname 'arb-advisory-panel'

Write-Host "`nSeeding rosters..." -ForegroundColor Cyan
Add-Members -GroupId $votingId   -Csv $VotingMembersCsv   -Label 'Voting Members'
Add-Members -GroupId $advisoryId -Csv $AdvisoryMembersCsv -Label 'Advisory Reviewers'

Write-Host ("`nVoting group ID   : {0}" -f $votingId)   -ForegroundColor Cyan
Write-Host ("Advisory group ID : {0}" -f $advisoryId) -ForegroundColor Cyan
Write-Host "Record these IDs in the ARB Charter - Transformation - Ratified so quorum and notifications resolve against them." -ForegroundColor DarkYellow
Disconnect-MgGraph | Out-Null
