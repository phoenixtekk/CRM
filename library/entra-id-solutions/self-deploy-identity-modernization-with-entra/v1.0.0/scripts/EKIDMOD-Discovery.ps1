<#
.SYNOPSIS
    EKIDMOD-Discovery.ps1 — Read-only baseline of the identity-modernization posture.
.DESCRIPTION
    PURPOSE
        Assess the current state before any modernization lab: legacy-authentication exposure,
        per-user MFA vs Conditional Access usage, registered authentication methods (passwordless
        adoption), and federated (AD FS) domains. This is the "Assess" baseline for the kit.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\EKIDMOD-Discovery.ps1
        Sign in when prompted and consent to the read-only scopes. No changes are made.
    EXPECTED RESULTS
        A printed baseline: domain authentication types (Managed/Federated), Conditional Access
        policy count and states, per-user MFA presence, authentication-method registration summary,
        and legacy-auth sign-in hints. Nothing is modified.
.NOTES
    White-label. Read-only.
#>
[CmdletBinding()] param()

$ErrorActionPreference = 'Stop'
$scopes = @('Directory.Read.All','Policy.Read.All','AuditLog.Read.All','Domain.Read.All','UserAuthenticationMethod.Read.All')

Write-Host "`n=== Identity Modernization — Discovery (read-only) ===" -ForegroundColor Cyan
try { Connect-MgGraph -Scopes $scopes -NoWelcome } catch { Write-Host "Connect-MgGraph failed: $($_.Exception.Message)" -ForegroundColor Red; return }
$ctx = Get-MgContext
Write-Host ("Tenant           : {0}" -f $ctx.TenantId)

# --- Domains: Managed vs Federated (coexistence signal) ---
try {
    $domains = Get-MgDomain -All
    $fed = $domains | Where-Object { $_.AuthenticationType -eq 'Federated' }
    Write-Host ("Domains          : {0} total, {1} federated (AD FS)" -f $domains.Count, @($fed).Count)
    foreach ($d in $fed) { Write-Host ("  FEDERATED       : {0}" -f $d.Id) -ForegroundColor Yellow }
} catch { Write-Host "  (could not read domains: $($_.Exception.Message))" -ForegroundColor Yellow }

# --- Conditional Access posture ---
try {
    $ca = Get-MgIdentityConditionalAccessPolicy -All
    $on   = @($ca | Where-Object { $_.State -eq 'enabled' }).Count
    $ro   = @($ca | Where-Object { $_.State -eq 'enabledForReportingButNotEnforced' }).Count
    $off  = @($ca | Where-Object { $_.State -eq 'disabled' }).Count
    Write-Host ("Conditional Access: {0} policies ({1} on, {2} report-only, {3} off)" -f $ca.Count,$on,$ro,$off)
    if ($ca.Count -eq 0) { Write-Host "  No CA policies — modernization opportunity (start report-only)." -ForegroundColor Yellow }
} catch { Write-Host "  (CA read requires Entra ID P1 — verify licensing: $($_.Exception.Message))" -ForegroundColor Yellow }

# --- Legacy per-user MFA hint (registration campaign / authentication methods policy) ---
try {
    $amPolicy = Get-MgPolicyAuthenticationMethodPolicy
    $enabled = @($amPolicy.AuthenticationMethodConfigurations | Where-Object { $_.State -eq 'enabled' } | Select-Object -ExpandProperty Id)
    Write-Host ("Auth methods on   : {0}" -f (($enabled) -join ', '))
    if ($enabled -notcontains 'Fido2') { Write-Host "  FIDO2/passkey not enabled tenant-wide — passwordless opportunity." -ForegroundColor Yellow }
} catch { Write-Host "  (could not read authentication methods policy: $($_.Exception.Message))" -ForegroundColor Yellow }

# --- Legacy-auth sign-in hint (last 7 days, sample) ---
try {
    $since = (Get-Date).AddDays(-7).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $legacy = Get-MgAuditLogSignIn -Filter "createdDateTime ge $since and (clientAppUsed eq 'Other clients' or clientAppUsed eq 'IMAP4' or clientAppUsed eq 'POP3' or clientAppUsed eq 'SMTP' or clientAppUsed eq 'Exchange ActiveSync')" -Top 50 -ErrorAction Stop
    Write-Host ("Legacy-auth signins (7d, sample<=50): {0}" -f @($legacy).Count) -ForegroundColor $(if(@($legacy).Count){'Yellow'}else{'Green'})
} catch { Write-Host "  (legacy sign-in sample unavailable — needs AuditLog.Read.All / P1: $($_.Exception.Message))" -ForegroundColor Yellow }

Write-Host "`nBaseline captured. Use this as the 'before' state; re-run after modernization to compare." -ForegroundColor Cyan
Write-Host "Next: EKIDMOD-LabSetup.ps1 (create pilot scope), then EKIDMOD-Validate.ps1." -ForegroundColor Cyan
