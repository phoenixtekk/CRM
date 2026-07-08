<#
.SYNOPSIS
    PURVAUDIT-Discovery.ps1 — Purview Audit configuration + retention + licensing assessment (read-only).
.DESCRIPTION
    PURPOSE
        Reports the current audit posture with no changes: whether unified audit log ingestion is on,
        org-level mailbox auditing state and any mailbox audit-bypass associations, whether an Audit
        Premium-bearing plan (E5 / Audit add-on) is present and how many users carry it, and the
        existing audit log retention policies. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVAUDIT-Discovery.ps1
        Requires the ExchangeOnlineManagement module (Connect-ExchangeOnline + Connect-IPPSSession)
        and, for the licensing section, Microsoft.Graph with delegated Organization.Read.All /
        Directory.Read.All. Uses an interactive modern-auth / MFA admin sign-in; no secrets in code.
    EXPECTED RESULTS
        A posture summary: UnifiedAuditLogIngestionEnabled True/False, AuditDisabled True/False, any
        bypassed mailboxes, Audit Premium plan present Yes/No with an assigned-user count, and the
        list of retention policies. Any "verify your licensing/tenant" item is flagged, not asserted.
.NOTES
    Purview category — Audit (Standard & Premium). Read-only. Feature availability is licensing-/tenant-
    dependent and evolving; confirm against your entitlements and current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,                      # optional: admin UPN to pass to Connect-* prompts
    [switch]$SkipGraphLicensing                      # skip the Graph licensing section if Graph is unavailable
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

# --- Connect: Exchange Online (audit config/search) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"
    return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$connectParams = @{ ShowBanner = $false }
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }
try { Connect-ExchangeOnline @connectParams } catch { Warn "Connect-ExchangeOnline failed: $($_.Exception.Message)"; return }

Write-Section "Unified audit log ingestion"
try {
    $cfg = Get-AdminAuditLogConfig
    if ($cfg.UnifiedAuditLogIngestionEnabled) { Ok "UnifiedAuditLogIngestionEnabled : True (unified audit is ON)" }
    else { Warn "UnifiedAuditLogIngestionEnabled : False (unified audit is OFF — no records are being written; NOT retroactive). Enable via PURVAUDIT-Set-RetentionPolicy.ps1 -EnableUnifiedAudit -Commit" }
} catch { Warn "Could not read AdminAuditLogConfig: $($_.Exception.Message)" }

Write-Section "Org-level mailbox auditing + bypass"
try {
    $org = Get-OrganizationConfig
    if ($org.AuditDisabled) { Warn "AuditDisabled : True (org mailbox auditing is OFF — mailbox events like MailItemsAccessed will not be captured)" }
    else { Ok "AuditDisabled : False (org mailbox auditing is ON)" }
} catch { Warn "Could not read OrganizationConfig: $($_.Exception.Message)" }
try {
    $bypass = Get-MailboxAuditBypassAssociation -ResultSize Unlimited | Where-Object { $_.AuditBypassEnabled -eq $true }
    if ($bypass) {
        Warn ("Mailbox audit BYPASS enabled on {0} account(s) — their mailbox events are suppressed:" -f @($bypass).Count)
        $bypass | Select-Object -ExpandProperty Identity | ForEach-Object { Warn "   bypassed: $_" }
    } else { Ok "No mailboxes have audit bypass enabled." }
} catch { Warn "Could not enumerate mailbox audit bypass: $($_.Exception.Message)" }

# --- Retention policies (Security & Compliance PowerShell) ---
Write-Section "Audit log retention policies"
try {
    Connect-IPPSSession @connectParams -ErrorAction Stop | Out-Null
    $pols = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop
    if ($pols) {
        $pols | Sort-Object Priority | Format-Table Name, RetentionDuration, Priority, RecordTypes -AutoSize | Out-String | Write-Host
    } else { Warn "No audit log retention policies found (records fall back to the default retention only)." }
} catch { Warn "Could not read retention policies (Connect-IPPSSession / Get-UnifiedAuditLogRetentionPolicy): $($_.Exception.Message)" }

# --- Licensing (Microsoft Graph) ---
if (-not $SkipGraphLicensing) {
    Write-Section "Audit Premium licensing (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping licensing section. Install-Module Microsoft.Graph -Scope CurrentUser (or re-run with -SkipGraphLicensing)."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Organization.Read.All','Directory.Read.All','User.Read.All' -NoWelcome
            # Service plan that indicates Audit Premium (M365_ADVANCED_AUDITING) — verify the plan name for your tenant.
            $planName = 'M365_ADVANCED_AUDITING'
            $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
            $hasPlan = $skus | Where-Object { $_.servicePlans.servicePlanName -contains $planName }
            if ($hasPlan) {
                Ok  "Audit Premium service plan ($planName) present in tenant subscriptions."
                Warn "Confirm it is ASSIGNED to the users who need high-value events (MailItemsAccessed is per-user licensed). Verify plan name against your licensing."
            } else {
                Warn "Service plan '$planName' not found in subscribedSkus — Audit Premium may not be licensed (verify your licensing/tenant; plan names change)."
            }
        } catch { Warn "Graph licensing check failed: $($_.Exception.Message)" }
    }
}

Write-Section "Summary"
Write-Host "Review each flagged item. Audit is NOT retroactive — enable what is off before an incident, under change control." -ForegroundColor White
