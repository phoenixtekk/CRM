<#
.SYNOPSIS
    IPCONT-Check-Prereqs.ps1 — scope/health check: container-labeling enablement, labels, SharePoint sharing baseline, licensing, toolchain (SAFE: read-only).
.DESCRIPTION
    PURPOSE
        Read-only readiness/health helper. Confirms the prerequisites for container labeling are in place:
        the Entra 'Group.Unified' EnableMIPLabels state; whether container-scoped sensitivity labels exist
        and are published; the SharePoint TENANT external-sharing baseline (SharingCapability) and
        ConditionalAccessPolicy; an Entra ID P1 licensing signal (gates unmanaged-device access); and the
        required PowerShell modules/connections. Writes a scope map. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IPCONT-Check-Prereqs.ps1 -CsvPath .\ContainerScope.csv -SPOAdminUrl https://contoso-admin.sharepoint.com
        Requires: Microsoft.Graph (read scopes) and, for the sharing baseline, Microsoft.Online.SharePoint.PowerShell.
    EXPECTED RESULTS
        A checklist of PASS/GAP lines + a CSV (Container Scope - Map). PASS = EnableMIPLabels True,
        container labels present/published, tenant sharing baseline compatible with the taxonomy, and the
        toolchain healthy. Any GAP (e.g. P1 missing) is reported so device-access can be scoped/deferred.
.NOTES
    Purview — Container Labeling (Teams, Groups & Sites). Read-only. Licensing/portal surfaces are
    plan-dependent and evolving — signals here are indicative; verify against your own tenant and plan.
    No secrets in code; interactive modern-auth only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = ".\ContainerScope.csv",
    [string]$SPOAdminUrl,
    [string[]]$GraphScopes = @('Directory.Read.All','Group.Read.All','InformationProtectionPolicy.Read','Organization.Read.All')
)

$checks = New-Object System.Collections.Generic.List[object]
function Add-Check([string]$name,[string]$status,[string]$detail){ $checks.Add([pscustomobject]@{ Check=$name; Status=$status; Detail=$detail }); $c = if($status -eq 'PASS'){'Green'}elseif($status -eq 'GAP'){'Yellow'}else{'Red'}; Write-Host ("  [{0}] {1} — {2}" -f $status, $name, $detail) -ForegroundColor $c }

Write-Host "=== Container Scope - Map : prerequisite / health check ===" -ForegroundColor Cyan

# Modules
foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Online.SharePoint.PowerShell','AIPService','ExchangeOnlineManagement') {
    if (Get-Module -ListAvailable -Name $m) { Add-Check "Module: $m" 'PASS' 'installed' } else { Add-Check "Module: $m" 'GAP' 'not installed (Install-Module)' }
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
try { $ctx = Get-MgContext } catch { $ctx = $null }
if (-not $ctx) { try { Connect-MgGraph -Scopes $GraphScopes | Out-Null } catch { Add-Check 'Graph connect' 'FAIL' $_.Exception.Message } }

# EnableMIPLabels
try {
    $setting = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/settings').value | Where-Object { $_.displayName -eq 'Group.Unified' } | Select-Object -First 1
    $mip = if ($setting) { ($setting.values | Where-Object { $_.name -eq 'EnableMIPLabels' }).value } else { $null }
    if ($mip -eq 'True') { Add-Check 'EnableMIPLabels (Group.Unified)' 'PASS' 'True — container labeling enabled' }
    else { Add-Check 'EnableMIPLabels (Group.Unified)' 'GAP' ("'{0}' — run IPCONT-Set-ContainerLabels.ps1 -EnablePrerequisites -Commit" -f ($(if($mip){$mip}else{'not set'}))) }
} catch { Add-Check 'EnableMIPLabels (Group.Unified)' 'FAIL' $_.Exception.Message }

# Container-scoped labels published
try {
    $labels = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/informationProtection/policy/labels').value
    $container = @($labels | Where-Object { $_.name -like 'Container*' -or $_.name -match 'Site|Group|Team' })
    if ($labels.Count -gt 0 -and $container.Count -gt 0) { Add-Check 'Container-scoped labels published' 'PASS' ("{0} candidate container label(s): {1}" -f $container.Count, (($container.name) -join ', ')) }
    elseif ($labels.Count -gt 0) { Add-Check 'Container-scoped labels published' 'GAP' 'labels published but none clearly container-scoped — verify a Groups & sites label exists' }
    else { Add-Check 'Container-scoped labels published' 'GAP' 'no published labels visible to this account' }
} catch { Add-Check 'Container-scoped labels published' 'GAP' ("could not read label catalog: {0}" -f $_.Exception.Message) }

# Entra ID P1 signal (gates unmanaged-device access)
try {
    $skus = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/subscribedSkus').value
    $parts = $skus.servicePlans.servicePlanName -join ' '
    if ($parts -match 'AAD_PREMIUM') { Add-Check 'Entra ID P1 (device-access control)' 'PASS' 'AAD_PREMIUM present — Conditional Access device settings available' }
    else { Add-Check 'Entra ID P1 (device-access control)' 'GAP' 'AAD_PREMIUM not detected — scope labels to privacy/guest/sharing; defer device control. Verify your plan.' }
} catch { Add-Check 'Entra ID P1 (device-access control)' 'GAP' ("could not read SKUs: {0}" -f $_.Exception.Message) }

# SharePoint tenant sharing baseline
if ($SPOAdminUrl) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) { Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
    try {
        Connect-SPOService -Url $SPOAdminUrl -ErrorAction Stop
        $t = Get-SPOTenant -ErrorAction Stop
        Add-Check 'SharePoint tenant sharing baseline' 'PASS' ("SharingCapability={0}; ConditionalAccessPolicy={1}" -f $t.SharingCapability, $t.ConditionalAccessPolicy)
    } catch { Add-Check 'SharePoint tenant sharing baseline' 'GAP' ("could not read Get-SPOTenant: {0}" -f $_.Exception.Message) }
} else {
    Add-Check 'SharePoint tenant sharing baseline' 'GAP' 'supply -SPOAdminUrl to read SharingCapability/ConditionalAccessPolicy'
}

$checks | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
$gaps = @($checks | Where-Object { $_.Status -ne 'PASS' }).Count
Write-Host ("`nWrote {0} checks to {1}" -f $checks.Count, $CsvPath) -ForegroundColor Green
Write-Host ("Gaps/failures: {0}" -f $gaps) -ForegroundColor $(if($gaps -eq 0){'Green'}else{'Yellow'})
Write-Host "PASS = enablement on, container labels published, tenant sharing baseline compatible, toolchain healthy (device control needs Entra ID P1)." -ForegroundColor Cyan
