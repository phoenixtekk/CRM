<#
.SYNOPSIS
    INTCOMPDX-Report.ps1 — fleet compliance summary ranked by failing setting, plus Conditional Access impact (read-only).
.DESCRIPTION
    PURPOSE
        Produces the fleet picture for triage: how many devices are compliant vs not, which
        settings fail most, and the Conditional Access blast radius — which enabled CA
        policies require a compliant device and how many affected devices they touch.
        Read-only. Optionally export to CSV; replace the sample path your-report-path.csv.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDX-Report.ps1

        Required Graph scopes:
            DeviceManagementManagedDevices.Read.All
            DeviceManagementConfiguration.Read.All
            Policy.Read.All
    EXPECTED RESULTS
        Fleet compliance counts, a ranking of top failing settings, and a list of
        compliance-requiring Conditional Access policies with their scope. No changes made.
        Authorization error = missing scopes/role.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [string]$OutputCsv
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    $scopes = @(
        'DeviceManagementManagedDevices.Read.All',
        'DeviceManagementConfiguration.Read.All',
        'Policy.Read.All'
    )
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or -not ($scopes | Where-Object { $ctx.Scopes -contains $_ })) {
        Connect-MgGraph -Scopes $scopes | Out-Null
    }
    Write-Host "Connected to tenant: $((Get-MgContext).TenantId)" -ForegroundColor Green
}

function Invoke-GraphGetAll {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $results += $resp.value } else { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

Connect-Graph

# --- Fleet compliance summary ---
Write-Host "`n=== Fleet compliance summary ===" -ForegroundColor Cyan
$devices = Invoke-GraphGetAll -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$select=id,deviceName,complianceState,operatingSystem"
$summary = $devices | Group-Object complianceState | Sort-Object Count -Descending |
    ForEach-Object { [pscustomobject]@{ ComplianceState = $_.Name; Devices = $_.Count } }
$summary | Format-Table -AutoSize
$total = $devices.Count
$nonCompliant = ($devices | Where-Object { $_.complianceState -eq 'noncompliant' }).Count
Write-Host ("Total: {0}   Non-compliant: {1}" -f $total, $nonCompliant)

# --- Top failing settings across non-compliant devices ---
Write-Host "`n=== Top failing settings ===" -ForegroundColor Cyan
$settingFailures = @()
foreach ($d in ($devices | Where-Object { $_.complianceState -eq 'noncompliant' })) {
    $states = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}/deviceCompliancePolicyStates" -f $d.id)
    foreach ($s in $states) {
        $settings = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}/deviceCompliancePolicyStates/{1}/settingStates" -f $d.id, $s.id)
        foreach ($set in ($settings | Where-Object { $_.state -in @('nonCompliant','error','conflict') })) {
            $settingFailures += [pscustomobject]@{ Setting = $set.settingName; State = $set.state }
        }
    }
}
$ranked = $settingFailures | Group-Object Setting | Sort-Object Count -Descending |
    ForEach-Object { [pscustomobject]@{ Setting = $_.Name; FailingDevices = $_.Count } }
$ranked | Format-Table -AutoSize

# --- Conditional Access impact (compliance-requiring policies) ---
Write-Host "`n=== Conditional Access impact (require compliant device) ===" -ForegroundColor Cyan
$caPolicies = Invoke-GraphGetAll -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
$caRows = foreach ($ca in $caPolicies) {
    $controls = @()
    if ($ca.grantControls -and $ca.grantControls.builtInControls) { $controls = $ca.grantControls.builtInControls }
    if ($controls -contains 'compliantDevice') {
        [pscustomobject]@{
            CAPolicy      = $ca.displayName
            State         = $ca.state
            IncludeUsers  = ($ca.conditions.users.includeUsers -join ',')
            IncludeGroups = ($ca.conditions.users.includeGroups -join ',')
            TargetApps    = ($ca.conditions.applications.includeApplications -join ',')
        }
    }
}
if ($caRows) {
    $caRows | Format-Table -AutoSize -Wrap
    Write-Host ("`nBlast radius: {0} non-compliant device(s) are subject to {1} compliance-requiring CA policy(ies)." -f $nonCompliant, ($caRows.Count))
} else {
    Write-Host "No enabled Conditional Access policy requires a compliant device." -ForegroundColor Yellow
}

if ($OutputCsv) {
    $ranked | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host "`nSaved failing-setting ranking to $OutputCsv" -ForegroundColor Green
}

Write-Host "`nReport complete (read-only)." -ForegroundColor Green
