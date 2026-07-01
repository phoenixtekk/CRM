<#
.SYNOPSIS
    SENTLOG-Remediation.ps1 — add a missing Entra ID diagnostic setting routing audit logs to the workspace.
.DESCRIPTION
    PURPOSE
        Safe remediation for the #1 gap: no diagnostic setting routing Entra ID logs to the workspace.
        Creates the named Entra ID diagnostic setting forwarding the in-scope categories to the Log
        Analytics workspace. Defaults to -WhatIf (reports what it WOULD do, changes nothing).
    HOW TO RUN
        Connect-AzAccount first. Preview (default, safe):
        powershell -ExecutionPolicy Bypass -File .\SENTLOG-Remediation.ps1 -ResourceGroup <rg> -WorkspaceName "Security Telemetry - Tenant - Workspace"
        Apply for real (must pass -WhatIf:$false):
        powershell -ExecutionPolicy Bypass -File .\SENTLOG-Remediation.ps1 -ResourceGroup <rg> -WorkspaceName "..." -WhatIf:$false
        Requires modules: Az.Accounts, Az.OperationalInsights, Az.Monitor. Requires a role that can edit
        Entra ID diagnostic settings (Requirement 2.2).
    EXPECTED RESULTS
        In preview: prints the diagnostic setting it would create and the categories. When applied:
        creates "Audit Telemetry - Entra ID - Pilot" routing the categories to the workspace.
.NOTES
    Sentinel Solutions. Mutating only when -WhatIf:$false is passed.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [string]$SettingName = 'Audit Telemetry - Entra ID - Pilot',
    [string[]]$Categories = @('SignInLogs','AuditLogs'),
    [bool]$WhatIf = $true
)

# Honor the script-default safety: if caller did not explicitly turn off -WhatIf, force preview.
if ($WhatIf) { $WhatIfPreference = $true }

Write-Host "=== SENTLOG Remediation — Entra ID diagnostic setting ===" -ForegroundColor Cyan
$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
$entraResId = "/providers/microsoft.aadiam"

# Does a setting already route these categories to this workspace?
$existing = Get-AzDiagnosticSetting -ResourceId $entraResId -ErrorAction SilentlyContinue |
    Where-Object { $_.WorkspaceId -eq $ws.ResourceId }
if ($existing) {
    Write-Host ("A diagnostic setting already routes Entra ID logs to this workspace: {0}" -f ($existing.Name -join ', ')) -ForegroundColor Green
    Write-Host "No remediation needed (avoiding duplicate ingestion). Add categories by editing it if required." -ForegroundColor Green
    return
}

Write-Host ("Would create diagnostic setting : {0}" -f $SettingName) -ForegroundColor Cyan
Write-Host ("  Target workspace             : {0}" -f $ws.Name)
Write-Host ("  Categories                   : {0}" -f ($Categories -join ', '))

if ($PSCmdlet.ShouldProcess($SettingName, "Create Entra ID diagnostic setting routing [$($Categories -join ', ')] to $($ws.Name)")) {
    $logs = foreach ($c in $Categories) { New-AzDiagnosticSettingLogSettingsObject -Category $c -Enabled $true }
    New-AzDiagnosticSetting -Name $SettingName -ResourceId $entraResId -WorkspaceId $ws.ResourceId -Log $logs -ErrorAction Stop | Out-Null
    Write-Host "Created. Allow ~15 minutes, then run SENTLOG-Validation.ps1." -ForegroundColor Green
} else {
    Write-Host "`nPreview only — re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
}
