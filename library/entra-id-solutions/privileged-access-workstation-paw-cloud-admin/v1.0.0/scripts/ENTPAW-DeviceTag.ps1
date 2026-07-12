<#
.SYNOPSIS
    ENTPAW-DeviceTag.ps1 — safely set the PAW marker (extensionAttribute1 = PAW) on named pilot devices.
.DESCRIPTION
    PURPOSE
        Marks a device as a PAW by setting an Entra device extension attribute (default
        extensionAttribute1 = PAW) so the Conditional Access device filter can recognise it. Runs in
        -WhatIf (preview) mode by default and only touches the devices you name, so the marker stays
        reserved for genuine PAWs. Can also clear the marker (-Remove) to decommission a PAW.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\ENTPAW-DeviceTag.ps1 `
            -DeviceNames "PAW-ADM-01","PAW-ADM-02"
        Apply: add -WhatIf:$false after reviewing the preview.
        Remove marker: add -Remove (also -WhatIf by default).
        Requires the Microsoft Graph PowerShell SDK. Scope: Device.ReadWrite.All.
    EXPECTED RESULTS
        A preview (or applied change) setting/clearing the marker on exactly the named devices. Re-run
        ENTPAW-Validate.ps1 afterward to confirm the device filter resolves to the PAW set.
.NOTES
    White-label — Entra ID Solutions. Changes a device attribute — preview first, reserve the marker for PAWs only.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)][string[]]$DeviceNames,
    [string]$MarkerAttribute = 'extensionAttribute1',
    [string]$MarkerValue = 'PAW',
    [switch]$Remove
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Device.ReadWrite.All' -NoWelcome
$val = if ($Remove) { $null } else { $MarkerValue }
Write-Host "=== ENTPAW DeviceTag — set $MarkerAttribute=$(if($Remove){'<null>'}else{$MarkerValue}) on $($DeviceNames.Count) device(s) ===" -ForegroundColor Cyan

foreach ($name in $DeviceNames) {
    $enc = [uri]::EscapeDataString($name)
    $dev = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices?`$filter=displayName eq '$enc'&`$select=id,displayName,extensionAttributes").value | Select-Object -First 1
    if (-not $dev) { Write-Host "  NOT FOUND: $name" -ForegroundColor Yellow; continue }
    $current = $dev.extensionAttributes.$MarkerAttribute
    if ($PSCmdlet.ShouldProcess($name, "Set $MarkerAttribute to '$val' (was '$current')")) {
        $body = @{ extensionAttributes = @{ $MarkerAttribute = $val } } | ConvertTo-Json
        Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/devices/$($dev.id)" -Body $body | Out-Null
        Write-Host "  APPLIED: $name  $MarkerAttribute='$val' (was '$current')" -ForegroundColor Green
    } else {
        Write-Host "  WHATIF would set $name  $MarkerAttribute='$val' (was '$current')" -ForegroundColor Yellow
    }
}
Write-Host "`nReserve this marker for PAWs only. Re-run ENTPAW-Validate.ps1 to confirm the filter set." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
