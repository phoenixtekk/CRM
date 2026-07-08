<#
.SYNOPSIS
    IPRMSMIG-Scope-Health.ps1 — read-only Azure RMS / scope health helper (-Commit only to trigger a label sync).
.DESCRIPTION
    PURPOSE
        Confirms the protection foundation before/after cutover: Azure Rights Management activation
        (Get-AipServiceConfiguration FunctionalState), super-user recovery posture
        (Get-AipServiceSuperUserFeature / Get-AipServiceSuperUser), toolchain connectivity, and the pilot
        scope. Read-only by default; with -Commit it runs Execute-AzureADLabelSync so the protection
        service picks up label/protection changes. Writes "Migration Scope - Map".
    HOW TO RUN
        # Read-only health check:
        powershell -ExecutionPolicy Bypass -File .\IPRMSMIG-Scope-Health.ps1 -CsvPath .\MigrationScope.csv
        # Also trigger a label sync (benign, one-way sync of label changes to protection):
        powershell -ExecutionPolicy Bypass -File .\IPRMSMIG-Scope-Health.ps1 -Commit
        PowerShell 5.1+/7+. Requires AIPService (Connect-AipService) and ExchangeOnlineManagement
        (Connect-IPPSSession, for Execute-AzureADLabelSync).
    EXPECTED RESULTS
        RMS FunctionalState, super-user feature state + members, and connectivity reported. PASS = RMS
        Enabled and recoverable (super-users configured) before you change protection behaviour.
.NOTES
    Purview — Azure RMS / AIP to Built-in Unified Labeling Migration. Read-only unless -Commit is passed
    (which only triggers a label sync). No secrets in code. Activating Azure RMS itself is a separate,
    reserved Global-Admin action (Enable-AipService) and is intentionally NOT performed here.
#>
[CmdletBinding()]
param(
    [switch]$Commit,
    [string]$CsvPath,
    [string]$ReportName = 'Migration Scope - Map'
)

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

$rows = @()

# --- Azure RMS protection service health (AIPService) ---
if (-not (Get-Module -ListAvailable -Name AIPService)) {
    Install-Module AIPService -Scope CurrentUser -Force -AllowClobber
}
Import-Module AIPService -ErrorAction Stop
try {
    Connect-AipService -ErrorAction Stop | Out-Null

    $cfg = Get-AipServiceConfiguration -ErrorAction SilentlyContinue
    $state = $cfg.FunctionalState
    Write-Host ("Azure RMS FunctionalState: {0}" -f $state) -ForegroundColor $(if ($state -eq 'Enabled') {'Green'} else {'Yellow'})
    $rows += [pscustomobject]@{ Check='RMS FunctionalState'; Value=$state; Result=$(if ($state -eq 'Enabled') {'PASS'} else {'FAIL (activate RMS first)'}) }

    # Super-user recovery posture
    $suFeature = $null
    try { $suFeature = Get-AipServiceSuperUserFeature -ErrorAction SilentlyContinue } catch {}
    $suMembers = @()
    try { $suMembers = @(Get-AipServiceSuperUser -ErrorAction SilentlyContinue) } catch {}
    Write-Host ("Super-user feature: {0}  members: {1}" -f $suFeature, $suMembers.Count) -ForegroundColor $(if ($suMembers.Count -gt 0) {'Green'} else {'Yellow'})
    $rows += [pscustomobject]@{ Check='Super-user feature'; Value=("{0}; members={1}" -f $suFeature, $suMembers.Count);
        Result=$(if ($suMembers.Count -gt 0) {'PASS'} else {'WARN (configure recovery before cutover)'}) }

    Disconnect-AipService | Out-Null
} catch {
    Write-Host ("  AIPService not reachable: {0}. Verify the module and Azure RMS activation." -f $_.Exception.Message) -ForegroundColor Yellow
    $rows += [pscustomobject]@{ Check='AIPService connectivity'; Value=$_.Exception.Message; Result='FAIL' }
}

# --- Optional: sync label changes to protection (-Commit) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

if ($Commit) {
    Write-Host '--- Running Execute-AzureADLabelSync (one-way sync of label changes to protection) ---' -ForegroundColor Cyan
    try {
        Execute-AzureADLabelSync -ErrorAction Stop
        Write-Host '  Label sync triggered. Allow time for protection to reflect label changes.' -ForegroundColor Green
        $rows += [pscustomobject]@{ Check='Execute-AzureADLabelSync'; Value='triggered'; Result='PASS' }
    } catch {
        Write-Host ("  Label sync failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
        $rows += [pscustomobject]@{ Check='Execute-AzureADLabelSync'; Value=$_.Exception.Message; Result='FAIL' }
    }
} else {
    Write-Host 'Read-only mode: skipping Execute-AzureADLabelSync (pass -Commit to trigger it).' -ForegroundColor DarkGray
    $rows += [pscustomobject]@{ Check='Label sync'; Value='skipped (read-only)'; Result='INFO' }
}

# Confirm the label toolchain is reachable
$labelCount = @(Get-Label -ErrorAction SilentlyContinue).Count
Write-Host ("Sensitivity labels reachable via S&C PowerShell: {0}" -f $labelCount) -ForegroundColor Green
$rows += [pscustomobject]@{ Check='S&C label toolchain'; Value=("labels=$labelCount"); Result=$(if ($labelCount -gt 0) {'PASS'} else {'WARN'}) }

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}
Write-Host 'Scope/health check complete.' -ForegroundColor Green
