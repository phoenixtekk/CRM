<#
.SYNOPSIS
  SPF scope/health helper — read-only; recursively resolves an SPF record, counts the real DNS lookups
  against the 10-lookup limit, and lists each include chain. Makes no changes.
.DESCRIPTION
  Chases the SPF record for a domain the way a receiver does: it follows nested include:/redirect=/a/mx
  mechanisms and counts every DNS-lookup-consuming term (RFC 7208 limit is 10). Reports the total, warns
  if over the limit, and prints the include tree so you can see which sender is consuming the budget.
  Purely DNS resolution — no Exchange connection and no writes.
.EXAMPLE
  .\Get-SpfLookupHealth.ps1 -Domain contoso.com
  # count lookups and show the include tree

.EXAMPLE
  .\Get-SpfLookupHealth.ps1 -Domain contoso.com -Verbose
  # include per-mechanism detail
  (PowerShell 5.1+/7+; uses Resolve-DnsName — read-only DNS queries only)
.NOTES
  Expected results: a lookup count and PASS/FAIL vs 10. PASS = TotalLookups <= 10. Over 10 means SPF
  permerror at receivers — consolidate includes or move a sender to a subdomain.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $Domain,
    [Parameter()] [int] $MaxLookups = 10
)

$script:total = 0
$script:tree  = New-Object System.Collections.Generic.List[string]
$lookupMechs  = 'include','a','mx','ptr','exists'

function Get-SpfString {
    param([string]$Name)
    try {
        $txt = Resolve-DnsName -Name $Name -Type TXT -ErrorAction Stop |
               Where-Object { $_.Strings -match 'v=spf1' } |
               ForEach-Object { ($_.Strings -join '') }
        return ($txt | Select-Object -First 1)
    } catch { return $null }
}

function Resolve-Spf {
    param([string]$Name, [int]$Depth = 0)
    $indent = '  ' * $Depth
    $spf = Get-SpfString -Name $Name
    if (-not $spf) { $script:tree.Add("$indent- $Name : (no SPF record)"); return }
    $script:tree.Add("$indent- $Name : $spf")

    foreach ($term in ($spf -split '\s+')) {
        $t = $term.TrimStart('+','~','-','?')
        switch -Regex ($t) {
            '^include:(.+)$'   { $script:total++; Resolve-Spf -Name $matches[1] -Depth ($Depth + 1) }
            '^redirect=(.+)$'  { $script:total++; Resolve-Spf -Name $matches[1] -Depth ($Depth + 1) }
            '^(a|mx|ptr|exists)([:=].+)?$' { $script:total++; Write-Verbose "$indent  lookup: $t" }
            default { }
        }
    }
}

Write-Host "Resolving SPF for $Domain ..." -ForegroundColor Cyan
Resolve-Spf -Name $Domain

Write-Host "`nInclude tree:" -ForegroundColor Cyan
$script:tree | ForEach-Object { Write-Host $_ }

$pass = ($script:total -le $MaxLookups)
Write-Host ("`nTotal DNS-lookup mechanisms: {0} (limit {1})" -f $script:total, $MaxLookups) -ForegroundColor Cyan
if ($pass) {
    Write-Host "PASS — within the SPF lookup limit." -ForegroundColor Green
} else {
    Write-Host "FAIL — exceeds the $MaxLookups-lookup limit (receivers will permerror). Consolidate includes or use a sending subdomain." -ForegroundColor Red
}

[pscustomobject]@{
    Domain       = $Domain
    TotalLookups = $script:total
    Limit        = $MaxLookups
    WithinLimit  = $pass
}
