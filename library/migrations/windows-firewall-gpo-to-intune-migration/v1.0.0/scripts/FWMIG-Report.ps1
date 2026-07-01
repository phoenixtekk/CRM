<#
.SYNOPSIS
    FWMIG-Report.ps1 - Migration coverage + conflict report (READ-ONLY).

.DESCRIPTION
    PURPOSE
        Produces the migration coverage and conflict report: lists the Intune endpoint-security
        firewall policies and firewall rule profiles (the migration targets) and their assignments
        via Microsoft Graph, and - on the local device - flags double-management (both GPO and
        Intune/MDM enforcing the firewall), which is the precursor to conflicts and merge loops.
        This script is READ-ONLY - it queries only; it makes no changes.

    HOW TO RUN
        Connect to Microsoft Graph first (delegated, least privilege):
            Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','Group.Read.All'
        Then:
            .\FWMIG-Report.ps1
            .\FWMIG-Report.ps1 -OutputPath C:\Temp\FWMIG
        Requires the Microsoft.Graph PowerShell SDK. The local double-management check uses the
        built-in NetSecurity module and should run on a representative in-scope device.

    EXPECTED RESULTS
        - Console table of Intune firewall policies / rules profiles and their assigned groups
          (the migration rings).
        - A local conflict flag: whether GPO-sourced firewall rules AND Intune/MDM rules both apply
          (double management) on this device.
        - A CSV (FWMIG-Coverage-<date>.csv) of the Intune firewall policy inventory + assignments.
#>

[CmdletBinding()]
param(
    [string] $OutputPath = (Join-Path $env:TEMP 'FWMIG')
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Error 'Microsoft.Graph SDK not found. Install-Module Microsoft.Graph -Scope CurrentUser'
    return
}
if (-not (Get-MgContext)) {
    Write-Error "Not connected. Run: Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','Group.Read.All'"
    return
}
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# --- Intune endpoint-security firewall: intents (configurationPolicies templateFamily=endpointSecurityFirewall) ---
Write-Host 'Querying Intune endpoint-security firewall policies via Microsoft Graph...' -ForegroundColor Cyan
$filter   = "templateReference/templateFamily eq 'endpointSecurityFirewall'"
$policies = Get-MgBetaDeviceManagementConfigurationPolicy -Filter $filter -All -ErrorAction SilentlyContinue
if (-not $policies) {
    # Fallback to raw Graph call if the Beta cmdlet is unavailable
    $uri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=$filter&`$expand=assignments"
    $policies = (Invoke-MgGraphRequest -Method GET -Uri $uri).value
}

$rows = foreach ($p in $policies) {
    $pid  = if ($p.Id) { $p.Id } else { $p.id }
    $name = if ($p.Name) { $p.Name } else { $p.name }
    $assignments = $p.assignments
    if (-not $assignments) {
        $au = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$pid/assignments"
        $assignments = (Invoke-MgGraphRequest -Method GET -Uri $au).value
    }
    $groups = foreach ($a in $assignments) {
        $gid = $a.target.groupId
        if ($gid) {
            try { (Get-MgGroup -GroupId $gid -ErrorAction Stop).DisplayName } catch { $gid }
        } else { $a.target.'@odata.type' }
    }
    [pscustomobject]@{
        PolicyName  = $name
        PolicyId    = $pid
        AssignedTo  = ($groups -join '; ')
    }
}

$rows | Format-Table -AutoSize
$csv = Join-Path $OutputPath "FWMIG-Coverage-$stamp.csv"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host "Coverage report: $csv" -ForegroundColor Green

# --- Local double-management / conflict flag ---
Write-Host "`nLocal firewall authority check on $env:COMPUTERNAME:" -ForegroundColor Cyan
if (Get-Module -ListAvailable -Name NetSecurity) {
    Import-Module NetSecurity -ErrorAction SilentlyContinue
    $gpoRules = Get-NetFirewallRule -PolicyStore RSOP -ErrorAction SilentlyContinue
    $mdmRules = Get-NetFirewallRule -PolicyStore ActiveStore -ErrorAction SilentlyContinue |
                Where-Object { $_.PolicyStoreSource -match 'MDM' -or $_.PolicyStoreSourceType -eq 'MDM' }
    $gpoCount = @($gpoRules).Count
    $mdmCount = @($mdmRules).Count
    if ($gpoCount -gt 0 -and $mdmCount -gt 0) {
        Write-Host "  CONFLICT RISK: both GPO ($gpoCount rules) and Intune/MDM ($mdmCount rules) apply - DOUBLE MANAGED." -ForegroundColor Red
    } elseif ($gpoCount -gt 0) {
        Write-Host "  GPO only ($gpoCount rules) - not yet migrated." -ForegroundColor Yellow
    } elseif ($mdmCount -gt 0) {
        Write-Host "  Intune/MDM only ($mdmCount rules) - migrated, single authority." -ForegroundColor Green
    } else {
        Write-Host "  No GPO or MDM firewall rules detected on this device." -ForegroundColor Yellow
    }
} else {
    Write-Host '  NetSecurity module unavailable - skipping local authority check.'
}
