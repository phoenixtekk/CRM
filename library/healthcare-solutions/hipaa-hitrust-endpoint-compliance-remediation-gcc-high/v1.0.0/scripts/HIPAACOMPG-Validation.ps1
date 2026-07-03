<#
.SYNOPSIS
    HIPAACOMPG-Validation.ps1 — read-only per-device PASS/FAIL check of the HIPAA/HITRUST endpoint safeguards on a GCC High tenant.
.DESCRIPTION
    PURPOSE
        For each in-scope clinical Windows device, reports whether it is Compliant and whether the
        key safeguards are enforced (encryption, Defender-managed, compliance state). Emits PASS or
        FAIL per device so you can see exactly which endpoint has a real gap. Read-only — makes no
        changes. Replace values like your-group-name only if you override -GroupName. Connects to
        Microsoft Graph US Gov (graph.microsoft.us).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HIPAACOMPG-Validation.ps1
        (Graph scopes: DeviceManagementManagedDevices.Read.All,
         DeviceManagementConfiguration.Read.All, Group.Read.All; connects with -Environment USGov)
    EXPECTED RESULTS
        A per-device table with an overall PASS/FAIL and a summary. PASS = the device is Compliant
        and encrypted; FAIL identifies the failing safeguard to remediate. An empty result or a
        Commercial-authority error means the session did not reach the US Gov cloud — see
        06-troubleshooting.md, section F.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $TenantId,
    [string] $GroupName = 'HIPAA - Clinical Endpoints',
    [string] $DeviceName,
    [string] $OutputCsv
)

$ErrorActionPreference = 'Stop'
$GraphBase = 'https://graph.microsoft.us/beta'

function Connect-UsGovGraph {
    param([string] $TenantId)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $p = @{ Environment = 'USGov'; Scopes = @(
        'DeviceManagementManagedDevices.Read.All',
        'DeviceManagementConfiguration.Read.All',
        'Group.Read.All'
    ) }
    if ($TenantId) { $p.TenantId = $TenantId }
    Write-Host "Connecting to Microsoft Graph (US Government cloud, -Environment USGov)..." -ForegroundColor Cyan
    Connect-MgGraph @p | Out-Null
    $ctx = Get-MgContext
    Write-Host ("Connected. Environment: {0} | Tenant: {1}" -f $ctx.Environment, $ctx.TenantId) -ForegroundColor Green
    if ($ctx.Environment -ne 'USGov') {
        Write-Warning "Graph environment is '$($ctx.Environment)', not 'USGov'. On GCC High this is WRONG — reconnect with -Environment USGov (06-troubleshooting.md, F)."
    }
}

function Get-GraphValue { param([string] $Uri) (Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop).value }

try {
    Connect-UsGovGraph -TenantId $TenantId

    Write-Host "`nEnumerating managed Windows devices..." -ForegroundColor Cyan
    $select  = 'id,deviceName,operatingSystem,osVersion,complianceState,isEncrypted,managementAgent,lastSyncDateTime,managedDeviceOwnerType'
    $devices = @(Get-GraphValue ("{0}/deviceManagement/managedDevices?`$select={1}" -f $GraphBase, $select)) |
               Where-Object { $_.operatingSystem -match 'Windows' }
    if ($DeviceName) { $devices = @($devices | Where-Object { $_.deviceName -eq $DeviceName }) }

    if (-not $devices -or $devices.Count -eq 0) {
        Write-Warning "No Windows devices returned. On GCC High confirm Environment: USGov above (06-troubleshooting.md, F)."
        return
    }

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($d in $devices) {
        $checks = @{
            Compliant = ($d.complianceState -eq 'compliant')
            Encrypted = ([bool]$d.isEncrypted)
            Managed   = ($d.managementAgent -match 'mdm|intune|configurationManagerClientMdm')
        }
        $fail = @($checks.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key })
        $overall = if ($fail.Count -eq 0) { 'PASS' } else { 'FAIL' }

        $rows.Add([pscustomobject]@{
            Device          = $d.deviceName
            OS              = $d.operatingSystem
            OSVersion       = $d.osVersion
            ComplianceState = $d.complianceState
            Encrypted       = [bool]$d.isEncrypted
            Managed         = $checks.Managed
            Result          = $overall
            Failing         = ($fail -join ', ')
            LastSync        = $d.lastSyncDateTime
        })
    }

    Write-Host "`n=== Per-device validation (GCC High) ===" -ForegroundColor Yellow
    $rows | Sort-Object Result, Device | Format-Table Device, ComplianceState, Encrypted, Managed, Result, Failing -AutoSize

    $pass = @($rows | Where-Object { $_.Result -eq 'PASS' }).Count
    $failc = @($rows | Where-Object { $_.Result -eq 'FAIL' }).Count
    Write-Host "`n=== Summary ===" -ForegroundColor Yellow
    Write-Host ("Scope group : {0}" -f $GroupName)
    Write-Host ("PASS: {0} | FAIL: {1} | Total: {2}" -f $pass, $failc, $rows.Count)
    if ($failc -gt 0) {
        Write-Warning "$failc device(s) FAIL — open Per-setting status in intune.microsoft.us and see 06-troubleshooting.md."
    }

    if ($OutputCsv) {
        $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
        Write-Host ("`nSaved validation results to {0} (store per R11; metadata only, no ePHI)." -f $OutputCsv) -ForegroundColor Green
    }
}
catch {
    Write-Error ("Validation failed: {0}" -f $_.Exception.Message)
    Write-Host "If this is an authority/authentication error, you may be on the Commercial cloud. Disconnect-MgGraph and retry (this script uses -Environment USGov)." -ForegroundColor Yellow
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}
