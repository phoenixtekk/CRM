<#
.SYNOPSIS
    ENTARCH-Report.ps1 — identity posture & maturity report, and emit the KQL evidence queries.
.DESCRIPTION
    PURPOSE
        Read-only reporting that produces the posture evidence for the Decision Record and prints the
        ready-to-run KQL queries the assessment relies on. It summarizes a maturity view across the six
        design domains (topology/source-of-authority, identity model, Zero Trust access, privileged
        access, governance, hybrid) from the Graph signals available, and then emits KQL you paste into
        Entra 'Monitoring -> Sign-in logs' (Log Analytics) to quantify: MFA coverage, legacy-auth
        sign-ins, risky sign-ins (P2 / Identity Protection), and privileged sign-in patterns. It changes
        NOTHING.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTARCH-Report.ps1
        Optional: -EmitKqlOnly   (skip Graph; just print the KQL block)
        Consents to Directory.Read.All, Policy.Read.All, AuditLog.Read.All (all read-only).
        The KQL requires SigninLogs/AuditLogs streamed to a Log Analytics workspace (Entra ID P1+).
    EXPECTED RESULTS
        A printed maturity summary and a KQL block. Nothing is modified. Paste the KQL into Log
        Analytics to complete the posture evidence for the Assess appendix.
.NOTES
    White-label — Entra ID Solutions. Read-only. Design/assessment helper (not a deployment script).
    *Verify current licensing/preview availability in your tenant* for any P2/Governance/GSA feature.
#>
[CmdletBinding()]
param(
    [switch]$EmitKqlOnly
)

if (-not $EmitKqlOnly) {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'Directory.Read.All','Policy.Read.All','AuditLog.Read.All' -NoWelcome

    Write-Host "`n=== Identity Posture & Maturity Report — $(Get-Date -Format s) ===" -ForegroundColor Cyan

    # Domain maturity signals (simple present/absent heuristics — evidence, not a score)
    $plans = @()
    try { $plans = ((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value).servicePlans.servicePlanName } catch {}
    $org = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/organization').value | Select-Object -First 1
    $ca  = @(); try { $ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value } catch {}
    $enforcedCa = @($ca | Where-Object { $_.state -eq 'enabled' }).Count

    $signal = [ordered]@{
        'Domain 1 — Source of authority' = $(if($org.onPremisesSyncEnabled){'hybrid (sync enabled)'}else{'cloud-only'})
        'Domain 3 — CA policies enforced' = "$enforcedCa of $($ca.Count)"
        'Domain 3 — Identity Protection (P2)' = $(if($plans -contains 'AAD_PREMIUM_P2'){'P2 present'}else{'P2 NOT detected — verify'})
        'Domain 4 — PIM available (P2)' = $(if($plans -contains 'AAD_PREMIUM_P2'){'yes (verify PIM in use)'}else{'no P2 — verify'})
        'Domain 5 — Governance licensed' = $(if($plans -match 'Governance|IGA'){'present — verify'}else{'NOT detected — verify'})
    }
    Write-Host "`n-- Domain maturity signals (evidence for the Decision Record) --" -ForegroundColor Cyan
    foreach ($k in $signal.Keys) { Write-Host ("  {0,-40} : {1}" -f $k, $signal[$k]) -ForegroundColor White }
    Write-Host "`n  NOTE: these are signals, not a maturity score — the architect judges maturity from the full evidence." -ForegroundColor DarkGray

    Disconnect-MgGraph | Out-Null
}

# ---------------- KQL evidence block ----------------
$kql = @'
// =========================================================================
// ENTARCH posture KQL — run in Entra 'Monitoring -> Sign-in logs' (Log Analytics)
// Requires SigninLogs/AuditLogs streamed to a workspace (Entra ID P1+). Read-only.
// Adjust the ago() windows to your retention. *Verify P2 for risk columns.*
// =========================================================================

// 1) MFA coverage — interactive sign-ins with vs. without a strong auth requirement (last 30d)
SigninLogs
| where TimeGenerated > ago(30d)
| where ResultType == 0            // successful sign-ins
| extend MfaSatisfied = tostring(AuthenticationRequirement)
| summarize Total = count(),
            MfaRequired = countif(AuthenticationRequirement == "multiFactorAuthentication")
        by bin(TimeGenerated, 1d)
| extend MfaCoveragePct = round(100.0 * MfaRequired / Total, 1)
| order by TimeGenerated asc

// 2) Legacy authentication sign-ins — clients that cannot do MFA (last 30d)
SigninLogs
| where TimeGenerated > ago(30d)
| where ClientAppUsed in ("Exchange ActiveSync", "Other clients", "IMAP4", "POP3", "SMTP", "Authenticated SMTP", "MAPI Over HTTP")
| summarize LegacySignIns = count() by UserPrincipalName, ClientAppUsed
| order by LegacySignIns desc

// 3) Risky sign-ins (Identity Protection — requires Entra ID P2) (last 30d)
SigninLogs
| where TimeGenerated > ago(30d)
| where RiskLevelDuringSignIn in ("medium", "high")
| summarize RiskySignIns = count() by UserPrincipalName, RiskLevelDuringSignIn
| order by RiskySignIns desc

// 4) Privileged sign-in patterns — sign-ins by users in privileged roles (last 30d)
//    (pair with ENTARCH-PrivilegedAccessReview.ps1 for the role membership)
SigninLogs
| where TimeGenerated > ago(30d)
| where ResultType == 0
| summarize SignIns = count(), Apps = make_set(AppDisplayName, 20), Countries = make_set(Location, 20)
        by UserPrincipalName
| order by SignIns desc

// 5) Directory audit — recent privileged role changes (governance evidence) (last 30d)
AuditLogs
| where TimeGenerated > ago(30d)
| where OperationName has_any ("Add member to role", "Add eligible member to role", "Remove member from role")
| project TimeGenerated, OperationName, InitiatedBy, TargetResources
| order by TimeGenerated desc
'@

Write-Host "`n-- KQL evidence queries (paste into Log Analytics / Sign-in logs) --" -ForegroundColor Cyan
Write-Host $kql -ForegroundColor Gray
Write-Host "`nAttach the query results to the Assess appendix — they quantify Domains 3, 4, and 5." -ForegroundColor Cyan
