<#
.SYNOPSIS
    CFAPG-Remediation.ps1 — safely fix the most common GCC High provisioning misconfig.
.DESCRIPTION
    PURPOSE
        Connects to Microsoft Graph US Gov and remediates the top failure of Autopilot
        device preparation on a GCC High / DoD tenant: the Intune Provisioning Client
        service principal not being an OWNER of the assigned device group (which leaves
        the group empty during OOBE so nothing deploys). Runs in preview mode by default
        (-WhatIf) and only makes a change when you pass -WhatIf:$false. Placeholders use
        hyphenated names such as your-tenant-id and your-device-group-name.
    HOW TO RUN
        Preview (no change):
          powershell -ExecutionPolicy Bypass -File .\CFAPG-Remediation.ps1
        Apply the fix:
          powershell -ExecutionPolicy Bypass -File .\CFAPG-Remediation.ps1 -WhatIf:$false
        (Graph scopes; -Environment USGov)
        Scopes requested: Group.ReadWrite.All, Application.Read.All, Directory.Read.All
    EXPECTED RESULTS
        Preview prints the intended action and makes no change. Apply adds the Provisioning
        Client as owner and confirms. PASS when ownership is present afterward; re-run
        CFAPG-Validation.ps1 to confirm.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints
    except the single, explicit owner-add performed only when -WhatIf:$false is passed.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$TenantId,
    [ValidateSet('USGov','USGovDoD')]
    [string]$Environment = 'USGov',
    [string]$DeviceGroupName = 'CFAPG-Autopilot-Devices',
    [string]$ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c',
    # Default to preview. Pass -WhatIf:$false to actually apply the change.
    [switch]$WhatIf = $true
)

$ErrorActionPreference = 'Stop'
$baseUri = 'https://graph.microsoft.us/beta'

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$connect = @{ Environment = $Environment; Scopes = @('Group.ReadWrite.All','Application.Read.All','Directory.Read.All') }
if ($TenantId) { $connect['TenantId'] = $TenantId }
Connect-MgGraph @connect | Out-Null
$ctx = Get-MgContext
Write-Host ("Connected. Environment = {0} | Tenant = {1}" -f $ctx.Environment, $ctx.TenantId) -ForegroundColor Cyan
if ($ctx.Environment -notmatch 'USGov') { throw "Connected environment is not US Gov. Refusing to run against a non-GCC-High cloud." }

$mode = if ($WhatIf) { 'PREVIEW (-WhatIf)' } else { 'APPLY' }
Write-Host ("Mode: {0}" -f $mode) -ForegroundColor Yellow

# Resolve the device group
$esc = [uri]::EscapeDataString($DeviceGroupName)
$dg = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/groups?`$filter=displayName eq '$esc'&`$select=id,displayName,membershipRule").value | Select-Object -First 1
if (-not $dg) { throw "Device group '$DeviceGroupName' not found. Create it first (03-implementation Step 1)." }
if ($dg.membershipRule) { Write-Warning "Group '$DeviceGroupName' is DYNAMIC. Enrollment Time Grouping requires an ASSIGNED group. Recreate it as Assigned; owner-add will not fix a dynamic group." }

# Resolve the Provisioning Client service principal
$sp = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/servicePrincipals?`$filter=appId eq '$ProvisioningClientAppId'&`$select=id,displayName,appId").value | Select-Object -First 1
if (-not $sp) { throw "Intune Provisioning Client ($ProvisioningClientAppId) not found. Open intune.microsoft.us once as Global Admin to provision it, then re-run (R6)." }

# Is it already an owner?
$owners = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/groups/$($dg.id)/owners?`$select=id").value
$already = @($owners | Where-Object { $_.id -eq $sp.id }).Count -gt 0

if ($already) {
    Write-Host ("No action needed: '{0}' already owns '{1}'." -f $sp.displayName, $dg.displayName) -ForegroundColor Green
    return
}

$action = "Add owner '$($sp.displayName)' ($($sp.appId)) to group '$($dg.displayName)'"
if ($WhatIf) {
    Write-Host ("[PREVIEW] Would: {0}" -f $action) -ForegroundColor Magenta
    Write-Host "Re-run with -WhatIf:`$false to apply." -ForegroundColor Magenta
    return
}

if ($PSCmdlet.ShouldProcess($dg.displayName, $action)) {
    $body = @{ '@odata.id' = "https://graph.microsoft.us/v1.0/directoryObjects/$($sp.id)" }
    Invoke-MgGraphRequest -Method POST -Uri "$baseUri/groups/$($dg.id)/owners/`$ref" -Body ($body | ConvertTo-Json)
    Write-Host ("[APPLIED] {0}" -f $action) -ForegroundColor Green
    Write-Host "Re-run CFAPG-Validation.ps1 to confirm the owner check now passes." -ForegroundColor Cyan
}
