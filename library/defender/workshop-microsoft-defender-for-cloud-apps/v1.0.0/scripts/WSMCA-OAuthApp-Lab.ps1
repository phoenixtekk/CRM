<#
.SYNOPSIS
    WSMCA-OAuthApp-Lab.ps1 — read-only Lab 3 helper: enumerate OAuth apps and consent grants with
    risk hints and print the approval-gated revoke steps. PREVIEW ONLY — revokes nothing.
.DESCRIPTION
    PURPOSE
        Supports Lab 3 of the "Workshop — Microsoft Defender for Cloud Apps". It enumerates OAuth
        applications (service principals) and their delegated/app-role permission grants, flags risk
        hints (broad/high-privilege scopes, unverified publisher, many users consented), and prints
        the precise, approval-gated steps to disable/revoke a risky app in the portal. It requests
        NO write scope and performs NO revocation — keeping the workshop read-only/preview-first.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WSMCA-OAuthApp-Lab.ps1
        powershell -ExecutionPolicy Bypass -File .\WSMCA-OAuthApp-Lab.ps1 -OutputPath .\wsmca-oauth.json
        Run as Security Reader / Security Administrator; consent the read-only scopes when prompted.
    EXPECTED RESULTS
        A ranked-ish list of OAuth apps with risk hints and a printed step-by-step for the
        approval-gated revoke. The facilitator uses this to build OAuthRisk-Shortlist.
.NOTES
    White-label. Read-only / preview-first. Requests NO write scopes and revokes nothing.
    Revoking consent can break a legitimate integration — always approval-gated with the app owner.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\wsmca-oauth.json"
)

$ErrorActionPreference = 'Continue'
$scopes = @('Application.Read.All','Directory.Read.All')
foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Applications') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# Scopes commonly considered high-privilege for consent risk (illustrative — verify for your tenant).
$highRiskScopes = @('Mail.ReadWrite','Mail.Send','Files.ReadWrite.All','Directory.ReadWrite.All',
    'Sites.ReadWrite.All','User.ReadWrite.All','full_access_as_user','Application.ReadWrite.All')

Write-Host "`n=== OAuth App Risk Lab (Lab 3) — read-only / preview ===" -ForegroundColor Cyan
try { Connect-MgGraph -Scopes $scopes -NoWelcome -ErrorAction Stop }
catch { Write-Host "  Could not connect: $($_.Exception.Message)" -ForegroundColor Red; return }

Import-Module Microsoft.Graph.Applications -ErrorAction Stop
$rows = @()
try {
    $sps = Get-MgServicePrincipal -All -Property 'id','displayName','appId','publisherName','verifiedPublisher','servicePrincipalType' -ErrorAction Stop |
        Where-Object { $_.ServicePrincipalType -eq 'Application' }
    foreach ($sp in $sps) {
        $grants = @()
        try { $grants = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $sp.Id -All -ErrorAction Stop } catch {}
        $scopeText = ($grants | ForEach-Object { $_.Scope }) -join ' '
        $high = @($highRiskScopes | Where-Object { $scopeText -match [regex]::Escape($_) })
        $verified = if ($sp.VerifiedPublisher -and $sp.VerifiedPublisher.DisplayName) { $true } else { $false }
        $risk = 0
        if ($high.Count -gt 0) { $risk += 2 }
        if (-not $verified)     { $risk += 1 }
        if ($grants.Count -gt 0 -and ($grants | Where-Object { $_.ConsentType -eq 'AllPrincipals' })) { $risk += 1 }
        $rows += [pscustomobject]@{
            App = $sp.DisplayName; AppId = $sp.AppId; VerifiedPublisher = $verified
            HighPrivScopes = ($high -join ', '); RiskHint = $risk
        }
    }
    $rows = $rows | Sort-Object RiskHint -Descending
    Write-Host ("`nOAuth apps by risk hint (higher = review first):") -ForegroundColor Green
    $rows | Select-Object -First 20 | Format-Table App, VerifiedPublisher, HighPrivScopes, RiskHint -AutoSize
} catch { Write-Host "  Enumeration error: $($_.Exception.Message)" -ForegroundColor Yellow }

$rows | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host @"

------------------------------------------------------------------------------
NEXT (approval-gated — this script does NOT revoke anything):
  1. Build OAuthRisk-Shortlist - CloudApps Lab - Pilot from the highest RiskHint apps.
  2. For a truly risky app, the DISABLE / REVOKE path (portal) is:
       https://security.microsoft.com  -> Cloud apps -> OAuth apps -> select app -> Disable app
       (or Entra -> Enterprise applications -> app -> Permissions -> Revoke).
  3. DO NOT revoke a production app during the workshop — it can break a legitimate integration.
     Queue the change for the app owner / security approval.
------------------------------------------------------------------------------
"@ -ForegroundColor Cyan

Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
Write-Host "PREVIEW complete — nothing was revoked or changed. Saved to $OutputPath" -ForegroundColor Green
