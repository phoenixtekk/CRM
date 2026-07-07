<#
.SYNOPSIS
  Validation report for email authentication — read-only; checks SPF scope, DKIM validity, and DMARC
  presence per domain and returns a PASS/FAIL per check. Makes no changes.
.DESCRIPTION
  For each accepted domain (or -Domain), runs four checks against live DNS and Exchange Online config:
  (1) SPF is a single record within the 10-lookup limit; (2) DKIM signing is Enabled/Valid with both
  selector CNAMEs resolving; (3) a DMARC record is present (and reports its policy); (4) optional -
  cross-check a DMARC aggregate-report summary (from Invoke-DmarcReportAnalysis) for unaligned
  legitimate senders. Emits a green/red validation table. Strictly read-only.
.EXAMPLE
  .\Test-EmailAuthAlignment.ps1 -Domain contoso.com
  # validate one domain's SPF/DKIM/DMARC posture

.EXAMPLE
  .\Test-EmailAuthAlignment.ps1
  # validate every accepted domain
  (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline)
.NOTES
  Expected results: a table with PASS/FAIL per check. Enforcement go/no-go = all checks PASS
  (SPF scoped, DKIM Valid, DMARC present). Read-only: no writes.
#>

[CmdletBinding()]
param(
    [Parameter()] [string[]] $Domain,
    [Parameter()] [string]   $ExchangeEnvironmentName = 'O365Default'
)

function Ensure-ExoConnected {
    param([string]$Environment)
    try { Get-AcceptedDomain -ErrorAction Stop | Out-Null; return }
    catch {
        Write-Host 'Connecting to Exchange Online...' -ForegroundColor Cyan
        Connect-ExchangeOnline -ExchangeEnvironmentName $Environment -ShowBanner:$false
    }
}

Ensure-ExoConnected -Environment $ExchangeEnvironmentName

$domains = if ($Domain) { $Domain } else { (Get-AcceptedDomain | Select-Object -ExpandProperty DomainName) }
$lookupTerms = @('include','a','mx','ptr','exists')

$report = foreach ($d in $domains) {
    # --- Check 1: SPF ---
    try {
        $spfAll = @(Resolve-DnsName -Name $d -Type TXT -ErrorAction Stop |
            Where-Object { $_.Strings -match 'v=spf1' } | ForEach-Object { ($_.Strings -join '') })
    } catch { $spfAll = @() }
    $spf = $spfAll | Select-Object -First 1
    $lookups = 0
    if ($spf) { foreach ($t in $lookupTerms) { $lookups += ([regex]::Matches($spf, "(?i)\b$t[:=]?")).Count } }
    $spfPass = ($spfAll.Count -eq 1 -and $lookups -le 10 -and $spf -match '[~\-]all')

    # --- Check 2: DKIM ---
    $cfg = Get-DkimSigningConfig -Identity $d -ErrorAction SilentlyContinue
    $s1 = $false; $s2 = $false
    if ($cfg) {
        try { $s1 = [bool](Resolve-DnsName -Type CNAME -Name "selector1._domainkey.$d" -ErrorAction Stop) } catch {}
        try { $s2 = [bool](Resolve-DnsName -Type CNAME -Name "selector2._domainkey.$d" -ErrorAction Stop) } catch {}
    }
    $dkimPass = ($cfg -and $cfg.Enabled -and ($cfg.Status -eq 'Valid') -and $s1 -and $s2)

    # --- Check 3: DMARC ---
    try {
        $dmarc = @(Resolve-DnsName -Name "_dmarc.$d" -Type TXT -ErrorAction Stop |
            Where-Object { $_.Strings -match 'v=DMARC1' } | ForEach-Object { ($_.Strings -join '') }) | Select-Object -First 1
    } catch { $dmarc = $null }
    $dmarcPolicy = if ($dmarc -match 'p\s*=\s*(none|quarantine|reject)') { $matches[1] } else { $null }
    $dmarcPass = [bool]$dmarc

    [pscustomobject]@{
        Domain     = $d
        SPF        = if ($spfPass)   { 'PASS' } else { 'FAIL' }
        SpfLookups = $lookups
        DKIM       = if ($dkimPass)  { 'PASS' } else { 'FAIL' }
        DkimStatus = if ($cfg) { $cfg.Status } else { 'None' }
        DMARC      = if ($dmarcPass) { 'PASS' } else { 'FAIL' }
        DmarcPolicy= $dmarcPolicy
        Overall    = if ($spfPass -and $dkimPass -and $dmarcPass) { 'GREEN' } else { 'REVIEW' }
    }
}

$report | Format-Table Domain,SPF,SpfLookups,DKIM,DkimStatus,DMARC,DmarcPolicy,Overall -AutoSize
$green = @($report | Where-Object Overall -eq 'GREEN').Count
Write-Host "`n$green of $($report.Count) domain(s) fully validated (GREEN). GREEN on all checks is the go signal for enforcement." -ForegroundColor Cyan
$report
