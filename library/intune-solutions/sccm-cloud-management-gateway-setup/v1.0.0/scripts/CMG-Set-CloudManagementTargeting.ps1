<#
.SYNOPSIS
    CMG-Set-CloudManagementTargeting.ps1 - Cloud-management settings helper. Scopes the
    cloud-management client settings to the pilot collection so internet clients are allowed to use
    the Cloud Management Gateway (CMG). DEFAULTS TO -WhatIf (no changes unless you opt in).

.DESCRIPTION
    Purpose:
        Deploys (assigns) the custom client settings object 'CMG - Internet Clients - Client Settings'
        to the device collection 'CMG - Internet Clients - Pilot'. That client settings object must
        already exist and have its Cloud Services page configured (Implementation Step 8): "Enable
        clients to use a cloud management gateway = Yes". This script only creates the assignment that
        targets the settings at the collection; it does not enable the CMG itself or change site roles.

    How to run:
        - Preview only (default, recommended first):
              .\CMG-Set-CloudManagementTargeting.ps1
          Shows what it WOULD assign; makes no changes (-WhatIf is on by default).
        - Apply the assignment:
              .\CMG-Set-CloudManagementTargeting.ps1 -Apply `
                  -ClientSettingsName "CMG - Internet Clients - Client Settings" `
                  -CollectionName "CMG - Internet Clients - Pilot"

    Expected results:
        In preview, the intended assignment is printed. With -Apply, the named client settings object
        is deployed to the named collection; clients in that collection then receive the
        cloud-management settings on their next policy cycle. Verify with CMG-Report.ps1 /
        CMG-Validation.ps1.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $false)][switch]$Apply,
    [Parameter(Mandatory = $false)][string]$ClientSettingsName = "CMG - Internet Clients - Client Settings",
    [Parameter(Mandatory = $false)][string]$CollectionName     = "CMG - Internet Clients - Pilot",
    [Parameter(Mandatory = $false)][string]$SiteCode
)

if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) {
    $WhatIfPreference = $true
    Write-Host "Running in preview mode (-WhatIf). Pass -Apply to assign the client settings." -ForegroundColor Yellow
}

if (-not $env:SMS_ADMIN_UI_PATH) { Write-Warning "Run on a host with the ConfigMgr console installed."; return }
$cmModule = Join-Path (Split-Path $env:SMS_ADMIN_UI_PATH) "ConfigurationManager.psd1"
if (-not (Test-Path $cmModule)) { Write-Warning "ConfigurationManager.psd1 not found."; return }
Import-Module $cmModule -ErrorAction Stop

$siteDrive = Get-PSDrive -PSProvider CMSite -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $siteDrive) { Write-Warning "No CMSite PS drive found. Open the console once."; return }
if (-not $SiteCode) { $SiteCode = $siteDrive.Name }
Push-Location "$($SiteCode):"

try {
    # Validate prerequisites (read-only checks)
    $cs = Get-CMClientSetting -Name $ClientSettingsName -ErrorAction SilentlyContinue
    if (-not $cs) {
        Write-Warning "Client settings '$ClientSettingsName' not found. Create/configure it first (Implementation Step 8)."
        return
    }
    $coll = Get-CMDeviceCollection -Name $CollectionName -ErrorAction SilentlyContinue
    if (-not $coll) {
        Write-Warning "Collection '$CollectionName' not found. Create it first (Implementation Step 2)."
        return
    }

    Write-Host "Client settings : $ClientSettingsName" -ForegroundColor Cyan
    Write-Host "Target collection: $CollectionName"   -ForegroundColor Cyan

    if ($PSCmdlet.ShouldProcess($CollectionName, "Deploy client settings '$ClientSettingsName'")) {
        try {
            # Assign the existing, already-configured client settings to the pilot collection.
            Start-CMClientSettingDeployment -ClientSettingName $ClientSettingsName -CollectionName $CollectionName -ErrorAction Stop
            Write-Host "Assigned '$ClientSettingsName' to '$CollectionName'." -ForegroundColor Green
        } catch {
            Write-Warning "Assignment failed: $($_.Exception.Message)"
        }
    }
}
finally {
    Pop-Location
}

if ($WhatIfPreference) {
    Write-Host "`nPreview complete. No changes were made. Re-run with -Apply to assign." -ForegroundColor Yellow
} else {
    Write-Host "`nDone. Allow a policy cycle, then verify with CMG-Report.ps1 / CMG-Validation.ps1." -ForegroundColor Green
}
