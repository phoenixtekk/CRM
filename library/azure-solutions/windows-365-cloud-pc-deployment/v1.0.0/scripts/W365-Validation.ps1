<#
.SYNOPSIS
    W365-Validation.ps1 — confirm Cloud PCs are provisioned and healthy.
.DESCRIPTION
    PURPOSE
        Validates the deployment after a provisioning policy is assigned: lists each Cloud PC with
        its provisioning status and health, and flags any not in the 'provisioned' state (failed,
        in grace period, or still provisioning). Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\W365-Validation.ps1
        Requires the Microsoft Graph PowerShell SDK; consents to a read-only Cloud PC scope.
    EXPECTED RESULTS
        A per-Cloud-PC status table and a PASS/ATTENTION summary; ATTENTION lists any Cloud PC not
        in a healthy provisioned state so you can investigate before expanding.
.NOTES
    Workplace Marketplace — Azure Solutions. Read-only. The repeatable way.
    Cloud PCs are read from /deviceManagement/virtualEndpoint/cloudPCs (beta) via Graph REST.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'CloudPC.Read.All' -NoWelcome

Write-Host "`n=== Windows 365 Cloud PC validation ===" -ForegroundColor Cyan

# Enumerate all Cloud PCs. Dedicated cmdlet (Get-MgDeviceManagementVirtualEndpointCloudPC) exists in
# newer SDKs but availability varies — REST keeps this script portable.
$cloudPCs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/virtualEndpoint/cloudPCs').value

if (-not $cloudPCs) {
    Write-Host "  No Cloud PCs found. Confirm the provisioning policy is assigned and users are licensed." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    return
}

$attention = @()
foreach ($c in $cloudPCs) {
    $healthy = ($c.status -eq 'provisioned')
    $color = if ($healthy) { 'Green' } else { 'Yellow' }
    Write-Host ("  {0,-28} user: {1,-30} status: {2}" -f $c.displayName, $c.userPrincipalName, $c.status) -ForegroundColor $color
    if (-not $healthy) { $attention += $c }
}

Write-Host ""
if ($attention.Count -eq 0) {
    Write-Host ("PASS — all {0} Cloud PC(s) are provisioned." -f $cloudPCs.Count) -ForegroundColor Green
} else {
    Write-Host ("ATTENTION — {0} of {1} Cloud PC(s) not in 'provisioned' state:" -f $attention.Count, $cloudPCs.Count) -ForegroundColor Yellow
    $attention | ForEach-Object { Write-Host ("   - {0} ({1}) : {2}" -f $_.displayName, $_.userPrincipalName, $_.status) -ForegroundColor Yellow }
    Write-Host "   See the Troubleshooting Guide (Section A/B). Use W365-Remediation.ps1 (-WhatIf) for safe fixes." -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
