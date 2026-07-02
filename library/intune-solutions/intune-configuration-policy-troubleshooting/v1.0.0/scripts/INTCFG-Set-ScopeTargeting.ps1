<#
.SYNOPSIS
    INTCFG-Set-ScopeTargeting.ps1 — create/populate the pilot scope groups for clean targeting.
.DESCRIPTION
    PURPOSE
        Builds the named pilot scope groups used to reproduce and fix targeting safely:
        INTCFG-Pilot-Devices and INTCFG-Pilot-Users. It creates each group if missing and adds the
        device/user object IDs you pass in. Use it to give a policy a small, known scope before
        touching production assignments. Defaults to -WhatIf: it previews every create/add and writes
        nothing until you re-run with -WhatIf:$false.
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\INTCFG-Set-ScopeTargeting.ps1 -DeviceIds id1,id2
        Apply:
          powershell -ExecutionPolicy Bypass -File .\INTCFG-Set-ScopeTargeting.ps1 -DeviceIds id1,id2 -WhatIf:$false
        Requires Microsoft Graph SDK and Group.ReadWrite.All (write scope only used when applying).
    EXPECTED RESULTS
        In -WhatIf: "WHATIF: would create/add ...". Applied: the groups exist and contain the members;
        then assign your policy to INTCFG-Pilot-Devices in Intune and validate.
.NOTES
    White-label — the repeatable way. Default -WhatIf. Object IDs are Entra directory object IDs,
    not device names — use your-device-object-id / your-user-object-id from Entra.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string[]]$DeviceIds = @(),
    [string[]]$UserIds   = @(),
    [string]$DeviceGroupName = 'INTCFG-Pilot-Devices',
    [string]$UserGroupName   = 'INTCFG-Pilot-Users',
    [switch]$WhatIf = $true
)
if ($PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = [bool]$WhatIf } else { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

function Get-OrCreateGroup([string]$name) {
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$name'").value
    if ($existing -and $existing.Count -gt 0) {
        Write-Host ("Group exists : {0}  [{1}]" -f $name, $existing[0].id) -ForegroundColor Green
        return $existing[0].id
    }
    if ($PSCmdlet.ShouldProcess($name, 'Create Entra security group')) {
        $body = @{
            displayName     = $name
            mailEnabled     = $false
            mailNickname    = ($name -replace '[^0-9A-Za-z]', '')
            securityEnabled = $true
        }
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("Group created: {0}  [{1}]" -f $name, $g.id) -ForegroundColor Green
        return $g.id
    } else {
        Write-Host ("WHATIF: would create security group '{0}' (no change made)." -f $name) -ForegroundColor Gray
        return $null
    }
}

function Add-Members([string]$groupId, [string]$groupName, [string[]]$objectIds) {
    if (-not $objectIds -or $objectIds.Count -eq 0) { return }
    foreach ($oid in $objectIds) {
        if ($PSCmdlet.ShouldProcess("$groupName <- $oid", 'Add member to group')) {
            if (-not $groupId) { Write-Host "  (group not created in preview; cannot add in -WhatIf)" -ForegroundColor Gray; continue }
            try {
                $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$oid" }
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$groupId/members/`$ref" -Body ($ref | ConvertTo-Json)
                Write-Host ("  added {0} to {1}" -f $oid, $groupName) -ForegroundColor Green
            } catch {
                if ($_.Exception.Message -match 'already exist') { Write-Host ("  {0} already a member of {1}" -f $oid, $groupName) -ForegroundColor Gray }
                else { Write-Host ("  add failed for {0}: {1}" -f $oid, $_.Exception.Message) -ForegroundColor Yellow }
            }
        } else {
            Write-Host ("  WHATIF: would add {0} to {1} (no change made)." -f $oid, $groupName) -ForegroundColor Gray
        }
    }
}

Write-Host "`n=== INTCFG Scope Targeting — pilot groups ===" -ForegroundColor Cyan

if ($DeviceIds.Count -gt 0 -or $UserIds.Count -eq 0) {
    $devGid = Get-OrCreateGroup $DeviceGroupName
    Add-Members $devGid $DeviceGroupName $DeviceIds
}
if ($UserIds.Count -gt 0) {
    $usrGid = Get-OrCreateGroup $UserGroupName
    Add-Members $usrGid $UserGroupName $UserIds
}

Write-Host "`nNext: in Intune, assign the affected policy to $DeviceGroupName, then run INTCFG-Validation.ps1." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
