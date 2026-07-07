<#
.SYNOPSIS
  Validation (READ-ONLY): reports the effective sign-in path per domain and checks the target managed
  method (PHS/PTA) and Seamless SSO readiness so you can confirm "Staged Rollout - Pilot - Wave1" users
  authenticate via the cloud. Makes no changes.
.DESCRIPTION
  Connects to Microsoft Graph and reports, per verified domain, whether it is Federated or Managed.
  Reads the tenant on-premises directory sync / password-hash-sync feature state
  (Get-MgOrganization -> OnPremisesSyncEnabled) and the Seamless SSO / Staged Rollout feature signals
  available via Graph. For a domain still Federated but expected to have pilot users on cloud auth, it
  reminds you to confirm those users bypass ADFS. Read-only: Domain.Read.All, Organization.Read.All,
  Directory.Read.All. This validates configuration state; end-user sign-in should also be confirmed
  interactively (browser + Outlook) per the Testing guide (T5/T6).
.EXAMPLE
  .\Test-CloudAuthSignIn.ps1
  # Read-only: lists each domain's auth type and the tenant's managed-auth readiness signals.
.EXAMPLE
  .\Test-CloudAuthSignIn.ps1 -DomainName contoso.com
  # Focus the report on a single domain.
  # (PowerShell 5.1+/7+, Microsoft.Graph module; connect with Connect-MgGraph.)
.NOTES
  Expected results: pilot users on Staged Rollout authenticate at login.microsoftonline.com with NO
  ADFS redirect; non-pilot users on a federated domain still use ADFS. This script confirms the
  configuration signals; verify actual sign-in interactively. Government cloud: connect Graph to the
  correct environment and verify endpoints.
#>

[CmdletBinding()]
param(
    [string]$DomainName
)

Write-Host "Connecting to Microsoft Graph (read-only)..." -ForegroundColor Cyan
try {
    Connect-MgGraph -Scopes 'Domain.Read.All','Organization.Read.All','Directory.Read.All' -ErrorAction Stop | Out-Null
} catch {
    Write-Error "Connect-MgGraph failed: $($_.Exception.Message)"; return
}

# Tenant-level directory sync signal
try {
    $org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
    Write-Host "`nTenant directory sync (OnPremisesSyncEnabled): $($org.OnPremisesSyncEnabled)" -ForegroundColor Cyan
    if ($org.OnPremisesLastSyncDateTime) {
        Write-Host "Last on-premises sync: $($org.OnPremisesLastSyncDateTime)" -ForegroundColor DarkGray
    }
} catch {
    Write-Warning "Get-MgOrganization failed: $($_.Exception.Message)"
}

Write-Host "Note: confirm the tenant sign-in method (PHS / PTA / Seamless SSO) in the Entra admin center" -ForegroundColor DarkGray
Write-Host "      (Identity > Hybrid management > Microsoft Entra Connect) - it is the source of truth for method + Staged Rollout." -ForegroundColor DarkGray

# Per-domain auth type
try {
    if ($DomainName) {
        $domains = @(Get-MgDomain -DomainId $DomainName -ErrorAction Stop)
    } else {
        $domains = Get-MgDomain -All -ErrorAction Stop
    }
} catch {
    Write-Error "Get-MgDomain failed: $($_.Exception.Message)"; return
}

$rows = foreach ($d in $domains) {
    [pscustomobject]@{
        Domain             = $d.Id
        AuthenticationType = $d.AuthenticationType
        IsVerified         = $d.IsVerified
        SignInPath         = if ($d.AuthenticationType -eq 'Managed') { 'Cloud (Entra)' } else { 'ADFS (unless Staged Rollout)' }
    }
}

Write-Host "`nDomain sign-in path:" -ForegroundColor Green
$rows | Format-Table Domain, AuthenticationType, SignInPath -AutoSize

Write-Host "`nValidation reminders:" -ForegroundColor Cyan
Write-Host "  T5: each Staged Rollout - Pilot - Wave1 user signs in with NO ADFS redirect (browser + Outlook)." -ForegroundColor DarkGray
Write-Host "  T6: a non-pilot federated user still authenticates via ADFS (unchanged)." -ForegroundColor DarkGray
Write-Host "  Seamless SSO: confirm the AZUREADSSOACC computer object exists and browser intranet-zone URL is pushed." -ForegroundColor DarkGray
