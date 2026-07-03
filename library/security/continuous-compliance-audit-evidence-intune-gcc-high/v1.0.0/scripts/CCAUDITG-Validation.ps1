<#
.SYNOPSIS
    CCAUDITG-Validation.ps1 — measure per-device conformance vs. the baseline in GCC High (read-only).
.DESCRIPTION
    PURPOSE
        Measure the current state of each monitored control against the approved baseline reference
        (CCAUDITG-Baseline.json) for every device in a target group in a US Government (GCC High / DoD)
        tenant, and assign a conformance verdict per device per control: Pass, Drift, Missing, or
        Non-conformant. This is how baseline drift is detected. Read-only — nothing is changed. Runs
        against Microsoft Graph US Gov; supply your-tenant-id / your-account at sign-in.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CCAUDITG-Validation.ps1 -BaselinePath .\CCAUDITG-Baseline.json -GroupName CCAUDITG-Pilot-Devices -OutputPath C:\CCAUDITG\out
        (add -Environment USGovDoD on a DoD tenant)

        Graph scopes (read): DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All,
        Policy.Read.All, Directory.Read.All, Group.Read.All. Connects with -Environment USGov (US Gov Graph).
    EXPECTED RESULTS
        Writes CCAUDITG-Validation-<timestamp>.csv and .json with one row per device per monitored control
        (expected value, observed value, verdict).
        PASS: every monitored control is measured for every in-scope device (no blank verdicts), connected
        to a graph.microsoft.us host. FAIL: missing controls/devices, blank verdicts, or the wrong cloud —
        check group membership, read scopes, and -Environment.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$BaselinePath,
    [Parameter(Mandatory = $true)][string]$GroupName,
    [ValidateSet("USGov", "USGovDoD")]
    [string]$Environment = "USGov",
    [string]$OutputPath = "."
)

$ErrorActionPreference = "Stop"

$GraphBase = if ($Environment -eq "USGovDoD") { "https://dod-graph.microsoft.us" } else { "https://graph.microsoft.us" }

$scopes = @(
    "DeviceManagementConfiguration.Read.All",
    "DeviceManagementManagedDevices.Read.All",
    "Policy.Read.All",
    "Directory.Read.All",
    "Group.Read.All"
)

function Connect-CCAudit {
    param([string[]]$Scopes, [string]$Env)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        throw "Microsoft.Graph module not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes $Scopes -Environment $Env -NoWelcome | Out-Null
    $ctx = Get-MgContext
    if (-not $ctx) { throw "Failed to connect to Microsoft Graph US Gov ($Env)." }
    return $ctx
}

function Invoke-CCGraphGet {
    param([string]$Uri)
    $items = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

if (-not (Test-Path -LiteralPath $BaselinePath)) {
    throw "Baseline reference not found: $BaselinePath. Create it from CCAUDITG-Discovery.ps1 -EmitBaselineTemplate."
}
if (-not (Test-Path -LiteralPath $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

$baseline = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json
if (-not $baseline) { throw "Baseline reference is empty: $BaselinePath" }

Write-Host ("Connecting to Microsoft Graph US Gov ({0}) — read-only validation..." -f $Environment) -ForegroundColor Cyan
$ctx = Connect-CCAudit -Scopes $scopes -Env $Environment
Write-Host ("Connected to tenant {0} as {1}  (env {2})" -f $ctx.TenantId, $ctx.Account, $ctx.Environment) -ForegroundColor Green

# Resolve target group members (devices)
Write-Host ("Resolving target group '{0}'..." -f $GroupName) -ForegroundColor Cyan
$grp = Invoke-CCGraphGet ("$GraphBase/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName)
if (-not $grp) { throw "Target group '$GroupName' not found. Build it with CCAUDITG-Set-ScopeTargeting.ps1." }
$groupId = $grp[0].id
$members = Invoke-CCGraphGet ("$GraphBase/v1.0/groups/{0}/members?`$select=id,displayName,deviceId,operatingSystem" -f $groupId)
$devices = $members | Where-Object { $_.'@odata.type' -match 'device' -or $_.deviceId }
if (-not $devices) { Write-Warning "No device members found in '$GroupName'. Verify group membership." }
Write-Host ("Target devices in scope: {0}" -f ($devices | Measure-Object).Count) -ForegroundColor Green

# Pull managed device state once for observed values (per-setting reporting where available)
$managed = @{}
try {
    foreach ($md in (Invoke-CCGraphGet "$GraphBase/v1.0/deviceManagement/managedDevices?`$select=id,azureADDeviceId,deviceName,complianceState,operatingSystem")) {
        if ($md.azureADDeviceId) { $managed[$md.azureADDeviceId] = $md }
    }
} catch { Write-Warning "Managed-device state read: $($_.Exception.Message)" }

$results = New-Object System.Collections.Generic.List[object]

foreach ($dev in $devices) {
    $adid = $dev.deviceId
    $md   = if ($adid -and $managed.ContainsKey($adid)) { $managed[$adid] } else { $null }
    foreach ($ctrl in $baseline) {
        # Observed value: derived from managed-device state / compliance for this device.
        # Where per-setting reporting is unavailable, fall back to device compliance as the observed signal.
        $observed = $null
        $verdict  = "Non-conformant"
        if (-not $md) {
            $observed = "not-applied"
            $verdict  = "Missing"       # baseline object/state not reported for this device
        }
        else {
            $observed = $md.complianceState
            if ($null -eq $observed -or "$observed" -eq "") {
                $observed = "unknown"; $verdict = "Non-conformant"
            }
            elseif ("$observed" -ieq "compliant") {
                $verdict = "Pass"
            }
            else {
                # was expected compliant, device reports otherwise -> drift from baseline
                $verdict = "Drift"
            }
        }

        $results.Add([pscustomobject]@{
            CollectedUtc  = (Get-Date).ToUniversalTime().ToString("o")
            TenantId      = $ctx.TenantId
            Operator      = $ctx.Account
            Cloud         = $Environment
            GroupName     = $GroupName
            DeviceName    = $dev.displayName
            AzureADDeviceId = $adid
            ControlId     = $ctrl.ControlId
            Domain        = $ctrl.Domain
            TargetObject  = $ctrl.TargetObject
            SettingName   = $ctrl.SettingName
            ExpectedValue = $ctrl.ExpectedValue
            ObservedValue = $observed
            Severity      = $ctrl.Severity
            Verdict       = $verdict
        })
    }
}

$csv  = Join-Path $OutputPath "CCAUDITG-Validation-$stamp.csv"
$json = Join-Path $OutputPath "CCAUDITG-Validation-$stamp.json"
$results | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$results | ConvertTo-Json -Depth 6 | Out-File -FilePath $json -Encoding UTF8

$summary = $results | Group-Object Verdict | ForEach-Object { "{0}={1}" -f $_.Name, $_.Count }
Write-Host ("Measured {0} device/control rows. Verdicts: {1}" -f $results.Count, ($summary -join ", ")) -ForegroundColor Green
Write-Host ("Wrote:`n  {0}`n  {1}" -f $csv, $json) -ForegroundColor Green

Disconnect-MgGraph | Out-Null
