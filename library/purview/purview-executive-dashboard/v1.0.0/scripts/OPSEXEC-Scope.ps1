<#
.SYNOPSIS
    OPSEXEC-Scope.ps1 - connection/permission/licensing health + in-scope coverage denominators (read-only).
.DESCRIPTION
    PURPOSE
        Verifies the collector account can read each dashboard source and lists the candidate in-scope
        set that forms the coverage denominators: published sensitivity labels, DLP policies, retention
        policies, and the workloads they target. Reports a clear permission/connection error per source
        rather than failing the whole run. Read-only - changes nothing.
    HOW TO RUN
        powershell -File .\OPSEXEC-Scope.ps1 -CsvPath .\Exec-Scope.csv
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth; no secrets.
    EXPECTED RESULTS
        A health table (source / OK|ERROR / detail) and an in-scope inventory you confirm and record in
        "Exec Metrics - Compliance Signals - Definition" as the coverage denominators.
.NOTES
    Purview category - Executive Dashboard. Read-only. Keep Insider Risk roles SEPARATE from the
    dashboard-author role. No client names; no secrets.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
$health = New-Object System.Collections.Generic.List[object]
$scope  = New-Object System.Collections.Generic.List[object]
function Add-Health($src,$ok,$detail){ $health.Add([pscustomobject]@{ Source=$src; Status=$(if($ok){'OK'}else{'ERROR'}); Detail=$detail }) }
function Add-Scope($type,$name,$detail){ $scope.Add([pscustomobject]@{ Type=$type; Name=$name; Detail=$detail }) }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser" -ForegroundColor Red; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{}; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null; Add-Health 'S&C PowerShell (Connect-IPPSSession)' $true 'connected' }
catch { Add-Health 'S&C PowerShell (Connect-IPPSSession)' $false $_.Exception.Message; Write-Host "Cannot continue without S&C PowerShell." -ForegroundColor Red; return }

# Published sensitivity labels (label-coverage numerator/candidates)
try {
    $labels = @(Get-Label -ErrorAction Stop)
    Add-Health 'Sensitivity labels (Get-Label)' $true "$($labels.Count) label(s)"
    foreach ($l in $labels) { Add-Scope 'Label' $l.DisplayName ("Priority=$($l.Priority) Guid=$($l.Guid)") }
} catch { Add-Health 'Sensitivity labels (Get-Label)' $false $_.Exception.Message }

# DLP policies (data-risk source; note in-scope workloads)
try {
    $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    Add-Health 'DLP policies (Get-DlpCompliancePolicy)' $true "$($dlp.Count) policy(ies)"
    foreach ($p in $dlp) {
        $wl = @(); if($p.ExchangeLocation){$wl+='Exchange'}; if($p.SharePointLocation){$wl+='SharePoint'}; if($p.OneDriveLocation){$wl+='OneDrive'}; if($p.TeamsLocation){$wl+='Teams'}; if($p.EndpointDlpLocation){$wl+='Endpoint'}
        Add-Scope 'DLP policy' $p.Name ("Mode=$($p.Mode) Workloads=$($wl -join ',')")
    }
} catch { Add-Health 'DLP policies (Get-DlpCompliancePolicy)' $false $_.Exception.Message }

# Retention policies (retention-coverage denominator)
try {
    $ret = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
    Add-Health 'Retention policies (Get-RetentionCompliancePolicy)' $true "$($ret.Count) policy(ies)"
    foreach ($r in $ret) {
        $wl = @(); if($r.ExchangeLocation){$wl+='Exchange'}; if($r.SharePointLocation){$wl+='SharePoint'}; if($r.OneDriveLocation){$wl+='OneDrive'}; if($r.TeamsChannelLocation -or $r.TeamsChatLocation){$wl+='Teams'}
        Add-Scope 'Retention policy' $r.Name ("Enabled=$($r.Enabled) Workloads=$($wl -join ',')")
    }
} catch { Add-Health 'Retention policies (Get-RetentionCompliancePolicy)' $false $_.Exception.Message }

# Explorer read capability (health only)
if (Get-Command Export-ActivityExplorerData -ErrorAction SilentlyContinue) { Add-Health 'Activity Explorer' $true 'Export-ActivityExplorerData available' } else { Add-Health 'Activity Explorer' $false 'cmdlet not available - portal-read/verify tenant' }
if (Get-Command Export-ContentExplorerData -ErrorAction SilentlyContinue)  { Add-Health 'Content Explorer'  $true 'Export-ContentExplorerData available (preview/tenant-dependent)' } else { Add-Health 'Content Explorer' $false 'cmdlet not available - portal-read/verify tenant' }

Write-Host "`n=== Exec Dashboard - Source Health ===" -ForegroundColor Cyan
$health | Format-Table -AutoSize | Out-String | Write-Host
Write-Host "=== In-scope candidates (confirm + record as coverage denominators) ===" -ForegroundColor Cyan
$scope | Format-Table -AutoSize | Out-String | Write-Host

$err = @($health | Where-Object Status -eq 'ERROR').Count
if ($err -gt 0) { Write-Host "$err source(s) not readable - assign least-privilege read roles (Requirement 2.2)." -ForegroundColor Yellow }
Write-Host "Reminder: Insider Risk reader role MUST be held separately from the dashboard author." -ForegroundColor Yellow
if ($CsvPath) { $scope | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "In-scope inventory exported to $CsvPath" -ForegroundColor Green }
