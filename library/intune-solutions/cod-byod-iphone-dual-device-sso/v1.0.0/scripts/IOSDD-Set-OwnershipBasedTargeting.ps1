<#
.SYNOPSIS
    Set-OwnershipBasedTargeting.ps1 — create the Corporate & Personal device filters.

.DESCRIPTION
    PURPOSE
        Creates the two Intune assignment filters on `deviceOwnership` that make "one account, both
        device types" work: a Corporate filter (routes full-MDM policy to company devices) and a
        Personal filter (keeps corporate device policy off BYOD). Idempotent — skips a filter that
        already exists.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\Set-OwnershipBasedTargeting.ps1 -WhatIf      # preview
        .\Set-OwnershipBasedTargeting.ps1              # create

    EXPECTED RESULTS
        Two filters — "Corporate Devices" and "Personal Devices" — exist in Tenant administration →
        Filters. Apply them as the Include filter on your compliance/config (Corporate) and
        app-protection (Personal) assignments.

.NOTES
    White-label — Intune Solutions. Creates assignment filters; supports -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('windows10AndLater','iOS','android','macOS','androidForWork','unknown')]
    [string]$Platform = 'windows10AndLater'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

$base = 'https://graph.microsoft.com/beta/deviceManagement/assignmentFilters'
$existing = @((Invoke-MgGraphRequest -Method GET -Uri $base).value)

$wanted = @(
    @{ name = 'Corporate Devices'; rule = '(device.deviceOwnership -eq "Corporate")' },
    @{ name = 'Personal Devices';  rule = '(device.deviceOwnership -eq "Personal")'  }
)

foreach ($w in $wanted) {
    if ($existing | Where-Object { $_.displayName -eq $w.name }) {
        Write-Host "SKIP  '$($w.name)' already exists." -ForegroundColor Yellow
        continue
    }
    if ($PSCmdlet.ShouldProcess($w.name, "Create assignment filter ($Platform)")) {
        $body = @{
            displayName = $w.name
            description = 'Created by Set-OwnershipBasedTargeting.ps1'
            platform    = $Platform
            rule        = $w.rule
        } | ConvertTo-Json
        $created = Invoke-MgGraphRequest -Method POST -Uri $base -Body $body -ContentType 'application/json'
        Write-Host "Created filter '$($created.displayName)' (id $($created.id))." -ForegroundColor Green
    }
}

Write-Host ''
Write-Host 'Next: set "Corporate Devices" as the Include filter on COD compliance/config assignments,' -ForegroundColor Green
Write-Host 'and "Personal Devices" where you need to scope BYOD-specific items. (App Protection is user-targeted.)' -ForegroundColor Green
