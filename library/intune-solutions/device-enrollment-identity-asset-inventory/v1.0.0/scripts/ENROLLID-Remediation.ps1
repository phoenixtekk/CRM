<#
.SYNOPSIS
    ENROLLID-Remediation.ps1 — safely fix a device's primary user or retire a stale record (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Applies a targeted correction: set/clear a device's primary user, or retire a confirmed stale
        record. Runs in preview (-WhatIf) by default so nothing changes until you review the planned
        action and re-run with -WhatIf:$false.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\ENROLLID-Remediation.ps1 -DeviceName PC-001 -SetPrimaryUser user@contoso.com
        Clear (shared):     ... -DeviceName KIOSK-01 -ClearPrimaryUser
        Retire stale:       ... -DeviceName OLD-PC -RetireStale
        Commit a change:    add  -WhatIf:$false
        Requires the Microsoft Graph SDK and DeviceManagementManagedDevices.ReadWrite.All.
    EXPECTED RESULTS
        With -WhatIf (default) it prints the action it WOULD take. With -WhatIf:$false it performs the
        single targeted fix and confirms it.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Makes changes ONLY when run with -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)] [string]$DeviceName,
    [string]$SetPrimaryUser,
    [switch]$ClearPrimaryUser,
    [switch]$RetireStale
)
if (-not $SetPrimaryUser -and -not $ClearPrimaryUser -and -not $RetireStale) { throw 'Choose one action: -SetPrimaryUser, -ClearPrimaryUser, or -RetireStale.' }
# Preview by default: unless the caller explicitly passes -WhatIf:$false, treat the run as -WhatIf.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true; Write-Host "(preview mode — re-run with -WhatIf:`$false to apply)" -ForegroundColor DarkGray }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.ReadWrite.All','User.Read.All' -NoWelcome
$enc = [uri]::EscapeDataString($DeviceName)
$dev = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '$enc'").value | Select-Object -First 1
if (-not $dev) { Write-Host "No managed device named '$DeviceName'." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
$id = $dev.id
Write-Host "=== ENROLLID Remediation — $DeviceName ===" -ForegroundColor Cyan
if ($SetPrimaryUser) {
    $u = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$([uri]::EscapeDataString($SetPrimaryUser))")
    if ($PSCmdlet.ShouldProcess($DeviceName, "Set primary user to $SetPrimaryUser")) {
        $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/users/$($u.id)" } | ConvertTo-Json
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/deviceManagement/managedDevices/$id/users/`$ref" -Body $body -ContentType 'application/json'
        Write-Host "  Primary user set to $SetPrimaryUser." -ForegroundColor Green
    }
}
elseif ($ClearPrimaryUser) {
    if ($PSCmdlet.ShouldProcess($DeviceName, "Clear primary user (set to None)")) {
        try { Invoke-MgGraphRequest -Method DELETE -Uri "/v1.0/deviceManagement/managedDevices/$id/users/`$ref" } catch {}
        Write-Host "  Primary user cleared (None)." -ForegroundColor Green
    }
}
elseif ($RetireStale) {
    if ($PSCmdlet.ShouldProcess($DeviceName, "Retire stale managed device record")) {
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/deviceManagement/managedDevices/$id/retire"
        Write-Host "  Retire requested for $DeviceName." -ForegroundColor Green
    }
}
Write-Host "`nRe-run ENROLLID-Validation.ps1 -DeviceName $DeviceName to confirm." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
