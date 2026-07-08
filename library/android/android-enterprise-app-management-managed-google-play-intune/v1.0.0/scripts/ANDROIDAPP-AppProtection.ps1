<#
.SYNOPSIS
    ANDROIDAPP-AppProtection.ps1 — list Android app protection (APP/MAM) policies, or stage a baseline one (read/-WhatIf by default, Graph).
.DESCRIPTION
    PURPOSE
        Reports Android managed app protection policies and their app/group assignments (read mode). With
        -Commit it creates a conservative BASELINE Android APP policy (PIN required, encrypt org data,
        block copy/paste + save-as to personal locations) that you then assign in Intune — a safe
        starting point to harden.
    HOW TO RUN
        Report:  powershell -ExecutionPolicy Bypass -File .\ANDROIDAPP-AppProtection.ps1
        Preview: ...same... -Name "ANDROIDAPP Baseline" -WhatIf
        Create:  ...same... -Name "ANDROIDAPP Baseline" -Commit
        Requires the Microsoft Graph SDK; read uses DeviceManagementApps.Read.All, -Commit needs DeviceManagementApps.ReadWrite.All.
    EXPECTED RESULTS
        A list of existing Android APP policies + assignments; with -Commit, a new unassigned baseline
        policy exists. PASS = the target apps have an APP policy enforcing your data controls.
.NOTES
    White-label — Android Solutions. Read/-WhatIf by default; creates only with -Commit. Assign in Intune after review. No credentials stored.
.EXAMPLE
    .\ANDROIDAPP-AppProtection.ps1 -WhatIf
#>
[CmdletBinding()]
param(
    [string]$Name = 'ANDROIDAPP Baseline (review before assigning)',
    [switch]$Commit,
    [switch]$WhatIf
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Commit) { 'DeviceManagementApps.ReadWrite.All' } else { 'DeviceManagementApps.Read.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome

# Report existing Android app protection policies + assignments.
Write-Host "`n=== Android app protection (APP) policies ===" -ForegroundColor Cyan
$pols = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/androidManagedAppProtections?`$expand=assignments").value
if (-not $pols) { Write-Host "(none found)" -ForegroundColor Yellow }
foreach ($p in $pols) {
    $groups = ($p.assignments | ForEach-Object { $_.target.groupId } | Where-Object { $_ }) -join ', '
    Write-Host ("POLICY: {0}  [PIN={1} encrypt={2} deployed-apps={3} groups={4}]" -f `
        $p.displayName, $p.pinRequired, $p.encryptAppData, $p.deployedAppCount, $(if ($groups) { $groups } else { '(unassigned)' })) -ForegroundColor Cyan
}

# Conservative baseline body (create only).
$body = @{
    '@odata.type'                 = '#microsoft.graph.androidManagedAppProtection'
    displayName                   = $Name
    description                   = 'Baseline Android app protection — review and assign in Intune before production.'
    pinRequired                   = $true
    encryptAppData                = $true
    allowedInboundDataTransferSources    = 'managedApps'
    allowedOutboundDataTransferDestinations = 'managedApps'
    allowedOutboundClipboardSharingLevel = 'managedAppsWithPasteIn'
    saveAsBlocked                 = $true
    disableAppEncryptionIfDeviceEncryptionIsEnabled = $false
    minimumPinLength              = 6
}

if ($Commit -and -not $WhatIf) {
    $created = Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceAppManagement/androidManagedAppProtections" -Body ($body | ConvertTo-Json -Depth 6)
    Write-Host ("`nCOMMIT: created baseline APP policy '{0}' (id {1}). Add target apps + assign a group in Intune." -f $created.displayName, $created.id) -ForegroundColor Green
} else {
    Write-Host "`n-WhatIf/report: no policy created. Re-run with -Commit to create the baseline (PIN, encrypt, block save-as, managed-apps-only transfer), then add apps + assign in Intune." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null
