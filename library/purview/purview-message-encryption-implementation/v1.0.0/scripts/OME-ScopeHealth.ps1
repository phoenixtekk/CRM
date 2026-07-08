<#
.SYNOPSIS
    OME-ScopeHealth.ps1 — test the RMS encrypt/decrypt path and preview pilot-group scope before expanding (read-only).
.DESCRIPTION
    PURPOSE
        Read-only health + scope helper for Purview Message Encryption (OME). Runs
        Test-IRMConfiguration for a sender/recipient pair to confirm the RMS encrypt/decrypt round-trip
        (Testing Gate 2), and previews the pilot group's current membership so an expansion is staged
        deliberately (group-by-group) rather than tenant-wide. It only reads and tests — it never adds
        members or changes rules.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with ExchangeOnlineManagement; Connect-ExchangeOnline as an Exchange admin.
          .\OME-ScopeHealth.ps1 -Sender pilot@contoso.com -Recipient external@example.com
          .\OME-ScopeHealth.ps1 -PilotGroup "SG-OME-Pilot@contoso.com" -Sender pilot@contoso.com -Recipient external@example.com
    EXPECTED RESULTS
        Test-IRMConfiguration returns PASS on all checks; the pilot group's members are listed so you can
        see who a rule change would affect before you widen scope.
.NOTES
    White-label. Read-only (no membership/rule changes). Exchange Online PowerShell. No credentials in
    code. Expansion (adding members / broadening -FromMemberOf) is a deliberate, gated step
    (03-implementation.md Phase 5). No cmdlets invented.
#>

[CmdletBinding()]
param(
    [string] $Sender,
    [string] $Recipient,
    [string] $PilotGroup = 'SG-OME-Pilot@contoso.com'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

if (-not (Get-Command Get-IRMConfiguration -ErrorAction SilentlyContinue)) {
    Write-Error 'Not connected to Exchange Online. Run Connect-ExchangeOnline with an Exchange admin, then retry.'
    return
}

# --- RMS encrypt/decrypt round-trip (Gate 2) --------------------------------------------------------
Write-Section 'RMS health — Test-IRMConfiguration'
if ($Sender -and $Recipient) {
    try {
        $res = Test-IRMConfiguration -Sender $Sender -Recipient $Recipient -ErrorAction Stop
        $res | Format-List
        $overall = ($res | Where-Object { $_.Result -match 'FAIL' }).Count -eq 0
        if ($overall) { Write-Host 'Test-IRMConfiguration: all checks PASS.' -ForegroundColor Green }
        else          { Write-Host 'Test-IRMConfiguration: one or more checks FAILED — see above; RMS must pass before OME.' -ForegroundColor Yellow }
    } catch { Write-Warning ("Test-IRMConfiguration failed: {0}" -f $_.Exception.Message) }
} else {
    Write-Host 'Pass -Sender and -Recipient to run the encrypt/decrypt round-trip test (Gate 2).' -ForegroundColor Yellow
    try {
        $irm = Get-IRMConfiguration -ErrorAction Stop
        Write-Host ("AzureRMSLicensingEnabled : {0}" -f $irm.AzureRMSLicensingEnabled) -ForegroundColor ($(if($irm.AzureRMSLicensingEnabled){'Green'}else{'Yellow'}))
    } catch { }
}

# --- Pilot scope preview ----------------------------------------------------------------------------
Write-Section ("Pilot scope preview — {0}" -f $PilotGroup)
$members = @()
try { $members = @(Get-DistributionGroupMember -Identity $PilotGroup -ErrorAction Stop) }
catch {
    try { $members = @(Get-UnifiedGroupLinks -Identity $PilotGroup -LinkType Members -ErrorAction Stop) }
    catch { Write-Host ("  Could not read '{0}' membership — verify the group name/type." -f $PilotGroup) -ForegroundColor Yellow }
}
if ($members.Count -gt 0) {
    Write-Host ("Current members: {0}" -f $members.Count) -ForegroundColor Green
    $members | Select-Object DisplayName, PrimarySmtpAddress | Format-Table -AutoSize
    Write-Host 'These are the senders a rule change affects today. Expand group-by-group and re-run the gates.' -ForegroundColor Cyan
} else {
    Write-Host 'No members resolved. Confirm the pilot group exists and holds only sanctioned pilot senders.' -ForegroundColor Yellow
}

Write-Section 'Scope/health check complete'
Write-Host 'Read-only: this script tests and previews only. Adding members / broadening rules is a'
Write-Host 'deliberate, gated expansion step (03-implementation.md Phase 5; re-run 05-testing.md gates).'
