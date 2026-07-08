<#
.SYNOPSIS
    ANDROIDGW-Set-Scope.ps1 — scope/config helper that creates & populates the pilot group for the integration. Defaults to -WhatIf (NO changes).
.DESCRIPTION
    PURPOSE
        Prepares the containment scope for the pilot: ensures the Entra security group
        "MGP Pilot - Android - Stage1" exists and (optionally) adds the pilot users/devices you supply,
        so app assignments and enrollment restrictions can be targeted at the pilot only. Also READ-
        reports the current managed Google Play enrollment target for awareness. SAFE BY DEFAULT — runs
        in -WhatIf mode and changes nothing unless -Commit is supplied; the only writes are group create
        + membership add (reversible). It does NOT change the managed Google Play binding or enrollment
        target — those high-impact changes are done deliberately in the consoles per the guide.
    HOW TO RUN
        Dry-run (default, NO changes):
          powershell -ExecutionPolicy Bypass -File .\ANDROIDGW-Set-Scope.ps1 -MemberUpns u1@contoso.com,u2@contoso.com
        Apply (create group if needed + add members):
          powershell -ExecutionPolicy Bypass -File .\ANDROIDGW-Set-Scope.ps1 -MemberUpns u1@contoso.com,u2@contoso.com -Commit
        Requires the Microsoft Graph PowerShell SDK and scopes:
          -WhatIf : Group.Read.All, DeviceManagementServiceConfig.Read.All
          -Commit : Group.ReadWrite.All, GroupMember.ReadWrite.All, DeviceManagementServiceConfig.Read.All
    EXPECTED RESULTS
        -WhatIf: prints the group + members that WOULD be created/added; nothing changes.
        -Commit: the pilot group exists and the listed members are added; a summary is printed.
.NOTES
    Android — Google Workspace <-> Intune Third-Party EMM. Only write is the reversible pilot-group
    membership; the binding / enrollment-target changes are NOT automated here (too high-impact) — do
    them in the consoles under change control per Implementation (03).
#>
[CmdletBinding()]
param(
    [string]$GroupName = 'MGP Pilot - Android - Stage1',
    [string[]]$MemberUpns = @(),
    [switch]$Commit                     # absent = -WhatIf (default, no changes)
)

$WhatIf = -not $Commit
$mode = if ($WhatIf) { 'WHATIF (no changes)' } else { 'COMMIT (applying changes)' }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($WhatIf) { @('Group.Read.All','DeviceManagementServiceConfig.Read.All') } else { @('Group.ReadWrite.All','GroupMember.ReadWrite.All','DeviceManagementServiceConfig.Read.All') }
Connect-MgGraph -Scopes $scopes -NoWelcome

Write-Host ("=== ANDROIDGW Set-Scope [{0}] group: {1} ===" -f $mode, $GroupName) -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Red' })

# --- Read-report current managed Google Play enrollment target (awareness only) ---
try {
    $binding = Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings'
    Write-Host ('Current MGP enrollmentTarget: {0}; targetGroupIds: {1}' -f $binding.enrollmentTarget, (($binding.targetGroupIds) -join ',')) -ForegroundColor DarkCyan
    Write-Host 'NOTE: This script does NOT change the enrollment target — do that deliberately in Intune per the guide.' -ForegroundColor DarkCyan
} catch {
    Write-Warning ("Could not read enrollment target (beta): {0}" -f $_.Exception.Message)
}

# --- Ensure the pilot group exists ---
$g = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f ($GroupName -replace "'","''"))).value | Select-Object -First 1
if ($g) {
    Write-Host ("Group exists: {0} ({1})" -f $g.displayName, $g.id) -ForegroundColor Green
    $groupId = $g.id
} else {
    if ($WhatIf) {
        Write-Host ("WOULD create security group '{0}'" -f $GroupName) -ForegroundColor Yellow
        $groupId = $null
    } else {
        $mailNick = ($GroupName -replace '[^a-zA-Z0-9]','')
        $body = @{ displayName = $GroupName; mailEnabled = $false; mailNickname = $mailNick; securityEnabled = $true }
        $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json) -ContentType 'application/json'
        $groupId = $new.id
        Write-Host ("Created group '{0}' ({1})" -f $GroupName, $groupId) -ForegroundColor Green
    }
}

# --- Add members ---
$added = 0; $skipped = 0
foreach ($upn in $MemberUpns) {
    if (-not $upn) { continue }
    $u = $null
    try { $u = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}?`$select=id,userPrincipalName" -f [uri]::EscapeDataString($upn)) } catch {}
    if (-not $u) { Write-Host ("SKIP {0} — user not found" -f $upn) -ForegroundColor DarkYellow; $skipped++; continue }

    if ($WhatIf -or -not $groupId) {
        Write-Host ("WOULD add {0} to '{1}'" -f $upn, $GroupName) -ForegroundColor Yellow
        $added++
    } else {
        try {
            $ref = @{ '@odata.id' = ("https://graph.microsoft.com/v1.0/directoryObjects/{0}" -f $u.id) }
            Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/groups/{0}/members/`$ref" -f $groupId) -Body ($ref | ConvertTo-Json) -ContentType 'application/json' | Out-Null
            Write-Host ("Added {0}" -f $upn) -ForegroundColor Green
            $added++
        } catch {
            if ($_.Exception.Message -match 'already exist|added object references already') { Write-Host ("Already a member: {0}" -f $upn) -ForegroundColor DarkGray; $skipped++ }
            else { Write-Host ("ERROR adding {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Red; $skipped++ }
        }
    }
}

Write-Host ("=== {0}: {1} added/would-add, {2} skipped ===" -f $mode, $added, $skipped) -ForegroundColor Cyan
if ($WhatIf) { Write-Host 'Re-run with -Commit to apply. To undo, remove members / delete the group in Entra.' -ForegroundColor Yellow }

Disconnect-MgGraph | Out-Null
