<#
.SYNOPSIS
    EXOMIGG-Discovery.ps1 — Read-only inventory of a GCC High tenant for an Exchange Online tenant-to-tenant migration.
.DESCRIPTION
    PURPOSE
        Collects a baseline for one GCC High (US Government L4) Microsoft 365 tenant: detected cloud/environment,
        mailbox inventory and sizes, licensing (including the Cross-Tenant User Data Migration add-on), the
        migrating domain's DNS records (MX/Autodiscover/SPF/DKIM/DMARC), and admin-role holders.
        Run once per tenant (source, then target). Placeholders use plain text like your-admin-upn and your-domain.com.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EXOMIGG-Discovery.ps1 -AdminUpn your-admin-upn -Domain your-domain.com -OutputFolder .\EXOMIGG-baseline
        (Uses Graph scope Directory.Read.All/Organization.Read.All via -Environment USGov, and
         Exchange Online via -ExchangeEnvironmentName O365USGovGCCHigh)
    EXPECTED RESULTS
        Console summary plus CSV/JSON files written to the output folder. PASS = environment reports GCC High/USGov
        and files are produced with no connection errors. FAIL = wrong-cloud auth error (see 06-troubleshooting.md #1).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph/EXO US Gov endpoints. No changes are made.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $AdminUpn,
    [Parameter(Mandatory = $false)] [string] $Domain,
    [Parameter(Mandatory = $false)] [string] $OutputFolder = ".\EXOMIGG-baseline"
)

$ErrorActionPreference = 'Stop'
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# --- Connect to US Gov endpoints (GCC High) ---
Write-Section "Connecting to GCC High (US Gov) endpoints"
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh -UserPrincipalName $AdminUpn -ShowBanner:$false
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Environment USGov -Scopes 'Organization.Read.All','User.Read.All','Directory.Read.All' -NoWelcome
} catch {
    Write-Host "FAIL: could not connect to GCC High endpoints. Verify -ExchangeEnvironmentName O365USGovGCCHigh / -Environment USGov and login.microsoftonline.us reachability. See 06-troubleshooting.md #1." -ForegroundColor Red
    throw
}

# --- Environment / cloud confirmation ---
Write-Section "Environment"
$org = Get-MgOrganization
$envInfo = [pscustomobject]@{
    TenantId          = $org.Id
    DisplayName       = $org.DisplayName
    DefaultDomain     = ($org.VerifiedDomains | Where-Object { $_.IsDefault }).Name
    OnMicrosoftDomain = ($org.VerifiedDomains | Where-Object { $_.Name -like '*.onmicrosoft.us' }).Name
    GraphEnvironment  = (Get-MgContext).Environment
    LooksLikeGccHigh  = [bool](($org.VerifiedDomains | Where-Object { $_.Name -like '*.onmicrosoft.us' }))
}
$envInfo | Format-List
$envInfo | ConvertTo-Json | Out-File (Join-Path $OutputFolder "environment-$stamp.json")
if (-not $envInfo.LooksLikeGccHigh) {
    Write-Host "WARNING: no *.onmicrosoft.us domain found — confirm this is a GCC High tenant (R0)." -ForegroundColor Yellow
}

# --- Mailbox inventory ---
Write-Section "Mailbox inventory"
$mailboxes = Get-Mailbox -ResultSize Unlimited | Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails, ExchangeGuid, Alias
$stats = foreach ($mb in $mailboxes) {
    $s = Get-MailboxStatistics -Identity $mb.PrimarySmtpAddress -ErrorAction SilentlyContinue
    [pscustomobject]@{
        DisplayName        = $mb.DisplayName
        PrimarySmtpAddress = $mb.PrimarySmtpAddress
        Type               = $mb.RecipientTypeDetails
        ExchangeGuid       = $mb.ExchangeGuid
        ItemCount          = $s.ItemCount
        TotalItemSize      = $s.TotalItemSize
    }
}
$stats | Export-Csv (Join-Path $OutputFolder "mailboxes-$stamp.csv") -NoTypeInformation
Write-Host ("Mailboxes: {0}" -f ($stats | Measure-Object).Count)

# --- Licensing (incl. Cross-Tenant User Data Migration add-on) ---
Write-Section "Licensing (subscribed SKUs)"
$skus = Get-MgSubscribedSku | Select-Object SkuPartNumber, SkuId,
    @{n='Enabled';e={$_.PrepaidUnits.Enabled}}, ConsumedUnits
$skus | Export-Csv (Join-Path $OutputFolder "licensing-$stamp.csv") -NoTypeInformation
$skus | Format-Table -AutoSize
if (-not ($skus | Where-Object { $_.SkuPartNumber -match 'Cross.?Tenant|Migration' })) {
    Write-Host "NOTE: no obvious Cross-Tenant User Data Migration SKU detected — required for NATIVE moves only. Verify orderability on your Gov agreement (R3)." -ForegroundColor Yellow
}

# --- DNS for migrating domain ---
if ($Domain) {
    Write-Section "DNS for $Domain"
    $dns = [ordered]@{}
    try { $dns.MX = (Resolve-DnsName -Name $Domain -Type MX -ErrorAction Stop | Select-Object NameExchange, Preference) } catch { $dns.MX = "lookup failed" }
    try { $dns.Autodiscover = (Resolve-DnsName -Name "autodiscover.$Domain" -Type CNAME -ErrorAction Stop | Select-Object NameHost) } catch { $dns.Autodiscover = "none/failed" }
    try { $dns.SPF = (Resolve-DnsName -Name $Domain -Type TXT -ErrorAction Stop | Where-Object { $_.Strings -match 'spf1' } | Select-Object -ExpandProperty Strings) } catch { $dns.SPF = "none/failed" }
    try { $dns.DMARC = (Resolve-DnsName -Name "_dmarc.$Domain" -Type TXT -ErrorAction Stop | Select-Object -ExpandProperty Strings) } catch { $dns.DMARC = "none/failed" }
    $dns | ConvertTo-Json -Depth 5 | Out-File (Join-Path $OutputFolder "dns-$Domain-$stamp.json")
    $dns.GetEnumerator() | ForEach-Object { Write-Host ("{0}: {1}" -f $_.Key, ($_.Value | Out-String).Trim()) }
} else {
    Write-Host "No -Domain supplied; skipping DNS capture." -ForegroundColor Yellow
}

# --- Admin role holders (migration-relevant) ---
Write-Section "Directory role holders"
$roles = Get-MgDirectoryRole -All | Where-Object { $_.DisplayName -match 'Global Administrator|Exchange Administrator' }
$roleRows = foreach ($r in $roles) {
    Get-MgDirectoryRoleMember -DirectoryRoleId $r.Id | ForEach-Object {
        [pscustomobject]@{ Role = $r.DisplayName; MemberId = $_.Id }
    }
}
$roleRows | Export-Csv (Join-Path $OutputFolder "roles-$stamp.csv") -NoTypeInformation

Write-Section "Discovery complete"
Write-Host "Baseline written to: $OutputFolder" -ForegroundColor Green
Write-Host "Reminder: also capture Exchange 'Organization Management' and 'Move Mailboxes' role membership in admin.exchange.office365.us (R2)." -ForegroundColor Yellow

Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
