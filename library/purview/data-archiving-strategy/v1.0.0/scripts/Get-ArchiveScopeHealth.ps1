<#
.SYNOPSIS
    Preflight scope/health check for the data archiving strategy (READ-ONLY; makes no changes).
.DESCRIPTION
    Verifies the engineer can proceed: required PowerShell modules are present, Exchange Online and
    Security & Compliance PowerShell sessions are connected, and the named pilot group resolves to
    mailboxes. Reports readiness; does not enable archives or change any policy.
.EXAMPLE
    .\Get-ArchiveScopeHealth.ps1 -PilotGroup grp-archive-pilot
    Runs on PowerShell 5.1+/7+. Connect first with Connect-ExchangeOnline and Connect-IPPSSession
    (and optionally Connect-MgGraph). Expected results: PASS lines for modules, both sessions, and a
    resolved pilot-group membership; any FAIL indicates a prerequisite to fix before configuring.
.NOTES
    Expected results: all checks PASS = ready to run discovery/configuration. Any FAIL = stop and
    remediate (module install, connect session, or fix the pilot group) before proceeding.
    No credentials or secrets are used or stored.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PilotGroup
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Name, [bool]$Pass, [string]$Detail)
    $results.Add([pscustomobject]@{
        Check  = $Name
        Status = if ($Pass) { 'PASS' } else { 'FAIL' }
        Detail = $Detail
    })
}

# 1. Required modules present
$mod = Get-Module -ListAvailable -Name ExchangeOnlineManagement | Select-Object -First 1
Add-Check 'ExchangeOnlineManagement module' ([bool]$mod) `
    ($(if ($mod) { "v$($mod.Version)" } else { 'Install-Module ExchangeOnlineManagement' }))

$graph = Get-Module -ListAvailable -Name Microsoft.Graph* | Select-Object -First 1
Add-Check 'Microsoft.Graph module (optional)' ([bool]$graph) `
    ($(if ($graph) { "v$($graph.Version)" } else { 'Optional: Install-Module Microsoft.Graph' }))

# 2. Exchange Online session connected
$exoOk = $false; $exoDetail = 'Run Connect-ExchangeOnline'
try {
    $org = Get-OrganizationConfig -ErrorAction Stop
    $exoOk = $true
    $exoDetail = "Connected; AutoExpandingArchive(org)=$($org.AutoExpandingArchive)"
} catch { $exoDetail = "Not connected: $($_.Exception.Message)" }
Add-Check 'Exchange Online session' $exoOk $exoDetail

# 3. Security & Compliance PowerShell session connected
$sccOk = $false; $sccDetail = 'Run Connect-IPPSSession'
try {
    $null = Get-RetentionCompliancePolicy -ErrorAction Stop | Select-Object -First 1
    $sccOk = $true
    $sccDetail = 'Connected (Data Lifecycle / retention cmdlets available)'
} catch { $sccDetail = "Not connected or no access: $($_.Exception.Message)" }
Add-Check 'Security & Compliance PowerShell session' $sccOk $sccDetail

# 4. Pilot group resolves to mailboxes (requires EXO session)
if ($exoOk) {
    try {
        $members = Get-DistributionGroupMember -Identity $PilotGroup -ErrorAction Stop
        $mbxCount = ($members | Where-Object { $_.RecipientType -like '*Mailbox*' }).Count
        Add-Check "Pilot group '$PilotGroup'" ($mbxCount -gt 0) "$mbxCount mailbox member(s)"
    } catch {
        Add-Check "Pilot group '$PilotGroup'" $false "Could not resolve: $($_.Exception.Message)"
    }
} else {
    Add-Check "Pilot group '$PilotGroup'" $false 'Skipped — Exchange Online session required'
}

$results | Format-Table -AutoSize
$failed = ($results | Where-Object Status -eq 'FAIL').Count
Write-Host ''
if ($failed -eq 0) {
    Write-Host 'READY: all preflight checks passed.' -ForegroundColor Green
} else {
    Write-Host "NOT READY: $failed check(s) failed — remediate before configuring." -ForegroundColor Yellow
}
