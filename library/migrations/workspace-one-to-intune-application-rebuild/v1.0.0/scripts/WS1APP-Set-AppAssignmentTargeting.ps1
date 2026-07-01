<#
.SYNOPSIS
    WS1APP-Set-AppAssignmentTargeting.ps1 — create the pilot/broad app-assignment Entra groups.
.DESCRIPTION
    PURPOSE
        Builds the ring-targeting Microsoft Entra security groups used to assign rebuilt apps, named
        with the <Purpose> - <Scope> - <Stage> convention so they match the Implementation Guide:
            App Rebuild - Pilot Devices - Ring 1
            App Rebuild - Broad Devices - Ring 2
            App Rebuild - Pilot Users  - Ring 1
            App Rebuild - Broad Users  - Ring 2
        It only CREATES the groups (idempotent: skips any that already exist). Adding members and
        attaching app assignments are done deliberately in the Intune console per the guide.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\WS1APP-Set-AppAssignmentTargeting.ps1
        Execute          : powershell -ExecutionPolicy Bypass -File .\WS1APP-Set-AppAssignmentTargeting.ps1 -WhatIf:$false
        Requires the Microsoft Graph SDK and Group.ReadWrite.All.
    EXPECTED RESULTS
        The four ring groups exist in Entra (created if missing, reported if already present).
.NOTES
    Workplace Marketplace — Migrations. Creates groups only; assignment is done in the console.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

$groups = @(
    'App Rebuild - Pilot Devices - Ring 1',
    'App Rebuild - Broad Devices - Ring 2',
    'App Rebuild - Pilot Users - Ring 1',
    'App Rebuild - Broad Users - Ring 2'
)

Write-Host "=== App-assignment ring groups ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "(preview mode — pass -WhatIf:`$false to create)" -ForegroundColor Yellow }

foreach ($name in $groups) {
    $filter   = "displayName eq '$($name.Replace("'","''"))'"
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$([uri]::EscapeDataString($filter))").value
    if ($existing) {
        Write-Host ("  exists : {0}" -f $name) -ForegroundColor Green
        continue
    }
    if ($PSCmdlet.ShouldProcess($name, 'Create Entra security group')) {
        $mailNick = ($name -replace '[^A-Za-z0-9]', '')
        $body = @{
            displayName     = $name
            mailEnabled     = $false
            mailNickname    = $mailNick
            securityEnabled = $true
        }
        Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json) | Out-Null
        Write-Host ("  created: {0}" -f $name) -ForegroundColor Green
    }
}

Write-Host "`nNext: add members, then assign rebuilt apps to these groups in Intune (Implementation Steps 11–13)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
