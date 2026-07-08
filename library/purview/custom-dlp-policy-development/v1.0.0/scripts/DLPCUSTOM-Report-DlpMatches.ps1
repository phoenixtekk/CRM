<#
.SYNOPSIS
    DLPCUSTOM-Report-DlpMatches.ps1 — read-only export of DLP simulation/enforcement matches for false-positive/negative tuning (no changes).
.DESCRIPTION
    PURPOSE
        Pulls DLP match/detection events for a custom policy from the Microsoft Purview reporting surface
        (Activity Explorer via Export-ActivityExplorerData) so you can review simulation results and tune:
        drive down false positives (add exceptions, raise confidence/instance counts) and false negatives
        (broaden/add SITs). READ-ONLY — makes no changes. Writes 'Custom DLP - Matches - Report'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPCUSTOM-Report-DlpMatches.ps1 -PolicyName 'Custom DLP - Sensitive Data - Pilot' -CsvPath .\DlpMatches.csv
        Optional: -Days 7   (look-back window; default 7)
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-IPPSSession).
    EXPECTED RESULTS
        PASS = a dated CSV of matches for the policy that lets you compute the false-positive rate and
        confirm known-sensitive samples were caught. If the reporting surface differs in your tenant,
        the script says so and points to the portal DLP reports / Activity Explorer. No object is modified.
.NOTES
    Purview — Custom DLP Policy Development. Read-only. DLP reporting cmdlets/surfaces evolve — verify the
    available surface in your tenant (some legacy Get-Dlp*Report cmdlets are retired in favour of Activity
    Explorer). No secrets in code (interactive modern-auth).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$CsvPath = ".\Custom-DLP-Matches-Report.csv",
    [int]$Days = 7
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

$start = (Get-Date).AddDays(-1 * [math]::Abs($Days))
$end   = Get-Date
Write-Host ("=== Custom DLP - Matches - Report : '{0}'  [READ-ONLY]  last {1} day(s) ===" -f $PolicyName, $Days) -ForegroundColor Cyan

$exported = $false
if (Get-Command Export-ActivityExplorerData -ErrorAction SilentlyContinue) {
    try {
        # Activity Explorer is the current surface for DLP rule matches. Filter to DLP activity and this policy.
        $data = Export-ActivityExplorerData -StartTime $start -EndTime $end `
                    -Filter1 'Activity','eq','DLPRuleMatch' -OutputFormat Json -PageSize 5000 -ErrorAction Stop
        $records = @()
        foreach ($chunk in $data) {
            if ($chunk.Data) { $records += ($chunk.Data | ConvertFrom-Json) }
        }
        $matches = $records | Where-Object { $_.PolicyName -eq $PolicyName -or $_.DlpPolicyName -eq $PolicyName -or -not $PolicyName }
        if (-not $matches) { $matches = $records }  # if the policy field name differs, keep all DLP matches for review
        $matches | Select-Object Happened, User, Workload, PolicyName, DlpPolicyName, SensitiveInfoType, Activity |
                   Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host ("  Exported {0} DLP match record(s) to {1}" -f @($matches).Count, $CsvPath) -ForegroundColor Green
        $exported = $true
    } catch {
        Write-Host ("  [WARN] Export-ActivityExplorerData failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

if (-not $exported) {
    Write-Host "  [INFO] Could not export matches via PowerShell in this tenant." -ForegroundColor Yellow
    Write-Host "         Review matches in the Purview portal: Data loss prevention -> Alerts / Activity explorer" -ForegroundColor Yellow
    Write-Host "         (Data classification -> Activity explorer, filter Activity = DLPRuleMatch, Policy = '$PolicyName' — verify path)." -ForegroundColor Yellow
    [pscustomobject]@{ Policy=$PolicyName; Note='Export unavailable in tenant — use portal Activity explorer / DLP Alerts'; Window="$start..$end" } |
        Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
}

Write-Host ("`nWrote {0}  (Custom DLP - Matches - Report). Use it to compute false-positive rate and confirm seeded samples were caught, then tune." -f $CsvPath) -ForegroundColor Cyan
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
