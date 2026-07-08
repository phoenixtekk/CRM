<#
.SYNOPSIS
    IPRMS-Discovery.ps1 — rights-protection posture: RMS service state, encryption-enabled labels, usage rights, super-user, Exchange IRM (read-only).
.DESCRIPTION
    Assesses the tenant's readiness and current state for label-based rights protection. Reports the
    Rights Management (RMS) service functional state (activated?), which sensitivity labels have
    encryption enabled and their protection type (Template vs UserDefined), the usage-rights definitions,
    offline-access and content-expiry values, whether an RMS super-user group is configured, and whether
    Exchange Online IRM is enabled. Read-only - makes no changes. Uses AIPService for the service/
    super-user state and Security & Compliance PowerShell for the labels.
.EXAMPLE
    .\IPRMS-Discovery.ps1
    Prints RMS activation, encryption-enabled labels with their rights, super-user, and IRM state.
.EXAMPLE
    .\IPRMS-Discovery.ps1 -CsvPath .\IPRMS-Posture.csv
    Also exports the per-label protection posture to CSV.
.NOTES
    Requires PowerShell 5.1+/7+. Modules: ExchangeOnlineManagement (Connect-IPPSSession), AIPService
    (Connect-AipService), and optionally the Exchange Online module (Get-IRMConfiguration).
    Role: Information Protection Admin (labels, read); RMS/Global Admin for the AIPService reads.
    Expected results: PASS = RMS shows Activated, encryption labels list with rights, a super-user group
    is set, IRM enabled. FAIL/verify = RMS not activated, no super-user (encrypted content not
    recoverable), or a module/role missing (verify your licensing/tenant). Nothing is modified.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

Write-Host "`n=== IPRMS rights-protection posture (read-only) ===" -ForegroundColor Cyan

# --- 1. RMS / Rights Management service state (AIPService) ---
Write-Host "`n-- Rights Management service --" -ForegroundColor Cyan
try {
    if (-not (Get-Command Get-AipServiceConfiguration -ErrorAction SilentlyContinue)) {
        Import-Module AIPService -ErrorAction Stop
    }
    if (-not (Get-Command Get-AipServiceConfiguration -ErrorAction SilentlyContinue)) { throw 'AIPService not loaded' }
    try { Get-AipServiceConfiguration -ErrorAction Stop | Out-Null } catch { Connect-AipService -ErrorAction Stop | Out-Null }
    $cfg = Get-AipServiceConfiguration -ErrorAction Stop
    $state = "$($cfg.FunctionalState)"
    $col = if ($state -match 'Activ') { 'Green' } else { 'Red' }
    Write-Host ("  Functional state : {0}" -f $state) -ForegroundColor $col
    if ($state -notmatch 'Activ') { Write-Host "  RMS is NOT activated - label encryption will fail. Enable-AipService (Req 2.5)." -ForegroundColor Red }

    try {
        $suGroup = Get-AipServiceSuperUserGroup -ErrorAction SilentlyContinue
        if ($suGroup) { Write-Host ("  Super-user group : {0}" -f $suGroup) -ForegroundColor Green }
        else { Write-Host "  Super-user group : (none) - encrypted content is NOT recoverable. Set before broad publish (Step 2)." -ForegroundColor Yellow }
    } catch { Write-Host "  Super-user group : (unable to read)" -ForegroundColor Yellow }
} catch {
    Write-Host ("  RMS state        : unable to read via AIPService ({0}). Install-Module AIPService; Connect-AipService. Verify RMS in the M365 admin center." -f $_.Exception.Message) -ForegroundColor Yellow
}

# --- 2. Exchange Online IRM state ---
Write-Host "`n-- Exchange Online IRM --" -ForegroundColor Cyan
try {
    if (Get-Command Get-IRMConfiguration -ErrorAction SilentlyContinue) {
        $irm = Get-IRMConfiguration -ErrorAction Stop
        Write-Host ("  InternalLicensingEnabled : {0}" -f $irm.InternalLicensingEnabled)
        Write-Host ("  AzureRMSLicensingEnabled : {0}" -f $irm.AzureRMSLicensingEnabled)
    } else {
        Write-Host "  Get-IRMConfiguration not available in this session - connect the Exchange Online module to check DNF/Encrypt-Only readiness." -ForegroundColor Yellow
    }
} catch { Write-Host ("  IRM state : unable to read ({0})." -f $_.Exception.Message) -ForegroundColor Yellow }

# --- 3. Encryption-enabled labels (S&C PowerShell) ---
Write-Host "`n-- Encryption-enabled sensitivity labels --" -ForegroundColor Cyan
$rows = @()
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) { Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop | Out-Null }
    $labels = @(Get-Label -ErrorAction Stop)
    $encLabels = @($labels | Where-Object { $_.EncryptionEnabled -eq $true })
    if ($encLabels.Count -eq 0) { Write-Host "  (no labels currently have encryption enabled)" -ForegroundColor Gray }
    foreach ($l in $encLabels) {
        $type    = "$($l.EncryptionProtectionType)"
        $rights  = "$($l.EncryptionRightsDefinitions)"
        $offline = "$($l.EncryptionOfflineAccessDays)"
        $expiry  = "$($l.EncryptionContentExpiredOnDateInDaysOrNever)"
        Write-Host ("  {0}" -f $l.DisplayName) -ForegroundColor Green
        Write-Host ("     type={0}  offlineDays={1}  expiry={2}" -f $type, $offline, $expiry)
        if ($rights) { Write-Host ("     rights: {0}" -f ($rights.Substring(0, [Math]::Min(120, $rights.Length)))) -ForegroundColor Gray }
        $rows += [pscustomobject]@{
            Label = $l.DisplayName; Identity = $l.Name; EncryptionEnabled = $true
            ProtectionType = $type; OfflineDays = $offline; Expiry = $expiry; Rights = $rights
        }
    }
    Write-Host ("`n  {0} of {1} label(s) have encryption enabled." -f $encLabels.Count, $labels.Count)
} catch {
    Write-Host ("  Labels : unable to read via S&C PowerShell ({0}). Connect-IPPSSession; confirm your role." -f $_.Exception.Message) -ForegroundColor Yellow
}

if ($CsvPath -and $rows.Count -gt 0) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported per-label posture to {0}" -f $CsvPath) -ForegroundColor Cyan
}
Write-Host "`nNOTE: RMS activation + a super-user group are prerequisites for safe encryption. Verify your licensing/tenant." -ForegroundColor Yellow
