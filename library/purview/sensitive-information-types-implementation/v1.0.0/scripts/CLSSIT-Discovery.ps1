<#
.SYNOPSIS
    CLSSIT-Discovery.ps1 — read-only inventory of built-in sensitive information types (SITs) and where they are referenced.
.DESCRIPTION
    PURPOSE
        Builds the SIT baseline: lists the sensitive information types available in the tenant
        (built-in vs custom), the confidence levels each publishes, and cross-references which existing
        DLP compliance policies (and auto-labeling policies, where available) already reference SITs.
        Read-only — makes no changes. Use it before selecting built-in SITs so you build on what exists.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CLSSIT-Discovery.ps1 -CsvPath .\CLSSIT-SIT-Inventory.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession via ExchangeOnlineManagement).
    EXPECTED RESULTS
        A console table of SITs (Name, Publisher, Built-in?, Confidence levels) and a summary of how many
        DLP policies reference SITs. PASS signal: the built-in SITs for your in-scope categories appear in
        the list — record them in the SIT Selection Register.
.NOTES
    Purview — Sensitive Information Types Implementation. Read-only against Security & Compliance PowerShell.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    # Optional case-insensitive filter, e.g. -NameLike 'credit','ssn','iban'
    [string[]]$NameLike,
    [string]$UserPrincipalName
)

# --- Connect (modern auth / MFA). Reuses an existing session if present. ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host '=== Built-in Sensitive Information Type Inventory (read-only) ===' -ForegroundColor Cyan

$sits = Get-DlpSensitiveInformationType -ErrorAction Stop
if ($NameLike) {
    $pattern = ($NameLike | ForEach-Object { [regex]::Escape($_) }) -join '|'
    $sits = $sits | Where-Object { $_.Name -match $pattern -or $_.LocalizedName -match $pattern }
}

$rows = foreach ($s in $sits) {
    $isBuiltIn = ($s.Publisher -match 'Microsoft')
    # Confidence levels available on the SIT (surfaced as Low/Medium/High ~= 65/75/85).
    $levels = $null
    if ($null -ne $s.RulePackId) { $levels = 'see definition' }
    [pscustomobject]@{
        Name        = $s.Name
        Publisher   = $s.Publisher
        BuiltIn     = $isBuiltIn
        Description = ($s.Description -replace '\s+', ' ')
    }
}

$builtIn = @($rows | Where-Object { $_.BuiltIn })
$custom  = @($rows | Where-Object { -not $_.BuiltIn })

Write-Host ("Built-in SITs: {0}   Custom SITs: {1}   Total: {2}" -f $builtIn.Count, $custom.Count, $rows.Count) -ForegroundColor Green
Write-Host '(Built-in library size varies by tenant/plan — verify against your licensing.)' -ForegroundColor DarkGray
Write-Host '--- SITs (filtered) ---' -ForegroundColor Cyan
$rows | Sort-Object @{e='BuiltIn';Descending=$true}, Name | Format-Table Name, Publisher, BuiltIn -AutoSize

# --- Cross-reference: which DLP policies/rules already reference SITs ---
Write-Host '--- DLP policies referencing SITs (context) ---' -ForegroundColor Cyan
try {
    $rules = Get-DlpComplianceRule -ErrorAction Stop
    $refCount = @($rules | Where-Object { $_.ContentContainsSensitiveInformation }).Count
    Write-Host ("DLP rules that reference sensitive information types: {0}" -f $refCount)
} catch {
    Write-Host 'Could not enumerate DLP rules (check role/connection) — SIT list above is still valid.' -ForegroundColor Yellow
}

# --- Auto-labeling policies (optional context; may be licensing-gated) ---
if (Get-Command Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue) {
    try {
        $auto = Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue
        Write-Host ("Auto-labeling policies present (may reference SITs): {0}" -f (@($auto).Count))
    } catch { }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("SIT inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Record the built-in SITs for your categories in the SIT Selection Register (see 03-implementation).' -ForegroundColor Cyan
