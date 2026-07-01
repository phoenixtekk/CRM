<#
.SYNOPSIS
    COPILOT-Discovery.ps1 — Copilot-readiness discovery: oversharing/access + label + readiness signals (Graph).
.DESCRIPTION
    PURPOSE
        Read-only assessment of the top Microsoft 365 Copilot risk — oversharing. Enumerates SharePoint
        sites and (optionally) OneDrive for broad/anonymous/organization sharing links and external
        (guest) access, reports whether sensitivity labels exist in the tenant, and summarizes
        Copilot-readiness signals so you can see the data-exposure surface BEFORE enabling Copilot.
        Copilot returns whatever the signed-in user can access, so broad access = broad exposure.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\COPILOT-Discovery.ps1 [-Top 200] [-IncludeExternal]
        Requires the Microsoft Graph PowerShell SDK and consent to (read-only):
        Sites.Read.All, Files.Read.All, InformationProtectionPolicy.Read, Group.Read.All, User.Read.All.
    EXPECTED RESULTS
        A per-site list flagging anonymous/organization sharing links and external sharing, a count of
        tenant sensitivity labels (0 = labeling not started), and a readiness summary. Nothing is
        changed. Feed the flagged sites into COPILOT-Remediation.ps1 and COPILOT-Report.ps1.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Volatile Copilot-portal and
    usage-report specifics are deferred to Microsoft documentation; this script reads the sharing,
    label, and identity surface via Graph.
#>
[CmdletBinding()]
param(
    [int]$Top = 200,
    [switch]$IncludeExternal
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('Sites.Read.All','Files.Read.All','InformationProtectionPolicy.Read','Group.Read.All','User.Read.All')
Connect-MgGraph -Scopes $scopes -NoWelcome

Write-Host "`n=== Sensitivity labels (protection Copilot honors) ===" -ForegroundColor Cyan
$labels = @()
try {
    $labels = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/security/informationProtection/sensitivityLabels').value
} catch {
    try { $labels = (Invoke-MgGraphRequest -Method GET -Uri '/beta/informationProtection/policy/labels').value } catch { $labels = @() }
}
if ($labels.Count) {
    foreach ($l in $labels) { Write-Host ("  {0}" -f ($l.name ?? $l.displayName)) }
    Write-Host ("  Total labels: {0}" -f $labels.Count) -ForegroundColor Green
} else {
    Write-Host "  No sensitivity labels found — labeling has not started. Unlabeled content relies on" -ForegroundColor Yellow
    Write-Host "  permissions + search controls only until labels are published (Implementation Step 3)." -ForegroundColor Yellow
}

Write-Host "`n=== SharePoint sites — oversharing signals ===" -ForegroundColor Cyan
$sites = @()
try {
    $sites = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/sites?search=*&`$top=$Top").value
} catch {
    Write-Host "  Could not enumerate sites: $($_.Exception.Message)" -ForegroundColor Red
}

$flagged = 0
foreach ($s in $sites) {
    $anon = 0; $org = 0
    try {
        $perms = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/sites/$($s.id)/permissions").value
    } catch { $perms = @() }
    foreach ($p in $perms) {
        $scope = $p.link.scope
        if ($scope -eq 'anonymous') { $anon++ }
        elseif ($scope -eq 'organization') { $org++ }
    }
    if ($anon -or $org) {
        $flagged++
        Write-Host ("  FLAG  {0}  [anonymous links: {1}  org-wide links: {2}]  {3}" -f `
            $s.displayName, $anon, $org, $s.webUrl) -ForegroundColor Yellow
    }
}
if ($flagged -eq 0 -and $sites.Count) {
    Write-Host "  No anonymous/org-wide site sharing links detected in the sampled sites." -ForegroundColor Green
}
Write-Host ("  Sites sampled: {0}  Flagged: {1}" -f $sites.Count, $flagged)

if ($IncludeExternal) {
    Write-Host "`n=== External (guest) users in the tenant ===" -ForegroundColor Cyan
    try {
        $guests = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=userType eq 'Guest'&`$select=displayName,mail,createdDateTime&`$top=999").value
        Write-Host ("  Guest accounts: {0} (review stale guests via Entra access reviews)" -f $guests.Count) -ForegroundColor $(if($guests.Count){'Yellow'}else{'Green'})
    } catch { Write-Host "  Could not enumerate guests: $($_.Exception.Message)" -ForegroundColor Red }
}

Write-Host "`nNext: review flagged sites, then run COPILOT-Remediation.ps1 (-WhatIf) and COPILOT-Report.ps1." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
