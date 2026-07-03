<#
.SYNOPSIS
    AVDG-Remediation.ps1 — safe, opt-in remediation of common AVD gaps on Azure Government (GCC High). Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Fixes the common prerequisite gaps this solution detects in Azure Government: registers the
        Microsoft.DesktopVirtualization resource provider, and (optionally) registers an application group to a
        workspace so published resources appear in clients. SAFE BY DEFAULT — runs in -WhatIf mode and only
        previews changes; pass -WhatIf:$false (or -Confirm) to apply. Replace placeholders like
        'your-workspace-name' and 'your-app-group-name' with your values.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\AVDG-Remediation.ps1
        Apply:              powershell -ExecutionPolicy Bypass -File .\AVDG-Remediation.ps1 -WhatIf:$false
        Register app group: .\AVDG-Remediation.ps1 -WorkspaceName your-workspace-name -AppGroupName your-app-group-name -ResourceGroupName your-resource-group -WhatIf:$false
        Modules: Az.Accounts, Az.Resources, Az.DesktopVirtualization
        Sign-in (US Gov): Connect-AzAccount -Environment AzureUSGovernment
    EXPECTED RESULTS
        In -WhatIf mode: "What if:" lines describing each change, no changes made. With -WhatIf:$false: the
        provider becomes Registered and/or the app group is registered to the workspace, with confirmation output.
.NOTES
    White-label — the repeatable way. Read-only against Azure/Graph US Gov endpoints; write actions gated by -WhatIf/-Confirm.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$WorkspaceName,
    [string]$AppGroupName,
    [string]$ResourceGroupName,
    [string]$AzureEnvironment = 'AzureUSGovernment'
)

$ErrorActionPreference = 'Stop'
# Default to preview: if the caller didn't explicitly pass -WhatIf or -Confirm, force -WhatIf on.
if (-not $PSBoundParameters.ContainsKey('WhatIf') -and -not $PSBoundParameters.ContainsKey('Confirm')) {
    $WhatIfPreference = $true
    Write-Host '[SAFE MODE] No -WhatIf/-Confirm supplied; running in -WhatIf (preview) mode. Pass -WhatIf:$false to apply.' -ForegroundColor Yellow
}
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }

Write-Section 'Connect (Azure Government)'
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx) { Connect-AzAccount -Environment $AzureEnvironment | Out-Null; $ctx = Get-AzContext }
if ($ctx.Environment.Name -ne 'AzureUSGovernment') {
    Write-Host "[FAIL] Connected environment is '$($ctx.Environment.Name)', not AzureUSGovernment. Aborting to avoid changing the wrong cloud. Re-run Connect-AzAccount -Environment AzureUSGovernment." -ForegroundColor Red
    return
}
Write-Host "Environment: $($ctx.Environment.Name) | Subscription: $($ctx.Subscription.Name)"

Write-Section 'Remediation 1 — register Microsoft.DesktopVirtualization'
try {
    $state = (Get-AzResourceProvider -ProviderNamespace 'Microsoft.DesktopVirtualization' | Select-Object -First 1).RegistrationState
    if ($state -eq 'Registered') { Write-Host '[SKIP] Provider already Registered.' -ForegroundColor Green }
    else {
        if ($PSCmdlet.ShouldProcess('Subscription: ' + $ctx.Subscription.Name, 'Register Microsoft.DesktopVirtualization resource provider')) {
            Register-AzResourceProvider -ProviderNamespace 'Microsoft.DesktopVirtualization' | Out-Null
            Write-Host '[APPLIED] Registration requested. Re-run AVDG-Validation.ps1 to confirm Registered.' -ForegroundColor Green
        }
    }
} catch { Write-Host "[ERROR] Provider registration: $($_.Exception.Message)" -ForegroundColor Red }

Write-Section 'Remediation 2 — register application group to workspace (optional)'
if ($WorkspaceName -and $AppGroupName -and $ResourceGroupName) {
    try {
        $ws = Get-AzWvdWorkspace -Name $WorkspaceName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
        $agId = (Get-AzWvdApplicationGroup -Name $AppGroupName -ResourceGroupName $ResourceGroupName -ErrorAction Stop).Id
        $existing = @($ws.ApplicationGroupReference)
        if ($existing -contains $agId) { Write-Host "[SKIP] App group '$AppGroupName' already registered to workspace '$WorkspaceName'." -ForegroundColor Green }
        else {
            $new = @($existing + $agId | Where-Object { $_ })
            if ($PSCmdlet.ShouldProcess("Workspace: $WorkspaceName", "Register application group '$AppGroupName'")) {
                Update-AzWvdWorkspace -Name $WorkspaceName -ResourceGroupName $ResourceGroupName -ApplicationGroupReference $new | Out-Null
                Write-Host "[APPLIED] App group '$AppGroupName' registered to workspace '$WorkspaceName'." -ForegroundColor Green
            }
        }
    } catch { Write-Host "[ERROR] App-group registration: $($_.Exception.Message)" -ForegroundColor Red }
} else {
    Write-Host '[INFO] Provide -WorkspaceName, -AppGroupName, -ResourceGroupName to (optionally) register an app group.' -ForegroundColor DarkGray
}

Write-Section 'Remediation complete'
if ($WhatIfPreference) { Write-Host 'Preview only — no changes were made. Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Applied requested changes. Re-validate with AVDG-Validation.ps1.' }
