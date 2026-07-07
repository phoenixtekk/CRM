<#
.SYNOPSIS
  Reporting (READ-ONLY): consolidated report of every domain's authentication type (Federated/Managed)
  plus tenant directory-sync signals, exportable to CSV for the change record. Makes no changes.
.DESCRIPTION
  Connects to Microsoft Graph and builds a single report combining each verified domain's
  AuthenticationType with the tenant on-premises sync state, for the migration change record and
  progress tracking (how many domains remain Federated vs Managed). Read-only: Domain.Read.All,
  Organization.Read.All. Confirm the exact tenant sign-in method (PHS/PTA) and Staged Rollout group
  membership in the Entra admin center - those are managed via Entra Connect, not fully exposed as
  Graph read cmdlets in every module version (verify in your version).
.EXAMPLE
  .\Get-M365SignInMethodReport.ps1
  # Read-only summary of Federated vs Managed domains and sync state.
.EXAMPLE
  .\Get-M365SignInMethodReport.ps1 -CsvPath .\signin-method-report.csv
  # Export the report to CSV for the change record.
  # (PowerShell 5.1+/7+, Microsoft.Graph module; connect with Connect-MgGraph.)
.NOTES
  Expected results: a table with one row per domain and a summary count of Federated vs Managed. During
  migration the Federated count should trend to zero as domains are converted. Government cloud: connect
  Graph to the correct environment and verify endpoints.
#>

[CmdletBinding()]
param(
    [string]$CsvPath
)

Write-Host "Connecting to Microsoft Graph (read-only)..." -ForegroundColor Cyan
try {
    Connect-MgGraph -Scopes 'Domain.Read.All','Organization.Read.All' -ErrorAction Stop | Out-Null
} catch {
    Write-Error "Connect-MgGraph failed: $($_.Exception.Message)"; return
}

$syncEnabled = $null
try {
    $org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
    $syncEnabled = $org.OnPremisesSyncEnabled
} catch {
    Write-Warning "Get-MgOrganization failed: $($_.Exception.Message)"
}

try {
    $domains = Get-MgDomain -All -ErrorAction Stop
} catch {
    Write-Error "Get-MgDomain failed: $($_.Exception.Message)"; return
}

$report = foreach ($d in $domains) {
    [pscustomobject]@{
        Domain              = $d.Id
        AuthenticationType  = $d.AuthenticationType
        IsVerified          = $d.IsVerified
        IsDefault           = $d.IsDefault
        TenantDirSyncEnabled= $syncEnabled
    }
}

Write-Host "`nM365 Sign-In Method Report" -ForegroundColor Green
$report | Sort-Object AuthenticationType, Domain | Format-Table Domain, AuthenticationType, IsVerified, IsDefault -AutoSize

$fedCount = ($report | Where-Object { $_.AuthenticationType -eq 'Federated' }).Count
$mgdCount = ($report | Where-Object { $_.AuthenticationType -eq 'Managed'   }).Count
Write-Host "`nSummary: Federated = $fedCount, Managed = $mgdCount (tenant dir-sync enabled = $syncEnabled)" -ForegroundColor Cyan
if ($fedCount -gt 0) {
    Write-Host "Migration in progress: $fedCount domain(s) still federated. Target is 0 before ADFS decommission." -ForegroundColor Yellow
}

if ($CsvPath) {
    $report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported report to $CsvPath" -ForegroundColor Cyan
}
