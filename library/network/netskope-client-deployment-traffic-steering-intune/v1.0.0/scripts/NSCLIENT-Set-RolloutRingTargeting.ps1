<#
.SYNOPSIS
    NSCLIENT-Set-RolloutRingTargeting.ps1 — build/preview the rollout-ring Entra groups (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Creates (or previews) the Entra security groups that the ringed Netskope client rollout is
        assigned to: Device Group - Pilot - Stage1, Device Group - Early - Stage2,
        Device Group - Broad - Stage3. Defaults to -WhatIf: it PREVIEWS and changes nothing unless you
        pass -Apply. It does not move members between rings; it ensures the ring groups exist.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\NSCLIENT-Set-RolloutRingTargeting.ps1
        Apply (create groups that are missing): powershell -ExecutionPolicy Bypass -File .\NSCLIENT-Set-RolloutRingTargeting.ps1 -Apply
        Requires the Microsoft Graph PowerShell SDK and Group.ReadWrite.All (preview needs only Group.Read.All).
    EXPECTED RESULTS
        A report of which ring groups exist; with -Apply, any missing ring group is created.
.NOTES
    Network Solutions. Default is -WhatIf (preview). Assigning these groups to the client app and the
    certificate profile is done in the Intune portal per the Implementation Guide.
#>
[CmdletBinding()]
param(
    [switch]$Apply  # without this, the script previews and creates nothing
)
$WhatIf = -not $Apply

$rings = @(
    'Device Group - Pilot - Stage1',
    'Device Group - Early - Stage2',
    'Device Group - Broad - Stage3'
)

$scope = if ($WhatIf) { 'Group.Read.All' } else { 'Group.ReadWrite.All' }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes $scope -NoWelcome

Write-Host "=== Rollout-ring groups ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if($WhatIf){'PREVIEW (-WhatIf) — no changes'}else{'APPLY'}))) -ForegroundColor ($(if($WhatIf){'Yellow'}else{'Green'}))

foreach ($name in $rings) {
    $enc = [uri]::EscapeDataString($name)
    $found = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$enc'").value | Select-Object -First 1
    if ($found) {
        Write-Host ("  EXISTS : {0}  (id {1})" -f $name, $found.id) -ForegroundColor Green
    } elseif ($WhatIf) {
        Write-Host ("  WOULD CREATE : {0}" -f $name) -ForegroundColor DarkGray
    } else {
        $mailNick = ($name -replace '[^a-zA-Z0-9]','')
        $body = @{
            displayName     = $name
            description     = 'Netskope client rollout ring (created by NSCLIENT-Set-RolloutRingTargeting.ps1)'
            mailEnabled     = $false
            mailNickname    = $mailNick
            securityEnabled = $true
        }
        try {
            $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
            Write-Host ("  CREATED : {0}  (id {1})" -f $name, $new.id) -ForegroundColor Green
        } catch {
            Write-Host ("  FAILED  : {0} — {1}" -f $name, $_.Exception.Message) -ForegroundColor Yellow
        }
    }
}

Write-Host "`nNext: assign these groups to 'Netskope Client - Windows - Production' and the certificate profile (Intune portal)." -ForegroundColor Green
if ($WhatIf) { Write-Host "Re-run with -Apply to create any missing ring groups." -ForegroundColor Yellow }

Disconnect-MgGraph | Out-Null
