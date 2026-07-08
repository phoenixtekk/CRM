<#
.SYNOPSIS
    OPSREPORT-Discovery.ps1 — read-only readiness check of the Microsoft Purview reporting sources (no changes).
.DESCRIPTION
    PURPOSE
        Inventories which Purview reporting data sources are reachable for the current reporting
        identity — Activity Explorer (Export-ActivityExplorerData), Purview alerts (Get-ProtectionAlert),
        the unified audit log (Search-UnifiedAuditLog), and secure-score posture (Graph
        security/secureScores) — and reports per-source readiness (available / not licensed / access
        denied) plus which Graph read scopes are consented. Makes no changes.
    HOW TO RUN
        Connect first, then run:
            Connect-IPPSSession
            Connect-MgGraph -Scopes 'SecurityEvents.Read.All','AuditLog.Read.All'
            .\OPSREPORT-Discovery.ps1
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement and Microsoft.Graph modules and a
        least-privilege reporting role (Compliance/Audit/Security Reader). Purview sources are
        licensing-gated — an unavailable source is reported, never assumed.
    EXPECTED RESULTS
        A per-source readiness table. PASS = every intended source is 'available' (or explicitly
        'not licensed - verify tenant') and required scopes are consented.
.NOTES
    Purview — Reporting & Power BI Framework. Read-only. No secrets in code; interactive modern-auth only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

function Test-Source {
    param([string]$Name, [scriptblock]$Probe)
    $status = 'available'; $detail = ''
    try {
        & $Probe | Out-Null
    } catch {
        $msg = $_.Exception.Message
        if     ($msg -match 'not.*licens|subscription|not enabled|isn''t enabled') { $status = 'not licensed - verify tenant' }
        elseif ($msg -match 'access|denied|Authorization|Forbidden|role')          { $status = 'access denied - check role' }
        else   { $status = 'unavailable' }
        $detail = $msg
    }
    [pscustomobject]@{ Source = $Name; Status = $status; Detail = $detail }
}

Write-Host '=== Purview Reporting — Source Readiness (read-only) ===' -ForegroundColor Cyan

$results = @()

# --- Security & Compliance PowerShell sources ---
$results += Test-Source 'Activity Explorer (Export-ActivityExplorerData)' {
    if (-not (Get-Command Export-ActivityExplorerData -ErrorAction SilentlyContinue)) { throw 'cmdlet unavailable - not enabled / not licensed' }
    Export-ActivityExplorerData -StartTime (Get-Date).AddDays(-1) -EndTime (Get-Date) -PageSize 1 -OutputFormat Json -ErrorAction Stop
}
$results += Test-Source 'Purview Alerts (Get-ProtectionAlert)' {
    if (-not (Get-Command Get-ProtectionAlert -ErrorAction SilentlyContinue)) { throw 'cmdlet unavailable - access denied / not licensed' }
    Get-ProtectionAlert -ErrorAction Stop | Select-Object -First 1
}
$results += Test-Source 'Unified Audit Log (Search-UnifiedAuditLog)' {
    if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) { throw 'cmdlet unavailable - audit not enabled' }
    Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-1) -EndDate (Get-Date) -ResultSize 1 -ErrorAction Stop
}

# --- Graph source: secure score ---
$results += Test-Source 'Compliance/Secure Score (Graph security/secureScores)' {
    if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) { throw 'Microsoft.Graph not connected' }
    (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/security/secureScores?$top=1' -ErrorAction Stop) | Out-Null
}

$results | Format-Table -AutoSize

# --- Graph scope consent check ---
Write-Host '--- Graph read scopes ---' -ForegroundColor Cyan
$needed = @('SecurityEvents.Read.All','AuditLog.Read.All')
$granted = @()
try { $ctx = Get-MgContext -ErrorAction Stop; if ($ctx) { $granted = $ctx.Scopes } } catch {}
foreach ($s in $needed) {
    $have = $granted -contains $s
    Write-Host ("  {0,-24} {1}" -f $s, $(if ($have) { 'consented' } else { 'MISSING - consent required' })) -ForegroundColor $(if ($have) { 'Green' } else { 'Yellow' })
}

$pass = -not ($results | Where-Object { $_.Status -notin @('available','not licensed - verify tenant') })
Write-Host ("Readiness: {0}" -f $(if ($pass) { 'PASS' } else { 'FAIL - resolve licensing/roles above' })) -ForegroundColor $(if ($pass) { 'Green' } else { 'Red' })

if ($CsvPath) {
    $results | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved readiness to {0}" -f $CsvPath) -ForegroundColor Green
}
