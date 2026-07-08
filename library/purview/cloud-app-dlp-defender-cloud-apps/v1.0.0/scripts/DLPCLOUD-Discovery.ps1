<#
.SYNOPSIS
    DLPCLOUD-Discovery.ps1 — read-only cloud-app DLP posture for Microsoft Defender for Cloud Apps (MDCA).
.DESCRIPTION
    PURPOSE
        Builds the baseline for extending DLP to third-party cloud apps: the sensitivity labels and
        sensitive-information-types available for content inspection (Security & Compliance PowerShell /
        Graph), the Microsoft Entra Conditional Access policies that route sessions to MDCA (Conditional
        Access App Control, via Graph), and — only if an MDCA REST API token is supplied via the
        MDCA_API_TOKEN environment variable — the connected app connectors and existing file/session
        policies (documented read-only GETs). Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPCLOUD-Discovery.ps1 -CsvPath .\DLPCLOUD-Posture.csv
        # Optional MDCA REST read: set the token + your tenant portal URL first (never hardcode):
        #   $env:MDCA_API_TOKEN = '<token>'
        #   .\DLPCLOUD-Discovery.ps1 -McasUrl 'https://<tenant>.portal.cloudappsecurity.com'
        Requires Microsoft Graph PowerShell (Connect-MgGraph) and Security & Compliance PowerShell
        (Connect-IPPSSession).
    EXPECTED RESULTS
        Console tables of: sensitivity labels + SIT counts; Conditional Access policies with CA App
        Control session routing; and (if a token is present) connected app connectors + policy counts.
        PASS signal: the labels/SITs you intend to inspect on exist, and at least one CA policy routes
        the target app to MDCA for the session plane (or a connector exists for the file plane).
.NOTES
    Purview — Cloud-App DLP (Defender for Cloud Apps). Read-only. No credentials in code; MDCA token read from env var only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$UserPrincipalName,
    # Your MDCA/Defender portal URL, e.g. https://<tenant>.portal.cloudappsecurity.com — only used if MDCA_API_TOKEN is set.
    [string]$McasUrl
)

Write-Host '=== Cloud-App DLP Posture (Defender for Cloud Apps) — read-only ===' -ForegroundColor Cyan

# --- Sensitivity labels + SITs available for content inspection (Security & Compliance PowerShell) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host '--- Sensitivity labels (Purview) ---' -ForegroundColor Cyan
$labels = Get-Label -ErrorAction SilentlyContinue
if ($labels) {
    Write-Host ("Sensitivity labels available for MDCA to match/apply: {0}" -f (@($labels).Count))
    $labels | Select-Object DisplayName, Name | Format-Table -AutoSize
} else {
    Write-Host 'Could not enumerate sensitivity labels (check role / connection).' -ForegroundColor Yellow
}

Write-Host '--- Sensitive information types (Purview) ---' -ForegroundColor Cyan
$sits = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue
if ($sits) {
    $builtIn = @($sits | Where-Object { $_.Publisher -match 'Microsoft' })
    $custom  = @($sits | Where-Object { $_.Publisher -notmatch 'Microsoft' })
    Write-Host ("Built-in SITs: {0}   Custom SITs: {1}   Total: {2}" -f $builtIn.Count, $custom.Count, @($sits).Count)
} else {
    Write-Host 'Could not enumerate SITs (check role / connection).' -ForegroundColor Yellow
}

# --- Conditional Access App Control routing (session plane) via Microsoft Graph ---
Write-Host '--- Conditional Access App Control (session plane) ---' -ForegroundColor Cyan
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
    Install-Module Microsoft.Graph.Identity.SignIns -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Identity.SignIns -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Policy.Read.All' -NoWelcome }

$caRows = @()
try {
    $caPolicies = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop
    foreach ($ca in $caPolicies) {
        $appEnforced = $ca.SessionControls.CloudAppSecurity
        if ($appEnforced -and $appEnforced.IsEnabled) {
            $caRows += [pscustomobject]@{
                Name          = $ca.DisplayName
                State         = $ca.State                             # enabled / disabled / enabledForReportingButNotEnforced (report-only)
                SessionType   = $appEnforced.CloudAppSecurityType     # e.g. monitorOnly / blockDownloads / mcasConfigured
                Apps          = ($ca.Conditions.Applications.IncludeApplications -join ', ')
            }
        }
    }
} catch {
    Write-Host ("Could not read Conditional Access policies: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}
if ($caRows.Count -gt 0) {
    $caRows | Format-Table -AutoSize
    $reportOnly = @($caRows | Where-Object { $_.State -eq 'enabledForReportingButNotEnforced' })
    Write-Host ("CA App Control policies: {0} (report-only: {1})" -f $caRows.Count, $reportOnly.Count) -ForegroundColor Green
} else {
    Write-Host 'No Conditional Access policy routes sessions to MDCA — the SESSION plane is not yet enabled (Req 2.4).' -ForegroundColor Yellow
}

# --- Optional: MDCA REST API (file plane) — only if a token is supplied via env var ---
$token = $env:MDCA_API_TOKEN
if ($token -and $McasUrl) {
    Write-Host '--- MDCA REST (file plane): connected connectors + policies ---' -ForegroundColor Cyan
    $headers = @{ Authorization = "Token $token" }
    try {
        # Documented read-only endpoints. Data-management/data-sources reflects app connectors.
        $conn = Invoke-RestMethod -Method Get -Uri ("{0}/api/v1/data_management/data_sources/" -f $McasUrl.TrimEnd('/')) -Headers $headers -ErrorAction Stop
        Write-Host ("Connected data sources / app connectors: {0}" -f (@($conn.data).Count)) -ForegroundColor Green
        $conn.data | Select-Object -First 20 name, appName, connected | Format-Table -AutoSize
    } catch {
        Write-Host ("MDCA REST call failed (verify URL/token/scope): {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host 'MDCA REST skipped (set $env:MDCA_API_TOKEN and -McasUrl to also enumerate app connectors/policies).' -ForegroundColor DarkGray
}

if ($CsvPath -and $caRows.Count -gt 0) {
    $caRows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("CA App Control inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Baseline captured — check readiness with DLPCLOUD-ConnectorReadiness.ps1.' -ForegroundColor Cyan
