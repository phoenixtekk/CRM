<#
.SYNOPSIS
    CMG-Discovery.ps1 - Read-only environment-readiness discovery for a Configuration Manager
    Cloud Management Gateway (CMG) deployment.

.DESCRIPTION
    Purpose:
        Reports whether the environment is ready for a CMG: Configuration Manager site version,
        Azure / Cloud Management onboarding, existing CMG service and connection point, management
        point / software update point CMG enablement, and Enhanced HTTP. READ-ONLY: makes no changes.

    How to run:
        1. Run on the site server (or an admin host with the Configuration Manager console installed),
           in an elevated PowerShell session, as a user with Configuration Manager read access.
        2. .\CMG-Discovery.ps1 -SiteCode "ABC"
           (SiteCode optional; auto-detected from the console install if omitted.)

    Expected results:
        A readiness report listing the site version, onboarding state, any existing CMG named
        'CMG - Internet Clients - Pilot', the connection point, MP/SUP CMG flags, and Enhanced HTTP,
        with PASS / REVIEW notes. No objects are created or modified.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SiteCode
)

function Write-Section($Title) { Write-Host "`n=== $Title ===" -ForegroundColor Cyan }

# --- Locate and import the Configuration Manager PowerShell module (ConfigurationManager.psd1) ---
if (-not $env:SMS_ADMIN_UI_PATH) {
    Write-Warning "SMS_ADMIN_UI_PATH not set. Run this on a host with the ConfigMgr console installed."
    return
}
$cmModule = Join-Path (Split-Path $env:SMS_ADMIN_UI_PATH) "ConfigurationManager.psd1"
if (-not (Test-Path $cmModule)) {
    Write-Warning "ConfigurationManager.psd1 not found at $cmModule."
    return
}
Import-Module $cmModule -ErrorAction Stop

# Resolve the site drive
$siteDrive = Get-PSDrive -PSProvider CMSite -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $siteDrive) {
    Write-Warning "No CMSite PS drive found. Open the console once to create the site drive, or map it."
    return
}
if (-not $SiteCode) { $SiteCode = $siteDrive.Name }
Push-Location "$($SiteCode):"

try {
    Write-Section "Configuration Manager site"
    $site = Get-CMSite -ErrorAction SilentlyContinue | Where-Object { $_.SiteCode -eq $SiteCode }
    if ($site) {
        Write-Host ("Site {0} - {1} - Version {2}" -f $site.SiteCode, $site.SiteName, $site.Version)
    } else {
        Write-Host "Could not read site details (check permissions)." -ForegroundColor Yellow
    }

    Write-Section "Azure / Cloud Management onboarding"
    # Cloud Management Azure service onboarding (server/client app registrations live in Entra)
    $azSvc = Get-CMAzureService -ErrorAction SilentlyContinue
    if ($azSvc) {
        $azSvc | ForEach-Object { Write-Host ("Azure service: {0}" -f $_.Name) }
    } else {
        Write-Host "No Cloud Management Azure service found. PASS requires onboarding (Requirement 2.3)." -ForegroundColor Yellow
    }

    Write-Section "Cloud Management Gateway service"
    $cmg = Get-CMCloudManagementGateway -ErrorAction SilentlyContinue
    if ($cmg) {
        $cmg | Select-Object Name, State | Format-Table -AutoSize | Out-String | Write-Host
        if (-not ($cmg.Name -contains 'CMG - Internet Clients - Pilot')) {
            Write-Host "Note: expected pilot CMG name 'CMG - Internet Clients - Pilot' not found." -ForegroundColor Yellow
        }
    } else {
        Write-Host "No CMG deployed yet (expected before Implementation Step 4)." -ForegroundColor Yellow
    }

    Write-Section "CMG connection point"
    $cp = Get-CMCloudManagementGatewayConnectionPoint -ErrorAction SilentlyContinue
    if ($cp) {
        $cp | Select-Object SiteCode, NetworkOSPath | Format-Table -AutoSize | Out-String | Write-Host
    } else {
        Write-Host "No CMG connection point found (expected before Implementation Step 6)." -ForegroundColor Yellow
    }

    Write-Section "MP / SUP CMG enablement (manual confirm)"
    Write-Host "Confirm in console: MP and SUP role properties -> 'Allow Configuration Manager cloud"
    Write-Host "management gateway traffic' is enabled (Implementation Step 7)."

    Write-Section "Enhanced HTTP"
    Write-Host "Confirm in console: Site Properties -> Communication Security -> HTTPS or Enhanced HTTP"
    Write-Host "enabled (Requirement 2.7). Token-based CMG auth depends on it."
}
finally {
    Pop-Location
}

Write-Host "`nDiscovery complete (read-only). Review any yellow items above before deploying." -ForegroundColor Green
