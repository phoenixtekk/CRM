<#
.SYNOPSIS
    ENTIDP-Report.ps1 — risk-and-coverage report: risky users/sign-ins, risk-policy coverage, legacy-auth & MFA gaps.
.DESCRIPTION
    PURPOSE
        Produces a management-readable snapshot: counts of risky users by level and recent risk
        detections, which Conditional Access policies use a risk condition (risk coverage), whether a
        legacy-authentication block exists, and MFA/phishing-resistant registration coverage. Highlights
        gaps that should close before or during enforcement.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTIDP-Report.ps1
        Requires the Microsoft Graph PowerShell SDK. Read-only scopes:
        Policy.Read.All, IdentityRiskyUser.Read.All, IdentityRiskEvent.Read.All,
        AuditLog.Read.All, UserAuthenticationMethod.Read.All.
    EXPECTED RESULTS
        A printed report of risk posture and coverage gaps. Use it as the pilot pass/fail evidence and
        the ongoing risk-operations dashboard.
.NOTES
    White-label — Entra ID Solutions. Read-only against Graph. Verify Entra ID P2 availability.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All','IdentityRiskyUser.Read.All','IdentityRiskEvent.Read.All','AuditLog.Read.All','UserAuthenticationMethod.Read.All' -NoWelcome
Write-Host "`n=== ENTIDP — risk & coverage report ===" -ForegroundColor Cyan

# Risky users by risk level
try {
    $ru = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityProtection/riskyUsers?$top=200').value)
    $byLevel = $ru | Group-Object riskLevel | Sort-Object Name
    Write-Host "Risky users by level:"
    if ($byLevel) { $byLevel | ForEach-Object { Write-Host ("  {0,-8}: {1}" -f $_.Name, $_.Count) } } else { Write-Host "  (none — verify P2 signal)" -ForegroundColor Yellow }
    $rd = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityProtection/riskDetections?$top=200').value)
    Write-Host ("Recent risk detections (sample): {0}" -f $rd.Count)
} catch { Write-Host "  Risk queries failed — verify Entra ID P2 licensing." -ForegroundColor Yellow }

# Risk coverage: which CA policies use a risk condition
$cap = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value)
$riskPols = @($cap | Where-Object { ($_.conditions.signInRiskLevels.Count -gt 0) -or ($_.conditions.userRiskLevels.Count -gt 0) })
Write-Host ("`nCA policies using a risk condition: {0}" -f $riskPols.Count) -ForegroundColor ($(if($riskPols.Count -gt 0){'Green'}else{'Yellow'}))
$riskPols | ForEach-Object { Write-Host ("  [{0}] {1}  signIn=[{2}] user=[{3}]" -f $_.state, $_.displayName, ($_.conditions.signInRiskLevels -join ','), ($_.conditions.userRiskLevels -join ',')) }

# Legacy-auth block present?
$legacyBlock = @($cap | Where-Object { $_.grantControls.builtInControls -contains 'block' -and ($_.conditions.clientAppTypes -contains 'exchangeActiveSync' -or $_.conditions.clientAppTypes -contains 'other') })
Write-Host ("`nLegacy-authentication block policy present: {0}" -f ($legacyBlock.Count -gt 0)) -ForegroundColor ($(if($legacyBlock.Count -gt 0){'Green'}else{'Yellow'}))

# MFA / phishing-resistant registration coverage
try {
    $reg = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/authenticationMethods/userRegistrationDetails?`$top=999").value)
    $mfa = @($reg | Where-Object { $_.isMfaRegistered }).Count
    $pr  = @($reg | Where-Object { $_.isPasswordlessCapable }).Count
    Write-Host ("`nUsers MFA-registered           : {0}/{1}" -f $mfa, $reg.Count)
    Write-Host ("Users passwordless-capable     : {0}/{1} (phishing-resistant readiness)" -f $pr, $reg.Count)
} catch { Write-Host "Registration report unavailable — check permissions/licensing." -ForegroundColor Yellow }

Write-Host "`nClose legacy-auth and registration gaps before broad enforcement." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
