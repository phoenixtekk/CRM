<#
.SYNOPSIS
    COMGMT-Set-CoMgmtPilotTargeting.ps1 — Build the co-management pilot collection membership.

PURPOSE
    Creates (if missing) and populates the Configuration Manager device collection
    'Co-Management - Pilot Collection - Stage 1' with a supplied set of pilot
    devices, using direct membership rules. This is the staged-enrollment scope
    that auto-enrolls into Intune first. Use the exact name from the
    Implementation Guide so the configuration, collection, and device group stay
    traceable.

HOW TO RUN
    Run on the site server (or where the ConfigMgr console / module is installed),
    in an elevated PowerShell session with the ConfigurationManager module loaded
    and the PSDrive set to your site code:
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
        Set-Location '<SiteCode>:'
        .\COMGMT-Set-CoMgmtPilotTargeting.ps1 -SiteCode 'ABC' -ComputerName 'PC1','PC2'
    Preview without changing anything (default):
        .\COMGMT-Set-CoMgmtPilotTargeting.ps1 -SiteCode 'ABC' -ComputerName 'PC1' -WhatIf

EXPECTED RESULTS
    The collection 'Co-Management - Pilot Collection - Stage 1' exists (limited to
    All Systems) and contains the named devices as direct members, ready to be the
    pilot scope when you enable co-management with Pilot auto-enrollment.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [string]$SiteCode,

    [Parameter(Mandatory = $true)]
    [string[]]$ComputerName,

    [string]$CollectionName = 'Co-Management - Pilot Collection - Stage 1',

    [string]$LimitingCollectionName = 'All Systems'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command Get-CMDeviceCollection -ErrorAction SilentlyContinue)) {
    throw 'ConfigurationManager module not loaded. Import ConfigurationManager.psd1 and Set-Location to "<SiteCode>:" first.'
}

# Ensure we are on the site PSDrive.
if ((Get-Location).Provider.Name -ne 'CMSite') {
    Set-Location "$SiteCode`:"
}

# Create the collection if it does not exist.
$collection = Get-CMDeviceCollection -Name $CollectionName -ErrorAction SilentlyContinue
if (-not $collection) {
    if ($PSCmdlet.ShouldProcess($CollectionName, 'Create device collection')) {
        $collection = New-CMDeviceCollection -Name $CollectionName `
            -LimitingCollectionName $LimitingCollectionName `
            -Comment 'Staged co-management pilot scope (Stage 1).'
        Write-Host "Created collection: $CollectionName"
    }
}
else {
    Write-Host "Collection already exists: $CollectionName"
}

# Add each device as a direct member.
foreach ($name in $ComputerName) {
    $device = Get-CMDevice -Name $name -ErrorAction SilentlyContinue
    if (-not $device) {
        Write-Warning "Device not found in ConfigMgr: $name (skipped)."
        continue
    }
    if ($PSCmdlet.ShouldProcess($name, "Add direct membership to $CollectionName")) {
        Add-CMDeviceCollectionDirectMembershipRule `
            -CollectionName $CollectionName `
            -ResourceId $device.ResourceID
        Write-Host "Added direct member: $name"
    }
}

Write-Host ''
Write-Host "Pilot collection '$CollectionName' is ready. Use it as the Pilot scope when enabling co-management."
