<#
.SYNOPSIS
    Find the failed Intune enrollment sign-in for a user (optionally by correlation/Activity Id) and show
    the failure reason and the applied Conditional Access result — the deterministic root cause.

.DESCRIPTION
    Phase 1. Queries the Entra sign-in logs for the Microsoft Intune Enrollment and Microsoft Intune
    cloud apps for the user, showing status, failure reason, and each applied CA policy. Use the
    Activity Id / Session Id / timestamp from the "Access Denied" screen to pinpoint the exact event.

.HOW TO RUN
    Connect-MgGraph is invoked with AuditLog.Read.All (+ Directory.Read.All).
        .\ENRLDX-Get-EnrollmentSignin.ps1 -UserPrincipalName user@contoso.com -Hours 6
        .\ENRLDX-Get-EnrollmentSignin.ps1 -UserPrincipalName user@contoso.com -CorrelationId af992f0f-1790-4677-8ef8-b61de01dfc67
    Sovereign cloud: add  -Environment USGov.

.EXPECTED RESULT
    The failed enrollment sign-in(s) with FailureReason and the CA policies applied (Success/Failure).
    The FailureReason routes you to the right remediation phase (license / MDM scope / restriction / CA).

.NOTES
    Intune Solutions — read-only diagnostic (Microsoft Graph).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$UserPrincipalName,
    [string]$CorrelationId,
    [int]$Hours = 6,
    [string]$OutputPath = ".",
    [string]$Environment = "Global"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'AuditLog.Read.All','Directory.Read.All' -Environment $Environment -NoWelcome
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$start = (Get-Date).ToUniversalTime().AddHours(-$Hours).ToString('yyyy-MM-ddTHH:mm:ssZ')

$filter = "userPrincipalName eq '$UserPrincipalName' and createdDateTime ge $start"
if ($CorrelationId) { $filter = "correlationId eq '$CorrelationId'" }
$signins = Get-MgAuditLogSignIn -Filter $filter -All -ErrorAction Stop
# enrollment-related apps
$enroll = $signins | Where-Object { $_.AppDisplayName -match 'Intune|Enrollment|Device Management|Company Portal' }
if (-not $enroll) { $enroll = $signins }

$rows = foreach ($s in $enroll) {
    $cas = @($s.AppliedConditionalAccessPolicies)
    if (-not $cas) { $cas = @([pscustomobject]@{ DisplayName='(none)'; Result='' }) }
    foreach ($ca in $cas) {
        [pscustomobject]@{
            Time          = $s.CreatedDateTime
            App           = $s.AppDisplayName
            Status        = $s.Status.ErrorCode
            FailureReason = $s.Status.FailureReason
            CorrelationId = $s.CorrelationId
            CAPolicy      = $ca.DisplayName
            CAResult      = $ca.Result
            Grants        = ($ca.EnforcedGrantControls -join ';')
        }
    }
}
$out = Join-Path $OutputPath "ENRLDX-EnrollmentSignin-$stamp.csv"
$rows | Sort-Object Time -Descending | Export-Csv $out -NoTypeInformation -Encoding UTF8
$rows | Sort-Object Time -Descending | Select-Object Time,App,Status,FailureReason,CAPolicy,CAResult -First 15 | Format-Table -AutoSize

$fail = $rows | Where-Object { $_.Status -ne 0 }
if ($fail) {
    Write-Host "`nFailure reason (routes you to the remediation phase):" -ForegroundColor Yellow
    $fail | Select-Object -First 1 -Expand FailureReason
    if ($rows | Where-Object CAResult -eq 'failure') { Write-Host "A Conditional Access policy shows Failure -> Phase 2D." -ForegroundColor Yellow }
} else { Write-Host "No failed enrollment sign-in found in the window — widen -Hours or use -CorrelationId." -ForegroundColor Cyan }
Write-Host "Exported: $out" -ForegroundColor Green
