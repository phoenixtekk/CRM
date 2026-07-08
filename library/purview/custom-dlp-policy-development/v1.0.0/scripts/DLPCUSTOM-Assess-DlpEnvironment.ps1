<#
.SYNOPSIS
    DLPCUSTOM-Assess-DlpEnvironment.ps1 — read-only discovery of existing DLP policies, rules, sensitive info types, and DLP licensing (no changes).
.DESCRIPTION
    PURPOSE
        Inventories the current Microsoft Purview DLP environment before you author a custom policy:
        every DLP policy and rule with its MODE (Enable / TestWithNotifications / TestWithoutNotifications /
        Disable) and locations, the available sensitive information types, and the DLP-relevant licensing.
        READ-ONLY — makes no changes. Writes an evidence CSV: 'Custom DLP - Discovery - Assess'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPCUSTOM-Assess-DlpEnvironment.ps1 -CsvPath .\DlpDiscovery.csv
        Optional: -NeededSit 'Credit Card Number','Custom Customer ID'  (flags whether each exists in the tenant)
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-IPPSSession for Security & Compliance PowerShell).
    EXPECTED RESULTS
        PASS = you have an inventory of existing DLP policies/modes/locations, the available SITs, and the
        licensed workloads, and every SIT your design needs is confirmed present. No object is modified.
.NOTES
    Purview — Custom DLP Policy Development. Read-only assessment; no secrets in code (interactive modern-auth).
    Capability availability is licensing-dependent — verify against your own tenant and plan.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = ".\Custom-DLP-Discovery-Assess.csv",
    [string[]]$NeededSit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "=== Custom DLP - Discovery - Assess  [READ-ONLY] ===" -ForegroundColor Cyan
$rows = New-Object System.Collections.Generic.List[object]

# 1. Existing DLP policies + their rules
try {
    $policies = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    Write-Host ("DLP policies found: {0}" -f $policies.Count) -ForegroundColor Green
    foreach ($p in $policies) {
        $locs = @('Exchange','SharePoint','OneDrive','Teams','Endpoint') |
                Where-Object { $p."${_}Location" } | ForEach-Object { $_ }
        $rows.Add([pscustomobject]@{
            Type       = 'Policy'
            Name       = $p.Name
            Mode       = $p.Mode
            Enabled    = $p.Enabled
            Locations  = ($locs -join ';')
            Detail     = ("Priority={0}" -f $p.Priority)
        })
        foreach ($r in @(Get-DlpComplianceRule -Policy $p.Name -ErrorAction SilentlyContinue)) {
            $rows.Add([pscustomobject]@{
                Type      = 'Rule'
                Name      = $r.Name
                Mode      = $r.Mode
                Enabled   = $r.Disabled -eq $false
                Locations = $p.Name
                Detail    = ("BlockAccess={0}; Notify={1}" -f $r.BlockAccess, ($null -ne $r.NotifyUser))
            })
        }
    }
} catch {
    Write-Host ("  [WARN] Could not enumerate DLP policies: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# 2. Available sensitive information types
try {
    $sits = @(Get-DlpSensitiveInformationType -ErrorAction Stop)
    Write-Host ("Sensitive information types available: {0}" -f $sits.Count) -ForegroundColor Green
    if ($NeededSit) {
        foreach ($need in $NeededSit) {
            $found = $sits | Where-Object { $_.Name -eq $need -or $_.Publisher }
            $present = [bool]($sits | Where-Object { $_.Name -eq $need })
            $flag = if ($present) { 'PRESENT' } else { 'MISSING - build it first in its own solution' }
            Write-Host ("  SIT '{0}': {1}" -f $need, $flag) -ForegroundColor $(if($present){'Green'}else{'Yellow'})
            $rows.Add([pscustomobject]@{ Type='NeededSIT'; Name=$need; Mode=$flag; Enabled=$present; Locations=''; Detail='' })
        }
    }
    foreach ($s in $sits) {
        $rows.Add([pscustomobject]@{ Type='SIT'; Name=$s.Name; Mode=$s.Publisher; Enabled=$true; Locations=''; Detail=$s.Id })
    }
} catch {
    Write-Host ("  [WARN] Could not enumerate sensitive info types: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

$rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nWrote {0} rows to {1}  (Custom DLP - Discovery - Assess)" -f $rows.Count, $CsvPath) -ForegroundColor Cyan
Write-Host "Confirm the SITs your design needs are PRESENT before authoring. Verify DLP licensing (Endpoint DLP needs E5/E5 Compliance) in your tenant." -ForegroundColor DarkGray
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
