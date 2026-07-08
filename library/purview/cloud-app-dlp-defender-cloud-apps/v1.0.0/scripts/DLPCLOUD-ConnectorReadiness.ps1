<#
.SYNOPSIS
    DLPCLOUD-ConnectorReadiness.ps1 — read-only two-plane readiness check for cloud-app DLP (MDCA).
.DESCRIPTION
    PURPOSE
        Confirms the two enabling planes are ready before you build policies. FILE plane: whether the
        target SaaS apps have a connected, healthy API connector (via the documented MDCA REST API, only
        if MDCA_API_TOKEN is set). SESSION plane: whether a Microsoft Entra Conditional Access policy
        routes the target app/users to MDCA (Conditional Access App Control) and whether it is still in
        report-only (test) mode (via Microsoft Graph). Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPCLOUD-ConnectorReadiness.ps1 -TargetApp 'Box'
        # To also check the file plane, set the token + portal URL (never hardcode):
        #   $env:MDCA_API_TOKEN = '<token>'
        #   .\DLPCLOUD-ConnectorReadiness.ps1 -TargetApp 'Box' -McasUrl 'https://<tenant>.portal.cloudappsecurity.com'
        Requires Microsoft Graph PowerShell (Connect-MgGraph). MDCA REST is optional (env token).
    EXPECTED RESULTS
        A readiness verdict per plane. PASS (file): the target app's connector is present and connected.
        PASS (session): a CA policy with CA App Control targets the app. It also flags whether the CA
        policy is still report-only (expected during pilot) vs already enforcing.
.NOTES
    Purview — Cloud-App DLP. Read-only. No credentials in code; MDCA token read from env var only.
#>
[CmdletBinding()]
param(
    [string]$TargetApp,
    [string]$McasUrl
)

Write-Host '=== Cloud-App DLP — Two-Plane Readiness (read-only) ===' -ForegroundColor Cyan

# ============ SESSION plane: Conditional Access App Control (Graph) ============
Write-Host '--- SESSION plane: Conditional Access App Control ---' -ForegroundColor Cyan
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
    Install-Module Microsoft.Graph.Identity.SignIns -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Identity.SignIns -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Policy.Read.All' -NoWelcome }

$sessionReady = $false
try {
    $caPolicies = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop
    $mcasPolicies = foreach ($ca in $caPolicies) {
        $s = $ca.SessionControls.CloudAppSecurity
        if ($s -and $s.IsEnabled) {
            [pscustomobject]@{
                Name        = $ca.DisplayName
                State       = $ca.State
                SessionType = $s.CloudAppSecurityType
                Apps        = ($ca.Conditions.Applications.IncludeApplications -join ', ')
            }
        }
    }
    if ($mcasPolicies) {
        $mcasPolicies | Format-Table -AutoSize
        $sessionReady = $true
        foreach ($p in $mcasPolicies) {
            if ($p.State -eq 'enabledForReportingButNotEnforced') {
                Write-Host ("  report-only (test mode): '{0}' — expected during pilot." -f $p.Name) -ForegroundColor Green
            } elseif ($p.State -eq 'enabled') {
                Write-Host ("  ENFORCING: '{0}' — confirm the scope is intended (not tenant-wide during pilot)." -f $p.Name) -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host 'SESSION plane NOT ready: no CA policy uses Conditional Access App Control (create one in Entra, report-only) — Req 2.4.' -ForegroundColor Yellow
    }
} catch {
    Write-Host ("Could not read Conditional Access policies: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# ============ FILE plane: app connectors (MDCA REST, optional) ============
Write-Host '--- FILE plane: app connectors (API, data at rest) ---' -ForegroundColor Cyan
$fileReady = $false
$token = $env:MDCA_API_TOKEN
if ($token -and $McasUrl) {
    $headers = @{ Authorization = "Token $token" }
    try {
        $conn = Invoke-RestMethod -Method Get -Uri ("{0}/api/v1/data_management/data_sources/" -f $McasUrl.TrimEnd('/')) -Headers $headers -ErrorAction Stop
        $sources = @($conn.data)
        Write-Host ("Connected app connectors: {0}" -f $sources.Count) -ForegroundColor Green
        $sources | Select-Object name, appName, connected | Format-Table -AutoSize
        if ($TargetApp) {
            $match = $sources | Where-Object { $_.name -like "*$TargetApp*" -or $_.appName -like "*$TargetApp*" }
            if ($match) {
                $fileReady = [bool]($match | Where-Object { $_.connected })
                if ($fileReady) { Write-Host ("FILE plane ready: '{0}' connector is connected." -f $TargetApp) -ForegroundColor Green }
                else { Write-Host ("FILE plane NOT ready: '{0}' connector exists but is not connected — reconnect (Req 2.3)." -f $TargetApp) -ForegroundColor Yellow }
            } else {
                Write-Host ("FILE plane NOT ready: no connector for '{0}' — connect it in Cloud apps -> App connectors (Req 2.3)." -f $TargetApp) -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host ("MDCA REST call failed (verify URL/token/scope): {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host 'FILE-plane check skipped — set $env:MDCA_API_TOKEN and -McasUrl to verify app connectors, or confirm in Cloud apps -> App connectors.' -ForegroundColor DarkGray
}

# ============ Verdict ============
Write-Host '--- Readiness verdict ---' -ForegroundColor Cyan
Write-Host ("  SESSION plane (CA App Control): {0}" -f ($(if ($sessionReady) { 'READY' } else { 'NOT READY' }))) -ForegroundColor $(if ($sessionReady) { 'Green' } else { 'Yellow' })
Write-Host ("  FILE plane (app connector)   : {0}" -f ($(if ($fileReady) { 'READY' } elseif ($token) { 'NOT READY' } else { 'UNVERIFIED (no token)' }))) -ForegroundColor $(if ($fileReady) { 'Green' } else { 'Yellow' })
Write-Host 'Enable the plane(s) your scope needs before building policies (Implementation Phase 1).' -ForegroundColor Cyan
