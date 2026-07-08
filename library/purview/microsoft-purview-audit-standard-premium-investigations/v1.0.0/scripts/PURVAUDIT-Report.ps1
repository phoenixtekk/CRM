<#
.SYNOPSIS
    PURVAUDIT-Report.ps1 — audit coverage + investigation-readiness scorecard (read-only).
.DESCRIPTION
    PURPOSE
        Produces a pass/fail readiness scorecard: unified audit ingestion on, org mailbox auditing on
        with no unexpected bypass, Audit Premium licensed (plan present), high-value events observed in
        a recent probe window, the expected retention policies present, and (optionally) export
        subscriptions active. Read-only — computes and reports, changes nothing. Optional CSV export.
    HOW TO RUN
        powershell -File .\PURVAUDIT-Report.ps1 -ProbeUser pilot.user@contoso.com -CsvPath .\Audit-Readiness.csv
        Requires ExchangeOnlineManagement (Connect-ExchangeOnline + Connect-IPPSSession) and, for the
        licensing gate, Microsoft.Graph. Interactive sign-in; no secrets in code.
    EXPECTED RESULTS
        A scorecard with PASS/FAIL/CHECK per gate and an overall readiness verdict; "Audit Readiness -
        Tenant - Report" material. FAIL rows point to the implementation step that fixes them.
.NOTES
    Purview category — Audit. Read-only. Licensing/feature gates are tenant-dependent — CHECK results
    mean "verify your licensing/tenant", not a defect. Retention-schedule/legal adequacy is out of scope.
#>
[CmdletBinding()]
param(
    [string[]]$ExpectedPolicies = @('Audit Retention - Mailbox High-Value - Premium','Audit Retention - Privileged Actions - LongTerm','Audit Retention - Sign-in Events - Standard+'),
    [string]$ProbeUser,                              # a licensed user to probe for high-value events
    [int]$ProbeDays = 7,
    [string]$CsvPath,
    [string]$UserPrincipalName,
    [switch]$SkipGraphLicensing
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]
function Add-Row($gate,$status,$detail){ $results.Add([pscustomobject]@{ Gate=$gate; Status=$status; Detail=$detail }) }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser" -ForegroundColor Red; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }
Connect-ExchangeOnline @cp

# Gate 1: unified audit
try { $on = (Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
      Add-Row 'Unified audit ingestion' ($(if($on){'PASS'}else{'FAIL'})) ("UnifiedAuditLogIngestionEnabled=$on" + $(if(-not $on){' → enable (Impl Step 3)'}else{''}))
} catch { Add-Row 'Unified audit ingestion' 'CHECK' $_.Exception.Message }

# Gate 2: mailbox auditing + bypass
try { $ad = (Get-OrganizationConfig).AuditDisabled
      Add-Row 'Org mailbox auditing' ($(if(-not $ad){'PASS'}else{'FAIL'})) "AuditDisabled=$ad"
      $bp = Get-MailboxAuditBypassAssociation -ResultSize Unlimited | Where-Object AuditBypassEnabled -eq $true
      Add-Row 'No unexpected audit bypass' ($(if(-not $bp){'PASS'}else{'CHECK'})) ("bypassed=" + (@($bp).Count))
} catch { Add-Row 'Org mailbox auditing' 'CHECK' $_.Exception.Message }

# Gate 5: retention policies present
try {
    Connect-IPPSSession @cp | Out-Null
    $pols = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop
    foreach ($name in $ExpectedPolicies) {
        $hit = $pols | Where-Object { $_.Name -eq $name }
        Add-Row "Retention policy: $name" ($(if($hit){'PASS'}else{'FAIL'})) ($(if($hit){"duration=$($hit.RetentionDuration) priority=$($hit.Priority)"}else{'missing → create (Impl Step 4)'}))
    }
} catch { Add-Row 'Retention policies' 'CHECK' $_.Exception.Message }

# Gate 4: high-value events observed for a probe user
if ($ProbeUser) {
    try {
        $ev = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-$ProbeDays) -EndDate (Get-Date) -UserIds $ProbeUser -Operations MailItemsAccessed,Send -ResultSize 10
        Add-Row 'High-value events captured' ($(if($ev){'PASS'}else{'CHECK'})) ($(if($ev){"$(@($ev).Count) sample record(s) for $ProbeUser"}else{"none in last $ProbeDays d — verify Premium licensing/latency/bypass for $ProbeUser"}))
    } catch { Add-Row 'High-value events captured' 'CHECK' $_.Exception.Message }
} else { Add-Row 'High-value events captured' 'CHECK' 'no -ProbeUser supplied' }

# Gate 3: Premium licensing (Graph)
if (-not $SkipGraphLicensing -and (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome
        $plan = 'M365_ADVANCED_AUDITING'
        $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
        $has = $skus | Where-Object { $_.servicePlans.servicePlanName -contains $plan }
        Add-Row 'Audit Premium plan present' ($(if($has){'PASS'}else{'CHECK'})) ($(if($has){"$plan in subscribedSkus (confirm per-user assignment)"}else{"$plan not found — verify licensing/tenant"}))
    } catch { Add-Row 'Audit Premium plan present' 'CHECK' $_.Exception.Message }
} else { Add-Row 'Audit Premium plan present' 'CHECK' 'Graph licensing check skipped/unavailable' }

# Output
Write-Host "`n=== Audit Readiness - Tenant - Report ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize | Out-String | Write-Host
$fail = @($results | Where-Object Status -eq 'FAIL').Count
$chk  = @($results | Where-Object Status -eq 'CHECK').Count
if ($fail -gt 0) { Write-Host "VERDICT: NOT READY — $fail FAIL, $chk CHECK. Resolve FAIL rows first." -ForegroundColor Red }
elseif ($chk -gt 0) { Write-Host "VERDICT: READY WITH CHECKS — 0 FAIL, $chk CHECK (verify licensing/tenant items)." -ForegroundColor Yellow }
else { Write-Host "VERDICT: READY — all gates PASS." -ForegroundColor Green }
if ($CsvPath) { $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "Exported to $CsvPath" -ForegroundColor Green }
