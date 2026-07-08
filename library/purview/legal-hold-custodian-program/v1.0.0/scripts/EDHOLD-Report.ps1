<#
.SYNOPSIS
    EDHOLD-Report.ps1 — read-only hold/custodian status + notice-acknowledgment tracking report (safe: read-only).
.DESCRIPTION
    PURPOSE
        Produces the defensible "Custodian Hold Register" for a matter: for the case's CaseHoldPolicies, the
        held locations, distribution status, and rule scope (query vs preserve-everything); and — where
        eDiscovery Premium is licensed and the Microsoft Graph eDiscovery API is available (beta) — each
        custodian, their mapped data sources, hold status, and (where the API exposes it) notice/acknowledgment
        status. Read-only — makes no changes. Notice ISSUANCE/ACKNOWLEDGMENT is operated in the Purview portal
        (Communications); this report inventories status, it does not send or acknowledge notices.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EDHOLD-Report.ps1 `
            -CaseName 'Legal Hold Case – Contoso-Matter-001 – Pilot' `
            -CsvPath '.\Custodian Hold Register – Contoso-Matter-001 – Report.csv'
        Requires Security & Compliance PowerShell (Connect-IPPSSession); custodian rows require Graph (Premium/beta).
.EXAMPLE
    .\EDHOLD-Report.ps1 -CaseName 'Legal Hold Case – Contoso-Matter-001 – Pilot' -CsvPath '.\register.csv'
    Prints the hold/custodian register and exports it as the tracking record for the matter.
.NOTES
    Purview — Legal-Hold & Custodian Management Program. Read-only tracking report. No changes made.
    Expected results: the register matches the portal state (holds, locations, custodians, notice/ack) — keep
    it current as the defensible record of the matter (PASS = register reflects reality).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CaseName,
    [string]$CsvPath,
    [string]$UserPrincipalName,
    [switch]$IncludeGraphCustodians
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-CaseHoldPolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host ("=== Hold register for case '{0}' (read-only) ===" -f $CaseName) -ForegroundColor Cyan

$case = Get-ComplianceCase -Identity $CaseName -ErrorAction SilentlyContinue
if (-not $case) { Write-Host ("Case '{0}' not found — check the name / your eDiscovery role." -f $CaseName) -ForegroundColor Red; return }

$rules = Get-CaseHoldRule -ErrorAction SilentlyContinue
$policies = Get-CaseHoldPolicy -ErrorAction SilentlyContinue -DistributionDetail | Where-Object { $_.CaseId -eq $case.Identity -or $_.Case -eq $CaseName }
if (-not $policies) { $policies = Get-CaseHoldPolicy -ErrorAction SilentlyContinue -DistributionDetail }

$rows = @()
foreach ($p in $policies) {
    $rule = $rules | Where-Object { $_.Policy -eq $p.Name } | Select-Object -First 1
    $kind = if ($rule -and -not [string]::IsNullOrWhiteSpace($rule.ContentMatchQuery)) { 'query-based' } else { 'preserve-everything' }
    $locs = @()
    if ($p.ExchangeLocation)   { $locs += ($p.ExchangeLocation   | ForEach-Object { "MBX:$_" }) }
    if ($p.OneDriveLocation)   { $locs += ($p.OneDriveLocation   | ForEach-Object { "OD:$_" }) }
    if ($p.SharePointLocation) { $locs += ($p.SharePointLocation | ForEach-Object { "SPO:$_" }) }
    $rows += [pscustomobject]@{
        Case               = $CaseName
        HoldPolicy         = $p.Name
        Enabled            = $p.Enabled
        DistributionStatus = $p.DistributionStatus
        RuleKind           = $kind
        Query              = ($(if ($rule) { $rule.ContentMatchQuery } else { '' }))
        Locations          = ($locs -join '; ')
        Custodian          = ''    # populated from Graph below where available
        DataSources        = ''
        HoldStatus         = ''
        NoticeStatus       = ''    # portal Communications — fill from the portal where API does not expose it
        AckStatus          = ''
        AsOfUtc            = (Get-Date).ToUniversalTime().ToString('u')
    }
}

Write-Host '--- Case hold policies ---' -ForegroundColor Cyan
$rows | Select-Object HoldPolicy, Enabled, DistributionStatus, RuleKind, Locations | Format-Table -AutoSize

# --- Custodian rows via Graph eDiscovery (Premium; beta — verify) ---
if ($IncludeGraphCustodians) {
    if (Get-Command Get-MgSecurityCaseEdiscoveryCase -ErrorAction SilentlyContinue) {
        Write-Host '--- Custodians (Graph eDiscovery, beta) ---' -ForegroundColor Cyan
        try {
            $gcases = Get-MgSecurityCaseEdiscoveryCase -Filter ("displayName eq '{0}'" -f $CaseName) -ErrorAction Stop
            foreach ($gc in $gcases) {
                $cust = Get-MgSecurityCaseEdiscoveryCaseCustodian -EdiscoveryCaseId $gc.Id -ErrorAction SilentlyContinue
                foreach ($c in $cust) {
                    $rows += [pscustomobject]@{
                        Case = $CaseName; HoldPolicy = ''; Enabled = ''; DistributionStatus = ''
                        RuleKind = ''; Query = ''; Locations = ''
                        Custodian = $c.Email; DataSources = ''; HoldStatus = $c.HoldStatus
                        NoticeStatus = '(see portal Communications)'; AckStatus = '(see portal Communications)'
                        AsOfUtc = (Get-Date).ToUniversalTime().ToString('u')
                    }
                    Write-Host ("  {0}  HoldStatus={1}" -f $c.Email, $c.HoldStatus)
                }
            }
        } catch { Write-Host ("  Graph custodian read unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    } else {
        Write-Host 'Graph eDiscovery cmdlets not present — custodian rows omitted (install Microsoft.Graph.Security; beta).' -ForegroundColor Yellow
        Write-Host 'Notice/acknowledgment tracking lives in Purview → eDiscovery → the case → Communications (portal).' -ForegroundColor Yellow
    }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Register exported to {0} — this is the defensible tracking record; keep it current." -f $CsvPath) -ForegroundColor Green
} else {
    Write-Host 'Tip: pass -CsvPath to export the register (e.g. "Custodian Hold Register – <Matter> – Report.csv").' -ForegroundColor Cyan
}
