<#
.SYNOPSIS
    SCCMTS-Report.ps1 — task-sequence failure summary with an exit-code breakdown.
.DESCRIPTION
    PURPOSE
        Read-only reporting: pulls task-sequence failure status messages (IDs 11124/11170) for a
        collection or the whole site over a window, extracts the exit/error code from each message,
        and prints a breakdown by exit code plus the affected devices. This is the fleet view of the
        runbook — which failures are common and which exit codes to chase first.
    HOW TO RUN
        From a ConfigurationManager PowerShell session:
          .\SCCMTS-Report.ps1 -SiteCode ABC -SmsProvider cm01.contoso.com -Days 7
          .\SCCMTS-Report.ps1 -SiteCode ABC -SmsProvider cm01.contoso.com -Days 7 -CsvPath C:\Temp\ts.csv
        Requires the ConfigurationManager module and RBAC read on status messages.
    EXPECTED RESULTS
        A count of failures, a table grouped by exit code (with the likely class), a per-device list,
        and an optional CSV export. Read-only against the SMS provider.
.NOTES
    Phoenixtekk Workplace Marketplace — Infrastructure Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SiteCode,
    [Parameter(Mandatory)][string]$SmsProvider,
    [int]$Days = 7,
    [string]$CollectionID,
    [string]$CsvPath
)

$ns = "root\SMS\site_$SiteCode"
$since = (Get-Date).AddDays(-$Days)

# Known exit codes -> failure class (see 01-solution-overview.md).
$codeClass = @{
    '0'          = 'Success'
    '3010'       = 'Success (reboot required)'
    '2'          = 'Content (file not found)'
    '5'          = 'Permissions (access denied)'
    '1603'       = 'Application install (fatal MSI error)'
    '1618'       = 'Application install (another install in progress)'
    '1620'       = 'Application install (package could not be opened)'
    '2147500037' = 'Generic (0x80004005 - read smsts.log)'
    '2278886630' = 'Content (0x87D00607 - download failed)'
}

Write-Host "=== TS failure report ($SiteCode, last $Days d) ===" -ForegroundColor Cyan
try {
    $msgs = Get-CimInstance -Namespace $ns -ComputerName $SmsProvider -ClassName SMS_StatusMessage `
        -Filter "MessageID=11124 OR MessageID=11170" -ErrorAction Stop |
        Where-Object { $_.Time -ge $since }
} catch {
    Write-Host "Status message query failed: $($_.Exception.Message)" -ForegroundColor Yellow; exit 1
}
if (-not $msgs) { Write-Host "No task-sequence failures in the window." -ForegroundColor Green; exit 0 }

# Resolve each message's insertion strings (where the exit code text lives) and extract a code.
$rows = foreach ($m in $msgs) {
    $full = Get-CimInstance -Namespace $ns -ComputerName $SmsProvider -ClassName SMS_StatusMessage `
        -Filter "RecordID=$($m.RecordID)" -ErrorAction SilentlyContinue
    $text = ($full.InsertionStrings -join ' ')
    # Pull a decimal error code (e.g. "error code 1603") or a hex code (0x....) from the message text.
    $code = if ($text -match '0x[0-9A-Fa-f]{6,8}') { $Matches[0] }
            elseif ($text -match '\b(\d{3,10})\b') { $Matches[1] }
            else { 'unknown' }
    [pscustomobject]@{
        Device   = $m.MachineName
        Time     = $m.Time
        MsgID    = $m.MessageID
        ExitCode = $code
        Class    = $(if ($codeClass.ContainsKey("$code")) { $codeClass["$code"] } else { 'Unclassified - read smsts.log' })
    }
}

Write-Host ("Total failures: {0}`n" -f $rows.Count) -ForegroundColor Yellow
Write-Host "--- By exit code ---" -ForegroundColor Cyan
$rows | Group-Object ExitCode | Sort-Object Count -Descending |
    Select-Object Count, @{n='ExitCode';e={$_.Name}}, @{n='Class';e={($_.Group | Select-Object -First 1).Class}} |
    Format-Table -AutoSize

Write-Host "--- By device (most recent) ---" -ForegroundColor Cyan
$rows | Sort-Object Time -Descending | Select-Object -First 50 Device, Time, MsgID, ExitCode, Class | Format-Table -AutoSize

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
