<#
.SYNOPSIS
    CMPCJIS-ScopeCheck.ps1 - connection/permission/licensing health + CJI-candidate scope and audit state (read-only).
.DESCRIPTION
    PURPOSE
        Verifies the operator can perform each CJIS-program function and lists the CJI-candidate scope that
        the label/DLP/retention controls will target: published sensitivity labels, DLP policies, retention
        policies, the workloads they cover, and the unified-audit-logging state. Reports a clear
        permission/connection error per function rather than failing the whole run, and reminds you of the
        separation-of-duties the program requires. Read-only - changes nothing.
    HOW TO RUN
        powershell -File .\CMPCJIS-ScopeCheck.ps1 -CsvPath .\CJIS-Scope.csv
        Requires ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline). Interactive
        modern-auth; no secrets.
    EXPECTED RESULTS
        A health table (function / OK|ERROR / detail) and a CJI-candidate inventory you confirm and record in
        the "CJIS Control Map - Purview - Baseline" as the in-scope set. Separation-of-duties reminders printed.
.NOTES
    Purview category - CJIS Compliance Program. Read-only. Keep the CJI-control configurer, the audit-evidence
    reader, and any insider-risk reviewer SEPARATE. No client names; no secrets.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
$health = New-Object System.Collections.Generic.List[object]
$scope  = New-Object System.Collections.Generic.List[object]
function Add-Health($fn,$ok,$detail){ $health.Add([pscustomobject]@{ Function=$fn; Status=$(if($ok){'OK'}else{'ERROR'}); Detail=$detail }) }
function Add-Scope($type,$name,$detail){ $scope.Add([pscustomobject]@{ Type=$type; Name=$name; Detail=$detail }) }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser" -ForegroundColor Red; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{}; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

# Exchange Online - audit config
try {
    Connect-ExchangeOnline @cp -ShowBanner:$false -ErrorAction Stop | Out-Null
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    Add-Health 'Exchange Online / audit config' $true ("UnifiedAuditLogIngestionEnabled={0}" -f [bool]$cfg.UnifiedAuditLogIngestionEnabled)
} catch { Add-Health 'Exchange Online / audit config' $false $_.Exception.Message }

# S&C PowerShell
try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null; Add-Health 'S&C PowerShell (Connect-IPPSSession)' $true 'connected' }
catch { Add-Health 'S&C PowerShell (Connect-IPPSSession)' $false $_.Exception.Message; Write-Host "Cannot continue without S&C PowerShell." -ForegroundColor Red }

# Labels (CJI classification candidates)
try {
    $labels = @(Get-Label -ErrorAction Stop)
    Add-Health 'Sensitivity labels (Get-Label)' $true "$($labels.Count) label(s)"
    foreach ($l in $labels) { Add-Scope 'Label' $l.DisplayName ("Priority=$($l.Priority) Encryption=$(if($l.EncryptionEnabled){'Yes'}else{'?'})") }
} catch { Add-Health 'Sensitivity labels (Get-Label)' $false $_.Exception.Message }

# DLP policies (CJI-exfiltration control target)
try {
    $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    Add-Health 'DLP policies (Get-DlpCompliancePolicy)' $true "$($dlp.Count) policy(ies)"
    foreach ($p in $dlp) {
        $wl = @(); if($p.ExchangeLocation){$wl+='Exchange'}; if($p.SharePointLocation){$wl+='SharePoint'}; if($p.OneDriveLocation){$wl+='OneDrive'}; if($p.TeamsLocation){$wl+='Teams'}; if($p.EndpointDlpLocation){$wl+='Endpoint'}
        Add-Scope 'DLP policy' $p.Name ("Mode=$($p.Mode) Workloads=$($wl -join ',')")
    }
} catch { Add-Health 'DLP policies (Get-DlpCompliancePolicy)' $false $_.Exception.Message }

# Retention policies (CJI records control target)
try {
    $ret = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
    Add-Health 'Retention policies (Get-RetentionCompliancePolicy)' $true "$($ret.Count) policy(ies)"
    foreach ($r in $ret) {
        $wl = @(); if($r.ExchangeLocation){$wl+='Exchange'}; if($r.SharePointLocation){$wl+='SharePoint'}; if($r.OneDriveLocation){$wl+='OneDrive'}; if($r.TeamsChannelLocation -or $r.TeamsChatLocation){$wl+='Teams'}
        Add-Scope 'Retention policy' $r.Name ("Enabled=$($r.Enabled) Workloads=$($wl -join ',')")
    }
} catch { Add-Health 'Retention policies (Get-RetentionCompliancePolicy)' $false $_.Exception.Message }

Write-Host "`n=== CJIS Program - Function Health ===" -ForegroundColor Cyan
$health | Format-Table -AutoSize | Out-String | Write-Host
Write-Host "=== CJI-candidate scope (confirm + record in the control map) ===" -ForegroundColor Cyan
$scope | Format-Table -AutoSize | Out-String | Write-Host

$err = @($health | Where-Object Status -eq 'ERROR').Count
if ($err -gt 0) { Write-Host "$err function(s) not available - assign least-privilege roles (Requirement 2.3)." -ForegroundColor Yellow }
Write-Host "Reminder: keep the CJI-control configurer, the audit-evidence reader, and any insider-risk reviewer SEPARATE (separation of duties)." -ForegroundColor Yellow
if ($CsvPath) { $scope | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "CJI-candidate scope exported to $CsvPath" -ForegroundColor Green }
