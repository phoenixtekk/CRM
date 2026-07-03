<#
.SYNOPSIS
    W365G-Remediation.ps1 — safe reprovision/resize/restart helpers for Windows 365 Government (GCC High) Cloud PCs.
.DESCRIPTION
    PURPOSE
        Performs a targeted lifecycle action (restart, reprovision, or resize) on a single Cloud PC via
        Microsoft Graph US Gov, to recover an unhealthy Cloud PC the repeatable way. Defaults to
        -WhatIf so nothing changes until you confirm. Placeholders like your-cloudpc-name and
        your-service-plan-id are used, not angle brackets.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\W365G-Remediation.ps1 -CloudPcName 'CPC-...' -Action Restart
        Execute (opt in):
            powershell -ExecutionPolicy Bypass -File .\W365G-Remediation.ps1 -CloudPcName 'CPC-...' -Action Reprovision -WhatIf:$false
        Resize needs a target service plan id:
            powershell -ExecutionPolicy Bypass -File .\W365G-Remediation.ps1 -CloudPcName 'CPC-...' -Action Resize -TargetServicePlanId 'your-service-plan-id' -WhatIf:$false
        Requires the Microsoft Graph PowerShell SDK; connects with -Environment USGov and consents to
        CloudPC.ReadWrite.All on first run.
    EXPECTED RESULTS
        In -WhatIf (default) the intended action is printed and nothing is changed. With -WhatIf:$false
        the action is issued; reprovision rebuilds to the policy image, restart returns the Cloud PC
        healthy, resize changes the SKU (CPU/RAM only — no GPU SKUs in GCC High).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
    Read-only unless invoked with -WhatIf:$false; then it issues one lifecycle action against US Gov Graph.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)] [string]$CloudPcName,
    [Parameter(Mandatory = $true)] [ValidateSet('Restart','Reprovision','Resize')] [string]$Action,
    [string]$TargetServicePlanId,
    [switch]$WhatIf = $true
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# GCC High: Microsoft Graph US Gov L4 (graph.microsoft.us). Write scope required for lifecycle actions.
Connect-MgGraph -Environment USGov -Scopes 'CloudPC.ReadWrite.All' -NoWelcome

Write-Host "`n=== Windows 365 Government (GCC High) remediation ===" -ForegroundColor Cyan
Write-Host "Graph environment: USGov (graph.microsoft.us)" -ForegroundColor DarkCyan

# Locate the Cloud PC by display name.
$esc = $CloudPcName.Replace("'","''")
$cpc = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/virtualEndpoint/cloudPCs?`$filter=displayName eq '$esc'").value | Select-Object -First 1
if (-not $cpc) { Write-Host ("  Cloud PC '{0}' not found." -f $CloudPcName) -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
Write-Host ("  Target: {0}  (id {1}, status {2})" -f $cpc.displayName, $cpc.id, $cpc.status)

if ($Action -eq 'Resize' -and -not $TargetServicePlanId) {
    Write-Host "  Resize requires -TargetServicePlanId (CPU/RAM SKU; no GPU SKUs in GCC High)." -ForegroundColor Red
    Disconnect-MgGraph | Out-Null; return
}

# Map action to the Graph endpoint + body.
switch ($Action) {
    'Restart'     { $uri = "/beta/deviceManagement/virtualEndpoint/cloudPCs/$($cpc.id)/restart";     $body = $null }
    'Reprovision' { $uri = "/beta/deviceManagement/virtualEndpoint/cloudPCs/$($cpc.id)/reprovision"; $body = $null }
    'Resize'      { $uri = "/beta/deviceManagement/virtualEndpoint/cloudPCs/$($cpc.id)/resize";       $body = @{ targetServicePlanId = $TargetServicePlanId } | ConvertTo-Json }
}

if ($WhatIf) {
    Write-Host ("`n  [WhatIf] Would POST {0}{1}" -f $uri, ($(if ($body) { " with body $body" } else { '' }))) -ForegroundColor Yellow
    Write-Host "  No change made. Re-run with -WhatIf:`$false to execute." -ForegroundColor Yellow
}
elseif ($PSCmdlet.ShouldProcess($cpc.displayName, $Action)) {
    if ($body) { Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body }
    else       { Invoke-MgGraphRequest -Method POST -Uri $uri }
    Write-Host ("  {0} issued for {1}." -f $Action, $cpc.displayName) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
Write-Host "`nRemediation routine complete (USGov)." -ForegroundColor Green
