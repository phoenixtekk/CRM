<#
.SYNOPSIS
    NSZTNA-Report.ps1 — access + usage report: who is entitled to which apps (Entra), plus posture.
.DESCRIPTION
    PURPOSE
        Read-only reporting for a Netskope Private Access (ZTNA) deployment. Enumerates the Entra
        entitlement groups ('Access Group - <App or Role> - <Stage>') and their members from Microsoft
        Graph, so you can audit who is entitled to which private apps and confirm least-privilege.
        Optionally annotates members with device posture (compliant device count) from Graph. The
        ZTNA *usage* side (sessions/bytes per app) lives in Netskope and is DEFERRED to its REST API.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NSZTNA-Report.ps1 ^
            -GroupPrefix "Access Group" ^
            -CsvPath .\ztna-access-report.csv
        Requires the Microsoft Graph PowerShell SDK and sign-in with Group.Read.All,
        User.Read.All, and DeviceManagementManagedDevices.Read.All (read-only).
    EXPECTED RESULTS
        A per-group listing of entitled members (and an optional CSV), plus a note that per-app usage
        metrics come from Netskope. No changes are made.
.NOTES
    Network — ZTNA / Netskope Private Access. Read-only against Graph. Authored the repeatable way.
#>
[CmdletBinding()]
param(
    [string]$GroupPrefix = "Access Group",
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Install-Module Microsoft.Graph.Groups, Microsoft.Graph.Users -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host "`n=== ZTNA Access Report — entitlement groups matching '$GroupPrefix*' ===" -ForegroundColor Cyan

$filter = "startswith(displayName,'$GroupPrefix')"
$groups = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$filter&`$select=id,displayName").value
if (-not $groups) { Write-Host "No matching entitlement groups found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$rows = @()
foreach ($g in $groups) {
    $members = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($g.id)/members?`$select=id,displayName,userPrincipalName").value
    Write-Host ("`n  {0}  [{1} member(s)]" -f $g.displayName, ($members | Measure-Object).Count) -ForegroundColor White
    foreach ($m in $members) {
        $upn = $m.userPrincipalName
        Write-Host ("    - {0}  ({1})" -f $m.displayName, $upn)
        $rows += [pscustomobject]@{ AccessGroup = $g.displayName; Member = $m.displayName; UserPrincipalName = $upn }
    }
}

# --- Posture summary (compliant managed device count, informational) ---
try {
    $devices = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$select=deviceName,complianceState").value
    $compliant = ($devices | Where-Object { $_.complianceState -eq 'compliant' } | Measure-Object).Count
    Write-Host ("`n  Posture: {0} of {1} managed devices report compliant." -f $compliant, ($devices | Measure-Object).Count) -ForegroundColor Cyan
} catch {
    Write-Host "`n  Posture summary skipped (no managed-device read access)." -ForegroundColor Yellow
}

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("`n  CSV written: {0}" -f $CsvPath) -ForegroundColor Green }

Write-Host "`n--- Per-app ZTNA usage (DEFERRED) ---" -ForegroundColor DarkGray
Write-Host "  Sessions/bytes per published app are in Netskope; pull them via the Netskope REST API" -ForegroundColor DarkGray
Write-Host "  (tenant base URL + token). Endpoints/schema are DEFERRED to the official Netskope docs." -ForegroundColor DarkGray

Disconnect-MgGraph | Out-Null
Write-Host "`nReport complete (read-only)." -ForegroundColor Green
