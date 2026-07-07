<#
.SYNOPSIS
  Read-only email-authentication posture discovery across all Exchange Online accepted domains
  (SPF / DKIM / DMARC), DNS-aware. Makes no changes.
.DESCRIPTION
  Connects to Exchange Online, enumerates accepted domains, and for each reports the current SPF TXT
  record (with an estimated DNS-lookup count and the all-qualifier), the Exchange Online DKIM signing
  config state (Enabled/Status and whether the selector CNAMEs resolve), and the DMARC record/policy.
  Output is a per-domain posture object you can export as the baseline. Strictly read-only.
.EXAMPLE
  .\Get-EmailAuthPosture.ps1
  # baseline every accepted domain

.EXAMPLE
  .\Get-EmailAuthPosture.ps1 -Domain contoso.com | Format-List
  # baseline a single domain
  (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline)
.NOTES
  Expected results: one posture row per domain. PASS signal = single v=spf1 record with <=10 lookups,
  DKIM Enabled/Valid with resolving CNAMEs, and a v=DMARC1 record present. Read-only: no writes.
#>

[CmdletBinding()]
param(
    [Parameter()] [string[]] $Domain,
    [Parameter()] [string]   $ExchangeEnvironmentName = 'O365Default'  # e.g. O365USGovGCCHigh for GCC High
)

function Ensure-ExoConnected {
    param([string]$Environment)
    try { Get-AcceptedDomain -ErrorAction Stop | Out-Null; return }
    catch {
        Write-Host 'Connecting to Exchange Online...' -ForegroundColor Cyan
        Connect-ExchangeOnline -ExchangeEnvironmentName $Environment -ShowBanner:$false
    }
}

function Get-SpfInfo {
    param([string]$DomainName)
    $lookupTerms = @('include','a','mx','ptr','exists')
    try {
        $txt = Resolve-DnsName -Name $DomainName -Type TXT -ErrorAction Stop |
               Where-Object { $_.Strings -match 'v=spf1' }
    } catch { $txt = $null }
    $records = @($txt | ForEach-Object { ($_.Strings -join '') })
    $spf = $records | Select-Object -First 1
    $qualifier = if ($spf -match '([~\-\+\?])all') { $matches[1] + 'all' } else { $null }
    # Count first-level lookup-causing mechanisms (nested includes are not chased here).
    $lookups = 0
    if ($spf) {
        foreach ($t in $lookupTerms) { $lookups += ([regex]::Matches($spf, "(?i)\b$t[:=]?")).Count }
    }
    [pscustomobject]@{
        RecordCount   = $records.Count
        Record        = $spf
        Qualifier     = $qualifier
        LookupEstimate= $lookups
        LookupWarning = ($lookups -gt 10)
    }
}

function Get-DkimInfo {
    param([string]$DomainName)
    try { $cfg = Get-DkimSigningConfig -Identity $DomainName -ErrorAction Stop } catch { $cfg = $null }
    $s1 = $false; $s2 = $false
    if ($cfg) {
        try { $s1 = [bool](Resolve-DnsName -Type CNAME -Name "selector1._domainkey.$DomainName" -ErrorAction Stop) } catch {}
        try { $s2 = [bool](Resolve-DnsName -Type CNAME -Name "selector2._domainkey.$DomainName" -ErrorAction Stop) } catch {}
    }
    [pscustomobject]@{
        Exists          = [bool]$cfg
        Enabled         = if ($cfg) { $cfg.Enabled } else { $null }
        Status          = if ($cfg) { $cfg.Status }  else { $null }
        Selector1CNAME  = if ($cfg) { $cfg.Selector1CNAME } else { $null }
        Selector1Resolves = $s1
        Selector2Resolves = $s2
    }
}

function Get-DmarcInfo {
    param([string]$DomainName)
    try {
        $txt = Resolve-DnsName -Name "_dmarc.$DomainName" -Type TXT -ErrorAction Stop |
               Where-Object { $_.Strings -match 'v=DMARC1' }
    } catch { $txt = $null }
    $rec = @($txt | ForEach-Object { ($_.Strings -join '') }) | Select-Object -First 1
    $policy = if ($rec -match 'p\s*=\s*(none|quarantine|reject)') { $matches[1] } else { $null }
    $rua    = if ($rec -match 'rua\s*=\s*([^;]+)') { $matches[1].Trim() } else { $null }
    [pscustomobject]@{ Record = $rec; Policy = $policy; Rua = $rua; Present = [bool]$rec }
}

Ensure-ExoConnected -Environment $ExchangeEnvironmentName

$domains = if ($Domain) { $Domain } else {
    (Get-AcceptedDomain | Select-Object -ExpandProperty DomainName)
}

$results = foreach ($d in $domains) {
    Write-Host "Assessing $d ..." -ForegroundColor Cyan
    $spf   = Get-SpfInfo   -DomainName $d
    $dkim  = Get-DkimInfo  -DomainName $d
    $dmarc = Get-DmarcInfo -DomainName $d
    [pscustomobject]@{
        Domain           = $d
        SpfRecordCount   = $spf.RecordCount
        SpfLookupEstimate= $spf.LookupEstimate
        SpfLookupWarning = $spf.LookupWarning
        SpfQualifier     = $spf.Qualifier
        DkimEnabled      = $dkim.Enabled
        DkimStatus       = $dkim.Status
        DkimCnamesResolve= ($dkim.Selector1Resolves -and $dkim.Selector2Resolves)
        DmarcPresent     = $dmarc.Present
        DmarcPolicy      = $dmarc.Policy
        DmarcRua         = $dmarc.Rua
        SpfRecord        = $spf.Record
        DmarcRecord      = $dmarc.Record
    }
}

$results | Format-Table Domain,SpfRecordCount,SpfLookupEstimate,SpfLookupWarning,DkimEnabled,DkimStatus,DkimCnamesResolve,DmarcPresent,DmarcPolicy -AutoSize
Write-Host "`nBaseline complete for $($results.Count) domain(s). This was a read-only assessment." -ForegroundColor Green
$results
