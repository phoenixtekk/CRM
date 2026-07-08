<#
.SYNOPSIS
    ANDROIDDX-BindingHealth.ps1 — read-only health check of the managed Google Play binding / connector.
.DESCRIPTION
    PURPOSE
        Reads the Android Enterprise (managed Google Play) connection settings from Microsoft Graph and
        reports the binding model, bind status, binding owner account, last app-sync time and status,
        and which device-management enrollment paths are enabled. Produces the
        'Binding Health - Android - Baseline' artifact. Read-only — it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ANDROIDDX-BindingHealth.ps1 -StaleHours 48
        Requires the Microsoft Graph PowerShell SDK and the read scope DeviceManagementServiceConfig.Read.All
        (DeviceManagementConfiguration.Read.All also accepted by some tenants).
    EXPECTED RESULTS
        bindStatus='bound' and a recent successful app sync = a healthy connector. 'notBound',
        'bindError', a missing owner account, or a stale/failed sync are the root cause behind
        binding/connector errors and app-delivery failures — take that node in the Diagnostic Playbook.
.NOTES
    Android. Read-only against Microsoft Graph (beta resource).
    The androidManagedStoreAccountEnterpriseSettings resource is beta and evolving with the AMAPI
    transition — verify property names against current Microsoft Graph documentation for your tenant.
#>
[CmdletBinding()] param(
    [int]$StaleHours = 48,
    [string]$JsonPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All' -NoWelcome

Write-Host "=== Managed Google Play binding health ===" -ForegroundColor Cyan
try {
    $b = Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings"
} catch {
    Write-Host ("FAILED to read binding settings: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host "If this 404s, the managed Google Play connection has never been created — bind it in Intune > Devices > Android > Android enterprise (Global Admin, one-time consent)." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; return
}

$ageH = $null
if ($b.lastAppSyncDateTime) { $ageH = [math]::Round(((Get-Date).ToUniversalTime() - ([datetime]$b.lastAppSyncDateTime).ToUniversalTime()).TotalHours,1) }

$report = [ordered]@{
    BindStatus                          = $b.bindStatus
    OwnerUserPrincipalName              = $b.ownerUserPrincipalName
    LastAppSyncDateTime                 = $b.lastAppSyncDateTime
    LastAppSyncStatus                   = $b.lastAppSyncStatus
    LastAppSyncAgeHours                 = $ageH
    DeviceOwnerManagementEnabled        = $b.deviceOwnerManagementEnabled
    AndroidDeviceOwnerFullyManaged      = $b.androidDeviceOwnerFullyManagedEnrollmentEnabled
    DedicatedDevicesAllowed             = $b.dedicatedDevicesAllowed
    CompanyOwnedWorkProfile             = $b.companyOwnedDevicesWithWorkProfileEnabled
}
$report.GetEnumerator() | ForEach-Object { '{0,-38}: {1}' -f $_.Key, $_.Value } | Write-Host

$issues = New-Object System.Collections.Generic.List[string]
if ($b.bindStatus -ne 'bound') { $issues.Add("bindStatus is '$($b.bindStatus)' (expected 'bound') — connector broken; re-establish or repair the managed Google Play connection.") }
if (-not $b.ownerUserPrincipalName) { $issues.Add("No binding owner account — the enterprise-binding managed account is missing; the connection needs re-consent by a Global Admin.") }
if ($b.lastAppSyncStatus -and $b.lastAppSyncStatus -ne 'success') { $issues.Add("Last app sync status is '$($b.lastAppSyncStatus)' — approved managed Google Play apps may not deliver.") }
if ($ageH -ne $null -and $ageH -gt $StaleHours) { $issues.Add("Last app sync was $ageH h ago (> $StaleHours h) — sync appears stalled.") }

Write-Host ""
if ($issues.Count -eq 0) { Write-Host "HEALTHY: binding bound, owner present, sync recent and successful." -ForegroundColor Green }
else { Write-Host ("UNHEALTHY — {0} issue(s):" -f $issues.Count) -ForegroundColor Red; $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow } }

if ($JsonPath) { $report | ConvertTo-Json | Set-Content -Path $JsonPath; Write-Host "Saved $JsonPath (record as 'Binding Health - Android - Baseline')." -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
