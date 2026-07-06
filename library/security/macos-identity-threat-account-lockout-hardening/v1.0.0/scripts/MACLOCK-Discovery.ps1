<#
.SYNOPSIS
    MACLOCK-Discovery.ps1 — identify Mac-originated failed sign-ins, lockouts, and spray sources plus current Smart Lockout / MFA posture (Graph).
.DESCRIPTION
    PURPOSE
        Reads Microsoft Entra sign-in logs and reports the FAILED sign-ins whose operating system is
        macOS, grouped by user, application, and failure/error code, so you can see which Macs are
        driving account lockouts and password-spray detections. Also reads the current Smart Lockout
        (password protection) settings and the Conditional Access / MFA policies so you can record the
        starting posture. Read-only. Use 'your-tenant-id' style values, not bracketed placeholders.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACLOCK-Discovery.ps1
        Optional: ... .\MACLOCK-Discovery.ps1 -Days 7
        Requires the Microsoft Graph PowerShell SDK and consent to:
        AuditLog.Read.All, Directory.Read.All, Policy.Read.All, IdentityRiskEvent.Read.All.
    EXPECTED RESULTS
        A table of Mac-originated failed sign-ins (user, app, error code, count), a note of any
        password-spray / risk detections (if licensed), and the current Smart Lockout threshold /
        duration and MFA-enforcing Conditional Access policies — printed so you can transcribe them
        into 'MACLOCK Sign-in Failure Findings - Mac-Originated - Sources' and 'MACLOCK Lockout &
        Spray Register - Mac Fleet - Baseline'.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
    Uses documented endpoints: /auditLogs/signIns, /identityProtection/riskDetections,
    /policies/authenticationMethodsPolicy (and legacy password-protection where surfaced),
    /identity/conditionalAccess/policies.
#>
[CmdletBinding()]
param(
    [int]$Days = 7
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'AuditLog.Read.All','Directory.Read.All','Policy.Read.All','IdentityRiskEvent.Read.All' -NoWelcome

$since = (Get-Date).ToUniversalTime().AddDays(-$Days).ToString('yyyy-MM-ddTHH:mm:ssZ')

Write-Host "`n=== Mac-originated failed sign-ins (last $Days day[s]) ===" -ForegroundColor Cyan
$macFailures = @()
try {
    # status/errorCode ne 0 = failure. Filter macOS client-side (OS lives in deviceDetail).
    $uri = "/v1.0/auditLogs/signIns?`$filter=createdDateTime ge $since and status/errorCode ne 0&`$top=1000"
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    $signIns = @($page.value)
    while ($page.'@odata.nextLink') {
        $page = Invoke-MgGraphRequest -Method GET -Uri $page.'@odata.nextLink'
        $signIns += $page.value
    }
    foreach ($s in $signIns) {
        $os = $s.deviceDetail.operatingSystem
        if ($os -and ($os -match 'mac|os ?x')) {
            $macFailures += [pscustomobject]@{
                User      = $s.userPrincipalName
                App       = $s.appDisplayName
                ErrorCode = $s.status.errorCode
                Reason    = $s.status.failureReason
                OS        = $os
                When      = $s.createdDateTime
            }
        }
    }
    if ($macFailures) {
        $macFailures |
            Group-Object User, App, ErrorCode |
            Sort-Object Count -Descending |
            Select-Object -First 30 |
            ForEach-Object {
                $f = $_.Group[0]
                Write-Host ("  {0,-4} x  {1}  app='{2}'  err={3} ({4})" -f $_.Count, $f.User, $f.App, $f.ErrorCode, $f.Reason)
            }
        Write-Host ("  {0} Mac-originated failure event(s) total." -f $macFailures.Count) -ForegroundColor DarkGray
    } else {
        Write-Host "  No macOS-originated sign-in failures found in the window. Widen -Days if expected." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("  Could not read sign-in logs: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`n=== Password-spray / risk detections (if licensed, P2) ===" -ForegroundColor Cyan
try {
    $risks = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/identityProtection/riskDetections?`$top=50").value
    $spray = $risks | Where-Object { $_.riskEventType -match 'passwordSpray|spray|unfamiliar|anonymized' }
    if ($spray) {
        $spray | Select-Object -First 15 | ForEach-Object {
            Write-Host ("  {0}  user={1}  detected={2}" -f $_.riskEventType, $_.userPrincipalName, $_.detectedDateTime)
        }
    } else {
        Write-Host "  No matching risk detections returned (or licensing does not surface them)." -ForegroundColor DarkGray
    }
} catch {
    Write-Host ("  Could not read risk detections (P2 may be required): {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
}

Write-Host "`n=== Current Smart Lockout (password protection) ===" -ForegroundColor Cyan
try {
    $settings = Invoke-MgGraphRequest -Method GET -Uri "/beta/settings"
    $pp = $settings.value | Where-Object { $_.displayName -eq 'Password Rule Settings' }
    if ($pp) {
        $threshold = ($pp.values | Where-Object { $_.name -eq 'LockoutThreshold' }).value
        $duration  = ($pp.values | Where-Object { $_.name -eq 'LockoutDurationInSeconds' }).value
        Write-Host ("  Lockout threshold: {0}" -f $threshold)
        Write-Host ("  Lockout duration (s): {0}" -f $duration)
    } else {
        Write-Host "  Smart Lockout values not surfaced via directory settings; read them in" -ForegroundColor Yellow
        Write-Host "  Entra > Protection > Authentication methods > Password protection." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("  Could not read password-protection settings: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "  Read them in Entra > Protection > Authentication methods > Password protection." -ForegroundColor Yellow
}

Write-Host "`n=== MFA-enforcing Conditional Access policies ===" -ForegroundColor Cyan
try {
    $caps = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/identity/conditionalAccess/policies").value
    $mfa = $caps | Where-Object { $_.grantControls -and ($_.grantControls.builtInControls -contains 'mfa') }
    if ($mfa) {
        $mfa | ForEach-Object {
            Write-Host ("  [{0}] {1}" -f $_.state, $_.displayName)
        }
    } else {
        Write-Host "  No MFA-grant Conditional Access policy found. Create 'MACLOCK CA - Require MFA - Mac Pilot' (Implementation Step 4)." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("  Could not read Conditional Access policies: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`nTranscribe the sources into 'MACLOCK Sign-in Failure Findings - Mac-Originated - Sources'" -ForegroundColor Yellow
Write-Host "and the Smart Lockout / MFA posture into 'MACLOCK Lockout & Spray Register - Mac Fleet - Baseline'." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
