<#
.SYNOPSIS
    W365-Remediation.ps1 — safe Cloud PC remediation (reprovision / restart / resize).
.DESCRIPTION
    PURPOSE
        Performs a targeted recovery action on a single Cloud PC: 'reprovision' (rebuild to the
        policy image), 'restart', or 'resize' (change SKU). DEFAULTS TO -WhatIf — it prints the
        action it would take and changes nothing until you pass -Execute.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\W365-Remediation.ps1 -CloudPCId <id> -Action Reprovision
        Apply for real (explicit):
            powershell -ExecutionPolicy Bypass -File .\W365-Remediation.ps1 -CloudPCId <id> -Action Reprovision -Execute
        Get <id> from W365-Report.ps1 / W365-Validation.ps1 or the Intune admin center.
        Requires the Microsoft Graph PowerShell SDK and CloudPC.ReadWrite.All to execute.
    EXPECTED RESULTS
        In -WhatIf mode (default): a printed description of the action and target — nothing changes.
        With -Execute: the Graph action is POSTed and the Cloud PC begins the requested operation.
.NOTES
    Workplace Marketplace — Azure Solutions. Defaults to -WhatIf. The repeatable way.
    Reprovision REBUILDS the Cloud PC to the policy image (user-profile data on the OS disk is lost —
    ensure OneDrive / folder redirection). Actions POST to /deviceManagement/virtualEndpoint/cloudPCs.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$CloudPCId,
    [Parameter(Mandatory)] [ValidateSet('Reprovision','Restart','Resize')] [string]$Action,
    [string]$TargetServicePlanId,   # required only for -Action Resize
    [switch]$Execute                 # omit for -WhatIf (default safe mode)
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

$whatIf = -not $Execute
$scope  = if ($whatIf) { 'CloudPC.Read.All' } else { 'CloudPC.ReadWrite.All' }
Connect-MgGraph -Scopes $scope -NoWelcome

# Map the action to its Graph endpoint + body.
$base = "/beta/deviceManagement/virtualEndpoint/cloudPCs/$CloudPCId"
switch ($Action) {
    'Reprovision' { $uri = "$base/reprovision"; $body = @{} }
    'Restart'     { $uri = "$base/restart";     $body = @{} }
    'Resize' {
        if (-not $TargetServicePlanId) { Write-Host "Resize requires -TargetServicePlanId (the target SKU id)." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
        $uri = "$base/resize"; $body = @{ targetServicePlanId = $TargetServicePlanId }
    }
}

if ($whatIf) {
    Write-Host "[WhatIf] Would POST $uri" -ForegroundColor Yellow
    Write-Host ("[WhatIf] Action '{0}' on Cloud PC '{1}'. No change made. Re-run with -Execute to apply." -f $Action, $CloudPCId) -ForegroundColor Yellow
} else {
    try {
        Invoke-MgGraphRequest -Method POST -Uri $uri -Body ($body | ConvertTo-Json)
        Write-Host ("Executed '{0}' on Cloud PC '{1}'. Re-check with W365-Validation.ps1 after it completes." -f $Action, $CloudPCId) -ForegroundColor Green
    } catch {
        Write-Host ("Action failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

Disconnect-MgGraph | Out-Null
