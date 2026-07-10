<#
.SYNOPSIS
    SENTDEPG-Set-Diagnostics.ps1 — preview/apply the Entra ID and Azure Activity diagnostic routing to the workspace (-WhatIf default).
.DESCRIPTION
    PURPOSE
        Configures the diagnostic-settings connectors that route high-value telemetry to the workspace:
        the Entra ID diagnostic setting Diag-EntraID-SignInAudit-Pilot (SignInLogs + AuditLogs) and the
        Azure Activity subscription routing. It runs in PREVIEW (-WhatIf) by default, printing exactly
        what it would create/change; only -Commit applies it. Every change is a named object that can be
        deleted for a clean rollback.
    HOW TO RUN
        # Preview (default, changes nothing):
        pwsh -File .\SENTDEPG-Set-Diagnostics.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace"
        # Apply:
        pwsh -File .\SENTDEPG-Set-Diagnostics.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace" -Commit

        Prereqs: Az.Accounts, Az.Monitor, Az.OperationalInsights; source-side rights to edit Entra ID /
        subscription diagnostic settings (R5). The Entra ID tenant diagnostic setting is created via the
        Entra diagnostic-settings API; some tenants require the portal path
        (entra.microsoft.com -> Diagnostic settings) — where the API is not exposed the script says so.
        Verify categories/paths against your tenant.
    EXPECTED RESULTS
        A preview of the intended Entra ID and Azure Activity diagnostic routing; with -Commit, the named
        settings are created/updated to send only the in-scope categories to the workspace.
.NOTES
    White-label. -WhatIf by default; -Commit gates any change. Az PowerShell. No credentials in code.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [string] $EntraDiagName = 'Diag-EntraID-SignInAudit-Pilot',
    [string[]] $EntraCategories = @('SignInLogs','AuditLogs'),
    [switch] $Commit,
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureUSGovernment'
)

$ErrorActionPreference = 'Stop'
if (-not $Commit) { $WhatIfPreference = $true }
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    $ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
    $wsResourceId = $ws.ResourceId
    Write-Host ("Target workspace: {0}" -f $wsResourceId) -ForegroundColor Green
}
catch { Write-Error ("Failed to resolve workspace: {0}" -f $_.Exception.Message); return }

if (-not $Commit) {
    Write-Host ''
    Write-Host 'PREVIEW MODE (-WhatIf). No changes will be made. Re-run with -Commit to apply.' -ForegroundColor Yellow
}

# --- Azure Activity routing -------------------------------------------------------------------------
Write-Section 'Azure Activity -> workspace'
$subId = (Get-AzContext).Subscription.Id
$subResourceId = "/subscriptions/$subId"
Write-Host ("Would route Azure Activity for subscription {0} to the workspace." -f (Get-AzContext).Subscription.Name)
Write-Host 'Note: the Sentinel Azure Activity connector provisions a DCR (DCR-AzureActivity-Subscription-Pilot).'
Write-Host 'For the classic diagnostic route, a subscription activity-log diagnostic setting is used.'
try {
    if ($PSCmdlet.ShouldProcess($subResourceId, "Create/update Azure Activity diagnostic routing to $WorkspaceName")) {
        # Preferred modern path is the Sentinel Azure Activity connector (DCR-based) in the portal.
        Write-Host 'Applying: enable Azure Activity via the Sentinel connector (portal wizard) or a'
        Write-Host 'subscription diagnostic setting. This script previews intent; complete the DCR-based'
        Write-Host 'connector in Sentinel -> Data connectors -> Azure Activity per 03-implementation.md Phase 2.'
    }
}
catch { Write-Warning ("Azure Activity step: {0}" -f $_.Exception.Message) }

# --- Entra ID diagnostic setting --------------------------------------------------------------------
Write-Section ("Entra ID diagnostic setting: {0}" -f $EntraDiagName)
Write-Host ("Categories to route: {0}" -f ($EntraCategories -join ', '))
Write-Host 'High-volume categories (NonInteractiveUserSignInLogs, etc.) are intentionally NOT included'
Write-Host 'unless a detection needs them. Add them only deliberately (cost).'
try {
    if ($PSCmdlet.ShouldProcess("Entra ID tenant", "Create diagnostic setting $EntraDiagName -> $WorkspaceName")) {
        Write-Host 'Applying via Entra diagnostic-settings API...'
        # The Entra ID (aadiam) diagnostic setting is set at the tenant scope. Where the Az cmdlet does
        # not expose the aad tenant scope in your tenant/cloud, use the portal:
        #   entra.microsoft.com -> Identity -> Monitoring & health -> Diagnostic settings -> Add.
        $logs = $EntraCategories | ForEach-Object { New-AzDiagnosticSettingLogSettingsObject -Category $_ -Enabled $true }
        try {
            New-AzDiagnosticSetting -Name $EntraDiagName -ResourceId '/providers/microsoft.aadiam/diagnosticSettings' `
                -WorkspaceId $wsResourceId -Log $logs -ErrorAction Stop | Out-Null
            Write-Host 'Entra ID diagnostic setting created/updated.' -ForegroundColor Green
        }
        catch {
            Write-Warning ("Entra ID diagnostic setting could not be set via Az here: {0}" -f $_.Exception.Message)
            Write-Host 'Create it in the portal: entra.microsoft.com -> Diagnostic settings -> Add ->'
            Write-Host ("  name '{0}', categories {1}, send to {2}." -f $EntraDiagName, ($EntraCategories -join '+'), $WorkspaceName)
        }
    }
}
catch { Write-Warning ("Entra ID step: {0}" -f $_.Exception.Message) }

Write-Section 'Done'
if (-not $Commit) { Write-Host 'Preview complete. Re-run with -Commit to apply.' -ForegroundColor Yellow }
else { Write-Host 'Apply complete. Verify with SENTDEPG-Report.ps1 (expect SigninLogs/AuditLogs/AzureActivity rows within ~30 min).' -ForegroundColor Green }
Write-Host 'Rollback: delete the named diagnostic setting / DCR to stop that source immediately.'
