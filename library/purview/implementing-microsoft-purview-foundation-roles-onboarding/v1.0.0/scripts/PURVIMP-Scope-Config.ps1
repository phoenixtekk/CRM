<#
.SYNOPSIS
    PURVIMP-Scope-Config.ps1 — read-only workload scope/health helper: confirms in-scope M365 workloads and reports endpoint device-onboarding readiness.
.DESCRIPTION
    PURPOSE
        Builds the workload scope map for the Purview foundation: confirms the M365 workloads are present
        for the tenant (Exchange Online, SharePoint Online, OneDrive, Teams — connected by virtue of the
        subscription) and reports endpoint device-onboarding READINESS (how many Windows/macOS devices
        are known via Graph managed devices), so a later endpoint-DLP solution can plan onboarding.
        Read-only — makes no changes. Writes the export "Purview Workload Scope - Map".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVIMP-Scope-Config.ps1 -CsvPath .\PurviewScope.csv
        PowerShell 5.1+/7+. Requires the Microsoft Graph SDK (scopes: Organization.Read.All,
        DeviceManagementManagedDevices.Read.All for the endpoint readiness count).
    EXPECTED RESULTS
        Console + CSV listing each in-scope workload with a Present/Connected status and an endpoint
        readiness count. PASS = every in-scope workload shows connected; endpoint gap (devices not yet
        onboarded to Purview) is recorded as a hand-off item for the endpoint-DLP solution.
.NOTES
    Purview — Implementing Microsoft Purview: Foundation, Roles & Onboarding. Read-only. Actual tenant-
    wide device onboarding is executed in the endpoint-DLP solution (Purview portal -> Settings -> Device
    onboarding, verify path), not here. No secrets in code.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$ReportName = 'Purview Workload Scope - Map'
)

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

# --- Detect M365 workload service plans (indicative — verify against your tenant) ---
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
$plans = $skus | ForEach-Object { $_.servicePlans } | ForEach-Object { $_.servicePlanName } | Sort-Object -Unique

$workloadPlans = @{
    'Exchange Online'  = @('EXCHANGE_S_ENTERPRISE','EXCHANGE_S_STANDARD')
    'SharePoint Online'= @('SHAREPOINTENTERPRISE','SHAREPOINTSTANDARD')
    'OneDrive'         = @('SHAREPOINTWAC','ONEDRIVESTANDARD','SHAREPOINTENTERPRISE')
    'Teams'            = @('TEAMS1','MCOSTANDARD')
}
$rows = foreach ($wl in $workloadPlans.Keys) {
    $present = @($workloadPlans[$wl] | Where-Object { $plans -contains $_ }).Count -gt 0
    [pscustomobject]@{
        Workload = $wl
        Status   = $(if ($present) {'Connected (M365 workload)'} else {'Not detected — verify licensing'})
    }
}

# --- Endpoint readiness: count managed devices as onboarding candidates ---
$deviceCount = 0
try {
    $r = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/managedDevices?$select=id,operatingSystem&$top=999'
    $deviceCount = @($r.value).Count
    while ($r.'@odata.nextLink') {
        $r = Invoke-MgGraphRequest -Method GET -Uri $r.'@odata.nextLink'
        $deviceCount += @($r.value).Count
    }
} catch {
    Write-Host ("  [WARN] Managed-device count unavailable (scope/licensing): {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}
$rows += [pscustomobject]@{
    Workload = 'Endpoints / Devices'
    Status   = ("{0} managed device(s) known — endpoint onboarding to Purview is a hand-off item for the endpoint-DLP solution (verify: Settings -> Device onboarding)" -f $deviceCount)
}

Write-Host '--- In-scope workloads ---' -ForegroundColor Cyan
$rows | Format-Table -AutoSize -Wrap

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
Write-Host 'Workload scope map complete (read-only). Confirm the in-scope list with stakeholders.' -ForegroundColor Green
