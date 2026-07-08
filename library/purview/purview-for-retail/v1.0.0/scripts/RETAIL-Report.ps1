<#
.SYNOPSIS
    RETAIL-Report.ps1 — classification + PCI/PII DLP-event coverage report (read-only).
.DESCRIPTION
    PURPOSE
        Summarizes retail information-protection coverage so you can review the DLP audit gate and track
        classification: (1) which sensitivity labels exist and their protection, (2) which services
        each DLP policy covers and its mode (flagging the retail PCI/PII policies), and (3) recent DLP
        events from the unified audit log grouped by workload — the audit data you tune before blocking
        PAN and customer PII.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RETAIL-Report.ps1 -Days 7 -CsvPath C:\Temp\retail-dlp.csv
        Sign in as a Compliance Administrator when prompted. Requires audit logging enabled
        (Requirement 2.8) for the DLP-event section to return data.
    EXPECTED RESULTS
        A label inventory, a DLP location/mode matrix (with a Retail/PCI flag), and a per-workload count
        of DLP rule matches for the window, optionally exported to CSV. Nothing is changed.
.NOTES
    White-label — Purview / Retail. Read-only.
    PowerShell 5.1+/7+. Uses Get-Label / Get-DlpCompliancePolicy and Search-UnifiedAuditLog (RecordType DLP).
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

Write-Host "`n=== Microsoft Purview for Retail — classification + DLP coverage report ===" -ForegroundColor Cyan

# --- Classification: labels in the tenant ---
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
        @{n='Retail/PCI';e={ if ($_.Name -match 'PCI|Cardholder|PII|Customer|Retail') {'YES'} else {''} }},
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
        if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
    } else { Write-Host "  No DLP events in the window (or audit not yet populated)." -ForegroundColor Yellow }
} catch {
    Write-Host ("  DLP event search unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "  Confirm audit logging is enabled (Requirement 2.8)." -ForegroundColor Yellow
}

Write-Host "`nReport complete." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
