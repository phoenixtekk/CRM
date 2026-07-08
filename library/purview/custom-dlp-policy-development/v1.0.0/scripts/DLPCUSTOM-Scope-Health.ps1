<#
.SYNOPSIS
    DLPCUSTOM-Scope-Health.ps1 — read-only scope/health helper: confirms in-scope workloads, endpoint-onboarding readiness, and that referenced SITs/labels exist (no changes).
.DESCRIPTION
    PURPOSE
        Pre-flight and health check for a custom DLP policy's scope: confirms the in-scope M365 workloads,
        reports whether devices are onboarded to Purview (needed for Endpoint DLP), and verifies the
        sensitive info types / sensitivity labels the design references actually exist in the tenant.
        READ-ONLY — makes no changes. Writes 'Custom DLP - Scope - Map'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPCUSTOM-Scope-Health.ps1 -CsvPath .\DlpScope.csv -NeededSit 'Credit Card Number' -TargetEndpoint
        -TargetEndpoint : also check endpoint device-onboarding readiness (Endpoint DLP needs E5/E5 Compliance + onboarded devices)
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-IPPSSession). Optional: Microsoft.Graph for device readiness.
    EXPECTED RESULTS
        PASS = every targeted workload is confirmed present, endpoint readiness is reported accurately (if
        -TargetEndpoint), and each referenced SIT/label is PRESENT. Any gap is recorded as a hand-off item
        (e.g. endpoints not yet onboarded -> endpoint-DLP solution). No object is modified.
.NOTES
    Purview — Custom DLP Policy Development. Read-only; no secrets in code (interactive modern-auth).
    Endpoint onboarding and cloud-app connection are separate solutions — this only reports readiness.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = ".\Custom-DLP-Scope-Map.csv",
    [string[]]$NeededSit,
    [string[]]$NeededLabel,
    [switch]$TargetEndpoint
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "=== Custom DLP - Scope - Map  [READ-ONLY] ===" -ForegroundColor Cyan
$rows = New-Object System.Collections.Generic.List[object]

# 1. Workloads — DLP over Exchange/SharePoint/OneDrive/Teams is available when S&C PowerShell connects and DLP cmdlets resolve.
$dlpReady = [bool](Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)
foreach ($w in 'Exchange','SharePoint','OneDrive','Teams') {
    $rows.Add([pscustomobject]@{ Item='Workload'; Name=$w; Status=$(if($dlpReady){'DLP-capable (verify licensing)'}else{'DLP cmdlets unavailable'}); Note='Baseline DLP broadly licensed' })
}
Write-Host ("  M365 workloads: DLP cmdlets {0}" -f $(if($dlpReady){'available'}else{'UNAVAILABLE'})) -ForegroundColor $(if($dlpReady){'Green'}else{'Yellow'})

# 2. Endpoint readiness (only if targeting Endpoint DLP)
if ($TargetEndpoint) {
    $onboarded = 'unknown'
    if (Get-Command Connect-MgGraph -ErrorAction SilentlyContinue) {
        try {
            Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome -ErrorAction Stop
            $devs = Get-MgDeviceManagementManagedDevice -Top 1 -ErrorAction Stop
            $onboarded = if ($devs) { 'managed devices present (verify Purview device onboarding separately)' } else { 'no managed devices found' }
        } catch { $onboarded = "readiness check skipped: $($_.Exception.Message)" }
    } else {
        $onboarded = 'Microsoft.Graph not installed — check Purview portal Settings -> Device onboarding (verify path)'
    }
    Write-Host ("  Endpoint DLP readiness: {0}   (needs E5/E5 Compliance + devices onboarded to Purview)" -f $onboarded) -ForegroundColor Yellow
    $rows.Add([pscustomobject]@{ Item='Workload'; Name='Endpoint'; Status=$onboarded; Note='Endpoint DLP requires E5/E5 Compliance + Purview device onboarding (separate solution)' })
}

# 3. Referenced SITs exist
if ($NeededSit) {
    $allSit = @(Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue).Name
    foreach ($s in $NeededSit) {
        $present = $allSit -contains $s
        Write-Host ("  SIT '{0}': {1}" -f $s, $(if($present){'PRESENT'}else{'MISSING'})) -ForegroundColor $(if($present){'Green'}else{'Yellow'})
        $rows.Add([pscustomobject]@{ Item='SIT'; Name=$s; Status=$(if($present){'PRESENT'}else{'MISSING'}); Note=$(if($present){''}else{'Build in custom-SIT/EDM/fingerprint solution first'}) })
    }
}

# 4. Referenced sensitivity labels exist
if ($NeededLabel) {
    $labels = @()
    if (Get-Command Get-Label -ErrorAction SilentlyContinue) { try { $labels = @(Get-Label -ErrorAction Stop).DisplayName } catch {} }
    foreach ($l in $NeededLabel) {
        $present = $labels -contains $l
        Write-Host ("  Label '{0}': {1}" -f $l, $(if($present){'PRESENT'}else{'MISSING/verify'})) -ForegroundColor $(if($present){'Green'}else{'Yellow'})
        $rows.Add([pscustomobject]@{ Item='Label'; Name=$l; Status=$(if($present){'PRESENT'}else{'MISSING/verify'}); Note='Sensitivity labels are built in the labels solution' })
    }
}

$rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nWrote scope map to {0}  (Custom DLP - Scope - Map). Record any gap (unlicensed workload, endpoints not onboarded, missing SIT) as a hand-off item." -f $CsvPath) -ForegroundColor Cyan
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
