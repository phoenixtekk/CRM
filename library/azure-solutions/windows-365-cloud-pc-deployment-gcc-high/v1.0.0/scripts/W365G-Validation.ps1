<#
.SYNOPSIS
    W365G-Validation.ps1 — validate Windows 365 Government (GCC High) Cloud PC health and prerequisites.
.DESCRIPTION
    PURPOSE
        Confirms, against Microsoft Graph US Gov, that Cloud PCs are provisioned and healthy and that
        the licensing prerequisites are in place. Lists each Cloud PC's status and grace-period state
        and surfaces GCC High parity reminders. Read-only — makes no changes. Placeholders like
        your-tenant-id are used, not angle brackets.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\W365G-Validation.ps1
        Requires the Microsoft Graph PowerShell SDK. Connects with -Environment USGov (graph.microsoft.us)
        and consents to read-only scopes on first run.
    EXPECTED RESULTS
        A per-Cloud-PC health list plus a licensing check. Pass = all Cloud PCs 'provisioned' and the
        required Windows 365 Government / Intune / Entra ID P1 seats are present; fail = any Cloud PC in
        'provisioningFailed'/'inGracePeriod' or a missing prerequisite license, each flagged.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# GCC High: Microsoft Graph US Gov L4 (graph.microsoft.us). Read-only scopes.
Connect-MgGraph -Environment USGov -Scopes 'CloudPC.Read.All','Organization.Read.All','Directory.Read.All' -NoWelcome

$fail = 0
Write-Host "`n=== Windows 365 Government (GCC High) validation ===" -ForegroundColor Cyan
Write-Host "Graph environment: USGov (graph.microsoft.us)" -ForegroundColor DarkCyan

# --- Cloud PC health ---
Write-Host "`n-- Cloud PC health --" -ForegroundColor Cyan
$cpcs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/virtualEndpoint/cloudPCs').value
if (-not $cpcs) { Write-Host "  No Cloud PCs found yet." -ForegroundColor Yellow }
foreach ($c in $cpcs) {
    $ok = $c.status -eq 'provisioned'
    $color = if ($ok) { 'Green' } else { 'Red' }
    if (-not $ok) { $fail++ }
    Write-Host ("  {0,-32} user: {1,-30} status: {2}" -f $c.displayName, $c.userPrincipalName, $c.status) -ForegroundColor $color
}

# --- Licensing prerequisites (match by name; part numbers vary by tenant) ---
Write-Host "`n-- Licensing prerequisites --" -ForegroundColor Cyan
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
foreach ($want in 'WINDOWS_365','INTUNE','AAD_PREMIUM') {
    $match = $skus | Where-Object { $_.skuPartNumber -match $want }
    if ($match) {
        foreach ($s in $match) {
            $avail = $s.prepaidUnits.enabled - $s.consumedUnits
            Write-Host ("  {0,-34} available: {1}" -f $s.skuPartNumber, $avail)
        }
    } else {
        Write-Host ("  MISSING prerequisite SKU matching '{0}'" -f $want) -ForegroundColor Red; $fail++
    }
}

Write-Host "`n-- GCC High parity reminders --" -ForegroundColor Cyan
Write-Host "  * Windows 365 Security baseline is unavailable — harden via a Settings catalog profile." -ForegroundColor DarkYellow
Write-Host "  * GPU Cloud PCs, Windows 365 Boot(GCC-only)/Switch/Reserve, cross-region DR are unavailable." -ForegroundColor DarkYellow
Write-Host "  * Intune Autopilot / Remote Help / Autopatch / update rings are unavailable in GCC High." -ForegroundColor DarkYellow

Disconnect-MgGraph | Out-Null
if ($fail -eq 0) { Write-Host "`nVALIDATION PASSED (read-only, USGov)." -ForegroundColor Green }
else { Write-Host ("`nVALIDATION FOUND {0} ISSUE(S) — review items in red above." -f $fail) -ForegroundColor Red }
