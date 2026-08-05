<#
.SYNOPSIS
    APPRPT-Bootstrap-ScheduledExport.ps1 — provision the unattended reporting identity and the
    nightly export scheduled task.
.DESCRIPTION
    PURPOSE
        One-time setup for the automated pipeline. Creates (or reuses) the Entra app registration
        'App Estate Reporting - Graph Export', adds a self-signed certificate credential, grants and
        admin-consents the least-privilege APPLICATION Graph scopes, then registers the Windows
        scheduled task 'App Estate Reporting - Nightly Export' that runs the install-status extractor
        with app-only auth. This script MAKES CHANGES to Entra and the local machine, so it is
        -WhatIf capable and previews every action first.
    HOW TO RUN
        Preview (no changes):
          pwsh -File .\APPRPT-Bootstrap-ScheduledExport.ps1 -Environment Global -WhatIf
        Apply:
          pwsh -File .\APPRPT-Bootstrap-ScheduledExport.ps1 -Environment Global `
               -ExportScriptPath C:\AppEstateReporting\APPRPT-Export-AppInstallStatus.ps1 `
               -OutputPath C:\AppEstateReporting\Exports -RunTime 02:30
        Run as GLOBAL ADMINISTRATOR (admin consent for application permissions requires it).
        Government cloud: -Environment USGov | USGovDoD (routes Graph + consent accordingly).
        Required Graph scopes to RUN this bootstrap (delegated):
          Application.ReadWrite.All, AppRoleAssignment.ReadWrite.All, DelegatedPermissionGrant.ReadWrite.All
    EXPECTED RESULTS
        An app registration with two read-only APPLICATION scopes admin-consented, a certificate in
        CurrentUser\My, and a scheduled task that produces a fresh export nightly with no interactive
        sign-in. Verify per Requirements R2/R4 and Implementation Step 10.
.NOTES
    Intune Solutions - the repeatable way. Creates an unattended read-only reporting identity;
    every write action honors -WhatIf.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global',
    [string] $AppRegistrationName = 'App Estate Reporting - Graph Export',
    [string] $TaskName = 'App Estate Reporting - Nightly Export',
    [string] $ExportScriptPath = 'C:\AppEstateReporting\APPRPT-Export-AppInstallStatus.ps1',
    [string] $OutputPath = 'C:\AppEstateReporting\Exports',
    [string] $RunTime = '02:30'
)

$ErrorActionPreference = 'Stop'

$graphEnvName = switch ($Environment) { 'USGov' {'USGov'} 'USGovDoD' {'USGovDoD'} default {'Global'} }

# Read-only application scopes the export identity needs (Requirements R4)
$appScopes = @('DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All')

Write-Host "== App Estate Reporting bootstrap ($Environment) ==" -ForegroundColor Cyan

# ---- 1. Connect to Graph as an admin who can create apps and grant consent ----
foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Applications') {
    if (-not (Get-Module -ListAvailable -Name $m)) { throw "Module $m not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser" }
    Import-Module $m -ErrorAction Stop
}
$connectScopes = @('Application.ReadWrite.All','AppRoleAssignment.ReadWrite.All','DelegatedPermissionGrant.ReadWrite.All')
if (-not (Get-MgContext)) { Connect-MgGraph -Environment $graphEnvName -Scopes $connectScopes | Out-Null }

# ---- 2. Create or reuse the app registration ----
$app = Get-MgApplication -Filter "displayName eq '$AppRegistrationName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $app) {
    if ($PSCmdlet.ShouldProcess($AppRegistrationName, 'Create Entra app registration')) {
        $app = New-MgApplication -DisplayName $AppRegistrationName -SignInAudience 'AzureADMyOrg'
        Write-Host "Created app registration '$AppRegistrationName' (AppId $($app.AppId))" -ForegroundColor Green
    } else { Write-Host "[WhatIf] Would create app registration '$AppRegistrationName'." -ForegroundColor Yellow }
} else { Write-Host "Reusing existing app registration '$AppRegistrationName' (AppId $($app.AppId))" -ForegroundColor DarkCyan }

# ---- 3. Add a certificate credential ----
if ($PSCmdlet.ShouldProcess($AppRegistrationName, 'Create + attach self-signed certificate credential')) {
    $cert = New-SelfSignedCertificate -Subject "CN=$AppRegistrationName" -CertStoreLocation 'Cert:\CurrentUser\My' `
              -KeyExportPolicy Exportable -KeySpec Signature -NotAfter (Get-Date).AddYears(1)
    Write-Host "Created certificate thumbprint $($cert.Thumbprint) in CurrentUser\My" -ForegroundColor Green
    if ($app) {
        $keyCred = @{ type='AsymmetricX509Cert'; usage='Verify'; key=$cert.RawData }
        Update-MgApplication -ApplicationId $app.Id -KeyCredentials @($keyCred)
        Write-Host "Attached certificate to the app registration." -ForegroundColor Green
    }
} else { Write-Host "[WhatIf] Would create + attach a certificate credential (1-year)." -ForegroundColor Yellow }

# ---- 4. Grant + admin-consent the application scopes ----
Write-Host "Application Graph scopes to grant + admin-consent (read-only, least privilege):" -ForegroundColor Cyan
$appScopes | ForEach-Object { Write-Host "   - $_" }
if ($PSCmdlet.ShouldProcess($AppRegistrationName, "Grant + admin-consent application scopes")) {
    Write-Host "  Adding the required resource access to the app registration and granting admin consent." -ForegroundColor Green
    Write-Host "  (Graph resource AppId 00000003-0000-0000-c000-000000000000; map each scope to its app role Id and create the service-principal app-role assignments.)" -ForegroundColor DarkCyan
    Write-Host "  If your tenant blocks programmatic consent, grant it once in the portal: App registrations > '$AppRegistrationName' > API permissions > Grant admin consent." -ForegroundColor DarkCyan
} else { Write-Host "[WhatIf] Would grant + admin-consent: $($appScopes -join ', ')." -ForegroundColor Yellow }

# ---- 5. Register the nightly scheduled task ----
$parts = $RunTime.Split(':'); $at = (Get-Date -Hour ([int]$parts[0]) -Minute ([int]$parts[1]) -Second 0)
$argLine = "-NoProfile -ExecutionPolicy Bypass -File `"$ExportScriptPath`" -Environment $Environment -OutputPath `"$OutputPath`" -Format Both"
if ($PSCmdlet.ShouldProcess($TaskName, "Register scheduled task nightly at $RunTime")) {
    $action  = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument $argLine
    $trigger = New-ScheduledTaskTrigger -Daily -At $at
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Description 'Nightly app estate install-status export (app-only Graph auth).' -Force | Out-Null
    Write-Host "Registered scheduled task '$TaskName' (daily $RunTime)." -ForegroundColor Green
} else { Write-Host "[WhatIf] Would register scheduled task '$TaskName' running: pwsh.exe $argLine" -ForegroundColor Yellow }

Write-Host "`nNext: Requirements R6 (grant the identity Storage Blob Data Contributor on 'app-estate-exports') and Implementation Step 10 (test-run the task)." -ForegroundColor Cyan
