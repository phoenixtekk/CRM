<#
.SYNOPSIS
    SAASLIC-Validation.ps1 — confirm Graph connectivity and the read access this solution needs.
.DESCRIPTION
    PURPOSE
        Verifies the Microsoft Graph PowerShell SDK is present, that you can connect, that the required
        read scopes are granted (Application.Read.All, AuditLog.Read.All, Directory.Read.All), and that
        enterprise apps and sign-in logs are readable. Read-only — it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SAASLIC-Validation.ps1
    EXPECTED RESULTS
        "ENVIRONMENT READY" when the SDK, connection, scopes, and sample reads all succeed.
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param()
Write-Host "=== SAASLIC environment validation ===" -ForegroundColor Cyan
$need = 'Application.Read.All','AuditLog.Read.All','Directory.Read.All'
$ok = $true

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "  Microsoft.Graph SDK : NOT INSTALLED (Install-Module Microsoft.Graph -Scope CurrentUser)" -ForegroundColor Yellow; $ok = $false
} else { Write-Host "  Microsoft.Graph SDK : present" -ForegroundColor Green }

if ($ok) {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    try { Connect-MgGraph -Scopes $need -NoWelcome; Write-Host "  Connection          : connected" -ForegroundColor Green }
    catch { Write-Host "  Connection          : FAILED ($($_.Exception.Message))" -ForegroundColor Yellow; $ok = $false }
}

if ($ok) {
    $ctx = Get-MgContext
    foreach ($s in $need) {
        $has = $ctx.Scopes -contains $s
        Write-Host ("  Scope {0,-24}: {1}" -f $s, ($(if($has){'granted'}else{'MISSING'}))) -ForegroundColor ($(if($has){'Green'}else{'Yellow'}))
        if (-not $has) { $ok = $false }
    }
    try { $null = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$top=1"; Write-Host "  Enterprise apps read: OK" -ForegroundColor Green }
    catch { Write-Host "  Enterprise apps read: FAILED" -ForegroundColor Yellow; $ok = $false }
    try { $null = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/auditLogs/signIns?`$top=1"; Write-Host "  Sign-in logs read   : OK" -ForegroundColor Green }
    catch { Write-Host "  Sign-in logs read   : FAILED (check AuditLog.Read.All / tenant plan)" -ForegroundColor Yellow; $ok = $false }
    Disconnect-MgGraph | Out-Null
}

if ($ok) { Write-Host "`nResult: ENVIRONMENT READY" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT READY — install the SDK / grant the scopes above, then re-run." -ForegroundColor Yellow; exit 1 }
