<#
.SYNOPSIS
    ANDROIDDX-Set-ScopeTargeting.ps1 — build/refresh the 'Enrollment Scope - Android' Entra ID group that bounds a pilot or expansion.
.DESCRIPTION
    PURPOSE
        Creates (if missing) and populates the security group that scopes an enrollment
        troubleshooting pilot — e.g. 'Enrollment Scope - Android - Pilot' for the reproduction/pilot
        set or 'Enrollment Scope - Android - Expanded' for the fleet. Members are added from a CSV of
        user principal names so every retest and every rollout targets a known, repeatable set. Writes
        group membership only; -WhatIf shows the plan without changing anything.
    HOW TO RUN
        Preview:  powershell -ExecutionPolicy Bypass -File .\ANDROIDDX-Set-ScopeTargeting.ps1 -GroupName "Enrollment Scope - Android - Pilot" -MembersCsv .\pilot-users.csv -WhatIf
        Apply:    powershell -ExecutionPolicy Bypass -File .\ANDROIDDX-Set-ScopeTargeting.ps1 -GroupName "Enrollment Scope - Android - Pilot" -MembersCsv .\pilot-users.csv
        MembersCsv expects a single column: UserPrincipalName. Requires the Microsoft Graph SDK and
        scopes Group.ReadWrite.All, User.Read.All. Assign your Android enrollment profile/config to this group in Intune.
    EXPECTED RESULTS
        The named group exists and contains the listed users; new members are added, existing ones left
        in place (idempotent). Use it as 'Enrollment Scope - Android - Pilot/Expanded' for assignment.
.NOTES
    Android. Writes Entra ID group membership; -WhatIf-safe and idempotent.
    No credentials/secrets in code; least-privilege scopes only.
#>
[CmdletBinding(SupportsShouldProcess)] param(
    [Parameter(Mandatory)][string]$GroupName,
    [Parameter(Mandatory)][string]$MembersCsv
)
if (-not (Test-Path $MembersCsv)) { throw "MembersCsv not found: $MembersCsv (column: UserPrincipalName)." }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

# Find or create the group
$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$GroupName'&`$select=id,displayName").value | Select-Object -First 1
if (-not $grp) {
    if ($PSCmdlet.ShouldProcess($GroupName, "Create security group")) {
        $mailNick = ($GroupName -replace '[^a-zA-Z0-9]','')
        $body = @{ displayName=$GroupName; mailEnabled=$false; mailNickname=$mailNick; securityEnabled=$true } | ConvertTo-Json
        $grp = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body $body -ContentType 'application/json'
        Write-Host ("Created group: {0}" -f $GroupName) -ForegroundColor Green
    } else { Write-Host ("WhatIf: would create group '{0}' (no members can be added in preview)." -f $GroupName) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
} else { Write-Host ("Group exists: {0}" -f $GroupName) -ForegroundColor Cyan }

# Existing members (idempotency)
$existing = New-Object System.Collections.Generic.HashSet[string]
$mUri = "/v1.0/groups/$($grp.id)/members?`$select=id&`$top=999"
do { $mr = Invoke-MgGraphRequest -Method GET -Uri $mUri; foreach ($m in $mr.value) { [void]$existing.Add($m.id) }; $mUri = $mr.'@odata.nextLink' } while ($mUri)

$added = 0
foreach ($row in (Import-Csv $MembersCsv)) {
    $upn = $row.UserPrincipalName
    if (-not $upn) { continue }
    $u = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn`?`$select=id" -ErrorAction SilentlyContinue)
    if (-not $u) { Write-Host ("  Skipped (not found): {0}" -f $upn) -ForegroundColor Yellow; continue }
    if ($existing.Contains($u.id)) { continue }
    if ($PSCmdlet.ShouldProcess($upn, "Add to $GroupName")) {
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" } | ConvertTo-Json
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($grp.id)/members/`$ref" -Body $ref -ContentType 'application/json'
        Write-Host ("  Added: {0}" -f $upn) -ForegroundColor Green; $added++
    }
}
Write-Host ("`nDone. Added {0} new member(s) to '{1}'. Assign the Android enrollment profile/config to this group in Intune." -f $added, $GroupName) -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
