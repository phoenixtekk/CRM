<#
.SYNOPSIS
    W365G-Set-ScopeTargeting.ps1 — create/populate the Windows 365 Government (GCC High) Cloud PC targeting groups.
.DESCRIPTION
    PURPOSE
        Builds the Entra ID security groups the Windows 365 provisioning policy is assigned to —
        'W365G - Users - Pilot' and 'W365G - Users - Production' — and optionally adds members from a
        list of user principal names, against Microsoft Graph US Gov. Defaults to -WhatIf so nothing
        changes until you confirm. Creating a group makes no Cloud PCs by itself; assigning the
        provisioning policy to the group (Implementation Step 4/9) is what triggers provisioning.
        Placeholders like user1@your-tenant.onmicrosoft.us are used, not angle brackets.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\W365G-Set-ScopeTargeting.ps1
        Create the groups (opt in):
            powershell -ExecutionPolicy Bypass -File .\W365G-Set-ScopeTargeting.ps1 -WhatIf:$false
        Create + add pilot members:
            powershell -ExecutionPolicy Bypass -File .\W365G-Set-ScopeTargeting.ps1 -Stage Pilot -Upns user1@your-tenant.onmicrosoft.us -WhatIf:$false
        Requires the Microsoft Graph PowerShell SDK; connects with -Environment USGov and consents to
        Group.ReadWrite.All + User.Read.All on first run.
    EXPECTED RESULTS
        In -WhatIf (default) the intended group creates/membership adds are printed and nothing changes.
        With -WhatIf:$false the named group exists (created if missing) and any supplied UPNs are added;
        the group object id is printed for the Intune assignment.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
    Read-only unless invoked with -WhatIf:$false; then it creates/updates groups only (no Cloud PC changes).
    Group naming uses the en-dash convention 'W365G - <Scope> - <Stage>' to match the docs.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Pilot','Production','Both')] [string]$Stage = 'Both',
    [string[]]$Upns,
    [switch]$WhatIf = $true
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# GCC High: Microsoft Graph US Gov L4 (graph.microsoft.us).
Connect-MgGraph -Environment USGov -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

function Get-OrNew-Group([string]$name) {
    $esc = $name.Replace("'","''")
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$esc'").value | Select-Object -First 1
    if ($g) { Write-Host ("  Exists : {0}  ({1})" -f $name, $g.id) -ForegroundColor Green; return $g.id }
    if ($WhatIf) { Write-Host ("  [WhatIf] Would create group: {0}" -f $name) -ForegroundColor Yellow; return $null }
    if ($PSCmdlet.ShouldProcess($name, 'Create security group')) {
        $mailNick = ($name -replace '[^a-zA-Z0-9]','')
        $body = @{ displayName = $name; mailEnabled = $false; mailNickname = $mailNick; securityEnabled = $true }
        $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("  Created: {0}  ({1})" -f $name, $new.id) -ForegroundColor Green
        return $new.id
    }
}

function Add-Members([string]$groupId, [string[]]$upnList) {
    if (-not $groupId) { return }
    foreach ($upn in $upnList) {
        if ($WhatIf) { Write-Host ("    [WhatIf] Would add {0}" -f $upn) -ForegroundColor Yellow; continue }
        if (-not $PSCmdlet.ShouldProcess($upn, "Add to group $groupId")) { continue }
        try {
            $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn"
            $ref = @{ '@odata.id' = "https://graph.microsoft.us/v1.0/directoryObjects/$($u.id)" }
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$groupId/members/`$ref" -Body ($ref | ConvertTo-Json)
            Write-Host ("    + added {0}" -f $upn) -ForegroundColor Green
        } catch { Write-Host ("    ! could not add {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Yellow }
    }
}

Write-Host "`n=== Windows 365 Government (GCC High) targeting groups ===" -ForegroundColor Cyan
Write-Host "Graph environment: USGov (graph.microsoft.us)" -ForegroundColor DarkCyan
if ($WhatIf) { Write-Host "Mode: -WhatIf (preview). Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow }

$targets = @()
if ($Stage -in 'Pilot','Both')      { $targets += @{ Stage='Pilot';      Name='W365G - Users - Pilot' } }
if ($Stage -in 'Production','Both') { $targets += @{ Stage='Production'; Name='W365G - Users - Production' } }

foreach ($t in $targets) {
    $id = Get-OrNew-Group $t.Name
    # Only add members to the stage explicitly requested (avoid putting pilot users into production).
    if ($Upns -and $Stage -ne 'Both' -and $t.Stage -eq $Stage) { Add-Members $id $Upns }
}
if ($Upns -and $Stage -eq 'Both') { Write-Host "  Note: -Upns ignored with -Stage Both; re-run with -Stage Pilot or Production to add members." -ForegroundColor Yellow }

Write-Host "`nAssign the provisioning policy to these groups in Intune (intune.microsoft.us > Devices > Windows 365)." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
