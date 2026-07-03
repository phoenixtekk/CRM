<#
.SYNOPSIS
    SENTLOGG-Remediation.ps1 — add a missing Entra ID diagnostic setting routing audit logs to the workspace (GCC High).
.DESCRIPTION
    PURPOSE
        Safe remediation for the #1 gap: no diagnostic setting routing Entra ID logs to the Azure
        Government workspace. Creates the named Entra ID diagnostic setting forwarding the in-scope
        categories to the Log Analytics workspace. Defaults to -WhatIf (reports what it WOULD do, changes
        nothing). Use your-resource-group and your-workspace-name.
    HOW TO RUN
        Connect-AzAccount -Environment AzureUSGovernment first. Preview (default, safe):
        powershell -ExecutionPolicy Bypass -File .\SENTLOGG-Remediation.ps1 -ResourceGroup your-resource-group -WorkspaceName "Security Telemetry - Tenant - Workspace"
        Apply for real (must pass -WhatIf:$false):
        powershell -ExecutionPolicy Bypass -File .\SENTLOGG-Remediation.ps1 -ResourceGroup your-resource-group -WorkspaceName "Security Telemetry - Tenant - Workspace" -WhatIf:$false
        Requires modules: Az.Accounts, Az.OperationalInsights, Az.Monitor. Requires a role that can edit
        Entra ID diagnostic settings (Requirement 2.2).
    EXPECTED RESULTS
        In preview (pass-through, no change): prints the diagnostic setting it would create and the
        categories. When applied: creates "Audit Telemetry - Entra ID - Pilot" routing the categories to
        the Azure Government workspace.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph/Azure US Gov endpoints unless -WhatIf:$false is passed.
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

Write-Host "=== SENTLOGG Remediation — Entra ID diagnostic setting (GCC High / Azure Government) ===" -ForegroundColor Cyan

# Confirm sovereign cloud context before making any change
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx) { Write-Host "Not connected. Run: Connect-AzAccount -Environment AzureUSGovernment" -ForegroundColor Yellow; return }
if ($ctx.Environment.Name -ne 'AzureUSGovernment') {
    Write-Host ("STOP: Az environment is '{0}', not 'AzureUSGovernment'. Re-connect to the sovereign cloud before remediating." -f $ctx.Environment.Name) -ForegroundColor Yellow
    return
}

$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
$entraResId = "/providers/microsoft.aadiam"

# Does a setting already route these categories to this workspace?
$existing = Get-AzDiagnosticSetting -ResourceId $entraResId -ErrorAction SilentlyContinue |
    Where-Object { $_.WorkspaceId -eq $ws.ResourceId }
if ($existing) {
    Write-Host ("A diagnostic setting already routes Entra ID logs to this workspace: {0}" -f ($existing.Name -join ', ')) -ForegroundColor Green
    Write-Host "No remediation needed (avoiding duplicate ingestion). Add categories by editing it in entra.microsoft.us if required." -ForegroundColor Green
    return
}

Write-Host ("Would create diagnostic setting : {0}" -f $SettingName) -ForegroundColor Cyan
Write-Host ("  Target workspace             : {0}" -f $ws.Name)
Write-Host ("  Categories                   : {0}" -f ($Categories -join ', '))

if ($PSCmdlet.ShouldProcess($SettingName, "Create Entra ID diagnostic setting routing [$($Categories -join ', ')] to $($ws.Name)")) {
    $logs = foreach ($c in $Categories) { New-AzDiagnosticSettingLogSettingsObject -Category $c -Enabled $true }
    New-AzDiagnosticSetting -Name $SettingName -ResourceId $entraResId -WorkspaceId $ws.ResourceId -Log $logs -ErrorAction Stop | Out-Null
    Write-Host "Created. Allow ~15 minutes, then run SENTLOGG-Validation.ps1." -ForegroundColor Green
} else {
    Write-Host "`nPreview only — re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
}
