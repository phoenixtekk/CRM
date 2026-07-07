<#
.SYNOPSIS
  Read-only test of the Autodiscover (Discovery) layer for a user/domain: DNS records, the
  Autodiscover v2 JSON endpoint, and (hybrid) the on-prem SCP internal URI.
.DESCRIPTION
  Resolves the autodiscover.<domain> CNAME and _autodiscover._tcp SRV record, queries the
  Autodiscover v2 JSON endpoint, and (if EXO/on-prem cmdlets are available) reports the SCP
  AutoDiscoverServiceInternalUri from Get-ClientAccessService. Purely read-only. Populates the
  D1 (Discovery) node of the Diagnostic Playbook and Gate 1 of Testing & Validation.
.EXAMPLE
  .\Test-AutodiscoverEndpoints.ps1 -EmailAddress user@contoso.com
  # Tests Autodiscover DNS + v2 JSON for the user's domain.
.EXAMPLE
  .\Test-AutodiscoverEndpoints.ps1 -EmailAddress user@contoso.com -ExpectedCname autodiscover.outlook.com
  (PowerShell 5.1+/7+; ExchangeOnlineManagement optional for SCP check)
.NOTES
  Expected results: PASS when the CNAME resolves to the expected host (autodiscover.outlook.com
  for Commercial cloud-only - verify the sovereign host for GCC High/DoD) and the v2 JSON
  endpoint returns an HTTP 200 with a protocol URL. Any FAIL is the pass-fail signal for D1.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('.+@.+\..+')]
    [string]$EmailAddress,

    [Parameter()]
    [string]$ExpectedCname = 'autodiscover.outlook.com',

    [Parameter()]
    [switch]$CheckScp
)

$domain = ($EmailAddress -split '@')[1]
Write-Host "Autodiscover diagnostics for $EmailAddress (domain: $domain)" -ForegroundColor Cyan
Write-Host "Expected CNAME target: $ExpectedCname  (verify sovereign host for GCC High/DoD)" -ForegroundColor DarkGray

$report = [ordered]@{}

# 1. CNAME
try {
    $cname = Resolve-DnsName -Name "autodiscover.$domain" -Type CNAME -ErrorAction Stop |
             Where-Object { $_.Type -eq 'CNAME' } | Select-Object -First 1
    $target = $cname.NameHost
    $report['CNAME_autodiscover'] = $target
    $report['CNAME_Result'] = if ($target -like "*$ExpectedCname*") { 'PASS' } else { "REVIEW (got $target)" }
}
catch { $report['CNAME_autodiscover'] = "FAIL: $($_.Exception.Message)"; $report['CNAME_Result'] = 'FAIL' }

# 2. SRV fallback
try {
    $srv = Resolve-DnsName -Name "_autodiscover._tcp.$domain" -Type SRV -ErrorAction Stop |
           Where-Object { $_.Type -eq 'SRV' } | Select-Object -First 1
    $report['SRV_autodiscover'] = if ($srv) { "$($srv.NameTarget):$($srv.Port)" } else { 'none' }
}
catch { $report['SRV_autodiscover'] = 'none (not configured - ok if CNAME resolves)' }

# 3. Autodiscover v2 JSON endpoint
$v2Url = "https://autodiscover.$domain/autodiscover/autodiscover.json?Email=$EmailAddress&Protocol=Autodiscoverv1"
try {
    $resp = Invoke-WebRequest -Uri $v2Url -UseBasicParsing -MaximumRedirection 5 -TimeoutSec 30 -ErrorAction Stop
    $report['AutodiscoverV2_Status'] = $resp.StatusCode
    $report['AutodiscoverV2_Body']   = ($resp.Content | Select-Object -First 1)
    $report['AutodiscoverV2_Result'] = if ($resp.StatusCode -eq 200) { 'PASS' } else { "REVIEW ($($resp.StatusCode))" }
}
catch {
    $report['AutodiscoverV2_Status'] = "FAIL: $($_.Exception.Message)"
    $report['AutodiscoverV2_Result'] = 'FAIL'
}

# 4. SCP (hybrid / on-prem) - optional
if ($CheckScp) {
    if (Get-Command Get-ClientAccessService -ErrorAction SilentlyContinue) {
        try {
            $scp = Get-ClientAccessService | Select-Object Name, AutoDiscoverServiceInternalUri
            $report['SCP_InternalUri'] = ($scp | ForEach-Object { "$($_.Name)=$($_.AutoDiscoverServiceInternalUri)" }) -join '; '
        } catch { $report['SCP_InternalUri'] = "FAIL: $($_.Exception.Message)" }
    } else {
        $report['SCP_InternalUri'] = 'N/A - Get-ClientAccessService not available (run in on-prem EMS for hybrid SCP)'
    }
}

[pscustomobject]$report | Format-List
Write-Host "Cross-check externally with the Remote Connectivity Analyzer Autodiscover test (verify sovereign RCA host for Government clouds)." -ForegroundColor DarkGray
[pscustomobject]$report
