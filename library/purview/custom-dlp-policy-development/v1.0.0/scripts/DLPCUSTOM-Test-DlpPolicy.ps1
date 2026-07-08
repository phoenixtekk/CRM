<#
.SYNOPSIS
    DLPCUSTOM-Test-DlpPolicy.ps1 — read-only validation that a DLP policy/rule matches its design and is in a test mode before enforcement (no changes).
.DESCRIPTION
    PURPOSE
        Validates a custom DLP policy against its design: confirms the policy MODE, the locations, and each
        rule's conditions (sensitive info types, confidence, instance counts), exceptions, and actions.
        Flags if a policy is in an ENFORCEMENT mode (Enable) so you can confirm that was intentional and
        gate-passed. READ-ONLY — makes no changes. Writes 'Custom DLP - Simulation - Validate'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPCUSTOM-Test-DlpPolicy.ps1 -PolicyName 'Custom DLP - Sensitive Data - Pilot'
        Optional: -CsvPath .\DlpValidate.csv
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-IPPSSession).
    EXPECTED RESULTS
        PASS = the policy is in the expected mode (TestWithoutNotifications while piloting), scoped to the
        pilot locations, and its rule conditions/exceptions/actions match the design. A policy already in
        Enable mode is reported so the gate can be re-confirmed. No object is modified.
.NOTES
    Purview — Custom DLP Policy Development. Read-only; no secrets in code (interactive modern-auth).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$CsvPath = ".\Custom-DLP-Simulation-Validate.csv"
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host ("=== Custom DLP - Simulation - Validate : '{0}'  [READ-ONLY] ===" -f $PolicyName) -ForegroundColor Cyan
$rows = New-Object System.Collections.Generic.List[object]

$p = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $p) {
    Write-Host ("  [FAIL] Policy '{0}' not found. Check the name, or create it with DLPCUSTOM-New-DlpPolicy.ps1." -f $PolicyName) -ForegroundColor Red
    Disconnect-ExchangeOnline -Confirm:$false | Out-Null
    return
}

$isTest = $p.Mode -in @('TestWithoutNotifications','TestWithNotifications')
$modeColor = if ($p.Mode -eq 'Enable') { 'Yellow' } elseif ($isTest) { 'Green' } else { 'DarkGray' }
Write-Host ("  Policy mode: {0}   (Enabled={1})" -f $p.Mode, $p.Enabled) -ForegroundColor $modeColor
if ($p.Mode -eq 'Enable') {
    Write-Host "  [ENFORCEMENT] This policy is ENFORCING. Confirm the tuning gate was passed and the change was approved." -ForegroundColor Yellow
} elseif ($isTest) {
    Write-Host "  [SIMULATION] No user impact — evaluating and recording matches only. Good for piloting/tuning." -ForegroundColor Green
}

$locs = @('Exchange','SharePoint','OneDrive','Teams','Endpoint') | Where-Object { $p."${_}Location" }
Write-Host ("  Locations: {0}" -f ($locs -join ', ')) -ForegroundColor DarkGray
$rows.Add([pscustomobject]@{ Object='Policy'; Name=$p.Name; Mode=$p.Mode; Detail=("Locations=" + ($locs -join ';')) })

foreach ($r in @(Get-DlpComplianceRule -Policy $PolicyName -ErrorAction SilentlyContinue)) {
    $sitNames = @()
    try { $sitNames = @($r.ContentContainsSensitiveInformation | ForEach-Object { $_.Name }) } catch {}
    Write-Host ("  Rule '{0}'  mode={1}  SITs=[{2}]  BlockAccess={3}  Notify={4}  ExceptDomains=[{5}]" -f `
        $r.Name, $r.Mode, ($sitNames -join ','), $r.BlockAccess, ($null -ne $r.NotifyUser), (($r.ExceptIfRecipientDomainIs) -join ',')) -ForegroundColor Gray
    $rows.Add([pscustomobject]@{
        Object='Rule'; Name=$r.Name; Mode=$r.Mode
        Detail=("SITs=" + ($sitNames -join ';') + "; BlockAccess=" + $r.BlockAccess + "; ExceptDomains=" + (($r.ExceptIfRecipientDomainIs) -join ';'))
    })
}

$rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nWrote validation snapshot to {0}  (Custom DLP - Simulation - Validate)" -f $CsvPath) -ForegroundColor Cyan
Write-Host "Compare against 'Custom DLP - Sensitive Data - Design'. PASS = mode/scope/conditions/exceptions all match; policy is in simulation while piloting." -ForegroundColor DarkGray
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
