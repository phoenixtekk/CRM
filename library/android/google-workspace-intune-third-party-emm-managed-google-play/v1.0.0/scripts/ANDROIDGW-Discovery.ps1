<#
.SYNOPSIS
    ANDROIDGW-Discovery.ps1 — read-only current managed Google Play binding + Workspace-integration posture assessment via Microsoft Graph.
.DESCRIPTION
    PURPOSE
        Reads the current managed Google Play connection state from Intune (bind status, owning
        account/organization, last app sync) and a summary of enrolled Android devices, then flags
        whether the binding looks like an account enterprise or a managed-domain / Google Workspace
        binding. Establishes the "before" baseline for the re-enrollment / impact assessment.
        Read-only — makes NO changes. Writes "Binding Posture - Workspace+Intune - Discovery".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ANDROIDGW-Discovery.ps1 -CsvPath C:\Temp\ANDROIDGW-Binding.csv
        Requires the Microsoft Graph PowerShell SDK and (read-only) scopes:
        DeviceManagementServiceConfig.Read.All, DeviceManagementManagedDevices.Read.All, Organization.Read.All.
        NOTE: androidManagedStoreAccountEnterpriseSettings is read from the Graph BETA endpoint — verify
        its shape against current Microsoft guidance / your tenant.
    EXPECTED RESULTS
        PASS: a bound connection, an owning account consistent with your Google Workspace domain, and a
        recent SUCCESSFUL last app sync. FAIL: not bound, unexpected owner, or a failed/stale sync.
.NOTES
    Android — Google Workspace <-> Intune Third-Party EMM. Read-only. Re-enrollment behavior is NOT
    asserted; this only reports current state. Verify beta-endpoint results against current guidance.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$ReportName = 'Binding Posture - Workspace+Intune - Discovery'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementManagedDevices.Read.All','Organization.Read.All' -NoWelcome

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

# --- Managed Google Play connection state (BETA: androidManagedStoreAccountEnterpriseSettings) ---
$binding = $null
try {
    $binding = Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings'
} catch {
    Write-Warning ("Could not read androidManagedStoreAccountEnterpriseSettings (beta): {0}" -f $_.Exception.Message)
    Write-Warning "If this 404s, managed Google Play may not be connected, or the beta shape changed — verify against current Microsoft guidance."
}

$bindStatus   = if ($binding -and $binding.bindStatus)          { $binding.bindStatus }          else { 'unknown / not-connected' }
$owner        = if ($binding -and $binding.ownerUserPrincipalName) { $binding.ownerUserPrincipalName } else { '(none)' }
$ownerOrg     = if ($binding -and $binding.ownerOrganizationName)  { $binding.ownerOrganizationName }  else { '(none)' }
$lastSync     = if ($binding -and $binding.lastAppSyncDateTime)  { $binding.lastAppSyncDateTime }  else { '(never)' }
$lastSyncStat = if ($binding -and $binding.lastAppSyncStatus)    { $binding.lastAppSyncStatus }    else { 'unknown' }

# Heuristic (informational only): a managed-domain / Workspace binding typically shows an owner org and
# a corporate-domain owner UPN; an anonymous account enterprise typically does not. NOT authoritative —
# confirm the actual model in the Intune admin center + Google Admin console.
$modelHint = 'INDETERMINATE — verify in Intune + Google Admin console'
if ($owner -ne '(none)' -and $owner -match '@' -and $ownerOrg -ne '(none)') {
    $modelHint = 'Looks like a MANAGED-DOMAIN / Workspace binding (owner org + domain UPN present) — VERIFY'
} elseif ($binding) {
    $modelHint = 'Could be an ACCOUNT-ENTERPRISE binding (no owner org / non-domain owner) — VERIFY'
}

Write-Host '--- Managed Google Play connection ---' -ForegroundColor Cyan
[pscustomobject]@{
    BindStatus        = $bindStatus
    OwnerUPN          = $owner
    OwnerOrganization = $ownerOrg
    LastAppSync       = $lastSync
    LastAppSyncStatus = $lastSyncStat
    ModelHint         = $modelHint
} | Format-List

if ($lastSyncStat -and $lastSyncStat -notmatch 'success') {
    Write-Host ("App sync status is '{0}' — investigate before relying on app delivery." -f $lastSyncStat) -ForegroundColor Yellow
}

# --- Enrolled Android device summary (baseline blast-radius, high level) ---
$rows = @()
$uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android'&`$select=deviceName,managedDeviceOwnerType,deviceEnrollmentType,complianceState,lastSyncDateTime,enrolledDateTime,manufacturer,model,osVersion&`$top=200"
do {
    $r = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($d in $r.value) {
        $rows += [pscustomobject]@{
            DeviceName      = $d.deviceName
            OwnerType       = $d.managedDeviceOwnerType
            EnrollmentType  = $d.deviceEnrollmentType
            ComplianceState = $d.complianceState
            EnrolledDate    = $d.enrolledDateTime
            LastSync        = $d.lastSyncDateTime
            Manufacturer    = $d.manufacturer
            Model           = $d.model
            OSVersion       = $d.osVersion
        }
    }
    $uri = $r.'@odata.nextLink'
} while ($uri)

Write-Host ('--- Enrolled Android devices: {0} total ---' -f $rows.Count) -ForegroundColor Cyan
$rows | Group-Object EnrollmentType | Sort-Object Name |
    Select-Object @{n='EnrollmentType';e={$_.Name}}, Count | Format-Table -AutoSize

Write-Host "NOTE: This report shows CURRENT state only. Re-enrollment impact is assessed by piloting the" -ForegroundColor DarkCyan
Write-Host "      change and diffing ANDROIDGW-DeviceImpact.ps1 against this baseline — never assumed." -ForegroundColor DarkCyan

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved device baseline for '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
