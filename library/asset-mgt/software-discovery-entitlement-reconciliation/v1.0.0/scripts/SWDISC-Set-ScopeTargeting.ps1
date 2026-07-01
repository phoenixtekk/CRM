<#
.SYNOPSIS
    SWDISC-Set-ScopeTargeting.ps1 — create/confirm the pilot "Discovery Scope Group - Pilot Source - Pilot".
.DESCRIPTION
    PURPOSE
        Bounds the reconciliation pilot to one discovery source / one product family by ensuring an
        Entra ID security group exists to target the pilot devices, and records the chosen source and
        (optional) product family for the pipeline. Other scripts read this scope when running the
        pilot before fleet-wide reconciliation.
        Creating the group is the only write; pass -WhatIf to preview. Membership is left to your
        standard group-assignment process (manual or dynamic membership rule) so this script does not
        guess device membership.
    HOW TO RUN
        Preview : powershell -ExecutionPolicy Bypass -File .\SWDISC-Set-ScopeTargeting.ps1 `
                      -PilotSource Intune -ProductFamily "Adobe Acrobat" -WhatIf
        Create  : powershell -ExecutionPolicy Bypass -File .\SWDISC-Set-ScopeTargeting.ps1 `
                      -PilotSource Intune -ProductFamily "Adobe Acrobat"
        Requires Microsoft Graph SDK and Group.ReadWrite.All to create the group.
    EXPECTED RESULTS
        Confirms (or creates) the security group "Discovery Scope Group - Pilot Source - Pilot" and
        prints the group id plus the recorded pilot source / product family. Add members via your
        normal process, then run SWDISC-Discovery.ps1 against the pilot source.
.NOTES
    Workplace Marketplace — Asset Mgt. The only write is creating the Entra group (honors -WhatIf).
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory)][ValidateSet('Intune','ConfigMgr','Flexera')][string]$PilotSource,
    [string]$ProductFamily,
    [string]$GroupName = "Discovery Scope Group - Pilot Source - Pilot"
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

Write-Host "=== Pilot scope ===" -ForegroundColor Cyan
Write-Host ("Source         : {0}" -f $PilotSource)
Write-Host ("Product family : {0}" -f ($(if($ProductFamily){$ProductFamily}else{'(all products in source)'})))
Write-Host ("Group name     : {0}" -f $GroupName)

$filter = "displayName eq '$($GroupName.Replace("'","''"))'"
$existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$([uri]::EscapeDataString($filter))").value

if ($existing) {
    $g = $existing | Select-Object -First 1
    Write-Host ("Group already exists. id: {0}" -f $g.id) -ForegroundColor Green
}
else {
    if ($PSCmdlet.ShouldProcess($GroupName, "Create Entra security group")) {
        $mailNick = ($GroupName -replace '[^a-zA-Z0-9]','').ToLower()
        $body = @{
            displayName     = $GroupName
            description     = "Discovery pilot scope — source: $PilotSource; product family: $ProductFamily"
            mailEnabled     = $false
            mailNickname    = $mailNick
            securityEnabled = $true
        }
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("Created group. id: {0}" -f $g.id) -ForegroundColor Green
    }
    else {
        Write-Host "Preview only (-WhatIf): group would be created." -ForegroundColor Yellow
    }
}

Write-Host "`nNext: add the pilot devices to this group via your normal assignment process," -ForegroundColor Cyan
Write-Host "then run SWDISC-Discovery.ps1 -Source $PilotSource to build the pilot inventory." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
