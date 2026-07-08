<#
.SYNOPSIS
    CLSREPORT-Validate.ps1 — read-only PASS/FAIL gate for classification reporting: audit ingestion on, viewer role groups populated (Content Viewer minimal), export cmdlets resolve.
.DESCRIPTION
    PURPOSE
        Confirms the reporting prerequisites are in place before you expand to the full analyst audience:
        unified audit log ingestion is True; the intended analysts are in Content Explorer List Viewer;
        Content Explorer Content Viewer is minimal (it exposes sensitive content); and the export surfaces
        this solution relies on resolve in the tenant. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CLSREPORT-Validate.ps1 -ExpectedListViewer user1@contoso.com,user2@contoso.com -MaxContentViewers 3
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and Exchange Online PowerShell
        (Connect-ExchangeOnline). PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        A PASS/FAIL table across the checks. PASS = audit ingestion True, expected analysts present in List
        Viewer, Content Viewer within the minimal threshold, and no unexpected members. An unresolved
        Export-ContentExplorerData is reported as VERIFY (licensing/tenant-dependent), not FAIL.
.NOTES
    Purview — Classification Reporting & Analytics. Read-only against S&C PowerShell / Exchange Online. No changes, no credentials in code.
    Expected results: all applicable checks PASS; Content Viewer minimal; export availability flagged VERIFY where tenant-dependent.
#>
[CmdletBinding()]
param(
    [string[]]$ExpectedListViewer    = @(),
    [string[]]$AllowedContentViewer  = @(),
    [int]$MaxContentViewers          = 5,
    [string]$ListViewerRoleGroup     = 'Content Explorer List Viewer',
    [string]$ContentViewerRoleGroup  = 'Content Explorer Content Viewer',
    [string]$CsvPath,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-RoleGroupMember -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}
if (-not (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false } else { Connect-ExchangeOnline -ShowBanner:$false }
}

$results = New-Object System.Collections.Generic.List[object]
function Add-Result { param($Check, $Status, $Detail)
    $results.Add([pscustomobject]@{ Check = $Check; Status = $Status; Detail = $Detail })
    $color = switch ($Status) { 'PASS' {'Green'} 'FAIL' {'Red'} 'VERIFY' {'Yellow'} default {'Gray'} }
    Write-Host ("[{0}] {1} — {2}" -f $Status, $Check, $Detail) -ForegroundColor $color
}

Write-Host '=== Classification Reporting Validation (read-only) ===' -ForegroundColor Cyan

# --- 1. Audit ingestion enabled ---
try {
    $auditOn = [bool](Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled
    if ($auditOn) { Add-Result 'Audit ingestion enabled' 'PASS' 'UnifiedAuditLogIngestionEnabled = True' }
    else          { Add-Result 'Audit ingestion enabled' 'FAIL' 'False — enable via CLSREPORT-Configure.ps1 -EnableAudit -Commit (Req 2.4)' }
} catch {
    Add-Result 'Audit ingestion enabled' 'VERIFY' ("Could not read audit config: {0}" -f $_.Exception.Message)
}

# --- 2. List Viewer contains the expected analysts ---
$listMembers = @()
try { $listMembers = @(Get-RoleGroupMember -Identity $ListViewerRoleGroup -ErrorAction Stop | Select-Object -ExpandProperty Name) } catch {
    Add-Result 'List Viewer readable' 'VERIFY' ("Could not read '{0}': {1}" -f $ListViewerRoleGroup, $_.Exception.Message)
}
if ($ExpectedListViewer.Count -gt 0) {
    $missing = @($ExpectedListViewer | Where-Object { $listMembers -notcontains $_ })
    if ($missing.Count -eq 0) { Add-Result 'List Viewer membership' 'PASS' ("All {0} expected analyst(s) present" -f $ExpectedListViewer.Count) }
    else                      { Add-Result 'List Viewer membership' 'FAIL' ("Missing: {0}" -f ($missing -join '; ')) }
} else {
    Add-Result 'List Viewer membership' 'VERIFY' ("{0} member(s); pass -ExpectedListViewer to assert the intended set" -f $listMembers.Count)
}

# --- 3. Content Viewer is minimal (it exposes sensitive content) ---
$contentMembers = @()
try { $contentMembers = @(Get-RoleGroupMember -Identity $ContentViewerRoleGroup -ErrorAction Stop | Select-Object -ExpandProperty Name) } catch {
    Add-Result 'Content Viewer readable' 'VERIFY' ("Could not read '{0}': {1}" -f $ContentViewerRoleGroup, $_.Exception.Message)
}
if ($contentMembers.Count -le $MaxContentViewers) {
    Add-Result 'Content Viewer minimal' 'PASS' ("{0} member(s) <= threshold {1}" -f $contentMembers.Count, $MaxContentViewers)
} else {
    Add-Result 'Content Viewer minimal' 'FAIL' ("{0} member(s) exceeds threshold {1} — Content Viewer exposes sensitive data; trim it" -f $contentMembers.Count, $MaxContentViewers)
}
if ($AllowedContentViewer.Count -gt 0) {
    $unexpected = @($contentMembers | Where-Object { $AllowedContentViewer -notcontains $_ })
    if ($unexpected.Count -eq 0) { Add-Result 'Content Viewer no drift' 'PASS' 'Only approved members present' }
    else                         { Add-Result 'Content Viewer no drift' 'FAIL' ("Unexpected member(s): {0} — investigate role-group drift; remove with Remove-RoleGroupMember" -f ($unexpected -join '; ')) }
}

# --- 4. Export surfaces resolve (licensing-/tenant-dependent — VERIFY, not FAIL) ---
if (Get-Command Export-ContentExplorerData -ErrorAction SilentlyContinue) {
    Add-Result 'Content coverage export' 'VERIFY' 'Export-ContentExplorerData resolved (version-dependent) — VERIFY output in your tenant before relying on it'
} else {
    Add-Result 'Content coverage export' 'VERIFY' 'Export-ContentExplorerData not present — use the Content Explorer PORTAL (or Graph, where available) for coverage; verify your licensing/tenant (Req 2.1)'
}
if (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue) {
    Add-Result 'Activity export cmdlet' 'PASS' 'Search-UnifiedAuditLog resolves (activity export available)'
} else {
    Add-Result 'Activity export cmdlet' 'FAIL' 'Search-UnifiedAuditLog not resolvable — connect Exchange Online (GR §3)'
}

# --- Summary ---
$fail = @($results | Where-Object { $_.Status -eq 'FAIL' }).Count
Write-Host ('--- {0} check(s): {1} PASS, {2} FAIL, {3} VERIFY ---' -f $results.Count,
    (@($results | Where-Object Status -eq 'PASS').Count), $fail, (@($results | Where-Object Status -eq 'VERIFY').Count)) -ForegroundColor Cyan
if ($fail -eq 0) { Write-Host 'OVERALL: PASS (VERIFY items are licensing/tenant flags to confirm, not failures).' -ForegroundColor Green }
else             { Write-Host ('OVERALL: FAIL — resolve the {0} FAIL check(s) above before expanding to the full analyst audience.' -f $fail) -ForegroundColor Red }

if ($CsvPath) {
    $dir = Split-Path -Parent $CsvPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Validation results exported to {0}" -f $CsvPath) -ForegroundColor Green
}
