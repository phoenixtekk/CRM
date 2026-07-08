<#
.SYNOPSIS
    IPRMS-Report.ps1 — export the rights-protection posture matrix (per-label encryption/type/rights/offline/expiry) plus RMS activation + super-user state to CSV (read-only).
.DESCRIPTION
    Builds the evidence artifact for the governance owner: a per-label matrix of every sensitivity
    label's protection state (encryption on/off, protection type, rights definition, offline-access days,
    content expiry), plus the tenant RMS/Rights Management activation state and the configured super-user
    group. Read-only - makes no changes. Writes a timestamped CSV to the folder you supply (or prints to
    the console).
.EXAMPLE
    .\IPRMS-Report.ps1
    Prints the per-label protection matrix and RMS/super-user summary to the console (no file written).
.EXAMPLE
    .\IPRMS-Report.ps1 -CsvFolder C:\Purview\Evidence
    Exports IPRMS-Protection-<timestamp>.csv as governance evidence.
.NOTES
    Requires PowerShell 5.1+/7+. Modules: ExchangeOnlineManagement (Connect-IPPSSession) for labels;
    AIPService (Connect-AipService) for the RMS/super-user summary. Role: Information Protection Admin
    (read) + RMS/Global Admin for the AIPService reads.
    Expected results: PASS = the CSV/console lists every label with its protection posture and shows RMS
    Activated with a super-user group. FAIL = a module/role missing or RMS not activated (verify your
    licensing/tenant). Nothing is modified.
#>
[CmdletBinding()]
param(
    [string]$CsvFolder
)

Write-Host "=== IPRMS protection posture report (read-only) ===" -ForegroundColor Cyan

# --- RMS / super-user summary ---
$rmsState = 'unknown'; $superUser = '(none)'
try {
    if (-not (Get-Command Get-AipServiceConfiguration -ErrorAction SilentlyContinue)) { Import-Module AIPService -ErrorAction Stop }
    try { Get-AipServiceConfiguration -ErrorAction Stop | Out-Null } catch { Connect-AipService -ErrorAction Stop | Out-Null }
    $rmsState = "$((Get-AipServiceConfiguration).FunctionalState)"
    try { $g = Get-AipServiceSuperUserGroup -ErrorAction SilentlyContinue; if ($g) { $superUser = "$g" } } catch {}
} catch { $rmsState = "unreadable ($($_.Exception.Message))" }
Write-Host ("`nRMS functional state : {0}" -f $rmsState) -ForegroundColor $(if ($rmsState -match 'Activ') { 'Green' } else { 'Yellow' })
Write-Host ("Super-user group     : {0}" -f $superUser) -ForegroundColor $(if ($superUser -ne '(none)') { 'Green' } else { 'Yellow' })

# --- Per-label protection matrix ---
$rows = @()
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) { Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop | Out-Null }
    foreach ($l in (Get-Label -ErrorAction Stop)) {
        $enc = [bool]$l.EncryptionEnabled
        $rows += [pscustomobject]@{
            Label          = $l.DisplayName
            Identity       = $l.Name
            Encryption     = if ($enc) { 'ON' } else { 'off' }
            ProtectionType = if ($enc) { "$($l.EncryptionProtectionType)" } else { '' }
            OfflineDays    = if ($enc) { "$($l.EncryptionOfflineAccessDays)" } else { '' }
            Expiry         = if ($enc) { "$($l.EncryptionContentExpiredOnDateInDaysOrNever)" } else { '' }
            DoNotForward   = if ($enc) { "$([bool]$l.EncryptionDoNotForward)" } else { '' }
            EncryptOnly    = if ($enc) { "$([bool]$l.EncryptionPromptUser)" } else { '' }
            Rights         = if ($enc) { "$($l.EncryptionRightsDefinitions)" } else { '' }
        }
    }
} catch {
    Write-Host ("`nLabels : unable to read ({0}). Connect-IPPSSession; confirm your role." -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host ("`n--- Labels ({0}; {1} encrypting) ---" -f $rows.Count, (@($rows | Where-Object { $_.Encryption -eq 'ON' }).Count)) -ForegroundColor Cyan
$rows | Select-Object Label, Encryption, ProtectionType, OfflineDays, Expiry, DoNotForward, EncryptOnly | Format-Table -AutoSize | Out-Host

if ($CsvFolder) {
    if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder -Force | Out-Null }
    $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
    $path = Join-Path $CsvFolder "IPRMS-Protection-$ts.csv"
    $rows | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported: {0}" -f $path) -ForegroundColor Green
} else {
    Write-Host "`n(No -CsvFolder supplied - console only. Add -CsvFolder <path> to export evidence.)" -ForegroundColor Yellow
}
Write-Host "`nNOTE: RMS must be Activated with a super-user group for safe, recoverable encryption. Verify your licensing/tenant." -ForegroundColor Yellow
