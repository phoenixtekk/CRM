<#
.SYNOPSIS
    GDPR-EvidenceReport.ps1 — cross-control evidence + coverage report for the GDPR evidence register.
.DESCRIPTION
    PURPOSE
        Produces the cross-control evidence the program records in `GDPR Evidence - Register`:
        (1) the sensitivity-label inventory (classification / Art. 32 evidence), (2) a DLP
        service/mode matrix over EU personal data, (3) recent DLP events from the unified audit log
        grouped by workload (the audit-gate data), and (4) a small audit-log sample proving
        accountability logging (Art. 5(2)/33) is on. Optionally exports to CSV. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GDPR-EvidenceReport.ps1 -Days 7 -CsvPath C:\Temp\gdpr-evidence.csv
        Sign in as a Compliance Administrator when prompted. Requires audit logging enabled
        (Requirement 2.7) for the event sections to return data.
    EXPECTED RESULTS
        A label inventory, a DLP location/mode matrix, a per-workload DLP-event count, and an
        audit-log sample for the window — optionally saved to CSV for the evidence register.
.NOTES
    White-label — Purview Solutions. Read-only.
    Uses Get-Label / Get-DlpCompliancePolicy and Search-UnifiedAuditLog (DLP + sample records).
#>
[CmdletBinding()] param(
    [int]$Days = 7,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview GDPR — evidence + coverage report ===" -ForegroundColor Cyan

# --- Classification: labels (Art. 32 evidence) ---
Write-Host "`n--- Sensitivity labels (classification coverage) ---" -ForegroundColor Cyan
$labels = Get-Label -ErrorAction SilentlyContinue
if ($labels) {
    $labels | Sort-Object Priority | Select-Object DisplayName, Priority,
        @{n='Encrypted';e={[bool]$_.EncryptionEnabled}} | Format-Table -AutoSize
} else { Write-Host "  No sensitivity labels found." -ForegroundColor Yellow }

# --- DLP location/mode matrix ---
Write-Host "`n--- DLP policies (service coverage + mode) ---" -ForegroundColor Cyan
$dlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue
if ($dlp) {
    $dlp | Select-Object Name, Mode,
        @{n='Exchange';e={[bool]$_.ExchangeLocation}},
        @{n='SharePoint';e={[bool]$_.SharePointLocation}},
        @{n='OneDrive';e={[bool]$_.OneDriveLocation}},
        @{n='Teams';e={[bool]$_.TeamsLocation}},
        @{n='Endpoint';e={[bool]$_.EndpointDlpLocation}} | Format-Table -AutoSize
} else { Write-Host "  No DLP policies found." -ForegroundColor Yellow }

# --- DLP events from the unified audit log ---
Write-Host ("`n--- DLP events (last {0} days) ---" -f $Days) -ForegroundColor Cyan
$start = (Get-Date).AddDays(-$Days)
$end   = Get-Date
$rows = @()
try {
    $events = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType DLP -ResultSize 5000 -ErrorAction Stop
    if ($events) {
        $rows = foreach ($e in $events) {
            $d = $null; try { $d = $e.AuditData | ConvertFrom-Json } catch {}
            [pscustomobject]@{
                Date     = $e.CreationDate
                Workload = $(if($d.Workload){$d.Workload}else{$e.RecordType})
                Policy   = $(if($d.PolicyDetails){($d.PolicyDetails | Select-Object -First 1).PolicyName}else{''})
                User     = $e.UserIds
            }
        }
        Write-Host "By workload:" -ForegroundColor Cyan
        $rows | Group-Object Workload | Sort-Object Count -Descending |
            Select-Object Count, @{n='Workload';e={$_.Name}} | Format-Table -AutoSize
        Write-Host ("Total DLP events: {0}" -f $rows.Count) -ForegroundColor Cyan
    } else { Write-Host "  No DLP events in the window (or audit not yet populated)." -ForegroundColor Yellow }
} catch {
    Write-Host ("  DLP event search unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "  Confirm audit logging is enabled (Requirement 2.7)." -ForegroundColor Yellow
}

# --- Audit-log sample (accountability evidence, Art. 5(2)/33) ---
Write-Host ("`n--- Unified audit-log sample (accountability evidence) ---" -f $Days) -ForegroundColor Cyan
try {
    $sample = Search-UnifiedAuditLog -StartDate $start -EndDate $end -ResultSize 5 -ErrorAction Stop
    if ($sample) {
        Write-Host "  Audit logging is returning records — accountability evidence present:" -ForegroundColor Green
        $sample | Select-Object CreationDate, Operations, RecordType | Format-Table -AutoSize
    } else { Write-Host "  No audit records returned in the window — verify audit is enabled." -ForegroundColor Yellow }
} catch {
    Write-Host ("  Audit sample unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

if ($CsvPath -and $rows.Count) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("`nSaved DLP-event evidence to {0}" -f $CsvPath) -ForegroundColor Green }

Write-Host "`nReport complete. Attach the output to 'GDPR Evidence - Register'." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
