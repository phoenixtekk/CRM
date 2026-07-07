<#
.SYNOPSIS
  Scope/health helper (SAFE BY DEFAULT: -WhatIf / dry-run): previews the "Domain Conversion - <domain> -
  Managed" - validates prerequisites and shows the federated->managed plan and rollback. Only converts
  the domain when -Commit is passed.
.DESCRIPTION
  Confirms the target domain is currently Federated, checks readiness signals (tenant on-premises sync
  enabled), and prints the conversion plan and the rollback (re-federate; keep ADFS running). In dry-run
  it makes NO changes. With -Commit (inside a change window, after the Staged Rollout pilot has passed),
  it converts the domain to Managed via Update-MgDomain -AuthenticationType Managed. Prefer the Microsoft
  Entra Connect wizard where possible - it converts the domain AND cleans up the federation trust in one
  supported operation; this cmdlet path is for scripted/controlled conversions.
.EXAMPLE
  .\Invoke-DomainConversionPlan.ps1 -DomainName contoso.com -WhatIf
  # Dry-run: validates prerequisites and prints the conversion plan; makes no changes.
.EXAMPLE
  .\Invoke-DomainConversionPlan.ps1 -DomainName contoso.com -Commit
  # Converts the domain Federated -> Managed (change window; pilot must have passed).
  # (PowerShell 5.1+/7+, Microsoft.Graph; Connect-MgGraph with Domain.ReadWrite.All to commit.)
.NOTES
  Expected results: dry-run reports READY / NOT READY and the plan. Commit sets AuthenticationType =
  Managed; all users on that domain then authenticate in the cloud. Rollback: re-federate via the Entra
  Connect wizard (or Update-MgDomain -AuthenticationType Federated with the ADFS trust) - keep ADFS
  running until stable. Legacy MSOnline equivalent: Set-MsolDomainAuthentication -Authentication Managed
  (deprecated - verify availability). Government cloud: connect Graph to the correct environment.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainName,

    [switch]$Commit
)

$isDryRun = -not $Commit
if ($isDryRun) { Write-Host "DRY-RUN (no changes). Pass -Commit inside a change window to convert the domain." -ForegroundColor Yellow }

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$scope = if ($isDryRun) { @('Domain.Read.All','Organization.Read.All') } else { @('Domain.ReadWrite.All','Organization.Read.All') }
try {
    Connect-MgGraph -Scopes $scope -ErrorAction Stop | Out-Null
} catch {
    Write-Error "Connect-MgGraph failed: $($_.Exception.Message)"; return
}

# --- Read current state ---
try {
    $domain = Get-MgDomain -DomainId $DomainName -ErrorAction Stop
} catch {
    Write-Error "Get-MgDomain failed for ${DomainName}: $($_.Exception.Message)"; return
}

$syncEnabled = $null
try { $syncEnabled = (Get-MgOrganization -ErrorAction Stop | Select-Object -First 1).OnPremisesSyncEnabled } catch { }

Write-Host "`nDomain: $($domain.Id)" -ForegroundColor Cyan
Write-Host "  Current AuthenticationType : $($domain.AuthenticationType)"
Write-Host "  Tenant dir-sync enabled    : $syncEnabled"

# --- Readiness checks ---
$ready = $true
if ($domain.AuthenticationType -ne 'Federated') {
    Write-Host "  [SKIP] Domain is not Federated (nothing to convert)." -ForegroundColor Yellow
    $ready = $false
}
if ($syncEnabled -ne $true) {
    Write-Host "  [WARN] Tenant on-premises sync does not report enabled - confirm Entra Connect health before converting." -ForegroundColor Yellow
}

Write-Host "`nPre-commit checklist (confirm manually - see Implementation B2/B3 and Testing T5/T6):" -ForegroundColor Cyan
Write-Host "  [ ] Target managed method (PHS/PTA) + Seamless SSO enabled in Entra Connect" -ForegroundColor DarkGray
Write-Host "  [ ] Staged Rollout - Pilot - Wave1 validated (pilot users authenticate via cloud)" -ForegroundColor DarkGray
Write-Host "  [ ] Entra Conditional Access parity for any ADFS access/MFA rules is in place" -ForegroundColor DarkGray
Write-Host "  [ ] Change window approved with rollback authority" -ForegroundColor DarkGray

# --- Plan / rollback ---
Write-Host "`nConversion plan (Domain Conversion - $DomainName - Managed):" -ForegroundColor Green
Write-Host "  1. Convert $DomainName Federated -> Managed (all users move to cloud auth)."
Write-Host "  2. Remove Staged Rollout for the method afterwards (whole domain now managed)."
Write-Host "  3. Validate broadly (Testing T7/T8), then keep ADFS parked until stable."
Write-Host "Rollback: re-federate via Entra Connect wizard (ADFS still running)." -ForegroundColor DarkGray

if ($isDryRun) {
    $verdict = if ($ready) { 'READY' } else { 'NOT READY' }
    Write-Host "`nDRY-RUN verdict: $verdict. Re-run with -Commit to convert (change window only)." -ForegroundColor Yellow
    return
}

if (-not $ready) {
    Write-Error "Domain is not in a convertible (Federated) state. Aborting."
    return
}

if ($PSCmdlet.ShouldProcess("$DomainName", "Convert Federated -> Managed (AuthenticationType = Managed)")) {
    try {
        Update-MgDomain -DomainId $DomainName -AuthenticationType 'Managed' -ErrorAction Stop
        Write-Host "`nConverted $DomainName to Managed. Validate sign-in now (Testing T7/T8) and keep ADFS parked until stable." -ForegroundColor Green
    } catch {
        Write-Error "Update-MgDomain failed: $($_.Exception.Message)"
        Write-Host "Rollback: re-federate via the Entra Connect wizard; ADFS is still running." -ForegroundColor Yellow
    }
}
