<#
.SYNOPSIS
    PROREM-Discovery.ps1 — read-only inventory of Proactive Remediation script packages.

.DESCRIPTION
    PURPOSE
        Lists every Endpoint Analytics Proactive Remediation (device health script) in the tenant
        with its publisher, run-as context, assignments, and a roll-up of run status (how many
        devices reported "with issue" vs "without issue", and remediation success/failure). Gives you
        a one-page picture of what auto-remediation is currently deployed. Makes NO changes.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\PROREM-Discovery.ps1
        .\PROREM-Discovery.ps1 -NameLike 'PROREM'
        Reads only — makes no changes.

    GRAPH SCOPES (read-only)
        DeviceManagementConfiguration.Read.All

    EXPECTED RESULTS
        A table of remediation packages with assignment count and run-status roll-up. An empty list
        means no Proactive Remediations are deployed yet (or the tenant lacks the entitlement — see
        Requirements R1). NOTE: Proactive Remediations live on Microsoft Graph BETA endpoints
        (deviceManagement/deviceHealthScripts) which can change — verify against current Microsoft
        documentation if a call returns nothing.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$NameLike
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

function GraphGet($uri) {
    $items = @()
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $items += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
    return $items
}

# Proactive Remediations = device health scripts (BETA endpoint — verify with Microsoft docs)
$base = 'https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts'
try {
    $scripts = GraphGet "$base`?`$select=id,displayName,publisher,runAsAccount,enforceSignatureCheck,runAs32Bit,version,lastModifiedDateTime"
} catch {
    Write-Host 'Could not read deviceHealthScripts (beta). Confirm the Proactive Remediations entitlement (R1) and the current Graph endpoint against Microsoft documentation.' -ForegroundColor Yellow
    return
}

if ($NameLike) { $scripts = $scripts | Where-Object { $_.displayName -like "*$NameLike*" } }
if (-not $scripts) { Write-Host 'No Proactive Remediation packages found.' -ForegroundColor Yellow; return }

$rows = foreach ($s in $scripts) {
    $assign = @(); $summary = $null
    try { $assign  = GraphGet "$base/$($s.id)/assignments" } catch {}
    try { $summary = Invoke-MgGraphRequest -Method GET -Uri "$base/$($s.id)/runSummary" } catch {}
    [pscustomobject]@{
        Name          = $s.displayName
        Publisher     = $s.publisher
        RunAs         = $s.runAsAccount        # 'system' or 'user' — must match what the pair touches (R6)
        Signed        = $s.enforceSignatureCheck
        Assignments   = $assign.Count
        WithIssue     = $summary.detectScriptPendingCount + $summary.issueDetectedDeviceCount
        Remediated    = $summary.remediatedDeviceCount
        RemediationFail = $summary.remediationScriptErrorDeviceCount
        Modified      = $s.lastModifiedDateTime
    }
}

$rows | Sort-Object Name | Format-Table -AutoSize
Write-Host ''
Write-Host ("Total Proactive Remediation packages: {0}" -f $rows.Count) -ForegroundColor Cyan
$unassigned = $rows | Where-Object { $_.Assignments -eq 0 }
if ($unassigned) {
    Write-Host ''
    Write-Host 'Packages with NO assignments (deployed to nothing — review):' -ForegroundColor Yellow
    $unassigned | Format-Table Name, Publisher, Modified -AutoSize
}
