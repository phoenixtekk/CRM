<#
.SYNOPSIS
    EXOMIGG-Validation.ps1 — Read-only pass/fail readiness checks for a GCC High Exchange Online tenant-to-tenant migration.
.DESCRIPTION
    PURPOSE
        Validates that one GCC High tenant is ready for the migration: required PowerShell modules present,
        a successful US Gov connection, migration-relevant admin roles assigned, sufficient mailbox licensing,
        and reachability of the GCC High service endpoints. Run once per tenant (source and target).
        Placeholders use plain text like your-admin-upn.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EXOMIGG-Validation.ps1 -AdminUpn your-admin-upn
        (Connects with -Environment USGov / -ExchangeEnvironmentName O365USGovGCCHigh)
    EXPECTED RESULTS
        A table of checks each marked PASS or FAIL, and an overall result. PASS overall = ready for the next phase
        gate. Any FAIL points to the matching item in 06-troubleshooting.md.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph/EXO US Gov endpoints. No changes are made.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $AdminUpn,
    [Parameter(Mandatory = $false)] [int] $RequiredMailboxLicenses = 0
)

$ErrorActionPreference = 'Continue'
$results = New-Object System.Collections.Generic.List[object]
function Add-Check($name, $pass, $detail) {
    $results.Add([pscustomobject]@{ Check = $name; Result = ($(if ($pass) {'PASS'} else {'FAIL'})); Detail = $detail })
}

# --- Endpoint reachability (GCC High .us) ---
$endpoints = 'login.microsoftonline.us','graph.microsoft.us','outlook.office365.us'
foreach ($e in $endpoints) {
    $ok = Test-Connection -ComputerName $e -Count 1 -Quiet -ErrorAction SilentlyContinue
    if (-not $ok) { $ok = [bool](Resolve-DnsName -Name $e -ErrorAction SilentlyContinue) }
    Add-Check "Endpoint reachable: $e" $ok "GCC High endpoint (see 06-troubleshooting.md #10 if FAIL)"
}

# --- Modules ---
$exo = Get-Module -ListAvailable ExchangeOnlineManagement | Sort-Object Version -Descending | Select-Object -First 1
Add-Check "Module: ExchangeOnlineManagement" ([bool]$exo) ("Version " + ($exo.Version))
$mg = Get-Module -ListAvailable Microsoft.Graph.Authentication | Sort-Object Version -Descending | Select-Object -First 1
Add-Check "Module: Microsoft.Graph" ([bool]$mg) ("Version " + ($mg.Version))

# --- Connections (must use US Gov env) ---
$exoConnected = $false; $mgConnected = $false
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh -UserPrincipalName $AdminUpn -ShowBanner:$false
    $exoConnected = $true
} catch { }
Add-Check "Connect: Exchange Online (O365USGovGCCHigh)" $exoConnected "If FAIL, tool likely hit Commercial cloud (06-troubleshooting.md #1)"

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Environment USGov -Scopes 'Organization.Read.All','Directory.Read.All' -NoWelcome
    $ctx = Get-MgContext
    $mgConnected = ($ctx.Environment -eq 'USGov')
} catch { }
Add-Check "Connect: Microsoft Graph (USGov)" $mgConnected "Get-MgContext.Environment must equal USGov"

# --- Cloud confirmation (R0) ---
if ($mgConnected) {
    $org = Get-MgOrganization
    $gccHigh = [bool](($org.VerifiedDomains | Where-Object { $_.Name -like '*.onmicrosoft.us' }))
    Add-Check "Tenant is GCC High (R0)" $gccHigh "Requires a *.onmicrosoft.us domain"
}

# --- Roles (R2) ---
if ($mgConnected) {
    $ga = Get-MgDirectoryRole -All | Where-Object { $_.DisplayName -eq 'Global Administrator' }
    $gaHasMembers = $false
    if ($ga) { $gaHasMembers = [bool](Get-MgDirectoryRoleMember -DirectoryRoleId $ga.Id -ErrorAction SilentlyContinue) }
    Add-Check "Role: Global Administrator assigned" $gaHasMembers "Also confirm Exchange 'Organization Management' + 'Move Mailboxes' in admin.exchange.office365.us"
}

# --- Licensing (R3) ---
if ($mgConnected -and $RequiredMailboxLicenses -gt 0) {
    $skus = Get-MgSubscribedSku
    $available = ($skus | ForEach-Object { $_.PrepaidUnits.Enabled } | Measure-Object -Sum).Sum
    Add-Check "Licensing: >= $RequiredMailboxLicenses mailbox licenses" ($available -ge $RequiredMailboxLicenses) "Enabled units total: $available"
    $hasMig = [bool]($skus | Where-Object { $_.SkuPartNumber -match 'Cross.?Tenant|Migration' })
    Add-Check "Licensing: Cross-Tenant User Data Migration add-on (native only)" $hasMig "Required for NATIVE moves; verify orderability on Gov agreement (R3)"
}

# --- Report ---
Write-Host "`n=== EXOMIGG Validation Results ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$overall = -not ($results | Where-Object { $_.Result -eq 'FAIL' })
if ($overall) {
    Write-Host "OVERALL: PASS — ready for the next phase gate." -ForegroundColor Green
} else {
    Write-Host "OVERALL: FAIL — resolve the FAIL rows above before proceeding (see 06-troubleshooting.md)." -ForegroundColor Red
}

if ($exoConnected) { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue }
if ($mgConnected)  { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null }
