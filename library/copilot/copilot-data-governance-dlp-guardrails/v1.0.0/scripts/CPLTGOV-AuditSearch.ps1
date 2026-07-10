<#
.SYNOPSIS
    CPLTGOV-AuditSearch.ps1 - Retrieve Microsoft 365 Copilot interaction audit events (READ-ONLY).
.DESCRIPTION
    PURPOSE:  Query the Purview unified audit log for Copilot interaction (prompt/response) events over a
              time window and export them as the audit-capture evidence for the governance guardrails.
              Confirms the audit/eDiscovery evidence trail works before you rely on it. Writes
              "Copilot Interaction Audit - Tenant - Validate".
    HOW TO RUN:
              1. Connect-IPPSSession   (Search-UnifiedAuditLog) OR
                 Connect-MgGraph -Scopes "AuditLog.Read.All"
              2. .\CPLTGOV-AuditSearch.ps1 -Days 7
                 .\CPLTGOV-AuditSearch.ps1 -StartDate 2026-07-01 -EndDate 2026-07-09 -OutDir C:\Temp\CPLTGOV
    EXPECTED RESULTS:
              PASS: Copilot interaction events (if any occurred) are exported; the trail is confirmed. FAIL:
              auditing off / not connected / latency (no events yet).
.NOTES
    White-label. Read-only - reads audit data only; changes nothing. Copilot audit record/operation names
    can vary by tenant/rollout - verify. Requires Search-UnifiedAuditLog (Connect-IPPSSession) or Graph.
#>

[CmdletBinding()]
param(
    [int]$Days = 7,
    [datetime]$StartDate,
    [datetime]$EndDate,
    [string]$OutDir = ".",
    [string]$ArtifactName = "Copilot Interaction Audit - Tenant - Validate"
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

if (-not $EndDate)   { $EndDate = Get-Date }
if (-not $StartDate) { $StartDate = $EndDate.AddDays(-1 * [math]::Abs($Days)) }

Write-Section "Searching unified audit log for Copilot interactions (read-only)"
$events = @()
$searched = $false
try {
    $null = Get-Command Search-UnifiedAuditLog -ErrorAction Stop
    $searched = $true
    # Copilot interactions surface under record types such as CopilotInteraction (verify in your tenant).
    $events = Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate `
        -RecordType CopilotInteraction -ResultSize 5000 -ErrorAction Stop
} catch {
    Write-Warning "Search-UnifiedAuditLog unavailable or record type differs: $($_.Exception.Message)"
    Write-Warning "Alternative: Get-MgAuditLogDirectoryAudit / the Purview Audit portal. Verify the Copilot record/operation names for your tenant."
}

$rows = @()
foreach ($e in $events) {
    $rows += [pscustomobject]@{
        CreationDate = $e.CreationDate
        UserId       = $e.UserIds
        Operation    = $e.Operations
        RecordType   = $e.RecordType
        AuditData    = ($e.AuditData) # JSON blob; do not parse content here (privacy)
    }
}

Write-Host ("Copilot interaction events found: {0} ({1:u} - {2:u})" -f $rows.Count, $StartDate, $EndDate)
$rows | Select-Object CreationDate, UserId, Operation -First 20 | Format-Table -AutoSize | Out-Host

$null = New-Item -ItemType Directory -Force -Path $OutDir
$safe = ($ArtifactName -replace '[^\w\-]+','_')
$summary = [ordered]@{
    Artifact       = $ArtifactName
    GeneratedUtc   = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    WindowStart    = $StartDate.ToUniversalTime().ToString("s") + "Z"
    WindowEnd      = $EndDate.ToUniversalTime().ToString("s") + "Z"
    Searched       = $searched
    EventCount     = $rows.Count
    TrailConfirmed = ($searched -and $rows.Count -gt 0)
    Note           = "If Searched=true but EventCount=0: no interactions in window OR audit latency/off. eDiscoverability: confirm in Purview eDiscovery. Copilot record/operation names may vary - verify."
}
$json = Join-Path $OutDir "$safe.json"
$summary | ConvertTo-Json -Depth 4 | Out-File -FilePath $json -Encoding UTF8
$csv  = Join-Path $OutDir "$safe.csv"
$rows | Select-Object CreationDate, UserId, Operation, RecordType | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $json" -ForegroundColor Green
Write-Host "Wrote $csv"  -ForegroundColor Green
Write-Host "`nRead-only: audit evidence exported. Confirm eDiscoverability in the Purview portal." -ForegroundColor Yellow
