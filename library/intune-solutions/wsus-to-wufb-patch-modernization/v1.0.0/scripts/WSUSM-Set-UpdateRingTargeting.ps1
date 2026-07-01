<#
.SYNOPSIS
    WSUSM-Set-UpdateRingTargeting.ps1 — build the update-ring device groups (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Creates the Microsoft Entra security groups that the Windows Update for Business update rings
        are assigned to, using the migration naming convention. By default it creates:
            'WUfB - Ring - Pilot'   (assigned the fast pilot update ring)
            'WUfB - Ring - Broad'   (assigned the slower broad ring)
        These are the targeting groups for the cutover; you assign the rings to them in the Intune
        admin center (Implementation Steps 3-4). Existing groups with the same name are reused, not
        duplicated.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\WSUSM-Set-UpdateRingTargeting.ps1
        Apply:             powershell -ExecutionPolicy Bypass -File .\WSUSM-Set-UpdateRingTargeting.ps1 -Confirm
        Requires the Microsoft Graph PowerShell SDK and the Group.ReadWrite.All scope.
    EXPECTED RESULTS
        In preview: the groups that WOULD be created are listed. With -Confirm: each missing group is
        created (assignable security group) and its object ID printed for use in ring assignment.
.NOTES
    Workplace Marketplace - Intune Solutions. Naming convention: <Purpose> - <Scope> - <Stage>.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string[]] $GroupNames = @('WUfB - Ring - Pilot', 'WUfB - Ring - Broad'),
    [switch]   $Confirm
)

if (-not $Confirm -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

Write-Host "`n=== WSUS-to-WUfB update-ring targeting groups ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "MODE: PREVIEW (-WhatIf) - no groups created. Pass -Confirm to apply.`n" -ForegroundColor Yellow }

foreach ($name in $GroupNames) {
    $filter   = "displayName eq '$($name.Replace("'","''"))'"
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$([uri]::EscapeDataString($filter))").value

    if ($existing) {
        Write-Host ("  Exists  : {0}  (id {1})" -f $name, $existing[0].id) -ForegroundColor DarkGray
        continue
    }

    if ($PSCmdlet.ShouldProcess($name, "Create security group")) {
        $mailNick = ($name -replace '[^a-zA-Z0-9]', '')
        $body = @{
            displayName     = $name
            description     = "Targeting group for WUfB update ring ($name)"
            mailEnabled     = $false
            mailNickname    = $mailNick
            securityEnabled = $true
        }
        $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("  Created : {0}  (id {1})" -f $name, $new.id) -ForegroundColor Green
    } else {
        Write-Host ("  WOULD create: {0}" -f $name) -ForegroundColor Yellow
    }
}

Write-Host "`nNext: in Intune, assign 'WUfB - Update Ring - Pilot' to 'WUfB - Ring - Pilot' and" -ForegroundColor Cyan
Write-Host "'WUfB - Update Ring - Broad' to 'WUfB - Ring - Broad' (Implementation Steps 3-4)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
